#!/bin/bash
set -euo pipefail

# Usage: bash scripts/bismark_alignment.sh <input_fastq_directory> <library_type> [threads]
#
# This script performs alignment of bisulfite-treated reads using Bismark.
#
# Behaviour:
#   - Reads FASTQ files from: <input_fastq_directory>/bismark_input_fastq/
#   - Automatically detects the Bismark genome index in input_genome_directory/
#   - Applies library-specific mapping parameters
#   - Outputs BAM files and reports to: methylation_output/bismark_alignment/
#
# Supported library types:
#   BS-Seq, RRBS, PBAT, scBS-Seq, TruSeq, Accel-NGS, Zymo, EM-seq

# Check arguments
if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
    echo "Usage: $0 <input_fastq_directory> <library_type> [threads]"
    exit 1
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

INPUT_DIR="$1"
LIBRARY_TYPE="$2"
THREADS="${3:-16}"

# Paths
FASTQ_DIR="${INPUT_DIR}/bismark_input_fastq"
OUTDIR="methylation_output/bismark_alignment"
GENOME_BASE_DIR="input_genome_directory"

# Detect genome index
GENOME_DIR=$(find "$GENOME_BASE_DIR" -maxdepth 1 -type d -name "bismark_index_*_lambda")

# Check it exists and is unique
if [ -z "$GENOME_DIR" ]; then
    echo "No Bismark index found in $GENOME_BASE_DIR"
    exit 1
fi

if [ "$(echo "$GENOME_DIR" | wc -l)" -gt 1 ]; then
    echo "Multiple Bismark indexes found. Please keep only one."
    exit 1
fi

# Create output directory
mkdir -p "$OUTDIR"

# Initialize Bismark parameters
BISMARK_FLAGS="--bowtie2 --local -X 2000"

case "$LIBRARY_TYPE" in

    BS-Seq)
        ;;
        
    RRBS)
        BISMARK_FLAGS="$BISMARK_FLAGS --non_directional"
        ;;
        
    PBAT)
        BISMARK_FLAGS="$BISMARK_FLAGS --pbat"
        ;;
        
    scBS-Seq)
        BISMARK_FLAGS="$BISMARK_FLAGS --non_directional"
        ;;
        
    Zymo)
        BISMARK_FLAGS="$BISMARK_FLAGS --non_directional"
        ;;
        
    TruSeq|Accel-NGS|EM-seq)
        ;;
        
    *)
        echo "Unknown library type: $LIBRARY_TYPE"
        exit 1
        ;;

esac

# Loop through paired FASTQ files
shopt -s nullglob

for R1 in "$FASTQ_DIR"/*_R1.fastq.gz; do

    base=$(basename "$R1" "_R1.fastq.gz")
    R2="${FASTQ_DIR}/${base}_R2.fastq.gz"

    [ -f "$R2" ] || { echo "Missing pair for $R1"; exit 1; }

    bismark \
        --genome "$GENOME_DIR" \
        -1 "$R1" -2 "$R2" \
        --output_dir "$OUTDIR" \
        --parallel "$THREADS" \
        $BISMARK_FLAGS

    # Rename BAM for cleaner naming
    if [ -f "$OUTDIR/${base}_1_bismark_bt2.bam" ]; then
        mv "$OUTDIR/${base}_1_bismark_bt2.bam" \
           "$OUTDIR/${base}_bismark_bt2.bam"
    fi

done

