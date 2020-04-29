include("matrix_disp_ex.jl")
global state
#Von Neumann neighborhood:
VN_Neighborhood    = [(1,0), (-1,0), (0,1), (0,-1)]
Moore_Neighborhood = vcat(VN_Neighborhood,[(-1,-1), (1,1), (-1,1), (1,-1)])
 #TODO select with a comnmand line arg
neighborhood = Moore_Neighborhood

get_int_bits(item) = sizeof(item)*8


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

state = rand(UInt16, 50, 50)
state = [ x > 0x8000 for x in state]

 #display(state)
 #for i in 1:10
 #  global state
 #  state = next_state(state)         
 #  display(state)
 #end

for i in 1:1000
   global state
   if(sum(state) == 0)
      println("ALL CELLS DEAD!!!")
      break
   end
   state = next_state(state)
   draw_state(c,state,8)
   sleep(0.1)
end

         
