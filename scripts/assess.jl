using Pkg
Pkg.activate("ConScapeJobs/")
# Pkg.instantiate()

import ConScape
import ConScapeJobs
using ConScape.Plots
using JSON3
using GLM
using SparseArrays

batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()
length(ConScape._window_ranges(batch_problem, rast))

bs = ConScape.assess(batch_problem, rast)
JSON3.write("bs.json", bs)

struct NestedAssessment
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
function Base.show(io::IO, mime::MIME"text/plain", bs::BatchSummary)
    println(io, "NestedAssessment")
    println(io)
    println(io, "Number of jobs: $(bs.njobs)")
    println(io, "Maximum windows in a job: $(bs.max_windows)")
    println(io, "Required memory: $(bs.max_allocations)")
    # Use SparseArrays nice matrix printing for the mask
    mask = sparse(reshape(bs.window_mask, bs.shape))
    println(io, "Job mask: ")
    Base.print_array(io, mask)
end

# summary = JSON3.read("summary.json", NestedAssesment)

bs.inner_window_allocations
bs.max_allocations / 1e9
shape = bs.shape
sort(maximum.(filter(!isempty, bs.inner_window_allocations)); rev=true)

# Plots

# compute_size = map(bs.inner_window_sizes) do sizes
#     length(sizes) > 0 ? sum(prod, sizes) : 0
# end
# compute_map = reshape(compute_size, shape)
# job_map = reshape(bs.inner_window_jobs, shape)

# plot(bs.inner_window_jobs)
# heatmap(rotl90(job_map); title="jobs")
# heatmap(rotl90(compute_map); title="compute")


# Find a job with a wide range of window sizes

using Statistics, StatsBase

# How many windows to run for timing analysis
nwindows = 4Threads.nthreads()
# Find the most variable batch with nwindows or more
stds = map(bs.inner_window_sizes) do ws
    targets = map(last, ws)
    @show targets
    x = count(>(0), targets) > nwindows ? std(filter(!=(0), targets)) : 0.0
    isnan(x) ? 0.0 : x
end
_, i = findmax(stds)

indices = bs.inner_window_indices[i]
window_indices = sample(indices, nwindows; replace=false)
window_sizes = bs.inner_window_sizes[i]
bs.inner_window_sizes[i][window_indices]
job_ranges = ConScape._window_ranges(batch_problem, rast)[i]
job_rast = rast[job_ranges...]
window_problem = batch_problem.problem

window_ranges = ConScape._window_ranges(window_problem, job_rast)[window_indices[1]]
window_rast = ConScape._get_window_with_zeroed_buffer(window_problem, job_rast, window_ranges)
parent(window_rast.target_qualities)
plot(window_rast)

results = ConScape.solve(window_problem, job_rast; 
    window_indices, window_sizes, verbose=true, timed=true
)

sizes = window_sizes[map(last, results.window_elapsed)]
lengths = prod.(sizes) / 1e6
rows = first.(sizes) / 1e6
cols = last.(sizes) / 1e6
times = map(first, results.window_elapsed)
data = (; lengths, rows, cols, times)
model = lm(@formula(times ~ rows * cols), data)

plot(rows, cols, times; label="data")
plot!(rows, cols, predict(model, data); label="predictions")
compute_times = map(bs.inner_window_sizes) do sizes
    data = (; rows=first.(sizes) ./ 1e6, cols=last.(sizes) ./ 1e6)
    if length(sizes) > 0
        sum(predict(model, data))
    else
        0.0
    end
end

sort!(collect(filter(x -> x[2] > 0, pairs(compute_times))); by=last)

sum(filter(x -> first(x) > 0, compute_times)) # 2.7187976296927966e7 for 21, 4.206030073641315e7 for 10, 2.9489153255297504e7 for 16


heatmap(rotl90(reshape(compute_times, bs.shape)))

histogram(filter(!=(0), compute_times) / 8 / 3600; bins=20)
