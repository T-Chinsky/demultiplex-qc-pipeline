# FastQ Screen Database Setup Guide

> 📘 **Part of:** [Demultiplex + QC Pipeline](../README.md)

This guide provides complete instructions for setting up reference genome databases for FastQ Screen contamination screening.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start: Minimal Setup](#quick-start-minimal-setup-30-minutes)
- [Full Setup: All Reference Genomes](#full-setup-all-reference-genomes)
- [Database Reference Table](#database-reference-table)
- [Individual Database Build Instructions](#individual-database-build-instructions)
- [Configuration File Setup](#configuration-file-setup)
- [Testing Your Setup](#testing-your-setup)
- [Using With the Pipeline](#using-with-the-pipeline)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Overview

FastQ Screen is a quality control tool that screens sequencing reads against a panel of reference genomes to detect contamination. This is essential for:

- **Multi-organism projects** - Detecting cross-contamination between species
- **Quality assurance** - Identifying adapter sequences, vectors, and common contaminants
- **Troubleshooting** - Diagnosing unexpected results from bacterial, viral, or mycoplasma contamination

This guide covers two setup approaches:
1. **Quick Start** (4 databases, ~30 minutes) - Essential screening for testing
2. **Full Setup** (11 databases, ~5-6 hours) - Comprehensive contamination detection

---

## Prerequisites

Before starting, ensure you have:

- **Bowtie2** (v2.3.0 or later) installed and available in your PATH
  ```bash
  bowtie2 --version
  ```
- **wget** or **curl** for downloading reference genomes
- **At least 50 GB free disk space** (for full setup with all genomes)
- **8-16 GB RAM** for building larger genome indices
- **4-8 CPU cores** recommended for faster indexing

**Time Requirements:**
- Quick Start: ~30 minutes
- Full Setup: ~5-6 hours (depending on download speeds and CPU cores)

---

## Quick Start: Minimal Setup (~30 minutes)

For testing or essential contamination screening, set up these 4 core databases:

### Step 1: Create Database Directory

```bash
# Choose a location with sufficient space
mkdir -p /path/to/fastq_screen_databases
cd /path/to/fastq_screen_databases
```

### Step 2: Build Core Databases

#### 1. PhiX Control (~1 minute)

PhiX is used as a sequencing control - high alignment indicates proper lane balance.

```bash
mkdir -p phix && cd phix
wget -O phix.fa "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=NC_001422.1&rettype=fasta"
bowtie2-build phix.fa phix
cd ..
```

**Database files:** `phix.1.bt2`, `phix.2.bt2`, etc. (~20 KB total)

#### 2. Illumina Adapters (~1 minute)

Detects adapter dimers and read-through.

```bash
mkdir -p adapters && cd adapters
cat > adapters.fa << 'EOF'
>TruSeq_Universal_Adapter
AATGATACGGCGACCACCGAGATCTACACTCTTTCCCTACACGACGCTCTTCCGATCT
>TruSeq_Adapter_Index
GATCGGAAGAGCACACGTCTGAACTCCAGTCAC
>Nextera_Transposase_Sequence
CTGTCTCTTATACACATCT
>Illumina_Multiplexing_Adapter
GATCGGAAGAGCACACGTCT
>TruSeq_PCR_Primer
CAAGCAGAAGACGGCATACGAGAT
>TruSeq_Adapter_Index_RC
GTGACTGGAGTTCAGACGTGTGCTCTTCCGATCT
EOF
bowtie2-build adapters.fa adapters
cd ..
```

**Database files:** `adapters.1.bt2`, `adapters.2.bt2`, etc. (~5 KB total)

#### 3. E. coli (~5 minutes)

Most common bacterial contaminant.

```bash
mkdir -p ecoli && cd ecoli
wget -O ecoli.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
gunzip ecoli.fa.gz
bowtie2-build ecoli.fa ecoli
cd ..
```

**Database files:** ~20 MB total

#### 4. UniVec (~5 minutes)

NCBI's comprehensive vector database (cloning vectors, adapters, linkers).

```bash
mkdir -p univec && cd univec
wget -O univec.fa https://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec
bowtie2-build univec.fa univec
cd ..
```

**Database files:** ~30 MB total

### Step 3: Create Configuration File

```bash
cd /path/to/fastq_screen_databases
cat > fastq_screen.conf << 'EOF'
# FastQ Screen Configuration - Quick Start Setup
# Edit paths below to match your installation directory

BOWTIE2 bowtie2
THREADS 8

DATABASE phix /path/to/fastq_screen_databases/phix/phix
DATABASE adapters /path/to/fastq_screen_databases/adapters/adapters
DATABASE ecoli /path/to/fastq_screen_databases/ecoli/ecoli
DATABASE univec /path/to/fastq_screen_databases/univec/univec
EOF
```

**⚠️ Important:** Replace `/path/to/fastq_screen_databases` with your **actual absolute path**!

### Step 4: Test Your Setup

```bash
fastq_screen --version
fastq_screen --conf fastq_screen.conf --test
```

Expected output: "TEST PASSED" for all databases.

✅ **Quick Start Complete!** You can now use FastQ Screen with the pipeline.

---

## Full Setup: All Reference Genomes

For comprehensive contamination screening across multiple organisms, build all 11 reference databases.

### Overview

The full setup provides screening against:
- **Model organisms**: Human, Mouse, Rat, Drosophila, Yeast
- **Contaminants**: Bacteria (E. coli), Mycoplasma, Viruses
- **Controls**: PhiX, Adapters, Vectors

**Total Requirements:**
- **Disk space:** ~25 GB (indices) + ~9 GB (FASTA files) = **~34 GB**
- **Build time:** ~5-6 hours (with 8 cores)
- **RAM:** 8-16 GB recommended

---

## Database Reference Table

| Database | Genome Size | Index Size | Build Time* | Key Contaminants Detected |
|----------|-------------|------------|-------------|---------------------------|
| **phix** | 5 KB | ~20 KB | <1 min | PhiX sequencing control |
| **adapters** | 1 KB | ~5 KB | <1 min | Illumina adapter dimers |
| **univec** | 10 MB | ~30 MB | ~2 min | Cloning vectors, linkers |
| **ecoli** | 4.6 MB | ~20 MB | ~2 min | E. coli (most common bacterial) |
| **mycoplasma** | 580 KB | ~3 MB | ~1 min | Mycoplasma contamination |
| **yeast** | 12 MB | ~50 MB | ~3 min | S. cerevisiae |
| **drosophila** | 143 MB | ~600 MB | ~15 min | D. melanogaster |
| **viral** | 500 MB | ~2 GB | ~30 min | Broad viral screening |
| **rat** | 2.8 GB | ~7 GB | ~90 min | R. norvegicus (rn6) |
| **mm10** | 2.7 GB | ~7 GB | ~90 min | M. musculus (mm10) |
| **hg38** | 3.1 GB | ~8 GB | ~120 min | H. sapiens (hg38) |
| **Total** | **~9.3 GB** | **~24.7 GB** | **~5-6 hours** |  |

*Build times with 8 CPU cores. Single-core builds will take 3-5x longer.

**Optional (Not Recommended):**
- **bacterial** (~50 GB FASTA, ~150 GB indices, several hours) - Comprehensive bacterial database. Only needed for specialized bacterial contamination screening.

---

## Individual Database Build Instructions

### 1. Human Genome (hg38)

```bash
cd /path/to/fastq_screen_databases
mkdir -p hg38 && cd hg38

# Download (~1 GB compressed, ~3.1 GB uncompressed)
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz

# Build index (~2 hours with 8 cores)
bowtie2-build --threads 8 hg38.fa hg38

cd ..
```

**Result:** ~8 GB index files

---

### 2. Mouse Genome (mm10)

```bash
mkdir -p mm10 && cd mm10

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz
gunzip mm10.fa.gz

# Build index (~1.5 hours with 8 cores)
bowtie2-build --threads 8 mm10.fa mm10

cd ..
```

**Result:** ~7 GB index files

---

### 3. Rat Genome (rn6)

```bash
mkdir -p rat && cd rat

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/rn6/bigZips/rn6.fa.gz
gunzip rn6.fa.gz

# Build index (~1.5 hours with 8 cores)
bowtie2-build --threads 8 rn6.fa rn6

cd ..
```

**Result:** ~7 GB index files

---

### 4. Drosophila Genome (dm6)

```bash
mkdir -p drosophila && cd drosophila

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/dm6/bigZips/dm6.fa.gz
gunzip dm6.fa.gz

# Build index (~10 minutes with 8 cores)
bowtie2-build --threads 8 dm6.fa drosophila

cd ..
```

**Result:** ~600 MB index files

---

### 5. Yeast Genome (S. cerevisiae)

```bash
mkdir -p yeast && cd yeast

# Download
wget https://hgdownload.soe.ucsc.edu/goldenPath/sacCer3/bigZips/sacCer3.fa.gz
gunzip sacCer3.fa.gz

# Build index (~1 minute)
bowtie2-build sacCer3.fa yeast

cd ..
```

**Result:** ~50 MB index files

---

### 6. E. coli (K-12 MG1655)

```bash
mkdir -p ecoli && cd ecoli

# Download
wget -O ecoli.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
gunzip ecoli.fa.gz

# Build index (~2 minutes)
bowtie2-build ecoli.fa ecoli

cd ..
```

**Result:** ~20 MB index files

---

### 7. Mycoplasma

```bash
mkdir -p mycoplasma && cd mycoplasma

# Download common mycoplasma species
wget "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/325/GCF_000027325.1_ASM2732v1/GCF_000027325.1_ASM2732v1_genomic.fna.gz"
gunzip -c GCF_000027325.1_ASM2732v1_genomic.fna.gz > mycoplasma.fa

# Build index (<1 minute)
bowtie2-build mycoplasma.fa mycoplasma

cd ..
```

**Result:** ~3 MB index files

---

### 8. Viral Database (RefSeq)

```bash
mkdir -p viral && cd viral

# Download viral RefSeq (updated regularly)
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.1.1.genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.2.1.genomic.fna.gz

# Concatenate all viral sequences
gunzip -c viral.*.genomic.fna.gz > viral_all.fa

# Build index (~30 minutes with 8 cores)
bowtie2-build --threads 8 viral_all.fa viral

# Clean up downloaded files
rm viral.*.genomic.fna.gz

cd ..
```

**Result:** ~2 GB index files

---

### 9. PhiX Control

See [Quick Start](#2-build-core-databases) above.

---

### 10. Illumina Adapters

See [Quick Start](#2-build-core-databases) above.

---

### 11. UniVec

See [Quick Start](#2-build-core-databases) above.

---

## Configuration File Setup

### Full Configuration File

After building all databases, create a comprehensive configuration file:

```bash
cd /path/to/fastq_screen_databases

cat > fastq_screen_full.conf << 'EOF'
#==========================================================
# FastQ Screen Configuration - Full Setup
# Update all paths to match your installation directory
#==========================================================

# Bowtie2 settings
BOWTIE2 bowtie2
THREADS 8

#----------------------------------------------------------
# Control & Technical Contaminants
#----------------------------------------------------------
DATABASE phix /path/to/fastq_screen_databases/phix/phix
DATABASE adapters /path/to/fastq_screen_databases/adapters/adapters
DATABASE univec /path/to/fastq_screen_databases/univec/univec

#----------------------------------------------------------
# Model Organisms
#----------------------------------------------------------
DATABASE hg38 /path/to/fastq_screen_databases/hg38/hg38
DATABASE mm10 /path/to/fastq_screen_databases/mm10/mm10
DATABASE rat /path/to/fastq_screen_databases/rat/rn6
DATABASE drosophila /path/to/fastq_screen_databases/drosophila/drosophila
DATABASE yeast /path/to/fastq_screen_databases/yeast/yeast

#----------------------------------------------------------
# Contaminants
#----------------------------------------------------------
DATABASE ecoli /path/to/fastq_screen_databases/ecoli/ecoli
DATABASE mycoplasma /path/to/fastq_screen_databases/mycoplasma/mycoplasma
DATABASE viral /path/to/fastq_screen_databases/viral/viral
EOF
```

**⚠️ Critical:** Replace **every instance** of `/path/to/fastq_screen_databases` with your actual absolute path!

### Alternative: Subset Configurations

You can create multiple configurations for different use cases:

**Minimal (Quick QC):**
```bash
# fastq_screen_minimal.conf
DATABASE phix /path/to/fastq_screen_databases/phix/phix
DATABASE adapters /path/to/fastq_screen_databases/adapters/adapters
DATABASE ecoli /path/to/fastq_screen_databases/ecoli/ecoli
```

**Mammalian Focus:**
```bash
# fastq_screen_mammal.conf
DATABASE hg38 /path/to/fastq_screen_databases/hg38/hg38
DATABASE mm10 /path/to/fastq_screen_databases/mm10/mm10
DATABASE rat /path/to/fastq_screen_databases/rat/rn6
DATABASE ecoli /path/to/fastq_screen_databases/ecoli/ecoli
DATABASE adapters /path/to/fastq_screen_databases/adapters/adapters
```

---

## Testing Your Setup

### 1. Verify Bowtie2 Installation

```bash
bowtie2 --version
# Should output: bowtie2-align-s version 2.x.x
```

### 2. Verify Database Files

Check that index files were created:

```bash
cd /path/to/fastq_screen_databases
ls -lh phix/*.bt2
# Should show: phix.1.bt2, phix.2.bt2, phix.3.bt2, phix.4.bt2, phix.rev.1.bt2, phix.rev.2.bt2
```

### 3. Test FastQ Screen Configuration

```bash
fastq_screen --conf fastq_screen.conf --test
```

**Expected output:**
```
Testing database: phix... PASSED
Testing database: adapters... PASSED
Testing database: ecoli... PASSED
Testing database: univec... PASSED
All tests passed!
```

### 4. Run Test with Sample Data

If you have sample FASTQ files:

```bash
fastq_screen --conf fastq_screen.conf --subset 100000 sample_R1.fastq.gz
```

This screens the first 100,000 reads against all databases.

---

## Using With the Pipeline

Once databases are set up, enable contamination screening in the pipeline:

### Method 1: Command Line

```bash
nextflow run main.nf \
  --input runs.csv \
  --fastq_screen_config /path/to/fastq_screen_databases/fastq_screen.conf \
  -profile docker
```

### Method 2: Configuration File

Add to `nextflow.config`:

```groovy
params {
  fastq_screen_config = '/path/to/fastq_screen_databases/fastq_screen.conf'
}
```

Then run:

```bash
nextflow run main.nf --input runs.csv -profile docker
```

### Method 3: Custom Configuration

Create a custom config file:

```groovy
// custom.config
params {
  fastq_screen_config = '/path/to/fastq_screen_databases/fastq_screen.conf'
  fastq_screen_subset = 100000  // Screen first 100k reads per file
}
```

Run with:

```bash
nextflow run main.nf --input runs.csv -c custom.config -profile docker
```

---

## Troubleshooting

### Issue: "bowtie2-build: command not found"

**Solution:** Install Bowtie2:

```bash
# Conda
conda install -c bioconda bowtie2

# Ubuntu/Debian
sudo apt-get install bowtie2

# macOS
brew install bowtie2
```

---

### Issue: "Cannot open index file"

**Symptoms:** FastQ Screen reports it cannot find index files.

**Solution:** Verify paths in configuration file are **absolute paths**, not relative:

```bash
# ❌ WRONG (relative path)
DATABASE phix databases/phix/phix

# ✅ CORRECT (absolute path)
DATABASE phix /home/user/fastq_screen_databases/phix/phix
```

---

### Issue: Build process killed / Out of memory

**Symptoms:** `bowtie2-build` process terminates unexpectedly during large genome indexing.

**Solution:** Reduce parallel threads or use a machine with more RAM:

```bash
# Use fewer threads (reduces memory usage)
bowtie2-build --threads 4 hg38.fa hg38

# Or use large-index option for very large genomes
bowtie2-build --large-index --threads 8 hg38.fa hg38
```

---

### Issue: Download interrupted / corrupt files

**Symptoms:** `gunzip` or `bowtie2-build` fails with errors.

**Solution:** Re-download the file and verify integrity:

```bash
# Remove corrupt file
rm hg38.fa.gz

# Re-download
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz

# Verify file integrity (check file size)
ls -lh hg38.fa.gz
```

---

### Issue: TEST FAILED for databases

**Symptoms:** `fastq_screen --test` reports failures.

**Solution:** Check that:
1. Database paths in config file are correct
2. All `.bt2` index files exist
3. Bowtie2 version is compatible (v2.3.0+)

```bash
# Verify index files exist
ls /path/to/fastq_screen_databases/phix/*.bt2

# Test bowtie2 directly
bowtie2 -x /path/to/fastq_screen_databases/phix/phix --version
```

---

### Issue: Slow screening performance

**Symptoms:** FastQ Screen takes very long to complete.

**Solution:** Increase threads or use subset option:

```bash
# In fastq_screen.conf, increase THREADS
THREADS 16

# Or use subset option (screen fewer reads)
fastq_screen --subset 100000 sample.fastq.gz
```

---

## Maintenance & Updates

### Updating Viral Database

Viral RefSeq is updated regularly. To update:

```bash
cd /path/to/fastq_screen_databases/viral

# Backup old database
mv viral_all.fa viral_all.fa.backup
rm viral.*.bt2

# Download latest
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.1.1.genomic.fna.gz
wget https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.2.1.genomic.fna.gz

# Rebuild
gunzip -c viral.*.genomic.fna.gz > viral_all.fa
bowtie2-build --threads 8 viral_all.fa viral
rm viral.*.genomic.fna.gz
```

### Updating Genome Assemblies

Check for new genome releases:

- **Human:** https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/
- **Mouse:** https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/
- **Rat:** https://hgdownload.soe.ucsc.edu/goldenPath/rn6/bigZips/

---

## References

### Official Documentation

- [FastQ Screen Documentation](https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/)
- [Bowtie2 Manual](http://bowtie-bio.sourceforge.net/bowtie2/manual.shtml)

### Genome Sources

- [UCSC Genome Browser](https://hgdownload.soe.ucsc.edu/downloads.html)
- [NCBI Reference Sequences](https://ftp.ncbi.nlm.nih.gov/genomes/)
- [NCBI RefSeq Viral](https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/)
- [UniVec Database](https://ftp.ncbi.nlm.nih.gov/pub/UniVec/)

### Citation

> Wingett SW and Andrews S. (2018). FastQ Screen: A tool for multi-genome mapping and quality control. *F1000Research*, 7:1338. doi: [10.12688/f1000research.15931.2](https://doi.org/10.12688/f1000research.15931.2)

---

📘 **[← Back to Main README](../README.md)**

