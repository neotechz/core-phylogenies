process MAKE_PHYLOGENY {
    cpus 12
    memory "12 GB"
    container "quay.io/biocontainers/raxml-ng:0.9.0--h192cbe9_1"
    publishDir "${params.results}/make-phylogeny", mode: "copy"
    cache "deep"

    input:
        tuple val(id), path(alignment), path(substitution_model)
    
    output:
        tuple val(id), path("${id}.raxml.support.tre")

    script:
        """
        export MODEL=\$(cat ${substitution_model} | grep "> raxml-ng" | tail -1 | grep -e "--model.*\$" -o | grep  -e "\\s.*\$" -o)

        raxml-ng \
            --all \
            --msa ${alignment} \
            --model \$MODEL \
            --prefix \${PWD}/${id} \
            --seed 119318 \
            --bs-metric tbe \
            --tree rand{1} \
            --bs-trees 1000 \
            --force perf_threads

        mv ${id}.raxml.support ${id}.raxml.support.tre
        """
}