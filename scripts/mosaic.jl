using Pkg
using Revise
Pkg.activate("ConScapeJobs/") # May be needed in interactive use
import ArchGDAL
using Rasters
using ConScape
import ConScapeJobs

datadir = ConScapeJobs.datadir

batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()
filename = joinpath(datadir, "outputs/combined.tif")

paths = filter(isdir, ConScape.batch_paths(batch_problem, rast))[1:10]
r1 = RasterStack(first(paths); lazy=true)

# This will take about 2 minutes
npaths = length(paths)
@time stacks = [
    begin
        @show i
        # GC every hundred stacks
        rem(i, 100) == 0 && GC.gc()
        RasterStack(path; lazy=true) 
    end
    for (i, path) in enumerate(paths)
];  

mosaic(sum, stacks; to=rast, filename, lazy=true, force=true);