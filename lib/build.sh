#!/bin/bash

function build()
{
    echo "Now running Omega script!"
    cd "$Working_Directory"
    
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
    
    # Function to run analysis and handle errors
    run_analysis() {
        source "$Conda_Directory" &&
        source "$Progressbar" &&
        conda activate "$1" &&
        echo "Starting $2 analysis..." &&
        echo "$3" &&
        if ! $3; then
            echo "$2 analysis failed!" &&
            conda deactivate
            exit 1
        fi
        echo "$2 analysis complete!" &&
        conda deactivate 
        echo
    }

    # Enable nullglob to avoid errors if no matching files exist
    shopt -s nullglob

    # Remove existing BLAST database files
    rm -rf "$GENOME_DIR"/*.{ndb,nhr,nin,njs,not,nsq,ntf,nto,fai}

    echo "Creating BLAST databases..."
    for FILE in "$GENOME_DIR"/*.{fasta,fna}; do
        [ -f "$FILE" ] || continue
        BASE_NAME="${FILE##*/}"
        BASE_NAME="${BASE_NAME%.*}"
        run_analysis "$blast" "make blast db" "makeblastdb -in $FILE -dbtype nucl -out $GENOME_DIR/${BASE_NAME}_db"
        echo "BLAST database created: $BASE_NAME"
    done

    # Ensure query file exists
    if [[ ! -f "$QUERY_FILE" ]]; then
        echo "Error: Query file does not exist: $QUERY_FILE"
        exit 1
    fi

    echo "Running BLAST searches..."
    for DB_FILE in "$GENOME_DIR"/*_db.nhr; do
        [ -f "$DB_FILE" ] || continue
        BASE_NAME="${DB_FILE%_db.nhr}"
        BASE_NAME="${BASE_NAME##*/}"
        OUTPUT_FILE="$OUTPUT_DIR/${BASE_NAME}_blast_results.tsv"
        
        if [[ -f "$OUTPUT_FILE" ]]; then
            echo "BLAST output found for $BASE_NAME, skipping..."
            continue
        fi

        run_analysis "$blast" "blastn" "eval blastn -query $QUERY_FILE -db $GENOME_DIR/${BASE_NAME}_db -outfmt \"$Variable_test2\" -evalue 1e-10 -gapopen 5 -gapextend 2 -perc_identity 89 -qcov_hsp_perc 20 -max_target_seqs 5 -word_size 7 -num_threads $Cpus -out $OUTPUT_FILE"
        echo "BLAST search completed: $BASE_NAME"
    done

    echo "Converting BLAST results to BED format..."
    for TSV_FILE in "$OUTPUT_DIR"/*.tsv; do
        BASE_NAME="${TSV_FILE##*/}"
        BASE_NAME="${BASE_NAME%.tsv}"
        BED_FILE="$OUTPUT_DIR/${BASE_NAME}.bed"
        awk '{
            sstart = $9; send = $10;
            strand = (sstart <= send) ? "+" : "-";
            start = (sstart <= send) ? sstart - 1 : send - 1;
            end = (sstart <= send) ? send : sstart;
            print $2 "\t" start "\t" end "\t" $1 "\t" $11 "\t" strand;
        }' "$TSV_FILE" > "$BED_FILE"
        echo "Converted: $TSV_FILE -> $BED_FILE"
    done

    echo "Starting sequence extraction..."
    for BED_FILE in "$OUTPUT_DIR"/*.bed; do
        BASE_NAME="${BED_FILE##*/}"
        BASE_NAME="${BASE_NAME%_blast_results.bed}"
        GENOME_FILE="$GENOME_DIR/${BASE_NAME}.fasta"
        [[ -f "$GENOME_FILE" ]] || GENOME_FILE="$GENOME_DIR/${BASE_NAME}.fna"
        [[ -f "$GENOME_FILE" ]] || GENOME_FILE=$(find "$GENOME_DIR" -maxdepth 1 -type f \( -name "${BASE_NAME}*.fasta" -o -name "${BASE_NAME}*.fna" \) | head -n 1)
        
        [[ -f "$GENOME_FILE" ]] || { echo "Warning: No genome file found for $BASE_NAME, skipping..."; continue; }
        [[ -s "$BED_FILE" ]] || { echo "Warning: Empty BED file: $BED_FILE, skipping..."; continue; }
        
        echo "Extracting sequences from: $GENOME_FILE using $BED_FILE"
        while IFS=$'\t' read -r CHR START END MARKER _; do
            HEADER="${CHR}_${MARKER}:${START}-${END}"
            bedtools getfasta -fi "$GENOME_FILE" -bed <(echo -e "$CHR\t$START\t$END") -tab -name |
            while read -r SEQ_HEADER SEQUENCE; do
                [[ -n "$SEQUENCE" ]] || continue
                echo ">$HEADER" >> "$EXTRACTED_SEQ_DIR/${BASE_NAME}_extracted.fasta"
                echo "$SEQUENCE" >> "$EXTRACTED_SEQ_DIR/${BASE_NAME}_extracted.fasta"
            done
        done < "$BED_FILE"
        echo "Sequences extracted to: $EXTRACTED_SEQ_DIR/${BASE_NAME}_extracted.fasta"
    done

    echo "Process complete!"
}