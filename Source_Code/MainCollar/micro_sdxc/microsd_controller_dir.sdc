#   SD Controller specific clocks:
#     clk       The information associated with it is the port it goes out
#               of and the clock names for it.


push_instance       "microsd_controller_inner:i_microsd_controller_inner_0"

copy_instvalues     [list "CLK_DIVIDE,CLK_DIVIDE" "clk,clk" "sd_clk,sclk"]

source microsd_controller_inner.sdc

pop_instance
