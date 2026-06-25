#!/bin/bash
set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input_fastq_directory> [threads]"
    exit 1
fi

INPUT_DIR=$1
THREADS=${2:-4}

OUTPUT_DIR="${INPUT_DIR}/fastqc_reports"

mkdir -p $OUTPUT_DIR

fastqc ${INPUT_DIR}/*.fastq.gz -o $OUTPUT_DIR -t $THREADS

