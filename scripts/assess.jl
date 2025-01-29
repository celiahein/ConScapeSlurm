using Pkg
Pkg.instantiate()

import ConScapeJobs
import ConScape

ConScape.assess(ConScapeJobs.batch_problem(), ConScapeJobs.load_raster())