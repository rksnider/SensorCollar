#   Mems Microphone Timing information.
#   Perform data constraining at the pins.

#   Create input and output virtual clocks for the generated clock.

set clock_port                [lindex [get_ioports {mic_clk}] 0]
set mic_clock                 [get_keyvalue $clock_port]

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

set CLKin_dev_max               0.000       ;#  tCOa
set CLKin_dev_min               0.000
set CLKin_brd_max               0.180       ;#  BDa
set CLKin_brd_min               0.120

#   Set the delays for the I/O ports.

set_false_path -to [get_ports $clock_port]

set input_port_list           [get_ioports {mic_right_io mic_left_io}]

set mic_min_delay             [expr $CLKin_src_min + $CLKin_dev_min + \
                                    $CLKin_brd_min - $CLKin_dst_max]

set mic_max_delay             [expr $CLKin_src_max + $CLKin_dev_max + \
                                    $CLKin_brd_max - $CLKin_dst_min]

set_input_delay -clock $mic_clock -min $mic_min_delay \
                [get_ports $input_port_list]

set_input_delay -clock $mic_clock -max $mic_max_delay \
                [get_ports $input_port_list]


#   Break the connection between the reset line and the device pins.

set reset_pin                 [get_keyvalue reset]

set reset_data                [get_pins $reset_pin]

set dev_data                  [get_ports [concat $clock_port            \
                                                 $input_port_list]]

set_false_path -hold -from $reset_data -to $dev_data
