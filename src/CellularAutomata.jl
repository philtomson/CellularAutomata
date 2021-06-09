module CellularAutomata

abstract type CellularAutomaton end
abstract type TwoDimensionalCA <: CellularAutomaton end
abstract type OneDimensionalCA <: CellularAutomaton end

include("lib/CA.jl")
#include("lib/matrix_disp_ex.jl")
include("lib/maze.jl")

export CellularAutomaton, TwoDimensionalCA, MazeRunner, GoL, runit, step
# Write your package code here.
#ca_types = module_types_matching(CAs, CellularAutomaton)
#@show ca_types

#ca = MazeRunnerCA()
#run(ca)

end
