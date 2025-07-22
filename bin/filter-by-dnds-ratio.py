#!/usr/bin/env python3
"""
Program: Single‐Alignment dN/dS Pass/Fail
-------------------------------------------------
Description:
    Reads one FASTA alignment and computes its average pairwise dN/dS ratio
    (using the Nei–Gojobori NG86 method). Ambiguous or incomplete codons are skipped.
    Prints "TRUE" if average ∈ [min_dnds, max_dnds], else "FALSE".

Usage:
    python filter_dnds_passfail.py <input_fasta> <min_dnds> <max_dnds> [--include-gaps]
"""

import argparse
from Bio import SeqIO
from Bio.codonalign.codonseq import cal_dn_ds
from Bio.codonalign import CodonSeq
import warnings
from itertools import combinations

def extract_valid_codons(seq, include_gaps):
    seq = seq.upper().replace("\n", "").replace(" ", "")
    if not include_gaps:
        seq = seq.replace("-", "")
    start = seq.find("ATG")
    if start < 0:
        return []
    valid = []
    stops = {"TAA", "TAG", "TGA"}
    bases = set("ATCG")
    for i in range(start, len(seq) - 2, 3):
        codon = seq[i:i+3]
        if codon in stops:
            break
        if len(codon) == 3 and all(c in bases for c in codon):
            valid.append(codon)
    return valid

def average_dnds(aln_file, include_gaps):
    records = list(SeqIO.parse(aln_file, "fasta"))
    if len(records) < 2:
        return None
    codon_seqs = []
    for rec in records:
        codons = extract_valid_codons(str(rec.seq), include_gaps)
        if not codons:
            return None
        try:
            cs = CodonSeq("".join(codons))
            codon_seqs.append(cs)
        except Exception:
            return None
    ratios = []
    for i, j in combinations(range(len(codon_seqs)), 2):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            dn, ds = cal_dn_ds(codon_seqs[i], codon_seqs[j], method="NG86")
        if ds > 0:
            ratios.append(dn / ds)
        elif dn == 0:
            ratios.append(0.0)
    return sum(ratios) / len(ratios) if ratios else None

def main():
    p = argparse.ArgumentParser(
        description="Print TRUE/FALSE if alignment average dN/dS passes threshold"
    )
    p.add_argument("input_fasta", help="Input FASTA alignment file")
    p.add_argument("min_dnds", type=float, help="Minimum dN/dS (inclusive)")
    p.add_argument("max_dnds", type=float, help="Maximum dN/dS (inclusive)")
    p.add_argument("--include-gaps", action="store_true",
                   help="Include gaps in codon extraction")
    args = p.parse_args()

    # Attempt to parse the file; on any error, print FALSE and exit
    try:
        # This will raise if the file is missing or not valid FASTA
        _ = list(SeqIO.parse(args.input_fasta, "fasta"))
    except Exception:
        print("FALSE")
        return

    avg = average_dnds(args.input_fasta, args.include_gaps)
    within_range:bool = avg is not None and args.min_dnds <= avg <= args.max_dnds
    if within_range:
        print("TRUE")
    else:
        print("FALSE")

    log_path = args.input_fasta + ".log"
    with open(log_path, 'w') as log_file:
        log_file.write(f"Average: {avg}\n")
        log_file.write(f"Min: {args.min_dnds}, Max: {args.max_dnds}\n")
        log_file.write("Result: " + ("TRUE" if within_range else "FALSE") + "\n")

if __name__ == "__main__":
    main()