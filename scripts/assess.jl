using Pkg
Pkg.instantiate()

import ConScape
import ConScapeJobs

ConScape.assess(ConScapeJobs.batch_problem(), ConScapeJobs.load_raster())