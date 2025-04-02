nothing
using ConScape
using ConScapeJobs

idkey = "SLURM_ARRAY_TASK_ID"
batch = if haskey(ENV, idkey) 
    parse(Int, ENV[idkey]) + 1 # SLURM is 0 based, Julia is 1 based
else
    1 # Just for interactive/debugging use
end
println("Starting task $batch on $(Threads.nthreads()) threads...")

# Loade the assessment
assessment = ConScapeJobs.assessment()
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.raster();
# Initialise the batch problem with the raster data and assessment
batch_init = init(batch_problem, rast, assessment; verbose=true)
# Garbage collect before we start, just in case...
GC.gc() 
# Solve
@time solve(batch_init, batch; verbose=true)