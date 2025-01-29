nothing
using ConScape
using ConScapeJobs

i = parse(Int, ENV["SLURM_ARRAY_TASK_ID"])
ConScape.solve(ConScapeJobs.batch_problem(), ConScapeJobs.load_raster(), i)