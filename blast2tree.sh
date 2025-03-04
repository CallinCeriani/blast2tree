#!/bin/bash

############################################################
# Function to source files in a directory based on extension #
############################################################

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

############################################################
#                Help Function                             #
############################################################

Help() {
  echo
  echo -e "${CYAN}=================================== START OF HELP MENU ===================================${RESET}"
  echo
  echo -e "${BLUE}----------------------------- Processing parameters -----------------------------${RESET}"
  echo
  echo -e " --threads|-t|--Cpus                  default = 1" 
  echo -e " --working_directory|--wd             default = uses your current directory. $PWD"
  echo -e " --Run_name|--s                       default = None. Run name and named logfile."
  echo -e " --THRESHOLD                          default = 300"
  echo -e " --MARKER_BLAST_ID                    default = ITS_Marker"
  echo -e " --EXTRACTED_MARKER_OUT               default = extracted_sequences_ITS"
  echo -e " --Input_seq                          default = ITS.fa" 
  echo -e " --CutValue                           default = 500" 
  echo
  echo -e "${BLUE}------------------------------- Analysis functions ------------------------------${RESET}"
  echo
  echo -e " --build               (Utilizes: ${GREEN}$blast, $bedtools.${RESET} Create blastdb for genome and  blast search our reference markers, whiling extracting sequences."
  echo -e " --extract             (Utilizes: ${GREEN}Custom script.${RESET} This determines the longest hit in .bed file and extracts it." 
  echo -e " --reconstruct         (Utilizes: ${GREEN}$cap3, $bedtools.${RESET} Reconstructs marker over separate contigs and adds to marker file in prep for --tree. Requires reference.fa in $Working_Directory."
  echo -e " --tree                (Utilizes: ${GREEN}$muscle, $trimal, $iqtree.${RESET} This does alignment, trimming and constructs the tree." 
  echo 
  echo -e "${BLUE}------------------------------- Utility functions -------------------------------${RESET}"
  echo
  echo -e " --variables|--l                      Display BUSCO, Augustus and NCBI taxonomic ID options or databases"
  echo -e " --rename_contigs|--K                 Renames all .fasta contigs in a directory based on filename(s). output is in the directory renamed_contigs. Built into --busco_batch"
  echo -e " --make_files|--mk                    Makes a folder for all .fasta's in a directory and moves them into their corresponding folder"
  echo
  echo -e "${BLUE}--------------------------------- Example usage ---------------------------------${RESET}"
  echo
  echo -e "                   Example: phylo1.sh -t <options> --s <options> --A1"
  echo
  echo -e "${CYAN}=================================== END OF HELP MENU ===================================${RESET}"
  echo
}

Wrong() {
echo
echo -e "${CYAN}This is C. Ceriani's experimental pipeline (2024)${RESET}"
echo -e "${CYAN}============================ CONFIGURATION INFORMATION ============================${RESET}"
echo -e "  Working Directory: $Working_Directory"
echo -e "  Sample Name:       $Input_name"
echo -e "  Number of CPUs:    $Cpus"
echo
echo -e "                                   To get help do phylo1.sh --h"
echo -e "${CYAN}==================================================================================${RESET}"
}

#######################################################
# Function to source the main configuration file      #
#######################################################

# Main configuration file path
MAIN_CONF="/opt/bin/config/main.conf"

source_main_conf() {
  if [ -f "$MAIN_CONF" ]; then
    source "$MAIN_CONF"
    #echo -e "${GREEN}Loaded main configuration file: $MAIN_CONF${RESET}"
  else
    echo -e "${RED}Error: main.conf not found at $MAIN_CONF.${RESET}"
    exit 1
  fi
}
 
