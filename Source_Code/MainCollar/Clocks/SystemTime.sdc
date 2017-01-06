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

set srcclk_path                 "$sysclk_source"
set srcclk_data                 $sysclk_data
set srcclk_clk                  "$sysclk"

#   Determine the clock dividers.

set max_divisor                 10000

set milliclk_name               "StartupTime_milli_clk"
set milliclk_bit                "startup_time.millisecond_nanosecond[19]"
set milliclk_target             "$systime_inst|$milliclk_bit"
set milliclk_freq               [expr 1.0 / ((2 ** 20) * 1.0e-9)]
set milliclk_div                [expr {int($sysclk_freq / $milliclk_freq)}]

set milli8clk_name              "StartupTime_milli8_clk"
set milli8clk_bit               "startup_time.week_millisecond[2]"
set milli8clk_target            "$systime_inst|$milli8clk_bit"
set milli8clk_freq              [expr 1.0 / ((2 ** 3) * 1.0e-3)]
set milli8clk_div               [expr {int($sysclk_freq / $milli8clk_freq)}]

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
  puts $sdc_log "Creating clock '$timerec_load_name' via '$srcclk_clk' on '$clk_target'\n"

  set clock_div                 [expr {min( $timerec_load_div,          \
                                            $max_divisor)}]

  create_generated_clock -source    "$srcclk_path"                      \
                         -name      "$timerec_load_name"                \
                         -divide_by "$clock_div" "$clk_target"

  set clk_out_data              [get_clocks "$timerec_load_name"]

  set_false_path -from $sysclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $sysclk_data
} else {
  puts $sdc_log "Skipped clock '$timerec_load_name' via '$srcclk_clk' on '$clk_target'\n"
}

regsub -all "@" "$seconds_load_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$seconds_load_name' via '$srcclk_clk' on '$clk_target'\n"

  set clock_div                 [expr {min( $seconds_load_div,          \
                                            $max_divisor)}]

  create_generated_clock -source    "$srcclk_path"                      \
                         -name      "$seconds_load_name"                \
                         -divide_by "$clock_div" "$clk_target"

  set clk_out_data              [get_clocks "$seconds_load_name"]

  set_false_path -from $srcclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $srcclk_data
} else {
  puts $sdc_log "Skipped clock '$seconds_load_name' via '$srcclk_clk' on '$clk_target'\n"
}

regsub -all "@" "$milliclk_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '${milliclk_name}_base' via '$srcclk_clk' on '$clk_target'\n"

  set clock_div                 [expr {min( $milliclk_div, $max_divisor)}]

  create_generated_clock -source "$srcclk_path"                           \
                         -name   "${milliclk_name}_base"                  \
                         -divide_by "$clock_div"      "$clk_target"

  set clk_out_data              [get_clocks "${milliclk_name}_base"]

  set_false_path -from $srcclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $srcclk_data

  push_instance               "GenClock:milli_clock_gen"

  set_instvalue               clk_freq_g        $milliclk_freq
  set_instvalue               out_clk_freq_g    $milliclk_freq
  set_instvalue               clk               [list ${milliclk_name}_base]
  set_instvalue               clk_out           [list $milliclk_name]

  source GenClock.sdc

  pop_instance
} else {
  puts $sdc_log "Skipped clock '$milliclk_name' via '$srcclk_clk' on '$clk_target'\n"
}

regsub -all "@" "$milli8clk_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '${milli8clk_name}_base' via '$srcclk_clk' on '$clk_target'\n"

  set clock_div                 [expr {min( $milli8clk_div, $max_divisor)}]

  create_generated_clock -source "$srcclk_path"                           \
                         -name   "${milli8clk_name}_base"                 \
                         -divide_by "$clock_div"        "$clk_target"

  set clk_out_data              [get_clocks "${milli8clk_name}_base"]

  set_false_path -from $srcclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $srcclk_data

  push_instance               "GenClock:milli8_clock_gen"

  set_instvalue               clk_freq_g        $milli8clk_freq
  set_instvalue               out_clk_freq_g    $milli8clk_freq
  set_instvalue               clk               [list ${milli8clk_name}_base]
  set_instvalue               clk_out           [list $milli8clk_name]

  source GenClock.sdc

  pop_instance
} else {
  puts $sdc_log "Skipped clock '$milli8clk_name' via '$srcclk_clk' on '$clk_target'\n"
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

#   Disconnect the result times from clock paths as their timings have been
#   carried out with delays in the code.

set result_week           "$systime_inst|result_time.week_number[*]"
set result_milli          "$systime_inst|result_time.week_millisecond[*]"
set result_nano           "$systime_inst|result_time.millisecond_nanosecond[*]"

regsub -all "@" "$result_week" "\\" clk_target
set result_cells          [get_cells -no_duplicates $clk_target]
set_false_path -through $result_cells
set_false_path -from    $result_cells

regsub -all "@" "$result_milli" "\\" clk_target
set result_cells          [get_cells -no_duplicates $clk_target]
set_false_path -through $result_cells
set_false_path -from    $result_cells

regsub -all "@" "$result_nano" "\\" clk_target
set result_cells          [get_cells -no_duplicates $clk_target]
set_false_path -through $result_cells
set_false_path -from    $result_cells
