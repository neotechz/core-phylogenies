process FILTER_BY_POLYMORPHIC_SITES {
    tag "${id}"
    cpus "${params.filter_by_polymorphic_sites_cpus}"
    memory "${params.filter_by_polymorphic_sites_memory} GB"
    container "${params.docker_python}"
    publishDir "${params.results}/filter-by-polymorphic-sites", mode: "copy"

    input:
        tuple val(id), path(input_alignments), val(cutoff) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("${id}-filtered-1/")

    script:
        """
        filter-by-normalized-polymorphic-sites.py ${input_alignments} ${id}-filtered-1 ${cutoff}
        """
}