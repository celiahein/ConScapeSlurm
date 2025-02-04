using Pkg
Pkg.activate("ConScapeJobs/")
# Pkg.instantiate()

import ConScape
import ConScapeJobs
using ConScape.Plots
using JSON3

rast = ConScapeJobs.load_raster()
batch_problem = ConScapeJobs.batch_problem()

# summary = ConScape.assess(batch_problem, rast)
# JSON3.write("summary.json", summary)

struct BatchSummary
    shape::Tuple{Int,Int}
    njobs::Int
    max_windows::Int 
    max_allocations::Int 
    window_indices::Vector{Int}
    window_mask::Vector{Bool}
    inner_window_jobs::Vector{Int}
    inner_window_allocations::Vector{Vector{Int}}
    inner_window_counts::Vector{Int}
    inner_window_sizes::Vector{Vector{Tuple{Int,Int}}}
    inner_window_indices::Vector{Vector{Int}}
    inner_window_masks::Vector{Vector{Bool}}
end

summary = JSON3.read("summary.json", BatchSummary)

summary.inner_window_allocations
summary.max_allocations / 1e9
shape = summary.shape
sort(maximum.(filter(!isempty, summary.inner_window_allocations)); rev=true)

# Plots

# compute_size = map(summary.inner_window_sizes) do sizes
#     length(sizes) > 0 ? sum(prod, sizes) : 0
# end
# compute_map = reshape(compute_size, shape)
# job_map = reshape(summary.inner_window_jobs, shape)

# plot(summary.inner_window_jobs)
# heatmap(rotl90(job_map); title="jobs")
# heatmap(rotl90(compute_map); title="compute")


# Find a job with a wide range of window sizes

using Statistics, StatsBase

# Find the most variable batch
stds = map(summary.inner_window_sizes) do ws
    targets = map(last, map(identity, ws))
    # sum(targets) > 1 ? std(filter(!=(0), targets)) : 0.0
end
_, i = findmax(stds)

indices = summary.inner_window_indices[i]
nwindows = min(length(indices), 2Threads.nthreads())
window_indices = sample(indices, nwindows; replace=false)
window_sizes = summary.inner_window_sizes[i]
summary.inner_window_sizes[i][window_indices]
job_ranges = ConScape._window_ranges(batch_problem, rast)[i]
job_rast = rast[job_ranges...]
window_problem = batch_problem.problem

window_ranges = ConScape._window_ranges(window_problem, job_rast)[window_indices[1]]
window_rast = ConScape._get_window_with_zeroed_buffer(window_problem, job_rast, window_ranges)
parent(window_rast.target_qualities)
plot(window_rast)

@time ConScape.solve(window_problem, job_rast; 
    window_indices, window_sizes, verbose=true
)
