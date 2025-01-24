# ConScapeJobs
 
Slurm job management for ConScape.jl

Runs a ConScape.jl `BatchProblem` as array jobs on a slurm cluster.

`problem.jl` holds the problem specification.

`assess_jobs.jl` calculates batch requirements based on the `BatchProblem` and the `RasterStack` dataset defined in `problem.jl`.

`run_job.jl` runs a single window of the `BatchProblem`.

`mosaic_job.jl` combines the output of all jobs into a single `RasterStack` and writes it to disk for download.