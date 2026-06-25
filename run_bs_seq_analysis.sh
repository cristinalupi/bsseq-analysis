#!/bin/bash
set -euo pipefail

# Usage: bash run_pipeline.sh <input_fastq_directory> <genome.fa> <library_type> [threads]

# This script runs the complete WGBS pipeline in sequential steps:
#   1. Setup environment (only required once)
#   2. Genome preparation (adds lambda and builds Bismark index)
#   3. FASTQ trimming (fastp + FastQC)
#   4. FASTQ processing for Bismark (library-specific trimming)
#   5. Bismark alignment
#   6. BAM processing (sorting, deduplication, filtering)
#   7. Methylation extraction and downstream analysis
#
# Input:
#   - Raw FASTQ directory
#   - Reference genome (FASTA)
#   - Library type (BS-Seq, RRBS, PBAT, etc.)
#
# Output:
#   - methylation_output/ (all downstream results)

# Check arguments
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 <input_fastq_directory> <genome.fa> <library_type> [threads]"
    exit 1
fi

INPUT_DIR="$1"
GENOME="$2"
LIB_TYPE="$3"
THREADS="${4:-16}"


# Step 1: Setup environment
echo "[1/7] Setup environment"
bash scripts/setup_environment.sh


# Step 2: Genome preparation
echo "[2/7] Genome preparation"
bash scripts/genome_preparation.sh "$GENOME"


# Step 3: FASTQ trimming
echo "[3/7] FASTQ trimming"
bash scripts/fastq_trimming.sh "$INPUT_DIR" "$THREADS"


# Step 4: Bismark FASTQ preparation
echo "[4/7] Bismark FASTQ preparation"
bash scripts/bismark_fastq_prep.sh "$INPUT_DIR" "$LIB_TYPE" "$THREADS"


# Step 5: Bismark alignment
echo "[5/7] Bismark alignment"
bash scripts/bismark_alignment.sh "$INPUT_DIR" "$LIB_TYPE" "$THREADS"


# Step 6: BAM processing
echo "[6/7] BAM processing"
bash scripts/bam_processing.sh "$THREADS"


# Step 7: Methylation analysis
echo "[7/7] Methylation analysis"
bash scripts/methylation_analysis.sh "$THREADS"

echo "Pipeline completed successfully."
