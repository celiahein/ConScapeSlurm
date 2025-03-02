##################
# Batch Assessment
##################

# It is reccomended to run this script as a SLURM batch using `sbatch assess.sh`
# Then, run over the script interactively to view plots and assessment details as needed.

# All heavy computations are stored to JSON files and skpped if the files are found, 
# so using this script on the login node is ok IF it has already been run with `sbatch`

#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# DO NOT run this scripts in login nodes without running with `sbatch assess.sh` first.
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

println("Starting ConScape assessment on $(Threads.nthreads()) cores...")
println("Loading packages...")

using Pkg
# using Revise
# Pkg.activate("ConScapeJobs/") # May be needed in interactive use
# Pkg.instantiate() 
using ConScape
using ConScapeJobs
using JSON3
using GLM
using Statistics
using StatsBase
using SparseArrays
using UnicodePlots

datadir = ConScapeJobs.datadir

println("Loading problem...")
batch_problem = ConScapeJobs.batch_problem()
rast = ConScapeJobs.load_raster()

println("RasterStack of size $(size(rast)) loaded lazily")

assessment_json = joinpath(datadir, "assessment.json")
original_assessment_json = joinpath(datadir, "original_assessment.json")
if isfile(assessment_json)
    assessment = JSON3.read(assessment_json, ConScape.NestedAssessment)
    original_assessment = JSON3.read(original_assessment_json, ConScape.NestedAssessment)
else
    println("Running assess...")
    @time assessment = ConScape.assess(batch_problem, rast; verbose=true)
    JSON3.write(assessment_json, assessment)
    JSON3.write(original_assessment_json, assessment)
end

###
# Find a job with a wide range of window sizes

function sample_performance(batch_problem, rast, a::ConScape.NestedAssessment;
    nwindows=16, nbatches=10,
) 
    a = assessment
    jobs = map(wa -> wa.njobs, a.assessments[a.indices])
    x, i = findmax(jobs)
    window_indices = map(x -> x.indices, a.assessments)
    all_grid_sizes = map(x -> x.grid_sizes, a.assessments)
    allocations = @allocated ConScape.init(batch_problem, rast, i; 
        verbose=true, batch_indices=a.indices, window_indices, grid_sizes=all_grid_sizes
    )
    allocations / 1e6
    # How many windows to run for timing analysis
    # Find the most variable batch with nwindows or more
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
    selected_batch_ranges = ConScape._window_ranges(batch_problem, rast)[selected_batch]
    batch_rast = rast[selected_batch_ranges...]
    window_problem = batch_problem.problem
    wrs = ConScape._window_ranges(window_problem, batch_rast)[indices]
    workspace = ConScape.init(window_problem, batch_rast; 
        selected_window_indices, grid_sizes, verbose=true,
    );
    results = ConScape.solve!(workspace, window_problem; 
        verbose=false, timed=true
    )

    # max_sizes = map(x -> length(x) > 0 ? maximum(prod, x) : 0, inner_window_sizes)
    sizes = grid_sizes[selected_window_indices]
    lengths = prod.(sizes) / 1e6 # divide by 1e6 just for numerical stability
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

estimates_json = joinpath(datadir, "estimates.json")
if isfile(estimates_json)
    estimates = JSON3.read(estimates_json, NamedTuple)
else
    println("Estimates run-time and memory use...")
    estimates = sample_performance(batch_problem, rast, assessment)
    JSON3.write(estimates_json, estimates)
end

# println("Generating plots")
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

assessment

# Trouble shooting after run

# Show all original jobs
# original_assessment
# Current status
# reassessment = ConScape.reassess(batch_problem, original_assessment)
# For a second round of batches for failed SLURM jobs, uncomment and run this line
# which replaces the job assessment with the reassment - removing completed jobs:

# JSON3.write(assessment_json, reassessment)
# assessment = JSON3.read(assessment_json, ConScape.NestedAssessment)

# After that you can launch run_job.sh with --array=0-[reassessment.njobs-1] - renumbered from 0