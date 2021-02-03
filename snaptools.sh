#!/bin/bash

# Submission script accepting arguments for snaptools for scATAC data
# Ellie Fewings, 20Nov2020

# Running:
# ./snaptools.sh -i <input directory> -r <reference trancriptome> -t <analysis tool> -c <conda environment> -o <output location>[optional] -h <help>

# Source bashrc
source ~/.bashrc

# Set abort function
abort()
{
    echo "Uh oh. An error occurred."
    echo ""
    echo "Exiting..."
    exit 2
}

trap 'abort' SIGINT SIGTERM

set -e

# Set help function
helpFunction()
{
  echo ""
  echo "Program: Snaptools"
  echo ""
  echo "Version: 0.1"
  echo ""
  echo "Usage: ./snaptools.sh -i <input directory> -r <reference trancriptome> -t <analysis tool> -c <conda environment> -o <output location>[optional] -h <help>"
  echo ""
  echo "Options:"
      echo -e "\t-i\tInput: Path to directory containing fastqs (for alignment), bams (for preprocessing), or snap files (for counting) [required]"
      echo -e "\t-r\tReference transcriptome: Path to reference transcriptome (.fa) [required]"
      echo -e "\t-t\tAnalysis tool: Stage of pipeline to run, one of 'align', 'preprocess', or 'count' [required]"
      echo -e "\t-c\tConda environment: Conda environment containing SnapTools and BWA [required]"
      echo -e "\t-o\tOutput directory: Path to location where output will be generated [default=$HOME]"
      echo -e "\t-h\tHelp: Does what it says on the tin"
  echo ""
}

# Set default output location
output="$HOME"

# Accept arguments specified by user
while getopts "i:r:t:c:o:h" opt; do
  case $opt in
    i ) input="$OPTARG"
    ;;
    r ) ref="$OPTARG"
    ;;
    t ) tool="$OPTARG"
    ;;
    c ) conda="$OPTARG"
    ;;
    o ) output="$OPTARG"
    ;;
    h ) helpFunction ; exit 0
    ;;
    * ) echo "Incorrect arguments" ; helpFunction ; abort
    ;;
  esac
done

