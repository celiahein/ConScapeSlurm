
#############################
# Time and memory estimations
#############################

using ConScape
using ConScapeSlurm
using JSON3
using GLM
using Statistics
using StatsBase
using UnicodePlots
using Plots

datadir = ConScapeSlurm.path()
batch_problem = ConScapeSlurm.batch_problem()
rast = ConScapeSlurm.load_raster()
assessment = ConScape.assessment()

###
# Find a job with a wide range of window sizes, and run a subset

function sample_performance(batch_problem, rast, a::ConScape.NestedAssessment;
    nwindows=16, nbatches=10,
) 
    a = assessment
    jobs = map(wa -> wa.njobs, a.assessments[a.indices])
    x, i = findmax(jobs)
    allocations = @allocated init(batch_problem, rast, assessment, i; verbose=true)
    allocations / 1e6
    # How many windows to run for timing analysis
    # Find the most variable batch with nwindows or more
    all_grid_sizes = map(x -> x.grid_sizes, a.assessments)
    stds = map(all_grid_sizes) do sizes
        length(sizes) > 0 || return 0.0
        targets = map(last, sizes)
        count(>(0), targets) > nwindows || return 0.0
        x = std(filter(!=(0), targets))
        isnan(x) ? 0.0 : x
    end
    _, selected_batch = findmax(stds)
    indices = a.assessments[selected_batch].indices
    selected_window_indices = sample(indices, nwindows; replace=false)
    grid_sizes = all_grid_sizes[selected_batch]
    selected_batch_ranges = ConScape.window_ranges(batch_problem, rast)[selected_batch]
    batch_rast = rast[selected_batch_ranges...]
    window_problem = batch_problem.problem
    workspace = ConScape.init(window_problem, batch_rast; 
        indices=selected_window_indices, grid_sizes, verbose=true
    );
    results = ConScape.solve(workspace; verbose=false, timed=true)

    # max_sizes = map(x -> length(x) > 0 ? maximum(prod, x) : 0, inner_window_sizes)
    sizes = grid_sizes[selected_window_indices]
    lengths = prod.(sizes) / 1e6 # divide by 1e6 just for numerical stability
    @show keys(results)
    times = map(first, results.window_elapsed)
    data = (; lengths, times)
    model = lm(@formula(times ~ lengths), data)

    compute_estimates = map(all_grid_sizes) do grid_sizes
        if length(grid_sizes) > 0
            data = (; lengths=prod.(grid_sizes) ./ 1e6)
            sum(predict(model, data))
        else
            0.0
        end
    end
    inds = assessment.indices
    total_estimate = sum(compute_estimates)
    batchsize = ceil(Int, length(inds) / nbatches)
    compute_sorted_indices = last.(sort(compute_estimates[inds] .=> inds; rev=true))
    batch_estimates = map(1:nbatches) do n
        largest = (n - 1) * batchsize + 1
        compute_estimates[compute_sorted_indices][largest]
    end
    
    return (; 
        sizes,
        lengths,
        times,
        compute_estimates,
        nbatches,
        batchsize,
        batch_estimates,
        total_estimate,
        allocations,
    )
end

println("Estimating run-time and memory use...")
estimates = sample_performance(batch_problem, rast, assessment)
JSON3.write(ConScapeSlurm.estimates_path(), estimates)

estimates.total_estimate # 2.7e7 for 21, 4.2e7 for 10, 2.95e7/3.3e7 for 16
estimates.allocations / 1e9

nthreads = 4
c = UnicodePlots.heatmap(replace(rotl90(reshape(estimates.compute_estimates, assessment.shape) ./ 60 ./ nthreads), 0.0 => NaN);
    title="Estimated compute minutes ($nthreads core)",
    width=40,
)

h = UnicodePlots.histogram(estimates.compute_estimates[assessment.mask] ./ 60 ./ nthreads; 
    nbins=20,
    xlabel="jobs",
    ylabel="minutes",
    title="Batch computation times ($nthreads core)"
)

display(assessment)
display(c)
display(h)