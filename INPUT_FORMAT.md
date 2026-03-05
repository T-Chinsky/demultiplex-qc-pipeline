# Input CSV Format

The pipeline accepts a CSV file via the `--input` parameter that lists multiple BCL conversion runs to process in parallel.

## CSV Structure

The input CSV must contain the following columns:

| Column | Required | Description |
|--------|----------|-------------|
| `run_id` | Yes | Unique identifier for this run (used in output directory naming) |
| `samplesheet` | Yes | Full path to the BCL Convert samplesheet for this run |
| `run_dir` | Yes | Full path to the BCL run directory containing BCL files |
| `multiqc_title` | No | Custom title for the MultiQC report (defaults to `run_id` if not provided) |

## Example CSV

```csv
run_id,samplesheet,run_dir,multiqc_title
run1,/data/runs/2024_01_15/SampleSheet.csv,/data/runs/2024_01_15,Cancer Panel - Batch 1
run2,/data/runs/2024_01_16/SampleSheet.csv,/data/runs/2024_01_16,Cancer Panel - Batch 2
run3,/data/runs/2024_01_20/SampleSheet.csv,/data/runs/2024_01_20,RNA-Seq Control Samples
```

## Notes

- **Samplesheet Format**: The pipeline passes samplesheets directly to `bcl-convert`, so any format accepted by BCL Convert is supported (no reformatting required)
- **Run ID**: Must be unique within the CSV; used for output directory organization
- **Paths**: All paths should be absolute or relative to where the pipeline is launched
- **MultiQC Title**: Use descriptive titles to make reports easier to identify (e.g., include experiment name, date, or batch number)

## Output Structure

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
│   ├── bclconvert/
│   ├── fastqc/
│   └── multiqc/
│       └── run2_multiqc_report.html  (title: "Cancer Panel - Batch 2")
└── run3/
    ├── bclconvert/
    ├── fastqc/
    └── multiqc/
        └── run3_multiqc_report.html  (title: "RNA-Seq Control Samples")
```

## Usage

```bash
nextflow run main.nf --input runs.csv --outdir results
```
