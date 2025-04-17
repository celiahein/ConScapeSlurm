function settings() 
    # TOML.parsefile(joinpath(@__DIR__, "..", "Settings.toml"))
    df = CSV.read(joinpath(@__DIR__, "../user", "datasets.csv"), DataFrame)
    if length(ARGS) > 0
        dataset_name = ARGS[1]
        filter(df) do row
            row.dataset_name == dataset_name
        end[1, :]
    else
        @warn """
            No ARGS found, using first row of datasets.csv.

            Please specify the dataset name on the command line, e.g. sbatch run.sh dataset_name. 
            This should match a line in the `dataset_name` column of user/datasets.csv
            """
        df[1, :]
    end
end

path()::String = settings()["path"]::String
assessment_path() = joinpath(path(), "assessment.json")
original_assessment_path() = joinpath(path(), "original_assessment.json")
estimates_path() = joinpath(path(), "estimates.json")

function assessment() 
    path = assessment_path() 
    isfile(path) || error("Assessment not found at $path. Did you run assess.sh first?")
    JSON3.read(path, ConScape.NestedAssessment) 
end
function original_assessment() 
    path = original_assessment_path()
    isfile(path) || error("Assessment not found at $path. Did you run assess.sh first?")
    JSON3.read(path, ConScape.NestedAssessment) 
end

function ConScape.assess()
    datadir = ConScapeJobs.path()
    isdir(datadir) || error("Data path $datadir not found, check your datasets.csv file")
    assessment_path = ConScapeJobs.assessment_path()
    original_assessment_path = ConScapeJobs.original_assessment_path()

    println("Loading problem...")
    batch_problem = ConScapeJobs.batch_problem()
    rast = ConScapeJobs.raster()
    println("RasterStack of size $(size(rast)) loaded lazily")

    println("Running ConScape.assess...")
    @time assessment = ConScape.assess(batch_problem, rast; verbose=true)

    JSON3.write(assessment_path, assessment)
    JSON3.write(original_assessment_path, assessment)

    return assessment
end

function raster()
    settings = ConScapeJobs.settings()
    datadir = path()
    source_qualities_path = joinpath(datadir, settings["source_qualities"])
    target_qualities_path = joinpath(datadir, settings["target_qualities"])
    affinities_path = joinpath(datadir, settings["affinities"])
    pad = settings["buffer"]::Int

    # Load rasters lazily
    source_qualities = Raster(source_qualities_path; lazy=true, missingval=NaN)
    target_qualities = Raster(target_qualities_path; lazy=true, missingval=NaN)
    affinities = Raster(affinities_path; lazy=true, missingval=NaN)
    
    # Here we assume affinities and qualities are the same
    st = RasterStack((; source_qualities, target_qualities, affinities))
    # Pad the raster border with the buffer size
    return DiskArrays.pad(st, (X=(pad, pad), Y=(pad, pad)); fill=NaN)
end
    
function batch_problem(;
    nwindows=nothing,
    buffer=nothing,
    centersize=nothing, 
    threaded=true,
)
    # Read window parameters from file if they were not passed in
    datapath = joinpath(path(), "outputs")
    fileinfo = settings()
    buffer = (isnothing(buffer) ? fileinfo["buffer"] : buffer)::Int
    nwindows = (isnothing(nwindows) ? fileinfo["nwindows"] : nwindows)::Int
    centersize = (isnothing(centersize) ? fileinfo["centersize"] : centersize)::Int

    # Specify the windowing pattern
    windowed_problem = ConScape.WindowedProblem(problem(); 
        buffer, centersize, threaded
    )

    # Specify the batch job windowing
    return BatchProblem(windowed_problem; datapath, nwindows)
end