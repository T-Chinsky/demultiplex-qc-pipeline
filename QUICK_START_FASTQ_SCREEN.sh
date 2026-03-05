#!/bin/bash

################################################################################
# FastQ Screen Database Quick Setup Script
################################################################################
# This script downloads and builds the essential fastq_screen databases
# for contamination screening in the BCL Convert pipeline.
#
# Usage:
#   1. Edit DB_DIR to your desired location
#   2. Run: bash QUICK_START_FASTQ_SCREEN.sh
#   3. Wait ~30-60 minutes for essential databases
#   4. Optional: Uncomment large genomes section for full setup (5-6 hours)
#
# For detailed instructions, see FASTQ_SCREEN_SETUP.md
################################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Configuration
DB_DIR="${HOME}/fastq_screen_databases"  # Change this to your preferred location
THREADS=8  # Adjust based on your system

echo "================================================"
echo "FastQ Screen Database Setup"
echo "================================================"
echo "Installation directory: $DB_DIR"
echo "Threads: $THREADS"
echo ""

# Create base directory
mkdir -p "$DB_DIR"
cd "$DB_DIR"

################################################################################
# ESSENTIAL DATABASES (Quick Setup - ~2 GB, 30 minutes)
################################################################################

echo "Building essential databases..."

# 1. PhiX (sequencing control)
echo "[1/7] PhiX..."
mkdir -p phix && cd phix
wget -q -O phix.fa "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nucleotide&id=NC_001422.1&rettype=fasta"
bowtie2-build --threads "$THREADS" phix.fa phix
cd ..

# 2. Adapters (Illumina)
echo "[2/7] Adapters..."
mkdir -p adapters && cd adapters
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
bowtie2-build --threads "$THREADS" adapters.fa adapters
cd ..

# 3. UniVec (vector contamination)
echo "[3/7] UniVec..."
mkdir -p univec && cd univec
wget -q -O univec.fa https://ftp.ncbi.nlm.nih.gov/pub/UniVec/UniVec
bowtie2-build --threads "$THREADS" univec.fa univec
cd ..

# 4. E. coli
echo "[4/7] E. coli..."
mkdir -p ecoli && cd ecoli
wget -q -O ecoli.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
gunzip ecoli.fa.gz
bowtie2-build --threads "$THREADS" ecoli.fa ecoli
rm ecoli.fa
cd ..

# 5. Yeast
echo "[5/7] Yeast..."
mkdir -p yeast && cd yeast
wget -q -O yeast.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/146/045/GCF_000146045.2_R64/GCF_000146045.2_R64_genomic.fna.gz"
gunzip yeast.fa.gz
bowtie2-build --threads "$THREADS" yeast.fa yeast
rm yeast.fa
cd ..

# 6. Mycoplasma
echo "[6/7] Mycoplasma..."
mkdir -p mycoplasma && cd mycoplasma
wget -q -O mycoplasma.fa.gz "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/027/325/GCF_000027325.1_ASM2732v1/GCF_000027325.1_ASM2732v1_genomic.fna.gz"
gunzip mycoplasma.fa.gz
bowtie2-build --threads "$THREADS" mycoplasma.fa mycoplasma
rm mycoplasma.fa
cd ..

# 7. Viral
echo "[7/7] Viral genomes..."
mkdir -p viral && cd viral
wget -q https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.1.1.genomic.fna.gz
wget -q https://ftp.ncbi.nlm.nih.gov/refseq/release/viral/viral.2.1.genomic.fna.gz
gunzip -c viral.*.genomic.fna.gz > viral_all.fa
bowtie2-build --threads "$THREADS" viral_all.fa viral
rm viral.*.genomic.fna.gz viral_all.fa
cd ..

echo ""
echo "✅ Essential databases complete!"

################################################################################
# OPTIONAL: LARGE GENOMES (Full Setup - adds ~23 GB, 5-6 hours)
################################################################################
# Uncomment the section below to build human, mouse, rat, and drosophila genomes

