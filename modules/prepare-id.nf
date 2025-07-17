process PREPARE_ID {
    cpus "${params.prepare_id_cpus}"
    memory "${params.prepare_id_memory} GB"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(input_data), val(container), val(cluster_options)
    
    output:
        tuple eval("echo \${ID}"), val(input_data)

    script:
        """
        ID=`${params.prepare_id_method}.py ${input_data}`
        """
}