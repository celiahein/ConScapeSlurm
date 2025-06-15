nothing
using Pkg, Revise
Pkg.activate("ConScapeSlurm/")

using ConScape
using ConScapeSlurm
using Rasters
using Plots


# Manually set the dataset if necessary
dataset_name = "temperate_bees"

# Load assessment, problem and rasters
datadir = ConScapeSlurm.path(dataset_name)
assessment =  ConScapeSlurm.assessment(dataset_name)
batch_problem = ConScapeSlurm.batch_problem(dataset_name; threaded=false)
rast = ConScapeSlurm.raster(dataset_name)

# Check the assessment and reassess
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

out = Raster("/cluster/projects/nn11055k/conscape/Bees/Temperate/output_betk.tif"; lazy=true)
plot(out)