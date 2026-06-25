#!/bin/bash
set -euo pipefail

# Usage: bash scripts/genome_preparation.sh <path/to/genome.fa|genome.fasta>
#
# This script prepares a reference genome for bisulfite analysis by:
#   - generating chrom.sizes for the original genome
#   - downloading and adding lambda phage sequence as a new chromosome
#   - generating chrom.sizes for lambda
#   - creating a combined genome (genome + lambda)
#   - building a Bismark index
#
# Outputs are generated in the same directory as the input genome.
#
# This step only needs to be executed once per genome.

# Check arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path/to/genome.fa|genome.fasta>"
    exit 1
fi

# Load conda
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate bsseq

GENOME_PATH="$1"

# Extract directory and filename
DIR=$(dirname "$GENOME_PATH")
GENOME_FILE=$(basename "$GENOME_PATH")

# Extract genome name (remove .fa or .fasta)
GENOME_NAME="${GENOME_FILE%.fa}"
GENOME_NAME="${GENOME_NAME%.fasta}"

# Paths
LAMBDA="$DIR/lambda.fa"
OUTPUT="$DIR/${GENOME_NAME}_lambda.fa"
BISMARK_DIR="$DIR/bismark_index_${GENOME_NAME}_lambda"

# Check genome exists
[ -f "$GENOME_PATH" ] || { echo "Genome file not found: $GENOME_PATH"; exit 1; }

# Generate chrom.sizes for original genome
samtools faidx "$GENOME_PATH"
cut -f1,2 "${GENOME_PATH}.fai" > "$DIR/${GENOME_NAME}.chrom.sizes"

# Download lambda phage sequence
wget -q -O "$LAMBDA" "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=nuccore&id=J02459.1&rettype=fasta&retmode=text"

# Generate chrom.sizes for lambda
samtools faidx "$LAMBDA"
cut -f1,2 "${LAMBDA}.fai" > "$DIR/lambda.chrom.sizes"

# Append lambda as a new chromosome
sed '1s/.*/>lambda/' "$LAMBDA" | cat "$GENOME_PATH" - > "$OUTPUT"

# Remove temporary file
rm "$LAMBDA"

echo "Genome with lambda added saved to: $OUTPUT"

# Create directory for Bismark index
mkdir -p "$BISMARK_DIR"

# Link genome into index directory (Bismark requirement)
ln -sf "$OUTPUT" "$BISMARK_DIR"

# Build Bismark index
bismark_genome_preparation "$BISMARK_DIR"