: <<'OPTIONAL_LARGE_GENOMES'

echo ""
echo "================================================"
echo "Building large genome databases..."
echo "This will take several hours..."
echo "================================================"

# Human (hg38)
echo "[1/4] Human (hg38) - ~2 hours..."
mkdir -p hg38 && cd hg38
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz
bowtie2-build --threads "$THREADS" hg38.fa hg38
rm hg38.fa
cd ..

# Mouse (mm10)
echo "[2/4] Mouse (mm10) - ~1.5 hours..."
mkdir -p mm10 && cd mm10
wget https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz
gunzip mm10.fa.gz
bowtie2-build --threads "$THREADS" mm10.fa mm10
rm mm10.fa
cd ..

# Rat (rn6)
echo "[3/4] Rat (rn6) - ~1.5 hours..."
mkdir -p rat && cd rat
wget https://hgdownload.soe.ucsc.edu/goldenPath/rn6/bigZips/rn6.fa.gz
gunzip rn6.fa.gz
bowtie2-build --threads "$THREADS" rn6.fa rn6
rm rn6.fa
cd ..

# Drosophila (dm6)
echo "[4/4] Drosophila (dm6) - ~10 minutes..."
mkdir -p drosophila && cd drosophila
wget https://hgdownload.soe.ucsc.edu/goldenPath/dm6/bigZips/dm6.fa.gz
gunzip dm6.fa.gz
bowtie2-build --threads "$THREADS" dm6.fa drosophila
rm dm6.fa
cd ..

echo ""
echo "✅ Large genome databases complete!"

OPTIONAL_LARGE_GENOMES

################################################################################
# Create Configuration File
################################################################################

echo ""
echo "Creating fastq_screen.conf..."

cat > "$DB_DIR/fastq_screen.conf" << EOF
# FastQ Screen Configuration File
# Generated by QUICK_START_FASTQ_SCREEN.sh
# Location: $DB_DIR

# Essential databases (always included)
DATABASE    phix           $DB_DIR/phix/phix
DATABASE    adapters       $DB_DIR/adapters/adapters
DATABASE    univec         $DB_DIR/univec/univec
DATABASE    ecoli          $DB_DIR/ecoli/ecoli
DATABASE    yeast          $DB_DIR/yeast/yeast
DATABASE    mycoplasma     $DB_DIR/mycoplasma/mycoplasma
DATABASE    viral          $DB_DIR/viral/viral

# Large genomes (uncomment if you built them above)
# DATABASE    hg38           $DB_DIR/hg38/hg38
# DATABASE    mm10           $DB_DIR/mm10/mm10
# DATABASE    rat            $DB_DIR/rat/rn6
# DATABASE    drosophila     $DB_DIR/drosophila/drosophila
EOF

################################################################################
# Summary
################################################################################

echo ""
echo "================================================"
echo "✅ Setup Complete!"
echo "================================================"
echo ""
echo "Configuration file: $DB_DIR/fastq_screen.conf"
echo ""
echo "To use with the BCL Convert pipeline:"
echo ""
echo "  nextflow run main.nf \\"
echo "    --input runs.csv \\"
echo "    --fastq_screen_config $DB_DIR/fastq_screen.conf"
echo ""
echo "Or add to nextflow.config:"
echo ""
echo "  params {"
echo "    fastq_screen_config = '$DB_DIR/fastq_screen.conf'"
echo "  }"
echo ""
echo "To build the large genomes (hg38, mm10, rat, drosophila):"
echo "  1. Edit this script and uncomment the OPTIONAL_LARGE_GENOMES section"
echo "  2. Run the script again"
echo "  3. Uncomment the corresponding lines in fastq_screen.conf"
echo ""
echo "For more information, see FASTQ_SCREEN_SETUP.md"
echo "================================================"
