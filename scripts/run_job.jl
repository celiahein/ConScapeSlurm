nothing
using ConScape
using ConScapeJobs
using JSON3

idkey = "SLURM_ARRAY_TASK_ID"
task_id = if haskey(ENV, idkey) 
    parse(Int, ENV[idkey]) + 1 # SLURM is 0 based, Julia is 1 based
else
    1
end
println("Starting task $task_id...")

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment)

@time ConScape.solve(ConScapeJobs.batch_problem(), ConScapeJobs.load_raster(), task_id;
    window_indices=assessment.indices, verbose=true
)