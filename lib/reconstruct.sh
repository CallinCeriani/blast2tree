#!/bin/bash 

function reconstruct() {
    echo "Now running reconstruct script!"
    cd "$Working_Directory" || { echo "Failed to change directory to $Working_Directory"; exit 1; }

    # Directory containing FASTA files (add directories as needed)
    directories=(
      # e.g. "$output_dir" "$EXTRACTED_SEQ_DIR" ...
    )

    # Create necessary directories if they don't exist
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Directory '$dir' created."
        else
            echo "Directory '$dir' already exists. Continuing..."
        fi
    done

    run_analysis() {
        # This function sources conda environments and runs a command.
        source "$Conda_Directory" &&
        source "$Progressbar" &&
        conda activate "$1" &&
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

    # Array to record files with contamination issues
    declare -a contamination_files

    # Ensure QUERY_FILE and LEFTOVERS exist
    touch "$QUERY_FILE"
    touch "$LEFTOVERS"
    echo "Created/checked Query file: $QUERY_FILE"
    echo "Created/checked leftovers.fasta: $LEFTOVERS"

    # Step 1: Modify headers for all _sequences.fasta files
    for file in "$output_dir"/*_sequences.fasta; do
        base_name="${file%_sequences.fasta}"
        output_file="${base_name}_header.fasta"
        
        echo "Processing file: $file"
        # Report how many header lines are in the file (for debugging)
        header_count=$(grep -c '^>' "$file")
        echo "Found $header_count header(s) in $(basename "$file")"
        
        # Modify headers: extract parts if possible, else leave unchanged
        awk '/^>/ {
            match($0, /_([A-Za-z0-9]+\.[0-9]+):([0-9]+-[0-9]+)/, arr);
            if (arr[1] != "" && arr[2] != "")
                print ">" arr[1] ":" arr[2];
            else 
                print $0;
        } 
        !/^>/ { print }' "$file" > "$output_file"
        
        echo "Processed: $(basename "$file") -> $(basename "$output_file")"
    done

    echo "Header modification completed."

    # Step 2: Check if any *_header.fasta files exist
    if [ -z "$(ls "$output_dir"/*_header.fasta 2>/dev/null)" ]; then
        echo "No *_header.fasta files found."
        exit 1
    fi

    # Step 3: Process each modified FASTA file sequentially
    for FASTA in "$output_dir"/*_header.fasta; do
        echo "Processing: $FASTA"
        header_count=$(grep -c '^>' "$FASTA")
        echo "File $FASTA has $header_count header(s)."

        # Get the basename without the "_header.fasta" suffix and remove trailing underscore section
        BASENAME=$(basename "$FASTA" "_header.fasta")
        BASE_NAME_ONLY="${BASENAME%_*}"

        # Construct the corresponding extracted_lengths file
        EXTRACTED_LENGTHS_FILE="$EXTRACTED_SEQ_DIR/${BASE_NAME_ONLY}_extracted_lengths.fasta"
        
        if [ ! -f "$EXTRACTED_LENGTHS_FILE" ]; then
            echo "Error: Extracted lengths file for $BASE_NAME_ONLY not found!"
            continue
        fi
    
        echo "Checking length in: $EXTRACTED_LENGTHS_FILE"
        # Assume the second line holds the length value
        LENGTH=$(sed -n '2p' "$EXTRACTED_LENGTHS_FILE")
        echo "Sequence length: $LENGTH"
    
        if [ "$LENGTH" -gt "$CutValue" ]; then
            echo "Length is greater than $CutValue, directly appending sequence from $FASTA"
            # If more than one header is found, use only the first entry
            if [ "$header_count" -gt 1 ]; then
                echo "Warning: more than one sequence found in $FASTA. Only the first entry will be used."
                SEQUENCE=$(awk 'BEGIN { entry=0 } /^>/{ if(entry==1) exit; entry=1; next } { print }' "$FASTA" | tr -d '\n')
            else
                SEQUENCE=$(sed -n '2,$p' "$FASTA" | tr -d '\n')
            fi
            FORMATTED_SEQ=$(echo "$SEQUENCE" | fold -w 70)
            {
                echo ">${BASE_NAME_ONLY}.fasta"
                echo "$FORMATTED_SEQ"
            } >> "$QUERY_FILE"
        else
            # Handle reconstruction via CAP3 and consensus process
            cat "$REFERENCE" "$FASTA" > "$COMBINED"
            echo "Running CAP3 on combined file: $COMBINED"
            run_analysis "$cap3" "fragment reconstruction" "cap3 \"$COMBINED\" -m 60 -p 75 -g 1 > out.txt"

            if [ ! -s out.txt ]; then
                echo "CAP3 failed to produce output for: $FASTA"
                continue
            fi
                
            run_analysis "$cap3" "fragment reconstruction" "python3 /opt/bin/lib/consensus.py"
            if [ ! -s res.txt ]; then
                echo "Consensus file (res.txt) is empty for $FASTA. Skipping consensus for this file."
                continue
            fi

            # Check consensus output for multiple entries
            consensus_headers=$(grep -c '^>' res.txt)
            echo "Consensus file res.txt has $consensus_headers header(s)."
            sed -i "1s/.*/>${BASE_NAME_ONLY}.fasta/" res.txt
            
            if [ "$consensus_headers" -gt 1 ]; then
                echo "Warning: Consensus file has more than one entry, using first sequence only."
                SEQUENCE=$(awk 'BEGIN { entry=0 } /^>/{ if(entry==1) exit; entry=1; next } { print }' res.txt | tr -d '\n')
            else
                SEQUENCE=$(sed -n '2,$p' res.txt | tr -d '\n')
            fi

            if [ -z "$SEQUENCE" ]; then
                echo "Consensus sequence from res.txt is empty for $FASTA. Skipping..."
                continue
            fi
            FORMATTED_SEQ=$(echo "$SEQUENCE" | fold -w 70)
            {
                echo ">${BASE_NAME_ONLY}.fasta"
                echo "$FORMATTED_SEQ"
            } >> "$QUERY_FILE"
            
            echo "Appended consensus for: $FASTA"
        fi
    done

    # Step 4: Clean headers in QUERY_FILE and output to CLEAN_FILE
    sed -r "/^>/ { s/ /_/g; s/[;:'\",]//g; s/_+/_/g }" "$QUERY_FILE" > "$CLEAN_FILE"

    echo "Checking for empty sequences and sequences below threshold length in $CLEAN_FILE..."
    TMP_FILE="${CLEAN_FILE}.tmp"
    > "$TMP_FILE"

    {
        CURRENT_HEADER=""
        CURRENT_SEQ=""
        while read -r LINE; do
            if [[ "$LINE" =~ ^\> ]]; then
                # Process the previous entry if it exists
                if [[ -n "$CURRENT_HEADER" ]]; then
                    if [[ -z "$CURRENT_SEQ" ]]; then
                        echo "Moving empty entry to leftovers: $CURRENT_HEADER"
                        echo "$CURRENT_HEADER" >> "$LEFTOVERS"
                    elif [[ ${#CURRENT_SEQ} -lt $THRESHOLD ]]; then
                        echo "Moving short sequence to leftovers: $CURRENT_HEADER"
                        echo "$CURRENT_HEADER" >> "$LEFTOVERS"
                        echo "$CURRENT_SEQ" >> "$LEFTOVERS"
                    else
                        echo "$CURRENT_HEADER" >> "$TMP_FILE"
                        echo "$CURRENT_SEQ" >> "$TMP_FILE"
                    fi
                fi
                CURRENT_HEADER="$LINE"
                CURRENT_SEQ=""
            else
                CURRENT_SEQ+="$LINE"
            fi
        done < "$CLEAN_FILE"

        # Process the final entry
        if [[ -n "$CURRENT_HEADER" ]]; then
            if [[ -z "$CURRENT_SEQ" ]]; then
                echo "Moving empty entry to leftovers: $CURRENT_HEADER"
                echo "$CURRENT_HEADER" >> "$LEFTOVERS"
            elif [[ ${#CURRENT_SEQ} -lt $THRESHOLD ]]; then
                echo "Moving short sequence to leftovers: $CURRENT_HEADER"
                echo "$CURRENT_HEADER" >> "$LEFTOVERS"
                echo "$CURRENT_SEQ" >> "$LEFTOVERS"
            else
                echo "$CURRENT_HEADER" >> "$TMP_FILE"
                echo "$CURRENT_SEQ" >> "$TMP_FILE"
            fi
        fi
    }

    mv "$TMP_FILE" "$CLEAN_FILE"
    echo "Empty and short sequences moved to leftovers.fasta."

    # Step 5: Re-wrap sequences to 70 nt per line
    wrap_fasta() {
        infile="$1"
        outfile="${infile}.tmp"
        awk 'BEGIN { RS=">"; ORS="" } 
             NR>1 {
               header = substr($0, 1, index($0, "\n")-1);
               seq = substr($0, index($0, "\n")+1);
               gsub(/\n/, "", seq);
               printf(">%s\n", header);
               for(i=1; i<=length(seq); i+=70){
                   print substr(seq,i,70) "\n"
               }
             }' "$infile" > "$outfile" && mv "$outfile" "$infile"
    }

    echo "Wrapping sequences in $CLEAN_FILE to 70 nt per line..."
    wrap_fasta "$CLEAN_FILE"

    echo "Wrapping sequences in $LEFTOVERS to 70 nt per line..."
    wrap_fasta "$LEFTOVERS"

    # Report files that had contamination issues
    if [ ${#contamination_files[@]} -ne 0 ]; then
        echo "WARNING: The following files showed high likelihood of contamination and defaulted to using the first sequence:"
        for f in "${contamination_files[@]}"; do
            echo "$f"
        done
    fi

    echo "All files processed. Final consensus sequences are in $CLEAN_FILE and removed entries are in $LEFTOVERS."
    
    rm -rf $Working_Directory/res.txt $Working_Directory/out.txt $Working_Directory/ref-plus*
    
}
