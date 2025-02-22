#!/bin/bash
#SBATCH --account=nn11055k
#SBATCH --job-name='mosaic_ConScape'
#SBATCH --time=0:30:0
#SBATCH --mem-per-cpu=8G 
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1                
set -o errexit  # Exit the script on any error
set -o nounset  # Treat any unset variables as an error
module --quiet purge   # clear any inherited modules
module load Julia/1.10.5-linux-x86_64
julia --threads=1 --project=.. mosaic.jl