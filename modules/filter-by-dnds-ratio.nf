process FILTER_BY_DNDS_RATIO {
    tag "${id}"
    cpus "${params.filter_by_dnds_ratio_cpus}"
    memory "${params.filter_by_dnds_ratio_memory} GB"
    maxForks params.filter_by_dnds_ratio_max_forks.toInteger()
    publishDir "${params.results}/filter-by-dnds-ratio", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(input_alignment), val(start), val(end), val(container), val(cluster_options) // ${input_alignment} is a file!
    
    output:
        tuple val(id), eval("echo \${RETURN}")

    script:
        """
        ANSWER=`filter-by-dnds-ratio.py ${input_alignment} ${start} ${end}`
        if [ "\${ANSWER}" == "TRUE" ]; then
            RETURN="\${PWD}/${input_alignment}"
        else
            RETURN=""
        fi
        """
}