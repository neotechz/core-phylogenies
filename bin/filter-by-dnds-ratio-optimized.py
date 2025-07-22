#!/usr/bin/env python3
"""
Program: Single‐Alignment dN/dS Pass/Fail
-------------------------------------------------
Description:
    Reads one FASTA alignment file, extracts valid ORFs, computes average 
    pairwise dN/dS (NG86), and prints "TRUE" if the result ∈ [min_dnds, max_dnds], 
    else "FALSE".

Usage:
    python filter_dnds_passfail.py <input_fasta> <min_dnds> <max_dnds> [--include-gaps]
"""

import sys
import argparse
from Bio import SeqIO
from Bio.codonalign.codonseq import cal_dn_ds
from Bio.codonalign import CodonSeq
import warnings
from itertools import combinations

def extract_valid_codons(seq, include_gaps):
    s = seq.upper().replace("\n","").replace(" ","")
    if not include_gaps:
        s = s.replace("-", "")
    start = s.find("ATG")
    if start < 0:
        return []
    bases, stops = set("ATCG"), {"TAA","TAG","TGA"}
    codons = []
    for i in range(start, len(s)-2, 3):
        c = s[i:i+3]
        if c in stops:
            break
        if all(b in bases for b in c):
            codons.append(c)
    return codons

def average_dnds(recs, include_gaps):
    if len(recs) < 2:
        return None
    cs_list = []
    for rec in recs:
        orf = extract_valid_codons(str(rec.seq), include_gaps)
        if not orf:
            return None
        try:
            cs_list.append(CodonSeq("".join(orf)))
        except:
            return None
    ratios = []
    for x, y in combinations(cs_list, 2):
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            dn, ds = cal_dn_ds(x, y, method="NG86")
        if ds > 0:
            ratios.append(dn/ds)
        elif dn == 0:
            ratios.append(0.0)
    return sum(ratios)/len(ratios) if ratios else None

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

    try:
        recs = list(SeqIO.parse(args.input_fasta, "fasta"))
    except Exception:
        print("FALSE")
        return

    avg = average_dnds(recs, args.include_gaps)
    print("TRUE" if (avg is not None and args.min_dnds <= avg <= args.max_dnds) else "FALSE")

if __name__ == "__main__":
    main()