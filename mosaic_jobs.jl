using Pkg
Pkg.instantiate()

include("problem.jl")

output_raster = mosaic(stored_problem; to=rast)
write("../data/output.nc", output_raster)
