#   GPS Timing information.
#   Perform GPS data constraining at the pins.

#   All GPS I/O activity is too slow for timing analysis.

set gps_ports                 [get_ioports {gps_rx_io gps_tx_out        \
                                            gps_timemark_out            \
                                            gps_timepulse_io}]

set gps_data                  [get_ports $gps_ports]

set_false_path -from $gps_data
set_false_path -to   $gps_data

#   Break the connection between the reset line and the device pins.

set reset_pin                 [get_keyvalue reset]

set reset_data                [get_pins $reset_pin]

set_false_path -hold -from $reset_data -to $gps_data
