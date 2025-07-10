#!/usr/bin/env python3
"""
Program #2: Filter genes by nucleotide diversity
--------------------------------------------------
This script filters aligned gene sequences based on nucleotide diversity (π), which measures variation between sequences.

🧬 WHAT IT DOES:
- Loads aligned sequences from FASTA files.
- Calculates pairwise Hamming distances (i.e., site mismatches).
- Optionally ignores positions with gaps ('-').
- Computes average nucleotide diversity (π) across all pairs.
- Retains sequences if π is within the desired range.

📥 INPUT:
- A folder containing FASTA alignments of DNA sequences.

📤 OUTPUT:
- Filtered FASTA files saved to a specified folder.

🧠 KEY TERMS:
- Hamming distance: Number of mismatches between two sequences.
- Nucleotide diversity (π): Average number of nucleotide differences per site.
- Effective length: Number of comparable positions per pair (excluding gaps if specified).

🖥️ USAGE:
    python nucleotide_diversity_filter.py input_folder/ output_folder/ 0.1 0.8

ARGUMENTS:
- input_folder:     Folder with input FASTA files.
- output_folder:    Folder to save filtered files.
- 0.1               Minimum nucleotide diversity (default: 0.05 if omitted)
- 0.8               Maximum nucleotide diversity (default: 0.7 if omitted)
- --include-gaps    (Optional) Include gaps in distance/diversity calculations.

🔍 OUTPUT SUMMARY:
For each file, prints:
    - Nucleotide diversity value
    - Whether the file passed or was filtered out

Final summary includes:
    - Number of files kept/removed
    - Retention rate
    - Min, max, and average diversity values

⚠️ NOTES:
- Skips files with <2 sequences or unequal-length sequences.
- If all sequences are gaps or empty, diversity = 0 and the file is skipped.
"""

import os
import sys
from pathlib import Path
from itertools import combinations
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord
import argparse
import numpy as np
from scipy.spatial.distance import hamming

def hamming_distance(seq1, seq2, ignore_gaps=True):
    """
    Calculate Hamming distance between two sequences of equal length using scipy.
    
    Args:
        seq1, seq2: DNA sequences as strings
        ignore_gaps: If True, ignore positions where either sequence has a gap ('-')
    
    Returns:
        int: Number of differing nucleotides (excluding gap positions if ignore_gaps=True)
    """
    if len(seq1) != len(seq2):
        raise ValueError("Sequences must have equal length")
    
    # Convert sequences to numpy arrays for scipy
    arr1 = np.array(list(seq1))
    arr2 = np.array(list(seq2))
    
    if ignore_gaps:
        # Create mask for positions where neither sequence has a gap
        valid_positions = (arr1 != '-') & (arr2 != '-')
        
        # If no valid positions, return 0
        if not np.any(valid_positions):
            return 0
        
        # Only compare non-gap positions
        arr1_filtered = arr1[valid_positions]
        arr2_filtered = arr2[valid_positions]
        
        # Calculate hamming distance only for valid positions
        return int(hamming(arr1_filtered, arr2_filtered) * len(arr1_filtered))
    else:
        # Include gaps in the comparison (treat '-' as a character)
        return int(hamming(arr1, arr2) * len(seq1))

