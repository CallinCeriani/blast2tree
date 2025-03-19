#!/bin/bash

function build() {
    echo "Now running Omega script!"
    cd "$Working_Directory" || { echo "Failed to change directory"; exit 1; }
    
    # Directories
    directories=(
        "$OUTPUT_DIR" 
        "$EXTRACTED_SEQ_DIR"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Directory '$dir' created."
        else
            echo "Directory '$dir' already exists. Continuing..."
        fi
    done

    run_analysis() {
        source "$Conda_Directory"
        source "$Progressbar"
        conda activate "$1"
        echo "Starting $2 analysis..."
        echo "$3"
        if ! eval "$3"; then
            echo "$2 analysis failed!"
            conda deactivate
            exit 1
        fi
        echo "$2 analysis complete!"
        conda deactivate
        echo
    }

    # Enable nullglob so that globs with no matches do not cause errors.
    shopt -s nullglob
    
    # Remove existing BLAST database files
    rm -rf "$GENOME_DIR"/*.{ndb,nhr,nin,njs,not,nsq,ntf,nto,fai}  

    ##############################################
    # Creates BLAST databases in parallel from genome files.
    ##############################################

run_blastdb_parallel() {
    echo "Creating BLAST databases in parallel..."
    
    # Ensure that $jobs is defined
    if [ -z "$jobs" ]; then
        echo "Error: jobs variable is not defined."
        return 1
    fi

    export GENOME_DIR  # Ensure GENOME_DIR is accessible in subshells

    # Function to create a BLAST database
    create_blastdb() {
        FILE="$1"
        BASE_NAME="$(basename "$FILE")"
        BASE_NAME="${BASE_NAME%.*}"
        
        makeblastdb -in "$FILE" -dbtype nucl -out "$GENOME_DIR/${BASE_NAME}_db" &&
        echo "BLAST database created: ${BASE_NAME}" ||
        echo "Failed to create BLAST database for: ${BASE_NAME}" >&2
    }

    export -f create_blastdb

    # Run database creation in parallel
    find "$GENOME_DIR" -maxdepth 1 -type f \( -name "*.fasta" -o -name "*.fna" \) | parallel -j "$jobs" create_blastdb

    echo "All BLAST databases have been created."
}
    
    ##############################################
    # Runs BLAST searches in parallel.
    ##############################################

run_blast_parallel() {
    # Ensure query file exists
    if [[ ! -f "$QUERY_FILE" ]]; then
        echo "Error: Query file does not exist: $QUERY_FILE"
        exit 1
    fi
    
    echo "Running BLAST searches in parallel..."

    export QUERY_FILE GENOME_DIR OUTPUT_DIR Variable_test2 Cpus

    # Function to execute BLAST
    run_blast() {
        DB_FILE="$1"
        BASE_NAME="${DB_FILE%_db.nhr}"
        BASE_NAME="${BASE_NAME##*/}"
        OUTPUT_FILE="$OUTPUT_DIR/${BASE_NAME}_blast_results.tsv"
        
        if [[ -f "$OUTPUT_FILE" ]]; then
            echo "BLAST output found for $BASE_NAME, skipping..."
            return
        fi

        echo "Processing $BASE_NAME with BLAST..."
        blastn -query "$QUERY_FILE" -db "$GENOME_DIR/${BASE_NAME}_db" \
            -outfmt "$Variable_test2" -evalue 1e-10 -gapopen 5 -gapextend 2 \
            -perc_identity 89 -qcov_hsp_perc 20 -max_target_seqs 5 -word_size 7 \
            -num_threads "$Cpus" -out "$OUTPUT_FILE" &&
        echo "BLAST completed for $BASE_NAME" ||
        echo "BLAST failed for $BASE_NAME" >&2
    }

    export -f run_blast

    # Run BLAST in parallel
    find "$GENOME_DIR" -name "*_db.nhr" | parallel -j "$jobs" run_blast

    echo "BLAST searches completed!"
}

    ##############################################
    # Converts BLAST TSV results to BED format in parallel.
    ##############################################
    
