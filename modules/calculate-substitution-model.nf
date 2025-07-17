process CALCULATE_SUBSTITUTION_MODEL {
    tag "${id}"
    cpus "${params.calculate_substitution_model_cpus}"
    memory "${params.calculate_substitution_model_memory} GB"
    publishDir "${params.results}/calculate-substitution-model", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(alignment), val(container), val(cluster_options)
    
    output:
        tuple val(id), path("${id}-substitution-model.out")

    script:
        """
        modeltest-ng \
            -i ${alignment} \
            -d nt \
            -p 4 \
            -T raxml \
            --rngseed 119318 \
            -o ${id}-substitution-model \
            > DUMP
        """
}