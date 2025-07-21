process CONCATENATE_ALIGNMENTS {
    tag "${id}"
    cpus "${params.concatenate_alignments_cpus}"
    memory "${params.concatenate_alignments_memory} GB"
    publishDir "${params.results}/concatenate-alignments", mode: "copy"
    container "${container}"
    clusterOptions "${cluster_options}"

    input:
        tuple val(id), val(input_alignments), val(container), val(cluster_options) // ${input_alignments} is a string of paths!
    
    output:
        tuple val(id), path("${id}-concatenated.fasta")

    script:
        """
        mkdir input-alignments
        cp ${input_alignments} input-alignments/
        concatenate-alignments.py "\${PWD}/input-alignments" ${id}-concatenated.fasta
        """
}