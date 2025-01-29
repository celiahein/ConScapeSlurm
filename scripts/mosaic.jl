import ConScapeJobs
import ArchGDAL
using Rasters

output_raster = mosaic(ConScapeJobs.batch_problem(); to=ConScapeJobs.load_raster())

write("../data/output.tif", output_raster; force=true)