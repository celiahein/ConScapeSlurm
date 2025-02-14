println("Loading packages...")
using Pkg
# Pkg.activate("ConScapeJobs/")
Pkg.instantiate() 
using ConScape
using ConScapeJobs
using ConScape.Plots
using JSON3
using GLM
using Statistics
using StatsBase
using SparseArrays

println("Loading problem...")
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()

assessment_json = "assessment.json"
if isfile(assessment_json)
    assessment = JSON3.read(assessment_json, ConScape.NestedAssessment)
else
    println("Running assess...")
    @time assessment = ConScape.assess(batch_problem, rast; verbose=false)
    JSON3.write(assessment_json, assessment)
end


###
# Find a job with a wide range of window sizes


function sample_performance(a::ConScape.NestedAssessment;
    nwindows=16,
    nbatches=10,
) 
    jobs = map(wa -> wa.njobs, a.assessments[a.mask])
    x, i = findmax(jobs)
    allocations = @allocated ConScape.init(batch_problem, rast, i; 
        verbose=true, window_indices=a.indices
    )
    # How many windows to run for timing analysis
    # Find the most variable batch with nwindows or more
    inner_window_sizes = map(ai -> ai.sizes, a.assessments)
    stds = map(inner_window_sizes) do sizes
        targets = map(last, sizes)
        count(>(0), targets) > nwindows || return 0.0
        x = std(filter(!=(0), targets))
        isnan(x) ? 0.0 : x
    end
    _, selected_batch = findmax(stds)
    window_indices = sample(a.assessments[selected_batch].indices, nwindows; replace=false)
    window_sizes = a.assessments[selected_batch].sizes
    job_ranges = ConScape._window_ranges(batch_problem, rast)[selected_batch]
    job_rast = rast[job_ranges...]
    window_problem = batch_problem.problem
    workspace = ConScape.init(window_problem, job_rast; 
        window_indices, window_sizes, verbose=true,
    )
    results = ConScape.solve!(workspace, window_problem; 
        verbose=true, timed=true
    )

    # max_sizes = map(x -> length(x) > 0 ? maximum(prod, x) : 0, inner_window_sizes)
    sizes = window_sizes[map(last, results.window_elapsed)]
    lengths = prod.(sizes) / 1e6 # divide by 1e6 just for numerical stability
    times = map(first, results.window_elapsed)
    data = (; lengths, times)
    model = lm(@formula(times ~ lengths), data)

    compute_estimates = map(inner_window_sizes) do sizes
        data = (; lengths=prod.(sizes) ./ 1e6)
        if length(sizes) > 0
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
        allocations,
        sizes,
        lengths,
        times,
        compute_estimates,
        total_estimate,
        nbatches,
        batchsize,
        batch_estimates,
    )
end

estimates_json = "estimates.json"
if isfile(estimates_json)
    estimates = JSON3.read("estimates.json", NamedTuple)
else
    println("Estimates run-time and memory use...")
    estimates = sample_performance(assessment)
    JSON3.write(estimates_json, estimates)
end

println("Generating plots")
estimates.total_estimate # 2.7e7 for 21, 4.2e7 for 10, 2.95e7/3.3e7 for 16

compute_map = heatmap(rotl90(reshape(estimates.compute_estimates, assessment.shape)))
savefig(compute_map, "compute_map.png")

# sorted_indices = last.(sort(max_sizes[inds] .=> inds; rev=true))
h = histogram(estimates.compute_estimates[assessment.mask] / 60; 
    bins=20,
    xlabel="minutes",
    ylabel="jobs",
    title="Window computations"
)
savefig(h, "compute_hist.png")
# inds = assessment.indices
# compute_sorted_indices = last.(sort(estimates.compute_estimates[inds] .=> inds; rev=true))
# assessment.assessments[assessment.indices[1]]
# @time ConScape.solve(batch_problem, rast, assessment.indices[1],
    # window_indices=assessment.indices, 
    # verbose=true,
# )