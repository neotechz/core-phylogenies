process FILTER_BY_DNDS_RATIO {
    cpus "${params.filter_by_dnds_ratio_cpus}"
    memory "${params.filter_by_dnds_ratio_memory} GB"
    container "${params.docker_python}"
    publishDir "${params.results}/filter-by-dnds-ratio", mode: "copy"

    input:
        tuple val(id), path(input_alignments), val(start), val(end) // ${input_alignments} is a directory!
    
    output:
        tuple val(id), path("output-alignments/")

    script:
        """
        # filter-by-dnds-ratio.py ${input_alignments} ${start} ${end}
        """
}