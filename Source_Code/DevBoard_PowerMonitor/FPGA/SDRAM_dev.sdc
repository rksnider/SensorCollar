#   SDRAM Timing information.
#   Perform sdram data constraining at the pins.

#   Create input and output virtual clocks for the generated clock.

set sdram_clock               [get_keyvalue "SDRAM_CLK"]

set sdram_clock_data          [get_clocks $sdram_clock]
set sdram_clock_period        [get_clock_info -period   $sdram_clock_data]

derive_clock_uncertainty

#   Set the timings for the pins accessed via the clock.
#     Set Quartus II TimeQuest Timing Analyzer Cookbook - I/O Constraints
#
#     The clock originates in the FPGA but this is not important from
#     the timing prospective.  An inverse clock is used to talk to the
#     SDRAM.  From the FPGA prospective this means the clock takes half a
#     clock cycle to reach the device and a full clock cycle to reach the
#     FPGA for input.  For the output the clock is received by the FPGA
#     with no delay and by the device with half a clock cycle delay.

set CLKin_src_PhaseDelay        [expr $sdram_clock_period * 180.0 / 360.0]

set CLKin_src_max               0.180       ;#  CLKAs in example
set CLKin_src_min               0.120

set CLKin_dst_max               0.000       ;#  CLKAd
set CLKin_dst_min               0.000

set CLKin_dev_max               2.500       ;#  tCOa
set CLKin_dev_min               1.500
set CLKin_brd_max               0.180       ;#  BDa
set CLKin_brd_min               0.120


set CLKout_src_PhaseDelay       [expr $sdram_clock_period * 180.0 / 360.0]

set CLKout_src_max              0.000       ;#  CLKBs
set CLKout_src_min              0.000

set CLKout_dst_max              0.100       ;#  CLKBd
set CLKout_dst_min              0.080

set CLKout_dev_max              1.500       ;#  tSUb
set CLKout_dev_hld              1.000       ;#  tHb
set CLKout_brd_max              0.100       ;#  BDb
set CLKout_brd_min              0.080

#   Set the delays for the I/O ports.

set_false_path -to [get_ports SDRAM_CLK]

set output_port_list          {SDRAM_data* SDRAM_address* SDRAM_bank* \
                               SDRAM_mask* SDRAM_command* SDRAM_CKE}

set input_port_list           {SDRAM_data*}

set sdram_min_delay           [expr $CLKin_src_min + $CLKin_dev_min + \
                                    $CLKin_brd_min - $CLKin_dst_max]

set sdram_max_delay           [expr $CLKin_src_max + $CLKin_dev_max + \
                                    $CLKin_brd_max - $CLKin_dst_min]

set_input_delay -clock $sdram_clock -min $sdram_min_delay \
                [get_ports $input_port_list]

set_input_delay -clock $sdram_clock -max $sdram_max_delay \
                [get_ports $input_port_list]


set sdram_min_delay           [expr $CLKout_brd_min - $CLKout_dev_hld + \
                                    $CLKout_src_min - $CLKout_dst_max]

set sdram_max_delay           [expr $CLKout_brd_max + $CLKout_dev_max + \
                                    $CLKout_src_max - $CLKout_dst_min]

set_output_delay -clock $sdram_clock -min $sdram_min_delay \
                 -add_delay [get_ports $output_port_list]

set_output_delay -clock $sdram_clock -max $sdram_max_delay \
                 -add_delay [get_ports $output_port_list]

#   Break the connection between the reset line and the device pins.

set reset_pin                 [get_keyvalue reset]

set reset_data                [get_pins $reset_pin]

set dev_data                  [get_ports [concat SDRAM_CLK              \
                                                 $input_port_list       \
                                                 $output_port_list]]

set_false_path -hold -from $reset_data -to $dev_data
