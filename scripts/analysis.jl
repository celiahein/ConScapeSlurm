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

paths = ConScape.batch_paths(batch_problem, rast)[assessment.indices]

assessment
re = ConScape.reassess(batch_problem, assessment)

# Plot the final outputs
measure_names = keys(ConScape.measures(batch_problem))
filenames = map(measure_names) do m
    joinpath(datadir, "output_$m.tif")
end |> NamedTuple{measure_names}
st = RasterStack(filenames; lazy=true)
# min remove outliers that dominate the colormap
plot(min.(2000000, st.betk); #[11000:13000, 11000:13000]; 
    title=basename(dirname(datadir)) * " Betweenness K",
    size=(1000, 1000), colormap=:inferno
)

plot(st.ch; 
    title=basename(dirname(datadir)) * " Connected Habitat",
    size=(1000, 1000), colormap=:inferno
)
