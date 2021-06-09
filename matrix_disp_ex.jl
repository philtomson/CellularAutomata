using Gtk, Gtk.ShortNames, Graphics, Images, Cairo, Colors
import Base.push!
include("src/CellularAutomata.jl")
mutable struct BiStateButton
   btn::Gtk.Button
   init_text::String
   clicked_text::String
   clicked::Bool
end

BiStateButton(init_txt::String, clicked_txt::String) =
   BiStateButton(Gtk.Button(init_txt), init_txt, clicked_txt, false)

Base.push!(box::GtkBoxLeaf, btn::BiStateButton) = Base.push!(box, btn.btn)

function expand_matrix(m, x)
   dims = size(m)
   ret_buf = zeros(UInt32,dims[1]*x, dims[2]*x)
   for i in 1:dims[1]
      for j in 1:dims[2]
          for ei in (x*i-x+1):x*i
              for ej in (x*j-x+1):x*j
                 ret_buf[ei,ej] = m[i,j]
              end
          end
      end
   end
   return ret_buf
end

 #mutable struct CallBackState
 #  task::Union{Task, Nothing}
 #  stopped::Bool
 #  reset::Bool
 #end

mutable struct CARenderer
   ca::CellularAutomata.CellularAutomaton
   win::GtkWindowLeaf
   canvas::GtkCanvas
   mult::Int #zoom factor
   resume::Condition
   task::Union{Task, Nothing}
   stopped::Bool
   reset::Bool
end

function CARenderer(ca::CellularAutomata.CellularAutomaton, ca_choices=[], mult=8)
   resume = Condition()
   task = @task callbackInner(state)
   win = Gtk.Window("Cellular Automata")
   h,w = size(ca.state)
   cnvs = Gtk.Canvas(h*mult,w*mult)
   boxH = Gtk.Box(:h)
   push!(win, boxH)

   boxV = Gtk.Box(:v)
   push!(boxH, boxV)
   start_stop_btn = BiStateButton("start","stop")
   push!(boxV, start_stop_btn)
   reset_btn = Gtk.Button("reset")
   push!(boxV, reset_btn)
   
   step_btn = Gtk.Button("step")
   push!(boxV, step_btn)
   gol_btn  = BiStateButton("GoL", "MazeRunner")
   push!(boxV, gol_btn)

   exit_btn = Gtk.Button("exit")
   push!(boxV, exit_btn)
 # TODO: change to using ComboBox (tried, but it never triggered)
 #   cb = GtkComboBoxText()
 #  for choice in ca_choices
 #     push!(cb, string(choice))
 #  end
 #  set_gtk_property!(cb, :active, 1)

   renderer = CARenderer(ca, win, cnvs, mult, resume, nothing, true, false)
   renderer.task = @task runit(renderer, state)


 #  push!(boxV, cb)
   push!(boxH, cnvs)
   function handle_start_stop_btn(widget)
      if(start_stop_btn.clicked)
         start_stop_btn.clicked = false
         set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.init_text)
         renderer.stopped = true
         println("STOP")
      else
         println("START")
         renderer.stopped = false
         notify(resume)
         start_stop_btn.clicked = true
         set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.clicked_text)
      end
   end

   function handle_gol_btn(widget)
      @show gol_btn.clicked
      if(gol_btn.clicked)
         gol_btn.clicked = false
         println("choose MazeRunner")
         set_gtk_property!(gol_btn.btn, :label, String, gol_btn.init_text)
         renderer.stopped = true
         renderer.ca  = MazeRunnerCA()
         draw_state(renderer)
         println("...after drawstate MazeRunner...")
         set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.init_text)
         start_stop_btn.clicked = false
         set_gtk_property!(win, :title, String, "Running MazeRunner")
      else
         set_gtk_property!(gol_btn.btn, :label, String, gol_btn.clicked_text)
         renderer.stopped = true
         gol_btn.clicked = true
         renderer.ca  = GoL()
         draw_state(renderer)
         println("choose GoL")
         set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.init_text)
         set_gtk_property!(win, :title, String, "Running GoL")
         start_stop_btn.clicked = false
      end
   end

   function handle_reset_btn(widget)
      println("RESET")
      #draw_state(renderer)
      renderer.reset = true
      renderer.stopped = true
      # since reset should put the ca into a stopped state:
      start_stop_btn.clicked = false
      set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.init_text)
      notify(resume) #what if it's not stopped?
   end

   function handle_step_btn(widget)
      println("STEP")
      renderer.stopped = true
      step(renderer.ca)
      draw_state(renderer)
   end

 #   function handle_combobox(widget)
 #     idx = get_gtk_proprty(cb, "active", Int)
 #     println("combobox selects: $idx")
 #     renderer.ca  = (ca_choices[(idx+1)])()
 #     renderer.stopped = true
 #     draw_state(renderer)
 #  end

   function handle_exit_btn(widget)
      println("EXIT")
      exit()
   end

   Gtk.signal_connect(handle_start_stop_btn, start_stop_btn.btn,  "clicked")
   Gtk.signal_connect(handle_reset_btn, reset_btn,"clicked")
   Gtk.signal_connect(handle_step_btn,  step_btn, "clicked")
   Gtk.signal_connect(handle_exit_btn,  exit_btn, "clicked")
   Gtk.signal_connect(handle_gol_btn,   gol_btn.btn,  "clicked")
 #  Gtk.signal_connect(handle_combobox,  cb,       "changed")

   Gtk.showall(win)
   schedule(renderer.task)
   return renderer
end

function draw_state(this::CARenderer)
   sz = size(this.ca.state,1)
   mult = this.mult
   @guarded draw(this.canvas) do widget
       ctx = getgc(this.canvas)
       buf = expand_matrix((this.ca.state .* 0x8000), mult)
       image(ctx, CairoRGBSurface(buf), 0, 0, sz*mult,sz*mult)
   end
end

function run(ca::CellularAutomata.TwoDimensionalCA)
   draw_er = CARenderer(ca, [CellularAutomata.GoL, CellularAutomata.MazeRunnerCA] )
   runit(draw_er)
 end

function runit(this::CARenderer )
   draw_state(this)
   while true
      draw_state(this)
      if(this.reset)
         println("runit: this.reset is true")
         this.reset = false
         this.ca.state = this.ca.init_fn()
         draw_state(this)
      end
      if this.stopped
         println("suspending for now...")
         wait(this.resume)
         println("... back after wait")
      end
      if(sum(this.ca.state) == 0)
         println("ALL CELLS DEAD!!!")
         this.stopped = true

      end
      CellularAutomata.step(this.ca)
      sleep(0.01)
   end
end




