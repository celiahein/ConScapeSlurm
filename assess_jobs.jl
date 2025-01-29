using Pkg
Pkg.instantiate()

include("problem.jl")

assess(batch_problem, rast)