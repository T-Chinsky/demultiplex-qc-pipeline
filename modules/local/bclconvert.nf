process BCLCONVERT {
    tag "${meta.id}"
    label 'process_high'
    container 'docker://ubgbc/bcl-convert:4.4.6'
    publishDir "${params.outdir}/${meta.id}/bclconvert", mode: params.publish_dir_mode

    input:
    tuple val(meta), path(samplesheet), path(run_dir)

    output:
    tuple val(meta), path('output/**_S*_R*.fastq.gz'), emit: fastq
    tuple val(meta), path('output/Reports'), emit: reports
    tuple val(meta), path('output/Logs'), emit: logs
    tuple val(meta), path('output/InterOp/*.bin'), optional: true, emit: interop
    path 'versions.yml', emit: versions

    script:
    def args = []
    if (params.bcl_sampleproject_subdirectories) {
        args.add('--bcl-sampleproject-subdirectories true')
    }
    if (params.no_lane_splitting) {
        args.add('--no-lane-splitting true')
    }
    def extra_args = args.join(' ')
    """
    bcl-convert \\
        --sample-sheet ${samplesheet} \\
        --bcl-input-directory ${run_dir} \\
        --output-directory output \\
        --force \\
        ${extra_args}

    # Generate versions file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bclconvert: \$(bcl-convert --version 2>&1 | sed -e 's/bcl-convert Version //g')
    END_VERSIONS
    """

    stub:
    """
    mkdir -p output/Reports output/Logs output/InterOp
    touch output/sample_S1_R1_001.fastq.gz
    touch output/sample_S1_R2_001.fastq.gz
    touch output/Reports/Adapter_Metrics.csv
    touch output/Reports/Demultiplex_Stats.csv
    touch output/Reports/Quality_Metrics.csv
    touch output/Logs/Errors.log
    touch output/InterOp/IndexMetricsOut.bin
    echo "${task.process}:" > versions.yml
    echo "  bclconvert: 4.4.6" >> versions.yml
    """
}
