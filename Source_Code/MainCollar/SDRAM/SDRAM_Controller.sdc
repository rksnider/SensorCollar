#   SDRAM specific clocks:
#     inmem_clk_out   Inverted and gated internal_clk.
#     outmem_clk_out  Inverted and gated internal_clk.
#     sdram_clk_out   Inverted and gated internal_clk.

set sysclk_clock                [get_instvalue sysclk]
set sdram_clk_port              [get_instvalue sdram_clk_out]

puts $sdc_log "Creating clock based on $sysclk_clock'\n"

set sysclk_data                 [get_clocks $sysclk_clock]
set sysclk_source               [get_clock_info -targets $sysclk_data]

# Assign a generated clock to the port.

set sdram_clock                 "sdram_clk"

create_generated_clock -source "$sysclk_source" -name "$sdram_clock" \
                       -invert "$sdram_clk_port"

set_keyvalue                    "$sdram_clk_port" "$sdram_clock"
