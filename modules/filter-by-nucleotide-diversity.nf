process FILTER_BY_NUCLEOTIDE_DIVERSITY {
    tag "${id}"
    cpus "${params.filter_by_nucleotide_diversity_cpus}"
    memory "${params.filter_by_nucleotide_diversity_memory} GB"
    maxForks params.filter_by_nucleotide_diversity_max_forks.toInteger()
    publishDir "${params.results}/filter-by-nucleotide-diversity", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(input_alignment), val(start), val(end), val(container), val(cluster_options) // ${input_alignment} is a file!
    
    output:
        tuple val(id), eval("echo \${RETURN}")

    script:
        """
        ANSWER=`filter-by-nucleotide-diversity.py ${input_alignment} ${start} ${end}`
        if [ "\${ANSWER}" == "TRUE" ]; then
            RETURN="${input_alignment}"
        else
            RETURN=""
        fi
        """
}