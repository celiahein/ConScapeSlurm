
bs = JSON3.read("summary.json", ConScape.NestedAssessment)
allocations = reinterpret(Int, read("allocations"))

GB = allocations / 1e9
