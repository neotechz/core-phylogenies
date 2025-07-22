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
include { MEASURE_RF_DISTANCE            } from '../modules/measure-rf-distance'
include { MEASURE_AVERAGE_SUPPORT        } from '../modules/measure-average-support'


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
            error "ERROR: Input directory not specified (--data)"
        }

        if(params.filter_only && params.measure_only) {
            error "ERROR: Cannot use both --filter_only and --measure_only options at the same time"
        }

        if (!params.filter_only && !params.data_reference) {
            error "ERROR: Reference tree for RF distance measurement not specified (--data_reference)"
        }

        if (!params.measure_only) {

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
        }

        // Input data
        if (!params.measure_only) {
            // Pipeline only needs input alignments if user wants to filter

            Channel
                .fromPath("${params.data}/*.fa*", checkIfExists: true, type: "file")
                .set {ch_input_alignments}
        }
        
        if (!params.filter_only){
            // Pipeline only needs input phylogenies if user wants to measure

            Channel
                .fromPath("${params.data}/*.tre", checkIfExists: true, type: "file")
                .branch { tree ->
                    reference: tree.endsWith("${params.data_reference}")
                    queries: true
                } // Separate reference tree from query trees, if applicable
                .set {ch_phylogenies}
        }
        
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

        Channel
            .of("${params.data.split('/').last()}"
                .concat("-${params.filter_by_polymorphic_sites_cutoff}")
                .concat("-${params.filter_by_nucleotide_diversity_start}")
                .concat("-${params.filter_by_nucleotide_diversity_end}")
                .concat("-${params.filter_by_dnds_ratio_start}")
                .concat("-${params.filter_by_dnds_ratio_end}"))
            .set {ch_data_name} // To identify the dataset and constraint values used


        // Process flow      
        if(!params.measure_only) {
            // Pipeline wont filter if user only wants to measure

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
                .filter( ~/(.)*\/(.)+/ ) // Only those with valid paths are retained
                .set {ch_filtered_alignments_1}
            
            FILTER_BY_NUCLEOTIDE_DIVERSITY(ch_filtered_alignments_1
                .combine(ch_filter_by_nucleotide_diversity_start)
                .combine(ch_filter_by_nucleotide_diversity_end)
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .filter( ~/(.)*\/(.)+/ ) // ^^
                .set {ch_filtered_alignments_2}
            
            FILTER_BY_DNDS_RATIO(ch_filtered_alignments_2
                .combine(ch_filter_by_dnds_ratio_start)
                .combine(ch_filter_by_dnds_ratio_end)
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .filter( ~/(.)*\/(.)+/ ) // ^^
                .set {ch_filtered_alignments_3}

            CONCATENATE_ALIGNMENTS(ch_data_name
                .combine(ch_filtered_alignments_3
                .map {gene -> gene[1]} // Extract the alignment path from the tuple
                .reduce("") {gene_1, gene_2 -> "$gene_1 $gene_2"}) // Concatenate all alignment paths
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .set {ch_concatenated_alignment}
        
        } else {
            // Pipeline has to prepare IDs for input phylogenetic trees, if user only wants to measure

            PREPARE_ID(ch_phylogenies.queries
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .set {ch_phylogeny}

        }

        if(!params.measure_only && !params.filter_only) { 
            // Pipeline wont make a phylogeny if user only wants to filter or measure

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

        if(!params.filter_only) {
            // Pipeline wont measure if user only wants to filter

            MEASURE_RF_DISTANCE(ch_phylogeny
                .combine(ch_phylogenies.reference)
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .set {ch_rf_distance}

            MEASURE_AVERAGE_SUPPORT(ch_phylogeny
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .set {ch_average_support}
        
        }
}