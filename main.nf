#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/bclconvert
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/T-Chinsky/bcl-convert-pipeline
    Website: https://nf-co.re/bclconvert
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Function to check resource limits
def check_max(obj, type, params) {
    if (type == 'memory') {
        try {
            if (obj.compareTo(params.max_memory as nextflow.util.MemoryUnit) == 1)
                return params.max_memory as nextflow.util.MemoryUnit
            else
                return obj
        } catch (_all) {
            println "   ### ERROR ###   Max memory '${params.max_memory}' is not valid! Using default value: $obj"
            return obj
        }
    } else if (type == 'time') {
        try {
            if (obj.compareTo(params.max_time as nextflow.util.Duration) == 1)
                return params.max_time as nextflow.util.Duration
            else
                return obj
        } catch (_all) {
            println "   ### ERROR ###   Max time '${params.max_time}' is not valid! Using default value: $obj"
            return obj
        }
    } else if (type == 'cpus') {
        try {
            return Math.min(obj as int, params.max_cpus as int)
        } catch (_all) {
            println "   ### ERROR ###   Max cpus '${params.max_cpus}' is not valid! Using default value: $obj"
            return obj as int
        }
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BCLCONVERT  } from './workflows/bclconvert'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELPER FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def helpMessage() {
    def command = "nextflow run ${workflow.manifest.name} --input samplesheet.csv --outdir <OUTDIR> -profile docker"
    return """
    ========================================
    ${workflow.manifest.name} v${workflow.manifest.version}
    ========================================
    
    Usage:
        ${command}

    Required arguments:
        --input                       Path to comma-separated file containing information about the samples and BCL run directories

    Optional arguments:
        --outdir                      Output directory for results (default: './results')
        --fastq_screen_config         Path to FastQ Screen configuration file (optional)
        
    Resource options:
        --max_cpus                    Maximum number of CPUs (default: ${params.max_cpus})
        --max_memory                  Maximum memory (default: ${params.max_memory})
        --max_time                    Maximum time (default: ${params.max_time})

    Generic options:
        --help                        Display this help message
        --version                     Display pipeline version
        --publish_dir_mode            Method for publishing results (default: 'copy')

    """.stripIndent()
}

def paramsSummary() {
    return """
    ========================================
    ${workflow.manifest.name} v${workflow.manifest.version}
    ========================================
    Input CSV               : ${params.input}
    Output directory        : ${params.outdir}
    FastQ Screen config     : ${params.fastq_screen_config ?: 'Not provided (skipping)'}
    Max CPUs                : ${params.max_cpus}
    Max memory              : ${params.max_memory}
    Max time                : ${params.max_time}
    Publish mode            : ${params.publish_dir_mode}
    ========================================
    """.stripIndent()
}

def validateParams() {
    // Check mandatory parameters
    if (!params.input) {
        log.error "ERROR: Please provide an input CSV file with --input"
        System.exit(1)
    }

    // Check input file exists
    def input_file = file(params.input, checkIfExists: false)
    if (!input_file.exists()) {
        log.error "ERROR: Input file does not exist: ${params.input}"
        System.exit(1)
    }

    // Check FastQ Screen config if provided
    if (params.fastq_screen_config) {
        def config_file = file(params.fastq_screen_config, checkIfExists: false)
        if (!config_file.exists()) {
            log.error "ERROR: FastQ Screen config file does not exist: ${params.fastq_screen_config}"
            System.exit(1)
        }
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline
//
workflow NFCORE_BCLCONVERT {

    take:
    ch_input         // channel: [ val(meta), path(samplesheet), path(run_dir) ]
    ch_fastq_screen_config  // channel: path(fastq_screen_config) or empty

    main:

    //
    // WORKFLOW: Run pipeline
    //
    BCLCONVERT(
        ch_input,
        ch_fastq_screen_config
    )

    emit:
    multiqc = BCLCONVERT.out.multiqc      // channel: [ val(meta), path(html) ]
    versions = BCLCONVERT.out.versions    // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    //
    // Print help message if requested
    //
    if (params.help) {
        log.info helpMessage()
        System.exit(0)
    }

    //
    // Print version if requested
    //
    if (params.version) {
        log.info "${workflow.manifest.name} ${workflow.manifest.version}"
        System.exit(0)
    }

    //
    // Validate parameters
    //
    validateParams()

    //
    // Print parameter summary
    //
    log.info paramsSummary()

    //
    // Parse input CSV and create channels
    //
    def input_csv = file(params.input, checkIfExists: true)
    
    def ch_input = channel
        .fromPath(input_csv)
        .splitCsv(header: true)
        .map { row ->
            // Create meta map following nf-core conventions
            def meta = [
                id: row.run_id,
                multiqc_title: row.multiqc_title ?: row.run_id
            ]
            def samplesheet = file(row.samplesheet, checkIfExists: true)
            def run_dir = file(row.run_dir, checkIfExists: true)
            
            tuple(meta, samplesheet, run_dir)
        }

    //
    // Prepare FastQ Screen config channel
    //
    def ch_fastq_screen_config = params.fastq_screen_config 
        ? channel.fromPath(params.fastq_screen_config, checkIfExists: true)
        : channel.empty()

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_BCLCONVERT(
        ch_input,
        ch_fastq_screen_config
    )

    //
    // Completion handlers
    //
    workflow.onComplete {
        log.info """
        ========================================
        Pipeline completed!
        ========================================
        Status:   ${workflow.success ? 'SUCCESS' : 'FAILED'}
        Time:     ${workflow.complete}
        Duration: ${workflow.duration}
        Output:   ${params.outdir}
        ========================================
        """.stripIndent()
    }

    workflow.onError {
        log.error """
        ========================================
        Pipeline failed!
        ========================================
        Error:    ${workflow.errorMessage}
        Report:   ${workflow.errorReport}
        ========================================
        """.stripIndent()
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
