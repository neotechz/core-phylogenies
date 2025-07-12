process FILTER_BY_NUCLEOTIDE_DIVERSITY {
    cpus "${params.filter_by_nucleotide_diversity_cpus}"
    memory "${params.filter_by_nucleotide_diversity_memory} GB"
    container "${params.docker_python}"
    publishDir "${params.results}/filter-by-nucleotide-diversity", mode: "copy"

    input:
        tuple val(id), path(input_alignments), val(start), val(end) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("${id}-filtered-1/")

    script:
        """
        filter-by-nucleotide-diversity.py ${input_alignments} ${id}-filtered-1 ${start} ${end}
        """
}