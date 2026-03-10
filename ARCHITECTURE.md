# Pipeline Architecture - BCL QC Pipeline

This document describes the architectural design and data flow of the BCL QC pipeline.

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        User Input                            │
│                      (input.csv)                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ run_id,samplesheet,run_dir,multiqc_title           │   │
│  │ RUN1,/data/sheet1.csv,/data/run1,Report 1          │   │
│  │ RUN2,/data/sheet2.csv,/data/run2,Report 2          │   │
│  └─────────────────────────────────────────────────────┘   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                     Main Workflow                            │
│                    (workflows/bclconvert.nf)                │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Parse and validate CSV                            │  │
│  │ 2. Create channels for each run                      │  │
│  │ 3. Invoke BCL_QC_SINGLE_RUN subworkflow             │  │
│  │ 4. Aggregate MultiQC reports                         │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                BCL_QC_SINGLE_RUN Subworkflow                │
│            (subworkflows/local/bcl_qc_single_run.nf)       │
│                                                              │
│  For each run:                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 1. Detect samplesheet format                         │  │
│  │ 2. Choose demultiplexer (BCLConvert or bcl2fastq)  │  │
│  │ 3. Run FastQC on outputs                             │  │
│  │ 4. Run FastQ Screen (optional)                       │  │
│  │ 5. Generate MultiQC report                           │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   Outputs     │
                    │  (outdir/)    │
                    └───────────────┘
```

---

## 📊 Detailed Data Flow

### Phase 1: Input Processing

```
input.csv
    │
    ▼
┌─────────────────────────────┐
│ CSV Parsing & Validation    │
│ (main.nf)                    │
│                              │
│ • Check required columns     │
│ • Validate paths exist       │
│ • Check for empty values     │
│ • Create error report        │
└──────────────┬───────────────┘
               │
               ▼
    Channel.fromPath(csv)
        .splitCsv(header: true)
        .map { row -> 
            [
                id: row.run_id,
                samplesheet: file(row.samplesheet),
                run_dir: file(row.run_dir),
                multiqc_title: row.multiqc_title
            ]
        }
               │
               ▼
        run_ch (channel)
```

### Phase 2: Samplesheet Format Detection

```
run_ch
    │
    ▼
┌─────────────────────────────────────┐
│ SAMPLESHEET_DETECTION               │
│ (modules/local/samplesheet_detection.nf) │
│                                      │
│ Input:                               │
│   tuple val(meta), path(samplesheet)│
│                                      │
│ Process:                             │
│   1. Read first 10 lines             │
│   2. Check for [Header] section      │
│   3. Identify column names           │
│   4. Determine version (v1/v2)       │
│                                      │
│ Output:                              │
│   tuple val(meta),                   │
│         path(samplesheet),           │
│         val(version)                 │
└──────────────┬──────────────────────┘
               │
               ▼
    version == 'v1' ? bcl2fastq_ch : bclconvert_ch
```

### Phase 3: Demultiplexing (Branch A - bcl2fastq)

```
bcl2fastq_ch
    │
    ▼
┌─────────────────────────────────────┐
│ BCL2FASTQ                           │
│ (modules/local/bcl2fastq.nf)       │
│                                      │
│ Input:                               │
│   tuple val(meta),                   │
│         path(samplesheet),           │
│         path(run_dir)                │
│                                      │
│ Container:                           │
│   wave.seqera.io/.../bcl2fastq      │
│                                      │
│ Command:                             │
│   bcl2fastq                          │
│     --runfolder-dir $run_dir         │
│     --sample-sheet $samplesheet      │
│     --output-dir fastq/              │
│     --no-lane-splitting              │
│                                      │
│ Output:                              │
│   tuple val(meta),                   │
│         path("fastq/*.fastq.gz"),    │
│         path("Reports/"),            │
│         path("Stats/")               │
└──────────────┬──────────────────────┘
               │
               ▼
         fastq_files_ch
```

### Phase 3: Demultiplexing (Branch B - BCLConvert)

```
bclconvert_ch
    │
    ▼
