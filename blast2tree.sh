#!/bin/bash
# Determine the script's directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  echo -e " Threads|-t|--Cpus               default = 2" 
  echo -e " Jobs|--jobs                     default = 2"
  echo -e " Working directory|--wd          default = uses your current directory. $PWD"
  echo -e " Run name|--s                    default = None. Run name and named logfile."
  echo -e " --THRESHOLD                     default = 300. Ninimum length required for final processing - less than this value are removed - moved to a leftovers.fasta file"
  echo -e " --MARKER_NAME                   defualt = ITS"
  echo -e " --Input_seq                     default = ITS.fa" 
  echo -e " --CutValue                      default = 450. minimum length  to compare the gene you specified - Sequences above this Cutvalue will not be reconstructed" 
  echo
  echo -e "${BLUE}------------------------------- Phylogenetic functions ------------------------------${RESET}"
  echo
  echo -e " Build|--A                      (Utilizes: ${GREEN}$blast, $bedtools.${RESET} Requires --K. Creates blast_db for genomes, blasting and extracting the relevant hit."
  echo -e " Extract|--B                    (Utilizes: ${GREEN}Custom script.${RESET} Requires --build. This determines the longest hit in .bed file and extracts it." 
  echo -e " Reconstruct|--C                (Utilizes: ${GREEN}$cap3, $bedtools.${RESET} Requires --extract. Reconstructs marker over separate contigs. Requires reference.fa and marker.fa."
  echo -e " Tree|--D                       (Utilizes: ${GREEN}$muscle, $trimal, $iqtree.${RESET} Requires --reconstruct. This does alignment, trimming and constructs the tree."
  echo 
  echo -e "${BLUE}------------------------------- Utility functions -------------------------------${RESET}"
  echo
  echo -e " Rename contigs|--K             Renames all .fasta contigs in a directory based on filename(s). output is in the directory renamed_contigs."
  echo -e " Make files|--M                 Makes a folder for all .fasta's in a directory and moves them into their corresponding folder"
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
MAIN_CONF="${SCRIPT_DIR}/config/main.conf"

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

# Function to re-source configuration files after updating variables
refresh_configurations() {
  #echo -e "${GREEN}Refreshing configurations with updated values...${RESET}"
  source_main_conf
  source_files_in_dir "${SCRIPT_DIR}/config" "conf" "No configuration files found in ${SCRIPT_DIR}/config"
  source_files_in_dir "${SCRIPT_DIR}/lib/phylogenetics" "sh" "No scripts found in ${SCRIPT_DIR}/lib"
  source_files_in_dir "${SCRIPT_DIR}/misc" "sh" "No scripts found in ${SCRIPT_DIR}/misc"
}

# Source the main configuration file
source_main_conf
# Source scripts from config/, lib/ and misc/ directories (CHANGED: use SCRIPT_DIR)
source_files_in_dir "${SCRIPT_DIR}/config" "conf" "No configuration files found in ${SCRIPT_DIR}/config"
source_files_in_dir "${SCRIPT_DIR}/lib/phylogenetics" "sh" "No scripts found in ${SCRIPT_DIR}/lib"
source_files_in_dir "${SCRIPT_DIR}/misc" "sh" "No scripts found in ${SCRIPT_DIR}/misc"

# Default values for new options
  Cpus=2
  jobs=2
  Working_Directory="$PWD"
  Input_name=""
  THRESHOLD=300                                    
  MARKER_NAME=""
  Input_seq=""
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
    -t)  # Set number of threads
       if [[ -z "$2" ]]; then
         echo "Error: -t requires a value"
         exit 1
       fi
       Cpus="$2"
       refresh_configurations
       shift 2
       ;;
    --jobs)  # Set number of Jobs
       if [[ -z "$2" ]]; then
         echo "Error: --jobs requires a value"
         exit 1
       fi
       jobs="$2"
       refresh_configurations
       shift 2
       ;;
    --wd)  # Set directory path
       if [[ -z "$2" ]]; then
         echo "Error: --wd requires a value"
         exit 1
       fi
       Working_Directory="$2"
       refresh_configurations
       shift 2
       ;;
    --s)  # Set sample name
       if [[ -z "$2" ]]; then
         echo "Error: --s requires a value"
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
    --A)  # Run build script
       log_and_time "build" "$Log_DIR/$Logfile"
       shift
       ;;
    --B)  # Run extract script
       log_and_time "extract" "$Log_DIR/$Logfile"
       shift
       ;;
    --C)  # Run reconstruct script
       log_and_time "reconstruct" "$Log_DIR/$Logfile"
       shift
       ;;
    --D)  # Run tree script
       log_and_time "tree" "$Log_DIR/$Logfile"
       shift
       ;;
    --K)  # Rename contigs
       rename_contigs
       shift
       ;;
    --M)  # Make files for all .fasta
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
