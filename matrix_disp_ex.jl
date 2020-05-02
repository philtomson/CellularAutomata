using Gtk, Gtk.ShortNames, Graphics, Images, Cairo, Colors
 #include("CA.jl")
mutable struct DrawingState
   ca
end

mutable struct BiStateButton
   btn::Gtk.ToggleButton
   init_text::String
   clicked_text::String
   clicked::Bool
end

BiStateButton(init_txt::String, clicked_txt::String) =
   BiStateButton(Gtk.ToggleButton(init_txt), init_txt, clicked_txt, false)

global ca

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

function draw_state(ds::DrawingState, mult=8)
   ca = ds.ca
   sz = size(ds.ca.state,1)
   @guarded draw(cnvs) do widget
       ctx = getgc(cnvs)
       buf = expand_matrix((ds.ca.state .* 0x8000), mult)
       image(ctx, CairoRGBSurface(buf), 0, 0, sz*mult,sz*mult)
   end
end
import Base.push!
Base.push!(box::GtkBoxLeaf, btn::BiStateButton) = Base.push!(box, btn.btn)

win = Gtk.Window("Game of Life")
cnvs = Gtk.Canvas(600,600)

boxH = Gtk.Box(:h)
push!(win, boxH)

boxV = Gtk.Box(:v)
push!(boxH, boxV)
 #stop_btn = Gtk.ToggleButton("stop")
start_stop_btn = BiStateButton("stop", "start")
push!(boxV, start_stop_btn)
reset_btn = Gtk.Button("reset")
push!(boxV, reset_btn)
exit_btn = Gtk.Button("exit")
push!(boxV, exit_btn)

push!(boxH, cnvs)

function handle_start_stop_btn(widget)
   if(start_stop_btn.clicked)
      start_stop_btn.clicked = false
      set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.init_text)
      ca.stopped = false
      println("RESTART")
   else
      println("CANCEL")
      ca.stopped = true
      start_stop_btn.clicked = true
      set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.clicked_text)
   end
end

function handle_reset_btn(widget)
   println("RESET")
   ca.reset = true
   ca.stopped = true
   # since reset should put the ca into a stopped state:
   start_stop_btn.clicked = true
   set_gtk_property!(start_stop_btn.btn, :label, String, start_stop_btn.clicked_text)
end

function handle_exit_btn(widget)
   println("EXIT")
   exit()
end

Gtk.signal_connect(handle_start_stop_btn,   start_stop_btn.btn,  "clicked")
Gtk.signal_connect(handle_reset_btn,  reset_btn, "clicked")
Gtk.signal_connect(handle_exit_btn,   exit_btn,  "clicked")

Gtk.showall(win)




