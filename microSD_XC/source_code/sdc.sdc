#**************************************************************
# Create Clock
#**************************************************************
create_clock -name {CLOCK_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports { CLOCK_50}]

derive_pll_clocks

derive_clock_uncertainty

create_clock -name INITCLK -period 2500 [get_nets {sd_tester|i_microsd_controller_inner_0|clk_400k_signal}]
#Create mic_clk. 3.6Mhz from 50Mhz.
create_generated_clock -source [get_pins {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] -divide_by 14 [get_nets {mic_clk}]

#50Mhz 20ns
#40Mhz 25ns
#25mhz 40ns
#10mhz 100ns
#2mhz  500ns

#Virtual clock created for constraining input pins. 
create_clock -period 25 -name sd_clk_ext
			
#Create generated clock on the pin used for the SD clock. Then! use this clock
#to constrain data and cmd output pins.
create_generated_clock -name sd_clk -source [get_pins {pll_data|data_pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] [get_ports {EG_BOTTOM[16]}]

#False paths I don't care about like leds and push buttons. 
#EG_TOP24/25 were the switches associated with switching voltage to the level translator. 

# Only constrain the sd data,and cmd. Leave other non-essential lines tact/gpio/leds alone, ie false path

#The following two commands only serve to make sure TimeQuest does not issue warnings on these false path I/O.
#If the sdc is only supplied with set_false_path without input/output delay, warnings may still be issued. 
set_input_delay -clock [get_clocks CLOCK_50] 10 [get_ports {tact[0] tact[1]}]
set_output_delay -clock [get_clocks CLOCK_50] 10 [get_ports {user_led_n[3] gpio[0] gpio[1] gpio[2] gpio[3] gpio[4] gpio[5] gpio[6] gpio[7] gpio[8] gpio[9] gpio[10] user_led_n[0] user_led_n[1] user_led_n[2] EG_TOP[24] EG_TOP[25]}]

set_false_path -from * -to [get_ports {user_led_n[3] gpio[0] gpio[1] gpio[2] gpio[3] gpio[4] gpio[5] gpio[6] gpio[7] gpio[8] gpio[9] gpio[10] user_led_n[0] user_led_n[1] user_led_n[2] EG_TOP[24] EG_TOP[25]}]
set_false_path -from [get_ports {tact[0] tact[1]}] -to *

#Set inputdelay on the data input ports.
#These values are calculated from Altera's Constraining Source Synchronous Interfaces 
#online training section 3.14. The -Tcomax and -Tcomin times taken from 
#SanDisk SD Card Product Manual 
#Version 2.2. tosu of SD manual taken to correspond to Altera Tco.  
#The Tco column of Altera training slides was used for calculations witthout any data or clock trace delay added. 
set_input_delay -clock sd_clk_ext  -min 0 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]
set_input_delay -clock sd_clk_ext  -max 14 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]

#Set false path for the asynch reset.

set_false_path -from [get_registers {rst_n}]
set_false_path -from [get_registers {power_up_done}]

#Set false path of the much slower INITCLK
set_false_path -from INITCLK
set_false_path -to INITCLK

#Set false path of the sd card clock pin.
#Do not constrain the clock output port with the clock it is itself putting out or any other clock. 
set_false_path -to [get_ports {EG_BOTTOM[16]}]

#Set output delay on the data output ports.
#These values calculated from Altera's Constraining Source Synchronous Interfaces 
#online training section 4.13. The -Tsu and -Th times taken from SanDisk 
#SD Card Product Manual 
#Version 2.2. The setup and hold column of Altera training slide used without
#any additional data or clock trace delay added. 
set_output_delay -clock sd_clk  -min -5 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]
set_output_delay -clock sd_clk  -max 5 [get_ports {EG_BOTTOM[25] EG_BOTTOM[17] EG_BOTTOM[18] EG_BOTTOM[14] EG_BOTTOM[15]}]


#Set everything except falling edge to rising edge to false path. sdcard_controller puts data on the line on the falling edge and the sd card samples on the rising edge of the clock.
#This is not entirely true for the sd card responses in 1.8V mode. 

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
   
	
#Set everything except falling edge to rising edge to false path.  
#This setup is an overconstraint as data is actually pushed back to
#the master slightly after the rising edge of the clock.
	
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
