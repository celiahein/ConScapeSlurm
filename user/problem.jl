# Problem definition

# This is the only code you need to edit
function problem(args...)
    s = settings(args...)
    ## Define connectivity
    alpha = s["alpha"]::Float64
    theta = s["theta"]::Float64
    # Define a distance transformation
    movement_mode = RandomisedShortestPath(ExpectedCost();
        distance_transformation=x -> exp(-x * alpha),
        theta,
    )

    # Define measures
    measures = (;
        ch=ConnectedHabitat(),
        betk=Betweenness(QualityAndProximityWeighted()),
    )

    ## Specify the problem
    solver = VectorSolver()
    problem = ConScape.Problem(; movement_mode, measures, solver)
end