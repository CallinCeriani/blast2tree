#!/usr/bin/env python3

import sys
from Bio import SeqIO
from Bio.Seq import Seq
import subprocess

if len(sys.argv) != 4:
    print("Usage: scaffold_with_gaps.py <reference.fasta> <fragments.fasta> <output.fasta>")
    sys.exit(1)

REFERENCE = sys.argv[1]
FRAGMENTS = sys.argv[2]
OUTPUT = sys.argv[3]
BLAST_OUTPUT = "blast_results.tsv"
LOG_FILE = "scaffold_log.txt"
GAP_CHAR = "N"

# Step 1: Run BLAST
subprocess.run(["makeblastdb", "-in", REFERENCE, "-dbtype", "nucl"], check=True)
subprocess.run([
    "blastn", "-query", FRAGMENTS, "-db", REFERENCE,
    "-outfmt", "6 qseqid sstart send sstrand",
    "-max_target_seqs", "1", "-max_hsps", "1",
    "-out", BLAST_OUTPUT
], check=True)

# Step 2: Parse BLAST hits
hits = []
with open(BLAST_OUTPUT) as f:
    for line in f:
        parts = line.strip().split()
        if len(parts) != 4:
            continue
        qid, sstart, send, strand = parts
        sstart, send = int(sstart), int(send)
        hits.append((qid, sstart, send, strand))

# Optional strict strand enforcement
# strands_seen = {strand for _, _, _, strand in hits}
# if len(strands_seen) > 1:
#     print("Error: mixed strand directions detected. Skipping scaffold.")
#     sys.exit(1)

# Step 3: Load sequences
seqs = {rec.id: rec.seq for rec in SeqIO.parse(FRAGMENTS, "fasta")}

# Step 4: Sort hits by actual start coordinate
hits.sort(key=lambda x: min(x[1], x[2]))

# Step 5: Build scaffold
scaffold = ""
prev_end = None
seen = set()

with open(LOG_FILE, "w") as log:
    for qid, sstart, send, strand in hits:
        if qid in seen:
            log.write(f"{qid}: skipped duplicate\n")
            continue
        seen.add(qid)

        start, end = sorted([sstart, send])  # for gap calculation

        # Get sequence and apply strand logic
        if qid not in seqs:
            log.write(f"{qid}: missing in fragment FASTA\n")
            continue

        seq = seqs[qid]
        if len(seq) < 20:
            log.write(f"{qid}: skipped (short sequence: {len(seq)} bp)\n")
            continue

        if strand == "minus":
            seq = seq.reverse_complement()
            log.write(f"{qid}: reverse strand, length={len(seq)}\n")
        else:
            log.write(f"{qid}: forward strand, length={len(seq)}\n")

        # Insert gap if needed
        if prev_end is not None and start > prev_end:
            gap_size = start - prev_end
            scaffold += GAP_CHAR * gap_size
            log.write(f"Inserted {gap_size} Ns between fragments\n")

        scaffold += str(seq)
        prev_end = end

# Step 6: Write output
with open(OUTPUT, "w") as out:
    out.write(">Scaffolded_gene\n")
    out.write(scaffold + "\n")
