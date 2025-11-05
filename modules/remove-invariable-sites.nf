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
        tuple val(id), path("${id}-varsites.phy")

    script:
        """
        iqtree2 -s ${alignment} -m MFP+ASC 2> /dev/null || true
        mv ${alignment}.varsites.phy ${id}-varsites.phy
        """
}