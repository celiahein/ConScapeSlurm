nothing
using ConScape
using ConScapeJobs
using JSON3
using DiskArrays
# Scalar reads over the network could take hours, 
# it has to error instead so the batch is killed.
DiskArrays.allowscalar(false)

idkey = "SLURM_ARRAY_TASK_ID"
batch = if haskey(ENV, idkey) 
    parse(Int, ENV[idkey]) + 1 # SLURM is 0 based, Julia is 1 based
else
    1 # Just for interactive/debugging use
end
println("Starting task $batch on $(Threads.nthreads()) threads...")

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment) 
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster();
batch_init = init(batch_problem, rast, assessment; verbose=true)
GC.gc()
@time solve(batch_init, batch; verbose=true)