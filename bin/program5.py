import re
import sys

def extract_bootstrap_values(newick_text):
    # Find numbers that appear right after ')'
    bootstrap_values = re.findall(r'\)(\d+(?:\.\d+)?)', newick_text)
    return [float(value) for value in bootstrap_values]

def compute_average(values):
    return sum(values) / len(values) if values else 0.0

def main():
    if len(sys.argv) != 3:
        print("Usage: python program5.py <input_file.tre> <output_file.txt>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        with open(input_file, "r") as f:
            newick_data = f.read()
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)

    bootstrap_values = extract_bootstrap_values(newick_data)
    average_value = compute_average(bootstrap_values)

    with open(output_file, "w") as f:
        f.write(f"{average_value:.2f}\n")

    print(f"Average bootstrap value saved to '{output_file}'")

if __name__ == "__main__":
    main()