def calculate_nucleotide_diversity(alignment_file, ignore_gaps=True):
    """
    Calculate nucleotide diversity for a gene alignment.
    
    Args:
        alignment_file: Path to FASTA alignment file
        ignore_gaps: If True, ignore positions with gaps ('-') in diversity calculation
        
    Returns:
        float: Nucleotide diversity (0 to 1)
    """
    try:
        # Read sequences from FASTA file
        sequences = list(SeqIO.parse(alignment_file, "fasta"))
        
        if len(sequences) < 2:
            print(f"Warning: {alignment_file} has fewer than 2 sequences. Skipping.")
            return None
        
        # Get sequence strings and convert to uppercase for consistency
        seq_strings = [str(seq.seq).upper() for seq in sequences]
        
        # Check if all sequences have the same length
        seq_length = len(seq_strings[0])
        if not all(len(seq) == seq_length for seq in seq_strings):
            print(f"Warning: {alignment_file} has sequences of different lengths. Skipping.")
            return None
        
        # Skip sequences that are too short
        if seq_length == 0:
            print(f"Warning: {alignment_file} has empty sequences. Skipping.")
            return None
        
        # Calculate effective length (non-gap positions) for diversity calculation
        if ignore_gaps:
            # Find positions where at least one sequence has a nucleotide (not gap)
            valid_positions = set()
            for seq in seq_strings:
                for i, char in enumerate(seq):
                    if char != '-':
                        valid_positions.add(i)
            
            effective_length = len(valid_positions)
            if effective_length == 0:
                print(f"Warning: {alignment_file} has only gaps. Skipping.")
                return None
        else:
            effective_length = seq_length
        
        # Calculate Hamming distances for all pairwise combinations
        hamming_distances = []
        valid_comparisons = 0
        
        for seq1, seq2 in combinations(seq_strings, 2):
            distance = hamming_distance(seq1, seq2, ignore_gaps=ignore_gaps)
            
            # Only count comparisons where there are valid positions to compare
            if ignore_gaps:
                # Count non-gap positions in both sequences
                valid_positions_pair = sum(1 for c1, c2 in zip(seq1, seq2) if c1 != '-' and c2 != '-')
                if valid_positions_pair > 0:
                    hamming_distances.append(distance)
                    valid_comparisons += 1
            else:
                hamming_distances.append(distance)
                valid_comparisons += 1
        
        # Calculate nucleotide diversity
        if hamming_distances and valid_comparisons > 0:
            average_hamming = sum(hamming_distances) / len(hamming_distances)
            
            # For diversity calculation, use the effective length
            if ignore_gaps:
                # Use average number of comparable positions across all pairwise comparisons
                total_comparable_positions = 0
                comparison_count = 0
                for seq1, seq2 in combinations(seq_strings, 2):
                    comparable = sum(1 for c1, c2 in zip(seq1, seq2) if c1 != '-' and c2 != '-')
                    if comparable > 0:
                        total_comparable_positions += comparable
                        comparison_count += 1
                
                if comparison_count > 0:
                    avg_comparable_length = total_comparable_positions / comparison_count
                    nucleotide_diversity = average_hamming / avg_comparable_length
                else:
                    nucleotide_diversity = 0.0
            else:
                nucleotide_diversity = average_hamming / seq_length
            
            return nucleotide_diversity
        else:
            return 0.0
            
    except Exception as e:
        print(f"Error processing {alignment_file}: {e}")
        return None

def filter_by_nucleotide_diversity(input_folder, output_folder, min_diversity, max_diversity, ignore_gaps=True):
    """
    Filter gene alignments based on nucleotide diversity.
    
    Args:
        input_folder: Path to folder containing input FASTA files
        output_folder: Path to folder for filtered FASTA files
        min_diversity: Minimum nucleotide diversity (inclusive)
        max_diversity: Maximum nucleotide diversity (inclusive)
        ignore_gaps: If True, ignore gap positions in diversity calculation
    """
    # Convert to Path objects
    input_path = Path(input_folder)
    output_path = Path(output_folder)
    
    # Create output folder if it doesn't exist
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Get all FASTA files from input folder (including subdirectories)
    input_files = []
    fasta_extensions = ['*.fasta', '*.fa', '*.fas', '*.fna', '*.ffn']
    
    for ext in fasta_extensions:
        input_files.extend(input_path.glob(ext))
        # Also check subdirectories
        input_files.extend(input_path.glob(f"**/{ext}"))
    
    # Remove duplicates and sort
    input_files = sorted(list(set(input_files)))
    
    if not input_files:
        print(f"No FASTA files found in {input_folder}")
        print(f"Searched for extensions: {', '.join(fasta_extensions)}")
        return
    
    filtered_count = 0
    total_count = len(input_files)
    diversity_values = []
    
    print(f"Processing {total_count} alignment files...")
    print(f"Filtering for nucleotide diversity between {min_diversity} and {max_diversity}")
    print("-" * 60)
    
    for input_file in input_files:
        print(f"Processing: {input_file.name}")
        
        # Calculate nucleotide diversity
        diversity = calculate_nucleotide_diversity(input_file, ignore_gaps=ignore_gaps)
        
        if diversity is None:
            continue
            
        diversity_values.append(diversity)
        print(f"  Nucleotide diversity: {diversity:.6f}")
        
        # Check if diversity is within range
        if min_diversity <= diversity <= max_diversity:
            # Copy file to output folder, preserving relative path structure
            relative_path = input_file.relative_to(input_path)
            output_file = output_path / relative_path
            
            # Create subdirectories if needed
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Read and write sequences
            sequences = list(SeqIO.parse(input_file, "fasta"))
            SeqIO.write(sequences, output_file, "fasta")
            
            print(f"  ✓ Kept (diversity within range)")
            filtered_count += 1
        else:
            print(f"  ✗ Filtered out (diversity outside range)")
    
    removed_count = total_count - filtered_count
    
    print("\n" + "=" * 60)
    print("RESULTS SUMMARY:")
    print("=" * 60)
    print(f"Total files processed: {total_count}")
    print(f"Files kept: {filtered_count}")
    print(f"Files removed: {removed_count}")
    print(f"Retention rate: {(filtered_count/total_count)*100:.1f}%")
    
    if diversity_values:
        print(f"\nDiversity statistics:")
        print(f"  Min diversity: {min(diversity_values):.6f}")
        print(f"  Max diversity: {max(diversity_values):.6f}")
        print(f"  Mean diversity: {sum(diversity_values)/len(diversity_values):.6f}")
    
    print(f"\nFiltered files saved to: {output_folder}")

