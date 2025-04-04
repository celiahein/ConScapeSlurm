using Rasters
using ConScape
import ConScapeJobs

datadir = ConScapeJobs.path()

# Load problem and raster
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.raster()
original_assessment = ConScapeJobs.original_assessment()

pad = ConScapeJobs.settings()["buffer"]::Int

# Get all the filepaths that we made raster files for
paths = filter(isdir, ConScape.batch_paths(batch_problem, rast)[original_assessment.indices])
# Create lazy RasterStacks for all of them
stacks = RasterStack.(paths; lazy=true, missingval=NaN)
GC.gc()

inner_qualities = map(ConScape.measures(batch_problem)) do _
    (@view rast.source_qualities[pad+1:end-pad, pad+1:end-pad]) .* 0
end |> RasterStack
filename = joinpath(datadir, "output.tif")
# Start with a zeroed out source_qualities
dest_filenames = write(filename, inner_qualities; 
    options="BIGTIFF" => "YES", # In case its larger than 4GB, but also faster somehow
    chunks=(128, 128), # 128 is faster than 256 and much faster than the default columns
    missingval=NaN,
    force=true, 
)
dest = RasterStack(dest_filenames; lazy=true, missingval=NaN)
# Mosaic
# Some care is needed here, both in making a file that is easy to use later
# and in making the mosaic faster. If we chunk it is much faster because
# Each mosaic only writes to a small area each time, rather than whole columns.
# This will also make reading subsets faster for users of the data.
@time open(dest; write=true) do D
    mosaic!(sum, D, stacks; 
        read=true, # Read every region from disk before the mosaic
        gc=50, # Garbage collect every 50 rasters to control memory
    );
end

# Show the chunk pattern in the output
display(Rasters.eachchunk(dest.ch))