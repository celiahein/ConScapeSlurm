nothing
using Pkg, Revise
Pkg.activate("ConScapeJobs/")
using ConScape
using ConScapeJobs
using JSON3
using Plots
using Rasters
Threads.nthreads()

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment) 
batch_problem = ConScapeJobs.batch_problem(; threaded=false)
rast = ConScapeJobs.load_raster()

i = assessment.indices[10]
paths = ConScape.batch_paths(batch_problem, rast)[assessment.indices]

plot(outputs3; size=(1200, 800))
M = Rasters.mosaic(sum, outputs3)

rebuild(M; missingval=0.0)

plot(window_rast)
plot(window_rast)
plot(M; size=(1200, 800))
plot(window_rast.target_qualities)

for (i, o) in enumerate(outputs)
    ismissing(o) || display(plot(o; title=string(i)))
end

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

onlynans
combined = mosaic(sum, stacks[101:end]; to=rast, lazy=true, force=true, progress=false)
size(combined)
using Plots
plot(combined.ch)
plot(combined.betk)

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment) 
assessment
# ranges = vec(ConScape.window_ranges(batch_problem, rast))
# corners = map(first, ranges)
batch = 2004 # findfirst(==(paths[104]), ConScape.batch_paths(batch_problem, rast)[assessment.indices])
batch_ranges = ConScape.window_ranges(batch_problem, rast)[assessment.indices[batch]]
batch_path = ConScape.batch_paths(batch_problem, rast)[assessment.indices[batch]]
batch_rast = rast[batch_ranges...]
batch_result = RasterStack(batch_path; missingval=NaN)
Plots.plot(batch_rast)
Plots.plot(batch_result)
plot(merge(batch_result, batch_rast))
Plots.plot(batch_rast.target_qualities)
batch_init = init(batch_problem, rast, assessment)
batch_init isa ConScape.BatchInit
window_init = init(batch_init, batch)
window_rast = window_init.rast[window_init.ranges[12]...]
Plots.plot(window_rast)
results = map(1:20) do i
    i = 12
    @show i
    ranges = window_init.ranges[i]
    # verbose && println("Initialising window from ranges $ranges...")
    # rast = ConScape._get_window_with_zeroed_buffer(view, ConScape.problem(window_init), window_init.rast, ranges)
    # grid_rast = window_init.rast[ranges...]
    # mgi = init(window_init.problem.problem, grid_rast)
    # try
    mgi = init(window_init, i);
    solve(mgi)
    # catch
        # missing
    # end
    # Convert cost matrix to graph, todo: is `permute=false` needed
    # graph = ConScape.SimpleWeightedDiGraph(ConScape.costmatrix(g); permute=false)
    # Find the subgraphs
    # scc = strongly_connected_components(graph)
end;
solve(init(window_init, 12))

for res in results2
    ismissing(res) && continue
    display(Plots.plot(res))
end

display(Plots.plot(results2[3]))