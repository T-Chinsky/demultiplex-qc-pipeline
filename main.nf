#!/usr/bin/env nextflow

/*
========================================================================================
    BCL CONVERT + QC PIPELINE
========================================================================================
    Workflow to demultiplex BCL files and perform comprehensive quality control
    - BCL Convert: Demultiplex Illumina BCL files to FASTQ
    - FastQC: Quality control of FASTQ files
    - fastq_screen: Contamination screening
    - MultiQC: Aggregate all QC reports
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { BCLCONVERT } from './modules/bclconvert'
include { FASTQC } from './modules/fastqc'
include { FASTQ_SCREEN } from './modules/fastq_screen'
include { MULTIQC } from './modules/multiqc'

workflow BCL_QC {
    take:
    samplesheet  // path: samplesheet CSV file
    run_dir      // path: BCL run directory
    fastq_screen_config  // path: fastq_screen config file (optional)

    main:
    // Run BCL Convert
    BCLCONVERT(samplesheet, run_dir)

    // Prepare FASTQ files for QC - flatten the glob output into individual files with metadata
    def fastq_ch = BCLCONVERT.out.fastq
        .flatten()
        .map { fastq ->
            def meta = [:]
            meta.id = fastq.simpleName.replaceAll(/_S\d+.*/, '')
            meta.single_end = !fastq.name.contains('_R2_')
            [meta, fastq]
        }

    // Run FastQC on all FASTQ files
    FASTQC(fastq_ch)

    // Run fastq_screen if config provided
    if (fastq_screen_config) {
        FASTQ_SCREEN(fastq_ch, fastq_screen_config)
    }

    // Collect all QC outputs for MultiQC
    def multiqc_files = channel.empty()
    multiqc_files = multiqc_files.mix(BCLCONVERT.out.reports)
    multiqc_files = multiqc_files.mix(FASTQC.out.zip.map { _meta, zip -> zip })
    
    if (fastq_screen_config) {
        multiqc_files = multiqc_files.mix(FASTQ_SCREEN.out.txt.map { _meta, txt -> txt })
    }

    // Run MultiQC
    MULTIQC(multiqc_files.collect())

    emit:
    fastq = BCLCONVERT.out.fastq
    fastqc_html = FASTQC.out.html
    fastqc_zip = FASTQC.out.zip
    fastq_screen_txt = fastq_screen_config ? FASTQ_SCREEN.out.txt : channel.empty()
    fastq_screen_html = fastq_screen_config ? FASTQ_SCREEN.out.html : channel.empty()
    multiqc_report = MULTIQC.out.report
    multiqc_data = MULTIQC.out.data
}

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    // Validate required parameters
    if (!params.samplesheet) {
        error "ERROR: --samplesheet parameter is required"
    }
    if (!params.run_dir) {
        error "ERROR: --run_dir parameter is required"
    }

    // Check input files exist
    def samplesheet_file = file(params.samplesheet)
    if (!samplesheet_file.exists()) {
        error "ERROR: Samplesheet does not exist: ${params.samplesheet}"
    }
    
    def run_dir_file = file(params.run_dir)
    if (!run_dir_file.exists()) {
        error "ERROR: Run directory does not exist: ${params.run_dir}"
    }
    
    def fastq_screen_config = null
    if (params.fastq_screen_config) {
        def config_file = file(params.fastq_screen_config)
        if (!config_file.exists()) {
            error "ERROR: fastq_screen config does not exist: ${params.fastq_screen_config}"
        }
        fastq_screen_config = config_file
    }

    // Run the workflow
    BCL_QC(
        samplesheet_file,
        run_dir_file,
        fastq_screen_config
    )

    // Print completion message
    workflow.onComplete {
        println ""
        println "Pipeline completed at: ${workflow.complete}"
        println "Execution status: ${workflow.success ? 'SUCCESS' : 'FAILED'}"
        println "Execution duration: ${workflow.duration}"
    }

    workflow.onError {
        println ""
        println "Pipeline execution failed!"
        println "Error message: ${workflow.errorMessage}"
    }
}
