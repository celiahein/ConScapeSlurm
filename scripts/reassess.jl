
# May be needed in interactive use
# using Pkg, Revise
# Pkg.activate("ConScapeJobs/")
# Pkg.instantiate() 

using ConScape
using ConScapeJobs
using JSON3

datadir = ConScapeJobs.datadir
assessment_json = joinpath(datadir, "assessment.json")
original_assessment_json = joinpath(datadir, "original_assessment.json")

batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()
original_assessment = JSON3.read(original_assessment_json, ConScape.NestedAssessment) 

# Current status
reassessment = ConScape.reassess(batch_problem, original_assessment)

# After this you can launch run_job.sh with --array=0-[reassessment.njobs-1] - renumbered from 0
JSON3.write(assessment_json, reassessment)

display(reassessment)