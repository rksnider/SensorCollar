#   SD Controller specific clocks:
#     clk       The information associated with it is the port it goes out
#               of and the clock names for it.

puts $sdc_log "Currently in LSM9DS1_dev.sdc\n"


set Tsu_SDI 5
set Th_SDI  15

set Tsu_CS 5
set Th_CS  20

set v_SO  50
set h_SO 5
set dis_SO 50

set data_tracemax   0.1 
set data_tracemin   0.1  

set clk_tracemin   0.1 
set clk_tracemax   0.1  

set im_clk_names              [get_keyvalue "IM_SPI_SCLK_TO_FPGA"]

set im_sclk_name              [lindex $im_clk_names 0]
#set im_sclk_vir_name          [lindex $im_clk_names 1]


set async_port_list {IM_INT_M_TO_FPGA IM_INT1_A_G_TO_FPGA IM_DRDY_M_TO_FPGA IM_INT2_A_G_TO_FPGA}



set_false_path -from [get_ports $async_port_list]

    
     

    # IM_INT_M_TO_FPGA      : inout   std_logic ;
    # IM_CS_A_G_TO_FPGA     : out     std_logic ;
    # IM_INT1_A_G_TO_FPGA   : inout   std_logic ;
    # IM_SDO_M_TO_FPGA      : inout   std_logic ;
    # IM_CS_M_TO_FPGA       : out     std_logic ;
    # IM_SPI_SDI_TO_FPGA    : out     std_logic ;
    # IM_DRDY_M_TO_FPGA     : inout   std_logic ;
    # IM_SDO_A_G_TO_FPGA    : inout   std_logic ;
    # IM_INT2_A_G_TO_FPGA   : inout   std_logic ;
    # IM_SPI_SCLK_TO_FPGA   : out     std_logic ;
    
    

set input_port_list {IM_SDO_A_G_TO_FPGA IM_SDO_M_TO_FPGA }
set output_port_list {IM_SPI_SDI_TO_FPGA}
set cs_port_list {IM_CS_A_G_TO_FPGA IM_CS_M_TO_FPGA}

set_false_path -to [get_ports IM_SPI_SCLK_TO_FPGA]


#Minimum time to stay active and still meet the devices hold"
set im_cs_min_delay_out           [expr $data_tracemin - $Th_CS - \
                                         $clk_tracemax ]
#"Maximum time to arrive and still meet the device's Tsu"
set im_cs_max_delay_out           [expr $data_tracemax + $Tsu_CS - \
                                         $clk_tracemin]

#"Minimum time to stay active and still meet Th"

set im_sdo_min_delay_in           [expr $data_tracemin + $h_SO - \
                                        $clk_tracemax]
                                        
#"Maximum time to arrive and still meet Tsu"
set im_sdo_max_delay_in           [expr $data_tracemax + $v_SO - \
                                        $clk_tracemin]
                                        

#Minimum time to stay active and still meet the devices hold"
set im_sdi_min_delay_out           [expr $data_tracemin - $Th_SDI - \
                                         $clk_tracemax ]
#"Maximum time to arrive and still meet the device's Tsu"
set im_sdi_max_delay_out           [expr $data_tracemax + $Tsu_SDI - \
                                         $clk_tracemin]

                                         
                                       
set_input_delay -clock $im_sclk_name   -min $im_sdo_min_delay_in [get_ports $input_port_list] -add_delay -clock_fall
set_input_delay -clock $im_sclk_name   -max $im_sdo_max_delay_in [get_ports $input_port_list] -add_delay -clock_fall



set_output_delay -clock $im_sclk_name  -min $im_cs_min_delay_out [get_ports $cs_port_list] -add_delay 
set_output_delay -clock $im_sclk_name  -max $im_cs_max_delay_out [get_ports $cs_port_list] -add_delay 


set_output_delay -clock $im_sclk_name  -min $im_sdi_min_delay_out [get_ports $output_port_list] -add_delay 
set_output_delay -clock $im_sclk_name  -max $im_sdi_max_delay_out [get_ports $output_port_list] -add_delay 


   