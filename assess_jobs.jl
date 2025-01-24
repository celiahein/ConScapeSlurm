using Pkg
Pkg.instantiate()

include("problem.jl")

allocations(batch_problem, rast)