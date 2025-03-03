nothing
using Pkg, Revise
Pkg.activate("ConScapeJobs/")
using ConScape
using ConScapeJobs
using JSON3
using Plots
using Rasters

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment) 
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()
stack1 = RasterStack(ConScape.batch_paths(batch_problem, rast)[assessment.indices[1]])
plot(stack)