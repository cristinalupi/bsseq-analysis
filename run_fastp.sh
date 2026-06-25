#!/bin/bash
set -e

# Usage: bash scripts/fastq_trimming.sh <input_fastq_directory> [threads]
#
# This script performs adapter trimming and quality filtering using fastp.
# It processes paired-end FASTQ files and outputs trimmed reads.
# FastQC is run on the trimmed reads using an existing script.

# Check arguments
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: $0 <input_fastq_directory> [threads]"
    exit 1
fi

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

INPUT_DIR="$1"
THREADS="${2:-8}"

OUTPUT_DIR="trimmed_fastq"

mkdir -p "$OUTPUT_DIR"

for R1 in "${INPUT_DIR}"/*_R1.fastq.gz
do
    R2="${R1/_R1.fastq.gz/_R2.fastq.gz}"
    SAMPLE=$(basename "$R1" _R1.fastq.gz)

    fastp \
        -i "$R1" -I "$R2" \
        -o "${OUTPUT_DIR}/${SAMPLE}_R1.trimmed.fastq.gz" \
        -O "${OUTPUT_DIR}/${SAMPLE}_R2.trimmed.fastq.gz" \
        --detect_adapter_for_pe \
        --cut_front --cut_front_window_size 5 --cut_front_mean_quality 20 \
        --cut_tail --cut_tail_window_size 5 --cut_tail_mean_quality 20 \
        --trim_poly_g \
        --trim_poly_x \
        --length_required 25 \
        --thread "$THREADS" \
        --html "${OUTPUT_DIR}/${SAMPLE}_fastp.html"
done

# Run FastQC on trimmed reads
bash scripts/run_fastqc.sh "$OUTPUT_DIR"
