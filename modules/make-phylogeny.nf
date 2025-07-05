process MAKE_PHYLOGENY {
    cpus "${params.make_phylogeny_cpus}"
    memory "${params.make_phylogeny_memory} GB"
    container "${params.docker_raxml_ng}"
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