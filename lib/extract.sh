#!/bin/bash
# Combined script to process fasta files and extract marker sequences.
# Usage: ./script.sh <input_directory> <output_directory>

# Check if the correct number of arguments are provided
#if [ "$#" -ne 2 ]; then
#  echo "Usage: $0 <input_directory> <output_directory>"
#  exit 1
#fi

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

# Process only files that follow the naming convention *_extracted.fasta
for file in "$EXTRACTED_SEQ_DIR"/*_extracted.fasta; do
  # Check if there are any matching files
  if [ ! -f "$file" ]; then
    echo "No extracted fasta files found in $EXTRACTED_SEQ_DIR."
    break
  fi

  echo "Processing file: $file"

  # Create a temporary file to hold header-length pairs
  temp_file=$(mktemp)

  # Extract headers from the file and compute the range length
  # Only headers (lines beginning with '>') are processed
  while read -r header; do
    # Look for a pattern like :<start>-<end> in the header
    if [[ "$header" =~ :([0-9]+)-([0-9]+) ]]; then
      start=${BASH_REMATCH[1]}
      end=${BASH_REMATCH[2]}
      length=$((end - start + 1))
      # Write the length and header separated by a tab
      echo -e "$length\t$header" >> "$temp_file"
    fi
  done < <(grep "^>" "$file")

  # Define the output file name by appending _lengths.fasta
  output_lengths_file="${file%.fasta}_lengths.fasta"

  # Sort the temporary file by the computed length (descending) and output in the desired format:
  # header on one line and its length on the next.
  sort -k1,1nr "$temp_file" | while read -r line; do
    length=$(echo "$line" | cut -f1)
    header=$(echo "$line" | cut -f2-)
    echo -e "$header\n$length"
  done > "$output_lengths_file"

  # Remove the temporary file
  rm "$temp_file"

  echo "Length file created: $output_lengths_file"
  done

  echo "Length processing complete."
  echo "--------------------------------"

##############################################
# Part 2: Extract Marker-Specific Sequences
##############################################

# Loop through all *_extracted_lengths.fasta files generated above
for length_file in "$EXTRACTED_SEQ_DIR"/*_extracted_lengths.fasta; do
  # Check if any such file exists
  if [ ! -f "$length_file" ]; then
    echo "No length files found in $EXTRACTED_SEQ_DIR."
    break
  fi

  # Derive the base name by removing the '_extracted_lengths.fasta' suffix
  base_name=$(basename "$length_file" "_extracted_lengths.fasta")

  # The corresponding extracted fasta file (with full sequences)
  extracted_file="$EXTRACTED_SEQ_DIR/${base_name}_extracted.fasta"

  if [[ -f "$length_file" && -f "$extracted_file" ]]; then
    # Read the first header from the lengths file
    header=$(head -n 1 "$length_file")
    # Extract the marker: text between the last "_" and the first ":" in the header
    marker=$(echo "$header" | sed -n 's/.*_\([A-Za-z0-9.-]*\):.*/\1/p')
    
    echo "Searching for marker: $marker in file $extracted_file"

    # Initialize variables for capturing sequences
    capture_sequence=false
    sequence=""
    current_header=""

    # Define the output file for sequences matching this marker
    output_file="$output_dir/${base_name}_${marker}_sequences.fasta"
    # Ensure the output file is empty before starting
    > "$output_file"

    # Process the extracted fasta file line by line
    while read -r line; do
      # If the line is a header line
      if [[ "$line" =~ ^\> ]]; then
        # If a sequence was being captured, write it to the output file
        if [ "$capture_sequence" = true ]; then
          echo -e "$current_header\n$sequence" >> "$output_file"
        fi

        # Check if the header contains the marker
        if [[ "$line" == *"$marker"* ]]; then
          current_header="$line"
          sequence=""
          capture_sequence=true
        else
          capture_sequence=false
        fi
      else
        # Append the line to the sequence if capturing is active
        if [ "$capture_sequence" = true ]; then
          sequence="$sequence$line"
        fi
      fi
    done < "$extracted_file"

    # Output the last captured sequence if needed
    if [ "$capture_sequence" = true ]; then
      echo -e "$current_header\n$sequence" >> "$output_file"
    fi

    echo "Marker-specific sequences saved to: $output_file"
  else
    echo "Required file(s) missing: $length_file or $extracted_file"
  fi
done

echo "Processing complete."
}
