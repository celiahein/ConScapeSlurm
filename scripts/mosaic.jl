# using Pkg
# using Revise
# Pkg.activate("ConScapeJobs/") # May be needed in interactive use
import ArchGDAL
using Rasters
using ConScape
import ConScapeJobs

datadir = ConScapeJobs.datadir

batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()

paths = filter(isdir, ConScape.batch_paths(batch_problem, rast))
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

filename_base = joinpath(datadir, "outputs/combined")
filenames = map(keys(r1)) do k
    rasters = map(s -> s[k], stacks)
    filename = filename_base * "_$k.tif"
    mosaic(sum, rasters; to=rast, filename, lazy=true, force=true, progress=false)
end

# combined = mosaic(sum, stacks; to=rast, filename, lazy=true, force=true, progress=false)

# st = RasterStack(filenames; lazy=true)
# downsampled = st[1:3:end, 1:3:end]
# south = st.combined_ch[X=0 .. 2.5e5, Y=6.5e6 .. 6.7e6]
# plot(south[1:3:end, 1:3:end]; size=(1000, 1000))
# using Plots
# plot(downsampled; size=(1000, 1000))

# oa = original_assessment
# allpaths = ConScape.batch_paths(batch_problem, rast)
# plot(RasterStack(allpaths[oa.indices[1005]]))
# plot(batch)
# o.indices[1005]