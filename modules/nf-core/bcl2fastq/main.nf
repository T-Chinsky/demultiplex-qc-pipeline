process BCL2FASTQ {
    tag "${meta.run_id}"
    label 'process_high'
    
    container 'community.wave.seqera.io/library/bcl2fastq2:2.20.0--1d9942001bacdbaa'
    
    input:
    tuple val(meta), path(run_dir)
    path(samplesheet)
    
    output:
    tuple val(meta), path("output/**.fastq.gz"), emit: fastq
    tuple val(meta), path("output/Reports"), emit: reports
    tuple val(meta), path("output/Stats"), emit: stats
    path("versions.yml"), emit: versions
    
    script:
    def args = task.ext.args ?: ''
    def loading_threads = Math.max(1, (task.cpus * 0.25) as int)
    def processing_threads = Math.max(1, (task.cpus * 0.25) as int)
    def writing_threads = Math.max(1, (task.cpus * 0.5) as int)
    
    """
    bcl2fastq \\
        --runfolder-dir ${run_dir} \\
        --output-dir output \\
        --sample-sheet ${samplesheet} \\
        --loading-threads ${loading_threads} \\
        --processing-threads ${processing_threads} \\
        --writing-threads ${writing_threads} \\
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcl2fastq2: \$(bcl2fastq --version 2>&1 | grep -oP 'bcl2fastq v\\K[0-9.]+')
    END_VERSIONS
    """
    
    stub:
    """
    mkdir -p output/Reports output/Stats
    touch output/Sample1_S1_L001_R1_001.fastq.gz
    touch output/Sample1_S1_L001_R2_001.fastq.gz
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcl2fastq2: 2.20.0
    END_VERSIONS
    """
}
