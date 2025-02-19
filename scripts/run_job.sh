#!/bin/bash
#SBATCH --account=nn11055k
#SBATCH --job-name='ConScape_Job'
#SBATCH --time=3:0:0
#SBATCH --mem-per-cpu=3G 
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --array=0-199
       # we start at 0 instead of 1 for this
                                  # example, as the $SLURM_ARRAY_TASK_ID
                                  # variable starts at 0
set -o errexit  # Exit the script on any error
set -o nounset  # Treat any unset variables as an error
module --quiet purge   # clear any inherited modulesk
module load Julia/1.10.5-linux-x86_64
julia --threads=1 --project=.. run_job.jl