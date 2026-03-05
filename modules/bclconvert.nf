process BCLCONVERT {
    tag "${run_id}"
    label 'process_high'
    container 'community.wave.seqera.io/library/bclconvert:4.2.7--abc21b231d8db3e0'
    publishDir "${params.outdir}/${run_id}/bclconvert", mode: 'copy'

    input:
    val run_id
    path samplesheet
    path run_dir

    output:
    path 'output/**_S*_R*.fastq.gz', emit: fastq
    path 'output/Reports', emit: reports
    path 'output/Logs', emit: logs
    path 'output/InterOp/*.bin', optional: true, emit: interop
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
    echo "  bclconvert: 4.2.7" >> versions.yml
    """
}
