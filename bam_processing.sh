#!/bin/bash
set -euo pipefail

# Usage: bash scripts/bam_processing.sh [threads]
#
# This script processes Bismark BAM files by:
#   - sorting alignments
#   - removing duplicate reads
#   - filtering low-quality and unwanted reads
#   - generating final sorted and indexed BAM files
#
# Input:
#   methylation_output/bismark_alignment/
#
# Output:
#   methylation_output/deduplicated/
#
# Intermediate files are removed after successful processing.

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

# Increase file descriptor limit for sambamba
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
    FINAL="${OUT_DIR}/${BASE}.bam"

    echo "Processing $BASE"

    # 1. Sort
    [ ! -f "$SORTED" ] && \
        sambamba sort -t "$THREADS" -o "$SORTED" "$BAM"

    # 2. Deduplicate
    [ ! -f "$DEDUP" ] && \
        sambamba markdup -r -t "$THREADS" "$SORTED" "$DEDUP"

    # 3. Filter reads
    #   - remove unmapped reads        (-F 4)
    #   - remove secondary alignments (-F 256)
    #   - remove supplementary reads  (-F 2048)
    #   - keep reads with MAPQ >= 20
    [ ! -f "$FILTERED" ] && \
        samtools view -b -F 2308 -q 20 "$DEDUP" > "$FILTERED"

    # 4. Final sort + index
    if [ ! -f "$FINAL" ]; then
        sambamba sort -t "$THREADS" -o "$FINAL" "$FILTERED"
        sambamba index "$FINAL"
    fi

    # Cleanup
    if [ -f "$FINAL" ]; then
        rm -f "$SORTED" "$DEDUP" "$FILTERED"
    fi

done

