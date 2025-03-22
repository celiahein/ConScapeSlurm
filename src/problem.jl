# datadir = "/cluster/projects/nn11055k/conscape/data/"
# datadir = "/home/NINA.NO/rafael.schouten/Mounts/scratch/tmp_raf/"
datadir = "C:\\Users\\rafael.schouten\\Data\\"
# Data
function load_raster()
    # Package test data

    # datadir = joinpath(dirname(pathof(ConScape)), "..", "data")
    # target_qualities_path = qualities_path = joinpath(datadir, "qualities_sno_2000.asc")

    # User data
    source_qualities_path = joinpath(datadir, "TemperateHSM.tif")
    target_qualities_path = joinpath(datadir, "TemperateHSM_target.tif")

    source_qualities = Raster(source_qualities_path; lazy=true, missingval=NaN)
    target_qualities = Raster(target_qualities_path; lazy=true, missingval=NaN)
    # Here we assume affinities and qualities are the same
    affinities = source_qualities

    st = view(RasterStack((; source_qualities, target_qualities, affinities)), X=10000:12000, Y=10000:12000)
    # Pad the raster border with the buffer size
    return DiskArrays.pad(st, (X=(200, 200), Y=(200, 200)); fill=NaN)
end

# Problem
function batch_problem(;
    nwindows=15,
    buffer=200,
    centersize=16, 
    threaded=true,
)
    ## Define connectivity
    α = 60 / 3000
    # Define a distance transformation
    movement_mode = RandomisedShortestPath(ExpectedCost();
        distance_transformation=x -> exp(-x * α),
        theta=0.5
    )

    # Define measures
    measures = (;
        ch=ConnectedHabitat(),
        betk=Betweenness(QualityAndProximityWeighted()),
    )

    ## Specify the problem
    solver = VectorSolver()
    problem = ConScape.Problem(; movement_mode, measures, solver)
    
    # Specify the windowing pattern
    windowed_problem = ConScape.WindowedProblem(problem; 
        buffer, centersize, threaded
    )

    # Specify the batch job windowing
    datapath = joinpath(datadir, "outputs")
    return BatchProblem(windowed_problem; 
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