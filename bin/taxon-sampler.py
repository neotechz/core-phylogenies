#!/usr/bin/env python3
"""
Program: Randomly sample k taxa from an alignment
------------------------------------------------------
Description:
    Reads one FASTA alignment (you may supply either the base name
    or full filename), randomly samples k unique taxon headers,
    and writes them—one per line—to the specified output file.

Supported extensions: .fasta, .fa, .fas, .fna

Usage:
    python sample_taxa.py <input_base_or_filename> <k> <output.txt>

Example:
    python sample_taxa.py cysl 5 taxa5.txt
    python sample_taxa.py cysl.fa 5 taxa5.txt
"""

import sys
import argparse
import random
from pathlib import Path
from Bio import SeqIO

# Supported FASTA extensions
EXTS = [".fasta", ".fa", ".fas", ".fna"]

def resolve_fasta_path(base):
    """
    Given a base name or filename, return the actual Path to an existing
    FASTA file by trying:
      1. Exact match
      2. Appending each supported extension
    """
    p = Path(base)
    if p.is_file():
        return p
    if p.suffix == "":
        for ext in EXTS:
            q = p.with_suffix(ext)
            if q.is_file():
                return q
    return None

def main():
    parser = argparse.ArgumentParser(
        description="Randomly sample k taxa headers from a FASTA alignment"
    )
    parser.add_argument("input_base", help="Base name or FASTA filename of the alignment")
    parser.add_argument("k", type=int, help="Number of taxa to sample (1 ≤ k ≤ total taxa)")
    parser.add_argument("output_txt", help="Output text file for sampled headers")
    args = parser.parse_args()

    # Locate the FASTA file
    fasta_path = resolve_fasta_path(args.input_base)
    if fasta_path is None:
        print(f"Error: no FASTA file found for '{args.input_base}'", file=sys.stderr)
        sys.exit(1)

    # Read all records
    try:
        records = list(SeqIO.parse(fasta_path, "fasta"))
    except Exception as e:
        print(f"Error reading alignment: {e}", file=sys.stderr)
        sys.exit(1)

    headers = [rec.id for rec in records]
    n = len(headers)
    if n == 0:
        print("Error: no records found in alignment", file=sys.stderr)
        sys.exit(1)
    if not (1 <= args.k <= n):
        print(f"Error: k must be between 1 and {n}", file=sys.stderr)
        sys.exit(1)

    # Sample without replacement
    sampled = random.sample(headers, args.k)

    # Write output
    try:
        with open(args.output_txt, "w") as out:
            for h in sampled:
                out.write(h + "\n")
    except Exception as e:
        print(f"Error writing output: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()