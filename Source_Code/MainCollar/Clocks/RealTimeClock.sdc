#   Real Time Clock:
#     startup_time_in FPGA's startup time used for clock generation.

set rtc_inst                    [get_instance]

set startup_time                [get_instvalue startup_time_in]

set startup_data                [get_clocks $startup_time]
set startup_source              [get_clock_info -targets $startup_data]
set startup_period              [get_clock_info -period  $startup_data]

set startup_freq                [expr 1.0 / ($startup_period * 1e-9)]

#   Determine the clock dividers.

set milliclk_name               "rtc_milli_clk"
set milliclk_target             "$rtc_inst|milli_clk"
set milliclk_freq               [expr 1.0 / (2 ** 3 * 1.0e-3)]
set milliclk_div                [expr {int($startup_freq / $milliclk_freq)}]

set fastclk_name                "rtc_fast_clk"
set fastclk_target              "rtc_inst|fast_clk"
set fastclk_freq                [expr 1.0 / (2 ** 8 * 1.0e-9)]
set fastclk_div                 [expr {int($startup_freq / $fastclk_freq)}]

#   Generate the clocks.
#   Timings between the source clock and the generating clock are not
#   important.

regsub -all "@" "$milliclk_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$milliclk_name' via '$startup_time' on '$clk_target'\n"

  create_generated_clock -source "$startup_source" -name "$milliclk_name" \
                         -divide_by "$milliclk_div"      "$clk_target"

  set clk_out_data              [get_clocks "$milliclk_name"]

  set_false_path -from $startup_data  -to $clk_out_data
  set_false_path -from $clk_out_data  -to $startup_data
} else {
  puts $sdc_log "Skipped clock '$milliclk_name' via '$startup_time' on '$clk_target'\n"
}

regsub -all "@" "$fastclk_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$fastclk_name' via '$startup_time' on '$clk_target'\n"

  create_generated_clock -source "$startup_source" -name "$fastclk_name" \
                         -divide_by "$fastclk_div"      "$clk_target"

  set clk_out_data              [get_clocks "$fastclk_name"]

  set_false_path -from $startup_data  -to $clk_out_data
  set_false_path -from $clk_out_data  -to $startup_data
} else {
  puts $sdc_log "Skipped clock '$fastclk_name' via '$startup_time' on '$clk_target'\n"
}
