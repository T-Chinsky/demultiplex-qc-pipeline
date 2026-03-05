/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { BCLCONVERT                 } from '../../modules/nf-core/bclconvert/main'
include { FASTQC                     } from '../../modules/nf-core/fastqc/main'
include { FASTQSCREEN_FASTQSCREEN    } from '../../modules/nf-core/fastqscreen/fastqscreen/main'
include { MULTIQC                    } from '../../modules/nf-core/multiqc/main'

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
    // MODULE: BCL Convert - Demultiplex BCL files to FASTQ
    //
    BCLCONVERT(ch_input)
    ch_versions = ch_versions.mix(BCLCONVERT.out.versions_bclconvert)

    //
    // Flatten the fastq channel for per-file QC
    //
    def ch_fastq_flat = BCLCONVERT.out.fastq
        .transpose()  // Converts [meta, [file1, file2]] to multiple [meta, file1], [meta, file2]

    //
    // MODULE: FastQC - Quality control of FASTQ files
    //
    def ch_fastqc_zip = channel.empty()
    if (!params.skip_fastqc) {
        FASTQC(ch_fastq_flat)
        ch_versions = ch_versions.mix(FASTQC.out.versions_fastqc.first())
        ch_fastqc_zip = FASTQC.out.zip.map { _meta, zip -> zip }
    }

    //
    // MODULE: fastq_screen - Contamination screening
    //
    def ch_fastq_screen_txt = channel.empty()
    if (!params.skip_fastq_screen) {
        FASTQSCREEN_FASTQSCREEN(ch_fastq_flat, ch_fastq_screen_config)
        ch_versions = ch_versions.mix(FASTQSCREEN_FASTQSCREEN.out.versions_fastqscreen.first())
        ch_fastq_screen_txt = FASTQSCREEN_FASTQSCREEN.out.txt.map { _meta, txt -> txt }
    }

    //
    // MODULE: MultiQC - Aggregate QC reports
    //
    // Collect all QC files
    def ch_multiqc_files = ch_fastqc_zip
        .mix(ch_fastq_screen_txt)
        .mix(BCLCONVERT.out.reports.map { _meta, reports -> reports }.flatten())
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
    fastq    = BCLCONVERT.out.fastq         // channel: [ val(meta), [ fastq files ] ]
    reports  = BCLCONVERT.out.reports       // channel: [ val(meta), [ report files ] ]
    versions = ch_versions                  // channel: [ versions.yml ]
    multiqc  = MULTIQC.out.report           // channel: [ val(meta), multiqc_report.html ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
