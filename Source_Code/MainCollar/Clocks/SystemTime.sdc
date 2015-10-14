#   System Time Maintenance
#     Startup Time
#     GPS Time
#     RTC Time
#     Local Time
#     Alarm Time

set systime_inst                [get_instance]

set sysclk                      [get_instvalue clk]

set sysclk_data                 [get_clocks $sysclk]
set sysclk_source               [get_clock_info -targets $sysclk_data]
set sysclk_period               [get_clock_info -period  $sysclk_data]

set sysclk_freq                 [expr 1.0 / ($sysclk_period * 1e-9)]

#   Determine the clock dividers.

set max_divider                 10000

set milliclk_name               "StartupTime_milli_clk"
set milliclk_target             "$systime_inst|milli_clk"
set milliclk_freq               [expr 1.0 / ((2 ** 3) * 1.0e-3)]
set milliclk_div                [expr {int($sysclk_freq / $milliclk_freq)}]

set timerec_load_name           "StartupTime_timerec_load"
set timerec_load_target         "$systime_inst|gps_timerec_load"
set timerec_load_freq           [expr 1.0 / 1.0e-3]
set timerec_load_div            [expr {int($sysclk_freq /               \
                                           $timerec_load_freq)}]

set seconds_load_name           "StartupTime_seconds_load"
set seconds_load_target         "$systime_inst|gps_seconds_load"
set seconds_load_freq           [expr 1.0 / 1.0e-3]
set seconds_load_div            [expr {int($sysclk_freq /               \
                                           $seconds_load_freq)}]

#   Generate the clocks.
#   Timings between the source clock and the generating clock are not
#   important.

regsub -all "@" "$timerec_load_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$timerec_load_name' via '$sysclk' on '$clk_target'\n"

  set clock_div                 [expr {min( $timerec_load_div,          \
                                            $max_divider)}]

  create_generated_clock -source    "$sysclk_source"                    \
                         -name      "$timerec_load_name"                \
                         -divide_by "$clock_div" "$clk_target"

  set clk_out_data              [get_clocks "$timerec_load_name"]

  set_false_path -from $sysclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $sysclk_data
} else {
  puts $sdc_log "Skipped clock '$timerec_load_name' via '$sysclk' on '$clk_target'\n"
}

regsub -all "@" "$seconds_load_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$seconds_load_name' via '$sysclk' on '$clk_target'\n"

  set clock_div                 [expr {min( $seconds_load_div,          \
                                            $max_divider)}]

  create_generated_clock -source    "$sysclk_source"                    \
                         -name      "$seconds_load_name"                \
                         -divide_by "$clock_div" "$clk_target"

  set clk_out_data              [get_clocks "$seconds_load_name"]

  set_false_path -from $sysclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $sysclk_data
} else {
  puts $sdc_log "Skipped clock '$seconds_load_name' via '$sysclk' on '$clk_target'\n"
}

regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
            "$milliclk_target|combout" {\1}   temp_path
regsub -all "@" "$temp_path" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$milliclk_name' via '$sysclk' on '$clk_target'\n"

  set clock_div                 [expr {min( $milliclk_div, $max_divider)}]

  create_generated_clock -source "$sysclk_source" -name "$milliclk_name" \
                         -divide_by "$clock_div"        "$clk_target"

  set clk_out_data              [get_clocks "$milliclk_name"]

  set_false_path -from $sysclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $sysclk_data
} else {
  puts $sdc_log "Skipped clock '$milliclk_name' via '$sysclk' on '$clk_target'\n"
}
