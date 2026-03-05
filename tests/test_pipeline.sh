#!/bin/bash
set -e

# Test script for BCL Convert pipeline
echo "=========================================="
echo "Testing BCL Convert Pipeline"
echo "=========================================="

# Test 1: Check syntax with nextflow config
echo ""
echo "Test 1: Checking Nextflow syntax..."
nextflow config main.nf > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Syntax check passed"
else
    echo "❌ Syntax check failed"
    exit 1
fi

# Test 2: Lint the pipeline
echo ""
echo "Test 2: Running nextflow lint..."
nextflow lint main.nf
if [ $? -eq 0 ]; then
    echo "✅ Linting passed"
else
    echo "❌ Linting failed"
    exit 1
fi

# Test 3: Validate parameter schema
echo ""
echo "Test 3: Validating parameter schema..."
if [ -f nextflow_schema.json ]; then
    echo "✅ Schema file exists"
else
    echo "⚠️  No schema file found (optional)"
fi

# Test 4: Check required files exist
echo ""
echo "Test 4: Checking required files..."
required_files=(
    "main.nf"
    "nextflow.config"
    "modules/bclconvert.nf"
    "modules/fastqc.nf"
    "modules/fastq_screen.nf"
    "modules/multiqc.nf"
)

all_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file missing"
        all_exist=false
    fi
done

if [ "$all_exist" = true ]; then
    echo "✅ All required files exist"
else
    echo "❌ Some required files missing"
    exit 1
fi

# Test 5: Dry run with test data
echo ""
echo "Test 5: Dry run with test input..."
if [ -f tests/test_input.csv ]; then
    nextflow run main.nf \
        -profile docker \
        --input tests/test_input.csv \
        --outdir test_results \
        -preview
    if [ $? -eq 0 ]; then
        echo "✅ Dry run completed"
    else
        echo "❌ Dry run failed"
        exit 1
    fi
else
    echo "⚠️  No test data found, skipping dry run"
fi

echo ""
echo "=========================================="
echo "All tests passed! ✅"
echo "=========================================="
