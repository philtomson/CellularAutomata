# Cellular Automata in Julia and Gtk

This is a code doodle where I'm playing with using Julia to create a Cellular Automata GUI with Gtk.jl. 

To run:

> $  julia -i CA.jl

There are two CAs defined here: 

1. Conway's Game of Life (GoL button)
2. Maze runner CA (MazeRunner button)

Choosing the latter will generate a maze and then click 'start' to start solving the maze.

# You can solve mazes with a Cellular Automaton

See: https://www.drdobbs.com/database/cellular-automata-for-solving-mazes/184408939

## The gist:

   Walls are 1's in the CA state. Open paths are 0's. Given a valid maze with at least one path
   from entry to exit, the rules for this CA are:

   1. If an open cell is surrounded by 3 or 4 wall cells (1's) it will become a wall cell
      in the next step.
   2. Wall cells remain wall cells.

   That's it. The CA will step with these rules until only the open path remains - at that point it's finished.
