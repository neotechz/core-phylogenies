#!/usr/bin/env python3

import os, sys, re

def main():
    # Alignments to format
    input_path = f"{sys.argv[1]}"
    input_alignments = os.fsencode(input_path)

    # Formatted alignments
    output_path = "./formatted-alignments"
    if not os.path.exists(output_path):
        os.mkdir("./formatted-alignments")
    
    # For each FASTA to format
    for fasta in os.listdir(input_alignments):
        fasta_path = os.fsdecode(fasta)

        # Open the FASTA to read and the new FASTA to write
        with open(f"{input_path}/{fasta_path}", "r") as input, open(f"{output_path}/{fasta_path}", "w+") as output:

            # For each line
            for line in input.readlines():

                # If header
                if line[0] == ">":
                    output_line = re.split("[-_]", line)[0]

                    # Add a newline if there's no newline at the end
                    output.write(f"{output_line}\n" if output_line[-1] != "\n" else output_line)

                # Else if sequence
                else:
                    output.write(line)


main()