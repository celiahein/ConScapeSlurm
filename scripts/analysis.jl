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
batch_problem = ConScapeJobs.batch_problem(; threaded=true)
rast = ConScapeJobs.load_raster()



missed = map(window_ranges[notstored]) do rs
    rast[rs...]
end
plot(missed[4])
notstored = .!isdir.(paths)
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
plot(RasterStack(paths[2]))


i = 8
isdir.(paths)
window_ranges = ConScape._window_ranges(batch_problem, rast)[assessment.indices]
window_rast = rast[window_ranges[i]...]
res = RasterStack(paths[i])
plot(res)
plot(window_rast) 
size(res)
size(window_rast) 
wa = assessment.assessments[assessment.indices][i]
RasterStack.(paths)

size(window_rast)
count(>(0), window_rast.target_qualities[201:end-200, 201:end-200])
# window_rast.target_qualities[201:end-200, 201:end-200] .= 0.000001

plot(wrast.qualities)
outputs = ConScape.solve(batch_problem.problem, window_rast; 
    selected_window_indices=wa.indices, mosaic_return=false
)

length(outputs)
plot(outputs[1])
outputs[2].ch
length(outputs)

for (i, o) in enumerate(outputs)
    ismissing(o) || display(plot(o.betk; title=string(i)))
end

M = Rasters.mosaic(sum, outputs)
plot(M)
for batch in 2:assessment.njobs
    @time ConScape.solve(batch_problem, rast, assessment, batch; verbose=true)
end
