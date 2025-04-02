nothing
using Pkg, Revise
Pkg.activate("ConScapeJobs/")

using ConScape
using ConScapeJobs
using Rasters
using Plots
using JSON3

Threads.nthreads()

datadir = ConScapeJobs.path()

assessment =  ConScapeJobs.assessment()
batch_problem = ConScapeJobs.batch_problem(; threaded=false)
rast = ConScapeJobs.raster()

i = assessment.indices[10]
paths = ConScape.batch_paths(batch_problem, rast)[assessment.indices]

    # Subset a small raster
    full_rast = ConScapeJobs.load_raster()
    # Get a chunk from the middle of the raster that has values
    ranges = map(size(full_rast)) do s
        a = div(s, 2) 
        max(a - 2050, 1):min(a - 2000, s)
    end
    rast = full_rast[ranges...]
    bp = ConScapeJobs.batch_problem(
        nwindows=1,
        buffer=10, 
        centersize=5, 
    ) 

import ArchGDAL
using Rasters
using ConScape
import ConScapeJobs

paths = ConScape.batch_paths(batch_problem, rast)
r1 = RasterStack(paths[re.indices[1]]; lazy=true)

# This will take about 2 minutes
npaths = length(paths)
@time stacks = [
    begin
        @show i
        # GC every hundred stacks
        rem(i, 100) == 0 && GC.gc()
        RasterStack(path; lazy=false, missingval=NaN) 
    end
    for (i, path) in enumerate(paths[101:200])
];  

filename_base = joinpath(datadir, "outputs/combined")
filenames = map(keys(r1)) do k
    rasters = map(s -> s[k], stacks)
    filename = filename_base * "_$k.tif"
    mosaic(sum, rasters; to=rast, filename, lazy=true, force=true, progress=false)
end
nancounts = map(stacks) do st
    count(isnan, st.betk)
end
nancounts
onlynans = filter(stacks) do st
    all(isnan, st.betk)
end
using Plots
for st in stacks
    display(Plots.plot(st.betk))
end
Plots.plot(stacks[4].betk)

assessment
re = ConScape.reassess(batch_problem, assessment)
findall(in(re.indices), assessment.indices)

filenames = (betk=joinpath(datadir, "output_betk.tif"), ch=joinpath(datadir, "output_ch.tif"))
st = RasterStack(filenames; lazy=true)
plot(min.(250000, st.betk); size=(1000, 1000), colormap=:inferno)
