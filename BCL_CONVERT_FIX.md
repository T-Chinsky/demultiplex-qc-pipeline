# Demultiplexer Read-Only Filesystem Fix

**Date**: 2026-03-30  
**Issue**: Exit status 134 - Demultiplexers cannot write to read-only system directories

## Problem

Both BCL Convert and BCL2FASTQ may attempt to write diagnostic logs to system directories inside Singularity containers that are read-only, causing processes to abort with exit status 134.

### BCL Convert Error:
```
Exception thrown in /data/jenkins/workspace/dragen_4.4.6/src/host/infra/util/dragen_run_log.cpp line 143 
-- Could not open log file /var/log/bcl-convert/dragen_run_1774836169636_42.log
```

### Preventive Fix for BCL2FASTQ:
Applied same protective measures to prevent similar issues with bcl2fastq2.

## Solution

### BCL Convert (`modules/local/bclconvert.nf`)

1. **Create writable log directory** in the process work directory:
   ```bash
   mkdir -p bcl_logs
   export BCL_LOG_DIR=$PWD/bcl_logs
   ```

2. **Redirect BCL Convert logs** to the work directory:
   ```bash
   bcl-convert \
       --log-level INFO \
       --log-file bcl_logs/bcl-convert.log \
       ...
   ```

### BCL2FASTQ (`modules/nf-core/bcl2fastq/main.nf`)

1. **Create writable directories** for logs and temp files:
   ```bash
   mkdir -p bcl2fastq_logs
   export BCL2FASTQ_LOG_DIR=$PWD/bcl2fastq_logs
   export TMPDIR=$PWD/tmp
   mkdir -p $TMPDIR
   ```

2. **Capture all output** to log file:
   ```bash
   bcl2fastq ... 2>&1 | tee bcl2fastq_logs/bcl2fastq.log
   ```

This ensures all diagnostic and log files are written to writable locations within the Nextflow work directory for both demultiplexing tools.

## Secondary Fix: Workflow Completion Handler

Also removed auto-cleanup code from `workflow.onComplete` block that was causing:
```
ERROR ~ Invalid method invocation `call` with arguments: [id:AAHNHWNM5, ...] on _closure14 type
```

The `.execute()` method on strings was conflicting with Nextflow's closure handling. Replaced with informational messages about manual cleanup.

## Files Changed

- `modules/local/bclconvert.nf` - Added log directory creation and log redirection
- `modules/nf-core/bcl2fastq/main.nf` - Added log directory, TMPDIR, and output capture
- `main.nf` - Disabled auto-cleanup, added informational messages

## Testing

Re-run the pipeline with the same command:
```bash
nextflow run main.nf \
    --input sample_input.csv \
    --outdir results \
    -profile singularity
```

Both BCL Convert and BCL2FASTQ processes should now complete successfully without read-only filesystem errors.

## Benefits

1. **BCL Convert**: Properly redirects DRAGEN diagnostic logs to work directory
2. **BCL2FASTQ**: Captures all output and sets TMPDIR to avoid system directory writes
3. **Debugging**: All logs are preserved in process work directories for troubleshooting
4. **Portability**: Works with both Docker and Singularity profiles
