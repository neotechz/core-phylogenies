docker pull neotechz/core-phylogenies:1.1
docker pull quay.io/biocontainers/modeltest-ng:0.1.7--hf316886_3
docker pull quay.io/biocontainers/raxml-ng:0.9.0--h192cbe9_1
docker pull quay.io/biocontainers/fasttree:2.1.11--h7b50bb2_5
docker pull quay.io/staphb/iqtree2:2.4.0


mkdir -p data
mkdir -p results
mkdir -p logs
mkdir -p slurm-logs
mkdir -p tmp