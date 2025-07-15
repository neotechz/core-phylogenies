process FILTER_BY_NUCLEOTIDE_DIVERSITY {
    tag "${id}"
    cpus "${params.filter_by_nucleotide_diversity_cpus}"
    memory "${params.filter_by_nucleotide_diversity_memory} GB"
    publishDir "${params.results}/filter-by-nucleotide-diversity", mode: "copy"
    container "${container}"

    input:
        tuple val(id), path(input_alignments), val(start), val(end), val(container) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("${id}-filtered-2/")

    script:
        """
        filter-by-nucleotide-diversity.py ${input_alignments} ${id}-filtered-2 ${start} ${end}
        """
}