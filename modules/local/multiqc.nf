process MULTIQC {
    tag "${meta.id}"
    label 'process_low'
    container 'community.wave.seqera.io/library/multiqc:1.25.2--d33ec18a85c9e91f'
    publishDir "${params.outdir}/${meta.id}/multiqc", mode: params.publish_dir_mode

    input:
    tuple val(meta), path('*')

    output:
    tuple val(meta), path("${meta.id}_multiqc_report.html"), emit: report
    tuple val(meta), path('multiqc_data'), emit: data
    path 'versions.yml', emit: versions

    script:
    def title = meta.multiqc_title ?: meta.id
    """
    multiqc \\
        --force \\
        --title "${title}" \\
        --filename ${meta.id}_multiqc_report.html \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed -e 's/multiqc, version //g')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p multiqc_data
    touch ${meta.id}_multiqc_report.html
    touch multiqc_data/multiqc_data.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: 1.25.2
    END_VERSIONS
    """
}
