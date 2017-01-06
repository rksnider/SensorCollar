#   Cross Chip Send Latches:
#     clk               Clock used to generate latches from
#     clk_freq_g        Frequency of the clock to generated from.
#     data_latch_out    Data latch used as a clock.
#     valid_latch_out   Data latch used as a clock when valid line high.

set ccs_inst                      [get_instance]

set sysclk_clock                  [get_instvalue fast_clk]

set sysclk_data                   [get_clocks $sysclk_clock]
set sysclk_source                 [get_clock_info -targets $sysclk_data]

#   Generate all clocks possibly produced by the entity.

set clk_list                      {data_latch_out,clock_high            \
                                   valid_latch_out,valid_high}

set latch_clocks                  [list]

foreach clock_data $clk_list {

  set clock_list                  [split "$clock_data" ","]
  set clock                       [lindex $clock_list 0]
  set target                      [lindex $clock_list 1]

  set clk_info                    [get_instvalue "$clock"]

  if {[llength $clk_info] > 0} {
    set clk_name                  [lindex $clk_info 0]

    set temp_path                 "$ccs_inst|$target"
    regsub -all "@" "$temp_path" "\\" clock_target
    set target_data               [get_registers $clock_target]

    #   Create the clock for the given target.

    if {[get_collection_size $target_data] > 0} {
      puts $sdc_log [format "%s%s%s\n" "Creating clock '$clk_name' via "  \
                                       "'$sysclk_clock' on "              \
                                       "'$clock_target' from '$clk_info'"]

      create_generated_clock -source "$sysclk_source" -invert             \
                             -name   "$clk_name" "$clock_target"

      lappend latch_clocks        "$clk_name"
      set clk_data                [get_clocks "$clk_name"]

      set_false_path -from $sysclk_data -to $clk_data
      set_false_path -from $clk_data    -to $sysclk_data
    } else {
      puts $sdc_log [format "%s%s%s\n" "Skipped clock '$clk_name' via "   \
                                       "'$sysclk_clock' on "              \
                                       "'$clock_target' from '$clk_info'"]
    }
  }
}

#   The valid latch follows the data latch by one clock cycle.

if {[llength $latch_clocks] >= 2} {
  set data_latch                  [get_clocks [lindex $latch_clocks 0]]
  set valid_latch                 [get_clocks [lindex $latch_clocks 1]]

  set_false_path -from $data_latch  -to $valid_latch
  set_false_path -from $valid_latch -to $data_latch
}
