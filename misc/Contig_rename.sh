#!/bin/bash

rename_contigs() {
    # Create the output directory if it doesn't exist
    mkdir -p renamed_contigs
    echo "Renaming contigs to standard format"

    # Loop through all files with the pattern *.fasta or *.fna
    for file in *.fasta *.fna; do
        # Check if the file exists and is not empty
        if [ -s "$file" ]; then
            # Extract the base name from the file name
            base="${file%.*}"
            # Define the output file path
            output_file="renamed_contigs/${file}"

            # Process the file with awk
            awk -v var="$base" '
            /^>/ {
                sub(/^>/, "", $0)  # Remove leading ">"
                gsub(/[^a-zA-Z0-9_. ]/, "", $0)  # Remove non-alphanumeric except "_", ".", and spaces
                gsub(/ /, "_", $0)  # Replace spaces with "_"
                print ">" var "_" $0  # Append filename prefix
                next
            }
            { print }  # Print sequence lines unchanged
            ' "$file" > "$output_file"
        fi
    done
}


