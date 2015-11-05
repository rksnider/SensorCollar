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

set milli8clk_name              "StartupTime_milli8_clk"
set milli8clk_bit               "startup_time.week_millisecond[2]"
set milli8clk_target            "$systime_inst|$milli8clk_bit"
set milli8clk_freq              [expr 1.0 / ((2 ** 3) * 1.0e-3)]
set milli8clk_div               [expr {int($sysclk_freq / $milli8clk_freq)}]

set milliclk_name               "StartupTime_milli_clk"
set milliclk_bit                "startup_time.millisecond_nanosecond[19]"
set milliclk_target             "$systime_inst|$milliclk_bit"
set milliclk_freq               [expr 1.0 / ((2 ** 20) * 1.0e-9)]
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

regsub -all "@" "$milli8clk_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$milli8clk_name' via '$sysclk' on '$clk_target'\n"

  set clock_div                 [expr {min( $milli8clk_div, $max_divider)}]

  create_generated_clock -source "$sysclk_source" -name "$milli8clk_name" \
                         -divide_by "$clock_div"        "$clk_target"

  set clk_out_data              [get_clocks "$milli8clk_name"]

  set_false_path -from $sysclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $sysclk_data
} else {
  puts $sdc_log "Skipped clock '$milli8clk_name' via '$sysclk' on '$clk_target'\n"
}

regsub -all "@" "$milliclk_target" "\\" clk_target

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

#   Cross chip send.

set ST_data_latch_name    "SystemTimeLatch"
set ST_valid_latch_name   "SystemTimeVLatch"

set sdc_file              "CrossChipSend.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "CrossChipSend:ccs"
  set_instvalue           data_latch_out    [list $ST_data_latch_name]
  set_instvalue           valid_latch_out   [list $ST_valid_latch_name]

  copy_instvalues         [list "clk,fast_clk"]

  source $sdc_file

  pop_instance
}

#   Disconnect the data latch from the millisecond clocks.

set milli_data            [get_clocks "$milliclk_name"]
set milli8_data           [get_clocks "$milli8clk_name"]
set latch_data            [get_clocks "$ST_data_latch_name"]

set_false_path -from $milli_data  -to $latch_data
set_false_path -from $latch_data  -to $milli_data
set_false_path -from $milli8_data -to $latch_data
set_false_path -from $latch_data  -to $milli8_data
