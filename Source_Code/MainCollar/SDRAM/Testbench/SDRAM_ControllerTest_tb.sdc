#   General reduced clock used in testbeds.  This is always checked at the
#   main clock frequency in order to detect problems that will occur at the
#   production clock speed but may not show up at the test bench clock
#   speed.
#
#   The internal clock is converted to a global clock by runing its output
#   into another cell whose output is on a global clock bus.  It is this
#   output that we want to be the named clock as the delay getting to
#   this point is not important for timing.

set sdram_tb_inst             [get_instance]

regsub -all {[A-Za-z0-9_]+:} $sdram_tb_inst "" sdram_tb_inst_name

set internal_clk_name         "internal_clk"
set global_clk_cell           "$sdram_tb_inst_name|gbl_intclk"
set pll_clk_cell              "internal_clock_altclkctrl_9kh_component"
set pll_clk_pin               "sd1|outclk"
set internal_clk_target       "$global_clk_cell|$pll_clk_cell|$pll_clk_pin"

set inmem_buff_ready_target   "$sdram_tb_inst|inmem_buff_ready"
set outmem_buff_ready_target  "$sdram_tb_inst|outmem_buff_ready"

set master_clk_target         [get_instvalue master_clk]

# set master_clock_data         [get_clocks master_clk]
# set master_clock_waveform     [get_clock_info -waveform $master_clock_data]
# set master_clock_period       [get_clock_info -period   $master_clock_data]

# create_clock -name $internal_clk_name -period $master_clock_period \
             # -waveform $master_clock_waveform $internal_clk_target
# create_generated_clock -source $master_clk_target -name $internal_clk_name \
#                        -divide_by $internal_clk_div $internal_clk_target

# set internal_clock_data       [get_clocks $internal_clk_name]

#   Power-up to all reset recovery times are not important.  Removal
#   recovery times are important.

set_false_path -from [get_registers "$sdram_tb_inst|power_up"] -setup

#   Process SDC file for internal and slow clocks.  Push the new instance
#   onto the instances stack beforehand and remove it afterwards.

set testbench_fast_clk_name testbench_fast_clk
push_instance               "GenClock:int_clock"

set_instvalue               clk_out       [list $testbench_fast_clk_name]
set_instvalue               inv_clk_out       { }
set_instvalue               gated_clk_out     { }
set_instvalue               gated_inv_clk_out { }

copy_instvalues             { "master_clk_freq_g,clk_freq_g" \
                              "internal_clk_freq_g,out_clk_freq_g" \
                              "master_clk,clk" }

source GenClock.sdc

pop_instance

set fast_clk_data           [get_clocks "$testbench_fast_clk_name"]
create_generated_clock -source [get_clock_info -targets $fast_clk_data] \
                       -name   $internal_clk_name   $internal_clk_target

set internal_clk_data       [get_clocks "$internal_clk_name"]

set_false_path -from $fast_clk_data     -to $internal_clk_data
set_false_path -from $internal_clk_data -to $fast_clk_data


set testbench_slow_clk_name testbench_slow_clk
push_instance               "GenClock:slow_clock"

set_instvalue               clk             $internal_clk_name
set_instvalue               out_clk_freq_g  $shared_constants(slow_clk_freq_c)
set_instvalue               clk_out         [list $testbench_slow_clk_name]
set_instvalue               inv_clk_out       { }
set_instvalue               gated_clk_out     { }
set_instvalue               gated_inv_clk_out { }

copy_instvalues             { "internal_clk_freq_g,clk_freq_g" }

source GenClock.sdc

pop_instance

#   Define clocks based on the internal clock.

create_generated_clock -source $internal_clk_target -invert \
                       -name inmem_buff_ready $inmem_buff_ready_target
create_generated_clock -source $internal_clk_target -invert \
                       -name outmem_buff_ready $outmem_buff_ready_target

#   Process SDC file for Status/Control SPI.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "StatCtlSPI_FPGA:pc_spi"

set_instvalue               clk "$testbench_slow_clk_name"

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
