module ConScapeSlurm

using ConScape
using PrecompileTools
using Rasters
using JSON3
using DataFrames

import DiskArrays
import ArchGDAL
import CSV

# Scalar reads over the network could take hours, 
# it has to error instead so the batch is killed.
DiskArrays.allowscalar(false)

include("../user/problem.jl")
include("utils.jl")
include("precompile.jl")

end
