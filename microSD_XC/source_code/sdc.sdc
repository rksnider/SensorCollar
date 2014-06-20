#**************************************************************
# Create Clock
#**************************************************************
create_clock -name {CLOCK_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports { CLOCK_50}]

derive_pll_clocks

##**************************************************************
## Create generated clocks based on PLLs
##**************************************************************

derive_clock_uncertainty
											
create_clock -name INITCLK -period 2500 [get_nets {sd_tester|i_microsd_controller_inner_0|clk_400k_signal}]

## Only contrain the sd data,cmd, and clk. Leave other non-essential lines tact/gpio/leds alone.

#50Mhz 20ns
#40Mhz 25ns
#25mhz 40ns
#10mhz 100ns
#2mhz	 500


create_clock -period 25 -name sd_clk_ext


							
create_generated_clock -name sd_clk -source [get_pins {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] [get_ports {EG_BOTTOM[16]}]

#False paths I don't really care about like leds and push buttons. 
set_input_delay -clock [get_clocks CLOCK_50] 10 [get_ports {tact[0] tact[1]}]
set_output_delay -clock [get_clocks CLOCK_50] 10 [get_ports {user_led_n[3] gpio[0] gpio[1] gpio[2] gpio[3] gpio[4] gpio[5] gpio[6] gpio[7] gpio[8] gpio[9] gpio[10] user_led_n[0] user_led_n[1] user_led_n[2] EG_TOP[24] EG_TOP[25]}]

set_false_path -from * -to [get_ports {user_led_n[3] gpio[0] gpio[1] gpio[2] gpio[3] gpio[4] gpio[5] gpio[6] gpio[7] gpio[8] gpio[9] gpio[10] user_led_n[0] user_led_n[1] user_led_n[2] EG_TOP[24] EG_TOP[25]}]
set_false_path -from [get_ports {tact[0] tact[1]}] -to *


set_input_delay -clock sd_clk_ext  -min 0 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]
set_input_delay -clock sd_clk_ext  -max 14 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]


set_false_path -from [get_registers {rst_n}]

set_false_path -from INITCLK
set_false_path -to INITCLK
set_false_path -to [get_ports {EG_BOTTOM[16]}]

set_output_delay -clock sd_clk  -min -5 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]
set_output_delay -clock sd_clk  -max 5 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]


#Set everything except falling edge to rising edge to false path. Data is pushed on falling edge and sampled on rising edge. 
#This is not entirely true for the sd card responses in 1.8V mode, but these constraints still work well.

set_false_path -setup  -rise_from [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -rise_to [get_clocks sd_clk]

set_false_path -setup  -fall_from [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -fall_to [get_clocks sd_clk]

set_false_path -setup   -rise_from [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -fall_to [get_clocks sd_clk]
	
set_false_path -hold   -rise_from [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -rise_to [get_clocks sd_clk]

set_false_path -hold -fall_from [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -fall_to [get_clocks sd_clk]

set_false_path -hold  -rise_from [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
   -fall_to [get_clocks sd_clk]
	
	
	
set_false_path -setup  -rise_from [get_clocks sd_clk_ext] \
   -rise_to [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]

set_false_path -setup  -fall_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]

set_false_path -setup   -rise_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
	
set_false_path -hold   -rise_from [get_clocks sd_clk_ext] \
   -rise_to [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]

set_false_path -hold -fall_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]

set_false_path -hold  -rise_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]




#Constrain Altera JTAG  related to signal tap/in memory viewer/and NIOS stuff.
create_clock -period 10MHz {altera_reserved_tck}
set_clock_groups -asynchronous -group {altera_reserved_tck}
set_input_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tdi]
set_input_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tms]
set_output_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tdo]
