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

        Channel
            .of("${resolveContainerPath(params.container_iqtree2)}")
            .set {ch_container_iqtree2}

        Channel
            .of("${resolveContainerPath(params.container_fasttree)}")
            .set {ch_container_fasttree}


        // Error handling for input params
        if (!params.data) {
            error "ERROR: Input directory not specified (--data)"
        }

        if (!params.pipeline_filter && !params.pipeline_phylo && !params.pipeline_measure) {
            error "ERROR: Cannot set all --pipeline_* options to false at the same time"
        }
        
        if (params.pipeline_filter && !params.pipeline_phylo && params.pipeline_measure) {
            error "ERROR: Cannot do both filtering and measuring togther without making phylogeny"
        }

        if (!params.pipeline_filter && params.pipeline_phylo && params.pipeline_measure) {
            error "ERROR: Cannot make phylogeny by supplying input concatenated alignment; please specify individual gene alignments"
        }

        if (params.pipeline_measure && !params.data_reference) {
            error "ERROR: Reference tree for RF distance measurement not specified (--data_reference)"
        }

        if (params.pipeline_filter) {
            // Pipeline needs to check for input constraints if user only wants to filter
            // Ranges must be complete

            if (!params.filter_by_nucleotide_diversity_start && params.filter_by_nucleotide_diversity_end) {
                error "ERROR: Start of range for filtering by nucleotide diversity not specified (--filter_by_nucleotide_diversity_start)"
            }

            if (params.filter_by_nucleotide_diversity_start && !params.filter_by_nucleotide_diversity_end) {
                error "ERROR: End of range for filtering by nucleotide diversity not specified (--filter_by_nucleotide_diversity_end)"
            }

            if (!params.filter_by_dnds_ratio_start && params.filter_by_dnds_ratio_end) {
                error "ERROR: Start of range for filtering by dN/dS ratio not specified (--filter_by_dnds_ratio_start)"
            }

            if (params.filter_by_dnds_ratio_start && !params.filter_by_dnds_ratio_end) {
                error "ERROR: End of range for filtering by dN/dS ratio not specified (--filter_by_dnds_ratio_end)"
            }
        }

        if (params.pipeline_phylo) {
            // Only when it has to make a phylogeny

            def valid_methods = ["raxml-ng", "iqtree2", "fasttree"]

            if(!params.make_phylogeny_method) {
                error "ERROR: Missing method ('raxml-ng', 'iqtree2', 'fasttree') for MAKE_PHYLOGENY module"
            }

            if (!valid_methods.contains(params.make_phylogeny_method)) {
                error "ERROR: Invalid value for MAKE_PHLOGENY method ('raxml-ng', 'iqtree2', 'fasttree')"
            }

        }


        // Input data
        if (params.pipeline_filter) {
            // Pipeline needs input alignments if user wants to filter

            Channel
                .fromPath("${params.data}/*.fa*", checkIfExists: true, type: "file")
                .set {ch_input_alignments}
        }

        if (params.pipeline_phylo) {
            // Pipeline needs to set the correct container for MAKE_PHYLOGENY if user wants to make phylogeny

            if (params.make_phylogeny_method == "raxml-ng") {

                ch_container_raxml_ng
                    .set{ch_container_make_phylogeny}

            } else if (params.make_phylogeny_method == "iqtree2") {

                ch_container_iqtree2
                    .set{ch_container_make_phylogeny}

            } else if (params.make_phylogeny_method == "fasttree") {
                
                ch_container_fasttree
                    .set{ch_container_make_phylogeny}

            }
        }

        if (params.pipeline_measure){
            // Pipeline needs input phylogenies if user wants to measure

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
                .concat("-${params.filter_by_polymorphic_sites_cutoff ?: ''}") // If null, it will be empty
                .concat("-${params.filter_by_nucleotide_diversity_start  ?: ''}") // ^
                .concat("-${params.filter_by_nucleotide_diversity_end ?: ''}") // ^
                .concat("-${params.filter_by_dnds_ratio_start ?: ''}") // ^
                .concat("-${params.filter_by_dnds_ratio_end  ?: ''}")) // ^
            .set {ch_data_name} // To identify the dataset and constraint values used


        // Process flow      
        if (params.pipeline_filter) {
            // If user wants to filter...

            PREPARE_ID(ch_input_alignments
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .collect(flat: false) // Wait for all alignments to be processed before continuing
                .flatMap {gene -> gene} // ^^^
                .set {ch_alignments_with_id}

            FORMAT_HEADERS(ch_alignments_with_id
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .collect(flat: false) // ^^^
                .flatMap {gene -> gene} // ^^^
                .set {ch_formatted_alignments}

            if (params.filter_by_polymorphic_sites_cutoff) {
                // Pipeline will filter by polymorphic sites if user specified a cutoff

                FILTER_BY_POLYMORPHIC_SITES(ch_formatted_alignments
                    .combine(ch_filter_by_polymorphic_sites_cutoff)
                    .combine(ch_container_base)
                    .combine(ch_cluster_options))
                    .filter( ~/(.)*\/(.)+/ ) // Only those with valid paths are retained
                    .collect(flat: false) // ^^^
                    .flatMap {gene -> gene} // ^^^
                    .set {ch_filtered_alignments_1}

            } else {
                 // No filtering by polymorphic sites, use formatted alignments directly

                ch_formatted_alignments
                    .set {ch_filtered_alignments_1}
            }

            if (params.filter_by_nucleotide_diversity_start && params.filter_by_nucleotide_diversity_end) {
                // Pipeline will filter by nucleotide diversity if user specified a range

                FILTER_BY_NUCLEOTIDE_DIVERSITY(ch_filtered_alignments_1
                    .combine(ch_filter_by_nucleotide_diversity_start)
                    .combine(ch_filter_by_nucleotide_diversity_end)
                    .combine(ch_container_base)
                    .combine(ch_cluster_options))
                    .filter( ~/(.)*\/(.)+/ ) // ^^
                    .collect(flat: false) // ^^^
                    .flatMap {gene -> gene} // ^^^
                    .set {ch_filtered_alignments_2}
            } else {
                // No filtering by nucleotide diversity, use previous alignments directly

                ch_filtered_alignments_1
                    .set {ch_filtered_alignments_2}
            }
            
            if (params.filter_by_dnds_ratio_start && params.filter_by_dnds_ratio_end) {
                // Pipeline will filter by dN/dS ratio if user specified a range

                FILTER_BY_DNDS_RATIO(ch_filtered_alignments_2
                    .combine(ch_filter_by_dnds_ratio_start)
                    .combine(ch_filter_by_dnds_ratio_end)
                    .combine(ch_container_base)
                    .combine(ch_cluster_options))
                    .filter( ~/(.)*\/(.)+/ ) // ^^
                    .collect(flat: false) // ^^^
                    .flatMap {gene -> gene} // ^^^
                    .set {ch_filtered_alignments_3}

            } else {
                // No filtering by dN/dS ratio, use previous alignments directly

                ch_filtered_alignments_2
                    .set {ch_filtered_alignments_3}
            }

            CONCATENATE_ALIGNMENTS(ch_data_name
                .combine(ch_filtered_alignments_3
                .map {gene -> gene[1]} // Extract the alignment path from the tuple
                .reduce("") {gene_1, gene_2 -> "$gene_1 $gene_2"}) // Concatenate all alignment paths
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .map {alignment -> [alignment[0], alignment[1]]} // Get only the ID and concatenated alignment path
                .set {ch_concatenated_alignment}
        
        } else {
            // Pipeline has to prepare IDs for input phylogenetic trees, if user only wants to measure

            PREPARE_ID(ch_phylogenies.queries
                .combine(ch_container_base)
                .combine(ch_cluster_options))
                .set {ch_phylogeny}

        }

        if(params.pipeline_phylo) { 
            // Pipeline will only make phylogeny if user only wants to
            // User can set this to FALSE if they only want to filter or measure

            if(params.make_phylogeny_method != 'fasttree') {
                // Substitution model for raxml-ng and iqtree2

                CALCULATE_SUBSTITUTION_MODEL(ch_concatenated_alignment
                    .combine(ch_container_modeltest_ng)
                    .combine(ch_cluster_options))
                    .set {ch_substitution_model} 

            } else {
                // No model needed for fasttree

                ch_concatenated_alignment
                    .map {alignment -> [alignment[0], "/"]} // Get only the ID, second element is filler
                    .set {ch_substitution_model} 
            }

            MAKE_PHYLOGENY(ch_concatenated_alignment
                .join(ch_substitution_model)
                .combine(ch_container_make_phylogeny)  // Depends on which method is used ('raxml-ng', 'iqtree2', 'fastttree')
                .combine(ch_cluster_options))
                .set {ch_phylogeny}

        }

        if(params.pipeline_measure) {
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