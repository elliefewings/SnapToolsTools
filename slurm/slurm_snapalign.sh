#!/bin/bash
## Run align function of snaptools, on scATACseq data. Takes one directory containing all fastqs. Output location is optional. If not supplied, output will be stored in home directory.
## For easy usage, submit job with ./snaptools.sh script
## Usage: sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},R1=${R1},R2=${R2} "${loc}/slurm/slurm_snapalign.sh"

# Job Name
#SBATCH --job-name=snaptools_align.$sample
# Resources, ... and one node with 4 processors:
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --time=48:00:00
#SBATCH --mem 64000
#SBATCH --mail-user=eleanor.fewings@bioquant.uni-heidelberg.de

# Source bashrc
source ~/.bashrc

# Load conda environment if requested
if [[ ! -z ${conda}  ]]; then
  conda activate ${conda}
fi

#Find aligner
bwa=$(dirname $(which bwa))
bowtie=$(dirname $(which bowtie2))

#Set reference directory
#refdir=$(dirname ${ref})

#Set output directory
outbam="${outdir}/bam"

mkdir -p ${outbam}

#Create log
slog="${tmp_dir}/${sample}.align.log"

#Set name of output
bam="${outdir}/${sample}.bam"

snaptools align-paired-end	\
	--input-reference=${ref}	\
	--input-fastq1=${R1}	\
	--input-fastq2=${R2}	\
	--output-bam=${bam}	\
  --aligner=bwa \
	--path-to-aligner=${bwa}	\
	--read-fastq-command=zcat	\
	--num-threads=7	\
	--if-sort=True	\
	--tmp-folder=${tmp_dir}	\
	--overwrite=TRUE &>> ${slog}
 
 
 #  --aligner=bowtie2 \
#  --aligner-options='-X 1000 --very-sensitive --fr' \
