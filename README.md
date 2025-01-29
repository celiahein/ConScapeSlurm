# ConScapeJobs
 
Slurm job management for ConScape.jl

Runs a ConScape.jl `BatchProblem` as array jobs on a slurm cluster.

`src/problem.jl` holds the problem specification, loaded with `using ConScapeJobs`.

`assess.jl` calculates batch requirements based on the `BatchProblem` and the `RasterStack` dataset defined in `problem.jl`.

`run_job.jl` runs a single window of the `BatchProblem`.

`mosaic.jl` combines the output of all jobs into a single `RasterStack` and writes it to disk for download.