#!/usr/bin/env nextflow

/*
========================================================================================
    BCL CONVERT + QC PIPELINE
========================================================================================
    Workflow to demultiplex BCL files and perform comprehensive quality control
    - BCL Convert: Demultiplex Illumina BCL files to FASTQ
    - FastQC: Quality control of FASTQ files
    - fastq_screen: Contamination screening
    - MultiQC: Aggregate all QC reports (one per run)
----------------------------------------------------------------------------------------
*/

nextflow.enable.dsl = 2

/*
========================================================================================
    NAMED WORKFLOW FOR PIPELINE
========================================================================================
*/

include { BCL_QC_SINGLE_RUN } from './subworkflows/bcl_qc_single_run'

/*
========================================================================================
    MAIN WORKFLOW
========================================================================================
*/

workflow {
    // Validate required parameters
    if (!params.input) {
        error "ERROR: --input parameter is required (CSV with run_id,samplesheet,run_dir,multiqc_title)"
    }

    // Parse the input CSV
    def input_csv = file(params.input)
    if (!input_csv.exists()) {
        error "ERROR: Input CSV does not exist: ${params.input}"
    }
    
    // Prepare fastq_screen config if provided
    def fastq_screen_config = null
    if (params.fastq_screen_config) {
        def config_file = file(params.fastq_screen_config)
        if (!config_file.exists()) {
            error "ERROR: fastq_screen config does not exist: ${params.fastq_screen_config}"
        }
        fastq_screen_config = config_file
    }

    // Create channel with run metadata tuples
    def runs_ch = channel
        .fromPath(input_csv)
        .splitCsv(header: true)
        .map { row ->
            def run_id = row.run_id
            def samplesheet = file(row.samplesheet, checkIfExists: true)
            def run_dir = file(row.run_dir, checkIfExists: true)
            def multiqc_title = row.multiqc_title ?: run_id
            tuple(run_id, samplesheet, run_dir, multiqc_title)
        }

    // Process each run through the BCL QC subworkflow
    BCL_QC_SINGLE_RUN(
        runs_ch.map { v -> v[0] },  // run_id
        runs_ch.map { v -> v[1] },  // samplesheet
        runs_ch.map { v -> v[2] },  // run_dir
        runs_ch.map { v -> v[3] },  // multiqc_title
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
