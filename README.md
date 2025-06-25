# Blast2Tree

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg?style=flat)](https://bioconda.github.io/)

An experimental Linux pipeline optimized for haploid fungi, enabling rapid genus-level identification of multiple genomes with uncertain classification at a user-defined taxonomic level. Additionally, it extracts sequences of interest for manual review. Sequences should be single-copy and taxonomically informative.

**Requires:**
- Working conda or miniconda installation [miniconda](https://www.anaconda.com/download/success) (to make sure its update to date do `conda update -n base --all`)
- A fasta file (.fa) with your reference markers (headers in default NCBI format) for each of the known species across your chosen classification level (e.g. ITS.fa)
- A fasta file (.fa) containing a single sequence best representing the reference markers (i.e. the best hit marker after blast and extraction e.g. reference.fa)
- Assembled genomes in the .fasta or .fna format (e.g. isolate_100.fasta)

**Utilizes:**
- [blast](https://anaconda.org/bioconda/blast) 
- [bedtools](https://anaconda.org/bioconda/bedtools)
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
After which to view the results, load in your .treefile found in the Out file

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

Pre-align & trim|--Z
> Standardizes references markers before using them in blast search and downstream processing

Build|--A
> Creates blastdb for each genome and does a blast search against your genomes using your provided reference markers (e.g. ITS.fa). Thereafter, it extracts the relevant hit sequences.

Extract|--B
> This determines the longest hit from your blast search, and extracts it, and any other shorter sequences related to the relative marker that produced a hit. After extraction determine the marker that had the best hit for your data and add it to a file called reference.fa with a unique header e.g. >best hit

Reconstruct|--C
> If sequences are below the --THRESHOLD value, this script attempts to reconstruct these markers through overlapping sequences from separate contigs to improve their length. In addition, it filters the relevant hits in preparation for --tree. Recently added the ability to reconstruct markers that may not overlap or are of difference sense directionality

Tree|--D
> This does alignment, trimming, and construction of a standard phylogenetic tree.

## Utility functions
Rename contigs|--K
> Renames all the .fasta file's contigs in a directory, based on the filename(s). Output is in the directory renamed_contigs.

Make files|--M
> Makes a folder for all .fasta's in a directory based on their names and moves them into their corresponding folder.

### Disclaimer
Those markers which have been reconstructed and meet the minimum length for comparison are often skewed to that of the reference marker from which they are reconstructed and should likely be removed from your dataset going forward. The Docker container/version of the code is still in development.

## How to uninstall
> To remove enviroment `conda remove -n Blast2Tree --all` 
> To remove the pathing `nano ~/.bashrc`
> To remove the downloaded program e.g. `rm -rf /path/to/blast2tree-v0.0.1` 
