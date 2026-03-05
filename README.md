# BCL Convert + QC Pipeline

A Nextflow DSL2 pipeline for demultiplexing Illumina BCL files and performing comprehensive quality control.

## Features

- ✅ **BCL Convert**: Demultiplex Illumina BCL files to FASTQ format
- ✅ **FastQC**: Quality control assessment of sequencing reads
- ✅ **fastq_screen**: Optional contamination screening
- ✅ **MultiQC**: Aggregated HTML reports combining all QC metrics
- ✅ **Container-based**: Reproducible execution with Docker/Singularity
- ✅ **Scalable**: Automatic parallelization and resource management
- ✅ **Resume**: Continue from failed tasks with `-resume`

## Quick Start

### Prerequisites

- Nextflow >= 25.04.0
- Docker or Singularity

### Basic Usage

```bash
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --run_dir /path/to/bcl/run \
  --outdir results
```

### With Contamination Screening

```bash
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --run_dir /path/to/bcl/run \
  --outdir results \
  --fastq_screen_config fastq_screen.conf
```

### On SLURM Cluster

```bash
nextflow run main.nf \
  -profile slurm \
  --samplesheet samplesheet.csv \
  --run_dir /path/to/bcl/run
```

## Parameters

### Required
- `--samplesheet`: Path to BCL Convert samplesheet CSV file
- `--run_dir`: Path to Illumina BCL run directory

### Optional
- `--outdir`: Output directory (default: `./results`)
- `--fastq_screen_config`: Path to fastq_screen config (enables contamination screening)
- `--bcl_sampleproject_subdirectories`: Create subdirectories by sample project (default: `false`)
- `--no_lane_splitting`: Disable lane splitting in BCL Convert (default: `false`)

### Resource Limits
- `--max_cpus`: Maximum CPUs (default: `32`)
- `--max_memory`: Maximum memory (default: `256.GB`)
- `--max_time`: Maximum time (default: `24.h`)

## Output Structure

```
results/
├── bclconvert/          # Demultiplexed FASTQ files + BCL Convert reports
├── fastqc/              # FastQC quality control reports
├── fastq_screen/        # Contamination screening results (optional)
├── multiqc/             
│   └── multiqc_report.html  ← START HERE for QC review
└── pipeline_info/       # Execution reports and logs
```

## Profiles

- `standard`: Local execution (default)
- `docker`: Docker containers
- `singularity`: Singularity containers
- `slurm`: SLURM scheduler (pre-configured for UMass cluster)

## Container Images

All tools use pre-built Wave containers:
- BCL Convert: 4.2.7
- FastQC: 0.12.1
- fastq_screen: 0.15.3
- MultiQC: 1.25.2

## License

MIT License

## Citation

If you use this pipeline, please cite:
- **Nextflow**: Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. Nature Biotechnology.
- **BCL Convert**: Illumina, Inc.
- **FastQC**: Andrews, S. (2010). FastQC: a quality control tool for high throughput sequence data.
- **MultiQC**: Ewels, P., et al. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report.
