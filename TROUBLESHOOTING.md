# Troubleshooting Guide - BCL QC Pipeline

This guide covers common issues and their solutions.

---

## Table of Contents

1. [Input and Data Issues](#input-and-data-issues)
2. [Resource Problems](#resource-problems)
3. [Container Issues](#container-issues)
4. [Module-Specific Errors](#module-specific-errors)
5. [Testing Problems](#testing-problems)
6. [Performance Issues](#performance-issues)
7. [Configuration Errors](#configuration-errors)

---

## Input and Data Issues

### Error: "No such file or directory"

**Symptoms**:
```
ERROR ~ Error executing process > 'BCLCONVERT:SAMPLESHEET_DETECTION'
Caused by: No such file or directory: /path/to/samplesheet.csv
```

**Solutions**:

1. **Use absolute paths in CSV**:
```csv
# WRONG - relative paths
run_id,samplesheet,run_dir,multiqc_title
RUN1,data/sheet.csv,data/run1,Report

# CORRECT - absolute paths
run_id,samplesheet,run_dir,multiqc_title
RUN1,/home/user/data/sheet.csv,/home/user/data/run1,Report
```

2. **Check file exists**:
```bash
ls -l /path/to/samplesheet.csv
```

3. **Check permissions**:
```bash
ls -la /path/to/samplesheet.csv
chmod 644 /path/to/samplesheet.csv
```

---

### Error: "Input CSV validation failed"

**Symptoms**:
```
ERROR: Missing required column 'samplesheet' in input CSV
ERROR: The following rows have empty required fields: [2, 3]
```

**Solutions**:

1. **Check CSV headers** (case-sensitive):
```csv
# CORRECT headers
run_id,samplesheet,run_dir,multiqc_title
```

2. **Ensure no empty cells** in required columns:
```csv
# WRONG - empty run_dir
RUN1,/path/sheet.csv,,Report

# CORRECT
RUN1,/path/sheet.csv,/path/run,Report
```

3. **Check for hidden characters** (especially Windows-generated CSVs):
```bash
# Convert line endings
dos2unix input.csv
```

---

### Error: "Samplesheet format not recognized"

**Symptoms**:
```
ERROR: Could not determine samplesheet version from header
```

**Solutions**:

1. **Check samplesheet header format**:

BCL Convert v2 (simple):
```csv
Lane,Sample_ID,index,index2
1,Sample1,ACGTACGT,TGCATGCA
```

BCL Convert v2 (with header):
```csv
[Header]
FileFormatVersion,2
[BCLConvert_Data]
Lane,Sample_ID,Index,Index2
```

bcl2fastq v1:
```csv
FCID,Lane,Sample_ID,SampleRef,Index,Description
```

2. **Check for BOM** (Byte Order Mark):
```bash
# Remove BOM if present
sed -i '1s/^\xEF\xBB\xBF//' samplesheet.csv
```

---

## Resource Problems

### Error: "Process requirement exceeds available memory"

**Symptoms**:
```
ERROR: Process 'BCLCONVERT' requires 128 GB memory but only 64 GB available
```

**Solutions**:

1. **Set lower max_memory**:
```bash
nextflow run main.nf \
--max_memory 64.GB \
--input input.csv
```

2. **Use test profile** for limited resources:
```bash
nextflow run main.nf \
-profile test,docker
```

3. **Check system resources**:
```bash
free -h # Check available memory
nproc # Check CPU count
```

---

### Error: "Process killed (signal 9)"

**Symptoms**:
```
ERROR: Process BCLCONVERT terminated with signal 9 (SIGKILL)
```

**Cause**: Out-of-memory (OOM) killer terminated the process

**Solutions**:

1. **Increase max_memory**:
```bash
nextflow run main.nf \
--max_memory 128.GB \
--input input.csv
```

2. **Reduce parallel jobs**:
```bash
nextflow run main.nf \
--max_cpus 8 \
--input input.csv
```

3. **Check system logs**:
```bash
dmesg | grep -i "out of memory"
```

---

## Container Issues

### Error: "Docker permission denied"

**Symptoms**:
```
ERROR: Got permission denied while trying to connect to Docker daemon
```

**Solutions**:

1. **Add user to docker group**:
```bash
sudo usermod -aG docker $USER
# Log out and back in for changes to take effect
```

2. **Or use sudo** (not recommended for production):
```bash
sudo nextflow run main.nf -profile docker
```

3. **Or use Singularity instead**:
```bash
nextflow run main.nf -profile singularity
```

---

### Error: "Container not found"

**Symptoms**:
```
ERROR: Failed to pull Docker image: community.wave.seqera.io/library/...
```

**Solutions**:

1. **Check internet connection**:
```bash
ping -c 3 community.wave.seqera.io
```

2. **Pull manually to test**:
```bash
docker pull community.wave.seqera.io/library/samtools:1.21--aeabac5fd3be86cb
```

3. **Check Wave service status**: Visit https://wave.seqera.io

4. **Use local cache** if available:
```bash
# Set Singularity cache directory
export NXF_SINGULARITY_CACHEDIR=/path/to/cache
```

---

### Error: "Singularity not found"

**Symptoms**:
```
ERROR: Cannot find Singularity executable
```

**Solutions**:

1. **Install Singularity**:
```bash
# Ubuntu/Debian
sudo apt-get install singularity-container

# Or download from: https://github.com/sylabs/singularity
```

2. **Check PATH**:
```bash
which singularity
echo $PATH
```

3. **Module load** (on HPC):
```bash
module load singularity
```

---

## Module-Specific Errors

### BCLConvert Error: "No BCL data found"

**Symptoms**:
```
ERROR: No BaseCalls directory found in run_dir
```

**Solutions**:

1. **Check run directory structure**:
```bash
ls -l /path/to/run_dir/
# Should contain: Data/Intensities/BaseCalls/
```

2. **Verify BCL files present**:
```bash
find /path/to/run_dir -name "*.bcl*"
```

3. **Check RunInfo.xml exists**:
```bash
ls /path/to/run_dir/RunInfo.xml
```

---

### bcl2fastq Error: "Index sequence mismatch"

**Symptoms**:
```
ERROR: Index length in samplesheet doesn't match RunInfo.xml
```

**Solutions**:

1. **Check index lengths** in RunInfo.xml:
```bash
grep "Read" /path/to/run_dir/RunInfo.xml
```

2. **Update samplesheet** to match index lengths:
```csv
# If RunInfo.xml shows 8bp indexes, use 8bp in samplesheet
Sample_ID,Index
Sample1,ACGTACGT # 8bp, not ACGTACGTN
```

---

### FastQ Screen Error: "No database configured"

**Symptoms**:
```
ERROR: FastQ Screen database not found
```

**Solutions**:

1. **Skip FastQ Screen**:
```bash
nextflow run main.nf \
--skip_fastq_screen \
--input input.csv
```

2. **Or provide config**:
```bash
nextflow run main.nf \
--fastq_screen_config /path/to/fastq_screen.conf \
--input input.csv
```

3. **Check config file format**:
```conf
DATABASE human /path/to/human_ref
DATABASE mouse /path/to/mouse_ref
```

---

### MultiQC Error: "No reports found"

**Symptoms**:
```
WARNING: MultiQC found no valid reports
```

**Solutions**:

1. **Check upstream modules completed**:
```bash
ls -l work/ # Check for output files
```

2. **Verify process outputs**:
```bash
# Check FASTQC outputs
find work/ -name "*_fastqc.html"
```

3. **Run with -resume** to regenerate:
```bash
nextflow run main.nf -resume -profile docker
```

---

## Testing Problems

### nf-test Error: "Docker daemon not accessible"

**Symptoms**:
```
ERROR: Cannot connect to Docker daemon in nf-test
```

**Solutions**:

1. **Run stub tests only**:
```bash
nf-test test tests/ --tag stub
```

2. **Check Docker socket**:
```bash
ls -l /var/run/docker.sock
sudo chmod 666 /var/run/docker.sock # Temporary fix
```

3. **Add user to docker group** (see Container Issues above)

---

### nf-test Error: "Test data not found"

**Symptoms**:
```
ERROR: No such file: tests/data/v2/samplesheet.csv
```

**Solutions**:

1. **Verify test data exists**:
```bash
ls -la tests/data/
```

2. **Regenerate test data**:
```bash
# Run setup scripts if provided
bash tests/setup_test_data.sh
```

3. **Check working directory**:
```bash
pwd # Should be in project root
```

---

## Performance Issues

### Pipeline Running Slowly

**Symptoms**: Pipeline takes hours for small datasets

**Solutions**:

1. **Check resource allocation**:
```bash
nextflow run main.nf \
--max_cpus 32 \
--max_memory 128.GB \
--input input.csv
```

2. **Enable process parallelism**:
```groovy
// In nextflow.config
process.maxForks = 10
```

3. **Use local executor for testing**:
```bash
nextflow run main.nf \
-profile docker,test \
-process.executor local
```

4. **Check disk I/O**:
```bash
iostat -x 1 # Monitor disk performance
```

---

### Work Directory Growing Large

**Symptoms**: `work/` directory consuming excessive disk space

**Solutions**:

1. **Clean work directory** after successful runs:
```bash
nextflow clean -f
```

2. **Or clean specific runs**:
```bash
nextflow clean -n # Dry run - see what would be deleted
nextflow clean -f # Actually delete
```

3. **Use tmpdir for intermediate files**:
```bash
export NXF_TEMP=/path/to/large/tmpdir
```

---

## Configuration Errors

### Error: "Unknown config option"

**Symptoms**:
```
ERROR: Unknown config option 'params.my_param'
```

**Solutions**:

1. **Check parameter name** (case-sensitive):
```bash
# WRONG
--my_Param value

# CORRECT
--my_param value
```

2. **List available parameters**:
```bash
nextflow run main.nf --help
```

3. **Check config syntax**:
```groovy
// CORRECT
params.max_memory = '128.GB'

// WRONG
max_memory = '128.GB'
```

---

### Error: "Profile not found"

**Symptoms**:
```
ERROR: Unknown configuration profile: 'myprofile'
```

**Solutions**:

1. **List available profiles**:
```bash
grep "profiles {" nextflow.config -A 20
```

2. **Check profile name**:
```bash
# WRONG
-profile Docker

# CORRECT
-profile docker
```

3. **Create custom profile**:
```groovy
// In nextflow.config
profiles {
myprofile {
process.executor = 'slurm'
process.queue = 'normal'
}
}
```

---

## General Debugging Tips

### 1. Enable Debug Mode

```bash
nextflow run main.nf \
-profile docker \
--input input.csv \
-with-trace \
-with-report \
-with-timeline \
-with-dag dag.html
```

### 2. Check Work Directory

```bash
# Find failed process work directory
find work/ -name ".exitcode" -exec grep -l "1" {} \;

# Inspect command and logs
cd work/ab/cd123...
cat .command.sh # Command that was run
cat .command.out # stdout
cat .command.err # stderr
cat .command.log # Nextflow wrapper logs
```

### 3. Run Single Process

```bash
# Test specific process in isolation
nextflow run main.nf \
-entry test_process \
-profile docker
```

### 4. Increase Logging

```bash
export NXF_DEBUG=1
nextflow run main.nf -profile docker
```

### 5. Resume Failed Runs

```bash
# Resume from last successful step
nextflow run main.nf -resume -profile docker
```

---

## Getting Help

If you're still stuck:

1. **Check logs**: Always review `.command.err` and `.command.log` files
2. **Search issues**: Check GitHub issues for similar problems
3. **Nextflow community**: https://nextflow.io/slack-invite.html
4. **nf-core help**: https://nf-co.re/join
5. **Read docs**: See README.md for complete documentation

---

## Common Solutions Summary

| Problem | Quick Fix |
|---------|-----------|
| Permission denied | `sudo usermod -aG docker $USER` |
| Out of memory | `--max_memory 64.GB` |
| File not found | Use absolute paths in CSV |
| Container pull fail | Check internet, try `-resume` |
| Test fail | Try `nf-test test --tag stub` |
| Slow performance | Increase `--max_cpus` |
| Work dir too large | `nextflow clean -f` |
| Process crash | Check `.command.err` in work dir |

---

## Preventive Measures

### Before Running
- Validate CSV with absolute paths
- Check disk space (`df -h`)
- Verify Docker/Singularity works
- Test with small dataset first
- Set appropriate resource limits

### During Running
- Monitor resource usage (`htop`, `nvidia-smi`)
- Check logs periodically
- Watch work directory size
- Keep terminal output

### After Running
- Review execution reports
- Check MultiQC for QC flags
- Clean work directory
- Archive results appropriately
- Document any issues encountered

---

**Still having issues?** Create a detailed issue report with:
- Exact command run
- Full error message
- `.command.err` content
- System information (`nextflow info`)
- Nextflow version (`nextflow -version`)
