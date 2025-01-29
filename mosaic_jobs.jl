using Pkg
Pkg.instantiate()

include("problem.jl")

output_raster = mosaic(stored_problem)
write("../data/output.nc", output_raster)
