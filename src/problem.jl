datadir = "/cluster/projects/nn11055k/conscape/data/"

# Data
function load_raster()
    # Package test data

    # datadir = joinpath(dirname(pathof(ConScape)), "..", "data")
    # target_qualities_path = qualities_path = joinpath(datadir, "qualities_sno_2000.asc")

    # User data
    qualities_path = joinpath(datadir, "TemperateHSM.tif")
    target_qualities_path = joinpath(datadir, "TemperateHSM_target.tif")

    qualities = Raster(qualities_path; lazy=true, missingval=0.0)
    target_qualities = Raster(target_qualities_path; lazy=true, missingval=0.0)
    # Here we assume affinities and qualities are the same
    affinities = qualities

    st = view(RasterStack((; qualities, target_qualities, affinities)), X=12000:13000, Y=12000:13000)
    # Pad the raster border with the buffer size
    return DiskArrays.pad(st, (X=(200, 200), Y=(200, 200)))
end

# Problem
function batch_problem(;
    nwindows=15,
    buffer=200,
    centersize=16, 
    threaded=true,
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

# Precompile the ConScapeJobs problem so this happens once,
# rather than at the start of every slurm job
# @compile_workload begin
#     # Subset a small raster
#     full_rast = load_raster()
#     # Get a chunk from the middle of the raster that has values
#     ranges = map(size(full_rast)) do s
#         a = div(s, 2) 
#         max(a - 2050, 1):min(a - 2000, s)
#     end
#     rast = full_rast[ranges...]
#     bp = batch_problem(
#         nwindows=1,
#         buffer=10, 
#         centersize=5, 
#     ) 
#     p = bp.problem.problem;
#     workspace = ConScape.init(p, rast)
#     ConScape.solve!(workspace, p)
#     workspace = ConScape.init(bp, rast)
#     assessment = ConScape.assess(bp, rast)
#     ConScape.solve!(workspace, bp, 1)
# end