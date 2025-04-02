# Problem definition

# This is the only code you need to edit
function problem()
    ## Define connectivity
    α = 60 / 3000
    # Define a distance transformation
    movement_mode = RandomisedShortestPath(ExpectedCost();
        distance_transformation=x -> exp(-x * α),
        theta=0.5
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