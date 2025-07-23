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
        tuple val(id), path("${id}-concatenated.fasta"), path("genes-after-filtering.txt")

    script:
        """
        mkdir input-alignments
        cp ${input_alignments} input-alignments/
        concatenate-alignments.py "\${PWD}/input-alignments" ${id}-concatenated.fasta

        ls input-alignments > genes-after-filtering.txt
        printf "\nNumber of genes after filtering:\n" >> genes-after-filtering.txt
        ls input-alignments | wc -l >> genes-after-filtering.txt
        """
}