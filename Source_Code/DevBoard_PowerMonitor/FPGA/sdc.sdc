
#**************************************************************
# Create Clock
#**************************************************************
create_clock -name {CLK_50MHZ_TO_FPGA} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK_50MHZ_TO_FPGA}]
create_clock -name {CLK_50MHZ_TO_FPGA_CLK_PIN} -period 20.000 -waveform { 0.000 10.000 } [get_ports {GPIOSEL_10}]

derive_clock_uncertainty
derive_pll_clocks


create_clock -name INITCLK -period 2500  [get_nets {*|clk_400k_signal}]

#Create another one for the microsd_c.
create_clock -name spi_clk -period 3.6Mhz {Collar:C|spi_cpld_fpga_clk} 


create_clock -period 50Mhz -name sd_clk_ext


## 
##Below is for when using a PLL to clk the microsd design.##
##
#create_generated_clock -name sd_clk_shift -source [get_pins {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] [get_ports {SDCARD_CLK_TO_FPGA}]
#create_generated_clock -name sd_clk_dir -source [get_pins {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] [get_ports {SDCARD_DI_CLK_TO_FPGA}]

create_generated_clock -name sd_clk_dir -source [get_ports {CLK_50MHZ_TO_FPGA}] [get_ports {SDCARD_DI_CLK_TO_FPGA}]

#Attempt to not constraing the asynchronous power up/reset stuff.
set_false_path -from [get_registers {Collar:C|power_up}]
#Attempt to not constrain any signal tap to design paths as recommended here:
#http://www.altera.com/support/kdb/solutions/rd04282008_867.html
set_false_path -from * -to {sld_signaltap:*}


#Set false path of the sd card clock pin.
#Do not constrain the clock output port with the clock it is itself putting out or any other clock. 
set_false_path -to [get_ports {SDCARD_CLK_TO_FPGA}]
set_false_path -to [get_ports {SDCARD_DI_CLK_TO_FPGA}]

#Set false path of the much slower INITCLK
set_false_path -from INITCLK
set_false_path -to INITCLK

#Set inputdelay on the data input ports.
#Specifies the data required time at the specified input ports relative to the clock.
#These values are calculated from Altera's Constraining Source Synchronous Interfaces 
#online training section 3.14. The -Tcomax and -Tcomin times taken from 
#SanDisk SD Card Product Manual 
#Version 2.2. tosu of SD manual taken to correspond to Altera Tco.  
#The Tco column of Altera training slides was used for calculations witthout any data or clock trace delay added. 
#SDCARD_CLK_TO_FPGA
#SDCARD_DI_CLK_TO_FPGA

set_input_delay -clock sd_clk_ext  -min 0 [get_ports {SDCARD_CMD_TO_FPGA SDCARD_DAT_TO_FPGA[0] SDCARD_DAT_TO_FPGA[1] \
SDCARD_DAT_TO_FPGA[2] SDCARD_DAT_TO_FPGA[3]}]
set_input_delay -clock sd_clk_ext  -max 14 [get_ports {SDCARD_CMD_TO_FPGA SDCARD_DAT_TO_FPGA[0] SDCARD_DAT_TO_FPGA[1] \
SDCARD_DAT_TO_FPGA[2] SDCARD_DAT_TO_FPGA[3]}]

 set_input_delay -clock sd_clk_ext  -min 0 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 set_input_delay -clock sd_clk_ext  -max 14 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]

#Set output delay on the data output ports.
#Specifies the required data arrival times at the specified output ports relative to the clock
#These values calculated from Altera's Constraining Source Synchronous Interfaces 
#online training section 4.13. The -Tsu and -Th times taken from SanDisk 
#SD Card Product Manual 
#Version 2.2. The setup and hold column of Altera training slide used without
#any additional data or clock trace delay added. 
set_output_delay -clock sd_clk_shift  -min -5 [get_ports {SDCARD_CMD_TO_FPGA SDCARD_DAT_TO_FPGA[0] SDCARD_DAT_TO_FPGA[1] \
SDCARD_DAT_TO_FPGA[2] SDCARD_DAT_TO_FPGA[3]}]
set_output_delay -clock sd_clk_shift  -max 5 [get_ports {SDCARD_CMD_TO_FPGA SDCARD_DAT_TO_FPGA[0] SDCARD_DAT_TO_FPGA[1] \
SDCARD_DAT_TO_FPGA[2] SDCARD_DAT_TO_FPGA[3]}]

 set_output_delay -clock sd_clk_dir -min -5 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 set_output_delay -clock sd_clk_dir  -max 5 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 
 
