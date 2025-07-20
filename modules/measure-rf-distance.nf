process MEASURE_RF_DISTANCE {
    tag "${id}"
    cpus "${params.measure_rf_distance_cpus}"
    memory "${params.measure_rf_distance_memory} GB"
    publishDir "${params.results}/measure-rf-distance", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(query_tree), path(reference_tree), val(container), val(cluster_options)
    
    output:
        tuple val(id), path("${id}-rf-distance.txt")

    script:
        """
        measure-rf-distance.py ${query_tree} ${reference_tree} ${id}-rf-distance.txt
        """
}