#   SD Card Timing information.
#   Perform SD Card data constraining at the pins.


puts $sdc_log "Currently in SDcard_dev.sdc\n"


set CLKin_src_max               0.180       ;#  CLKAs in example
set CLKin_src_min               0.120       ;

set CLKin_dst_max               0.000       ;#  CLKAd
set CLKin_dst_min               0.000

set CLKin_dev_max               14       ;#  tCOa
set CLKin_dev_min               0
set CLKin_brd_max               0.180       ;#  BDa
set CLKin_brd_min               0.120


set CLKout_src_max              0.000       ;#  CLKBs
set CLKout_src_min              0.000

set CLKout_dst_max              0.180       ;#  CLKBd
set CLKout_dst_min              0.120

set CLKout_dev_max              5       ;#  tSUb
set CLKout_dev_hld              5       ;#  tHb
set CLKout_brd_max              0.180       ;#  BDd
set CLKout_brd_min              0.120       ;



#Clock names were set in microsd_controller_inner.sdc with
set sd_clk_names              [get_keyvalue "SDCARD_DI_CLK_TO_FPGA"]
set sd_master_clk             [lindex $sd_clk_names 0]   
set sd_clk_400_sig            [lindex $sd_clk_names 1]  
set sd_clk                    [lindex $sd_clk_names 2]   
set sd_clk_400                [lindex $sd_clk_names 3]   
set sd_clk_ext                [lindex $sd_clk_names 4]   
set sd_clk_400_ext            [lindex $sd_clk_names 5]   


set out_clks  [list $sd_clk $sd_clk_400]
set in_virt_clks [list $sd_clk_ext $sd_clk_400_ext]



set output_port_list          {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA*}
                               
set input_port_list          {SDCARD_DI_CMD_TO_FPGA SDCARD_DI_DAT_TO_FPGA* }


set_false_path -to [get_ports SDCARD_DI_CLK_TO_FPGA]

set sdcard_min_delay_in           [expr $CLKin_src_min + $CLKin_dev_min + \
                                    $CLKin_brd_min - $CLKin_dst_max]

set sdcard_max_delay_in           [expr $CLKin_src_max + $CLKin_dev_max + \
                                    $CLKin_brd_max - $CLKin_dst_min]
                                    
set sdcard_min_delay_out           [expr $CLKout_brd_min - $CLKout_dev_hld + \
                                $CLKout_dst_min - $CLKout_src_max]

set sdcard_max_delay_out           [expr $CLKout_brd_max + $CLKout_dev_max + \
                                    $CLKout_dst_max - $CLKout_src_min]
                                    
                             
foreach clock $in_virt_clks {
set_input_delay -clock $clock   -min $sdcard_min_delay_in [get_ports $input_port_list] -add_delay
set_input_delay -clock $clock   -max $sdcard_max_delay_in [get_ports $input_port_list] -add_delay
}

foreach clock $out_clks {
set_output_delay -clock $clock  -min $sdcard_min_delay_out [get_ports $output_port_list] -add_delay
set_output_delay -clock $clock  -max $sdcard_max_delay_out [get_ports $output_port_list] -add_delay
}       



# For output timing I only want to consider the falling edge of the sd_data clk which sends the data
# and the rising edge of the sd_clk which receives the data. 


set_false_path -setup  -rise_from [get_clocks $sd_master_clk] \
   -rise_to [get_clocks $sd_clk]
   
set_false_path -hold   -rise_from [get_clocks $sd_master_clk]  \
   -rise_to [get_clocks $sd_clk]

set_false_path -setup  -fall_from [get_clocks $sd_master_clk]  \
   -fall_to [get_clocks $sd_clk]

set_false_path -setup   -rise_from [get_clocks $sd_master_clk]  \
   -fall_to [get_clocks $sd_clk]
	
set_false_path -hold -fall_from [get_clocks $sd_master_clk]  \
   -fall_to [get_clocks $sd_clk]

set_false_path -hold  -rise_from [get_clocks $sd_master_clk]  \
   -fall_to [get_clocks $sd_clk]

   
	
#For input timing I only want to consider the falling edge of the sd_clk_ext which sends the data
#and the rising edge of the sd_data clk which receives the data. 
	
set_false_path -setup  -rise_from [get_clocks $sd_clk_ext] \
   -rise_to [get_clocks $sd_master_clk] 

set_false_path -setup  -fall_from [get_clocks $sd_clk_ext] \
   -fall_to [get_clocks $sd_master_clk] 

set_false_path -setup   -rise_from [get_clocks $sd_clk_ext] \
   -fall_to [get_clocks $sd_master_clk] 
	
set_false_path -hold   -rise_from [get_clocks $sd_clk_ext] \
   -rise_to [get_clocks $sd_master_clk] 

set_false_path -hold -fall_from [get_clocks $sd_clk_ext] \
   -fall_to [get_clocks $sd_master_clk] 

set_false_path -hold  -rise_from [get_clocks $sd_clk_ext] \
   -fall_to [get_clocks $sd_master_clk]  
   
   

# # For the 400k clock..

# # For output timing I only want to consider the falling edge of the sd_data clk which sends the data
# # and the rising edge of the sd_clk which receives the data. 

set_false_path -setup  -rise_from [get_clocks $sd_clk_400_sig] \
   -rise_to [get_clocks $sd_clk_400]

set_false_path -setup  -fall_from [get_clocks $sd_clk_400_sig]  \
   -fall_to [get_clocks $sd_clk_400]

set_false_path -setup   -rise_from [get_clocks $sd_clk_400_sig]  \
   -fall_to [get_clocks $sd_clk_400]
	
set_false_path -hold   -rise_from [get_clocks $sd_clk_400_sig]  \
   -rise_to [get_clocks $sd_clk_400]

set_false_path -hold -fall_from [get_clocks $sd_clk_400_sig]  \
   -fall_to [get_clocks $sd_clk_400]

set_false_path -hold  -rise_from [get_clocks $sd_clk_400_sig]  \
   -fall_to [get_clocks $sd_clk_400]

   
	
# #For input timing I only want to consider the falling edge of the sd_clk_ext which sends the data
# #and the rising edge of the sd_data clk which receives the data. 
	
set_false_path -setup  -rise_from [get_clocks $sd_clk_400_ext] \
   -rise_to [get_clocks $sd_clk_400_sig] 

set_false_path -setup  -fall_from [get_clocks $sd_clk_400_ext] \
   -fall_to [get_clocks $sd_clk_400_sig] 

set_false_path -setup   -rise_from [get_clocks $sd_clk_400_ext] \
   -fall_to [get_clocks $sd_clk_400_sig] 
	
set_false_path -hold   -rise_from [get_clocks $sd_clk_400_ext] \
   -rise_to [get_clocks $sd_clk_400_sig] 

set_false_path -hold -fall_from [get_clocks $sd_clk_400_ext] \
   -fall_to [get_clocks $sd_clk_400_sig] 

set_false_path -hold  -rise_from [get_clocks $sd_clk_400_ext] \
   -fall_to [get_clocks $sd_clk_400_sig] 
 




