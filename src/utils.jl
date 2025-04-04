files() = settings()
settings() = TOML.parsefile(joinpath(@__DIR__, "..", "Settings.toml"))
path()::String = settings()["path"]::String
assessment() = JSON3.read(assessment_path(), ConScape.NestedAssessment) 
original_assessment() = JSON3.read(original_assessment_path(), ConScape.NestedAssessment) 
assessment_path() = joinpath(path(), "assessment.json")
original_assessment_path() = joinpath(path(), "original_assessment.json")
estimates_path() = joinpath(path(), "estimates.json")

function ConScape.assess()
    datadir = ConScapeJobs.path()
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