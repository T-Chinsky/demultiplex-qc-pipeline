#!/bin/bash
# Test script to verify the Singularity configuration is correct

echo "========================================="
echo "BCL Convert Singularity Configuration Test"
echo "========================================="
echo ""

# Check if nextflow.config contains the fix
echo "1. Checking nextflow.config for Singularity runOptions..."
if grep -q "runOptions.*--bind.*bcl_convert_logs:/var/log/bcl-convert" nextflow.config; then
    echo "   ✅ Singularity runOptions configured correctly"
else
    echo "   ❌ Singularity runOptions NOT found"
    exit 1
fi

# Check if the bind path uses escaped $PWD
echo ""
echo "2. Checking for proper variable escaping..."
if grep -q 'runOptions.*\\$PWD' nextflow.config; then
    echo "   ✅ Variable \$PWD properly escaped for runtime evaluation"
else
    echo "   ⚠️  WARNING: \$PWD may not be escaped properly"
fi

# Check if BCLCONVERT process creates the directory
echo ""
echo "3. Checking BCLCONVERT process for directory creation..."
if grep -q "mkdir.*bcl_convert_logs" modules/local/bclconvert.nf; then
    echo "   ✅ BCLCONVERT process creates bcl_convert_logs directory"
else
    echo "   ❌ BCLCONVERT process does NOT create bcl_convert_logs directory"
    exit 1
fi

# Validate config syntax
echo ""
echo "4. Validating Nextflow configuration syntax..."
if nextflow config -profile singularity > /dev/null 2>&1; then
    echo "   ✅ Configuration syntax is valid"
else
    echo "   ❌ Configuration syntax error detected"
    exit 1
fi

# Show the actual runOptions value
echo ""
echo "5. Actual Singularity runOptions value:"
nextflow config -profile singularity 2>/dev/null | grep -A 1 "singularity {" | grep runOptions | sed 's/^/   /'

echo ""
echo "========================================="
echo "✅ All checks passed!"
echo "========================================="
echo ""
echo "The pipeline is ready to test with Singularity."
echo "Run with: nextflow run main.nf -profile singularity --input <samplesheet.csv> --outdir results"
