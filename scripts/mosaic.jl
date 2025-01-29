import ConScapeJobs
using Rasters

output_raster = mosaic(ConScapeJobs.batch_problem())
write("../data/output.nc", output_raster)
