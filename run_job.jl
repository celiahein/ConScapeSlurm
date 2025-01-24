using Pkg
Pkg.instantiate()

include("conscape_problem.jl")

i = Environment["job_index"]
ConScape.solve(stored_problem, rast, i)