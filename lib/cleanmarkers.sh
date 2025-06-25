#!/bin/bash

function cleanmarkers()
{
   echo "Now running cleanmarkers script"
   cd $Working_Directory
   
       directories=(
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
        if ! $3; then
            echo "$2 analysis failed!" &&
            conda deactivate
            exit 1
        fi
        echo "$2 analysis complete!" &&
        conda deactivate 
        current_step=$((current_step + 1))
        show_progress $current_step $total_steps
        echo
    }
    
    # Total number of analysis steps
    total_steps=2
    current_step=0
    
   cp $Input_seq $MARKER_NAME.copy.fa
   run_analysis "$mafft" "mafft alignment" "eval mafft --adjustdirectionaccurately --threadtb $Cpus --threadit $Cpus --thread $Cpus --auto $Input_seq > $MARKER_NAME.prealigned.fa"
   awk '/^>/ {print; next} {gsub("n", "N"); print}' $MARKER_NAME.prealigned.fa > temp && mv temp $MARKER_NAME.prealigned.fa
   run_analysis "$trimal" "trimal" "trimal -keepheader -in $MARKER_NAME.prealigned.fa -out $MARKER_NAME.pretrimmed.fa -automated1"
   awk '/^>/ {print; next} {gsub("-", "", $0); print}'  $MARKER_NAME.pretrimmed.fa >  $MARKER_NAME.fa
   rm -rf $MARKER_NAME.prealigned.fa $MARKER_NAME.pretrimmed.fa

}