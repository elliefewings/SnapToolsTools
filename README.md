# SnapToolsTools

## A toolkit for running SnapTools for scATAC data

SnapTools is a tool for aligning, processing, and counting scATAC data to produce SNAP (Single Nucleus Accessibility Profile) files.

See [repository](https://github.com/r3fang/SnapTools) for further information.

This wrapper allows a user to submit batch jobs of multiple samples to the SLURM cluster.

## Usage
```
$ ./snaptools.sh -h

Program: Snaptools

Version: 0.1

Usage: ./snaptools.sh -i <input directory> -r <reference trancriptome> -t <analysis tool> -c <conda environment> -o <output location>[optional] -h <help>

Options:
        -i      Input: Path to directory containing fastqs (for alignment), bams (for preprocessing), or snap files (for counting) [required]
        -r      Reference transcriptome: Path to directory containing reference transcriptome [required]
        -t      Analysis tool: Stage of pipeline to run, one of 'align', 'preprocess', or 'count' [required]
        -c      Conda environment: Conda environment containing SnapTools and BWA [required]
        -o      Output directory: Path to location where output will be generated [default=/home/bq_efewings]
        -h      Help: Does what it says on the tin
```

## Installation

Snaptools can be installed into a conda environment and supplied to the command above.

This tool also requires Samtools, which can be added to the environment as follows:

```
$ conda install -c bioconda samtools openssl=1.0
