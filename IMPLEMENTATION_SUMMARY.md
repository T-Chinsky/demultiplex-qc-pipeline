# BCL2FASTQ2 Support Implementation Summary

## Overview
Successfully added bcl2fastq2 support to the BCL Convert pipeline with automatic samplesheet format detection. The pipeline now supports both BCL Convert (v2 samplesheets) and bcl2fastq2 (v1 samplesheets) with seamless auto-detection.

## Changes Made

### 1. New Modules Created

#### `modules/nf-core/bcl2fastq/main.nf`
- BCL2FASTQ process implementation
- Container: `community.wave.seqera.io/library/bcl2fastq2:2.20.0--1d9942001bacdbaa`
- Proper thread allocation (loading, processing, writing threads)
- Output channels: fastq, reports, stats, versions
- Compatible input/output signatures with BCL Convert

#### `bin/detect_samplesheet_version.py`
- Python script to detect samplesheet format
- Returns 'v1' for bcl2fastq2 format, 'v2' for BCL Convert format
- Detection logic:
  - Checks for `[BCLConvert_Settings]`, `[BCLConvert_Data]` → v2
  - Checks for `[Reads]` section → v1
  - Checks `IEMFileVersion` values (v4 → v1, v5 → v2)
  - Checks for `FileFormatVersion` → v2
- Exit code 0 on success, 1 on error

### 2. Updated Files

#### `subworkflows/local/bcl_qc_single_run.nf`
- Added samplesheet version detection using Python script
- Splits input channel based on demux tool (bclconvert vs bcl2fastq)
- Conditional execution of BCLCONVERT or BCL2FASTQ based on detection
- Proper channel handling for different input signatures
- Unified output channels for both demux tools

#### `workflows/bclconvert.nf`
- Integrated BCL2FASTQ subworkflow alongside BCLCONVERT
- Updated version tracking to include bcl2fastq2
- Seamless switching between tools based on samplesheet

#### `nextflow.config`
- Added `demux_tool` parameter (default: null = auto-detect)
- Added `bcl_sampleproject_subdirectories` parameter (default: false)
- Added `no_lane_splitting` parameter (default: false)
- Updated help text to document new parameters

#### `conf/base.config`
- Resource label configurations for process_low, process_medium, process_high
- Proper CPU and memory allocation based on task attempt and max resources

#### `conf/modules.config`
- Module-specific configurations for BCLCONVERT and BCL2FASTQ
- Publishing directories for outputs

### 3. Configuration Files Updated

#### `README.md`
- Added documentation for new parameters
- Usage examples for both auto-detection and manual tool selection
- Samplesheet format compatibility guide

## Detection Logic Flow

```
Input Samplesheet
    ↓
Run detect_samplesheet_version.py
    ↓
Check for format markers:
  - [BCLConvert_Settings]/[BCLConvert_Data] → v2
  - [Reads] section → v1
  - IEMFileVersion=4 → v1
  - IEMFileVersion=5 → v2
  - FileFormatVersion → v2
    ↓
Return v1 or v2
    ↓
Channel splits:
  - v2 → BCLCONVERT process
  - v1 → BCL2FASTQ process
    ↓
Unified FASTQ outputs
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--demux_tool` | `null` | Force specific demux tool ('bcl2fastq' or 'bclconvert'). If null, auto-detects from samplesheet format |
| `--bcl_sampleproject_subdirectories` | `false` | Create subdirectories for each Sample_Project in BCL Convert output |
| `--no_lane_splitting` | `false` | Disable lane splitting in BCL Convert output |

## Usage Examples

### Auto-detection (Recommended)
```bash
nextflow run main.nf \
  --input runs.csv \
  --outdir results
```

### Force BCL Convert
```bash
nextflow run main.nf \
  --input runs.csv \
  --outdir results \
  --demux_tool bclconvert
```

### Force bcl2fastq2
```bash
nextflow run main.nf \
  --input runs.csv \
  --outdir results \
  --demux_tool bcl2fastq
```

## Testing Performed

1. ✅ Nextflow lint - all files pass without errors or warnings
2. ✅ Config parsing - all parameters recognized
3. ✅ Help text display - new parameters documented
4. ✅ Samplesheet v1 detection - correctly identifies bcl2fastq2 format
5. ✅ Samplesheet v2 detection - correctly identifies BCL Convert format
6. ✅ Pipeline syntax validation - no errors

## Test Samplesheets Created

- `test_samplesheet_v1.csv` - bcl2fastq2 format with [Reads] section
- `test_samplesheet_v2.csv` - BCL Convert format with [BCLConvert_Settings]

## Container Images

Both demux tools use Wave containers for reproducibility:
- BCL Convert: `community.wave.seqera.io/library/bclconvert:4.2.7--abc21b231d8db3e0`
- bcl2fastq2: `community.wave.seqera.io/library/bcl2fastq2:2.20.0--1d9942001bacdbaa`

## Next Steps

To fully validate the pipeline:
1. Test with real BCL data for both formats
2. Verify FASTQ output compatibility
3. Compare QC metrics between tools
4. Add integration tests with test datasets
5. Update test profile with example BCL data

## Files Modified/Created

**New Files:**
- `modules/nf-core/bcl2fastq/main.nf`
- `bin/detect_samplesheet_version.py`
- `conf/base.config`
- `test_samplesheet_v1.csv`
- `test_samplesheet_v2.csv`

**Modified Files:**
- `subworkflows/local/bcl_qc_single_run.nf`
- `workflows/bclconvert.nf`
- `nextflow.config`
- `conf/modules.config`
- `README.md`

## Linting Status

✅ All 12 Nextflow files pass `nextflow lint` without errors or warnings
