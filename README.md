# BS-seq Methylation Analysis Pipeline

This repository provides a reproducible and modular pipeline for DNA methylation analysis using bisulfite sequencing (BS-seq) data.
The workflow processes raw sequencing reads from FASTQ files through alignment, filtering and methylation extraction, generating outputs suitable for downstream analysis and visualization.

---
## Installation
### Clone the repository
```bash
git clone https://github.com/your-org/bsseq-analysis.git
cd bsseq-analysis
```
### Setup the environment
```bash
bash scripts/setup_environment.sh
```
What it does:
- Installs Miniconda locally (if not already installed)
- Creates a Conda environment named bsseq
- Installs all required tools:
  - fastp
  - FastQC
  - Bismark
  - Bowtie2
  - Samtools
  - Sambamba
  - MethylDackel
  - Bedtools
  - UCSC utilities (bedGraphToBigWig)
This step only needs to be executed once per system.

### Input requirements
FASTQ files:
- Paired-end reads
- Compressed format: `.fastq.gz`
- Naming convention:
Reference genome:
- FASTA format (`.fa` or `.fasta`)

### Expected directory structure
Before running the pipeline, your project should look like this:
```
bsseq-analysis/
├── input_fastq_directory/
│   ├── sample1_R1.fastq.gz
│   ├── sample1_R2.fastq.gz
│   ├── sample2_R1.fastq.gz
│   └── sample2_R2.fastq.gz
└── input_genome_directory/
    └── genome.fa
```
---
## Pipeline usage
The pipeline can be executed in two ways:
---
### Full pipeline 
```bash
bash run_pipeline.sh input_fastq_directory input_genome_directory/genome.fa BS-Seq 16
```
####Arguments:
`input_fastq_directory`: directory containing FASTQ files
`genome.fa`: reference genome
`library_type`: sequencing library type
`threads` (optional): number of threads (default: 16)
Supported library types:
- BS-Seq
- RRBS
- PBAT
- scBS-Seq
- TruSeq
- Accel-NGS
- Zymo
- EM-seq

### Step-by-step execution
Each script can be executed independently:
1. Genome preparation
```bash
bash scripts/genome_preparation.sh input_genome_directory/genome.fa
```
What it does:
- Adds lambda phage as spike-in control
- Generates combined genome (genome + lambda)
- Creates chrom.sizes files
- Builds Bismark index
2. FASTQ trimming
```bash
bash scripts/fastq_trimming.sh input_fastq_directory 8
```
What it does:
- Removes adapters and low-quality bases
- Trims reads based on quality
- Filters short reads
- Generates QC reports (fastp + FastQC)

3. FASTQ preparation for Bismark
```bash
bash scripts/bismark_fastq_prep.sh input_fastq_directory BS-Seq
```
What it does:
- Applies library-specific trimming
- Adjusts reads depending on library type
- Generates input FASTQ files for alignment

4. Alignment
```bash
bash scripts/bismark_alignment.sh input_fastq_directory BS-Seq 16
```
What it does:
- Aligns reads using Bismark
- Uses Bowtie2 backend
- Applies library-specific parameters
- Generates BAM files and reports

5. BAM processing
```bash
bash scripts/bam_processing.sh 16
```
What it does:
- Sorts BAM files
- Removes duplicate reads
- Filters low-quality and unwanted reads
- Produces final processed BAM files

6. Methylation analysis
```bash
bash scripts/methylation_analysis.sh 16
```
What it does:
- Detects and corrects M-bias
- Extracts CpG methylation (MethylDackel)
- Computes lambda methylation (conversion efficiency)
- Generates BEDGRAPH files
- Produces DSS input tables
- Generates BigWig tracks for visualization
## Output
All results are stored in: `methylation_output/`
### Output structure
```
methylation_output/
├── bismark_alignment/
├── deduplicated/
├── mbias/
├── methylation/
├── DSS/
├── lambda_stats/
└── bigwig/
```
