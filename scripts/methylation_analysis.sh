#!/bin/bash
set -euo pipefail

# Usage: bash scripts/methylation_analysis.sh [threads]
#
# This script performs methylation extraction and downstream processing
# from deduplicated BAM files obtained after Bismark alignment.
#
# Workflow:
#   1. Runs MethylDackel mbias to detect positional biases
#   2. Extracts methylation data (CpG context)
#   3. Computes lambda methylation percentage (conversion efficiency)
#   4. Filters BEDGRAPH files (removes merged entries only)
#   5. Generates DSS input files for differential methylation analysis
#   6. Produces BigWig files for genome browser visualization
#
# Input:
#   methylation_output/deduplicated/*.bam
#
# Requirements:
#   - Genome with lambda spike-in (generated in genome_preparation.sh)
#   - Corresponding *_lambda.chrom.sizes file
#
# Output directories:
#   methylation_output/
#     ├── mbias/          (M-bias reports)
#     ├── methylation/    (MethylDackel output BEDGRAPH)
#     ├── DSS/            (input files for DSS)
#     ├── lambda_stats/   (conversion efficiency statistics)
#     └── bigwig/         (BigWig tracks for visualization)
#
# Notes:
#   - Lambda is retained in the methylation data for QC purposes
#   - Only 'merged' entries are filtered out prior to DSS analysis
#   - Script is idempotent (safe to re-run)
#   - Parallel execution is implemented with MAX_JOBS
#
# This step is part of the WGBS pipeline and assumes previous steps
# (alignment and BAM processing) have been completed.

# Load conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

THREADS="${1:-16}"

# Paths
ALIGN_DIR="methylation_output/deduplicated"
WORK_DIR="methylation_output"


genome_files=(input_genome_directory/*_lambda.fa)

if [ ${#genome_files[@]} -eq 0 ]; then
    echo "No genome file found (*_lambda.fa) in input_genome_directory"
    exit 1
elif [ ${#genome_files[@]} -gt 1 ]; then
    echo "Multiple genome files found (*_lambda.fa). Please keep only one."
    exit 1
fi

GENOME="${genome_files[0]}"

chrom_files=(input_genome_directory/*_lambda.chrom.sizes)

if [ ${#chrom_files[@]} -eq 0 ]; then
    echo "No chrom.sizes file found (*_lambda.chrom.sizes)"
    exit 1
elif [ ${#chrom_files[@]} -gt 1 ]; then
    echo "Multiple chrom.sizes files found (*_lambda.chrom.sizes). Please keep only one."
    exit 1
fi

CHROM_SIZES="${chrom_files[0]}"


MBIAS_DIR="${WORK_DIR}/mbias"
MET_DIR="${WORK_DIR}/methylation"
DSS_DIR="${WORK_DIR}/DSS"
LAMBDA_STATS_DIR="${WORK_DIR}/lambda_stats"
BIGWIG_DIR="${WORK_DIR}/bigwig"

mkdir -p "$MBIAS_DIR" "$MET_DIR" "$DSS_DIR" "$LAMBDA_STATS_DIR" "$BIGWIG_DIR"

MAX_JOBS=5


# Functions
generate_mbias() {
    local bam=$1
    local prefix=$2
    local log="${prefix}_mbias.txt"

    options=$(MethylDackel mbias -@ "$THREADS" "$GENOME" "$bam" "$prefix" 2>&1 | tee "$log" | \
              grep "Suggested inclusion options:" | sed 's/Suggested inclusion options: //')

    echo "$options"
}


extract_methylation() {
    local bam=$1
    local prefix=$2
    local mbias_params=$3

    MethylDackel extract \
        "$GENOME" \
        "$bam" \
        --minOppositeDepth 10 \
        --maxVariantFrac 0.5 \
        $mbias_params \
        --mergeContext \
        -p "$THREADS" \
        -o "$prefix"
}


lambda_stats() {
    local bedgraph=$1
    local sample=$2

    awk -v sample="$sample" '
    $1=="lambda"{meth+=$5; unmeth+=$6}
    END{
        total=meth+unmeth
        if(total>0){
            print "sample\tlambda_methylation_percent"
            print sample "\t" meth/total*100
        }
    }' "$bedgraph" > "${LAMBDA_STATS_DIR}/${sample}_lambda_stats.txt"
}


filter_bedgraph() {
    local bedgraph=$1
    local output_prefix=$2
    local filtered="${output_prefix}_filtered.bedGraph"

    awk '$0 !~ /merged/' "$bedgraph" > "$filtered"

    echo "$filtered"
}

generate_dss() {
    local filtered=$1
    local sample=$2

    awk -v sample="$sample" 'BEGIN{OFS="\t"; print "chr","pos","N","X"}
    {
        chr=$1
        pos=int(($2+$3)/2)
        N=$5+$6
        X=$6
        print chr,pos,N,X
    }' "$filtered" > "${DSS_DIR}/${sample}.DSS.txt"
}

generate_bigwig() {
    local bedgraph=$1
    local sample=$2

    clean="${bedgraph}.clean"
    sorted="${clean}.sorted"

    awk 'BEGIN{OFS="\t"} {print $1,$2,$3,$4}' "$bedgraph" > "$clean"
    sort -k1,1 -k2,2n "$clean" > "$sorted"

    bedGraphToBigWig "$sorted" "$CHROM_SIZES" "${BIGWIG_DIR}/${sample}.bw"

    rm "$clean" "$sorted"
}


# Main loop
shopt -s nullglob

for BAM in "$ALIGN_DIR"/*.bam; do
    (
        BASE=$(basename "$BAM" .bam)
        SAMPLE="$BASE"
        
        MBIAS_PREFIX="${MBIAS_DIR}/${SAMPLE}"
        MET_PREFIX="${MET_DIR}/${SAMPLE}"
        BEDGRAPH="${MET_PREFIX}_CpG.bedGraph"
        FILTERED="${MET_PREFIX}_filtered.bedGraph"

        if [ ! -f "${MBIAS_PREFIX}_mbias.txt" ]; then
            generate_mbias "$BAM" "$MBIAS_PREFIX"
        fi

        if [ -f "${MBIAS_PREFIX}_mbias.txt" ]; then

            MBIAS_PARAMS=$(grep "Suggested inclusion options:" "${MBIAS_PREFIX}_mbias.txt" | \
                           sed 's/Suggested inclusion options: //')

            [ ! -f "$BEDGRAPH" ] && extract_methylation "$BAM" "$MET_PREFIX" "$MBIAS_PARAMS"

            [ ! -f "${LAMBDA_STATS_DIR}/${SAMPLE}_lambda_stats.txt" ] && \
                lambda_stats "$BEDGRAPH" "$SAMPLE"

            # Generate filtered BEDGRAPH only if needed
            [ ! -s "$FILTERED" ] && FILTERED=$(filter_bedgraph "$BEDGRAPH" "$MET_PREFIX")

            [ ! -f "${DSS_DIR}/${SAMPLE}.DSS.txt" ] && \
                generate_dss "$FILTERED" "$SAMPLE"

            # BigWig from full data
            [ ! -f "${BIGWIG_DIR}/${SAMPLE}.bw" ] && \
                generate_bigwig "$BEDGRAPH" "$SAMPLE"
        fi

    ) &

    while [ $(jobs -rp | wc -l) -ge $MAX_JOBS ]; do
        sleep 2
    done

done

wait