#For output timing I only want to consider the falling edge of the sd_data clk which sends the data
#and the rising edge of the sd_clk which receives the data. 

set_false_path -setup  -rise_from [get_clocks CLK_50MHZ_TO_FPGA] \
   -rise_to [get_clocks sd_clk_dir]

set_false_path -setup  -fall_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_dir]

set_false_path -setup   -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_dir]
	
set_false_path -hold   -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -rise_to [get_clocks sd_clk_dir]

set_false_path -hold -fall_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_dir]

set_false_path -hold  -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_dir]
	
	
set_false_path -setup  -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
-rise_to [get_clocks sd_clk_shift]

set_false_path -setup  -fall_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_shift]

set_false_path -setup   -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_shift]
	
set_false_path -hold   -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -rise_to [get_clocks sd_clk_shift]

set_false_path -hold -fall_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_shift]

set_false_path -hold  -rise_from [get_clocks CLK_50MHZ_TO_FPGA]  \
   -fall_to [get_clocks sd_clk_shift]
   
	
#For input timing I only want to consider the falling edge of the sd_clk_ext which sends the data
#and the rising edge of the sd_data clk which receives the data. 
	
set_false_path -setup  -rise_from [get_clocks sd_clk_ext] \
   -rise_to [get_clocks CLK_50MHZ_TO_FPGA] 

set_false_path -setup  -fall_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks CLK_50MHZ_TO_FPGA] 

set_false_path -setup   -rise_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks CLK_50MHZ_TO_FPGA] 
	
set_false_path -hold   -rise_from [get_clocks sd_clk_ext] \
   -rise_to [get_clocks CLK_50MHZ_TO_FPGA] 

set_false_path -hold -fall_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks CLK_50MHZ_TO_FPGA] 

set_false_path -hold  -rise_from [get_clocks sd_clk_ext] \
   -fall_to [get_clocks CLK_50MHZ_TO_FPGA]  
 
 
## 
##Below is for when using a PLL to clk the microsd design.##
##

#For output timing I only want to consider the falling edge of the sd_data clk which sends the data
#and the rising edge of the sd_clk which receives the data. 

#set_false_path -setup  -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -rise_to [get_clocks sd_clk_dir]
#
#set_false_path -setup  -fall_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_dir]
#
#set_false_path -setup   -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_dir]
#	
#set_false_path -hold   -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -rise_to [get_clocks sd_clk_dir]
#
#set_false_path -hold -fall_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_dir]
#
#set_false_path -hold  -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_dir]
#	
#	
#set_false_path -setup  -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#-rise_to [get_clocks sd_clk_shift]
#
#set_false_path -setup  -fall_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_shift]
#
#set_false_path -setup   -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_shift]
#	
#set_false_path -hold   -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -rise_to [get_clocks sd_clk_shift]
#
#set_false_path -hold -fall_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_shift]
#
#set_false_path -hold  -rise_from [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] \
#   -fall_to [get_clocks sd_clk_shift]
#   
#	
##For input timing I only want to consider the falling edge of the sd_clk_ext which sends the data
##and the rising edge of the sd_data clk which receives the data. 
#	
#set_false_path -setup  -rise_from [get_clocks sd_clk_ext] \
#   -rise_to [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
#
#set_false_path -setup  -fall_from [get_clocks sd_clk_ext] \
#   -fall_to [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
#
#set_false_path -setup   -rise_from [get_clocks sd_clk_ext] \
#   -fall_to [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
#	
#set_false_path -hold   -rise_from [get_clocks sd_clk_ext] \
#   -rise_to [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
#
#set_false_path -hold -fall_from [get_clocks sd_clk_ext] \
#   -fall_to [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
#
#set_false_path -hold  -rise_from [get_clocks sd_clk_ext] \
#   -fall_to [get_clocks {pll_0|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
	

#Constrain Altera JTAG stuff related to signal tap/in memory viewer/and NIOS stuff.
create_clock -period 10MHz {altera_reserved_tck}
set_clock_groups -asynchronous -group {altera_reserved_tck}
set_input_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tdi]
set_input_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tms]
set_output_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tdo]
