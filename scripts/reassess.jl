
# May be needed in interactive use
# using Pkg, Revise
# Pkg.activate("ConScapeSlurm/")
# Pkg.instantiate() 

using ConScape
using ConScapeSlurm
using JSON3

datadir = ConScapeSlurm.path()
batch_problem = ConScapeSlurm.batch_problem()
rast = ConScapeSlurm.raster()
original_assessment = ConScapeSlurm.original_assessment()

# Current status
reassessment = ConScape.reassess(batch_problem, original_assessment)

# After this you can launch run_job.sh with --array=0-[reassessment.njobs-1] - renumbered from 0
JSON3.write(ConScapeSlurm.assessment_path(), reassessment)

display(reassessment)