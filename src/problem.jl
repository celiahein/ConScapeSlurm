# Data
function load_raster()
    # Package test data
    datadir = joinpath(dirname(pathof(ConScape)), "..", "data")
    target_qualities_path = qualities_path = joinpath(datadir, "qualities_$landscape.asc")

    # User data
    # datadir = "P:/31212200_greenplan/Species_Maps/Pollinators/Connectivity/in_data/"
    # qualities_path = joinpath(datadir, "TemperateHSM.tif")
    # target_qualities_path = joinpath(datadir, "TemperateHSM_target.tif")

    qualities = Raster(qualities_path; lazy=true, missingval=NaN)
    target_qualities = Raster(target_qualities_path; lazy=true, missingval=NaN)

    zerotonan(x) = x == 0 ? NaN : x

    affinities = zerotonan.(qualities)
    costs = ConScape.MinusLog().(affinities)

    return RasterStack((; qualities, target_qualities, affinities, costs))
end

# Problem
function batch_problem()
    θ = 0.5
    α = 60 / 3000
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

    return ConScape.BatchProblem(windowed_problem; 
        datapath="../data/outputs", joblistpath="../data/joblist", nwindows=10,
    )
end

# Precompile the problem so that it can happen on one thread,
# rather than while all threads are active.
@compile_workload begin
    # Subset a small raster
    rast = load_raster()[1:20, 1:20]
    batch = batch_problem() 
    # Just precompile the inner problem
    problem = batch.problem.problem
    workspace = init(problem, rast)
    solve!(workspace, problem)
end