#!/bin/bash
#SBATCH --account=YourProject
#SBATCH --job-name='ConScape'
#SBATCH --time=0:0:10
#SBATCH --mem-per-cpu=8G 
#SBATCH --ntasks=1                
# module --quiet purge   # clear any inherited modulesk
# module load Julia/1.10.5-linux-x86_64
julia --threads=1 --project=.. mosaic.jl