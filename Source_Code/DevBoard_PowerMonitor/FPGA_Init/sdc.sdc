
#**************************************************************
# Create Clock
#**************************************************************
create_clock -name {CLK_50MHZ_TO_FPGA} -period 20.000 -waveform { 0.000 10.000 } [get_ports {CLK_50MHZ_TO_FPGA}]
create_clock -name {CLK_50MHZ_TO_FPGA_CLK_PIN} -period 20.000 -waveform { 0.000 10.000 } [get_ports {GPIOSEL_10}]

create_generated_clock -name spi_clk -source [get_ports {CLK_50MHZ_TO_FPGA}] -divide_by 14 [get_registers {Collar:C|spi_cpld_fpga_clk}]
create_generated_clock -name sd_400 -source [get_ports {CLK_50MHZ_TO_FPGA}] -divide_by 128 [get_registers {Collar:C|microsd_controller:\use_SDH:i_microsdh_controller_0|microsd_controller_inner:i_microsd_controller_inner_0|clk_400k_signal}]
#create_generated_clock -name master_clk_invert -source [get_ports {CLK_50MHZ_TO_FPGA}] -invert [get_registers {Collar:C|master_clk_invert}]


derive_clock_uncertainty
derive_pll_clocks




#Create virtual external clock for the SD Card.
create_clock -period 50Mhz -name sd_clk_ext
create_clock -period .3906Mhz -name sd_clk_ext_400


#http://www.alterawiki.com/uploads/3/3f/TimeQuest_User_Guide.pdf
#Recommendations on using generated clock with the set output delay. Page 88.
create_generated_clock -name sd_clk_dir -source [get_ports {CLK_50MHZ_TO_FPGA}] [get_ports {SDCARD_DI_CLK_TO_FPGA}]
create_generated_clock -add -name sd_clk_dir_400 -source [get_registers {Collar:C|microsd_controller:\use_SDH:i_microsdh_controller_0|microsd_controller_inner:i_microsd_controller_inner_0|clk_400k_signal}] [get_ports {SDCARD_DI_CLK_TO_FPGA}]
set_clock_groups -exclusive -group {sd_400 sd_clk_ext_400 sd_clk_dir_400} -group {sd_clk_dir sd_clk_ext CLK_50MHZ_TO_FPGA}
#Attempt to not constrain the asynchronous power up/reset.
set_false_path -from [get_registers {Collar:C|power_up}]
#Attempt to not constrain any signal tap to design paths as recommended here:
#http://www.altera.com/support/kdb/solutions/rd04282008_867.html
set_false_path -from * -to {sld_signaltap:*}


#Set false path of the sd card clock pin.
#Do not constrain the clock output port with the clock it is itself putting out or any other clock. 
#Noted here: http://wl.altera.com/education/training/courses/OCSS1000
set_false_path -to [get_ports {SDCARD_DI_CLK_TO_FPGA}]


#Set inputdelay on the data input ports.
#Specifies the data required time at the specified input ports relative to the clock.
#These values are calculated from Altera's Constraining Source Synchronous Interfaces 
#online training section 3.14. The -Tcomax and -Tcomin times taken from 
#SanDisk SD Card Product Manual 
#Version 2.2. tosu of SD manual taken to correspond to Altera Tco.  
#The Tco column of Altera training slides was used for calculations witthout any data or clock trace delay added. 
#SDCARD_CLK_TO_FPGA
#SDCARD_DI_CLK_TO_FPGA
 set_input_delay -clock sd_clk_ext   -min 0 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 set_input_delay -clock sd_clk_ext   -max 14 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 
  set_input_delay -clock sd_clk_ext_400 -clock_fall  -min 0 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}] -add_delay
 set_input_delay -clock sd_clk_ext_400 -clock_fall  -max 14 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}] -add_delay

