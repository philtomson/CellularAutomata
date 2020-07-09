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


export GoL, MazeRunnerCA#, CA
#2D neighborhoods:
#Von Neumann neighborhood:
VN_Neighborhood    = [(1,0), (-1,0), (0,1), (0,-1)]
#Maze neighborhood has to include current cell
Maze_Neighborhood    = [(0,0), (1,0), (-1,0), (0,1), (0,-1)]
Moore_Neighborhood = vcat(VN_Neighborhood,[(-1,-1), (1,1), (-1,1), (1,-1)])
 #TODO select with a comnmand line arg



get_int_bits(item) = sizeof(item)*8

function init(sz=50)
   println("GoL init")
   state = rand(UInt16, sz, sz)
   state = [ x > 0x8000 for x in state]
   return state
end

function init_with_maze(sz=50)
   println("maze init")
   h=w=Int(floor(sz/2))
   return maze(h,w)
end

#Game of Life
# Conway's Game of Life rules:
# 1.Any live cell with fewer than two live neighbours dies, as if by underpopulation.
# 2.Any live cell with two or three live neighbours lives on to the next generation.
# 3.Any live cell with more than three live neighbours dies, as if by overpopulation.
# 4.Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
mutable struct GoL <: TwoDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
   rule::Array{Int,1}

   function gen_rule(ca::GoL)
      println("gen_rule(ca::GoL) called")
      out_rule = []
      num_entries = 2^length(ca.neighborhood)
      for i in 1:num_entries
         bits = digits(i-1, base=2, pad=length(ca.neighborhood))
         numones = sum(bits)
         if (numones < 2 || numones > 3)
            push!(out_rule, 0)
         else
            push!(out_rule, 1)
         end
      end
      return reverse(out_rule)
   end

   function GoL()
      println("GoL constructor called")
      ca = new(Moore_Neighborhood, init, init(), true)
      @show ca
      ca.rule = gen_rule(ca)
      @show ca.rule
      return ca
   end

end

#Maze solver rules:
# 1. Wall cells (1's) remain walls 
# 2. A Cell surrounded by 3 or 4 wall cells becomes a wall cell
# ... otherwise maintain state
mutable struct MazeRunnerCA <: TwoDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
   rule::Array{Int,1}

   function gen_rule(ca::MazeRunnerCA)
      println("gen_rule(ca::MazeRunnerCA) called")
      out_rule = []
      num_entries = 2^length(ca.neighborhood)
      for i in 1:num_entries
         bits = digits(i-1, base=2, pad=length(ca.neighborhood))
         if bits[1] == 1 #wall (special case - wall stays a wall)
            push!(out_rule, bits[1])
         else
            if (sum(bits[2:end]) >= 3)
               push!(out_rule, 1)
            else
               push!(out_rule, 0)
            end
         end
      end
      return out_rule
   end
   
   function MazeRunnerCA()
      ca = new(Maze_Neighborhood, init_with_maze, init_with_maze(), false)
      ca.rule = gen_rule(ca)
      @show ca.rule
      return ca
   end
end

mutable struct OneD_CA <: OneDimensionalCA
   neighborhood::Array{Tuple{Int64,Int64},1} 
   init_fn::Function
   state
   wrap::Bool
 #next_state::Function
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

function getindex(ca::TwoDimensionalCA, cur_pos)
   idx = 0
   for (i,p) in enumerate(ca.neighborhood)
      if ca.wrap
         safe_pos = mod1.(cur_pos .+ p, size(ca.state))
         #sum += state_matrix[safe_pos...]
         idx += 2^(i-1) * ca.state[safe_pos...]
      else
         pos = cur_pos .+ p
         if (0 < pos[1] < size(ca.state,1)+1) && (0 < pos[2] < size(ca.state,2)+1)
            #sum += ca.state[pos...]
            idx += 2^(i-1) * ca.state[pos...]
         end
      end
   end
   return idx
end



function next_state(ca::TwoDimensionalCA)
   ret_matrix = similar(ca.state)
   for j = 1:size(ca.state,2)
      for i = 1:size(ca.state,2)
         idx = getindex(ca, (i,j)) 
         ret_matrix[i,j] = ca.rule[idx+1]
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
   
   ca = CAs.MazeRunnerCA()
   CAs.run(ca)
end
         
