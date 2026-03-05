/*
========================================================================================
    BCL QC SINGLE RUN SUBWORKFLOW
========================================================================================
    Process a single BCL run through the complete QC workflow
*/

include { BCLCONVERT } from '../modules/bclconvert'
include { FASTQC } from '../modules/fastqc'
include { FASTQ_SCREEN } from '../modules/fastq_screen'
include { MULTIQC } from '../modules/multiqc'

workflow BCL_QC_SINGLE_RUN {
    take:
    run_id
    samplesheet
    run_dir
    multiqc_title
    fastq_screen_config

    main:
    // Run BCL Convert
    BCLCONVERT(run_id, samplesheet, run_dir)

    // Prepare FASTQ files for QC
    def fastq_ch = BCLCONVERT.out.fastq
        .flatten()
        .map { fastq ->
            def meta = [:]
            meta.id = fastq.simpleName.replaceAll(/_S\d+.*/, '')
            meta.run_id = run_id
            meta.single_end = !fastq.name.contains('_R2_')
            tuple(meta, fastq)
        }

    // Run FastQC
    FASTQC(fastq_ch)

    // Run fastq_screen if config provided
    def fastq_screen_txt = channel.empty()
    if (fastq_screen_config) {
        FASTQ_SCREEN(fastq_ch, fastq_screen_config)
        fastq_screen_txt = FASTQ_SCREEN.out.txt
    }

    // Collect all QC outputs for MultiQC
    def multiqc_files = BCLCONVERT.out.reports
        .mix(FASTQC.out.zip.map { _meta, zip -> zip })
        .mix(fastq_screen_txt.map { _meta, txt -> txt })
        .collect()

    // Run MultiQC with custom title
    MULTIQC(run_id, multiqc_files, multiqc_title)

    emit:
    multiqc_report = MULTIQC.out.report
}