#Set output delay on the data output ports.
#Specifies the required data arrival times at the specified output ports relative to the clock
#These values calculated from Altera's Constraining Source Synchronous Interfaces 
#online training section 4.13. The -Tsu and -Th times taken from SanDisk 
#SD Card Product Manual 
#Version 2.2. The setup and hold column of Altera training slide used without
#any additional data or clock trace delay added. 
 set_output_delay -clock sd_clk_dir   -min -5 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 set_output_delay -clock sd_clk_dir   -max 5 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}]
 
 set_output_delay -clock sd_clk_dir_400   -min -5 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}] -add_delay
 set_output_delay -clock sd_clk_dir_400    -max 5 [get_ports {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA[0] \
 SDCARD_DI_DAT_TO_FPGA[1] SDCARD_DI_DAT_TO_FPGA[2] SDCARD_DI_DAT_TO_FPGA[3]}] -add_delay
 
 
# For output timing I only want to consider the falling edge of the sd_data clk which sends the data
# and the rising edge of the sd_clk which receives the data. 

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
   
   

# For the 400k clock..

# For output timing I only want to consider the falling edge of the sd_data clk which sends the data
# and the rising edge of the sd_clk which receives the data. 

set_false_path -setup  -rise_from [get_clocks sd_400] \
   -rise_to [get_clocks sd_clk_dir_400]

set_false_path -setup  -fall_from [get_clocks sd_400]  \
   -fall_to [get_clocks sd_clk_dir_400]

set_false_path -setup   -rise_from [get_clocks sd_400]  \
   -fall_to [get_clocks sd_clk_dir_400]
	
set_false_path -hold   -rise_from [get_clocks sd_400]  \
   -rise_to [get_clocks sd_clk_dir_400]

set_false_path -hold -fall_from [get_clocks sd_400]  \
   -fall_to [get_clocks sd_clk_dir_400]

set_false_path -hold  -rise_from [get_clocks sd_400]  \
   -fall_to [get_clocks sd_clk_dir_400]

   
	
#For input timing I only want to consider the falling edge of the sd_clk_ext which sends the data
#and the rising edge of the sd_data clk which receives the data. 
	
set_false_path -setup  -rise_from [get_clocks sd_clk_ext_400] \
   -rise_to [get_clocks sd_400] 

set_false_path -setup  -fall_from [get_clocks sd_clk_ext_400] \
   -fall_to [get_clocks sd_400] 

set_false_path -setup   -rise_from [get_clocks sd_clk_ext_400] \
   -fall_to [get_clocks sd_400] 
	
set_false_path -hold   -rise_from [get_clocks sd_clk_ext_400] \
   -rise_to [get_clocks sd_400] 

set_false_path -hold -fall_from [get_clocks sd_clk_ext_400] \
   -fall_to [get_clocks sd_400] 

set_false_path -hold  -rise_from [get_clocks sd_clk_ext_400] \
   -fall_to [get_clocks sd_400]  
   

#Timequest was attempting to launch/latch on the same edge. I added a multicycle. 
#This is explained on page 23 of Quartus II TimeQuest Timing Analyzer Cookbook.
set_multicycle_path -from [get_clocks {sd_clk_ext_400}] -to [get_clocks {sd_400}] -hold -end 2
set_multicycle_path -from [get_clocks {sd_clk_ext_400}] -to [get_clocks {sd_400}] -setup -end 2
   
   
   
#The clock multiplexing whereby I add the same output/input delay multiple times
#idea came from : Quartus II TimeQuest Timing Analyzer Cookbook
#http://www.alteraforum.com/forum/showthread.php?t=1858
#Two clocks are used. They are then seperated with set_clock_groups -exclusive
#set_clocks_groups -exclusive is explained 
#https://www.altera.com/support/support-resources/design-examples/design-software/timequest/exm-tq-clock-mux.html
#The -add is needed whenever multiple output/input delays are added to the same output
#port. This is explained here:TimeQuest_User_Guide PG88. Altera wiki.
 


	

#Constrain Altera JTAG stuff related to signal tap/in memory viewer/and NIOS stuff.
create_clock -period 10MHz {altera_reserved_tck}
set_clock_groups -asynchronous -group {altera_reserved_tck}
set_input_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tdi]
set_input_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tms]
set_output_delay -clock {altera_reserved_tck} 20 [get_ports altera_reserved_tdo]
