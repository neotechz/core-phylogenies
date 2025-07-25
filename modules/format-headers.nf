process FORMAT_HEADERS {
    tag "${id}"
    cpus "${params.format_headers_cpus}"
    memory "${params.format_headers_memory} GB"
    maxForks params.format_headers_max_forks.toInteger()
    publishDir "${params.results}/format-headers", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(input_alignment), val(container), val(cluster_options) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("formatted-alignments/*")

    script:
        """
        format-headers.py ${input_alignment}
        """
}