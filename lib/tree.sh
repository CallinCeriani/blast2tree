#!/bin/bash

tree()
{
    echo "Now running Tree making script!"
    cd "$Working_Directory"
    
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
    total_steps=4
    current_step=1

   run_analysis "$blast2tree" "mafft alignment" "eval mafft --adjustdirectionaccurately --threadtb $Cpus --threadit $Cpus --thread $Cpus --auto $CLEAN_FILE > $output_dir/$MARKER_NAME.aligned.fasta"
   awk '/^>/ {print; next} {gsub("n", "N"); print}' $output_dir/$MARKER_NAME.aligned.fasta > $output_dir/temp && mv $output_dir/temp $output_dir/$MARKER_NAME.aligned.fasta
   run_analysis "$blast2tree" "trimal" "trimal -keepheader -in $output_dir/$MARKER_NAME.aligned.fasta -out $output_dir/$MARKER_NAME.trimmed.fasta -automated1"
   run_analysis "$blast2tree" "iqtree" "iqtree2 -s $output_dir/$MARKER_NAME.trimmed.fasta -m MFP -bb 1000 -alrt 1000 -nt AUTO --threads-max $Cpus -redo"
   #-b 1000 (serious) -B 1000 (not serious)
}

