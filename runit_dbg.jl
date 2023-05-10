# Debugging has proven to be problematic with the Gtk mainloop
# Run this file (runit_dbg.jl) if debugging
include("./src/CellularAutomata.jl")

function runit(ca::CellularAutomata.TwoDimensionalCA)
   #draw_state(this) #TODO: ASCII renderer 
   while true
      prev_ca_state = copy(ca.state)
      if(sum(ca.state) == 0)
         println("ALL CELLS DEAD!!!")
         return
      end
      CellularAutomata.step(ca)
      if ca.state == prev_ca_state
         @show ca.state
         println("CA has stabilized, exiting")
         return ca.state
      end
   end
end

ca = CellularAutomata.MazeRunnerCA(20)
runit(ca)

