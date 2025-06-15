
println("Loading packages...")
using ConScapeSlurm

println("Starting ConScape assessment on $(Threads.nthreads()) cores...")
assessment = ConScapeSlurm.assess()

display(assessment)