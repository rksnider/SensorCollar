#   SD Controller specific clocks:
#     clk       The information associated with it is the port it goes out
#               of and the clock names for it.

set microsd_inst              [get_instance]

# regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:} $microsd_inst \
#             {\1} microsd_inst_name

#   Find information about the entity's clock.

set sysclk_clock              [get_instvalue clk]

set sdclk_info                [get_instvalue sclk]
set sdclk_port                [lindex $sdclk_info 0]
set sdclk_400                 [lindex $sdclk_info 1]
set sdclk_dir                 [lindex $sdclk_info 2]
set sdclk_dir_400             "${sdclk_dir}_400"

set sysclk_data               [get_clocks $sysclk_clock]
set sysclk_source             [get_clock_info -targets $sysclk_data]

#   Determine the information for the 400K clock.

set sd_400_signal             "$microsd_inst|clk_400k_signal"

set sd_400_divideby           [get_instvalue CLK_DIVIDE]

#   Assign two generated clocks to the port.

regsub -all "@" "$sd_400_signal" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating Clock  '$sdclk_400' from '$sysclk_clock' on '$clk_target'\n"
  puts $sdc_log "Creating Clocks '$sdclk_dir' and '$sdclk_dir_400' on '$sdclk_port'\n"

  create_generated_clock -name "$sdclk_400" -source "$sysclk_source" \
                         -divide_by $sd_400_divideby "$clk_target"

  create_generated_clock -name "$sdclk_dir" -source "$sysclk_source" \
                         "$sdclk_port"
  create_generated_clock -name "$sdclk_dir_400" -source "$clk_target" \
                         -add "$sdclk_port"

  set_keyvalue                  "$sdclk_port" [list "$sdclk_dir" "$sdclk_dir_400"]
} else {
  puts $sdc_log "Skipping Clock  '$sdclk_400' from '$sysclk_clock' on '$clk_target'\n"
  puts $sdc_log "Skipping Clocks '$sdclk_dir' and '$sdclk_dir_400' on '$sdclk_port'\n"
}
