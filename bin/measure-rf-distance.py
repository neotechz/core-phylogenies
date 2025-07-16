#!/usr/bin/env python3
"""
Program #6: Measure Tree Correctness via RF Distance
----------------------------------------------------
Description:
- Compares two phylogenetic trees in Newick format.
- Calculates the Robinson-Foulds (RF) distance between them.
- Outputs the RF distance to a .txt file.

Usage:
    python measure_rf_distance.py your_tree.tre reference_tree.tre rf_output.txt
"""

import sys
import dendropy
from dendropy.calculate import treecompare

def calculate_rf_distance(tree_path_1, tree_path_2):
    """
    Load two trees and compute their RF distance.
    Returns: rf_distance (int), max_rf (int)
    """
    taxa = dendropy.TaxonNamespace()

    tree1 = dendropy.Tree.get(
        path=tree_path_1, schema="newick",
        rooting="force-unrooted", taxon_namespace=taxa
    )
    tree2 = dendropy.Tree.get(
        path=tree_path_2, schema="newick",
        rooting="force-unrooted", taxon_namespace=taxa
    )

    # RF distance (symmetric difference)
    rf_distance = treecompare.symmetric_difference(tree1, tree2)

    # Number of taxa
    n = len(taxa)
    # Max possible RF for unrooted binary tree with n taxa: 2*(n - 3)
    max_rf = 2 * (n - 3)

    return rf_distance, max_rf

def write_output(rf_distance, max_rf, output_path):
    """
    Write RF results to a text file.
    """
    with open(output_path, "w") as f:
        f.write("ROBINSON-FOULDS DISTANCE RESULTS\n")
        f.write("=" * 40 + "\n")
        f.write(f"RF distance: {rf_distance}\n")
        f.write(f"Max possible RF distance: {max_rf}\n")
        f.write("=" * 40 + "\n")

def main():
    if len(sys.argv) != 4:
        print("Usage: python measure_rf_distance.py tree1.tre tree2.tre output.txt")
        sys.exit(1)

    tree_file_1, tree_file_2, output_file = sys.argv[1:4]

    rf_distance, max_rf = calculate_rf_distance(tree_file_1, tree_file_2)
    write_output(rf_distance, max_rf, output_file)

    print(f"✓ RF distance ({rf_distance}) written to: {output_file}")

if __name__ == "__main__":
    main()