# BCL Convert Logging Fix - Implementation Summary

## Problem
BCL Convert fails in Singularity containers because it attempts to write logs to `/var/log/bcl-convert/` before processing command-line arguments. This directory is read-only in the container environment, causing the process to fail and preventing execution timeline generation.

## Solution Implemented

### 1. Nextflow Configuration (`nextflow.config`)
Added Singularity `runOptions` to bind mount a writable directory:

```groovy
singularity {
    enabled                        = false
    autoMounts                     = true
    runOptions                     = '--bind \$PWD/bcl_convert_logs:/var/log/bcl-convert'
}
```

**Key Details:**
- `\$PWD` is escaped so it's evaluated at **task execution time** (not config parsing)
- At runtime, `$PWD` refers to the task's work directory
- BCL Convert's `/var/log/bcl-convert/` is mounted to `<task-work-dir>/bcl_convert_logs/`

### 2. BCLCONVERT Process (`modules/local/bclconvert.nf`)
Modified the process script to create the mount target directory:

```bash
# Create writable log directories (one for our logs, one for bcl-convert internal logs)
mkdir -p bcl_logs bcl_convert_logs
export BCL_LOG_DIR=$PWD/bcl_logs

bcl-convert \
    --sample-sheet ${samplesheet} \
    --bcl-input-directory ${run_dir} \
    --output-directory output \
    --force \
    --log-level INFO \
    --log-file bcl_logs/bcl-convert.log \
    ${extra_args}
```

**Key Details:**
- `bcl_convert_logs/` directory is created in the task work directory
- This directory is mounted to `/var/log/bcl-convert/` inside the container
- BCL Convert can now write its internal logs successfully

## Verification

### Configuration Check
```bash
nextflow config -profile singularity | grep -A 3 "singularity {"
```

**Output:**
```groovy
singularity {
   enabled = true
   autoMounts = true
   runOptions = '--bind $PWD/bcl_convert_logs:/var/log/bcl-convert'
```

✅ Configuration is correctly set with proper variable escaping

### Process Check
The BCLCONVERT process now includes:
1. ✅ Directory creation: `mkdir -p bcl_logs bcl_convert_logs`
2. ✅ Proper log file specification: `--log-file bcl_logs/bcl-convert.log`
3. ✅ Container-compatible logging path

## Expected Behavior After Fix

### During Execution
1. Nextflow creates the task work directory
2. Task script runs: `mkdir -p bcl_logs bcl_convert_logs`
3. Singularity launches with: `--bind <work-dir>/bcl_convert_logs:/var/log/bcl-convert`
4. BCL Convert writes internal logs to `/var/log/bcl-convert/` (mounted to work dir)
5. Process completes successfully

### After Successful Execution
- ✅ BCL Convert processes samples without logging errors
- ✅ Task work directories contain `bcl_convert_logs/` with internal BCL Convert logs
- ✅ Execution timeline is generated: `results/pipeline_info/execution_timeline.html`
- ✅ Other reports are generated without FileAlreadyExistsException errors

## Testing Instructions

### On a System with Singularity
```bash
nextflow run main.nf \
    -profile singularity \
    --input samplesheet.csv \
    --outdir results \
    -resume
```

### Verify Success
1. Check pipeline completes without errors
2. Verify reports exist:
   ```bash
   ls -lh results/pipeline_info/
   ```
3. Check BCL Convert logs:
   ```bash
   find work -name "bcl_convert_logs" -type d
   ```

## Technical Notes

### Why `\$PWD` instead of `$PWD`?
- **Without escape (`$PWD`)**: Evaluated at Nextflow config parsing → refers to launch directory
- **With escape (`\$PWD`)**: Evaluated at task execution → refers to task work directory
- **Required**: Each task needs its own isolated log directory

### Alternative Approaches Considered
1. ❌ Modify container to make `/var/log/bcl-convert/` writable → Requires custom container
2. ❌ Set BCL_LOG_DIR environment variable → BCL Convert writes before reading env vars
3. ✅ Bind mount writable directory → Works without modifying container or BCL Convert

## Files Modified
- `nextflow.config` (2 locations: global and singularity profile)
- `modules/local/bclconvert.nf` (process script section)

## Date
2026-03-30

## Status
✅ **READY FOR TESTING** - Configuration validated, awaiting Singularity environment test
