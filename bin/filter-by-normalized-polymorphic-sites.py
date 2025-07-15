#!/usr/bin/env python3
"""
Program #1: Filter genes by normalized number of polymorphic sites
------------------------------------------------------------------
Description:
- Filters aligned gene sequences based on polymorphic site rate (normalized to gene length).
- A polymorphic site is one where at least two non-gap, non-N nucleotides occur.
- Files with a normalized rate below a cutoff are excluded.

Input:
- Folder of FASTA gene alignments.

Output:
- Folder with alignments that pass the polymorphic site rate threshold.

Usage:
    python filter_polymorphic_sites.py input_folder/ output_folder/ 0.05
"""

import os
import sys
import argparse
from pathlib import Path
from Bio import AlignIO
from Bio.SeqRecord import SeqRecord
from Bio.Seq import Seq

def count_polymorphic_sites(alignment):
    """
    Count the number of polymorphic (variable) sites in a multiple sequence alignment.
    """
    num_sites = alignment.get_alignment_length()
    poly_count = 0

    for i in range(num_sites):
        column = alignment[:, i]
        bases = set(column.upper().replace("-", "").replace("N", ""))
        if len(bases) >= 2:
            poly_count += 1

    return poly_count, num_sites

def filter_alignments_by_normalized_polymorphism(input_folder, output_folder, min_normalized_rate):
    """
    Filter alignment files based on normalized polymorphic site rate (poly sites / gene length).
    """
    input_path = Path(input_folder)
    output_path = Path(output_folder)
    output_path.mkdir(parents=True, exist_ok=True)

    fasta_extensions = ['*.fasta', '*.fa', '*.fas', '*.fna']
    input_files = []

    for ext in fasta_extensions:
        input_files.extend(input_path.rglob(ext))
    input_files = sorted(set(input_files))

    if not input_files:
        print(f"No FASTA files found in {input_folder}")
        return

    kept, removed = 0, 0

    for file in input_files:
        try:
            alignment = AlignIO.read(file, "fasta")
            poly_sites, gene_length = count_polymorphic_sites(alignment)
            normalized_rate = poly_sites / gene_length if gene_length > 0 else 0

            print(f"{file.name} - Polymorphic sites: {poly_sites} | Length: {gene_length} | Rate: {normalized_rate:.4f}")

            if normalized_rate >= min_normalized_rate:
                relative_path = file.relative_to(input_path)
                out_file = output_path / relative_path
                out_file.parent.mkdir(parents=True, exist_ok=True)
                AlignIO.write(alignment, out_file, "fasta")
                print(f"  ✓ Kept (rate ≥ {min_normalized_rate})")
                kept += 1
            else:
                print(f"  ✗ Removed (rate < {min_normalized_rate})")
                removed += 1

        except Exception as e:
            print(f"Error processing {file.name}: {e}")
            continue

    print("\n" + "=" * 50)
    print("FILTER SUMMARY")
    print("=" * 50)
    print(f"Total files processed: {len(input_files)}")
    print(f"Files kept: {kept}")
    print(f"Files removed: {removed}")
    print(f"Retention rate: {(kept / len(input_files)) * 100:.1f}%")
    print(f"Filtered files saved to: {output_folder}")

def main():
    parser = argparse.ArgumentParser(
        description="Filter gene alignments by normalized polymorphic site rate"
    )
    parser.add_argument("input_folder", help="Folder containing input FASTA files")
    parser.add_argument("output_folder", help="Folder to save filtered FASTA files")
    parser.add_argument("min_normalized_rate", type=float, help="Minimum polymorphic site rate (e.g. 0.05 for 5%)")

    args = parser.parse_args()

    if not os.path.exists(args.input_folder):
        print(f"Error: Input folder '{args.input_folder}' does not exist")
        sys.exit(1)

    if args.min_normalized_rate < 0 or args.min_normalized_rate > 1:
        print("Error: Normalized polymorphic rate must be between 0 and 1")
        sys.exit(1)

    filter_alignments_by_normalized_polymorphism(
        args.input_folder,
        args.output_folder,
        args.min_normalized_rate
    )

if __name__ == "__main__":
    main()