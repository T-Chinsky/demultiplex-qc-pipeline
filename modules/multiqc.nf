process MULTIQC {
    label 'process_low'
    container 'community.wave.seqera.io/library/multiqc:1.25.2--d33ec18a85c9e91f'
    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path multiqc_files

    output:
    path 'multiqc_report.html', emit: report
    path 'multiqc_data', emit: data
    path 'versions.yml', emit: versions

    script:
    """
    multiqc \\
        --force \\
        --filename multiqc_report.html \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$(multiqc --version | sed -e 's/multiqc, version //g')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p multiqc_data
    touch multiqc_report.html
    touch multiqc_data/multiqc_data.json
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: 1.25.2
    END_VERSIONS
    """
}
