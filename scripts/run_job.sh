#!/bin/bash
#SBATCH --account=nn11055k
#SBATCH --job-name='batchCS'
#SBATCH --time=0:30:0
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem-per-cpu=2G
#SBATCH --array=1-9 # Start at 0 not 1!
set -o errexit  # Exit the script on any error
set -o nounset  # Treat any unset variables as an error
module --quiet purge   # Clear any inherited modules
module load Julia/1.10.5-linux-x86_64
julia --threads=auto --project=.. run_job.jl