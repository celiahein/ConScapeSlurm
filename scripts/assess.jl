
println("Loading packages...")
using ConScapeJobs

println("Starting ConScape assessment on $(Threads.nthreads()) cores...")
assessment = ConScapeJobs.assess()

display(assessment)