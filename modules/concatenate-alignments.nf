process CONCATENATE_ALIGNMENTS {
    cpus "${params.concatenate_alignments_cpus}"
    memory "${params.concatenate_alignments_memory} GB"
    publishDir "${params.results}/concatenate-alignments", mode: "copy"
    container "${container}"

    input:
        tuple val(id), path(input_alignments), val(container) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("${id}-concatenated.fasta")

    script:
        """
        concatenate-alignments.py ${input_alignments} ${id}-concatenated.fasta
        """
}