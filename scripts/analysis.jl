nothing
using Pkg, Revise
Pkg.activate("ConScapeJobs/")
using ConScape
using ConScapeJobs
using JSON3
using Plots
using Rasters
Threads.nthreads()

assessment_path = joinpath(ConScapeJobs.datadir, "assessment.json")
assessment = JSON3.read(assessment_path, ConScape.NestedAssessment) 
batch_problem = ConScapeJobs.batch_problem(; threaded=false)
rast = ConScapeJobs.load_raster()

i = assessment.indices[10]
paths = ConScape.batch_paths(batch_problem, rast)[assessment.indices]
isdir.(paths)
# for i in eachindex(paths)
#     path = paths[i]
#     isdir(path) || continue
#     @show path
#     stack1 = RasterStack(path)
#     display(plot(stack1))
# end;

# missed = map(window_ranges[notstored]) do rs
#     rast[rs...]
# end
# plot(missed[4])
# notstored = .!isdir.(paths)

i = 20
wa = assessment.assessments[assessment.indices][i]
window_ranges = ConScape.window_ranges(batch_problem, rast)[assessment.indices]
window_rast = rast[window_ranges[i]...]
# res = RasterStack(paths[i])
# plot(res)
plot(window_rast[(:source_qualities, :target_qualities)]; size=(1200, 800))
# size(res)
# RasterStack.(paths)

size(window_rast)
count(>(0), window_rast.target_qualities[201:end-200, 201:end-200])
# window_rast.target_qualities[201:end-200, 201:end-200] .= 0.000001
wa.indices
outputs3 = ConScape.solve(batch_problem.problem, window_rast; 
    indices=wa.indices, verbose=true
);

plot(outputs3; size=(1200, 800))
M = Rasters.mosaic(sum, outputs3)

rebuild(M; missingval=0.0)

plot(window_rast)
plot(window_rast)
plot(M; size=(1200, 800))
plot(window_rast.target_qualities)

for (i, o) in enumerate(outputs)
    ismissing(o) || display(plot(o; title=string(i)))
end