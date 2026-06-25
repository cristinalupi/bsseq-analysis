# BS-seq Methylation Analysis Pipeline

This repository provides a reproducible and modular pipeline for DNA methylation analysis using bisulfite sequencing (BS-seq) data.

The workflow processes raw sequencing reads from FASTQ files through alignment, filtering and methylation extraction, generating outputs suitable for downstream analysis and visualization.

## Setup
Clone the repository:

```bash
git clone https://github.com/your-org/bsseq-analysis.git
cd bsseq-analysis
```

Install all required dependencies:
```bash
bash scripts/setup.sh
```
Activate the environment:
```bash
conda activate bsseq
```

## Read preprocessing

### Input data

The pipeline expects raw bisulfite sequencing reads in FASTQ format.

- Files must be compressed (`.fastq.gz`)
- Paired-end reads are supported
- File naming must follow the pattern: `sample_name_R1.fastq.gz sample_name_R2.fastq.gz`
- FASTQ files must be in the same directory: `input_fastq_directory` (path to the directory containing raw FASTQ files `.fastq.gz`)


#### Input directory:
```
besseq-analysis
  └── input_fastq_directory/
  |   ├── sample1_R1.fastq.gz
  |   ├── sample1_R2.fastq.gz
  |   ├── sample2_R1.fastq.gz
  |   └── sample2_R2.fastq.gz
  └── input_genome_directory/
      └── genome.fa
```

### FastQC quality control
This pipeline uses FastQC for quality control of raw sequencing data.
More info: 
https://github.com/s-andrews/fastqc
#### Arguments
`input_fastq_directory`: path to the directory containing raw FASTQ files (`.fastq.gz`)
```bash
bash scripts/run_fastqc.sh input_fastq_directory
```

#### Output
Quality control reports are generated in: `input_fastq_directory/fastqc_reports/`

#### Output directory after FastQC:
```
besseq-analysis
  └── input_fastq_directory/
  |   ├── sample1_R1.fastq.gz
  |   ├── sample1_R2.fastq.gz
  |   ├── sample2_R1.fastq.gz
  |   └── sample2_R2.fastq.gz
  └── fastqc_reports/
  |  ├── sample1_R1_fastqc.html
  |  ├── sample1_R2_fastqc.html
  |  ├── sample2_R1_fastqc.html
  |  └── sample2_R2_fastqc.html
  └── input_genome_directory/
      └── genome.fa
```
### Trimming and adapter removal (fastp)
This step performs read trimming, adapter removal and quality filtering using `fastp`.
More info: 
https://github.com/opengene/fastp

#### Arguments
- `input_fastq_directory`: path to the directory containing raw FASTQ files (`.fastq.gz`)
- `threads` (optional): number of threads to use (default: 8)

#### Run fastp

```bash
bash scripts/run_fastp.sh input_fastq_directory
```

#### Output directory after fastp:
```
besseq-analysis
  └── input_fastq_directory/
  |   ├── sample1_R1.fastq.gz
  |   ├── sample1_R2.fastq.gz
  |   ├── sample2_R1.fastq.gz
  |   └── sample2_R2.fastq.gz
  ├── fastqc_reports/
  |  ├── sample1_R1_fastqc.html
  |  ├── sample1_R2_fastqc.html
  |  ├── sample2_R1_fastqc.html
  |  ├── sample2_R2_fastqc.html
  |  └── trimmed_fastq/
  |      ├── sample1_R1.trimmed.fastq.gz
  |      ├── sample1_R2.trimmed.fastq.gz
  |      ├── sample2_R1.trimmed.fastq.gz
  |      ├── sample2_R2.trimmed.fastq.gz
  |      ├── sample1_fastp.html
  |      ├── sample2_fastp.html
  |      └── fastqc_reports/
  |          ├── sample1_R1.trimmed_fastqc.html
  |          ├── sample1_R2.trimmed_fastqc.html
  |          ├── sample2_R1.trimmed_fastqc.html
  |          └── sample2_R2.trimmed_fastqc.html
  └── input_genome_directory/
      └── genome.fa
```

