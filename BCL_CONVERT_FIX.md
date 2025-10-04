# BCL Convert Read-Only Filesystem Fix

**Date**: 2026-03-30  
**Issue**: Exit status 134 - BCL Convert cannot write to `/var/log/bcl-convert/`

## Problem

BCL Convert was attempting to write diagnostic logs to `/var/log/bcl-convert/` inside the Singularity container, but this directory is read-only, causing the process to abort with exit status 134:

```
Exception thrown in /data/jenkins/workspace/dragen_4.4.6/src/host/infra/util/dragen_run_log.cpp line 143 
-- Could not open log file /var/log/bcl-convert/dragen_run_1774836169636_42.log
```

## Solution

Modified `modules/local/bclconvert.nf` to:

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

This ensures all diagnostic and log files are written to a writable location within the Nextflow work directory.

## Secondary Fix: Workflow Completion Handler

Also removed auto-cleanup code from `workflow.onComplete` block that was causing:
```
ERROR ~ Invalid method invocation `call` with arguments: [id:AAHNHWNM5, ...] on _closure14 type
```

The `.execute()` method on strings was conflicting with Nextflow's closure handling. Replaced with informational messages about manual cleanup.

## Files Changed

- `modules/local/bclconvert.nf` - Added log directory creation and log redirection
- `main.nf` - Disabled auto-cleanup, added informational messages

## Testing

Re-run the pipeline with the same command:
```bash
nextflow run main.nf \
    --input sample_input.csv \
    --outdir results \
    -profile singularity
```

The BCL Convert process should now complete successfully without read-only filesystem errors.
