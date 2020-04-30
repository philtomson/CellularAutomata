using Gtk, Gtk.ShortNames, Graphics, Images, Cairo, Colors
 #include("CA.jl")

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

win = Gtk.Window("Game of Life")
c = Gtk.Canvas(600,400)

boxH = Gtk.Box(:h)
push!(win, boxH)

boxV = Gtk.Box(:v)
push!(boxH, boxV)
stop_btn = Gtk.Button("stop")
push!(boxV, stop_btn)
reset_btn = Gtk.Button("reset")
push!(boxV, reset_btn)


push!(boxH, c)

 #@guarded draw(c) do widget
 #   ctx = getgc(c)
 ##buf = rand(UInt32,150,150)
 #   buf = expand_matrix(rand(UInt32,50,50), 8)
 ##    image(ctx, CairoRGBSurface(buf), 0, 0, 150,150)
 #   image(ctx, CairoRGBSurface(buf), 0, 0, 400,400)
 #end
 #show(c)
Gtk.showall(win)

function draw_it(cnvs,sz,mult=8)
   @guarded draw(c) do widget
       ctx = getgc(c)
       buf = expand_matrix(rand(UInt32,sz,sz), mult)
       image(ctx, CairoRGBSurface(buf), 0, 0, sz*mult,sz*mult)
   end
end

function draw_state(cnvs, st, mult=8)
   sz = size(st,1)
   @guarded draw(c) do widget
       ctx = getgc(c)
       buf = expand_matrix((st .* 0x8000), mult)
       image(ctx, CairoRGBSurface(buf), 0, 0, sz*mult,sz*mult)
   end
end



#for i in 1:30
#  draw_it(c,50,8)
#  sleep(0.1)
#end

 #for i in 1:1000
 #  global state
 #  if(sum(state) == 0)
 #     println("ALL CELLS DEAD!!!")
 #     break
 #  end
 #  state = next_state(state)
 #  draw_state(c,state,8)
 #  sleep(0.1)
 #end

#subsequent calls to draw will then replace the random image.
#loop with a time delay to create random noise image

