##################
# Batch Assessment
##################

# It is reccomended to run this script as a SLURM batch using `sbatch assess.sh`
# Then, run over the script interactively to view plots and assessment details as needed.

# All heavy computations are stored to JSON files and skpped if the files are found, 
# so using this script on the login node is ok IF it has already been run with `sbatch`

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# DO NOT run this scripts in login nodes without running with `sbatch assess.sh` first.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

println("Starting ConScape assessment on $(Threads.nthreads()) cores...")
println("Loading packages...")

using ConScape
using ConScapeJobs
using JSON3

datadir = ConScapeJobs.datadir

println("Loading problem...")
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()
println("RasterStack of size $(size(rast)) loaded lazily")

assessment_json = joinpath(datadir, "assessment.json")
original_assessment_json = joinpath(datadir, "original_assessment.json")

println("Running ConScape.assess...")
@time assessment = ConScape.assess(batch_problem, rast; verbose=true)

JSON3.write(assessment_json, assessment)
JSON3.write(original_assessment_json, assessment)

display(assessment)