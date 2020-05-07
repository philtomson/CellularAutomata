module CAs
abstract type CellularAutomaton end

include("matrix_disp_ex.jl")
include("maze.jl")


export GoL, CA
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
mutable struct GoL <: CellularAutomaton
   task::Union{Task, Nothing}
   stopped::Bool
   reset::Bool
   neighborhood::Array{Tuple{Int64,Int64},1} 
   state
 #TODO: should have a renderer instead of the renderer having
 # a CA
end

mutable struct CA <: CellularAutomaton
   task::Union{Task, Nothing}
   stopped::Bool
   reset::Bool
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
   next_state::Function
 #TODO: should have a renderer instead of the renderer having
 # a CA
end


CA() = CA(nothing, true, false, Moore_Neighborhood, init(), true,next_state)
   

function CA(fn::Function)
   init_fn_name = Symbol(fn)
   nbrhood, ns_fn, wrap = if init_fn_name == :init
                (Moore_Neigborhood, next_state,true)
             else
                (VN_Neighborhood, next_state_maze,false)
             end
   return CA(nothing, 
             (init_fn_name == :init_with_maze),
             false,
             nbrhood,
             fn,
             fn(),
             wrap,
             ns_fn)
end

function sum_neighbors(ca::CA, cur_pos)
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

# Conway's Game of Life rules:
#    Any live cell with fewer than two live neighbours dies, as if by underpopulation.
#   Any live cell with two or three live neighbours lives on to the next generation.
#   Any live cell with more than three live neighbours dies, as if by overpopulation.
#   Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

function next_state_maze(ca::CA)
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

function next_state(ca::CA)
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

function step(ca::CA)
   ca.state = ca.next_state(ca)
end


function run(ca::CA)
   draw_er = CARenderer(ca)
   runit(draw_er)
 end

end #module
if abspath(PROGRAM_FILE) == @__FILE__
   using .CAs
   ca = CAs.CA(CAs.init_with_maze)
   CAs.run(ca)

end
         
