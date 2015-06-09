#   General reduced clock used in testbeds.  This is always checked at the
#   main clock frequency in order to detect problems that will occur at the
#   production clock speed but may not show up at the test bench clock
#   speed.
#
#   The internal clock is converted to a global clock by runing its output
#   into another cell whose output is on a global clock bus.  It is this
#   output that we want to be the named clock as the delay getting to
#   this point is not important for timing.

set sdram_tb_inst               [get_instance]

regsub -all {[A-Za-z0-9_]+:} $sdram_tb_inst "" sdram_tb_inst_name

set internal_clk_name         "internal_clk"
set global_clk_cell           "$sdram_tb_inst_name|gbl_intclk"
set pll_clk_cell              "internal_clock_altclkctrl_9kh_component"
set pll_clk_pin               "sd1|outclk"
set internal_clk_target       "$global_clk_cell|$pll_clk_cell|$pll_clk_pin"

# set internal_clk_target       "$sdram_tb_inst|$internal_clk_name"
# set internal_clk_div          [expr {int ($master_clk_freq / 1e6)}]
set internal_clk_div          1

set inmem_buff_ready_target   "$sdram_tb_inst|inmem_buff_ready"
set outmem_buff_ready_target  "$sdram_tb_inst|outmem_buff_ready"

set master_clk_target         [get_instvalue master_clk]


set master_clock_data         [get_clocks master_clk]
set master_clock_waveform     [get_clock_info -waveform $master_clock_data]
set master_clock_period       [get_clock_info -period   $master_clock_data]

create_clock -name $internal_clk_name -period $master_clock_period \
             -waveform $master_clock_waveform $internal_clk_target
# create_generated_clock -source $master_clk_target -name $internal_clk_name \
#                        -divide_by $internal_clk_div $internal_clk_target

set internal_clock_data       [get_clocks $internal_clk_name]

#   Master clock to internal clock delays are unimportant.
#   Power-up to all reset recovery times are not important.  Removal
#   recovery times are important.

set_false_path -from $master_clock_data   -to $internal_clock_data
set_false_path -from $internal_clock_data -to $master_clock_data

set_false_path -from [get_registers "$sdram_tb_inst|power_up"] -setup


create_generated_clock -source $internal_clk_target -invert \
                       -name inmem_buff_ready $inmem_buff_ready_target
create_generated_clock -source $internal_clk_target -invert \
                       -name outmem_buff_ready $outmem_buff_ready_target

#   Process SDC file for Status/Control SPI.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "StatCtlSPI_FPGA:pc_spi"

set_instvalue               clk "$internal_clk_target"

copy_instvalues             { "PC_SPI_clk_out,sclk" }

source StatCtlSPI_FPGA.sdc

pop_instance

#   Process SDC file for SDRAM Controller.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "SDRAM_Controller:sdram_ctl"

set_instvalue               sysclk "$internal_clk_target"

copy_instvalues             { "sdram_clk,sdram_clk_out" }

source SDRAM_Controller.sdc

pop_instance
