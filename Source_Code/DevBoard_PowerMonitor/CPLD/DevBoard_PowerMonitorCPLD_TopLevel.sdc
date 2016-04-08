## Generated SDC file "sdc.sdc"

## Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus II License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 15.0.1 Build 150 06/03/2015 SJ Full Version"

## DATE    "Mon Feb 22 14:02:52 2016"

##
## DEVICE  "5M570ZM100I5"
##


#**************************************************************
# Time Information
#**************************************************************



set_time_format -unit ns -decimal_places 3


#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {CLK_50MHZ} -period 20.000 -waveform { 0.000 10.000 } [get_ports { CLK_50MHZ }]


create_generated_clock -name pfl_clk  -divide_by 2 -source [get_ports { CLK_50MHZ }] {PowerController:PC|pfl_clk_div[0]}



#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************


set Tsu 5
set Th  5

set data_tracemax   0.1 
set data_tracemin   0.1  

set clk_tracemin   0.1 
set clk_tracemax   0.1 



#Minimum time to stay active and still meet the devices hold"
set fpga_min_delay_out           [expr $data_tracemin - $Th - \
                                         $clk_tracemax ]
#"Maximum time to arrive and still meet the device's Tsu"
set fpga_max_delay_out           [expr $data_tracemax + $Tsu - \
                                         $clk_tracemin]


set_output_delay -clock pfl_clk -min $fpga_min_delay_out [get_ports FPGA_DATA0] 

set_output_delay -clock pfl_clk -max $fpga_max_delay_out [get_ports FPGA_DATA0] 


#**************************************************************
# Set Clock Groups
#**************************************************************

#**************************************************************
# Set False Path
#**************************************************************

set async_port_list          { FPGA_NSTATUS FPGA_CONF_DONE FPGA_INIT_DONE FPGA_NCONFIG GPS_CNTRL_TO_CPLD  
SDRAM_CNTRL_TO_CPLD  MRAM_CNTRL_TO_CPLD MIC_B_CNTRL MIC_A_CTRL CLOCK_CNTRL_TO_CPLD DATA_TX_CNTRL_TO_CPLD 
SDCARD_CNTRL_TO_CPLD FPGA_ON_TO_CPLD IM_2P5V_TO_CPLD IM_1P8V_TO_CPLD 
    MAIN_ON                         
    RECHARGE_EN                    
    BAT_HIGH_TO_CPLD            
    BAT_HIGH_TO_FPGA          
    BAT_LOW_TO_CPLD         
    BATT_GD_N_TO_CPLD         
    VCC1P1_RUN_TO_CPLD          
    VCC2P5_RUN_TO_CPLD          
    VCC3P3_RUN_TO_CPLD          
    PWR_GOOD_1P1_TO_CPLD      
    PWR_GOOD_2P5_TO_CPLD       
    PWR_GOOD_3P3_TO_CPLD       
    BUCK_PWM_TO_CPLD           
    FLASH_PFL[0]
    FLASH_PFL[1]
    FLASH_PFL[2]
    FLASH_PFL[3]
    VCC1P8_AUX_CTRL}

set_false_path -from [get_ports $async_port_list]
set_false_path -to [get_ports $async_port_list]


#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

