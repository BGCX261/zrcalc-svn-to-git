require 'tk'
require 'Parser'

#------------------------------
root = TkRoot.new {
    title 'Calculator'
}

#------------------------------
def about
    info = "Ruby Calculator v0.1\n" +
           "Implemented with Ruby 1.8.6 and Tcl/Tk 8.4.15\n" +
#           "(c) Copyright by \xC1\xFA\xB5\xDA\xBE\xC5\xD7\xD3, 2009\n" +
           "(c) Copyright by 龙第九子, 2009\n" +
           "Contact: physacco@gmail.com"
    Tk.messageBox(
        'type'   => 'ok',
        'icon'   => 'info',
        'title'  => 'About',
        'message'=> info
    )
end

about
exit

menu_spec = [
  [ ['File', 0],
    ['Quit',      proc{exit}]
  ],
  [ ['Help', 0],
    ['About',     proc{about}],
  ]
]
TkMenubar.new(nil, menu_spec, 'tearoff'=>false) {
#    background 'white'
    grid('row'=>0, 'column'=>0)
}

#------------------------------
entry_in = TkEntry.new {
#    insert 0, 'expression'
    font '{Monospace} 10 {bold}'
    grid('row'=>1, 'column'=>0, 'columnspan'=>6, 'ipadx'=>120, 'pady'=>5)
}
#------------------------------
entry_out = TkEntry.new {
#    insert 0, 'result'
    state 'readonly'
    readonlybackground 'white'
    font '{Monospace} 10 {bold}'
    grid('row'=>2, 'column'=>0, 'columnspan'=>4, 'ipadx'=>50, 'pady'=>5)
}
TkButton.new {
    text 'C'
    font '{Monospace} 10 {bold}'
    command proc {
        entry_in.value=''
        entry_out.configure('state'=>'normal')
        entry_out.value=''
        entry_out.configure('state'=>'readonly')
    }
    grid('row'=>2, 'column'=>4, 'ipadx'=>20, 'pady'=>5)
}
bt_compute = TkButton.new {
    text '='
    font '{Monospace} 10 {bold}'
    foreground 'red'
    command proc {
        result = RCalc.calc(entry_in.value)
#        result = parser.parse

#        result = entry_in.value
#        begin
#          result = Kernel.eval(result)
#        rescue Exception => e
#          result = 'Error'
#        end

        entry_out.configure('state'=>'normal')
        entry_out.value=result
        entry_out.configure('state'=>'readonly')
    }
    grid('row'=>2, 'column'=>5, 'ipadx'=>20, 'pady'=>5)
}
# Event binding fro TkEntry entry_in: key event handler for Carriage-Return
entry_in.bind("KeyPress", proc {|event|
    bt_compute.invoke if event.keysym_num == 65293 })
#------------------------------
TkButton.new {
    text '+'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '+') }
    grid('row'=>3, 'column'=>0, 'ipadx'=>20, 'pady'=>5)
}
TkButton.new {
    text '-'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '-') }
    grid('row'=>3, 'column'=>1, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '*'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '*') }
    grid('row'=>3, 'column'=>2, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '/'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '/') }
    grid('row'=>3, 'column'=>3, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '('
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '(') }
    grid('row'=>3, 'column'=>4, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text ')'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, ')') }
    grid('row'=>3, 'column'=>5, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
#------------------------------
TkButton.new {
    text '7'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '7') }
    grid('row'=>4, 'column'=>0, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '8'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '8') }
    grid('row'=>4, 'column'=>1, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '9'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '9') }
    grid('row'=>4, 'column'=>2, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '0'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '0') }
    grid('row'=>4, 'column'=>3, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'sin'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, 'sin') }
    grid('row'=>4, 'column'=>4, 'ipadx'=>12, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'cos'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, 'cos') }
    grid('row'=>4, 'column'=>5, 'ipadx'=>12, 'padx'=>5, 'pady'=>5)
}
#------------------------------
TkButton.new {
    text '3'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '3') }
    grid('row'=>5, 'column'=>0, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '4'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '4') }
    grid('row'=>5, 'column'=>1, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '5'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '5') }
    grid('row'=>5, 'column'=>2, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '6'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '6') }
    grid('row'=>5, 'column'=>3, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'tan'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, 'tan') }
    grid('row'=>5, 'column'=>4, 'ipadx'=>12, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'exp'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '^') }
    grid('row'=>5, 'column'=>5, 'ipadx'=>12, 'padx'=>5, 'pady'=>5)
}
#------------------------------
TkButton.new {
    text '1'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '1') }
    grid('row'=>6, 'column'=>0, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '2'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '2') }
    grid('row'=>6, 'column'=>1, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text '.'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, '.') }
    grid('row'=>6, 'column'=>2, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'E'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, 'E') }
    grid('row'=>6, 'column'=>3, 'ipadx'=>20, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'log'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, 'log') }
    grid('row'=>6, 'column'=>4, 'ipadx'=>12, 'padx'=>5, 'pady'=>5)
}
TkButton.new {
    text 'ln'
    font '{Monospace} 10 {bold}'
    command proc { entry_in.insert(entry_in.icursor, 'ln') }
    grid('row'=>6, 'column'=>5, 'ipadx'=>16, 'padx'=>5, 'pady'=>5)
}

#------------------------------
=begin
root.withdraw
root.update
width, height = root.winfo_width, root.winfo_height
x = (TkWinfo.screenwidth(root) - root.winfo_width) / 2
y = (root.winfo_screenheight - root.winfo_height) / 2
root.geometry "#{width}x#{height}+#{x}+#{y}"
root.resizable(0, 0)
root.deiconify
=end
#------------------------------
#Tk.mainloop
