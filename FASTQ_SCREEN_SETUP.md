# FastQ Screen Database Setup Guide

This guide explains how to download and build the reference genome databases for fastq_screen contamination screening.

## Prerequisites

- **Bowtie2** installed and in your PATH
- **wget** or **curl** for downloading
- At least **50 GB** of free disk space (for all genomes)
- Approximately **4-6 hours** for downloading and indexing all databases

## Recommended Directory Structure

```bash
# Create a base directory for all databases
mkdir -p /path/to/fastq_screen_databases
cd /path/to/fastq_screen_databases
```

Replace `/path/to/fastq_screen_databases` with your preferred location (e.g., `/data/references/fastq_screen_db` or `$HOME/references/fastq_screen_db`)

---

## Database Download and Index Building

### 1. Human (hg38) - ~3.1 GB genome, ~8 GB indexed

```bash
mkdir -p hg38 && cd hg38

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz

# Extract
gunzip hg38.fa.gz

# Build bowtie2 index (takes ~2 hours)
bowtie2-build --threads 8 hg38.fa hg38

# Clean up FASTA to save space (optional - keep if you need the reference)
# rm hg38.fa

cd ..
```

**Index files created:** `hg38.1.bt2`, `hg38.2.bt2`, `hg38.3.bt2`, `hg38.4.bt2`, `hg38.rev.1.bt2`, `hg38.rev.2.bt2`

---

### 2. Mouse (mm10) - ~2.7 GB genome, ~7 GB indexed

```bash
mkdir -p mm10 && cd mm10

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz

# Extract
gunzip mm10.fa.gz

# Build bowtie2 index (takes ~1.5 hours)
bowtie2-build --threads 8 mm10.fa mm10

# Clean up FASTA (optional)
# rm mm10.fa

cd ..
```

---

### 3. Rat (rn6) - ~2.8 GB genome, ~7 GB indexed

```bash
mkdir -p rat && cd rat

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/rn6/bigZips/rn6.fa.gz

# Extract
gunzip rn6.fa.gz

# Build bowtie2 index (takes ~1.5 hours)
bowtie2-build --threads 8 rn6.fa rn6

# Clean up FASTA (optional)
# rm rn6.fa

cd ..
```

---

### 4. UniVec (Vector Database) - ~10 MB

```bash
mkdir -p univec && cd univec

# Download
wget -O univec.fa https://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec

# Build bowtie2 index (takes ~1 minute)
bowtie2-build univec.fa univec

cd ..
```

---

### 5. PhiX Control - ~5 KB

```bash
mkdir -p phix && cd phix

# Download
wget -O phix.fa "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=NC_001422.1&rettype=fasta"

# Build bowtie2 index (takes <1 minute)
bowtie2-build phix.fa phix

cd ..
```

---

### 6. Adapters (Illumina) - ~1 KB

```bash
mkdir -p adapters && cd adapters

# Create adapter sequences file
cat > adapters.fa << 'EOF'
>TruSeq_Universal_Adapter
AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT
>TruSeq_Adapter_Index
GATCGGAAGAGCACACGTCTGAACTCCAGTCAC
>Nextera_Transposase_Sequence
CTGTCTCTTATACACATCT
>SOLID_Small_RNA_Adapter
CGCCTTGGCCGTACAGGCG
>Illumina_PCR_Primer
AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT
>Illumina_Sequencing_Primer
ACACTCTTTCCCTACACGACGCTCTTCCGATCT
>Illumina_Multiplexing_Adapter
GATCGGAAGAGCACACGTCT
EOF

# Build bowtie2 index (takes <1 minute)
bowtie2-build adapters.fa adapters

cd ..
```

---

### 7. E. coli (K-12 MG1655) - ~4.6 MB genome, ~20 MB indexed

```bash
mkdir -p ecoli && cd ecoli

# Download
wget -O ecoli.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"

# Extract
gunzip ecoli.fa.gz

# Build bowtie2 index (takes ~1 minute)
bowtie2-build ecoli.fa ecoli

# Clean up FASTA (optional)
# rm ecoli.fa

cd ..
```

---

### 8. Yeast (S. cerevisiae S288C) - ~12 MB genome, ~50 MB indexed

```bash
mkdir -p yeast && cd yeast

# Download
wget -O yeast.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz"

# Extract
gunzip yeast.fa.gz

# Build bowtie2 index (takes ~1 minute)
bowtie2-build yeast.fa yeast

# Clean up FASTA (optional)
# rm yeast.fa

cd ..
```

---

### 9. Drosophila (dm6) - ~143 MB genome, ~600 MB indexed

```bash
mkdir -p drosophila && cd drosophila

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/dm6/bigZips/dm6.fa.gz

# Extract
gunzip dm6.fa.gz

# Build bowtie2 index (takes ~10 minutes)
bowtie2-build --threads 8 dm6.fa drosophila

# Clean up FASTA (optional)
# rm dm6.fa

cd ..
```

---

### 10. Mycoplasma (M. genitalium G37) - ~580 KB genome, ~3 MB indexed

```bash
mkdir -p mycoplasma && cd mycoplasma

# Download
wget -O mycoplasma.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/325/GCF_000027325.1_ASM2732v1/GCF_000027325.1_ASM2732v1_genomic.fna.gz"

# Extract
gunzip mycoplasma.fa.gz

# Build bowtie2 index (takes <1 minute)
bowtie2-build mycoplasma.fa mycoplasma

# Clean up FASTA (optional)
# rm mycoplasma.fa

cd ..
```

---

### 11. Bacterial (RefSeq Representative Bacteria)

