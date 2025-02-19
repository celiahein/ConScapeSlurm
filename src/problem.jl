datadir = "/cluster/projects/nn11055k/conscape/data/"

# Data
function load_raster()
    # Package test data

    # datadir = joinpath(dirname(pathof(ConScape)), "..", "data")
    # target_qualities_path = qualities_path = joinpath(datadir, "qualities_sno_2000.asc")

    # User data
    qualities_path = joinpath(datadir, "TemperateHSM.tif")
    target_qualities_path = joinpath(datadir, "TemperateHSM_target.tif")

    qualities = Raster(qualities_path; lazy=true, missingval=NaN)
    target_qualities = Raster(target_qualities_path; lazy=true, missingval=NaN)

    zerotonan(x) = x == 0 ? NaN : x

    affinities = zerotonan.(qualities)

    return RasterStack((; qualities, target_qualities, affinities))
end

# Problem
function batch_problem(;
    nwindows=15,
    buffer=200,
    centersize=16, 
    threaded=false,
)
    ## Define connectivity
    # Set theta
    θ = 0.5
    α = 60 / 3000
    # Define a distance transformation
    distance_transformation = x -> exp(-x * α)
    connectivity_measure = ConScape.ExpectedCost(; θ, distance_transformation)

    # Define graph measures
    graph_measures = (;
        ch=ConScape.ConnectedHabitat(),
        betk=ConScape.BetweennessKweighted(),
    )

    ## Specify the problem
    solver = ConScape.VectorSolver()
    problem = ConScape.Problem(; graph_measures, connectivity_measure, solver)
    
    # Specify the windowing pattern
    windowed_problem = ConScape.WindowedProblem(problem; 
        buffer, centersize, threaded
    )

    # Specify the batch job windowing
    datapath = joinpath(datadir, "outputs")
    return ConScape.BatchProblem(windowed_problem; 
        datapath, nwindows
    )
end

# Precompile the problem so that it can happen on one thread,
# rather than while all threads are active.
@compile_workload begin
    # Subset a small raster
    full_rast = load_raster()
    # Get a chunk form the middle area
    ranges = map(size(full_rast)) do s
        a = div(s, 2) 
        max(a - 24, 1):min(a + 25, s)
    end
    rast = full_rast[ranges...]
    batch = batch_problem(
        nwindows=1,
        buffer=10, 
        centersize=5, 
    ) 
    # Just precompile the inner problem
    # problem = batch.problem.problem
    # workspace = ConScape.init(problem, rast)
    # ConScape.solve!(workspace, problem)
    # ConScape.assess(problem, rast)
end