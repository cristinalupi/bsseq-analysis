#!/bin/bash
set -e

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
        python=3.10 \
        fastp \
        bismark \
        bowtie2 \
        samtools \
        sambamba \
        methyldackel \
        bedtools \
        ucsc-bedgraphtobigwig \
        r-base=4.2
fi
conda activate bsseq

