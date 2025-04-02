using Rasters
using ConScape
import ConScapeJobs

datadir = ConScapeJobs.files()["path"]

# Load problem and raster
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.raster()
assessment = ConScapeJobs.assessment()

# Get all the filepaths that we made raster files for
paths = filter(isdir, ConScape.batch_paths(batch_problem, rast)[assessment.indices])
# Create lazy RasterStacks for all of them
stacks = RasterStack.(paths[1:10]; lazy=true, missingval=NaN)
filename = joinpath(datadir, "output.tif")
GC.gc()

# Mosaic
# Some care is needed here, both in making a file that is easy to use later
# and in making the mosaic faster. If we chunk it is much faster because
# Each mosaic only writes to a small area each time, rather than whole columns.
# This will also make reading subsets faster for users of the data.
@time combined = mosaic(sum, stacks; 
    to=rast,
    filename, # Mosaic to disk
    force=true, # Force overwriting existing files
    read=true, # Read every region from disk before the mosaic
    gc=50, # Garbage collect every 50 rasters to control memory
    missingval=NaN, # Keep it the same for everything
    chunks=(128, 128), # 128 is faster than 256 and much faster than the default columns
    options="BIGTIFF" => "YES", # In case its larger than 4GB, but also faster somehow
);

# Show the chunk pattern in the output
display(Rasters.eachchunk(combined.ch))