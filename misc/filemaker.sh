#!/bin/bash

function make_files() {
for file in *.fasta; do
  dir_name="${file%.*}" # Remove the file extension to get the directory name
  mkdir -p "$dir_name" # Create the directory
  mv "$file" "$dir_name/" # Move the file into the directory
done
    }
