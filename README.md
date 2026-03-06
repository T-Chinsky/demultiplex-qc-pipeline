# Demultiplex QC Pipeline

A Nextflow DSL2 pipeline for batch processing multiple Illumina sequencing runs with comprehensive quality control. Supports both **BCL Convert** (v2 samplesheets) and **bcl2fastq2** (v1 samplesheets) with automatic format detection.

## Features

- ✅ **Dual Demultiplexer Support**: Automatically detects and uses BCL Convert or bcl2fastq2 based on samplesheet format
- ✅ **Automatic Format Detection**: Seamlessly handles v1 (bcl2fastq2) and v2 (BCL Convert) samplesheet formats
- ✅ **Batch Processing**: Process multiple BCL runs simultaneously from a single CSV input
- ✅ **Direct Samplesheet Support**: Use your existing samplesheets without reformatting
- ✅ **Custom MultiQC Titles**: Set descriptive report titles for each run
- ✅ **FastQC**: Quality control assessment of sequencing reads
- ✅ **fastq_screen**: Optional contamination screening
- ✅ **MultiQC**: Separate QC reports for each run with custom titles
- ✅ **Container-based**: Reproducible execution with Docker/Singularity via Wave containers
- ✅ **Scalable**: Automatic parallelization and resource management
- ✅ **Resume**: Continue from failed tasks with `-resume`

## Quick Start

### Prerequisites

- Nextflow >= 25.04.0
- Docker or Singularity

### Basic Usage

```bash
nextflow run main.nf \
  --input runs.csv \
  --outdir results
```

The pipeline automatically detects whether to use **BCL Convert** or **bcl2fastq2** based on your samplesheet format. No manual configuration needed!

See [INPUT_FORMAT.md](INPUT_FORMAT.md) for detailed CSV format documentation.

**Example `runs.csv`:**
```csv
run_id,samplesheet,run_dir,multiqc_title
run1,/data/runs/2024_01_15/SampleSheet.csv,/data/runs/2024_01_15,Cancer Panel - Batch 1
run2,/data/runs/2024_01_16/SampleSheet.csv,/data/runs/2024_01_16,RNA-Seq Controls
```

### Automatic Format Detection

The pipeline intelligently detects the samplesheet format and chooses the appropriate demultiplexer:

**Detection Logic:**
1. **BCL Convert (v2)** is used when the samplesheet contains:
   - `[BCLConvert_Settings]` section, OR
   - `[BCLConvert_Data]` section

2. **bcl2fastq2 (v1)** is used when the samplesheet contains:
   - `[Reads]` section (specifying read lengths), OR
   - `IEMFileVersion=4` in the header

**Manual Override:**
You can bypass auto-detection using the `--demux_tool` parameter:
```bash
# Force BCL Convert
nextflow run main.nf --input runs.csv --demux_tool bclconvert

# Force bcl2fastq2
nextflow run main.nf --input runs.csv --demux_tool bcl2fastq
```

**Mixed Batches:**
You can process runs with different samplesheet formats in the same batch - the pipeline will automatically use the correct tool for each run!

### With Contamination Screening

First, set up fastq_screen databases following the [FASTQ_SCREEN_SETUP.md](FASTQ_SCREEN_SETUP.md) guide.

```bash
nextflow run main.nf \
  --input runs.csv \
  --outdir results \
  --fastq_screen_config /path/to/fastq_screen.conf
```

### On SLURM Cluster

```bash
nextflow run main.nf \
  -profile slurm \
  --input runs.csv
```

## FastQ Screen Setup (Optional)

For contamination screening, you'll need to download and build reference genome databases. See the comprehensive guide:

📖 **[FASTQ_SCREEN_SETUP.md](FASTQ_SCREEN_SETUP.md)** - Complete instructions for downloading and indexing all 12 reference genomes

