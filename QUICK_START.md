# Quick Start Guide - BCL QC Pipeline

## 🚀 Fastest Path to Running the Pipeline

### 1. Prepare Your Input CSV

Create a file called `input.csv` with your run information:

```csv
run_id,samplesheet,run_dir,multiqc_title
RUN_001,/path/to/samplesheet.csv,/path/to/illumina_run,My First QC Report
```

**Required columns:**
- `run_id`: Unique identifier for this run
- `samplesheet`: Path to BCLConvert or bcl2fastq samplesheet
- `run_dir`: Path to Illumina run directory (contains BCL files)
- `multiqc_title`: Custom title for the MultiQC report (optional)

### 2. Run the Pipeline

```bash
nextflow run main.nf \
  --input input.csv \
  --outdir results \
  -profile docker
```

**That's it!** The pipeline will:
1. Detect samplesheet format (BCLConvert v2/v3 or bcl2fastq)
2. Run demultiplexing with appropriate tool
3. Perform FastQC on outputs
4. Generate MultiQC report

### 3. Check Results

```bash
results/
├── fastq/                    # Demultiplexed FASTQ files
│   └── RUN_001/
│       ├── Sample1_R1.fastq.gz
│       └── Sample1_R2.fastq.gz
├── fastqc/                   # FastQC reports
├── multiqc/                  # MultiQC summary
│   └── multiqc_report.html   # ← Open this in your browser!
└── pipeline_info/            # Execution reports
```

## 📋 Common Scenarios

### Multiple Runs

Add more rows to your CSV:

```csv
run_id,samplesheet,run_dir,multiqc_title
RUN_001,/data/run1/samplesheet.csv,/data/run1,Run 1 QC
RUN_002,/data/run2/samplesheet.csv,/data/run2,Run 2 QC
RUN_003,/data/run3/samplesheet.csv,/data/run3,Run 3 QC
```

The pipeline processes all runs in parallel!

### Use bcl2fastq Instead of BCLConvert

```bash
nextflow run main.nf \
  --input input.csv \
  --demultiplexer bcl2fastq \
  --outdir results \
  -profile docker
```

### Skip FastQ Screen (Faster)

```bash
nextflow run main.nf \
  --input input.csv \
  --skip_fastq_screen \
  --outdir results \
  -profile docker
```

### Run with Custom Resources

```bash
nextflow run main.nf \
  --input input.csv \
  --max_cpus 32 \
  --max_memory 256.GB \
  --max_time 72.h \
  --outdir results \
  -profile docker
```

### Use Singularity Instead of Docker

```bash
nextflow run main.nf \
  --input input.csv \
  --outdir results \
  -profile singularity
```

## 🧪 Testing Without Real Data

Use our test profile with mock data:

```bash
nextflow run main.nf -profile test,docker
```

This runs a quick validation with minimal test data.

## 🔍 Understanding Samplesheet Formats

### BCLConvert v2 Format
```csv
Lane,Sample_ID,index,index2
1,Sample1,ACGTACGT,TGCATGCA
2,Sample2,GGTTAACC,CCTTAATT
```

### BCLConvert v3 Format (with [Header])
```csv
[Header]
FileFormatVersion,2
[BCLConvert_Settings]
SoftwareVersion,3.9.3
[BCLConvert_Data]
Lane,Sample_ID,Index,Index2
1,Sample1,ACGTACGT,TGCATGCA
```

### bcl2fastq Format
```csv
FCID,Lane,Sample_ID,SampleRef,Index,Description,Control,Recipe,Operator,SampleProject
FC1,1,Sample1,hg38,ACGTACGT,,,,,Project1
```

The pipeline **automatically detects** which format you're using!

## 🆘 Troubleshooting

### "No such file or directory"
✅ Check paths in your CSV are absolute, not relative
✅ Verify the run directory exists and is readable

### "Process requirement exceeds available memory"
✅ Set lower resource limits:
```bash
--max_memory 64.GB --max_cpus 8
```

### "Docker permission denied"
✅ Add yourself to docker group:
```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

### FastQ Screen fails
✅ Either skip it with `--skip_fastq_screen` or provide a config:
```bash
--fastq_screen_config /path/to/fastq_screen.conf
```

## 📊 What Gets Generated?

### Key Outputs

| File | Description |
|------|-------------|
| `multiqc/multiqc_report.html` | Interactive QC summary (START HERE!) |
| `fastq/{run_id}/*.fastq.gz` | Demultiplexed FASTQ files |
| `fastqc/{run_id}/*.html` | Per-sample FastQC reports |
| `pipeline_info/execution_report.html` | Pipeline execution statistics |

### MultiQC Report Sections
- **Demultiplexing Stats**: Yield, Q30, index mismatches
- **FastQC**: Quality scores, sequence content, duplication
- **FastQ Screen** (if enabled): Contamination screening
- **Workflow Summary**: Pipeline parameters and versions

## 🔧 Advanced Options

### Enable FastQ Screen with Custom Config
```bash
nextflow run main.nf \
  --input input.csv \
  --fastq_screen_config /path/to/fastq_screen.conf \
  --outdir results \
  -profile docker
```

### Resume Failed Run
```bash
nextflow run main.nf \
  --input input.csv \
  --outdir results \
  -profile docker \
  -resume
```

### Run on HPC with Slurm
```bash
nextflow run main.nf \
  --input input.csv \
  --outdir results \
  -profile singularity \
  -process.executor slurm \
  -process.queue normal
```

### Generate Timeline Report
```bash
nextflow run main.nf \
  --input input.csv \
  --outdir results \
  -profile docker \
  -with-timeline timeline.html \
  -with-report report.html \
  -with-dag dag.html
```

## 📚 Need More Help?

- **Full Documentation**: See `README.md`
- **Testing Guide**: See `tests/README.md`
- **Output Details**: See `docs/output.md`
- **Complete Conversion Notes**: See `PIPELINE_CONVERSION_COMPLETE.md`

## ⚡ Pro Tips

1. **Always use absolute paths** in your input CSV
2. **Start with test profile** to verify setup: `-profile test,docker`
3. **Use -resume** if a run fails partway through
4. **Check MultiQC report first** - it summarizes everything
5. **Monitor with `-with-tower`** for cloud-based monitoring

## 🎯 Example End-to-End Workflow

```bash
# 1. Create input CSV
cat > my_runs.csv << EOF
run_id,samplesheet,run_dir,multiqc_title
Run_March2025,/data/run1/SampleSheet.csv,/data/run1,March 2025 QC
EOF

# 2. Run pipeline
nextflow run main.nf \
  --input my_runs.csv \
  --outdir qc_results \
  --max_cpus 16 \
  --max_memory 64.GB \
  -profile docker \
  -with-report execution_report.html

# 3. View results
firefox qc_results/multiqc/multiqc_report.html

# 4. Check execution stats
firefox execution_report.html
```

---

**Ready to start? Copy the commands above and adjust the paths!** 🚀
