#!/bin/bash
set -euo pipefail

# Usage: bash scripts/bam_processing.sh [threads]

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq
ulimit -n 8192

THREADS="${1:-16}"

# Paths
ALIGN_DIR="methylation_output/bismark_alignment"
OUT_DIR="methylation_output/deduplicated"

mkdir -p "$OUT_DIR"

# Main loop
shopt -s nullglob

for BAM in "$ALIGN_DIR"/*_bismark_bt2.bam; do

    BASE=$(basename "$BAM" _bismark_bt2.bam)

    SORTED="${OUT_DIR}/${BASE}_sorted.bam"
    DEDUP="${OUT_DIR}/${BASE}_dedup.bam"
    FILTERED="${OUT_DIR}/${BASE}_q20.bam"

    echo "Processing $BASE"


    # 1. Sort

    [ ! -f "$SORTED" ] && \
        sambamba sort -t "$THREADS" -o "$SORTED" "$BAM"

    # 2. Deduplicate

    [ ! -f "$DEDUP" ] && \
        sambamba markdup -r -t "$THREADS" "$SORTED" "$DEDUP"

    # 3. Filter reads
    #   - remove unmapped reads
    #   - remove secondary alignments
    #   - remove supplementary alignments (chimeric)
    #   - keep only properly mapped reads with mapping quality >= 20

    [ ! -f "$FILTERED" ] && \
        samtools view -b -F 2308 -q 20 "$DEDUP" > "$FILTERED"


    # 4. Final sort + index

    FINAL="${OUT_DIR}/${BASE}.bam"

    if [ ! -f "$FINAL" ]; then
        sambamba sort -t "$THREADS" -o "$FINAL" "$FILTERED"
        sambamba index "$FINAL"
    fi

    # Cleanup
    if [ -f "$FINAL" ]; then
        rm -f "$SORTED" "$DEDUP" "$FILTERED"
    fi

done
