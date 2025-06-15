# Precompile the ConScape problem so this happens once,
# rather than at the start of every slurm job
@compile_workload begin
    df = CSV.read(datasets_csv_path(), DataFrame)
    name = df[1, 1]
    checkdatasets(df, name)
    # Subset a small raster
    full_rast = raster(name)
    # Get a chunk from the middle of the raster that has values
    ranges = map(size(full_rast)) do s
        a = div(s, 2) 
        max(a - 2050, 1):min(a - 2000, s)
    end
    rast = full_rast[ranges...]
    bp = batch_problem(name;
        nwindows=1,
        buffer=10, 
        centersize=5, 
    ) 
    assessment = assess(bp, rast)
    batch_init = init(bp, rast, assessment; verbose=true)
    solve(batch_init, 1; verbose=true)
end
