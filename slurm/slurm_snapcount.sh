#!/bin/bash
## Run align function of snaptools, on scATACseq data. Takes one directory containing all fastqs. Output location is optional. If not supplied, output will be stored in home directory.
## For easy usage, submit job with ./snaptools.sh script
## Usage: sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},snap=${snap},conda=${conda} "${loc}/slurm/slurm_snapcount.sh"

# Job Name
#SBATCH --job-name=snaptools_count.$sample
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

#Create log
slog="${tmp_dir}/${sample}.count.log"

# Add cell-by-bin matrix
snaptools snap-add-bmat  \
	--snap-file=snap=${snap}  \
	--bin-size-list 5000 10000  \
	--verbose=True &>> ${slog}
 