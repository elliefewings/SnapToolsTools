#!/bin/bash
## Run align function of snaptools, on scATACseq data. Takes one directory containing all fastqs. Output location is optional. If not supplied, output will be stored in home directory.
## For easy usage, submit job with ./snaptools.sh script
## Usage: sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},bam=${bam},conda=${conda} "${loc}/slurm/slurm_snappreprocess.sh"

# Job Name
#SBATCH --job-name=snaptools_preprocess.$sample
# Resources, ... and one node with 8 processors:
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

#Set output directory
outsnap="${outdir}/snap"

mkdir -p ${outsnap}

#Create log
slog="${tmp_dir}/${sample}.preprocess.log"

#Set name of output
snap="${sample}.snap"

#Set reference name
rname=$(basename ${ref} | sed 's/.fa//' )

snaptools snap-pre  \
	--input-file=${bam} \
	--output-snap=${snap}  \
	--genome-name=${rname}  \
	--genome-size="${rname}.chrom.size"  \
	--min-mapq=30  \
	--min-flen=0  \
	--max-flen=1000  \
	--keep-chrm=TRUE  \
	--keep-single=TRUE  \
	--keep-secondary=False  \
	--overwrite=True  \
	--max-num=1000000  \
	--min-cov=100  \
 	--num-threads=7	\
	--verbose=True &>> ${slog}

 