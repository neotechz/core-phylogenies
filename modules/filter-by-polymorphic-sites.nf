process FILTER_BY_POLYMORPHIC_SITES {
    cpus "${params.filter_by_polymorphic_sites_cpus}"
    memory "${params.filter_by_polymorphic_sites_memory} GB"
    container "${params.docker_python}"
    publishDir "${params.results}/filter-by-polymorphic-sites", mode: "copy"

    input:
        tuple val(id), path(input_alignments), val(cutoff) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("output-alignments/")

    script:
        """
        # filter-by-polymorphic-sites.py ${input_alignments} ${cutoff}
        """
}