┌─────────────────────────────────────┐
│ BCLCONVERT                          │
│ (modules/local/bclconvert.nf)      │
│                                      │
│ Input:                               │
│   tuple val(meta),                   │
│         path(samplesheet),           │
│         path(run_dir)                │
│                                      │
│ Container:                           │
│   wave.seqera.io/.../bclconvert     │
│                                      │
│ Command:                             │
│   bcl-convert                        │
│     --bcl-input-directory $run_dir   │
│     --sample-sheet $samplesheet      │
│     --output-directory fastq/        │
│     --bcl-num-parallel-tiles 4       │
│                                      │
│ Output:                              │
│   tuple val(meta),                   │
│         path("fastq/*.fastq.gz"),    │
│         path("Reports/")             │
└──────────────┬──────────────────────┘
               │
               ▼
         fastq_files_ch
```

### Phase 4: Quality Control

```
fastq_files_ch
    │
    ├────────────────────┐
    │                    │
    ▼                    ▼
┌─────────────┐   ┌──────────────────┐
│   FASTQC    │   │  FASTQ_SCREEN    │
│             │   │   (optional)     │
│ Container:  │   │                  │
│  fastqc     │   │ Container:       │
│             │   │  fastq-screen    │
│ Command:    │   │                  │
│  fastqc     │   │ Command:         │
│   *.fastq.gz│   │  fastq_screen    │
│   -o output │   │   --conf config  │
│             │   │   *.fastq.gz     │
│ Output:     │   │                  │
│  *_fastqc.* │   │ Output:          │
│             │   │  *_screen.*      │
└──────┬──────┘   └────────┬─────────┘
       │                   │
       └───────┬───────────┘
               │
               ▼
         qc_reports_ch
```

### Phase 5: Aggregation and Reporting

```
qc_reports_ch
    │
    ▼
┌─────────────────────────────────────┐
│ MULTIQC                             │
│ (modules/local/multiqc.nf)         │
│                                      │
│ Input:                               │
│   tuple val(meta),                   │
│         path("*_fastqc.html"),       │
│         path("*_screen.txt"),        │
│         path("Reports/")             │
│                                      │
│ Container:                           │
│   wave.seqera.io/.../multiqc        │
│                                      │
│ Command:                             │
│   multiqc .                          │
│     --filename multiqc_report.html   │
│     --title "$meta.multiqc_title"    │
│                                      │
│ Output:                              │
│   path("multiqc_report.html")        │
│   path("multiqc_data/")              │
└──────────────┬──────────────────────┘
               │
               ▼
      Final MultiQC Report
```

---

## 🗂️ File Organization

### Project Structure

```
demultiplex-qc-pipeline/
│
├── main.nf                     # Entry point
│   └── includes workflows/bclconvert.nf
│
├── workflows/
│   └── bclconvert.nf          # Main workflow
│       └── includes subworkflows/local/bcl_qc_single_run.nf
│
├── subworkflows/
│   └── local/
│       └── bcl_qc_single_run.nf  # Per-run QC logic
│           └── includes modules
│
├── modules/
│   ├── local/                 # Custom modules
│   │   ├── bclconvert.nf
│   │   ├── bcl2fastq.nf
│   │   ├── fastqc.nf
│   │   ├── fastq_screen.nf
│   │   ├── multiqc.nf
│   │   └── samplesheet_detection.nf
│   │
│   └── nf-core/              # nf-core modules
│       └── bcl2fastq/
│           └── main.nf
│
├── conf/
│   ├── base.config           # Process resource labels
│   ├── modules.config        # Module-specific configs
│   └── test.config           # Test profile
│
├── nextflow.config           # Main configuration
│
├── tests/                    # Test infrastructure
│   ├── data/                 # Test data
│   └── *.nf.test            # Test files
│
└── docs/                     # Documentation
    └── output.md
