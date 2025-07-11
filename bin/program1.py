#!/usr/bin/env python3
"""
Program #1: Filter genes by number of polymorphic sites
--------------------------------------------------------
Description:
- Filters aligned gene sequences based on the number of polymorphic sites.
- A polymorphic site is one where at least two non-gap, non-identical nucleotides occur.
- Files with fewer than K polymorphic sites are excluded.

Input:
- Folder of FASTA gene alignments.

Output:
- Folder with alignments that pass the polymorphic site threshold.

Usage:
    python filter_polymorphic_sites.py input_folder/ output_folder/ 10
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

    return poly_count

def filter_alignments_by_polymorphic_sites(input_folder, output_folder, min_polymorphic_sites):
    """
    Process and filter each alignment file based on polymorphic site count.
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
            poly_sites = count_polymorphic_sites(alignment)
            print(f"{file.name} - Polymorphic sites: {poly_sites}")

            if poly_sites >= min_polymorphic_sites:
                relative_path = file.relative_to(input_path)
                out_file = output_path / relative_path
                out_file.parent.mkdir(parents=True, exist_ok=True)
                AlignIO.write(alignment, out_file, "fasta")
                print(f"  ✓ Kept (≥ {min_polymorphic_sites} sites)")
                kept += 1
            else:
                print(f"  ✗ Removed (< {min_polymorphic_sites} sites)")
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
        description="Filter gene alignments by number of polymorphic sites"
    )
    parser.add_argument("input_folder", help="Folder containing input FASTA files")
    parser.add_argument("output_folder", help="Folder to save filtered FASTA files")
    parser.add_argument("min_polymorphic_sites", type=int, help="Minimum number of polymorphic sites required")

    args = parser.parse_args()

    if not os.path.exists(args.input_folder):
        print(f"Error: Input folder '{args.input_folder}' does not exist")
        sys.exit(1)

    filter_alignments_by_polymorphic_sites(
        args.input_folder,
        args.output_folder,
        args.min_polymorphic_sites
    )

if __name__ == "__main__":
    main()