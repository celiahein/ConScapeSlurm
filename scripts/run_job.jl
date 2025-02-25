nothing
using ConScape
using ConScapeJobs
using JSON3

idkey = "SLURM_ARRAY_TASK_ID"
batch = if haskey(ENV, idkey) 
    parse(Int, ENV[idkey]) + 1 # SLURM is 0 based, Julia is 1 based
else
    1
end
println("Starting task $batch on $(Threads.nthreads()) threads...")

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment)
batch_problem = ConScapeJobs.batch_problem()
GC.gc()
rast = ConScapeJobs.load_raster()

@time ConScape.solve(batch_problem, rast, assessment, batch)