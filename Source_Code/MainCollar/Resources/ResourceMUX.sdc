#   Resource MUX defined clocks.
#     resource_tbl_in   Clock name prefix to apply each clock's and
#                       requester's number to.

set mux_inst                      [get_instance]

#   Determine if any clocks are needed and what they are.

set clock_prefix                  [get_instvalue "resource_tbl_in"]

set source_cell                   [format "%s|clocks" $mux_inst]

regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                          \
        "$source_cell" {\1}       temp_path
regsub -all "@" "$temp_path"      "\\" source_path

set clock_nets                    [get_nets -nowarn -no_duplicates        \
                                            ${source_path}*]

#   Find the number of clocks and requesters from the entity's clock array.

if {[get_collection_size $clock_nets] > 0} {
  puts $sdc_log "Creating clocks for '$source_path'\n"

  set dimensions                  [list 0 0]

  foreach_in_collection net $clock_nets {
    set net_name                  [get_net_info -name $net]

    regsub -all {[^[]*\[([^]]+)]} $net_name {\1 } indexes
    set index_list                [concat $indexes]

    for {set i 0} {$i < [llength $dimensions]} {incr i} {
      lset dimensions $i          [expr {max ([lindex $dimensions $i],    \
                                              [lindex $index_list $i] + 1)}]
    }
  }

  #   Find the number of resouces that are output.

  set out_cell                    [format "%s|resources_out" $mux_inst]

  regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
          "$out_cell" {\1}        temp_path
  regsub -all "@" "$temp_path"    "\\" out_path

  set out_nets                    [get_nets -no_duplicates ${out_path}*]

  set out_counts                  [list 0]

  foreach_in_collection net $out_nets {
    set net_name                  [get_net_info -name $net]

    regsub -all {[^[]*\[([^]]+)]} $net_name {\1 } indexes
    set index_list                [concat $indexes]

    for {set i 0} {$i < [llength $out_counts]} {incr i} {
      lset out_counts $i          [expr {max ([lindex $out_counts $i],    \
                                              [lindex $index_list $i] + 1)}]
    }
  }

  #   Create clocks for all clock signals in the clock array.

  set out_bits                    [lindex $out_counts 0]

  set clock_count                 [lindex $dimensions 0]
  set req_count                   [lindex $dimensions 1]

  set clock_start                 [expr $out_bits - $clock_count]

  set clock_groups                [list set_clock_groups                  \
                                        -logically_exclusive]

  for {set clkno 0} {$clkno < $clock_count} {incr clkno} {
    for {set reqno 0} {$reqno < $req_count} {incr reqno} {

      #   Find the clock source and target paths.

      set source_net              [format {%s|clocks[%d][%d]}             \
                                          $mux_inst $clkno $reqno]
      set target_net              [format {%s|resources_out[%d]}          \
                                          $mux_inst [expr $clock_start +  \
                                                          $clkno]]

      regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                    \
              "$source_net" {\1}        temp_path
      regsub -all "@" "$temp_path"      "\\" source_path

      regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                    \
              "$target_net" {\1}        temp_path
      regsub -all "@" "$temp_path"     "\\" target_path

      #   Generate a clock from the source to the target.

      set clock_name                [format "%s%d%02d" $clock_prefix      \
                                            $clkno $reqno]

      puts $sdc_log [format "%s%s%s\n" "Creating clock '$clock_name' "    \
                                       "via '$source_path' "              \
                                       "on '$target_path'"]

      create_generated_clock -source "$source_path" -name "$clock_name"   \
                             -add    "$target_path"

      lappend clock_groups "-group" "$clock_name"
    }
  }

  #   Create clock groups for each MUX clock.

  puts $sdc_log "Creating clock groups '$clock_groups'\n"

  eval $clock_groups

} else {
  puts $sdc_log "Skipping clocks for '$source_path'\n"
}
