process FILTER_BY_POLYMORPHIC_SITES {
    tag "${id}"
    cpus "${params.filter_by_polymorphic_sites_cpus}"
    memory "${params.filter_by_polymorphic_sites_memory} GB"
    publishDir "${params.results}/filter-by-polymorphic-sites", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(input_alignment), val(cutoff), val(container), val(cluster_options) // ${input_alignment} is a file!
    
    output:
        tuple val(id), eval("echo \${RETURN}")

    script:
        """
        ANSWER=`filter-by-normalized-polymorphic-sites.py ${input_alignment} ${cutoff}`
        if [ "\${ANSWER}" == "TRUE" ]; then
            RETURN="${input_alignment}"
        else
            RETURN=""
        fi
        """
}