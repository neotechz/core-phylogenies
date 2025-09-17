#!/usr/bin/env python3
"""
Program: Single‐Alignment Nucleotide Diversity (Pass/Fail)
------------------------------------------------------
Description:
    Reads one FASTA alignment and computes its nucleotide diversity (π),
    defined as the average pairwise Hamming distance per site.
    Prints "TRUE" if π ∈ [min_diversity, max_diversity]; otherwise "FALSE".

Usage:
    python filter_diversity_passfail.py <input_fasta> <min_diversity> <max_diversity> [--include-gaps]
"""

import argparse
from Bio import SeqIO
import numpy as np
from itertools import combinations

def calculate_nucleotide_diversity(seqs, ignore_gaps):
    m = len(seqs)
    if m < 2:
        return None
    arr = np.array(seqs, dtype='<U1')
    _, L = arr.shape
    pair_divs = []
    for i, j in combinations(range(m), 2):
        a, b = arr[i], arr[j]
        if ignore_gaps:
            mask = (a != '-') & (b != '-')
            comp = int(mask.sum())
            if comp == 0:
                continue
            mismatches = int((a[mask] != b[mask]).sum())
        else:
            comp = L
            mismatches = int((a != b).sum())
        pair_divs.append(mismatches / comp)
    return float(np.mean(pair_divs)) if pair_divs else 0.0

def main():
    p = argparse.ArgumentParser(
        description="Print TRUE/FALSE if alignment nucleotide diversity (π) passes threshold"
    )
    p.add_argument("input_fasta", help="Input FASTA alignment file")
    p.add_argument("min_diversity", type=float, help="Minimum π (inclusive)")
    p.add_argument("max_diversity", type=float, help="Maximum π (inclusive)")
    p.add_argument("--include-gaps", action="store_true",
                   help="Include gaps in diversity calculation")
    args = p.parse_args()

    try:
        seqs = [list(str(rec.seq).upper()) for rec in SeqIO.parse(args.input_fasta, "fasta")]
    except Exception:
        print("FALSE")
        return

    pi = calculate_nucleotide_diversity(seqs, ignore_gaps=not args.include_gaps)
    within_range:bool = pi is not None and args.min_diversity <= pi <= args.max_diversity
    if within_range:
        print("TRUE")
    else:
        print("FALSE")

    log_path = args.input_fasta + ".log"
    with open(log_path, 'w') as log_file:
        log_file.write(f"π: {pi}\n")
        log_file.write(f"Min: {args.min_diversity}, Max: {args.max_diversity}\n")
        log_file.write("Result: " + ("TRUE" if within_range else "FALSE") + "\n")

if __name__ == "__main__":
    main()