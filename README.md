# ConScapeSlurm
 
_SLURM job management for ConScape.jl_

Runs a ConScape.jl `BatchProblem` as array jobs on a slurm cluster.


`user/problem.jl` holds the problem specification, loaded with `using ConScapeSlurm`.
`user/datasets.csv` holds file paths and parameters for one or multpiple dataset that use this `Problem` specification.

The `scripts` folder holds paired julia `.jl` and bash `.sh` scripts. The `.sh` scripts can be edited to change
SLURM settings, and set memory and time requirements, and the number of jobs to run.

Generally, a ConScape workflow looks like this.

1. Clone this repository, and make a branch or a fork to work in
2. Edit the datasets.csv and problem.jl files to match your needs.
3. `rsync` files to the `path` specified in `dataset.csv` on your cluster.
4. Run `sbatch instantiate.sh` to install the exact project dependencies specified in `Manifest.toml`.
5. Run `sbatch assess.sh mydatasetname` to calculate the number of jobs and windows for each dataset (row) in `datasets.csv`.
6. Run `sbatch estimate.sh mydatasetname` to estimate computation and memory needs.
7. In run.sh set `array` to e.g. `0-9` and other SLURM parameters, to see if things are working with `sbatch run.sh mydatasetname`.
8. Update `array` for the rest of the job and rerun `sbatch run.sh mydatasetname`, and repeat for each dataset.
9. Run `sbatch reassess.sh mydatasetname` and check the data map in the slurm file to make sure it is empty.
    If there are remaining jobs for some reason, update `runs.sh` with `array=0-myremainingjobs` and run 
    `sbatch run.sh mydatasetname`.
10. Repeat until the map is empty, fixing any issues that may cause the same jobs to fail repeatedly.
11. Run `sbatch mosaic.sh mydatasetname` for each dataset to mosaic the outputs into rasters.
12. rsync `output_*` files from the paths in your `datasets.csv` back to your local machine.

If you have any problems following this, please make an issue in the issues tab above. 
