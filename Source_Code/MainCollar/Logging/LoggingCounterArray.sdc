#   Clock information passed through this entity.

#   Process SDC file for Interrupt Controller.  Push the new instance onto
#   the instances stack beforehand and remove it afterwards.

push_instance               "InterruptController:intctl"

copy_instvalues             { "clk,clk" }

source InterruptController.sdc

pop_instance
