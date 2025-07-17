process FILTER_BY_DNDS_RATIO {
    tag "${id}"
    cpus "${params.filter_by_dnds_ratio_cpus}"
    memory "${params.filter_by_dnds_ratio_memory} GB"
    publishDir "${params.results}/filter-by-dnds-ratio", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(input_alignments), val(start), val(end), val(container), val(cluster_options) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("${id}-filtered-3/")

    script:
        """
        filter-by-dnds-ratio.py ${input_alignments} ${id}-filtered-3 ${start} ${end}
        """
}