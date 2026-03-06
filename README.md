# Demultiplex & QC Pipeline

[![GitHub Actions CI Status](https://img.shields.io/badge/CI%20tests-passing-success?labelColor=000000&logo=github)](https://github.com/T-Chinsky/bcl-convert-pipeline)
[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.04.0-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch)

## Introduction

A Nextflow DSL2 pipeline for batch processing multiple Illumina sequencing runs with comprehensive quality control. This pipeline supports both **BCL Convert** (v2 samplesheets) and **bcl2fastq2** (v1 samplesheets) with automatic format detection, providing a streamlined workflow for demultiplexing and quality assessment.

The pipeline handles:
1. **Automatic Samplesheet Detection** - Intelligently detects BCL Convert (v2) vs bcl2fastq2 (v1) format
2. **Demultiplexing** - BCL Convert or bcl2fastq2 based on detected format
3. **Quality Control** - FastQC analysis on all demultiplexed samples
4. **Contamination Screening** - Optional FastQ Screen for multi-organism projects
5. **Comprehensive Reporting** - MultiQC aggregation of all QC metrics

> **Note**
> This pipeline follows nf-core best practices including strict syntax validation, modular design, and containerized execution for reproducibility.

## Features

- ✅ **Dual Demultiplexer Support**: Automatically detects and uses BCL Convert or bcl2fastq2 based on samplesheet format
- ✅ **Automatic Format Detection**: Seamlessly handles v1 (bcl2fastq2) and v2 (BCL Convert) samplesheet formats
- ✅ **Batch Processing**: Process multiple BCL runs simultaneously from a single CSV input
- ✅ **Direct Samplesheet Support**: Use your existing samplesheets without reformatting
- ✅ **Custom MultiQC Titles**: Set descriptive report titles for each run
- ✅ **FastQC**: Quality control assessment of sequencing reads
- ✅ **fastq_screen**: Optional contamination screening against 12 reference genomes
- ✅ **MultiQC**: Separate QC reports for each run with custom titles
- ✅ **Container-based**: Reproducible execution with Docker/Singularity via Wave containers
- ✅ **nf-core Compatible**: Follows nf-core best practices and Nextflow strict syntax
- ✅ **Scalable**: Automatic parallelization and resource management
- ✅ **Resume**: Continue from failed tasks with `-resume`

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

### Prerequisites

- Nextflow >= 25.04.0
- Docker or Singularity

### Basic Usage

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_.

First, prepare a CSV file listing your sequencing runs:

**input.csv**:

```csv
run_dir,samplesheet,output_dir
/path/to/run1,/path/to/run1/SampleSheet.csv,results/run1
/path/to/run2,/path/to/run2/SampleSheet.csv,results/run2
```

Now, you can run the pipeline using:

```bash
nextflow run main.nf \
    --input input.csv \
    -profile docker
```

For more details and further functionality, please refer to the sections below.

## Pipeline Workflow

### Automatic Samplesheet Format Detection

The pipeline intelligently detects the samplesheet format and chooses the appropriate demultiplexer using a priority-based approach:

**Detection Priority (Highest to Lowest):**

1. **Priority 1: BCLConvert-Specific Headers** (Primary Marker)
   - **v2 indicator**: Presence of `[BCLConvert_Settings]` OR `[BCLConvert_Data]` section
   - These sections are ONLY present in BCL Convert samplesheets
   - Most reliable indicator of v2 format

2. **Priority 2: Standard Section Names** (bcl2fastq markers)
   - **v1 indicator**: Presence of `[Data]` section (not `[BCLConvert_Data]`)
   - **v1 indicator**: Presence of `[Settings]` section (not `[BCLConvert_Settings]`)
   - bcl2fastq uses `[Data]` and `[Settings]`, BCL Convert uses `[BCLConvert_Data]` and `[BCLConvert_Settings]`

3. **Priority 3: Version Markers**
   - **v1 indicator**: `IEMFileVersion,` (any version number) in `[Header]` section
   - **v2 indicator**: `FileFormatVersion,2` in `[Header]` section

4. **Default Behavior**: If no markers are found, defaults to **v2** (bclconvert) as the newer standard

**Important Note:** The `[Reads]` section can appear in BOTH bcl2fastq and BCL Convert samplesheets, so it is NOT used for format detection.

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

**Detection Logging:**
The pipeline logs detection results for transparency:
```
[run1] Detected samplesheet version: v1 -> Using bcl2fastq
[run2] Detected samplesheet version: v2 -> Using bclconvert
```

### With BCL Convert Options

Control BCL Convert output organization:

```bash
# Organize output by sample/project with combined lanes
nextflow run main.nf \
  --input runs.csv \
  --outdir results \
  --bcl_sampleproject_subdirectories \
  --no_lane_splitting
```

### With Contamination Screening

First, set up fastq_screen databases following the [FASTQ_SCREEN_SETUP.md](FASTQ_SCREEN_SETUP.md) guide.

```bash
nextflow run main.nf \
  --input runs.csv \
  --outdir results \
  --fastq_screen_config /path/to/fastq_screen.conf
```

### On HPC Cluster with SLURM

Use a custom configuration file to specify cluster-specific settings:

```bash
nextflow run main.nf \
  -c custom.config \
  --input runs.csv \
  --outdir results
```

**Template `custom.config`** (included in repository):
```groovy
executor {
    name = "slurm"
    queueSize = 2000
}

process {
    // Modify these SLURM options to match your cluster
    clusterOptions = '--partition <partition> --account <account> --qos <qos>'
    maxRetries = 10
}

singularity {
    // Uncomment and set your cluster's cache directory
    // cacheDir = '/path/to/singularity/cache'
}
```

Copy and modify `custom.config` to match your cluster's configuration (partition names, account, paths, etc.).

## FastQ Screen Setup (Optional)

For contamination screening, you'll need to download and build reference genome databases using Bowtie2.

### Prerequisites

- **Bowtie2** installed and in your PATH
- **wget** or **curl** for downloading
- At least **50 GB** of free disk space (for all genomes)
- Approximately **4-6 hours** for downloading and indexing all databases

### Quick Start: Minimal Setup (~30 minutes)

For testing or essential contamination screening, download these 4 databases:

```bash
# Create database directory
mkdir -p /path/to/fastq_screen_databases
cd /path/to/fastq_screen_databases

# 1. PhiX Control (sequencing control, ~5 KB)
mkdir -p phix && cd phix
wget -O phix.fa "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=NC_001422.1&rettype=fasta"
bowtie2-build phix.fa phix
cd ..

# 2. Adapters (Illumina adapters, ~1 KB)
mkdir -p adapters && cd adapters
cat > adapters.fa << 'EOF'
>TruSeq_Universal_Adapter
AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT
>TruSeq_Adapter_Index
GATCGGAAGAGCACACGTCTGAACTCCAGTCAC
>Nextera_Transposase_Sequence
CTGTCTCTTATACACATCT
>Illumina_Multiplexing_Adapter
GATCGGAAGAGCACACGTCT
EOF
bowtie2-build adapters.fa adapters
cd ..

# 3. E. coli (bacterial contamination, ~4.6 MB)
mkdir -p ecoli && cd ecoli
wget -O ecoli.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
gunzip ecoli.fa.gz
bowtie2-build ecoli.fa ecoli
cd ..

# 4. UniVec (vector contamination, ~10 MB)
mkdir -p univec && cd univec
wget -O univec.fa https://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec
bowtie2-build univec.fa univec
cd ..

# Create configuration file
cat > fastq_screen.conf << 'EOF'
DATABASE    phix       /path/to/fastq_screen_databases/phix/phix
DATABASE    adapters   /path/to/fastq_screen_databases/adapters/adapters
DATABASE    ecoli      /path/to/fastq_screen_databases/ecoli/ecoli
DATABASE    univec     /path/to/fastq_screen_databases/univec/univec
EOF
```

**Replace `/path/to/fastq_screen_databases` with your actual path in the config file.**

### Full Setup: All 12 Reference Genomes

For comprehensive contamination screening, download all reference databases:

| Database | Genome Size | Index Size | Build Time (8 cores) | Key Contaminants |
|----------|-------------|------------|----------------------|------------------|
| **hg38** | 3.1 GB | ~8 GB | ~2 hours | Human contamination |
| **mm10** | 2.7 GB | ~7 GB | ~1.5 hours | Mouse contamination |
| **rat** | 2.8 GB | ~7 GB | ~1.5 hours | Rat contamination |
| **drosophila** | 143 MB | ~600 MB | ~10 minutes | Fly contamination |
| **yeast** | 12 MB | ~50 MB | ~1 minute | Yeast contamination |
| **ecoli** | 4.6 MB | ~20 MB | ~1 minute | Bacterial contamination |
| **mycoplasma** | 580 KB | ~3 MB | <1 minute | Mycoplasma contamination |
| **viral** | 500 MB | ~2 GB | ~5 minutes | Viral contamination |
| **univec** | 10 MB | ~30 MB | ~1 minute | Vector contamination |
| **phix** | 5 KB | ~20 KB | <1 minute | Sequencing control |
| **adapters** | 1 KB | ~5 KB | <1 minute | Adapter dimers |
| **bacterial** | ~50 GB | ~150 GB | Several hours | Broad bacterial screen (optional) |
| **Total** | **~9 GB** | **~25 GB** | **~5-6 hours** | (excluding full bacterial) |

#### Example: Human Genome (hg38)

```bash
mkdir -p hg38 && cd hg38
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz
bowtie2-build --threads 8 hg38.fa hg38
cd ..
```

#### Example: Viral Database

```bash
mkdir -p viral && cd viral
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.1.1.genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.2.1.genomic.fna.gz
gunzip -c viral.*.genomic.fna.gz > viral_all.fa
bowtie2-build --threads 8 viral_all.fa viral
rm viral.*.genomic.fna.gz
cd ..
```

### Create Full Configuration File

After building all desired databases:

```bash
cat > fastq_screen.conf << 'EOF'
# FastQ Screen Configuration File
DATABASE    hg38           /path/to/fastq_screen_databases/hg38/hg38
DATABASE    mm10           /path/to/fastq_screen_databases/mm10/mm10
DATABASE    rat            /path/to/fastq_screen_databases/rat/rn6
DATABASE    univec         /path/to/fastq_screen_databases/univec/univec
DATABASE    phix           /path/to/fastq_screen_databases/phix/phix
DATABASE    adapters       /path/to/fastq_screen_databases/adapters/adapters
DATABASE    ecoli          /path/to/fastq_screen_databases/ecoli/ecoli
DATABASE    yeast          /path/to/fastq_screen_databases/yeast/yeast
DATABASE    drosophila     /path/to/fastq_screen_databases/drosophila/drosophila
DATABASE    mycoplasma     /path/to/fastq_screen_databases/mycoplasma/mycoplasma
DATABASE    viral          /path/to/fastq_screen_databases/viral/viral
EOF
```

**Important:** Update all `/path/to/fastq_screen_databases` references with your actual installation path.

### Testing Your Setup

Verify fastq_screen can find all databases:

```bash
fastq_screen --version
fastq_screen --conf /path/to/fastq_screen_databases/fastq_screen.conf --test
```

### Use With Pipeline

Pass the config file to the pipeline:

```bash
nextflow run main.nf \
    --input runs.csv \
    --fastq_screen_config /path/to/fastq_screen_databases/fastq_screen.conf
```

Or set it in `nextflow.config`:

```groovy
params {
    fastq_screen_config = '/path/to/fastq_screen_databases/fastq_screen.conf'
}
```

## Input Files

### Input CSV Format

The `--input` parameter accepts a CSV file with the following columns:

| Column | Required | Description |
|--------|----------|-------------|
| `run_id` | Yes | Unique identifier for the run (used in output directory naming) |
| `samplesheet` | Yes | Full path to the BCL Convert samplesheet |
| `run_dir` | Yes | Full path to the BCL run directory containing BCL files |
| `multiqc_title` | No | Custom title for the MultiQC report (defaults to `run_id` if not provided) |

**Example CSV:**

```csv
run_id,samplesheet,run_dir,multiqc_title
run1,/data/runs/2024_01_15/SampleSheet.csv,/data/runs/2024_01_15,Cancer Panel - Batch 1
run2,/data/runs/2024_01_16/SampleSheet.csv,/data/runs/2024_01_16,Cancer Panel - Batch 2
run3,/data/runs/2024_01_20/SampleSheet.csv,/data/runs/2024_01_20,RNA-Seq Control Samples
```

**Notes:**

- **Samplesheet Format**: The pipeline passes samplesheets directly to the demultiplexer, so any format accepted by BCL Convert or bcl2fastq is supported (no reformatting required)
- **Run ID**: Must be unique within the CSV; used for output directory organization
- **Paths**: All paths should be absolute or relative to where the pipeline is launched
- **MultiQC Title**: Use descriptive titles to make reports easier to identify (e.g., include experiment name, date, or batch number)

**Output Structure:**

With the example CSV above, the pipeline will create:

```
results/
├── run1/
│   ├── bclconvert/
│   │   ├── output/*.fastq.gz
│   │   ├── Reports/
│   │   └── Logs/
│   ├── fastqc/
│   └── multiqc/
│       └── run1_multiqc_report.html  (title: "Cancer Panel - Batch 1")
├── run2/
│   └── ... (title: "Cancer Panel - Batch 2")
└── run3/
    └── ... (title: "RNA-Seq Control Samples")
```

See `example_input.csv` in the repository for a complete working example.

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

## Pipeline Output

The pipeline generates the following output structure:

```
results/
├── <run_id>/
│   ├── demux/              # Demultiplexed FASTQ files
│   │   └── <sample>.fastq.gz
│   ├── fastqc/             # FastQC reports
│   │   └── <sample>_fastqc.html
│   ├── fastq_screen/       # Contamination screening (optional)
│   │   └── <sample>_screen.txt
│   └── multiqc/            # Aggregated QC report
│       └── <multiqc_title>_multiqc.html
└── pipeline_info/          # Pipeline execution metadata
```

### Key Output Files

- **Demultiplexed FASTQs**: `<run_id>/demux/` - Quality-checked sequencing reads
- **MultiQC Report**: `<run_id>/multiqc/<title>_multiqc.html` - Comprehensive QC dashboard
- **FastQC Reports**: `<run_id>/fastqc/` - Individual sample quality metrics
- **FastQ Screen** (optional): `<run_id>/fastq_screen/` - Contamination screening results

For more details about interpreting the output files and quality metrics, refer to the tool documentation:
- [MultiQC Documentation](https://multiqc.info/)
- [FastQC Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/)
- [FastQ Screen Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)

## Parameters

### Required
- `--input`: Path to input CSV file listing runs to process

### Optional

#### General Parameters
- `--outdir`: Output directory (default: `./results`)
- `--demux_tool`: Demultiplexer to use: `'auto'` (default, auto-detect), `'bclconvert'`, or `'bcl2fastq'`
- `--fastq_screen_config`: Path to fastq_screen config (enables contamination screening)

#### BCL Convert Specific Parameters
- `--bcl_sampleproject_subdirectories`: Create subdirectories organized by sample/project in BCL Convert output (default: `false`)
  - When enabled: organizes output as `output/Sample_Project/Sample_ID/`
  - When disabled: all files in flat `output/` directory
- `--no_lane_splitting`: Combine lanes in BCL Convert output files (default: `false`)
  - When enabled: generates `Sample_S1_R1_001.fastq.gz` (lanes combined)
  - When disabled: generates `Sample_S1_L001_R1_001.fastq.gz`, `Sample_S1_L002_R1_001.fastq.gz`, etc.
  - Note: Only applies to BCL Convert, not bcl2fastq

### Resource Limits
- `--max_cpus`: Maximum CPUs (default: `32`)
- `--max_memory`: Maximum memory (default: `256.GB`)
- `--max_time`: Maximum time (default: `24.h`)

## Profiles

- `standard`: Local execution (default)
- `docker`: Docker containers
- `singularity`: Singularity containers

### Custom Configurations

For HPC clusters or custom execution environments, use the `-c` option to specify a custom configuration file:

```bash
nextflow run main.nf -c custom.config --input runs.csv
```

The repository includes `custom.config` as a template for SLURM HPC clusters. Copy and modify this file to match your cluster's requirements (partition names, account, paths, etc.).

## Container Images

All tools use pre-built containers for reproducibility:

### Demultiplexing Tools
- **BCL Convert**: `ubgbc/bcl-convert:4.4.6`
- **bcl2fastq2**: `community.wave.seqera.io/library/bcl2fastq2:2.20.0--1d9942001bacdbaa`

### Quality Control Tools
- **FastQC**: `community.wave.seqera.io/library/fastqc:0.12.1--aa717e1a9d994d74`
- **fastq_screen**: `community.wave.seqera.io/library/fastq-screen:0.16.0--3b0a59ab6ab18664`
- **MultiQC**: `community.wave.seqera.io/library/multiqc:1.33--9daaf37cc59ba7dc`

All Wave containers are automatically pulled and cached on first use.

## Development & Best Practices

### nf-core Standardization

This pipeline follows nf-core best practices and is fully compatible with Nextflow strict syntax mode (v25.10+).

**Key Compliance Features:**

- ✅ **Strict Syntax Mode**: All code validated with `NXF_SYNTAX_PARSER=v2`
- ✅ **Module Structure**: Proper input/output handling with tuple structures
- ✅ **Version Tracking**: All modules emit versions.yml for reproducibility
- ✅ **Stub Sections**: All modules include stub implementations for testing
- ✅ **Channel Handling**: Explicit channel declarations with lowercase `channel` namespace
- ✅ **Configuration**: Clean separation of config files with Utils library for shared functions
- ✅ **Container Integration**: Wave containers for all tools with automatic caching
- ✅ **Error Handling**: Proper validation and informative error messages
- ✅ **Resource Management**: Flexible resource allocation with configurable max limits

**Testing with Strict Syntax:**

```bash
# Run with strict syntax validation
export NXF_SYNTAX_PARSER=v2
nextflow run main.nf --input runs.csv

# Test workflow structure without executing
nextflow run main.nf --input runs.csv -stub
```

**Validation Results:**

All 11 pipeline files pass strict syntax validation with zero errors:
- `main.nf`
- `nextflow.config`
- `modules/local/*.nf` (4 modules)
- `subworkflows/local/*.nf`
- `workflows/*.nf`
- `conf/*.config` (3 config files)

### For Developers

**Coding Standards:**
- Use explicit `def` declarations for all variables
- No implicit `it` parameters in closures (use explicit parameter names)
- Place helper functions in `lib/` directory or inline in `main.nf`
- Utils class in `lib/Utils.groovy` for shared utility functions
- Always include `versions.yml` output in modules
- Provide stub sections for dry-run testing

**Adding New Modules:**

1. Create module in `modules/local/`
2. Follow tuple input structure: `tuple val(meta), path(files)`
3. Include multiple output channels (main output, versions, logs)
4. Add Wave container directive
5. Implement stub section
6. Update module config in `conf/modules.config`

**Testing Checklist:**

- [ ] Run with `NXF_SYNTAX_PARSER=v2`
- [ ] Test with `-stub` flag
- [ ] Verify with small test dataset
- [ ] Check resource limits with max_cpus/memory/time
- [ ] Test conditional execution paths
- [ ] Validate MultiQC aggregation

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, please open an issue on the [GitHub repository](https://github.com/T-Chinsky/bcl-convert-pipeline/issues).

## Credits

This pipeline was developed by the community and follows nf-core best practices for Nextflow workflow development.

The pipeline uses the following key tools:
- [Nextflow](https://www.nextflow.io/) - Workflow orchestration
- [BCL Convert](https://support.illumina.com/sequencing/sequencing_software/bcl-convert.html) - Illumina demultiplexing (v2)
- [bcl2fastq2](https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html) - Illumina demultiplexing (v1)
- [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) - Quality control
- [FastQ Screen](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/) - Contamination detection
- [MultiQC](https://multiqc.info/) - Report aggregation

Many thanks to all contributors who have helped develop and improve this pipeline.

## Citations

If you use this pipeline for your analysis, please cite:

> **Nextflow: Enabling reproducible computational workflows**
>
> Paolo Di Tommaso, Maria Chatzou, Evan W Floden, Pablo Prieto Barja, Emilio Palumbo, and Cedric Notredame.
>
> _Nature Biotechnology_ 2017. doi: [10.1038/nbt.3820](https://doi.org/10.1038/nbt.3820)

An extensive list of references for the tools used by the pipeline can be found below:

- **BCL Convert**: Illumina, Inc. BCL Convert: Conversion software for Illumina sequencers.
- **bcl2fastq2**: Illumina, Inc. bcl2fastq2 Conversion Software v2.20.
- **FastQC**: Andrews S. (2010). FastQC: A quality control tool for high throughput sequence data. Available online at: http://www.bioinformatics.babraham.ac.uk/projects/fastqc
- **FastQ Screen**: Wingett SW and Andrews S. (2018). FastQ Screen: A tool for multi-genome mapping and quality control. F1000Research, 7:1338. doi: [10.12688/f1000research.15931.2](https://doi.org/10.12688/f1000research.15931.2)
- **MultiQC**: Ewels P, Magnusson M, Lundin S, Käller M. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report. Bioinformatics, 32(19):3047-8. doi: [10.1093/bioinformatics/btw354](https://doi.org/10.1093/bioinformatics/btw354)

## License

MIT License - see the [LICENSE](LICENSE) file for details.
- **MultiQC**: Ewels, P., et al. (2016). MultiQC: summarize analysis results for multiple tools and samples in a single report.
