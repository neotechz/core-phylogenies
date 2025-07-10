#!/usr/bin/env python3
"""
Program #4: Concatenate all remaining gene alignments

Description:
    - Concatenates gene alignments into a single alignment
    - Ensures that only common organism headers (IDs) are included
    - Maintains consistent organism order across genes

Input:
    Folder of (n) filtered gene alignments (FASTA format)

Output:
    Single concatenated alignment in FASTA format

Usage:
    python concatenate_alignments.py input_folder/ output_file.fasta
"""

import os
import sys
from pathlib import Path
from Bio import AlignIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
from collections import defaultdict
from Bio import SeqIO

def concatenate_alignments(input_folder: str, output_file: str):
    # Step 1: Gather all FASTA files
    input_path = Path(input_folder)
    fasta_extensions = ['*.fasta', '*.fa', '*.fas', '*.fna']
    input_files = []

    for ext in fasta_extensions:
        input_files.extend(input_path.rglob(ext))
    input_files = sorted(set(input_files))

    if not input_files:
        print(f"No FASTA files found in {input_folder}")
        return

    # Step 2: Build organism-wise sequence storage
    sequence_dict = defaultdict(list)
    common_headers = None
    file_count = 0

    for file in input_files:
        try:
            alignment = AlignIO.read(file, "fasta")
        except Exception as e:
            print(f"Skipping {file.name}: {e}")
            continue

        headers = [record.id for record in alignment]

        if common_headers is None:
            common_headers = set(headers)
        else:
            common_headers &= set(headers)

        for record in alignment:
            if record.id in common_headers:
                sequence_dict[record.id].append(str(record.seq).upper())
        file_count += 1

    if not common_headers:
        print("❌ No common organism headers found across all alignments.")
        return

    print(f"✓ Found {file_count} valid alignment files.")
    print(f"✓ Common organism headers: {len(common_headers)}")

    # Step 3: Concatenate sequences for each organism
    concatenated_records = []
    for organism in sorted(common_headers):
        full_seq = "".join(sequence_dict[organism])
        concatenated_records.append(SeqRecord(Seq(full_seq), id=organism, description=""))

    # Step 4: Write to output file
    SeqIO.write(concatenated_records, output_file, "fasta")
    print(f"\n✅ Concatenated alignment written to: {output_file}")
    print(f"Total concatenated organisms: {len(concatenated_records)}")
    print(f"Total alignment length: {len(concatenated_records[0].seq)} bases")

def main():
    import argparse
    parser = argparse.ArgumentParser(
        description="Concatenate multiple gene alignments into a single alignment"
    )
    parser.add_argument("input_folder", help="Folder containing FASTA gene alignments")
    parser.add_argument("output_file", help="Output FASTA file for concatenated alignment")
    args = parser.parse_args()

    if not os.path.exists(args.input_folder):
        print(f"Error: Input folder '{args.input_folder}' does not exist.")
        sys.exit(1)

    concatenate_alignments(args.input_folder, args.output_file)

if __name__ == "__main__":
    main()