**Option A: Pre-built Kraken2/Bracken database (Recommended)**
```bash
mkdir -p bacterial && cd bacterial

# Download pre-built bacterial representative genomes from RefSeq
# This is a smaller curated set (~8 GB)
wget https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20240112.tar.gz
tar -xzf k2_standard_08gb_20240112.tar.gz
# Convert to bowtie2 format or use alternate screening approach

cd ..
```

**Option B: NCBI RefSeq Representative Bacterial Genomes**
```bash
mkdir -p bacterial && cd bacterial

# Download representative bacterial genomes (this is large, ~50+ GB)
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/bacteria/bacteria.*.genomic.fna.gz
cat bacteria.*.genomic.fna.gz > bacterial_all.fa.gz
gunzip bacterial_all.fa.gz

# Build bowtie2 index (takes several hours)
bowtie2-build --threads 8 --large-index bacterial_all.fa bacterial

cd ..
```

**Note:** For practical contamination screening, using E. coli alone may be sufficient for bacterial contamination. The full bacterial database is very large.

---

### 12. Viral (RefSeq Viral Database)

```bash
mkdir -p viral && cd viral

# Download all viral genomes from RefSeq (~500 MB)
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.1.1.genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.2.1.genomic.fna.gz

# Combine and extract
gunzip -c viral.*.genomic.fna.gz > viral_all.fa

# Build bowtie2 index (takes ~5 minutes)
bowtie2-build --threads 8 viral_all.fa viral

# Clean up
rm viral.*.genomic.fna.gz
# rm viral_all.fa  # optional

cd ..
```

---

## Create FastQ Screen Configuration File

After building all databases, create a configuration file:

```bash
cd /path/to/fastq_screen_databases

cat > fastq_screen.conf << 'EOF'
# FastQ Screen Configuration File
# Format: DATABASE <name> <path_to_bowtie2_index>

DATABASE    hg38           /path/to/fastq_screen_databases/hg38/hg38
DATABASE    mm10           /path/to/fastq_screen_databases/mm10/mm10
DATABASE    rat            /path/to/fastq_screen_databases/rat/rn6
DATABASE    univec         /path/to/fastq_screen_databases/univec/univec
DATABASE    phix           /path/to/fastq_screen_databases/phix/phix
DATABASE    adapters       /path/to/fastq_screen_databases/adapters/adapters
DATABASE    ecoli          /path/to/fastq_screen_databases/ecoli/ecoli
DATABASE    yeast          /path/to/fastq_screen_databases/yeast/yeast
DATABASE    drosophila     /path/to/fastq_screen_databases/drosophila/drosophila
DATABASE    mycoplasma     /path/to/fastq_screen_databases/mycoplasma/mycoplasma
DATABASE    viral          /path/to/fastq_screen_databases/viral/viral

# Optional: Add bacterial if you built it
# DATABASE    bacterial      /path/to/fastq_screen_databases/bacterial/bacterial
EOF
```

**Important:** Replace `/path/to/fastq_screen_databases` with your actual path in the config file.

---

## Update Pipeline Configuration

Edit `nextflow.config` to point to your config file:

```groovy
params {
    fastq_screen_config = '/path/to/fastq_screen_databases/fastq_screen.conf'
}
```

Or pass it at runtime:

```bash
nextflow run main.nf \
    --input runs.csv \
    --fastq_screen_config /path/to/fastq_screen_databases/fastq_screen.conf
```

---

## Quick Setup Script

For convenience, here's a complete script to download and build all recommended databases:

```bash
#!/bin/bash

# Set your database directory
DB_DIR="/path/to/fastq_screen_databases"
THREADS=8

mkdir -p "$DB_DIR"
cd "$DB_DIR"

# Small databases first (quick)
echo "Building small databases..."
# [Add the small database commands from above]

# Large databases (optional - comment out if not needed)
echo "Building large genomes (hg38, mm10, rat)..."
# [Add the large genome commands from above]

echo "Done! Config file created at $DB_DIR/fastq_screen.conf"
```

---

## Disk Space Summary

| Database | Genome Size | Index Size | Build Time (8 cores) |
|----------|-------------|------------|----------------------|
| hg38 | 3.1 GB | ~8 GB | ~2 hours |
| mm10 | 2.7 GB | ~7 GB | ~1.5 hours |
| rat | 2.8 GB | ~7 GB | ~1.5 hours |
| drosophila | 143 MB | ~600 MB | ~10 minutes |
| yeast | 12 MB | ~50 MB | ~1 minute |
| ecoli | 4.6 MB | ~20 MB | ~1 minute |
| mycoplasma | 580 KB | ~3 MB | <1 minute |
| viral | 500 MB | ~2 GB | ~5 minutes |
| univec | 10 MB | ~30 MB | ~1 minute |
| phix | 5 KB | ~20 KB | <1 minute |
| adapters | 1 KB | ~5 KB | <1 minute |
| **Total** | **~9 GB** | **~25 GB** | **~5-6 hours** |

**Note:** Bacterial database is optional but adds ~50 GB if included.

---

## Testing Your Setup

Test that fastq_screen can find all databases:

```bash
fastq_screen --version
fastq_screen --conf /path/to/fastq_screen_databases/fastq_screen.conf --test
```

---

## Alternative: Minimal Setup (Quick Start)

If you want to start quickly with just the most important databases:

```bash
# Essential databases only (~2 GB total, ~30 minutes)
mkdir -p fastq_screen_minimal
cd fastq_screen_minimal

# 1. PhiX (sequencing control)
# 2. Adapters (Illumina adapters)
# 3. E. coli (bacterial contamination)
# 4. UniVec (vector contamination)

# [Use the individual commands from sections 4, 5, 6, 7 above]
```

This minimal setup covers the most common contamination sources and builds in under 30 minutes.
