function module_types_matching(modname, typ::DataType)
   list = String[]
   for nm in names(modname)
      @show nm
      @show modname
      if typeof(eval(nm)) != Module
         supertype(eval(nm)) == typ && push!(list,string(nm))
      end 
   end
   return list
end

module CAs
abstract type CellularAutomaton end
abstract type TwoDimensionalCA <: CellularAutomaton end
abstract type OneDimensionalCA <: CellularAutomaton end

include("matrix_disp_ex.jl")
include("maze.jl")


export GoL, MazeRunnerCA, CA
#2D neighborhoods:
#Von Neumann neighborhood:
VN_Neighborhood    = [(1,0), (-1,0), (0,1), (0,-1)]
Moore_Neighborhood = vcat(VN_Neighborhood,[(-1,-1), (1,1), (-1,1), (1,-1)])
 #TODO select with a comnmand line arg
 #neighborhood = Moore_Neighborhood

get_int_bits(item) = sizeof(item)*8

function init(sz=50)
   state = rand(UInt16, sz, sz)
   state = [ x > 0x8000 for x in state]
   return state
end

function init_with_maze(sz=50)
   h=w=Int(floor(sz/2))
   return maze(h,w)
end

#Game of Life
mutable struct GoL <: TwoDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
   #next_state::Function
end

GoL() = GoL(Moore_Neighborhood, init, init(), true)

mutable struct CA <: TwoDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
  #next_state::Function
end

mutable struct MazeRunnerCA <: TwoDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
 #next_state::Function
end

MazeRunnerCA() = MazeRunnerCA(VN_Neighborhood, init_with_maze, init_with_maze(), false)

 #TwoArityOneDimNeighborhood = [

mutable struct OneD_CA <: OneDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
 #next_state::Function
end


CA() = CA(nothing, true, false, Moore_Neighborhood, init(), true)
   

function CA(fn::Function)
   init_fn_name = Symbol(fn)
   nbrhood, ns_fn, wrap = if init_fn_name == :init
                (Moore_Neigborhood, next_state,true)
             else
                (VN_Neighborhood, next_state_maze,false)
             end
   return CA(nbrhood,
             fn,
             fn(),
             wrap
             )
end

function sum_neighbors(ca::TwoDimensionalCA, cur_pos)
   state_matrix = ca.state
   nhood = ca.neighborhood
   sum = 0
   for p in nhood
      if ca.wrap
         safe_pos = mod1.(cur_pos .+ p, size(state_matrix))
         sum += state_matrix[safe_pos...]
      else
         pos = cur_pos .+ p
         if (0 < pos[1] < size(ca.state,1)+1) && (0 < pos[2] < size(ca.state,2)+1)
            sum += state_matrix[pos...]
         end
      end
   end

   return sum
end



#Maze solver rules:
# 1. Wall cells (1's) remain walls 
# 2. A Cell surrounded by 3 or 4 wall cells becomes a wall cell
# ... otherwise maintain state

function next_state(ca::MazeRunnerCA)
   ret_matrix = similar(ca.state)
   for j = 1:size(ca.state,2)
      for i = 1:size(ca.state,2)
         ns = sum_neighbors(ca, (i,j)) 
         if(ca.state[i,j] > 0 ) #WALL
            ret_matrix[i,j] = (ca.state[i,j])
         else #FREE CELL
            if(ns < 3)
               ret_matrix[i,j] = 0
            elseif(ns == 3 || ns == 4)
               ret_matrix[i,j] = 1
            end
         end
      end
    end
    return ret_matrix
end

# Conway's Game of Life rules:
# 1.Any live cell with fewer than two live neighbours dies, as if by underpopulation.
# 2.Any live cell with two or three live neighbours lives on to the next generation.
# 3.Any live cell with more than three live neighbours dies, as if by overpopulation.
# 4.Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

function next_state(ca::TwoDimensionalCA)
   ret_matrix = similar(ca.state)
   for j = 1:size(ca.state,2)
      for i = 1:size(ca.state,2)
         ns = sum_neighbors(ca, (i,j)) 
         if(ca.state[i,j] > 0 )
            if( ns < 2 || ns > 3)
               ret_matrix[i,j] = 0
            else 
               ret_matrix[i,j] = (ca.state[i,j])
            end
         else #currently dead
            if(ns == 3)
               ret_matrix[i,j] = 1
            else
               ret_matrix[i,j] = (ca.state[i,j])
            end
         end
      end
    end
    return ret_matrix
end

function step(ca::CellularAutomaton)
   ca.state = next_state(ca)
end


function run(ca::TwoDimensionalCA)
   draw_er = CARenderer(ca, [GoL, MazeRunnerCA] )
   runit(draw_er)
 end

end #module
if abspath(PROGRAM_FILE) == @__FILE__
   using .CAs
   ca_types = module_types_matching(CAs, CAs.CellularAutomaton)
   @show ca_types
   
   #ca = CAs.MazeRunnerCA(CAs.init_with_maze)
   ca = CAs.MazeRunnerCA()
   CAs.run(ca)
end
         
