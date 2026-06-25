#!/bin/bash
set -euo pipefail

# Usage: bash scripts/run_fastqc.sh <input_fastq_directory> [threads]
#
# This script runs FastQC on FASTQ files in a given directory.
# It generates quality control reports for each FASTQ file.
#
# Output:
#   - HTML and .zip FastQC reports are saved in:
#     <input_fastq_directory>/fastqc_reports/
#
# This step can be applied to both raw and processed FASTQ files.

# Check arguments
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <input_fastq_directory> [threads]"
    exit 1
fi

# Load conda 
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