**Quick summary:**
- Download genomes (hg38, mm10, rat, univec, phix, adapters, ecoli, yeast, drosophila, mycoplasma, viral, bacterial)
- Build Bowtie2 indexes for each genome
- Create `fastq_screen.conf` pointing to your indexes
- Pass config file to pipeline with `--fastq_screen_config`

**Minimal setup (recommended for testing):** PhiX + Adapters + E.coli + UniVec (~2 GB, 30 minutes)

**Full setup:** All 12 genomes (~25 GB indexed, 5-6 hours build time)

## Input Files

### Input CSV Format

The `--input` parameter accepts a CSV file with the following columns:

| Column | Required | Description |
|--------|----------|-------------|
| `run_id` | Yes | Unique identifier for the run (used in output directory naming) |
| `samplesheet` | Yes | Full path to the BCL Convert samplesheet |
| `run_dir` | Yes | Full path to the BCL run directory |
| `multiqc_title` | No | Custom title for the MultiQC report (defaults to `run_id`) |

See [INPUT_FORMAT.md](INPUT_FORMAT.md) and `example_input.csv` for complete documentation and examples.

### Samplesheet Formats

The pipeline supports both Illumina samplesheet formats with automatic detection:

#### BCL Convert (v2) Format
```csv
[Header]
FileFormatVersion,2

[BCLConvert_Settings]
SoftwareVersion,4.2.7

[BCLConvert_Data]
Sample_ID,Index,Index2,Lane
Sample1,TAAGGCGA,TAGATCGC,1
```

**Key characteristics:**
- Uses `[BCLConvert_Settings]` and `[BCLConvert_Data]` sections (required)
- Always includes Sample_ID in output file names
- Stricter validation - aborts on invalid settings
- Preferred for new workflows

#### bcl2fastq2 (v1) Format
```csv
[Header]
IEMFileVersion,4

[Reads]
151
151

[Data]
Sample_ID,Sample_Name,index,index2
Sample1,TestSample1,TAAGGCGA,TAGATCGC
```

**Key characteristics:**
- Uses `[Settings]` and `[Data]` sections
- Less strict about header names
- Typically warns (not aborts) on invalid settings
- Compatible with legacy workflows

#### Format Comparison

| Feature | bcl2fastq2 (v1) | BCL Convert (v2) |
|---------|-----------------|------------------|
| **Version** | v1 (legacy) | v1 & v2 supported (v2 preferred) |
| **Section Names** | `[Settings]`, `[Data]` | `[BCLConvert_Settings]`, `[BCLConvert_Data]` |
| **File Naming** | Variable | Always includes Sample_ID |
| **Error Handling** | Warns on invalid settings | Aborts on invalid settings |
| **Header Strictness** | Flexible | Strict |
| **Required Columns** | Lane, Sample_ID, Index1/Index2 | Lane, Sample_ID, Index1/Index2 |
| **Optional Columns** | Sample_Name, Sample_Project | Sample_Name, Sample_Project |

See `test_samplesheet_v1.csv` and `test_samplesheet_v2.csv` for complete examples.

## Parameters

### Required
- `--input`: Path to input CSV file listing runs to process (see [INPUT_FORMAT.md](INPUT_FORMAT.md))

### Optional
- `--outdir`: Output directory (default: `./results`)
- `--demux_tool`: Demultiplexer to use: `'auto'` (default, auto-detect), `'bclconvert'`, or `'bcl2fastq'`
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
├── run1/                    # First run from input CSV
│   ├── bclconvert/          # Demultiplexed FASTQ files + BCL Convert reports
│   ├── fastqc/              # FastQC quality control reports
│   ├── fastq_screen/        # Contamination screening (if enabled)
│   └── multiqc/             
│       └── run1_multiqc_report.html  ← QC report with custom title
├── run2/                    # Second run from input CSV
│   ├── bclconvert/
│   ├── fastqc/
│   └── multiqc/
│       └── run2_multiqc_report.html
└── pipeline_info/           # Execution reports and logs
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