def main():
    parser = argparse.ArgumentParser(
        description="Filter gene alignments by nucleotide diversity",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Filter with moderate diversity (good for phylogenetic analysis)
    python nucleotide_diversity_filter.py input_alignments/ output_alignments/ 0.1 0.8
    
    # Filter for highly conserved genes
    python nucleotide_diversity_filter.py genes/ filtered_genes/ 0.0 0.2
    
    # Filter for moderately variable genes
    python nucleotide_diversity_filter.py genes/ filtered_genes/ 0.05 0.5
    
    # Use default parameters (moderate diversity)
    python nucleotide_diversity_filter.py input_alignments/ output_alignments/
        """
    )
    
    parser.add_argument("input_folder", help="Folder containing input FASTA alignment files")
    parser.add_argument("output_folder", help="Folder for filtered FASTA alignment files")
    parser.add_argument("min_diversity", nargs='?', type=float, default=0.05, 
                       help="Minimum nucleotide diversity (default: 0.05)")
    parser.add_argument("max_diversity", nargs='?', type=float, default=0.7, 
                       help="Maximum nucleotide diversity (default: 0.7)")
    
    parser.add_argument("--include-gaps", action="store_true", 
                       help="Include gap positions in diversity calculation (default: ignore gaps)")
    
    args = parser.parse_args()
    
    # Set ignore_gaps based on command line argument
    ignore_gaps = not args.include_gaps
    
    # Validate arguments
    if not os.path.exists(args.input_folder):
        print(f"Error: Input folder '{args.input_folder}' does not exist")
        sys.exit(1)
    
    if args.min_diversity < 0 or args.max_diversity > 1:
        print("Error: Nucleotide diversity values must be between 0 and 1")
        sys.exit(1)
    
    if args.min_diversity > args.max_diversity:
        print("Error: Minimum diversity cannot be greater than maximum diversity")
        sys.exit(1)
    
    # Show parameters being used
    print("NUCLEOTIDE DIVERSITY FILTER")
    print("=" * 40)
    print(f"Input folder: {args.input_folder}")
    print(f"Output folder: {args.output_folder}")
    print(f"Diversity range: {args.min_diversity} - {args.max_diversity}")
    print(f"Gap handling: {'Include gaps' if not ignore_gaps else 'Ignore gaps'}")
    print()
    
    # Run the filtering
    filter_by_nucleotide_diversity(
        args.input_folder, 
        args.output_folder, 
        args.min_diversity, 
        args.max_diversity,
        ignore_gaps
    )

if __name__ == "__main__":
    main()