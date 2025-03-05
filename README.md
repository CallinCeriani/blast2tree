# Blast2Tree
A Linux pipeline to quickly get genus-level identification for many genomes of uncertain classification at your chosen classification level.

Requires:
- a fasta file with your reference markers for each of the known species across your chosen classification level
- a single fasta file containing the best representation from the reference markers
- Assembled genomes 

#### Utilizes: 
- [blast](https://anaconda.org/bioconda/blast) 
- [bedtools](https://anaconda.org/bioconda/bedtools)
- [cap3](https://anaconda.org/bioconda/cap3)
- [bedtools](https://anaconda.org/bioconda/bedtools)
- [mafft](https://anaconda.org/bioconda/mafft)
- [trimal](https://anaconda.org/bioconda/trimal)
- [iqtree](https://anaconda.org/bioconda/iqtree)

## How to install
- [Download](https://github.com/CallinCeriani/Blast2Tree/archive/refs/tags/Versions.tar.gz)
- Install the conda environments with `conda env create -f Blast2Tree_environment.yml`
- set the script Blast2Tree.sh to path with `echo 'export PATH="$PATH:/path/to/blast2tree.sh"' >> ~/.bashrc && source ~/.bashrc`
- Add your genome files (either .fasta or .fna) to your folder containing the reference (.fa) and your markers (.fa)
- To get the help menu do `blast2tree.sh -h`

## Processing parameters

--threads|-t|--Cpus 
> Default = 2

--working_directory|--wd 
> Uses your current directory.

--s
>Run name and corresponding logfile output identifier.

--THRESHOLD
> This is the minimum length required for final processing to ensure quality through higher-length sequences. Sequences that are less than this value are removed from the final analysis (tree making) and are moved to a leftovers.fasta file

--MARKER_BLAST_ID
> Name of your gene marker e.g. ITS or BT 

--EXTRACTED_MARKER_OUT
> Name of the folder for the extracted sequences related to your marker e.g. Extracted_ITS or Extracted_BT

--Input_seq
> This fasta file contains the reference sequences at your specific taxonomic level.

--CutValue 
> This value is the minimum length you are willing to compare the gene you specified after extraction. Sequences above this Cutvalue will not be reconstructed. Therefore, knowing your expected sequence size (65% is good starting point) is important as the greater the length of the sequence the more resolution you will be able to achieve. 

## Analysis functions

--build
> Creates blastdb for each genome and does a blast search against your provided reference markers, thereafter, extracting the relevant hit sequences.

--extract
> This determines the longest hit in from your blast search and extracts it and any other shorter sequences related to the relative marker hit.

--reconstruct
> If sequences are bellow the --THRESHOLD value, this script attempts to reconstructs these markers over the separate contigs to imrpove their length. In addition, to filtering the relevant hits in preparation for --tree.

--tree
> This does alignment, trimming, and constructs the tree.

## Utility functions
--rename_contigs|--K
> Renames all .fasta contigs in a directory based on filename(s). Output is in the directory renamed_contigs. Built into --busco_batch.

--make_files|--mk
> Makes a folder for all .fasta's in a directory and moves them into their corresponding folder.
