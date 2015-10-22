#   Clock information passed through this entity.

#   Process SDC file for GPS clocks.

push_instance             "GPSclocks:gpsclks"

copy_instvalues         { "clk_freq_g,clk_freq_g" "clk,clk"               \
                          "gps_rx_in,gps_clk_out" "gps_tx_out,tx_clk_out" }

source GPSclocks.sdc

pop_instance
