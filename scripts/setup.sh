#!/bin/bash
set -e

# Usage: bash scripts/setup_environment.sh

# This script installs Miniconda (if not present) and creates
# the bsseq conda environment required for the pipeline.
# This step only needs to be executed once per system.

# This script is intended for Linux systems only.
# Tested on Ubuntu-based environments.
# It installs Miniconda locally in $HOME and creates the bsseq environment.

# Check if conda is installed
if ! command -v conda &> /dev/null
then
    # Download and install Miniconda
    curl -L -o miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash miniconda.sh -b -p $HOME/miniconda
    # Add Conda to PATH for current session
    export PATH="$HOME/miniconda/bin:$PATH"
    rm miniconda.sh
fi

# Initialize conda for shell usage
source "$(conda info --base)/etc/profile.d/conda.sh"

# Create environment with required tools
if ! conda env list | grep -q "^bsseq "
then
    conda create -n bsseq -y \
    -c conda-forge \
    -c bioconda \
    python=3.10.20 \
    fastp=1.3.5 \
    bismark=0.25.1 \
    bowtie2=2.5.5 \
    samtools=1.23.1 \
    sambamba=1.0.1 \
    methyldackel=0.6.1 \
    bedtools=2.31.1 \
    ucsc-bedgraphtobigwig=482
fi
conda activate bsseq

