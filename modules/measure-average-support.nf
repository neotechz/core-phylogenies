process MEASURE_AVERAGE_SUPPORT {
    tag "${id}"
    cpus "${params.measure_average_support_cpus}"
    memory "${params.measure_average_support_memory} GB"
    publishDir "${params.results}/measure-average-support", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(query_tree), val(container), val(cluster_options)
    
    output:
        tuple val(id), path("${id}-average-support.txt")

    script:
        """
        measure-average-support.py ${query_tree} ${id}-average-support.txt
        """
}