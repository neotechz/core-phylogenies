process FILTER_BY_RANDOM {
    tag "${id}"
    cpus "1"
    memory "1 GB"
    maxForks params.filter_by_random_max_forks.toInteger()
    publishDir "${params.results}/filter-by-random", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), val(input_alignment_name), val(container), val(cluster_options) 
    
    output:
        tuple val(id), eval("echo \${RETURN}"), path("${input_alignment_name}.log")

    script:
        """
        ANSWER=`echo \$(( RANDOM % 2 ))`
        if [ "\${ANSWER}" == "1" ]; then
            echo "${id} TRUE" >> ${input_alignment_name}.log
            RETURN="TRUE"
        else
            echo "${id} FALSE" >> ${input_alignment_name}.log
            RETURN="FALSE"
        fi
        """
}