Convert_bed() {    
    echo "Converting BLAST results to BED format..."

    # Export necessary variables for parallel processing
    export OUTPUT_DIR

    # Function to process each TSV file and convert to BED
    convert_tsv_to_bed() {
        TSV_FILE="$1"
        BASE_NAME="${TSV_FILE##*/}"
        BASE_NAME="${BASE_NAME%.tsv}"
        BED_FILE="$OUTPUT_DIR/${BASE_NAME}.bed"
        
        # Convert TSV to BED format
        awk '{
            sstart = $9; send = $10;
            strand = (sstart <= send) ? "+" : "-";
            start = (sstart <= send) ? sstart - 1 : send - 1;
            end = (sstart <= send) ? send : sstart;
            print $2 "\t" start "\t" end "\t" $1 "\t" $11 "\t" strand;
        }' "$TSV_FILE" > "$BED_FILE"

        echo "Converted: $TSV_FILE -> $BED_FILE"
    }

    export -f convert_tsv_to_bed  # Export the function for parallel execution

    # Use GNU Parallel to process each TSV file in parallel
    find "$OUTPUT_DIR" -name "*.tsv" | parallel -j "$jobs" convert_tsv_to_bed

    echo "BED file conversion complete!"
}

    ##############################################
    # Extracts sequences from genome files based on BED coordinates in parallel.
    ##############################################

run_extract_seq() {
    echo "Starting sequence extraction..."

    # Export necessary variables for parallel processing
    export GENOME_DIR
    export EXTRACTED_SEQ_DIR

    # Function for processing each BED file in parallel
    extract_sequences() {
        BED_FILE="$1"
        BASE_NAME="${BED_FILE##*/}"
        BASE_NAME="${BASE_NAME%_blast_results.bed}"
        echo "Processing BED file: $BED_FILE with base name: $BASE_NAME"

        # Try to find the corresponding genome file based on the base name
        GENOME_FILE="$GENOME_DIR/${BASE_NAME}.fasta"
        [[ -f "$GENOME_FILE" ]] || GENOME_FILE="$GENOME_DIR/${BASE_NAME}.fna"
        [[ -f "$GENOME_FILE" ]] || GENOME_FILE=$(find "$GENOME_DIR" -maxdepth 1 -type f \( -name "${BASE_NAME}*.fasta" -o -name "${BASE_NAME}*.fna" \) | head -n 1)

        # Check if the genome file exists
        if [[ ! -f "$GENOME_FILE" ]]; then
            echo "Warning: No genome file found for $BASE_NAME, skipping..."
            return
        fi
        echo "Using genome file: $GENOME_FILE"

        # Check if the BED file is empty
        if [[ ! -s "$BED_FILE" ]]; then
            echo "Warning: Empty BED file: $BED_FILE, skipping..."
            return
        fi

        # Extract sequences using BED file coordinates
        echo "Extracting sequences from: $GENOME_FILE using $BED_FILE"
        while IFS=$'\t' read -r CHR START END MARKER _; do
            HEADER="${CHR}_${MARKER}:${START}-${END}"
            bedtools getfasta -fi "$GENOME_FILE" -bed <(echo -e "$CHR\t$START\t$END") -tab -name |
            while read -r SEQ_HEADER SEQUENCE; do
                # Skip empty sequences
                [[ -n "$SEQUENCE" ]] || continue
                echo ">$HEADER" >> "$EXTRACTED_SEQ_DIR/${BASE_NAME}_extracted.fasta"
                echo "$SEQUENCE" >> "$EXTRACTED_SEQ_DIR/${BASE_NAME}_extracted.fasta"
            done
        done < "$BED_FILE"
        echo "Sequences extracted to: $EXTRACTED_SEQ_DIR/${BASE_NAME}_extracted.fasta"
    }

    export -f extract_sequences  # Export the function for parallel execution

    # Use GNU Parallel to process each BED file in parallel
    find "$OUTPUT_DIR" -name "*.bed" | parallel -j "$jobs" extract_sequences

    echo "Sequence extraction complete!"
}

    ##############################################
    # Call each step via run_analysis, using the function name as a command string.
    ##############################################
    
    run_analysis "$blast" "make BLAST databases" "run_blastdb_parallel"
    run_analysis "$blast" "BLAST searches" "run_blast_parallel"
    Convert_bed
    run_analysis "$bedtools" "Sequence extraction" "run_extract_seq"
    echo "Process complete!"
}
