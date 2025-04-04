
# May be needed in interactive use
# using Pkg, Revise
# Pkg.activate("ConScapeJobs/")
# Pkg.instantiate() 

using ConScape
using ConScapeJobs
using JSON3

datadir = ConScapeJobs.path()
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.raster()
original_assessment = ConScapeJobs.original_assessment()

# Current status
reassessment = ConScape.reassess(batch_problem, original_assessment)

# After this you can launch run_job.sh with --array=0-[reassessment.njobs-1] - renumbered from 0
JSON3.write(ConScapeJobs.assessment_path(), reassessment)

display(reassessment)