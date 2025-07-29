#!/usr/bin/env python3
"""
Program: Filter an alignment to only the taxa in a header list
---------------------------------------------------------------------
Input:
    1) A text file of k headers (one per line)
    2) Base name or FASTA filename of an alignment (supports .fasta, .fa, .fas, .fna)

Output:
    A FASTA alignment file containing only those records whose headers
    appear in the header list (order preserved).

Usage:
    python filter_by_taxa_list.py <headers.txt> <alignment_base_or_filename> <filtered.fasta>
"""

import sys
import argparse
from pathlib import Path
from Bio import SeqIO

# Supported FASTA extensions
EXTS = [".fasta", ".fa", ".fas", ".fna"]

def resolve_fasta_path(base):
    """
    Resolve a base name or filename to an actual FASTA file on disk.
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
    p = argparse.ArgumentParser(
        description="Filter FASTA alignment to only headers in a text list"
    )
    p.add_argument("headers_txt", help="Text file with one header per line")
    p.add_argument("alignment_base", help="Base name or FASTA filename of the alignment")
    p.add_argument("output_fasta", help="Output FASTA file for filtered records")
    args = p.parse_args()

    # Load header set
    try:
        with open(args.headers_txt) as f:
            wanted = {line.strip() for line in f if line.strip()}
    except Exception as e:
        print(f"Error reading headers file: {e}", file=sys.stderr)
        sys.exit(1)
    if not wanted:
        print("Error: no headers found in list", file=sys.stderr)
        sys.exit(1)

    # Resolve the alignment path
    aln_path = resolve_fasta_path(args.alignment_base)
    if aln_path is None:
        print(f"Error: no FASTA file found for '{args.alignment_base}'", file=sys.stderr)
        sys.exit(1)

    # Parse and filter
    try:
        records = SeqIO.parse(aln_path, "fasta")
    except Exception as e:
        print(f"Error reading alignment: {e}", file=sys.stderr)
        sys.exit(1)

    filtered = (rec for rec in records if rec.id in wanted)

    # Write output
    try:
        SeqIO.write(filtered, args.output_fasta, "fasta")
    except Exception as e:
        print(f"Error writing filtered alignment: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()