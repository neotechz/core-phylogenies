#!/usr/bin/env python3
"""
Program: Single‐Alignment Polymorphic‐Site Rate Pass/Fail
--------------------------------------------------------
Description:
    Reads one FASTA alignment and computes its polymorphic‐site rate,
    defined as (# polymorphic sites) / (alignment length).
    A polymorphic site is a column with ≥2 distinct non‐gap, non‐N bases.
    Prints "TRUE" if rate ≥ min_rate, else "FALSE".

Input:
    - One FASTA alignment file containing ≥1 sequence.

Output:
    - Writes exactly one line to stdout: "TRUE" or "FALSE".

Key steps:
 1. Load the alignment via Biopython’s AlignIO.
 2. Count polymorphic sites: for each column, strip '-' and 'N'; if ≥2 distinct bases remain, it’s polymorphic.
 3. Compute rate = polymorphic_sites / total_columns.
 4. Print TRUE if rate ≥ min_rate; otherwise FALSE.

Usage:
    python filter_polymorphic_rate_passfail.py <input_fasta> <min_rate>

Example:
    python filter_polymorphic_rate_passfail.py gene1.fasta 0.10
"""

import sys
import argparse
from Bio import AlignIO

def compute_polymorphic_rate(alignment):
    """Return (polymorphic_site_count, total_columns)."""
    length = alignment.get_alignment_length()
    poly = 0
    for i in range(length):
        col = alignment[:, i].upper()
        bases = set(col.replace('-', '').replace('N', ''))
        if len(bases) >= 2:
            poly += 1
    return poly, length

def main():
    p = argparse.ArgumentParser(
        description="Print TRUE/FALSE if alignment polymorphic‐site rate passes threshold"
    )
    p.add_argument("input_fasta", help="Input FASTA alignment file")
    p.add_argument("min_rate", type=float, help="Minimum polymorphic‐site rate (0–1)")
    args = p.parse_args()

    try:
        aln = AlignIO.read(args.input_fasta, "fasta")
    except Exception:
        print("FALSE")
        return

    poly, length = compute_polymorphic_rate(aln)
    rate = poly / length if length > 0 else 0.0

    if rate >= args.min_rate:
        print("TRUE")
    else:
        print("FALSE")

if __name__ == "__main__":
    main()