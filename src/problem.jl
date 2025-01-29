# Data
function load_raster()
    # Package test data

    datadir = joinpath(dirname(pathof(ConScape)), "..", "data")
    target_qualities_path = qualities_path = joinpath(datadir, "qualities_sno_2000.asc")

    # User data
    # datadir = "P:/31212200_greenplan/Species_Maps/Pollinators/Connectivity/in_data/"
    # qualities_path = joinpath(datadir, "TemperateHSM.tif")
    # target_qualities_path = joinpath(datadir, "TemperateHSM_target.tif")

    qualities = Raster(qualities_path; lazy=true, missingval=NaN)
    target_qualities = Raster(target_qualities_path; lazy=true, missingval=NaN)

    zerotonan(x) = x == 0 ? NaN : x

    affinities = zerotonan.(qualities)

    return RasterStack((; qualities, target_qualities, affinities))
end

# Problem
function batch_problem(;
    nwindows=5,
    # buffer=200, 
    # centersize=21, 
    buffer=10, 
    centersize=5, 
)
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
        buffer, centersize, threaded=true
    )
    jobdir = joinpath(dirname(pathof(ConScapeJobs)), "..", "data")
    joblistpath = joinpath(jobdir, "joblist")
    datapath = joinpath(jobdir, "outputs")
    return ConScape.BatchProblem(windowed_problem; 
        datapath, joblistpath, nwindows
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