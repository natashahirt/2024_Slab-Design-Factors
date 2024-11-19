#!/bin/bash

#SBATCH -n 1
#SBATCH -N 1
#SBATCH -t 12:00:00
#SBATCH -C centos7
#SBATCH -p sched_any
#SBATCH -o output_%j.txt
#SBATCH -e error_%j.txt
#SBATCH --mail-type=BEGIN,END,FAIL,TIME_LIMIT
#SBATCH --mail-user=nhirt@mit.edu
#SBATCH --array=0-2

# Load the Julia module
module load julia

# Set the environment variables
export EXECUTABLE_PATH="SlabDesignFactors/executable/executable_analyze.jl"
export RESULTS_PATH="SlabDesignFactors/results/remote_results/"
# export JSON_PATH="/path/to/your/slab/files/"
# export RESULTS_NAME="your_results_name"

# Read the parameters for this task
PARAMS=$(sed -n "${SLURM_ARRAY_TASK_ID}p" SlabDesignFactors/executable/params.txt)
JSON_PATH=$(echo $PARAMS | cut -d ' ' -f 1)
RESULTS_NAME=$(echo $PARAMS | cut -d ' ' -f 2)

# Run the Julia script
julia -e 'include(ENV["EXECUTABLE_PATH"]); analyze_slabs(ENV["JSON_PATH"], ENV["RESULTS_PATH"], ENV["RESULTS_NAME"])'