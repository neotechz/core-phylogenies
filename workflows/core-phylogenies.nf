// Default utility imports
include { resolveContainerPath } from '../utils/resolve-container-path'


// Default module imports
include { PREPARE_ID                     } from '../modules/prepare-id'
include { FORMAT_HEADERS                 } from '../modules/format-headers'
include { FILTER_BY_POLYMORPHIC_SITES    } from '../modules/filter-by-polymorphic-sites'
include { FILTER_BY_NUCLEOTIDE_DIVERSITY } from '../modules/filter-by-nucleotide-diversity'
include { FILTER_BY_DNDS_RATIO           } from '../modules/filter-by-dnds-ratio'
include { CONCATENATE_ALIGNMENTS         } from '../modules/concatenate-alignments'
include { CALCULATE_SUBSTITUTION_MODEL   } from '../modules/calculate-substitution-model'
include { MAKE_PHYLOGENY                 } from '../modules/make-phylogeny'


// Pipeline workflow
workflow CORE_PHYLOGENIES {
    main:
        // SLURM cluster options, if applicable
        if (workflow.profile == "slurm") {
            if (!params.cluster_options) {
                error "ERROR: SLURM cluster options (account, partition, qos, etc.) not specified (--cluster_options)"
            }
        } else {
            params.cluster_options = null
        }

        Channel
            .of("${params.cluster_options}")
            .set {ch_cluster_options}


        // Container paths
        Channel
            .of("${resolveContainerPath(params.container_base)}")
            .set {ch_container_base}

        Channel
            .of("${resolveContainerPath(params.container_modeltest_ng)}")
            .set {ch_container_modeltest_ng}

        Channel
            .of("${resolveContainerPath(params.container_raxml_ng)}")
            .set {ch_container_raxml_ng}


        // Error handling for input params
        if (!params.data) {
            error "ERROR: Input directory of gene alignments not specified (--data)"
        }

        if (!params.filter_by_polymorphic_sites_cutoff) {
            error "ERROR: Cutoff for filtering by polymorphic sites not specified (--filter_by_polymorphic_sites_cutoff)"
        }

        if (!params.filter_by_nucleotide_diversity_start) {
            error "ERROR: Start of range for filtering by nucleotide diversity not specified (--filter_by_nucleotide_diversity_start)"
        }

        if (!params.filter_by_nucleotide_diversity_end) {
            error "ERROR: End of range for filtering by nucleotide diversity not specified (--filter_by_nucleotide_diversity_end)"
        }

        if (!params.filter_by_dnds_ratio_start) {
            error "ERROR: Start of range for filtering by dN/dS ratio not specified (--filter_by_dnds_ratio_start)"
        }

        if (!params.filter_by_dnds_ratio_end) {
            error "ERROR: End of range for filtering by dN/dS ratio not specified (--filter_by_dnds_ratio_end)"
        }


        // Input data
        Channel
            .fromPath("${params.data}/*", checkIfExists: true, type: "dir")
            .set {ch_input_alignments}

        Channel
            .of("${params.filter_by_polymorphic_sites_cutoff}")
            .set {ch_filter_by_polymorphic_sites_cutoff}

        Channel
            .of("${params.filter_by_nucleotide_diversity_start}")
            .set {ch_filter_by_nucleotide_diversity_start}
        
        Channel
            .of("${params.filter_by_nucleotide_diversity_end}")
            .set {ch_filter_by_nucleotide_diversity_end}

        Channel
            .of("${params.filter_by_dnds_ratio_start}")
            .set {ch_filter_by_dnds_ratio_start}
        
        Channel
            .of("${params.filter_by_dnds_ratio_end}")
            .set {ch_filter_by_dnds_ratio_end}


        // Process flow
        PREPARE_ID(ch_input_alignments
            .combine(ch_container_base)
            .combine(ch_cluster_options))
            .set {ch_alignments_with_id}

        FORMAT_HEADERS(ch_alignments_with_id
            .combine(ch_container_base)
            .combine(ch_cluster_options))
            .set {ch_formatted_alignments}

        FILTER_BY_POLYMORPHIC_SITES(ch_formatted_alignments
            .combine(ch_filter_by_polymorphic_sites_cutoff)
            .combine(ch_container_base)
            .combine(ch_cluster_options))
            .set {ch_filtered_alignments_1}
        
        FILTER_BY_NUCLEOTIDE_DIVERSITY(ch_filtered_alignments_1
            .combine(ch_filter_by_nucleotide_diversity_start)
            .combine(ch_filter_by_nucleotide_diversity_end)
            .combine(ch_container_base)
            .combine(ch_cluster_options))
            .set {ch_filtered_alignments_2}
        
        FILTER_BY_DNDS_RATIO(ch_filtered_alignments_2
            .combine(ch_filter_by_dnds_ratio_start)
            .combine(ch_filter_by_dnds_ratio_end)
            .combine(ch_container_base)
            .combine(ch_cluster_options))
            .set {ch_filtered_alignments_3}

        CONCATENATE_ALIGNMENTS(ch_filtered_alignments_3
            .combine(ch_container_base)
            .combine(ch_cluster_options))
            .set {ch_concatenated_alignment}

        CALCULATE_SUBSTITUTION_MODEL(ch_concatenated_alignment
            .combine(ch_container_modeltest_ng)
            .combine(ch_cluster_options))
            .set {ch_substitution_model}

        MAKE_PHYLOGENY(ch_concatenated_alignment
            .join(ch_substitution_model)
            .combine(ch_container_raxml_ng)
            .combine(ch_cluster_options))
            .set {ch_phylogeny}
}