# Nextflow Lint Report - Manual Review
**Date**: 2026-03-30  
**Pipeline**: demultiplex-qc-pipeline

## Summary
✅ **PASSED** - No critical issues found

## Files Reviewed
- `main.nf`
- `modules/local/bclconvert.nf`
- `modules/local/fastqc.nf`
- `modules/local/fastq_screen.nf`
- `modules/local/multiqc.nf`
- `modules/local/samplesheet_detection.nf`
- `modules/nf-core/bcl2fastq/main.nf`
- `subworkflows/local/bcl_qc_single_run.nf`
- `workflows/bclconvert.nf`
- `nextflow.config`

## ✅ Good Practices Found

### Proper DSL2 Structure
- ✅ All workflows use proper `take:`, `main:`, `emit:` blocks
- ✅ Processes have proper input/output definitions
- ✅ Include statements use correct syntax
- ✅ Channel operations follow DSL2 conventions

### Container Definitions
- ✅ All processes have container directives
- ✅ Using explicit `docker://` prefix for Singularity compatibility (bclconvert)
- ✅ Wave containers used where appropriate (fastqc, multiqc, fastq_screen)

### Code Organization
- ✅ Logical separation of processes, subworkflows, and workflows
- ✅ Proper use of meta maps for sample tracking
- ✅ Helper functions properly defined (check_max, helpMessage, paramsSummary)

### Configuration
- ✅ Parameters properly defined with defaults
- ✅ Process labels defined (process_high, process_medium, process_low)
- ✅ PublishDir directives configured
- ✅ Registry settings configured for Docker Hub

### Error Handling
- ✅ Parameter validation included (validateParams function)
- ✅ File existence checks in place
- ✅ Workflow completion handlers defined

## 🟡 Minor Style Observations (Non-blocking)

### Container URI Format
- **bclconvert.nf**: Uses `docker://ubgbc/bcl-convert:4.4.6`
  - ✅ **Correct** - Explicit docker:// prefix ensures Singularity pulls from Docker Hub
  
- **Other modules**: Use Wave/community containers without prefix
  - ✅ **Correct** - Wave containers resolve properly

### Optional: Nextflow.enable.strict (v25.10+)
Consider adding to nextflow.config for future-proofing:
```groovy
nextflow {
    enable {
        strict = true  // Enable strict syntax mode
    }
}
```

## 📝 Notes

### Workflow Naming
- Main workflow: `NFCORE_BCLCONVERT`
- Sub-workflow: `BCLCONVERT`
- ✅ No naming conflicts - proper scoping

### Process Outputs
- All processes emit proper channels
- Optional outputs marked with `optional: true`
- Versions tracked across all processes

### Script Blocks
- Triple-quoted strings used appropriately
- Variable interpolation with `${variable}` syntax
- Multi-line commands properly escaped with `\\`

## Recommendations

1. ✅ **Already implemented**: Explicit container URIs for Singularity
2. ✅ **Already implemented**: Docker Hub registry configuration
3. 🟢 **Optional**: Consider enabling strict syntax mode when ready for v25.10+
4. 🟢 **Optional**: Add nf-validation plugin for schema validation

## Conclusion
**Status**: ✅ **PRODUCTION READY**

The pipeline follows Nextflow DSL2 best practices and is properly structured. The container configuration has been fixed to work correctly with both Docker and Singularity profiles. No critical issues detected.
