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
        tuple val(id), path("${id}.support.tre")

    script:
        """
        if [ "${container}" = "${params.container_raxml_ng}" ]; then
        
            export MODEL=\$(cat ${substitution_model} | grep "> raxml-ng" | tail -1 | grep -e "--model.*\$" -o | grep  -e "\\s.*\$" -o)

            raxml-ng \
                --all \
                --msa ${alignment} \
                --model \$MODEL \
                --prefix \${PWD}/${id} \
                --seed 119318 \
                --bs-metric tbe \
                --tree pars{100} \
                --bs-trees ${params.make_phylogeny_bootstraps} \
                --threads ${task.cpus} \
                --force perf_threads

            mv ${id}.raxml.support ${id}.support.tre

        elif [ "${container}" = "${params.container_iqtree2}" ]; then

            export MODEL=\$(cat ${substitution_model} | grep "> iqtree" | tail -1 | grep -e "-m.*\$" -o | grep  -e "\\s.*\$" -o)

            iqtree2 \
                -s ${alignment} \
                -m \$MODEL \
                -b ${params.make_phylogeny_bootstraps} \
                -fast \
                -T ${task.cpus} \
                --prefix ${id} \
                --seed 119318

            mv ${id}.treefile ${id}.support.tre

        elif [ "${container}" = "${params.container_fasttree}" ] ; then

            OMP_NUM_THREADS=${task.cpus}

            FastTreeMP \
                -quiet \
                -gtr \
                -gamma \
                -spr 4 \
                -mlacc 2 \
                -slownni \
                -out ${id}.support.tre \
                ${alignment}

        fi
        """
}