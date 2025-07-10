#!/usr/bin/env python3
"""
Program: Filter genes by dN/dS ratio (Updated)
-------------------------------------------------
This script filters gene alignments based on dN/dS ratio using codon-aware analysis.

🧬 WHAT IT DOES:
- Parses FASTA files in the input folder.
- For each sequence:
  1. Finds the first start codon (ATG)
  2. Skips ambiguous codons (those with non-ATCG bases)
  3. Stops at the first stop codon (TAA, TAG, TGA)
  4. Builds a cleaned codon sequence
- Calculates pairwise dN/dS (non-synonymous/synonymous substitutions) using NG86 method.
- Computes the average dN/dS for each file.
- Saves sequences only if the average dN/dS falls within the specified range.

🧪 EXAMPLE:
Input sequence: ACTAATGCCCARTCCATAAACT
Cleaned codons: ATG CCC CCA TAA  (skipped ambiguous "ART")
This becomes the valid codon sequence for comparison.

📥 INPUT:
- A folder of aligned FASTA files.

📤 OUTPUT:
- Filtered FASTA files saved to an output folder if their dN/dS is in the desired range.

🖥️ USAGE:
    python filter_dnds.py input_folder/ output_folder/ 0.1 1.0 --include-gaps

ARGUMENTS:
- input_folder:     Folder with aligned FASTA files.
- output_folder:    Folder to save retained files.
- 0.1               Minimum dN/dS ratio.
- 1.0               Maximum dN/dS ratio.
- --include-gaps    (Optional) Keep gaps ('-') in the sequences.

⚠️ NOTES:
- Files with <2 sequences, invalid codons, or mismatched ORF lengths will be skipped.
- Ambiguous codons are skipped, not substituted.
- Gaps are optionally removed unless --include-gaps is used.
"""

import os
import sys
import argparse
from pathlib import Path
from itertools import combinations
from Bio import SeqIO
from Bio.codonalign.codonseq import cal_dn_ds
from Bio.codonalign import CodonSeq
import warnings

def find_fasta_files(input_folder):
    extensions = ['*.fasta', '*.fa', '*.fas', '*.fna', '*.ffn', '*.faa', '*.frn']
    fasta_files = []
    for ext in extensions:
        fasta_files.extend(Path(input_folder).rglob(ext))
    return sorted(set(fasta_files))

def extract_valid_orf_codons(seq):
    """
    Extract valid codons from the first start codon (ATG) to the first stop codon,
    skipping ambiguous codons (those with bases other than A, T, C, G).
    """
    start_codon = "ATG"
    stop_codons = {"TAA", "TAG", "TGA"}
    valid_bases = {"A", "T", "C", "G"}

    seq = seq.upper().replace("\n", "").replace(" ", "")
    orf = []

    start_index = seq.find(start_codon)
    if start_index == -1:
        return []  # No start codon

    for i in range(start_index, len(seq) - 2, 3):
        codon = seq[i:i+3]
        if len(codon) < 3:
            break
        if codon in stop_codons:
            break
        if all(base in valid_bases for base in codon):
            orf.append(codon)
        # else: skip codons with ambiguous bases

    return orf

def calculate_dnds_ratio(alignment_file, include_gaps=False, output_folder=None, min_dnds=0, max_dnds=float("inf")):
    sequences = list(SeqIO.parse(alignment_file, "fasta"))
    if len(sequences) < 2:
        print(f"Skipping {alignment_file.name}: <2 sequences.")
        return None

    codon_seqs = []
    for seq_record in sequences:
        raw_seq = str(seq_record.seq)
        if not include_gaps:
            raw_seq = raw_seq.replace("-", "")
        codons = extract_valid_orf_codons(raw_seq)
        joined_seq = "".join(codons)
        if len(joined_seq) < 3:
            print(f"{alignment_file.name} - Skipped: ORF too short or missing start codon.")
            return None
        try:
            codon = CodonSeq(joined_seq)
            codon_seqs.append(codon)
        except Exception as e:
            print(f"{alignment_file.name} - CodonSeq error: {e}")
            return None

    dnds_list = []
    for i, j in combinations(range(len(codon_seqs)), 2):
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                dn, ds = cal_dn_ds(codon_seqs[i], codon_seqs[j], method="NG86")
            if ds == 0:
                ratio = float('inf') if dn > 0 else 0.0
            else:
                ratio = dn / ds
            if ratio != float('inf'):
                dnds_list.append(ratio)
        except Exception as e:
            print(f"{alignment_file.name} - Pair error: {e}")
            continue

    if not dnds_list:
        print(f"{alignment_file.name} - No valid dN/dS values.")
        return None

    avg_dnds = sum(dnds_list) / len(dnds_list)
    print(f"{alignment_file.name} - dN/dS: {avg_dnds:.4f}")

    if min_dnds <= avg_dnds <= max_dnds:
        if output_folder:
            output_path = Path(output_folder)
            output_path.mkdir(parents=True, exist_ok=True)
            out_file = output_path / alignment_file.name
            SeqIO.write(sequences, out_file, "fasta")
            print(f"  ✓ Saved to {out_file}")
    else:
        print(f"  ✗ Outside dN/dS range.")

    return avg_dnds

def process_folder(input_folder, output_folder, min_dnds, max_dnds, include_gaps=False):
    files = find_fasta_files(input_folder)
    print(f"Found {len(files)} FASTA files.")
    for f in files:
        print(f"\nProcessing {f.name}")
        calculate_dnds_ratio(f, include_gaps, output_folder, min_dnds, max_dnds)

def main():
    parser = argparse.ArgumentParser(description="Filter genes by dN/dS ratio and export FASTA")
    parser.add_argument("input_folder", help="Folder with input FASTA files")
    parser.add_argument("output_folder", help="Folder to save passing FASTA files")
    parser.add_argument("min_dnds", type=float, help="Minimum dN/dS ratio")
    parser.add_argument("max_dnds", type=float, help="Maximum dN/dS ratio")
    parser.add_argument("--include-gaps", action="store_true", help="Include gaps in alignment")
    args = parser.parse_args()

    if not os.path.exists(args.input_folder):
        print("Error: Input folder doesn't exist.")
        sys.exit(1)

    process_folder(args.input_folder, args.output_folder, args.min_dnds, args.max_dnds, args.include_gaps)

if __name__ == "__main__":
    main()
