#   SD Controller specific clocks:
#     clk       The information associated with it is the port it goes out
#               of and the clock names for it.



set master_clock            [get_instvalue clk]

set clk                     [get_clocks $master_clock]
set sysclk_source           [get_clock_info -targets $clk]


set sd_dir            [get_instance]
set sd_clk_in         "$sd_dir|clk_signal"
set sd_clk_name       sd_master_clk  


#If you want to cut master_clk to master_sd_clk do the following
#Also remember to not copy_instvalues. 

# regsub -all "@" "$sd_clk_in" "\\" clk_target

# create_generated_clock -name "$sd_clk_name" -source "$sysclk_source" \
                        # "$clk_target"
                
# set_false_path -from [get_clocks $master_clock] -to [get_clocks $sd_clk_name]

# set_instvalue       clk $sd_clk_name



push_instance       "microsd_controller_inner:i_microsd_controller_inner_0"

copy_instvalues     [list "clk_divide_g,clk_divide_g" "clk,clk" "sd_clk,sclk"]

source microsd_controller_inner.sdc

pop_instance
