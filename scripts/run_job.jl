nothing
using ConScape
using ConScapeJobs
using JSON3

task_id = parse(Int, ENV["SLURM_ARRAY_TASK_ID"])

assessment = JSON3.read("assessment.json", ConScape.NestedAssessment)

@time ConScape.solve(ConScapeJobs.batch_problem(), ConScapeJobs.load_raster(), task_id;
    window_indices=assessment.indices, verbose=true
)