```

### Output Directory Structure

```
results/
│
├── fastq/                    # Demultiplexed FASTQ files
│   ├── RUN_001/
│   │   ├── Sample1_S1_R1_001.fastq.gz
│   │   ├── Sample1_S1_R2_001.fastq.gz
│   │   ├── Sample2_S2_R1_001.fastq.gz
│   │   └── Sample2_S2_R2_001.fastq.gz
│   │
│   └── RUN_002/
│       └── ...
│
├── fastqc/                   # FastQC reports
│   ├── RUN_001/
│   │   ├── Sample1_S1_R1_001_fastqc.html
│   │   ├── Sample1_S1_R1_001_fastqc.zip
│   │   └── ...
│   │
│   └── RUN_002/
│       └── ...
│
├── fastq_screen/            # FastQ Screen reports (optional)
│   ├── RUN_001/
│   │   └── *_screen.txt
│   │
│   └── RUN_002/
│       └── ...
│
├── multiqc/                 # MultiQC reports (per run)
│   ├── RUN_001/
│   │   ├── multiqc_report.html
│   │   └── multiqc_data/
│   │
│   └── RUN_002/
│       └── ...
│
└── pipeline_info/           # Pipeline execution info
    ├── execution_report.html
    ├── execution_timeline.html
    └── execution_trace.txt
```

---

## 🔄 Process Execution Flow

### Sequential Steps per Run

```
1. Input Validation
   ↓
2. Samplesheet Detection (SAMPLESHEET_DETECTION)
   ↓
3. Demultiplexing (BCL2FASTQ or BCLCONVERT)
   ↓
4. Parallel QC:
   ├─ FastQC (FASTQC)
   └─ FastQ Screen (FASTQ_SCREEN) [optional]
   ↓
5. Aggregation (MULTIQC)
```

### Parallel Execution Across Runs

```
Run 1: [────────────────>]
Run 2:   [────────────────>]
Run 3:     [────────────────>]
          Time →
```

Each run processes independently in parallel.

---

## 🎯 Module Architecture

### Module Template Structure

```groovy
// Module: modules/local/example.nf

