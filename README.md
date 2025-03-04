# Blast2Tree
A linux pipeline to quickly get genus identification for many genomes of unknown classification.
- Requires a fasta file with reference markers for each of the species at your chosen classification level
- a single fasta file containing the best representation from the reference markers
- 

## How to install
- [Download](https://github.com/CallinCeriani/Blast2Tree/archive/refs/tags/Versions.tar.gz)
- Install with `conda env create -f Blast2Tree_environment.yml`
- set Blast2Tree.sh to path
- Referenca.fa amd Marker.fa

## Processing parameters

--threads|-t|--Cpus 
Default = 2

--working_directory|--wd 
Uses your current directory. $PWD

--s
Run name and corresponding logfile ID.

--THRESHOLD
This is the minimum length required for final processing. Sequence still not making this value are removed from analysis and are moved to a leftovers.fasta file

--MARKER_BLAST_ID

--EXTRACTED_MARKER_OUT

--Input_seq
This is the fasta file containing your reference sequences at your specific taxonomic level and gene.

--CutValue 
This value is the minimum length you are willing to compare the gene you specified after extraction. Sequences above this Cutvalue will not be reconstructed. Therefore, knowing your expected sequence size (65% is good starting point) is important as the greater the length of the sequence the more resolution. 

## Analysis functions
Utilizes: 
- [blast](https://anaconda.org/bioconda/blast) 
- [bedtools](https://anaconda.org/bioconda/bedtools)
- [cap3](https://anaconda.org/bioconda/cap3)
- [bedtools](https://anaconda.org/bioconda/bedtools)
- [mafft](https://anaconda.org/bioconda/mafft)
- [trimal](https://anaconda.org/bioconda/trimal)
- [iqtree](https://anaconda.org/bioconda/iqtree)

--build
Creates blastdb for each genome and does blast search against your provided reference markers, thereafter, extracting the relevant hit sequences.

--extract
This determines the longest hit in .bed file and extracts it.

--reconstruct
Reconstructs marker over separate contigs and adds to marker file in prep for --tree. Requires reference.fa in $Working_Directory.

--tree
This does alignment, trimming, and constructs the tree.

## Utility functions

--variables|--l
Display BUSCO, Augustus and NCBI taxonomic ID options or databases.

--rename_contigs|--K
Renames all .fasta contigs in a directory based on filename(s). Output is in the directory renamed_contigs. Built into --busco_batch.

--make_files|--mk
Makes a folder for all .fasta's in a directory and moves them into their corresponding folder.
