#   General Generated clock:
#     clk               Clock used to generate clocks from
#     clk_freq_g        Frequency of the clock to generated from.
#     out_clk_freq_g    Frequency of the clocks to generate.
#     clk_out           Continuously running generated clock and port.
#     clk_inv_out       Continuously running generated inverted clock and
#                       port.
#     gated_clk_out     Gated generated clock and port.
#     gated_clk_inv_out Gated generated inverted clock and port.

set genclk_inst                 [get_instance]
regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
            "$genclk_inst" {\1}   temp_path
regsub -all "@" "$temp_path" "\\" genclk_path

set sysclk_clock                [get_instvalue clk]

set sysclk_data                 [get_clocks $sysclk_clock]
set sysclk_source               [get_clock_info -targets $sysclk_data]

#   Determine the clock divider.

set clk_freq_g                  [get_instvalue clk_freq_g]
set out_clk_freq_g              [get_instvalue out_clk_freq_g]

set clk_div                     [expr {int($clk_freq_g / \
                                           $out_clk_freq_g)}]

#   Generate clock buffer pin names for all clock buffer types.

set clock_net_type_list         {"GlobalClock,vch" "DualClock,i2i"      \
                                 "QuadrantClock,vjh"}

set net_pin_list                [list]

foreach clock_type $clock_net_type_list {
  set type_list                 [split "$clock_type" ","]
  set net_type                  [lindex $type_list 0]
  set net_code                  [lindex $type_list 1]

  set clock_pin                 [format "%s:%s|%s_%s_%s_%s"             \
                                        "$net_type" "net_clock"         \
                                        "$net_type" "altclkctrl"        \
                                        "$net_code"                     \
                                        "component|sd1|outclk"]
  lappend net_pin_list          "$clock_pin"
}

#   Generate all clocks possibly produced by the entity.
#   Timings between the source clock and the generating clock are not
#   important and are broken.

set clk_list                    {clk clk_inv gated_clk gated_clk_inv}

foreach clock $clk_list {

  set clk_info                    [get_instvalue "${clock}_out"]

  if {[llength $clk_info] > 0} {
    set clk_name                  [lindex $clk_info 0]

    if {[llength $clk_info] > 1} {
      #   Try for an output port as the target.

      set clk_port                [lindex $clk_info 1]
      set_keyvalue                "$clk_port" "$clk_name"

      regsub -all "@" "$clk_port" "\\" clock_target
      set target_data             [get_nodes $clock_target]

    } else {
      #   Try all network clock types as clock targets.

      foreach net_pin $net_pin_list {
        set clock_target          "$genclk_path|\\${clock}_$net_pin"
        set target_data           [get_nodes $clock_target]

        if {[get_collection_size $target_data] > 0} {
          break
        }
      }

      #   Try for a normal, non clock network, clock.

      if {[get_collection_size $target_data] == 0} {
        set temp_path             "$genclk_inst|out_$clock"
        regsub -all "@" "$temp_path" "\\" clock_target
        set target_data           [get_nodes $clock_target]
      }
    }

    if {[get_collection_size $target_data] > 0} {
      puts $sdc_log [format "%s%s%s\n" "Creating clock '$clk_name' via "  \
                                       "'$sysclk_clock' on "              \
                                       "'$clock_target' from '$clk_info'"]

      create_generated_clock -source "$sysclk_source"                     \
                             -name   "$clk_name"                          \
                             -divide_by "$clk_div" "$clock_target"

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
