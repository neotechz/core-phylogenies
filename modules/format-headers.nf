process FORMAT_HEADERS {
    tag "${id}"
    cpus "${params.format_headers_cpus}"
    memory "${params.format_headers_memory} GB"
    publishDir "${params.results}/format-headers", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), path(input_alignments), val(container), val(cluster_options) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("formatted-alignments/")

    script:
        """
        format-headers.py ${input_alignments}
        """
}