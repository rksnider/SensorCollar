#   General Generated clock:
#     clk             Clock used to generate clocks from
#     clk_freq_g      Frequency of the clock to generated from.
#     out_clk_freq_g  Frequency of the clocks to generate.
#     clk_out         Continuously running generated clock and port.
#     gated_clk_out   Gated generated clock and port.

set genclk_inst                 [get_instance]

set sysclk_clock                [get_instvalue clk]

set sysclk_data                 [get_clocks $sysclk_clock]
set sysclk_source               [get_clock_info -targets $sysclk_data]

#   Determine the clock divider.

set clk_freq_g                  [get_instvalue clk_freq_g]
set out_clk_freq_g              [get_instvalue out_clk_freq_g]

set clk_div                     [expr {int($clk_freq_g / \
                                           $out_clk_freq_g)}]

#   Generate the continuously running clock if it is desired.
#   Timings between the source clock and the generating clock are not
#   important.

set clk_out_info                [get_instvalue clk_out]

if {[llength $clk_out_info] > 0} {
  set clk_out_clock             [lindex $clk_out_info 0]

  if {[llength $clk_out_info] > 1} {
    set clk_out_port            [lindex $clk_out_info 1]
    set clk_out_target          "$clk_out_port"
    set_keyvalue                "$clk_out_port" "$clk_out_clock"
  } else {
    set clk_out_target          "$genclk_inst|out_clk"
  }

  regsub -all "@" "$clk_out_target" "\\" clk_target

  if {[get_collection_size [get_nodes $clk_target]] > 0} {
    puts $sdc_log "Creating clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"

    create_generated_clock -source "$sysclk_source" -name "$clk_out_clock" \
                           -divide_by "$clk_div"          "$clk_target"

    set clk_out_data              [get_clocks "$clk_out_clock"]

    set_false_path -from $sysclk_data  -to $clk_out_data
    set_false_path -from $clk_out_data -to $sysclk_data
  } else {
    puts $sdc_log "Skipped clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"
  }
}

#   Generate inverted clock if it is desired.

set clk_out_info                [get_instvalue clk_inv_out]

if {[llength $clk_out_info] > 0} {
  set clk_out_clock             [lindex $clk_out_info 0]

  if {[llength $clk_out_info] > 1} {
    set clk_out_port            [lindex $clk_out_info 1]
    set clk_out_target          "$clk_out_port"
    set_keyvalue                "$clk_out_port" "$clk_out_clock"
  } else {
    set clk_out_target          "$genclk_inst|out_inv_clk"
  }

  regsub -all "@" "$clk_out_target" "\\" clk_target

  if {[get_collection_size [get_nodes $clk_target]] > 0} {
    puts $sdc_log "Creating clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"

    create_generated_clock -source "$sysclk_source" -name "$clk_out_clock" \
                           -divide_by "$clk_div"          "$clk_target"

    set clk_out_data              [get_clocks "$clk_out_clock"]

    set_false_path -from $sysclk_data  -to $clk_out_data
    set_false_path -from $clk_out_data -to $sysclk_data
  } else {
    puts $sdc_log "Skipped clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"
  }
}

#   Generate gated clock if it is desired.

set clk_out_info                [get_instvalue gated_clk_out]

if {[llength $clk_out_info] > 0} {
  set clk_out_clock             [lindex $clk_out_info 0]

  if {[llength $clk_out_info] > 1} {
    set clk_out_port            [lindex $clk_out_info 1]
    set clk_out_target          "$clk_out_port"
    set_keyvalue                "$clk_out_port" "$clk_out_clock"
  } else {
    set clk_out_target          "$genclk_inst|out_gated_clk"
  }

  regsub -all "@" "$clk_out_target" "\\" clk_target

  if {[get_collection_size [get_nodes $clk_target]] > 0} {
    puts $sdc_log "Creating clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"

    create_generated_clock -source "$sysclk_source" -name "$clk_out_clock" \
                           -divide_by "$clk_div"          "$clk_target"

    set clk_out_data              [get_clocks "$clk_out_clock"]

    set_false_path -from $sysclk_data  -to $clk_out_data
    set_false_path -from $clk_out_data -to $sysclk_data
  } else {
    puts $sdc_log "Skipped clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"
  }
}

#   Generate inverted gated clock if it is desired.

set clk_out_info                [get_instvalue gated_clk_inv_out]

if {[llength $clk_out_info] > 0} {
  set clk_out_clock             [lindex $clk_out_info 0]

  if {[llength $clk_out_info] > 1} {
    set clk_out_port            [lindex $clk_out_info 1]
    set clk_out_target          "$clk_out_port"
    set_keyvalue                "$clk_out_port" "$clk_out_clock"
  } else {
    set clk_out_target          "$genclk_inst|out_inv_gated_clk"
  }

  regsub -all "@" "$clk_out_target" "\\" clk_target

  if {[get_collection_size [get_nodes $clk_target]] > 0} {
    puts $sdc_log "Creating clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"

    create_generated_clock -source "$sysclk_source" -name "$clk_out_clock" \
                           -divide_by "$clk_div"          "$clk_target"

    set clk_out_data              [get_clocks "$clk_out_clock"]

    set_false_path -from $sysclk_data  -to $clk_out_data
    set_false_path -from $clk_out_data -to $sysclk_data
  } else {
    puts $sdc_log "Skipped clock '$clk_out_clock' via '$sysclk_clock' on '$clk_target' from '$clk_out_info'\n"
  }
}
