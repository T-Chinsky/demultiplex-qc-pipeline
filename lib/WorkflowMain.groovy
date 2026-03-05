/*
========================================================================================
    WorkflowMain
========================================================================================
*/

class WorkflowMain {

    //
    // Print help message
    //
    public static String help(workflow, params, log) {
        def command = "nextflow run ${workflow.manifest.name} --input samplesheet.csv --outdir <OUTDIR> -profile docker"
        def help_string = """
        ========================================
        ${workflow.manifest.name} v${workflow.manifest.version}
        ========================================
        
        Usage:
            ${command}

        Required arguments:
            --input                       Path to comma-separated file containing information about the samples and BCL run directories

        Optional arguments:
            --outdir                      Output directory for results (default: './results')
            --fastq_screen_config         Path to FastQ Screen configuration file (optional)
            
        Resource options:
            --max_cpus                    Maximum number of CPUs (default: ${params.max_cpus})
            --max_memory                  Maximum memory (default: ${params.max_memory})
            --max_time                    Maximum time (default: ${params.max_time})

        Generic options:
            --help                        Display this help message
            --version                     Display pipeline version
            --publish_dir_mode            Method for publishing results (default: 'copy')

        """.stripIndent()

        return help_string
    }

    //
    // Print parameter summary log
    //
    public static String paramsSummaryLog(workflow, params) {
        def summary_log = """
        ========================================
        ${workflow.manifest.name} v${workflow.manifest.version}
        ========================================
        Input CSV               : ${params.input}
        Output directory        : ${params.outdir}
        FastQ Screen config     : ${params.fastq_screen_config ?: 'Not provided (skipping)'}
        Max CPUs                : ${params.max_cpus}
        Max memory              : ${params.max_memory}
        Max time                : ${params.max_time}
        Publish mode            : ${params.publish_dir_mode}
        ========================================
        """.stripIndent()

        return summary_log
    }

    //
    // Validate parameters
    //
    public static void validateParams(params, log) {
        // Check mandatory parameters
        if (!params.input) {
            log.error "ERROR: Please provide an input CSV file with --input"
            System.exit(1)
        }

        // Check input file exists
        def input_file = new File(params.input)
        if (!input_file.exists()) {
            log.error "ERROR: Input file does not exist: ${params.input}"
            System.exit(1)
        }

        // Check FastQ Screen config if provided
        if (params.fastq_screen_config) {
            def config_file = new File(params.fastq_screen_config)
            if (!config_file.exists()) {
                log.error "ERROR: FastQ Screen config file does not exist: ${params.fastq_screen_config}"
                System.exit(1)
            }
        }
    }

    //
    // Generate methods description for MultiQC
    //
    public static String toolCitationText(params) {
        def citation_text = """
        ## Tools
        
        - [BCL Convert](https://support.illumina.com/sequencing/sequencing_software/bcl-convert.html)
        - [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
        - [MultiQC](https://multiqc.info/)
        """.stripIndent()

        if (params.fastq_screen_config) {
            citation_text += "        - [FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)\n"
        }

        return citation_text
    }

    //
    // Generate workflow citation
    //
    public static String workflowCitation(workflow) {
        def workflow_citation = """
        If you use ${workflow.manifest.name} for your analysis please cite:

        * The pipeline
          https://github.com/${workflow.manifest.name}

        * The nf-core framework
          https://doi.org/10.1038/s41587-020-0439-x

        * Software dependencies
          https://github.com/${workflow.manifest.name}/blob/master/CITATIONS.md
        """.stripIndent()

        return workflow_citation
    }
}
