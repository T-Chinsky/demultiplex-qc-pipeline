/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BCLCONVERT                 } from '../../modules/local/bclconvert'
include { BCL2FASTQ                  } from '../../modules/nf-core/bcl2fastq/main'
include { FASTQC                     } from '../../modules/local/fastqc'
include { FASTQ_SCREEN               } from '../../modules/local/fastq_screen'
include { MULTIQC                    } from '../../modules/local/multiqc'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW: Process a single BCL run through conversion and QC
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow BCL_QC_SINGLE_RUN {
    
    take:
    ch_input              // channel: [ val(meta), path(samplesheet), path(run_dir) ]
    ch_fastq_screen_config // channel: path(fastq_screen_config) or empty

    main:
    ch_versions = channel.empty()

    //
    // Detect samplesheet version and select appropriate demultiplexing tool
    //
    def ch_input_with_tool = ch_input
        .map { meta, samplesheet, run_dir ->
            // Detect samplesheet version using the detection script
            def version_detect = """
            ${projectDir}/bin/detect_samplesheet_version.py ${samplesheet}
            """.execute()
            version_detect.waitFor()
            def version = version_detect.text.trim()
            
            // Determine demux tool based on version or user override
            def demux_tool = params.demux_tool ?: (version == 'v1' ? 'bcl2fastq' : 'bclconvert')
            
            // Add tool info to meta
            def meta_with_tool = meta + [demux_tool: demux_tool, samplesheet_version: version]
            
            tuple(meta_with_tool, samplesheet, run_dir)
        }

    //
    // Split input based on demux tool
    //
    def ch_bclconvert_input = ch_input_with_tool
        .filter { meta, _samplesheet, _run_dir -> meta.demux_tool == 'bclconvert' }
    
    def ch_bcl2fastq_input = ch_input_with_tool
        .filter { meta, _samplesheet, _run_dir -> meta.demux_tool == 'bcl2fastq' }

    //
    // MODULE: BCL Convert - Demultiplex BCL files to FASTQ (v2 samplesheets)
    //
    def ch_demux_fastq = channel.empty()
    def ch_demux_reports = channel.empty()
    
    if (!ch_bclconvert_input.isEmpty()) {
        BCLCONVERT(ch_bclconvert_input)
        ch_versions = ch_versions.mix(BCLCONVERT.out.versions)
        ch_demux_fastq = ch_demux_fastq.mix(BCLCONVERT.out.fastq)
        ch_demux_reports = ch_demux_reports.mix(BCLCONVERT.out.reports)
    }

    //
    // MODULE: BCL2FASTQ - Demultiplex BCL files to FASTQ (v1 samplesheets)
    //
    if (!ch_bcl2fastq_input.isEmpty()) {
        // BCL2FASTQ requires two separate inputs: tuple(meta, run_dir) and path(samplesheet)
        def ch_bcl2fastq_meta_run = ch_bcl2fastq_input.map { meta, _samplesheet, run_dir -> 
            tuple(meta, run_dir)
        }
        def ch_bcl2fastq_samplesheet = ch_bcl2fastq_input.map { _meta, samplesheet, _run_dir -> 
            samplesheet
        }
        
        BCL2FASTQ(ch_bcl2fastq_meta_run, ch_bcl2fastq_samplesheet)
        ch_versions = ch_versions.mix(BCL2FASTQ.out.versions)
        ch_demux_fastq = ch_demux_fastq.mix(BCL2FASTQ.out.fastq)
        ch_demux_reports = ch_demux_reports.mix(BCL2FASTQ.out.reports)
    }

    //
    // Flatten the fastq channel for per-file QC
    //
    def ch_fastq_flat = ch_demux_fastq
        .transpose()  // Converts [meta, [file1, file2]] to multiple [meta, file1], [meta, file2]

    //
    // MODULE: FastQC - Quality control of FASTQ files
    //
    def ch_fastqc_zip = channel.empty()
    if (!params.skip_fastqc) {
        FASTQC(ch_fastq_flat)
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
        ch_fastqc_zip = FASTQC.out.zip.map { _meta, zip -> zip }
    }

    //
    // MODULE: fastq_screen - Contamination screening
    //
    def ch_fastq_screen_txt = channel.empty()
    if (!params.skip_fastq_screen) {
        FASTQ_SCREEN(ch_fastq_flat, ch_fastq_screen_config)
        ch_versions = ch_versions.mix(FASTQ_SCREEN.out.versions.first())
        ch_fastq_screen_txt = FASTQ_SCREEN.out.txt.map { _meta, txt -> txt }
    }

    //
    // MODULE: MultiQC - Aggregate QC reports
    //
    // Collect all QC files
    def ch_multiqc_files = ch_fastqc_zip
        .mix(ch_fastq_screen_txt)
        .mix(ch_demux_reports.map { _meta, reports -> reports }.flatten())
        .collect()
        .ifEmpty([])
    
    // Create MultiQC input with meta - nf-core module expects:
    // tuple val(meta), path(multiqc_files), path(multiqc_config), path(multiqc_logo), path(replace_names), path(sample_names)
    def ch_multiqc_input = ch_input
        .first()
        .map { meta, _samplesheet, _run_dir -> tuple(meta) }
        .combine(ch_multiqc_files)
        .map { meta, files ->
            tuple(
                meta,
                files,
                [],  // multiqc_config
                [],  // multiqc_logo
                [],  // replace_names
                []   // sample_names
            )
        }
    
    MULTIQC(ch_multiqc_input)
    ch_versions = ch_versions.mix(MULTIQC.out.versions)

    emit:
    fastq    = ch_demux_fastq               // channel: [ val(meta), [ fastq files ] ]
    reports  = ch_demux_reports             // channel: [ val(meta), [ report files ] ]
    versions = ch_versions                  // channel: [ versions.yml ]
    multiqc  = MULTIQC.out.report           // channel: [ val(meta), multiqc_report.html ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
