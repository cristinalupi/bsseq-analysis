#!/bin/bash
set -e

# Check input argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_fastq_directory>"
    exit 1
fi

INPUT_DIR=$1
OUTPUT_DIR="${INPUT_DIR}/fastqc_reports"

mkdir -p $OUTPUT_DIR

fastqc ${INPUT_DIR}/*.fastq.gz -o $OUTPUT_DIR -t 8
