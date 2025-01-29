using Pkg
Pkg.instantiate()

using ConScapeJobs
using ConScape

i = ENV["job_index"]
ConScape.solve(ConScapeJobs.batch_problem(), ConScapeJobs.load_raster(), i)