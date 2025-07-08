process CONCATENATE_ALIGNMENTS {
    cpus "${params.concatenate_alignments_cpus}"
    memory "${params.concatenate_alignments_memory} GB"
    container "${params.docker_python}"
    publishDir "${params.results}/concatenate-alignments", mode: "copy"

    input:
        tuple val(id), path(input_alignments) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("concatenated-alignment.fasta")

    script:
        """
        # concatenate-alignments.py ${input_alignments}
        """
}