using Rasters
import DiskArrays
import ArchGDAL
import ConScape as CS

# Data
datadir = "P:/31212200_greenplan/Species_Maps/Pollinators/Connectivity/in_data/"
qualities = Raster(joinpath(datadir, "TemperateHSM.tif"); lazy=true, missingval=NaN) |> DiskArrays.cache
target_qualities = Raster(joinpath(datadir, "TemperateHSM_target.tif"); lazy=true, missingval=NaN)
ztonan(x) = x == 0 ? NaN : x
affinities = ztonan.(qualities)
costs = ConScape.MinusLog().(affinities)
rast = RasterStack((; qualities, target_qualities, affinities, costs))

# Problem
θ = 0.5
α = 60 /3000
distance_transformation = x -> exp(-x * α)
connectivity_measure = ConScape.ExpectedCost(; θ, distance_transformation)
graph_measures = (;
    ch=ConScape.ConnectedHabitat(),
    betk=ConScape.BetweennessKweighted(),
)

solver = ConScape.MatrixSolver()
problem = ConScape.Problem(; graph_measures, connectivity_measure, solver)
windowed_problem = ConScape.WindowedProblem(problem; 
    buffer=200, centersize=21, threaded=false
)
stored_problem = ConScape.BatchProblem(windowed_problem; 
    path=tempname(), buffer=200, centersize=10,
    # nwindows=4, TODO 
)