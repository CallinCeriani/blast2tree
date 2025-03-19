# Blast2Tree

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](https://bioconda.github.io/)

An experimental Linux pipeline designed around haploid fungi to quickly get genus-level identification for many genomes that have been sampled of uncertain classification at your chosen classification level. In addition, sequences of interest are generated for manual perusal. Ideally, targeted sequences are single-copy taxonomic-informative markers.

**Requires:**
- Working conda or miniconda installation [miniconda](https://www.anaconda.com/download/success) (to make sure its update to date do `conda update -n base --all`)
- A fasta file with your reference markers for each of the known species across your chosen classification level
- A single fasta file containing the best representation from the reference markers
- Assembled genomes in the .fasta or .fna format

**Utilizes:**
- [blast](https://anaconda.org/bioconda/blast) 
- [bedtools](https://anaconda.org/bioconda/bedtools)
- [cap3](https://anaconda.org/bioconda/cap3)
- [mafft](https://anaconda.org/bioconda/mafft)
- [trimal](https://anaconda.org/bioconda/trimal)
- [iqtree](https://anaconda.org/bioconda/iqtree)
- [GNU Parallel](https://anaconda.org/conda-forge/parallel)

## How to install
1) [Download](https://github.com/CallinCeriani/blast2tree/releases)
2) Install the conda environment with
```
conda env create -f /path/to/download/blast2tree_environment.yml
```
3) Set the script blast2tree.sh to path with
```
echo 'export PATH="$PATH:/path/to/script/dir"' >> ~/.bashrc && source ~/.bashrc
```
followed by
```
chmod +x /path/to/blast2tree.sh
```

**To run:**
- Add your genome files (either .fasta or .fna) to a folder containing a file for the reference (.fa) and the markers (.fa)
  
- Then do
```
conda activate Blast2Tree
```
  
- To get the help menu do
```
blast2tree.sh -h
```

- To view your phylogenetic tree activate the conda environment and do
```
figtree
```
After which to view the results, load in your .treefile found in the --MARKER_BLAST_ID /dir/ that was set

## Processing parameters

Threads|-t
> Default = 2

Working directory|--wd 
> Uses your current directory as the expected working directory.

Run name|--s
> Run name and corresponding logfile output identifier.

--MARKER_NAME
> Name of your gene marker e.g. ITS or BT

--Input_seq
> This fasta file contains the reference sequences at your specific taxonomic level. e.g. ITS.fa

--CutValue 
> This value is the minimum length you are willing to compare the genes you specified after extraction. Sequences above this Cutvalue will not be reconstructed. Therefore, knowing your expected sequence size (65% is good starting point) is important as the greater the length of the sequence the more resolution you will be able to achieve.

 --THRESHOLD
> This is the minimum length required for final processing to ensure quality through higher-length sequences. Sequences that are less than this value are removed from the final analysis (tree making process) and are moved to a leftovers.fasta file

## Analysis functions

Build|--A
> Creates blastdb for each genome and does a blast search against your provided reference markers, thereafter, extracting the relevant hit sequences.
> `-evalue 1e-10 -gapopen 5 -gapextend 2 -perc_identity 89 -qcov_hsp_perc 20 -max_target_seqs 5 -word_size 7`

Extract|--B
> This determines the longest hit in from your blast search and extracts it and any other shorter sequences related to the relative marker that produced the longest hit.

Reconstruct|--C
> If sequences are below the --THRESHOLD value, this script attempts to reconstructs these markers over the separate contigs to improve their length. In addition, to filtering the relevant hits in preparation for --tree.
> `cap3 -m 60 -p 75 -g 1`

Tree|--D
> This does alignment, trimming, and constructs the tree.
>`mafft --adjustdirectionaccurately --auto`
> `trimal -automated1`
> `iqtree2 -m MFP -bb 1000 -alrt 1000` 

## Utility functions
Rename contigs|--K
> Renames all the .fasta file's contigs in a directory, based on the filename(s). Output is in the directory renamed_contigs.

Make files|--M
> Makes a folder for all .fasta's in a directory based on their names and moves them into their corresponding folder.

### Disclaimer
Those markers which have been reconstructed and meet the minimum length for comparison are often skewed to that of the reference marker from which they are reconstructed.

## How to uninstall
conda remove -n Blast2Tree --all
edit ~/.bashrc and remove set path