process EXAMPLE {
    tag "$meta.id"              // Display tag in logs
    label 'process_medium'       // Resource label
    container "..."              // Container image

    input:
    tuple val(meta), path(files) // Inputs with metadata

    output:
    tuple val(meta), path("output/*"), emit: results  // Named outputs
    path "versions.yml",               emit: versions

    when:
    !params.skip_example         // Conditional execution

    script:
    def args = task.ext.args ?: '' // Module-specific args
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    example_tool \\
        $args \\
        --input $files \\
        --output output/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        example_tool: \$(example_tool --version | sed 's/v//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p output/
    touch output/${prefix}_result.txt
    echo "${task.process}:" > versions.yml
    echo "    example_tool: 1.0.0" >> versions.yml
    """
}
```

### Module Connection Pattern

```groovy
// In subworkflow or workflow

// Module A output → Module B input
MODULE_A(input_ch)
MODULE_B(MODULE_A.out.results)

// Fork outputs to multiple modules
MODULE_A(input_ch)
MODULE_B(MODULE_A.out.results)
MODULE_C(MODULE_A.out.results)  // Automatic channel forking

// Join channels
combined_ch = MODULE_B.out.results
    .join(MODULE_C.out.results, by: 0)
MODULE_D(combined_ch)
```

---

## ⚙️ Configuration Architecture

### Configuration Hierarchy

```
1. nextflow.config              (Base configuration)
   │
   ├─► conf/base.config         (Process resource labels)
   │   └─► process_low, process_medium, process_high
   │
   ├─► conf/modules.config      (Module-specific settings)
   │   └─► ext.args for each module
   │
   └─► conf/test.config         (Test profile)
       └─► Resource limits for testing
```

### Resource Label Resolution

```
Process declares:
  label 'process_high'
         │
         ▼
base.config defines:
  process_high {
    cpus = 12
    memory = { 72.GB * task.attempt }
    time = 16.h
  }
         │
         ▼
Runtime clamping:
  cpus = min(12, params.max_cpus)
  memory = min(72.GB, params.max_memory)
  time = min(16.h, params.max_time)
         │
         ▼
Final allocation to process
```

---

## 🧩 Channel Architecture

### Channel Types Used

```groovy
// Value channel (can be reused multiple times)
params_ch = channel.value(params.max_cpus)

// Queue channel (consumed by processes)
fastq_ch = channel.fromPath('*.fastq.gz')

// Tuple channel (metadata + files)
input_ch = channel.fromPath(csv)
    .splitCsv(header: true)
    .map { row -> [id: row.id, file: file(row.path)] }
```

### Channel Operators

```groovy
// Branch by condition
ch.branch { meta, files ->
    v1: meta.version == 'v1'  // bcl2fastq format
    v2: meta.version == 'v2'  // BCL Convert format
}

// Join channels by key
ch1.join(ch2, by: 0)  // Join on first element (meta)

// Mix multiple channels
channel.empty()
    .mix(bcl2fastq_ch)
    .mix(bclconvert_ch)

// Collect all items
ch.collect()  // Gather all items into a list
```

---

## 🔐 Error Handling Strategy

### Validation Layers

```
Layer 1: Input Validation (main.nf)
  ├─ CSV structure
  ├─ Required columns
  ├─ File existence
  └─ Empty value check
         │
         ▼
Layer 2: Process-Level Validation
  ├─ Container availability
  ├─ Tool execution
  └─ Output generation
         │
         ▼
Layer 3: Workflow Handlers
  ├─ onComplete
  ├─ onError
  └─ onTerminate
```

### Error Propagation

```
Process fails
    │
    ▼
Nextflow catches error
    │
    ▼
Check errorStrategy:
  ├─ 'terminate' → Stop pipeline
  ├─ 'ignore' → Continue
  └─ 'retry' → Retry with more resources
    │
    ▼
Trigger workflow.onError
    │
    ▼
Log to .nextflow.log
    │
    ▼
Exit with error code
```

---

## 📈 Performance Optimization Points

### 1. Process Parallelization

```
Runs are processed in parallel
    ↓
Within each run, QC steps are parallel
    ↓
FastQC processes multiple files in parallel
```

### 2. Resource Allocation

```
process_low:    2 CPUs,  8 GB RAM,  4h
process_medium: 6 CPUs, 36 GB RAM,  8h
process_high:  12 CPUs, 72 GB RAM, 16h
```

### 3. Container Caching

```
First run: Pull containers (~5-10 min)
    ↓
Subsequent runs: Use cached containers (~0 min)
```

### 4. Work Directory Management

```
-resume flag: Skip completed processes
    ↓
Only re-run failed/modified processes
    ↓
Significant time savings
```

---

## 🔬 Testing Architecture

### Test Layers

```
Layer 1: Unit Tests (stub mode)
  └─ Individual module validation

Layer 2: Integration Tests (stub mode)
  └─ Workflow component testing

Layer 3: End-to-End Tests (full mode)
  └─ Complete pipeline execution

Layer 4: System Tests
  └─ Real-world data processing
```

### Test Data Strategy

```
tests/data/
├─ Minimal mock data for stub tests
├─ Small real data for integration tests
└─ Production-like data for E2E tests
```

---

## 🎛️ Extension Points

### Adding New Demultiplexer

```
1. Create new module: modules/local/new_demux.nf
2. Add detection logic in SAMPLESHEET_DETECTION
3. Add branch in BCL_QC_SINGLE_RUN subworkflow
4. Update tests
5. Document in README
```

### Adding New QC Module

```
1. Create module: modules/local/new_qc.nf
2. Add to BCL_QC_SINGLE_RUN after demultiplexing
3. Pass outputs to MULTIQC
4. Update conf/modules.config
5. Add tests
```

### Adding New Output Format

```
1. Create conversion module
2. Add to end of subworkflow
3. Configure with params.output_format
4. Document outputs
```

---

This architecture supports scalability, maintainability, and extensibility for future enhancements.
