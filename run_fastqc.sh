#!/bin/bash
set -euo pipefail

# Usage: bash scripts/fastqc.sh <input_fastq_directory> [threads]
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

INPUT_DIR="$1"
THREADS="${2:-4}"

# Paths
OUTPUT_DIR="${INPUT_DIR}/fastqc_reports"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run FastQC
fastqc "${INPUT_DIR}"/*.fastq.gz -o "$OUTPUT_DIR" -t "$THREADS"
