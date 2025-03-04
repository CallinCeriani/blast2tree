# Blast2Tree
A pipeline to quickly get species identification for genomes.

# How to use
-
-
-

# How to install
- Download
- Install Conda env
- set Blast2Tree.sh to path
- Referenca.fa amd Marker.fa

# Processing parameters

--threads|-t|--Cpus 
default = 1

--working_directory|--wd 
default = uses your current directory. $PWD

--s
default = None. Run name and named logfile.

--THRESHOLD
default = 300

--MARKER_BLAST_ID
default = ITS_Marker

--EXTRACTED_MARKER_OUT
default = extracted_sequences_ITS

--Input_seq
default = ITS.fa

--CutValue
default = 500

# Analysis functions

--build
(Utilizes: [blast](https://anaconda.org/bioconda/blast) and [bedtools](https://anaconda.org/bioconda/bedtools)) Creates blastdb for each genome and does blast search against your provided reference markers, thereafter, extracting the relevant hit sequences.

--extract
(Utilizes: Custom script) This determines the longest hit in .bed file and extracts it.

--reconstruct
(Utilizes: [cap3](https://anaconda.org/bioconda/cap3) and [bedtools](https://anaconda.org/bioconda/bedtools)) Reconstructs marker over separate contigs and adds to marker file in prep for --tree. Requires reference.fa in $Working_Directory.

--tree
(Utilizes: [muscle](https://anaconda.org/bioconda/mafft), [trimal](https://anaconda.org/bioconda/trimal), and [iqtree](https://anaconda.org/bioconda/iqtree)) This does alignment, trimming, and constructs the tree.

# Utility functions

--variables|--l
Display BUSCO, Augustus and NCBI taxonomic ID options or databases.

--rename_contigs|--K
Renames all .fasta contigs in a directory based on filename(s). Output is in the directory renamed_contigs. Built into --busco_batch.

--make_files|--mk
Makes a folder for all .fasta's in a directory and moves them into their corresponding folder.
