process MAKE_PHYLOGENY {
    tag "${id}"
    cpus "${params.make_phylogeny_cpus}"
    memory "${params.make_phylogeny_memory} GB"
    maxForks params.make_phylogeny_max_forks.toInteger()
    publishDir "${params.results}/make-phylogeny", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"
    cache "deep"

    input:
        tuple val(id), path(alignment), path(substitution_model), val(container), val(cluster_options)
    
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
            --bs-trees ${params.make_phylogeny_bootstraps} \
            --threads ${task.cpus} \
            --force perf_threads

        mv ${id}.raxml.support ${id}.raxml.support.tre
        """
}