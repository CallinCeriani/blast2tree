#!/bin/bash

function extract() {
    echo "Now running extraction script!"
    cd "$Working_Directory" || exit 1  # Exit if directory change fails
    
# Set directories

    directories=(
        "$output_dir"
    )

    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir "$dir"
            echo "Directory '$dir' created."
        else
            echo "Directory '$dir' already exists. Continuing..."
        fi
    done

    run_analysis() {
        source "$Conda_Directory" &&
        source "$Progressbar" &&
        conda activate "$1" &&
        echo "Starting $2 analysis..." &&
        echo "$3" &&
        # Use eval so that process substitutions are correctly interpreted
        if ! eval "$3"; then
            echo "$2 analysis failed!"
            conda deactivate
            exit 1
        fi
        echo "$2 analysis complete!" &&
        conda deactivate 
        echo
    }

# Check if input directory exists
if [ ! -d "$EXTRACTED_SEQ_DIR" ]; then
  echo "Input directory $EXTRACTED_SEQ_DIR does not exist."
  exit 1
fi

echo "Starting processing in $EXTRACTED_SEQ_DIR..."

###############################
# Part 1: Generate Length Files
###############################

generate_length_files() {
    for file in "$EXTRACTED_SEQ_DIR"/*_extracted.fasta; do
        [[ -f "$file" ]] || { echo "No extracted fasta files found."; break; }
        echo "Processing file: $file"

        temp_file=$(mktemp)
        grep "^>" "$file" | while read -r header; do
            if [[ "$header" =~ :([0-9]+)-([0-9]+) ]]; then
                local start=${BASH_REMATCH[1]}
                local end=${BASH_REMATCH[2]}
                local length=$((end - start + 1))
                echo -e "$length\t$header" >> "$temp_file"
            fi
        done
        
        local output_lengths_file="${file%.fasta}_lengths.fasta"
        sort -k1,1nr "$temp_file" | while read -r line; do
            echo -e "$(echo "$line" | cut -f2-)\n$(echo "$line" | cut -f1)"
        done > "$output_lengths_file"

        rm "$temp_file"
        echo "Length file created: $output_lengths_file"
    done
    echo "Length processing complete."
}

##############################################
# Part 2: Extract Marker-Specific Sequences
##############################################

# Function to extract marker-specific sequences
extract_marker_sequences() {
    for length_file in "$EXTRACTED_SEQ_DIR"/*_extracted_lengths.fasta; do
        [[ -f "$length_file" ]] || { echo "No length files found."; break; }
        
        local base_name=$(basename "$length_file" "_extracted_lengths.fasta")
        local extracted_file="$EXTRACTED_SEQ_DIR/${base_name}_extracted.fasta"

        if [[ -f "$length_file" && -f "$extracted_file" ]]; then
            local header=$(head -n 1 "$length_file")
            local marker=$(echo "$header" | sed -n 's/.*_\([A-Za-z0-9.-]*\):.*/\1/p')
            
            echo "Searching for marker: $marker in file $extracted_file"
            local output_file="$output_dir/${base_name}_${marker}_sequences.fasta"
            > "$output_file"
            
            local capture_sequence=false sequence="" current_header=""
            while read -r line; do
                if [[ "$line" =~ ^\> ]]; then
                    if [ "$capture_sequence" = true ]; then
                        echo -e "$current_header\n$sequence" >> "$output_file"
                    fi
                    if [[ "$line" == *"$marker"* ]]; then
                        current_header="$line"
                        sequence=""
                        capture_sequence=true
                    else
                        capture_sequence=false
                    fi
                elif [ "$capture_sequence" = true ]; then
                    sequence+="$line"
                fi
            done < "$extracted_file"
            
            [ "$capture_sequence" = true ] && echo -e "$current_header\n$sequence" >> "$output_file"
            echo "Marker-specific sequences saved to: $output_file"
        else
            echo "Required file(s) missing: $length_file or $extracted_file"
        fi
    done
}

generate_length_files
extract_marker_sequences

}
