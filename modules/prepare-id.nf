process PREPARE_ID {
    cpus "${params.prepare_id_cpus}"
    memory "${params.prepare_id_memory} GB"
    container "${params.docker_python}"

    input:
        val(input_data)
    
    output:
        tuple eval("echo \${ID}"), val(input_data)

    script:
        """
        ID=`${params.prepare_id_method}.py ${input_data}`
        """
}