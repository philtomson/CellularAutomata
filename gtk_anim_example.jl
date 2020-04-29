using Gtk
using Dates

global canvasWidget
global state 

mutable struct CallbackState
  task::Union{Task,Nothing}
  cancelled::Bool
  startTime::DateTime
  canvas::GtkCanvas
end

function cancel(state::CallbackState)
  measState.cancelled = true
end

function callback(canvasWidget)
  state = CallbackState(nothing, false, now(), canvasWidget)
  state.task = Task(()->callbackInner(state))
  schedule(state.task)
  return state
end

function callbackInner(state::CallbackState)
    i = 0
    while !state.cancelled
        Gtk.draw(state.canvas)
        
        i+=1
        println("i=$(i)")

        if (now() - state.startTime).value > 10000
          state.cancelled = true
        end
        sleep(0.5)
    end
end


function drawColor(Widget)
    println("color")
    ctx = getgc(Widget)
    h = height(Widget)
    w = width(Widget)
    rectangle(ctx, 0, 0, w, h)
    set_source_rgb(ctx, rand(), rand(), rand())
    fill(ctx)
end

win = Gtk.Window("random colors")

boxV = Gtk.Box(:v)
push!(win,boxV)

button1 = Gtk.Button("change color 5x")
button2 = Gtk.Button("cancel")

function b_handler1(widget)
    println("button1")
    global canvasWidget
    global state
    state = callback(canvasWidget)
end

function b_handler2(widget)
    global state
    state.cancelled = true
end

signal_connect(b_handler1, button1, "clicked")
signal_connect(b_handler2, button2, "clicked")

push!(boxV,button1)
push!(boxV,button2)

canvasWidget = Gtk.Canvas(200,200)
canvasWidget.draw = drawColor
push!(boxV, canvasWidget)

Gtk.showall(win)
