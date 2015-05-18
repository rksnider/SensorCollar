#   SD Controller specific clocks:
#     clk       The information associated with it is the port it goes out
#               of and the clock names for it.

set microsd_inst              [get_instance]

# regsub -all {[A-Za-z0-9_]+:} $microsd_inst "" microsd_inst_name

#   Find information about the entity's clock.

set sysclk_clock              [get_instvalue clk]

set clk_port                  [get_instvalue sclk]

#   Determine the information for the 400K clock.

set sd_400_target             "$microsd_inst|clk_400k_signal"
set sd_400_divideby           [get_instvalue CLK_DIVIDE]

#   Assign two generated clocks to the port.

create_generated_clock -name sd_400 -source "$sysclk_clock" \
                       -divide_by $sd_400_divideby "$sd_400_target"

create_generated_clock -name sd_clk_dir -source "$sysclk_clock" \
                       "$clk_port"
create_generated_clock -name sd_clk_dir_400 -source sd_400 \
                       -add "$clk_port"

set_keyvalue                  "$clk_port" [list sd_clk_dir sd_clk_dir_400]
