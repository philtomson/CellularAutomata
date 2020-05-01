using Gtk, Gtk.ShortNames, Graphics, Images, Cairo, Colors
 #include("CA.jl")
mutable struct DrawingState
   ca
end

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

win = Gtk.Window("Game of Life")
cnvs = Gtk.Canvas(400,400)

boxH = Gtk.Box(:h)
push!(win, boxH)

boxV = Gtk.Box(:v)
push!(boxH, boxV)
stop_btn = Gtk.Button("stop")
push!(boxV, stop_btn)
reset_btn = Gtk.Button("reset")
push!(boxV, reset_btn)
start_btn = Gtk.Button("start")
push!(boxV, start_btn)
exit_btn = Gtk.Button("exit")
push!(boxV, exit_btn)

push!(boxH, cnvs)

function handle_stop_btn(widget)
   println("CANCEL")
   ca.stopped = true
end

function handle_reset_btn(widget)
   println("RESET")
   ca.reset = true
   ca.stopped = false
end

function handle_start_btn(widget)
   println("START")
   ca.stopped = false
end

function handle_exit_btn(widget)
   println("EXIT")
   exit()
end

Gtk.signal_connect(handle_stop_btn,   stop_btn,  "clicked")
Gtk.signal_connect(handle_reset_btn,  reset_btn, "clicked")
Gtk.signal_connect(handle_start_btn,  start_btn, "clicked")
Gtk.signal_connect(handle_exit_btn,   exit_btn,  "clicked")

Gtk.showall(win)




