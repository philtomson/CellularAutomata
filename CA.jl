include("matrix_disp_ex.jl")
global state

#Von Neumann neighborhood:
VN_Neighborhood    = [(1,0), (-1,0), (0,1), (0,-1)]
Moore_Neighborhood = vcat(VN_Neighborhood,[(-1,-1), (1,1), (-1,1), (1,-1)])
 #TODO select with a comnmand line arg
neighborhood = Moore_Neighborhood

get_int_bits(item) = sizeof(item)*8

function init(sz=50)
   state = rand(UInt16, sz, sz)
   state = [ x > 0x8000 for x in state]
   return state
end

mutable struct CA
   task::Union{Task, Nothing}
   stopped::Bool
   reset::Bool
   neighborhood 
   state
 #TODO: should have a renderer instead of the renderer having
 # a CA
end

CA() = CA(nothing, false, false, Moore_Neighborhood, init())
   


function sum_neighbors(state_matrix, cur_pos, nhood=neighborhood)
   sum = 0
   for p in nhood
      safe_pos = mod1.(cur_pos .+ p, size(state_matrix))
      sum += state_matrix[safe_pos...]
   end

   return sum
end

# Conway's Game of Life rules:
#    Any live cell with fewer than two live neighbours dies, as if by underpopulation.
#   Any live cell with two or three live neighbours lives on to the next generation.
#   Any live cell with more than three live neighbours dies, as if by overpopulation.
#   Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.

function next_state(state_matrix)
   ret_matrix = similar(state_matrix)
   for j = 1:size(state_matrix,2)
      for i = 1:size(state_matrix,2)
         ns = sum_neighbors(state_matrix, (i,j)) 
         if(state_matrix[i,j] > 0 )
            if( ns < 2 || ns > 3)
               ret_matrix[i,j] = 0
            else 
               ret_matrix[i,j] = (state_matrix[i,j])
            end
         else #currently dead
            if(ns == 3)
               ret_matrix[i,j] = 1
            else
               ret_matrix[i,j] = (state_matrix[i,j])
            end
         end
      end
    end
    return ret_matrix
end


function run(ca::CA)
   draw_er = DrawingState(ca)
   while true
      if(ca.reset)
         ca.reset = false
         ca.state = init()
      end
      if(sum(ca.state) == 0)
         println("ALL CELLS DEAD!!!")
         break
      end
      if(!ca.stopped)
         ca.state = next_state(ca.state)
         draw_state(draw_er)
      end
      sleep(0.1)
   end
 end

ca = CA()
run(ca)
         
