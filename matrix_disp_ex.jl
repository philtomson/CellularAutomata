using Gtk, Gtk.ShortNames, Graphics, Images, Cairo, Colors
 #include("CA.jl")
import Base.push!
mutable struct BiStateButton
   btn::Gtk.ToggleButton
   init_text::String
   clicked_text::String
   clicked::Bool

end

BiStateButton(init_txt::String, clicked_txt::String) =
   BiStateButton(Gtk.ToggleButton(init_txt), init_txt, clicked_txt, false)

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
   ca::CellularAutomaton
   win::GtkWindowLeaf
   canvas::GtkCanvas
   mult::Int #zoom factor
   resume::Condition
   task::Union{Task, Nothing}
   stopped::Bool
   reset::Bool
end

function CARenderer(ca::CellularAutomaton, mult=8)
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
   exit_btn = Gtk.Button("exit")
   push!(boxV, exit_btn)
   push!(boxH, cnvs)
   renderer = CARenderer(ca, win, cnvs, mult, resume, nothing, true, false)
   renderer.task = @task runit(renderer, state)
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

   function handle_exit_btn(widget)
      println("EXIT")
      exit()
   end

   Gtk.signal_connect(handle_start_stop_btn, start_stop_btn.btn,  "clicked")
   Gtk.signal_connect(handle_reset_btn, reset_btn, "clicked")
   Gtk.signal_connect(handle_exit_btn,  exit_btn,  "clicked")

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

function runit(this::CARenderer )
   draw_state(this)
   while true
      draw_state(this)
      if(this.reset)
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
         break
      end
      step(this.ca)
      sleep(0.01)
   end
end




