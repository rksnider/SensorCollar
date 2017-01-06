#   Data Transmitter Timing information for the CC1120 device.
#   Perform data constraining at the pins.

puts $sdc_log "Currently in cc1120_dev.sdc\n"

#   Create input and output virtual clocks for the generated clock.

set txrx_spi_clkport          [lindex [get_ioports {radio_clk}] 0]
set txrx_spi_clock            [get_keyvalue "$txrx_spi_clkport"]

set txrx_clock_data           [get_clocks $txrx_spi_clock]
set txrx_clock_period         [get_clock_info -period   $txrx_clock_data]

derive_clock_uncertainty

#   Set the timings for the pins accessed via the clock.
#     Set Quartus II TimeQuest Timing Analyzer Cookbook - I/O Constraints
#
#     The clock originates in the FPGA but this is not important from
#     the timing prospective.

set CLKin_src_max               0.180       ;#  CLKAs in example
set CLKin_src_min               0.120

set CLKin_dst_max               0.000       ;#  CLKAd
set CLKin_dst_min               0.000

set CLKin_dev_max              50.000       ;#  tCOa
set CLKin_dev_min               5.000
set CLKin_brd_max               0.180       ;#  BDa
set CLKin_brd_min               0.120


set CLKout_src_max              0.000       ;#  CLKBs
set CLKout_src_min              0.000

set CLKout_dst_max              0.100       ;#  CLKBd
set CLKout_dst_min              0.080

set CLKout_dev_max              5.000       ;#  tSUb
set CLKout_dev_hld             15.000       ;#  tHb
set CLKout_brd_max              0.100       ;#  BDb
set CLKout_brd_min              0.080

set CLKcs_dev_max               5.000       ;#  tSUb
set CLKcs_dev_hld              20.000       ;#  tHb

#   Set the delays for the I/O ports.  Interrupt ports are asyncrhonous
#   without other constraints.

set_false_path -to [get_ports "$txrx_spi_clkport"]


set async_port_list           [get_ioports {radio_rdy_io}]

set_false_path -from [get_ports $async_port_list]

set output_port_list          [get_ioports {radio_mosi_out}]

set cs_port_list              [get_ioports {radio_cs_n_out}]

set input_port_list           [get_ioports {radio_miso_io}]

set min_delay                 [expr $CLKin_src_min + $CLKin_dev_min + \
                                    $CLKin_brd_min - $CLKin_dst_max]

set max_delay                 [expr $CLKin_src_max + $CLKin_dev_max + \
                                    $CLKin_brd_max - $CLKin_dst_min]

set_input_delay -clock $txrx_spi_clock -min $min_delay \
                [get_ports $input_port_list]

set_input_delay -clock $txrx_spi_clock -max $max_delay \
                [get_ports $input_port_list]


set min_delay                 [expr $CLKout_brd_min - $CLKout_dev_hld + \
                                    $CLKout_src_min - $CLKout_dst_max]

set max_delay                 [expr $CLKout_brd_max + $CLKout_dev_max + \
                                    $CLKout_src_max - $CLKout_dst_min]

set_output_delay -clock $txrx_spi_clock -min $min_delay \
                 -add_delay [get_ports $output_port_list]

set_output_delay -clock $txrx_spi_clock -max $max_delay \
                 -add_delay [get_ports $output_port_list]

set min_delay                 [expr $CLKout_brd_min - $CLKcs_dev_hld + \
                                    $CLKout_src_min - $CLKout_dst_max]

set max_delay                 [expr $CLKout_brd_max + $CLKcs_dev_max + \
                                    $CLKout_src_max - $CLKout_dst_min]

set_output_delay -clock $txrx_spi_clock -min $min_delay \
                 -add_delay [get_ports $cs_port_list]

set_output_delay -clock $txrx_spi_clock -max $max_delay \
                 -add_delay [get_ports $cs_port_list]

#   Break the connection between the reset line and the device pins.

set reset_pin                 [get_keyvalue reset]

set reset_data                [get_pins $reset_pin]

set dev_data                  [get_ports [concat $txrx_spi_clkport      \
                                                 $async_port_list       \
                                                 $input_port_list       \
                                                 $cs_port_list          \
                                                 $output_port_list]]

set_false_path -hold -from $reset_data -to $dev_data
