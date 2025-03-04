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

# Unnamed title
----------------------------- Processing parameters -----------------------------

 --threads|-t|--Cpus                  default = 1
 --working_directory|--wd             default = uses your current directory. /home/ldapusers/callin.ceriani/Documents/Fasta_new
 --Run_name|--s                       default = None. Run name and named logfile.
 --species_name|--sp                  default = None. Do use underscores for space, e.g. Genus_species or Aspergillus_fumigatus
 --busco_taxon|-busco|--busco         default = sordariomycetes_odb10. Do sentral --l to get the options
 --augustus_species|--augustus        default = fusarium_graminearum. Do sentral --l to get the options
 --reference_fasta|--ref_fa           default = Fusarium circinatum. Set /path/to/your/reference.fasta. Check the reference genomes in your home dir.
 --reference_gff3|--ref_gf3           default = Fusarium circinatum. Set /path/to/your/reference.gff3
 --THRESHOLD                          default = 300
 --MARKER_BLAST_ID                    default = ITS_Marker
 --EXTRACTED_MARKER_OUT               default = extracted_sequences_ITS
 --Input_seq                          default = ITS.fa
 --CutValue                           default = 500

------------------------------- Analysis functions ------------------------------

 --build               (Utilizes: blast-v2.16.0, bedtools-v2.31.1. Create blastdb for genome and  blast search our reference markers, whiling extracting sequences.
 --extract             (Utilizes: Custom script. This determines the longest hit in .bed file and extracts it.
 --reconstruct         (Utilizes: cap3_env, bedtools-v2.31.1. Reconstructs marker over separate contigs and adds to marker file in prep for --tree. Requires reference.fa in /home/ldapusers/callin.ceriani/Documents/Fasta_new.
 --tree                (Utilizes: muscle-v5.3, trimal-v1.5.0, iqtree2-v2.3.6. This does alignment, trimming and constructs the tree.
 --busco_batch|-U|--U  (Utilizes: seqkit-v2.8.2, busco-v5.8.2, quast-v5.2.0. Processes all fastas in a dir does --rename_contigs & requires --reference_fasta, --busco_taxon, and --augustus_species)
 --phylo|--P           (Utilizes: BUSCO_phylogenomics is a custom script that produces gene-tree and supermatrix files. Requires --busco_batch before proceeding)

------------------------------- Utility functions -------------------------------

 --variables|--l                      Display BUSCO, Augustus and NCBI taxonomic ID options or databases
 --rename_contigs|--K                 Renames all .fasta contigs in a directory based on filename(s). output is in the directory renamed_contigs. Built into --busco_batch
 --make_files|--mk                    Makes a folder for all .fasta's in a directory and moves them into their corresponding folder
