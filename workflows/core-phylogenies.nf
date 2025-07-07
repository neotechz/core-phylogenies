// Default module imports
include { PREPARE_ID                   } from '../modules/prepare-id'
include { CALCULATE_SUBSTITUTION_MODEL } from '../modules/calculate-substitution-model'
include { MAKE_PHYLOGENY               } from '../modules/make-phylogeny'


// Pipeline workflow
workflow CORE_PHYLOGENIES {
    main:
        Channel
            .fromPath("${params.data}/*-aligned.fasta", checkIfExists: true)
            .set {ch_alignment}

        PREPARE_ID(ch_alignment)
            .set {ch_alignment_with_id}

        CALCULATE_SUBSTITUTION_MODEL(ch_alignment_with_id)
            .set {ch_substitution_model}

        MAKE_PHYLOGENY(ch_alignment_with_id
            .join(ch_substitution_model))
            .set {ch_phylogeny}
        
}