process FASTQ_SCREEN {
    tag "${meta.id}"
    label 'process_medium'
    container 'community.wave.seqera.io/library/fastq-screen:0.16.0--3b0a59ab6ab18664'

    input:
    tuple val(meta), path(reads)
    path config

    output:
    tuple val(meta), path('*_screen.txt'), emit: txt
    tuple val(meta), path('*_screen.html'), emit: html
    tuple val(meta), path('*_screen.png'), optional: true, emit: png
    path 'versions.yml', emit: versions

    script:
    def reads_command = reads instanceof List ? reads[0] : reads
    """
    # Run fastq_screen on first read file (or single-end)
    fastq_screen \\
        --conf ${config} \\
        --threads ${task.cpus} \\
        --outdir . \\
        --force \\
        ${reads_command}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: \$(fastq_screen --version 2>&1 | sed -e 's/fastq_screen v//g')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_screen.txt
    touch ${meta.id}_screen.html
    touch ${meta.id}_screen.png
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastq_screen: 0.16.0
    END_VERSIONS
    """
}
