/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BCL_QC_SINGLE_RUN } from '../subworkflows/local/bcl_qc_single_run'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BCLCONVERT {
    
    take:
    ch_input         // channel: [ val(meta), path(samplesheet), path(run_dir) ]
    ch_fastq_screen_config  // channel: path(fastq_screen_config) or empty

    main:
    ch_versions = channel.empty()

    //
    // Process each run through the BCL QC subworkflow
    //
    BCL_QC_SINGLE_RUN(
        ch_input,
        ch_fastq_screen_config
    )

    ch_versions = ch_versions.mix(BCL_QC_SINGLE_RUN.out.versions)

    emit:
    versions = ch_versions                     // channel: [ path(versions.yml) ]
    multiqc  = BCL_QC_SINGLE_RUN.out.multiqc   // channel: [ val(meta), path(multiqc_report.html) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
