#   System Time Maintenance
#     Startup Time
#     GPS Time
#     RTC Time
#     Local Time
#     Alarm Time

set systime_inst                [get_instance]

set sysclk                      [get_instvalue clk]

set sysclk_data                 [get_clocks $sysclk]
set sysclk_source               [get_clock_info -targets $startup_data]
set sysclk_period               [get_clock_info -period  $startup_data]

set sysclk_freq                 [expr 1.0 / ($sysclk_period * 1e-9)]

#   Determine the clock dividers.

set milliclk_name               "StartupTime_milli_clk"
set milliclk_target             "$systime_inst|milli_clk"
set milliclk_freq               [expr 1.0 / ((2 ** 3) * 1.0e-3)]
set milliclk_div                [expr {int($sysclk_freq / $milliclk_freq)}]

#   Generate the clocks.
#   Timings between the source clock and the generating clock are not
#   important.

regsub -all "@" "$milliclk_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$milliclk_name' via '$sysclk' on '$clk_target'\n"

  create_generated_clock -source "$sysclk_source" -name "$milliclk_name" \
                         -divide_by "$milliclk_div"     "$clk_target"

  set clk_out_data              [get_clocks "$milliclk_name"]

  set_false_path -from $sysclk_data   -to $clk_out_data
  set_false_path -from $clk_out_data  -to $sysclk_data
} else {
  puts $sdc_log "Skipped clock '$milliclk_name' via '$sysclk' on '$clk_target'\n"
}
