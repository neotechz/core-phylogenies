process REMOVE_INVARIABLE_SITES {
    tag "${id}"
    cpus "${params.remove_invariable_sites_cpus}"
    memory "${params.remove_invariable_sites_memory} GB"
    publishDir "${params.results}/remove-invariable-sites", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(alignment), val(container), val(cluster_options)
    
    output:
        tuple val(id), path("${id}-varsites.fasta")

    script:
        """
        snp-sites -c -o ${id}-varsites.fasta ${alignment}
        """
}