#   SPI specific clock:
#     sclk      Inverted and gated clk.  The information associated with
#               it is the port it goes out of and the clock name for it.

set sysclk_clock                [get_instvalue clk]

set spi_clk_info                [get_instvalue sclk]
set spi_clk_port                [lindex $spi_clk_info 0]
set spi_clock                   [lindex $spi_clk_info 1]

# Assign a generated clock to the port.

puts $sdc_log "Creating clock '$spi_clock' on port '$spi_clk_port' from '$spi_clk_info'\n"

create_generated_clock -source "$sysclk_clock" -name "$spi_clock" \
                       -invert "$spi_clk_port"

set_keyvalue                    "$spi_clk_port" "$spi_clock"
