process FORMAT_HEADERS {
    tag "${id}"
    cpus "${params.format_headers_cpus}"
    memory "${params.format_headers_memory} GB"
    container "${params.docker_python}"
    publishDir "${params.results}/format-headers", mode: "copy"

    input:
        tuple val(id), path(input_alignments) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("formatted-alignments/")

    script:
        """
        format-headers.py ${input_alignments}
        """
}