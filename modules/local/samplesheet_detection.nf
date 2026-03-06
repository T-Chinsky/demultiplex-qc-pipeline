#!/usr/bin/env nextflow

/*
 * Process to detect samplesheet format version
 */

process DETECT_SAMPLESHEET_VERSION {
    tag "$sample_id"
    
    input:
    tuple val(sample_id), path(samplesheet)
    path detection_script
    
    output:
    tuple val(sample_id), env('VERSION'), emit: version
    tuple val(sample_id), path(samplesheet), emit: samplesheet
    
    script:
    """
    VERSION=\$(python3 ${detection_script} ${samplesheet})
    """
}
