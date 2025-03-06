#!/bin/bash

function show_progress() {
    local progress=$1
    local total=$2

    # Get the width of the terminal
    local terminal_width=$(tput cols)
    local text_length=15  # Adjust for text like "Progress: [  ] %"
    local bar_length=$((terminal_width - text_length - 3))  # 3 for spaces around the bar

    # Calculate the progress percentage and lengths
    local percent=$(( (progress * 100) / total ))
    local filled_length=$(( (bar_length * progress) / total ))
    local empty_length=$(( bar_length - filled_length ))

    # Ensure we don't go beyond terminal width
    if [ $empty_length -lt 0 ]; then
        filled_length=$(( bar_length + empty_length ))
        empty_length=0
    fi

    # ANSI color codes
    local green="\033[0;32m"
    local red="\033[0;31m"
    local reset="\033[0m"

    # Print the progress bar
    printf "\rProgress: ["
    printf "${green}%${filled_length}s" | tr ' ' '#'
    printf "${red}%${empty_length}s" | tr ' ' '-'
    printf "${reset}] %2d%%" $percent
}
