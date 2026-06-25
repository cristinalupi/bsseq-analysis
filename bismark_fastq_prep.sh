#!/bin/bash
set -euo pipefail

# Usage: bash scripts/bismark_fastq_prep.sh <input_fastq_directory> <library_type> [threads]

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

INPUT_DIR="$1"
LIBRARY_TYPE="$2"
THREADS="${3:-4}"

# Paths
TRIMMED_DIR="${INPUT_DIR}/trimmed_fastq"
OUTPUT_DIR="${INPUT_DIR}/bismark_input_fastq"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize trimming parameters
TRIM_FRONT_R1=0
TRIM_FRONT_R2=0
TRIM_TAIL_R1=0
TRIM_TAIL_R2=0

case "$LIBRARY_TYPE" in

    BS-Seq)
        ;;
        
    RRBS)
        TRIM_FRONT_R1=2
        TRIM_FRONT_R2=2
        ;;
        
    PBAT)
        TRIM_FRONT_R1=6
        TRIM_FRONT_R2=6
        TRIM_TAIL_R1=6
        TRIM_TAIL_R2=6
        ;;
        
    scBS-Seq)
        TRIM_FRONT_R1=6
        TRIM_TAIL_R1=6
        ;;
        
    TruSeq)
        TRIM_FRONT_R1=8
        TRIM_FRONT_R2=8
        TRIM_TAIL_R1=8
        TRIM_TAIL_R2=8
        ;;
        
    Accel-NGS)
        TRIM_FRONT_R1=10
        TRIM_FRONT_R2=15
        TRIM_TAIL_R1=10
        TRIM_TAIL_R2=10
        ;;
        
    Zymo)
        TRIM_FRONT_R1=10
        TRIM_FRONT_R2=10
        TRIM_TAIL_R1=10
        TRIM_TAIL_R2=10
        ;;
        
    EM-seq)
        TRIM_FRONT_R1=10
        TRIM_FRONT_R2=10
        TRIM_TAIL_R1=10
        TRIM_TAIL_R2=10
        ;;
        
    *)
        echo "Unknown library type: $LIBRARY_TYPE"
        exit 1
        ;;

esac

# Loop through paired FASTQ files
for R1 in "$TRIMMED_DIR"/*_R1.trimmed.fastq.gz; do

    base=$(basename "$R1" "_R1.trimmed.fastq.gz")
    R2="${TRIMMED_DIR}/${base}_R2.trimmed.fastq.gz"

    OUT_R1="${OUTPUT_DIR}/${base}_R1.fastq.gz"
    OUT_R2="${OUTPUT_DIR}/${base}_R2.fastq.gz"

    # BS-Seq: no hard trimming (create symbolic links)
    if [ "$LIBRARY_TYPE" = "BS-Seq" ]; then
        ln -sf "$R1" "$OUT_R1"
        ln -sf "$R2" "$OUT_R2"
        continue
    fi

    fastp \
        -i "$R1" -I "$R2" \
        -o "$OUT_R1" -O "$OUT_R2" \
        --trim_front1 "$TRIM_FRONT_R1" \
        --trim_front2 "$TRIM_FRONT_R2" \
        --trim_tail1 "$TRIM_TAIL_R1" \
        --trim_tail2 "$TRIM_TAIL_R2" \
        --thread "$THREADS"

done
``
