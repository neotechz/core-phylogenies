process CALCULATE_SUBSTITUTION_MODEL {
    cpus 4
    memory "4 GB"
    container "quay.io/biocontainers/modeltest-ng:0.1.7--hf316886_3"
    publishDir "${params.results}/calculate-substitution-model", mode: "copy"

    input:
        tuple val(id), path(alignment)
    
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