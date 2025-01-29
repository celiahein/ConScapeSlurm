#!/bin/bash

#SBATCH --account=YourProject
#SBATCH --job-name='ConScape'
#SBATCH --time=1:0:0
#SBATCH --mem-per-cpu=4G 
#SBATCH --ntasks=8                
#SBATCH --array=0-199      
       # we start at 0 instead of 1 for this
                                  # example, as the $SLURM_ARRAY_TASK_ID
                                  # variable starts at 0

# module --quiet purge   # clear any inherited modulesk
# module load Julia/1.10.5-linux-x86_64

julia --threads=8 --project=.. run_job.jl