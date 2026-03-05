process FASTQC {
    tag "${meta.id}"
    label 'process_medium'
    container 'community.wave.seqera.io/library/fastqc:0.12.1--aa717e1a9d994d74'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.html'), emit: html
    tuple val(meta), path('*.zip'), emit: zip
    path 'versions.yml', emit: versions

    script:
    """
    # Create array of all FASTQ files
    printf '%s\\n' ${reads} > input_files.txt

    # Run FastQC on all files
    fastqc \\
        --quiet \\
        --threads ${task.cpus} \\
        ${reads}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: \$(fastqc --version | sed -e 's/FastQC v//g')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}_fastqc.html
    touch ${meta.id}_fastqc.zip
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastqc: 0.12.1
    END_VERSIONS
    """
}
