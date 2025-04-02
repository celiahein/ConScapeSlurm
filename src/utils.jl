files() = TOML.parsefile(joinpath(@__DIR__, "..", "Files.toml"))
path()::String = files()["path"]::String
assessment() = JSON3.read(joinpath(path(), "assessment.json"), ConScape.NestedAssessment) 

function ConScape.assess()
    datadir = ConScapeJobs.path()

    println("Loading problem...")
    batch_problem = ConScapeJobs.batch_problem()
    rast = ConScapeJobs.raster()
    println("RasterStack of size $(size(rast)) loaded lazily")

    assessment_path = joinpath(datadir, "assessment.json")
    original_assessment_path = joinpath(datadir, "original_assessment.json")

    println("Running ConScape.assess...")
    @time assessment = ConScape.assess(batch_problem, rast; verbose=true)

    JSON3.write(assessment_path, assessment)
    JSON3.write(original_assessment_path, assessment)

    return assessment
end

function raster()
    fileinfo = files()
    datadir = path()
    source_qualities_path = joinpath(datadir, fileinfo["source_qualities"])
    target_qualities_path = joinpath(datadir, fileinfo["target_qualities"])
    affinities_path = joinpath(datadir, fileinfo["affinities"])
    pad = fileinfo["buffer"]::Int

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
    fileinfo = files()
    buffer = (isnothing(buffer) ? fileinfo["buffer"] : buffer)::Int
    nwindows = (isnothing(nwindows) ? fileinfo["nwindows"] : nwindows)::Int
    centersize = (isnothing(centersize) ? fileinfo["centersize"] : centersize)::Int

    # Specify the windowing pattern
    windowed_problem = ConScape.WindowedProblem(problem(); 
        buffer, centersize, threaded
    )

    # Specify the batch job windowing
    datapath = joinpath(path(), "outputs")
    return BatchProblem(windowed_problem; 
        datapath, nwindows
    )
end