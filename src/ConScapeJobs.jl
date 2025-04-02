module ConScapeJobs

using ConScape
using PrecompileTools
using Rasters
using JSON3
using TOML

import DiskArrays
import ArchGDAL

# Scalar reads over the network could take hours, 
# it has to error instead so the batch is killed.
DiskArrays.allowscalar(false)

include("problem.jl")
include("utils.jl")
include("precompile.jl")

end