include { CORE_PHYLOGENIES } from './workflows/core-phylogenies'

workflow {
    main:
        CORE_PHYLOGENIES()
}