# Function to source files with a given extension from a directory
source_files_in_dir() {
  local dir="$1"
  local ext="$2"
  local message_no_files="$3"

  if [ -d "$dir" ]; then
    local files=("$dir"/*."$ext")
    if [ ! -e "${files[0]}" ]; then
      echo -e "${YELLOW}$message_no_files${RESET}"
    else
      for file in "${files[@]}"; do
        if [ -f "$file" ]; then
          #echo -e "${CYAN}Sourcing $file${RESET}"
          source "$file"
        fi
      done
    fi
  else
    echo -e "${RED}Directory $dir does not exist.${RESET}"
  fi
}

# Function to handle variable conflicts
handle_conflicts() {
  local file="$1"
  local var_conflict=""
  while read -r line; do
    if [[ "$line" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
      local var_name="${line%%=*}"
      if [[ -n "${!var_name+x}" ]]; then
        echo -e "${YELLOW}Warning: Variable $var_name already set. New value from $file might override existing value.${RESET}"
      fi
    fi
  done < "$file"
}

# Function to re-source configuration files after updating variables
refresh_configurations() {
  #echo -e "${GREEN}Refreshing configurations with updated values...${RESET}"
  source_main_conf
  source_files_in_dir "/opt/bin/config" "conf" "No configuration files found in /opt/bin/config"
  source_files_in_dir "/opt/bin/lib" "sh" "No scripts found in /opt/bin/lib"
  source_files_in_dir "/opt/bin/misc" "sh" "No scripts found in /opt/bin/misc"
}

# Source the main configuration file
source_main_conf
# Source scripts from lib/ and misc/ directories
source_files_in_dir "/opt/bin/config" "conf" "No configuration files found in /opt/bin/config"
source_files_in_dir "/opt/bin/lib" "sh" "No scripts found in /opt/bin/lib"
source_files_in_dir "/opt/bin/misc" "sh" "No scripts found in /opt/bin/misc"

# Default values for new options
  Cpus=1
  Working_Directory="$PWD"
  THRESHOLD=300                                      # Set the threshold for sequence length
  MARKER_NAME=ITS
  MARKER_BLAST_ID=ITS_Marker                         # User set last dir
  EXTRACTED_MARKER_OUT=extracted_sequences_ITS       # User set last part
  Input_seq=ITS.fa                                   # User set last part
  CutValue="450"
   
############################################################
# Function to log the time and output of a command         #
############################################################

log_and_time() {
  local command=$1
  local log_file=$2
  { time $command; } 2>&1 | tee -a "$log_file"
}

############################################################
# Processing input options with getopts
#############################################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --threads|-t|--Cpus)  # Set number of threads
       if [[ -z "$2" ]]; then
         echo "Error: --threads requires a value"
         exit 1
       fi
       Cpus="$2"
       refresh_configurations
       shift 2
       ;;
    --working_directory|--wd)  # Set directory path
       if [[ -z "$2" ]]; then
         echo "Error: --working_directory requires a value"
         exit 1
       fi
       Working_Directory="$2"
       refresh_configurations
       shift 2
       ;;
    --sample_name|--s)  # Set sample name
       if [[ -z "$2" ]]; then
         echo "Error: --sample_name requires a value"
         exit 1
       fi
       Input_name="$2"
       refresh_configurations
       shift 2
       ;;
    --THRESHOLD)  # Set THRESHOLD value
       if [[ -z "$2" ]]; then
         echo "Error: --THRESHOLD requires a value"
         exit 1
       fi
       THRESHOLD="$2"
       refresh_configurations
       shift 2
       ;;
    --MARKER_NAME)  # Set MARKER_NAME directory
       if [[ -z "$2" ]]; then
         echo "Error: --MARKER_NAME requires a value"
         exit 1
       fi
       MARKER_NAME="$2"
       refresh_configurations
       shift 2
       ;;
    --MARKER_BLAST_ID)  # Set MARKER_BLAST_ID directory
       if [[ -z "$2" ]]; then
         echo "Error: --MARKER_BLAST_ID requires a value"
         exit 1
       fi
       MARKER_BLAST_ID="$2"
       refresh_configurations
       shift 2
       ;;
    --EXTRACTED_MARKER_OUT)  # Set EXTRACTED_MARKER_OUT directory
       if [[ -z "$2" ]]; then
         echo "Error: --EXTRACTED_MARKER_OUT requires a value"
         exit 1
       fi
       EXTRACTED_MARKER_OUT="$2"
       refresh_configurations
       shift 2
       ;;
    --Input_seq)  # Set Input_seq directory
       if [[ -z "$2" ]]; then
         echo "Error: --Input_seq requires a value"
         exit 1
       fi
       Input_seq="$2"
       refresh_configurations
       shift 2
       ;;
    --CutValue)  # Set CutValue directory
       if [[ -z "$2" ]]; then
         echo "Error: --CutValue requires a value"
         exit 1
       fi
       CutValue="$2"
       refresh_configurations
       shift 2
       ;;
    --build)  # Run build script
       log_and_time "build" "$Log_DIR/$Logfile"
       shift
       ;;
    --extract)  # Run extract script
       log_and_time "extract" "$Log_DIR/$Logfile"
       shift
       ;;
    --reconstruct)  # Run reconstruct script
       log_and_time "reconstruct" "$Log_DIR/$Logfile"
       shift
       ;;
    --tree)  # Run tree script
       log_and_time "tree" "$Log_DIR/$Logfile"
       shift
       ;;
    --variables|--l)  # Display variables
       Variables
       shift
       ;;
    --rename_contigs|--K)  # Rename contigs
       rename_contigs
       shift
       ;;
    --make_files|--mk)  # Make files for all .fasta
       make_files
       shift
       ;;
    --help|-h|--h)  # Display help
       Help
       exit 0
       ;;
    *)  # Invalid option
       echo -e "${RED}Error: Invalid option ${RESET}$1"
       Wrong
       exit 1
       ;;
  esac
done

############################################################
#             Check & Display configuration                #
############################################################

Wrong
