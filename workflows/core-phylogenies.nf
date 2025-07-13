// Default module imports
include { PREPARE_ID                     } from '../modules/prepare-id'
include { FORMAT_HEADERS                 } from '../modules/format-headers'
// include { FILTER_BY_POLYMORPHIC_SITES    } from '../modules/filter-by-polymorphic-sites'
include { FILTER_BY_NUCLEOTIDE_DIVERSITY } from '../modules/filter-by-nucleotide-diversity'
include { FILTER_BY_DNDS_RATIO           } from '../modules/filter-by-dnds-ratio'
include { CONCATENATE_ALIGNMENTS         } from '../modules/concatenate-alignments'
include { CALCULATE_SUBSTITUTION_MODEL   } from '../modules/calculate-substitution-model'
include { MAKE_PHYLOGENY                 } from '../modules/make-phylogeny'


// Pipeline workflow
workflow CORE_PHYLOGENIES {
    main:
        Channel
            .fromPath("${params.data}/*", checkIfExists: true, type: "dir")
            .set {ch_input_alignments}
        
        PREPARE_ID(ch_input_alignments)
            .set {ch_alignments_with_id}

        FORMAT_HEADERS(ch_alignments_with_id)
            .set {ch_formatted_alignments}

        /*
        Channel
            .of("${params.filter_by_polymorphic_sites_cutoff}")
            .set {ch_filter_by_polymorphic_sites_cutoff}

        FILTER_BY_POLYMORPHIC_SITES(ch_formatted_alignments
            .combine(ch_filter_by_polymorphic_sites_cutoff))
            .set {ch_filtered_alignments_1}
        */ 

        Channel
            .of("${params.filter_by_nucleotide_diversity_start}")
            .set {ch_filter_by_nucleotide_diversity_start}
        
        Channel
            .of("${params.filter_by_nucleotide_diversity_end}")
            .set {ch_filter_by_nucleotide_diversity_end}
        
        FILTER_BY_NUCLEOTIDE_DIVERSITY(ch_formatted_alignments
            .combine(ch_filter_by_nucleotide_diversity_start)
            .combine(ch_filter_by_nucleotide_diversity_end))
            .set {ch_filtered_alignments_2}
        
        Channel
            .of("${params.filter_by_dnds_ratio_start}")
            .set {ch_filter_by_dnds_ratio_start}
        
        Channel
            .of("${params.filter_by_dnds_ratio_end}")
            .set {ch_filter_by_dnds_ratio_end}
        
        FILTER_BY_DNDS_RATIO(ch_filtered_alignments_2
            .combine(ch_filter_by_dnds_ratio_start)
            .combine(ch_filter_by_dnds_ratio_end))
            .set {ch_filtered_alignments_3}

        CONCATENATE_ALIGNMENTS(ch_filtered_alignments_3)
            .set {ch_concatenated_alignment}

        CALCULATE_SUBSTITUTION_MODEL(ch_concatenated_alignment)
            .set {ch_substitution_model}

        MAKE_PHYLOGENY(ch_concatenated_alignment
            .join(ch_substitution_model))
            .set {ch_phylogeny}
}