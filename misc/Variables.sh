#!/bin/bash

function Variables()
{
   echo "Now grabbing busco & augustus lineages!"
   cd "$Working_Directory" || exit

   directories=( "$datasets" )

   for dir in "${directories[@]}"; do
       if [ ! -d "$dir" ]; then
           mkdir -p "$dir"  # Use -p to create parent directories if needed
           echo "Directory '$dir' created."
       else
           echo "Directory '$dir' already exists. Continuing..."
       fi
   done

   ls "$Busco_lineages" > "$datasets/Busco_db.txt"
   ls "$Augustus_species_config" > "$datasets/Augustus_species.txt"

   # Declare associative array of species and their Taxonomic IDs
   declare -A species_taxa=(
       ["Fusarium circinatum"]="48490"
       ["Chrysoporthe austroafricanus"]="354353"
       ["Chrysoporthe puriensis"]="2029752"
       ["Chrysoporthe cubensis"]="305400"
       ["Chrysoporthe syzgiicola"]="671139"
       ["Chrysoporthe zambiensis"]="671140"
       ["Chrysoporthe deuterocubensis"]="764597"
       ["Sclerotinia sclerotiorum"]="665079"
       ["Ganoderma resinaceum"]="34465"
       ["Ganoderma boninense"]="34458"
       ["Armillaria mellea"]="47429"
   )

   # Define output file for species and Taxonomic IDs
   tax_id_file="$datasets/Species_Taxonomic_IDs.txt"

   # Remove the file if it exists and create a new one
   > "$tax_id_file"

   echo "Here are the Taxonomic IDs for the following species (as per NCBI):" > "$tax_id_file"

   # Loop through ordered list and print each species with its Taxonomic ID
   for species in "${!species_taxa[@]}"; do
       printf "%s = %s\n" "$species" "${species_taxa[$species]}" >> "$tax_id_file"
   done

   echo "Done"
}
