# Testing Documentation

This directory contains comprehensive tests for the BCL Convert Pipeline using the [nf-test](https://code.askimed.com/nf-test/) framework.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Test Structure](#test-structure)
- [Test Data](#test-data)
- [Running Tests](#running-tests)
- [Test Cases](#test-cases)
- [Writing New Tests](#writing-new-tests)
- [Continuous Integration](#continuous-integration)
- [Troubleshooting](#troubleshooting)

---

## Overview

The testing infrastructure provides:

- **23 test cases** across 5 test files covering all pipeline features
- **Snapshot-based validation** for automated output verification
- **Stub mode testing** for fast syntax validation
- **Multiple test profiles** for quick vs comprehensive testing
- **CI/CD ready** infrastructure with minimal resource requirements

### Testing Framework

We use [nf-test](https://www.nf-test.com/) which is:
- The modern testing framework for Nextflow pipelines
- Used by nf-core and major pipelines
- Supports snapshot testing for easy validation
- Enables stub mode for fast dry-run testing

---

## Quick Start

### Prerequisites

1. **Nextflow** (≥25.04.0)
   ```bash
   curl -s https://get.nextflow.io | bash
   ```

2. **nf-test** (≥0.9.0)
   ```bash
   wget -qO- https://code.askimed.com/install/nf-test | bash
   sudo mv nf-test /usr/local/bin/
   ```

3. **Container runtime** (Docker or Singularity)
   ```bash
   # Docker
   docker --version
   
   # Or Singularity
   singularity --version
   ```

### Run All Tests

```bash
# From the pipeline root directory
nf-test test

# With Docker
nf-test test --profile docker

# With Singularity
nf-test test --profile singularity
```

### Expected Output

```
🚀 nf-test 0.9.0
https://code.askimed.com/nf-test

Test Process:
✅ default.nf.test [4/4 PASSED]
✅ bclconvert_v2.nf.test [5/5 PASSED]
✅ bcl2fastq_v1.nf.test [5/5 PASSED]
✅ fastq_screen.nf.test [4/4 PASSED]
✅ mixed_formats.nf.test [5/5 PASSED]

SUCCESS: Executed 23 tests in 8m 32s
```

---

## Test Structure

### Directory Layout

```
tests/
├── nextflow.config              # Test-specific Nextflow configuration
├── .nftignore                   # Patterns to exclude from snapshots
│
├── Test Suites
├── default.nf.test              # Basic pipeline execution (4 tests)
├── bclconvert_v2.nf.test        # BCLConvert specific features (5 tests)
├── bcl2fastq_v1.nf.test         # bcl2fastq2 specific features (5 tests)
├── fastq_screen.nf.test         # Contamination screening (4 tests)
├── mixed_formats.nf.test        # Edge cases and mixed formats (5 tests)
│
├── data/                        # Test data directory
│   ├── fastq_screen.conf        # FASTQ Screen configuration
│   ├── v1/                      # bcl2fastq2 v1 format test data
│   │   ├── samplesheet.csv
│   │   └── runs/TEST_RUN_V1/
│   └── v2/                      # BCLConvert v2 format test data
│       ├── samplesheet.csv
│       ├── mixed_samplesheet.csv
│       └── runs/TEST_RUN_001/
│
└── .nf-test.snapshot/           # Auto-generated snapshot files
    ├── default.nf.test.snap
    ├── bclconvert_v2.nf.test.snap
    ├── bcl2fastq_v1.nf.test.snap
    ├── fastq_screen.nf.test.snap
    └── mixed_formats.nf.test.snap
```

### Configuration Files

#### `nextflow.config`
Test-specific configuration that:
- Disables work directory cleanup for inspection
- Sets deterministic settings
- Configures test profiles

#### `.nftignore`
Patterns to exclude from snapshot validation:
```
*.log                        # Variable log content
*.command.*                  # Process execution metadata
*.exitcode                   # Exit codes
pipeline_info/*.{html,json}  # Contains timestamps
work/                        # Temporary work directory
```

---

## Test Data

### Design Principles

Our test data is:
- **Minimal**: Small mock files for fast execution
- **Representative**: Matches real Illumina BCL structure
- **Comprehensive**: Covers both v1 and v2 formats
- **Stable**: Deterministic for reproducible testing

### BCLConvert v2 Format (`data/v2/`)

**Samplesheet Format**: Modern FileFormatVersion 2
```csv
[Header]
FileFormatVersion,2

[Settings]
BarcodeMismatchesIndex1,1
BarcodeMismatchesIndex2,1

[Data]
Sample_ID,Index,Index2,Lane
Sample1,AACCGGTT,TTGGCCAA,1
Sample2,GGTTAACC,CCAATTGG,1
Sample3,TTAACCGG,GGCCAATT,2
```

**Run Directory**: `runs/TEST_RUN_001/`
- Instrument: NovaSeq 6000
- Configuration: 2 lanes, 151bp paired-end
- Index structure: Dual 8bp indexes (I8+I8)
- Read structure: Y151;I8N2;I8N2;Y151

### bcl2fastq2 v1 Format (`data/v1/`)

**Samplesheet Format**: Traditional Illumina format
```csv
[Header]
Date,2024-01-01
Workflow,GenerateFASTQ
Application,NovaSeq FASTQ Only

[Reads]
151
151

[Settings]
BarcodeMismatches,1

[Data]
Lane,Sample_ID,Sample_Name,Index,Index2,Sample_Project
1,Sample1,Sample1,AACCGGTT,TTGGCCAA,Project_A
1,Sample2,Sample2,GGTTAACC,CCAATTGG,Project_A
2,Sample3,Sample3,TTAACCGG,GGCCAATT,Project_B
```

**Run Directory**: `runs/TEST_RUN_V1/`
- Same instrument structure as v2
- Compatible with bcl2fastq2 v2.20

### FASTQ Screen Configuration

**File**: `data/fastq_screen.conf`
```
DATABASE ecoli /path/to/ecoli
DATABASE human /path/to/human
THREADS 8
```

---

## Running Tests

### Basic Commands

```bash
# Run all tests
nf-test test

# Run specific test file
nf-test test tests/default.nf.test
nf-test test tests/bclconvert_v2.nf.test

# Run specific test case
nf-test test tests/default.nf.test --testcase "Default parameters - BCLConvert v2"

# Run with verbose output
nf-test test --verbose

# Run with debug information
nf-test test --debug
```

### Test Modes

#### Real Mode (Full Execution)
Tests run the complete pipeline with actual process execution:
```bash
nf-test test tests/default.nf.test
```
- **Duration**: ~5-10 minutes
- **Purpose**: Validate full pipeline functionality
- **Resource Usage**: Uses actual CPU/memory as configured

#### Stub Mode (Dry Run)
Tests validate workflow logic without executing processes:
```bash
nf-test test tests/default.nf.test --testcase "Default parameters - BCLConvert v2 - stub"
```
- **Duration**: ~30 seconds
- **Purpose**: Fast syntax and logic validation
- **Resource Usage**: Minimal

### Test Profiles

#### `test` - Quick Validation

```bash
nextflow run . -profile test,docker
```

**Configuration**:
- Max CPUs: 2
- Max Memory: 6 GB
- Max Time: 6 hours
- Skips: FASTQ Screen (for speed)
- Duration: ~5 minutes

**Use Cases**:
- Pull request validation
- Local development
- Quick sanity checks

#### `test_full` - Comprehensive Testing

```bash
nextflow run . -profile test_full,docker
```

**Configuration**:
- Max CPUs: 4
- Max Memory: 12 GB
- Max Time: 12 hours
- Enables: All QC modules
- Duration: ~15 minutes

**Use Cases**:
- Release validation
- Full feature testing
- Pre-deployment verification

### Snapshot Management

#### Update Snapshots

After intentional changes to pipeline outputs:
```bash
nf-test test --updateSnapshot
```

#### Clean Obsolete Snapshots

Remove snapshots that no longer have corresponding tests:
```bash
nf-test test --clean-snapshot
```

#### View Snapshot Differences

When tests fail, nf-test shows what changed:
```
❌ FAILED: Default parameters - BCLConvert v2

Expected: 4 files
Actual:   5 files

Difference:
+ output/fastq/new_sample.fastq.gz
```

---

## Test Cases

### 1. default.nf.test (4 tests)

**Purpose**: Basic pipeline execution tests

| Test Case | Description | Mode | Duration |
|-----------|-------------|------|----------|
| Default - BCLConvert v2 | Standard v2 execution | Real | ~2 min |
| Default - BCLConvert v2 - stub | Syntax validation | Stub | ~10 sec |
| Default - bcl2fastq2 v1 | Standard v1 execution | Real | ~2 min |
| Default - bcl2fastq2 v1 - stub | Syntax validation | Stub | ~10 sec |

**What's Tested**:
- Pipeline completes successfully
- Correct number of tasks executed
- Expected output files generated
- MultiQC report created

### 2. bclconvert_v2.nf.test (5 tests)

**Purpose**: BCLConvert specific features

| Test Case | Description | Duration |
|-----------|-------------|----------|
| With FastQC and MultiQC | Full QC pipeline | ~3 min |
| Skip FastQC | Only MultiQC enabled | ~2 min |
| Skip MultiQC | Only FastQC enabled | ~2 min |
| Custom override_cycles | Custom cycle masking | ~2 min |
| Stub mode | Syntax validation | ~10 sec |

**What's Tested**:
- QC module toggling (skip_fastqc, skip_multiqc)
- Custom BCLConvert parameters
- Process execution logic
- Conditional outputs

### 3. bcl2fastq_v1.nf.test (5 tests)

**Purpose**: bcl2fastq2 specific features

| Test Case | Description | Duration |
|-----------|-------------|----------|
| With FastQC and MultiQC | Full QC pipeline | ~3 min |
| Skip FastQC | Only MultiQC enabled | ~2 min |
| Custom barcode mismatches | Barcode settings | ~2 min |
| Custom trimming | Read trimming options | ~2 min |
| Stub mode | Syntax validation | ~10 sec |

**What's Tested**:
- bcl2fastq2 v1 samplesheet format
- Custom barcode mismatch settings
- Adapter trimming parameters
- Project-based organization

### 4. fastq_screen.nf.test (4 tests)

**Purpose**: Contamination screening validation

| Test Case | Description | Duration |
|-----------|-------------|----------|
| FASTQ Screen enabled | With config file | ~3 min |
| FASTQ Screen disabled | Skip screening | ~2 min |
| Custom aligner | Custom aligner option | ~3 min |
| Stub mode | Syntax validation | ~10 sec |

**What's Tested**:
- FASTQ Screen execution
- Configuration file handling
- Optional module behavior
- Custom aligner parameters

### 5. mixed_formats.nf.test (5 tests)

**Purpose**: Edge cases and format handling

| Test Case | Description | Duration |
|-----------|-------------|----------|
| Mixed v1/v2 formats | Auto-detection | ~2 min |
| Multiple lanes | Multi-lane processing | ~2 min |
| Project organization | v1 project structure | ~2 min |
| Minimal samplesheet | Minimal metadata | ~2 min |
| Stub mode | Syntax validation | ~10 sec |

**What's Tested**:
- Samplesheet format auto-detection
- Multi-lane sample organization
- Project-level directory structure
- Edge case handling

### Test Coverage Summary

| Feature | Test Count | Coverage |
|---------|-----------|----------|
| **Demultiplexers** | | |
| BCLConvert v2 | 9 tests | ✅ Complete |
| bcl2fastq2 v1 | 9 tests | ✅ Complete |
| **QC Modules** | | |
| FastQC | 4 tests | ✅ Complete |
| MultiQC | 6 tests | ✅ Complete |
| FASTQ Screen | 4 tests | ✅ Complete |
| **Formats** | | |
| v1 samplesheets | 6 tests | ✅ Complete |
| v2 samplesheets | 11 tests | ✅ Complete |
| Mixed formats | 1 test | ✅ Complete |
| **Modes** | | |
| Real execution | 18 tests | ✅ Complete |
| Stub execution | 5 tests | ✅ Complete |

---

## Writing New Tests

### Test File Template

```groovy
nextflow_pipeline {
    name "Description of test suite"
    script "../main.nf"
    tag "category"
    tag "subcategory"

    test("Descriptive test name") {
        
        when {
            params {
                outdir     = "$outputDir"
                input      = "${projectDir}/tests/data/v2/samplesheet.csv"
                run_dir    = "${projectDir}/tests/data/v2/runs/TEST_RUN_001"
                
                // Test-specific parameters
                param_name = value
                
                // Resource limits
                max_cpus   = 2
                max_memory = '6.GB'
                max_time   = '6.h'
            }
        }

        then {
            // Assertions
            assert workflow.success
            assert workflow.trace.succeeded().size() > 0
            
            // Get stable outputs
            def stable_name = getAllFilesFromDir(
                params.outdir, 
                relative: true, 
                includeDir: true, 
                ignore: ['pipeline_info/*.{html,json,txt,svg}', '*.log']
            )
            
            // Snapshot test
            assert snapshot(
                workflow.trace.succeeded().size(),
                stable_name,
                path("${params.outdir}/fastq/").list()
            ).match()
        }
    }

    test("Same test - stub mode") {
        
        options "-stub"
        
        when {
            params {
                outdir     = "$outputDir"
                input      = "${projectDir}/tests/data/v2/samplesheet.csv"
                run_dir    = "${projectDir}/tests/data/v2/runs/TEST_RUN_001"
                
                max_cpus   = 2
                max_memory = '6.GB'
                max_time   = '6.h'
            }
        }

        then {
            assert workflow.success
            assert workflow.trace.succeeded().size() > 0
        }
    }
}
```

### Best Practices

1. **Descriptive Names**
   - Use clear, specific test case names
   - Include the feature being tested
   - Add "- stub" suffix for stub mode tests

2. **Resource Limits**
   - Always include max_cpus, max_memory, max_time
   - Keep values low for CI/CD compatibility
   - Use 2 CPUs / 6 GB for standard tests

3. **Snapshot Testing**
   - Use `getAllFilesFromDir()` for stable file lists
   - Exclude dynamic content (logs, timestamps)
   - Include key assertions before snapshots

4. **Conditional Assertions**
   - Verify processes run when expected:
     ```groovy
     assert workflow.trace.tasks().any { task -> task.process == 'FASTQC' }
     ```
   - Verify processes skip when expected:
     ```groovy
     assert !workflow.trace.tasks().any { task -> task.process == 'MULTIQC' }
     ```

5. **Stub Mode Testing**
   - Always include stub mode test for each feature
   - Use `options "-stub"` in test definition
   - Keep assertions minimal (just success + task count)

### Adding Test Data

1. **Create minimal representative data**
   ```bash
   mkdir -p tests/data/my_feature
   touch tests/data/my_feature/sample.csv
   ```

2. **Keep files small**
   - Mock BCL directories (no actual sequence data)
   - Minimal samplesheets
   - Placeholder configuration files

3. **Update .nftignore if needed**
   ```bash
   echo "my_feature/*.log" >> tests/.nftignore
   ```

### Running Your New Test

```bash
# Test specific file
nf-test test tests/my_new_test.nf.test

# Generate initial snapshot
nf-test test tests/my_new_test.nf.test --updateSnapshot

# Validate
nf-test test tests/my_new_test.nf.test
```

---

## Continuous Integration

### GitHub Actions Integration

The test infrastructure is designed for CI/CD. Here's a recommended workflow:

```yaml
name: nf-test CI
on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  test-stub:
    name: Stub Mode Tests (Fast)
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Nextflow
        uses: nf-core/setup-nextflow@v2
        with:
          version: "25.04.0"
      
      - name: Install nf-test
        run: |
          wget -qO- https://code.askimed.com/install/nf-test | bash
          sudo mv nf-test /usr/local/bin/
      
      - name: Run stub tests
        run: nf-test test --tag stub --profile docker

  test-real:
    name: Full Pipeline Tests
    runs-on: ubuntu-latest
    needs: test-stub
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Nextflow
        uses: nf-core/setup-nextflow@v2
        with:
          version: "25.04.0"
      
      - name: Install nf-test
        run: |
          wget -qO- https://code.askimed.com/install/nf-test | bash
          sudo mv nf-test /usr/local/bin/
      
      - name: Pull Docker images
        run: |
          docker pull community.wave.seqera.io/library/bclconvert:4.2.7
          docker pull community.wave.seqera.io/library/bcl2fastq2:2.20.0
      
      - name: Run all tests
        run: nf-test test --profile docker
      
      - name: Upload test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: test-reports
          path: .nf-test/reports/
```

### Expected CI Performance

- **Stub tests**: ~30 seconds
- **Full tests**: ~8-10 minutes
- **Total CI time**: <11 minutes
- **Resource usage**: Standard GitHub Actions runner (2 CPU, 7 GB RAM)

### Pre-commit Hooks

Add to `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running nf-test stub mode checks..."
nf-test test --tag stub
if [ $? -ne 0 ]; then
    echo "Stub tests failed! Fix errors before committing."
    exit 1
fi
```

---

## Troubleshooting

### Common Issues

#### 1. Tests Fail with Snapshot Mismatch

**Symptom**:
```
❌ FAILED: Default parameters - BCLConvert v2
Snapshot mismatch
```

**Solution**:
```bash
# Review what changed
nf-test test tests/default.nf.test --verbose

# If changes are expected, update snapshot
nf-test test tests/default.nf.test --updateSnapshot
```

#### 2. Container Pull Failures

**Symptom**:
```
Error: Failed to pull Docker image
```

**Solution**:
```bash
# Pull images manually first
docker pull community.wave.seqera.io/library/bclconvert:4.2.7
docker pull community.wave.seqera.io/library/bcl2fastq2:2.20.0

# Or use Singularity
export NXF_SINGULARITY_CACHEDIR=/path/to/cache
nextflow run . -profile test,singularity
```

#### 3. Resource Limit Errors

**Symptom**:
```
Error: Process exceeded memory limit
```

**Solution**:
```bash
# Increase limits in test parameters
params {
    max_memory = '12.GB'  // Increase from 6.GB
    max_cpus   = 4        // Increase from 2
}
```

#### 4. Test Data Not Found

**Symptom**:
```
Error: Cannot find file: tests/data/v2/samplesheet.csv
```

**Solution**:
```bash
# Verify test data exists
ls -la tests/data/

# Regenerate if missing
git checkout tests/data/
```

#### 5. nf-test Not Found

**Symptom**:
```
bash: nf-test: command not found
```

**Solution**:
```bash
# Install nf-test
wget -qO- https://code.askimed.com/install/nf-test | bash
sudo mv nf-test /usr/local/bin/

# Verify installation
nf-test version
```

### Debug Tips

#### View Test Execution Details

```bash
# Run with verbose output
nf-test test --verbose

# Run with debug mode
nf-test test --debug

# Check specific test work directory
ls -la .nf-test/tests/<test-id>/
```

#### Inspect Nextflow Work Directory

```bash
# Work directory is preserved for inspection
ls -la work/

# View process script
cat work/XX/XXXXXXXX*/script

# View process logs
cat work/XX/XXXXXXXX*/.command.log
```

#### Check Snapshot Files

```bash
# View snapshot content
cat tests/.nf-test.snapshot/default.nf.test.snap

# Compare with actual output
diff tests/.nf-test.snapshot/default.nf.test.snap .nf-test/tests/<test-id>/snapshot.json
```

#### Manual Test Execution

```bash
# Run pipeline manually with test parameters
nextflow run . \
    -profile test,docker \
    --input tests/data/v2/samplesheet.csv \
    --run_dir tests/data/v2/runs/TEST_RUN_001 \
    --outdir test_output
```

### Getting Help

1. **Check nf-test documentation**: https://www.nf-test.com/
2. **Review test examples**: Look at existing test files in `tests/`
3. **Check Nextflow logs**: `tail -f .nextflow.log`
4. **Open an issue**: Include test output and error messages

---

## Advanced Topics

### Custom Assertions

```groovy
// Check specific file content
assert path("${params.outdir}/file.txt").text.contains("expected content")

// Validate file size
assert path("${params.outdir}/file.fastq.gz").size() > 0

// Count files matching pattern
assert path("${params.outdir}").list().size() == 5

// Check process exit codes
assert workflow.trace.tasks().every { task -> task.exitStatus == 0 }
```

### Parameterized Tests

```groovy
// Test multiple parameter combinations
['bclconvert', 'bcl2fastq'].each { demux ->
    test("Test with ${demux}") {
        when {
            params {
                demultiplexer = demux
                // other params...
            }
        }
        then {
            assert workflow.success
        }
    }
}
```

### Process-Level Testing

```groovy
// Test individual process
nextflow_process {
    name "Test FASTQC process"
    script "modules/local/fastqc.nf"
    process "FASTQC"

    test("Should run FastQC on single file") {
        when {
            process {
                input[0] = [
                    [ id: 'test' ],
                    file('test_R1.fastq.gz')
                ]
            }
        }
        then {
            assert process.success
            assert process.out.html.size() == 1
            assert process.out.zip.size() == 1
        }
    }
}
```

---

## Summary

### Key Takeaways

✅ **23 comprehensive tests** covering all pipeline features  
✅ **Snapshot-based validation** for automated testing  
✅ **Stub mode support** for fast CI/CD feedback  
✅ **CI/CD ready** infrastructure with minimal resources  
✅ **nf-core standard** testing patterns  

### Test Execution Commands

```bash
# Quick validation (stub mode only)
nf-test test --tag stub

# Full test suite
nf-test test

# Update snapshots after changes
nf-test test --updateSnapshot

# Run with specific profile
nextflow run . -profile test,docker
nextflow run . -profile test_full,docker
```

### Next Steps

1. Run tests locally to validate your setup
2. Integrate with CI/CD for automated testing
3. Add new tests for new features
4. Keep snapshots up to date with pipeline changes

For questions or issues, refer to the [Troubleshooting](#troubleshooting) section or consult the [nf-test documentation](https://www.nf-test.com/).