# Check minimum number of arguments
if [ $# -lt 3 ]; then
  echo "Not enough arguments"
  helpFunction
  abort
fi

# If input or intervals are missing report help function
if [[ "${input}" == "" || "${ref}" == "" || "${tool}" == "" ]]; then
  echo "Incorrect arguments."
  echo "Input, reference, and analysis tool are required."
  helpFunction
  abort
else
  input=$(realpath "${input}")
  ref=$(realpath "${ref}")
fi

# Check if input contains files
if [[ "${tool}" == "align" ]] ; then

   if [[ $(ls -1 ${input}/*fastq.gz | wc -l) -lt 1 ]] ; then
    echo "Input directory contains no fastqs. Please try again." 
    helpFunction
    abort
  fi
elif [[ "${tool}" == "preprocess" ]] ; then
  if [[ $(ls -1 ${input}/*bam | wc -l) -lt 1 ]] ; then
    echo "Input directory contains no bams. Please try again." 
    helpFunction
    abort
  fi
elif [[ "${tool}" == "count" ]] ; then
  if [[ $(ls -1 ${input}/*snap | wc -l) -lt 1 ]] ; then
    echo "Input directory contains no snap files. Please try again." 
    helpFunction
    abort
  fi
fi

# Check if tool is one of expected choices
if [[ "${tool}" == "align" || "${tool}" == "preprocess" || "${tool}" == "count" ]] ; then
  echo "Running in ${tool} mode..."
else
  echo "Please supply an analysis tool of 'align', 'preprocess', or 'count'"
  helpFunction
  abort
fi

################
## Find tools ##
################

#Load conda environment and look for snaptools and bwa
if [[ ! -z ${conda}  ]]; then
  conda activate ${conda}
else
  echo "Please supply a conda environment with -c flag."
  helpFunction
  abort
fi

#Look for tools
bwa=$(which bwa)
snaptools=$(which snaptools)

if [[ ${bwa} == "" || ${snaptools} == "" ]]; then
  echo "Cannot find BWA or SNAPtools in conda environment."
  echo "Please install these. See README for help with installation."
  helpFunction
  abort
fi

################
## Create log ##
################

# Create directory for log and output
if [[ -z ${output} ]]; then
    outdir="${HOME}/snaptools_output_$(date +%Y%m%d)"
else
    outdir="${output}/snaptools_output_$(date +%Y%m%d)"
fi

mkdir -p ${outdir}

log="${outdir}/snaptools_count_$(date +%Y%m%d).log"

# Create temporary directory
tmp_dir=$(mktemp -d -p ${outdir})

# Create list of unique samples on which to run analysis
tfile="${tmp_dir}/samples.tmp.txt"
sfile="${tmp_dir}/samples.txt"

# Report to log
echo "Running ./snaptools.sh" > ${log}
echo "" >> ${log}
echo "------------" >> ${log}
echo " Submission " >> ${log}
echo "------------" >> ${log}
echo "" >> ${log}
echo "Job name: snaptools" >> ${log}
echo "Time of submission: $(date +"%T %D")" >> ${log}
echo "Resources allocated: nodes=1:ppn=8" >> ${log}
echo "User: ${USER}" >> ${log}
echo "Log: ${log}" >> ${log}
echo "Input: ${input}" >> ${log}
echo "Analysis tool: ${tool}" >> ${log}
echo "Reference trancriptome: ${ref}" >> ${log}
echo "Output: ${outdir}" >> ${log}

###########
## Input ##
###########

echo "" >> ${log}
echo "-------" >> ${log}
echo " Input " >> ${log}
echo "-------" >> ${log}
echo "" >> ${log}

# Create list of samples

if [[ "${tool}" == "align" ]] ; then

  #If input is fqs
  for fq in $(ls -1 ${input}/*fastq.gz) ; do
    sample=$(basename ${fq} | sed 's/_L.*/_/g' | sed 's/_S[0-9]_.*//g' | sed 's/_[1-9].fastq.gz//g' | sed 's/_$//')
    
    R1=$(realpath $(ls ${input}/${sample}*R1*))
    R2=$(realpath $(ls ${input}/${sample}*R2*))    
     if [[ ${R1} == "" || ${R2} == "" ]] ; then
       echo "R1 or R2 missing for sample: ${sample}"
       exit 1
     fi
    
    #Write to file
    echo -e "${sample}\t${R1}\t${R2}" >> ${tfile}
   done
 #If input is bams   
elif [[ "${tool}" == "preprocess" ]] ; then
  for bam in $(ls -1 ${input}/*bam) ; do
    sample=$(basename ${bam} | sed 's/.bam//' )
    bm=$(realpath ${bam})
    
    #Write to file
    echo -e "${sample}\t${bam}" >> ${tfile}
  done
#If input is snap files     
elif [[ "${tool}" == "count" ]] ; then
  for snap in $(ls -1 ${input}/*snap) ; do
    sample=$(basename ${snap} | sed 's/.snap//' )
    sn=$(realpath ${snap})
      
    #Write to file
    echo -e "${sample}\t${sn}" >> ${tfile}
  done
fi


# Remove duplicates from samples file
cat ${tfile} | sort -u > ${sfile}

################
## Submit job ##
################

# Submit job to cluster
loc="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Submit job based on tool
if [[ "${tool}" == "align" ]] ; then

  while read sample R1 R2; do
    echo "Submitting to cluster: ${sample}" >> ${log}
    sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},R1=${R1},R2=${R2},conda=${conda} "${loc}/slurm/slurm_snapalign.sh"
  done < ${sfile}
  
elif [[ "${tool}" == "preprocess" ]] ; then

    while read sample bam; do
      echo "Submitting to cluster: ${sample}" >> ${log}
      sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},bam=${bam},conda=${conda} "${loc}/slurm/slurm_snappreprocess.sh"
    done < ${sfile}

elif [[ "${tool}" == "count" ]] ; then

    while read sample snap; do
      echo "Submitting to cluster: ${sample}" >> ${log}
      sbatch --export=sample=${sample},ref=${ref},outdir=${outdir},tmp_dir=${tmp_dir},log=${log},snap=${snap},conda=${conda} "${loc}/slurm/slurm_snapcount.sh"
    done < ${sfile}

fi