## Alignment (Bismark)
This step aligns bisulfite-treated reads to a reference genome using Bismark.
More info:
https://www.bioinformatics.babraham.ac.uk/projects/bismark/
### Genome preparation
```
bash scripts/genome_preparation.sh input_genome_directory/genome.fa
```
#### Output directory after genome_preparation.sh:
```
besseq-analysis
├── input_fastq_directory/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   ├── sample2_R1.fastq.gz
│   ├── sample2_R2.fastq.gz
│   ├── fastqc_reports/
│   |  ├── sample1_R1_fastqc.html
│   |  ├── sample1_R2_fastqc.html
│   |  ├── sample2_R1_fastqc.html
│   |  └── sample2_R2_fastqc.html
│   └── trimmed_fastq/
│       ├── sample1_R1.trimmed.fastq.gz
│       ├── sample1_R2.trimmed.fastq.gz
│       ├── sample2_R1.trimmed.fastq.gz
│       ├── sample2_R2.trimmed.fastq.gz
│       ├── sample1_fastp.html
│       ├── sample2_fastp.html
│       └── fastqc_reports/
│           ├── sample1_R1.trimmed_fastqc.html
│           ├── sample1_R2.trimmed_fastqc.html
│           ├── sample2_R1.trimmed_fastqc.html
│           └── sample2_R2.trimmed_fastqc.html
└── input_genome_directory/
    ├── genome.fa
    ├── genome.chrom.sizes
    ├── lambda.chrom.sizes
    ├── genome_lambda.fa
    └── bismark_index_genome_lambda/
        └── Bisulfite_Genome/
```
### Pre-alignment trimming and parameters selection
https://felixkrueger.github.io/Bismark/
#### Check if any requirements in from lybrary types: 
https://felixkrueger.github.io/Bismark/usage/library-types/

```
bash scripts/fastq_trimming.sh input_fastq_directory BS-Seq
```
```
besseq-analysis
├── input_fastq_directory/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   ├── sample2_R1.fastq.gz
│   ├── sample2_R2.fastq.gz
│   ├── fastqc_reports/
│   │   ├── sample1_R1_fastqc.html
│   │   ├── sample1_R2_fastqc.html
│   │   ├── sample2_R1_fastqc.html
│   │   └── sample2_R2_fastqc.html
│   └── trimmed_fastq/
│       ├── sample1_R1.trimmed.fastq.gz
│       ├── sample1_R2.trimmed.fastq.gz
│       ├── sample2_R1.trimmed.fastq.gz
│       ├── sample2_R2.trimmed.fastq.gz
│       ├── sample1_fastp.html
│       ├── sample2_fastp.html
│       ├── fastqc_reports/
│       │   ├── sample1_R1.trimmed_fastqc.html
│       │   ├── sample1_R2.trimmed_fastqc.html
│       │   ├── sample2_R1.trimmed_fastqc.html
│       │   └── sample2_R2.trimmed_fastqc.html
│       └── bismark_input_fastq/
│           ├── sample1_R1.fastq.gz
│           ├── sample1_R2.fastq.gz
│           ├── sample2_R1.fastq.gz
│           └── sample2_R2.fastq.gz
│
└── input_genome_directory/
    ├── genome.fa
    ├── genome.chrom.sizes
    ├── lambda.chrom.sizes
    ├── genome_lambda.fa
    └── bismark_index_genome_lambda/
        └── Bisulfite_Genome/
```

```
bash scripts/bismark_alignment.sh input_fastq_directory BS-Seq
```

```
besseq-analysis
├── input_fastq_directory/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   ├── sample2_R1.fastq.gz
│   ├── sample2_R2.fastq.gz
│   ├── fastqc_reports/
│   │   ├── sample1_R1_fastqc.html
│   │   ├── sample1_R2_fastqc.html
│   │   ├── sample2_R1_fastqc.html
│   │   └── sample2_R2_fastqc.html
│   └── trimmed_fastq/
│   |   ├── sample1_R1.trimmed.fastq.gz
│   |   ├── sample1_R2.trimmed.fastq.gz
│   |   ├── sample2_R1.trimmed.fastq.gz
│   |   ├── sample2_R2.trimmed.fastq.gz
│   |   ├── sample1_fastp.html
│   |   └── sample2_fastp.html
│   |        ├── fastqc_reports/
│   |        │   ├── sample1_R1.trimmed_fastqc.html
│   |        │   ├── sample1_R2.trimmed_fastqc.html
│   |        │   ├── sample2_R1.trimmed_fastqc.html
│   |        │   └── sample2_R2.trimmed_fastqc.html
│   |        └── bismark_input_fastq/
│   |            ├── sample1_R1.fastq.gz
│   |            ├── sample1_R2.fastq.gz
│   |            ├── sample2_R1.fastq.gz
│   |            └── sample2_R2.fastq.gz
├── bismark_alignment/
|   ├── sample1_bismark_bt2.bam
│   ├── sample2_bismark_bt2.bam
│   ├── sample1_bismark_bt2_PE_report.txt
│   └── sample2_bismark_bt2_PE_report.txt
└── input_genome_directory/
    ├── genome.fa
    ├── genome.chrom.sizes
    ├── lambda.chrom.sizes
    ├── genome_lambda.fa
    └── bismark_index_genome_lambda/
        └── Bisulfite_Genome/
```
