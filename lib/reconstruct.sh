#!/bin/bash

function reconstruct() {
    echo "Now running reconstruct script!"
    cd "$Working_Directory" || { echo "Failed to change directory to $Working_Directory"; exit 1; }

    directories=(
      # e.g. "$output_dir" "$EXTRACTED_SEQ_DIR"
    )

    for dir in "${directories[@]}"; do
        [ -d "$dir" ] || { mkdir -p "$dir"; echo "Directory '$dir' created."; }
    done

    run_analysis() {
        source "$Conda_Directory"
        source "$Progressbar"
        conda activate "$1"
        echo "Starting $2 analysis..."
        echo "Running command: $3"
        if ! eval "$3"; then
            echo "$2 analysis failed!"
            conda deactivate
            exit 1
        fi
        echo "$2 analysis complete!"
        conda deactivate
        echo
    }

    wrap_fasta_70() {
        input="$1"
        awk 'BEGIN { RS=">"; ORS="" }
        NR>1 {
            header = substr($0, 1, index($0, "\n")-1);
            seq = substr($0, index($0, "\n")+1);
            gsub(/\n/, "", seq);
            printf(">%s\n", header);
            for(i=1; i<=length(seq); i+=70){
                print substr(seq,i,70) "\n"
            }
        }' "$input" > "${input}.tmp" && mv "${input}.tmp" "$input"
    }

    declare -a contamination_files

    touch "$QUERY_FILE" "$LEFTOVERS"
    echo "Created/checked files: $QUERY_FILE and $LEFTOVERS"

    # Header trimming
    for file in "$output_dir"/*_sequences.fasta; do
        base_name="${file%_sequences.fasta}"
        output_file="${base_name}_header.fasta"
        awk '/^>/ {
            match($0, /_([A-Za-z0-9]+\.[0-9]+):([0-9]+-[0-9]+)/, arr);
            if (arr[1] != "" && arr[2] != "")
                print ">" arr[1] ":" arr[2];
            else
                print $0;
        } !/^>/ { print }' "$file" > "$output_file"
        echo "Processed: $(basename "$file") -> $(basename "$output_file")"
    done
    echo "Header modification completed."

    files=("$output_dir"/*_header.fasta)
    [ -e "${files[0]}" ] || { echo "No *_header.fasta files found."; exit 1; }

    wrap_fasta_70 "$REFERENCE"

    # Main loop: append or scaffold
    for FASTA in "$output_dir"/*_header.fasta; do
        echo "Processing: $FASTA"
        BASENAME=$(basename "$FASTA" "_header.fasta")
        BASE_NAME_ONLY="${BASENAME%_*}"
        EXTRACTED_LENGTHS_FILE="$EXTRACTED_SEQ_DIR/${BASE_NAME_ONLY}_extracted_lengths.fasta"

        [ -f "$EXTRACTED_LENGTHS_FILE" ] || { echo "Missing: $EXTRACTED_LENGTHS_FILE"; continue; }

        LENGTH=$(sed -n '2p' "$EXTRACTED_LENGTHS_FILE")
        echo "Sequence length: $LENGTH"

        if [ "$LENGTH" -gt "$CutValue" ]; then
            echo "Length > $CutValue: directly appending from $FASTA"
            header_count=$(grep -c '^>' "$FASTA")
            if [ "$header_count" -gt 1 ]; then
                echo "Warning: multiple sequences, using only first."
                SEQUENCE=$(awk 'BEGIN{e=0}/^>/{if(e)exit;e=1;next}{print}' "$FASTA" | tr -d '\n')
            else
                SEQUENCE=$(sed -n '2,$p' "$FASTA" | tr -d '\n')
            fi
        else
            echo "Length <= $CutValue: running reference-guided scaffold"
            SCAFFOLD_OUTPUT="$Working_Directory/${BASE_NAME_ONLY}_scaffolded.fasta"
            run_analysis "$blast" "reference-guided scaffold" \
                "python3 $Sentral/python_scripts/scaffold_with_gaps.py '$REFERENCE' '$FASTA' '$SCAFFOLD_OUTPUT'"
            sed -i "1s/.*/>${BASE_NAME_ONLY}.fasta/" "$SCAFFOLD_OUTPUT"

            if [ ! -s "$SCAFFOLD_OUTPUT" ]; then
                echo "Scaffolding failed; adding to leftovers."
                echo ">${BASE_NAME_ONLY}.fasta" >> "$LEFTOVERS"
                echo "" >> "$LEFTOVERS"
                continue
            fi

            # Corrected awk to avoid backslash error
            SEQUENCE=$(awk '!/^>/ { printf "%s", $0 }' "$SCAFFOLD_OUTPUT")
        fi

        echo "Appending sequence to CLEAN_FILE for sample: $BASE_NAME_ONLY"
        {
            [ -s "$QUERY_FILE" ] && echo ""
            echo ">${BASE_NAME_ONLY}.fasta"
            echo "$SEQUENCE" | fold -w 70
        } >> "$QUERY_FILE"
    done

    # Cleanup and final wrapping
    sed -r "/^>/ { s/ /_/g; s/[;:'\",]//g; s/_+/_/g }" "$QUERY_FILE" > "$CLEAN_FILE"

    echo "Filtering short/empty sequences in $CLEAN_FILE..."
    TMP_FILE="${CLEAN_FILE}.tmp"; > "$TMP_FILE"
    {
        CURRENT_HEADER=""; CURRENT_SEQ=""
        while read -r LINE; do
            if [[ "$LINE" == ">"* ]]; then
                if [[ -n "$CURRENT_HEADER" ]]; then
                    if [[ -z "$CURRENT_SEQ" || ${#CURRENT_SEQ} -lt $THRESHOLD ]]; then
                        echo "$CURRENT_HEADER" >> "$LEFTOVERS"
                        echo "$CURRENT_SEQ" >> "$LEFTOVERS"
                    else
                        echo "$CURRENT_HEADER" >> "$TMP_FILE"
                        echo "$CURRENT_SEQ" >> "$TMP_FILE"
                    fi
                fi
                CURRENT_HEADER="$LINE"; CURRENT_SEQ=""
            else
                CURRENT_SEQ+="$LINE"
            fi
        done < "$CLEAN_FILE"
        if [[ -n "$CURRENT_HEADER" ]]; then
            if [[ -z "$CURRENT_SEQ" || ${#CURRENT_SEQ} -lt $THRESHOLD ]]; then
                echo "$CURRENT_HEADER" >> "$LEFTOVERS"
                echo "$CURRENT_SEQ" >> "$LEFTOVERS"
            else
                echo "$CURRENT_HEADER" >> "$TMP_FILE"
                echo "$CURRENT_SEQ" >> "$TMP_FILE"
            fi
        fi
    }
    mv "$TMP_FILE" "$CLEAN_FILE"

    echo "Wrapping final FASTA outputs..."
    wrap_fasta_70 "$CLEAN_FILE"
    wrap_fasta_70 "$LEFTOVERS"

    # Only print contamination warning if array non-empty
    if [ ${#contamination_files[@]} -gt 0 ]; then
        echo "WARNING: These files had high contamination:"
        printf '%s
' "${contamination_files[@]}"
    fi

    echo "Cleaning up intermediate files..."
    rm -f "$Working_Directory"/*scaffolded.fasta \
          "$Working_Directory"/blast_results.tsv \
          "$Working_Directory"/scaffold_log.txt \
          "$REFERENCE".{nhr,nin,nsq,ndb,not,nog,pal,phr,pin,psq,njs,ntf,nto}

    echo "Finished. Final: $CLEAN_FILE | Leftovers: $LEFTOVERS"
}
