#   Interrupt Controller update clock
#     The speed of the components that use the interrupt controller are
#     unknown.  Thus the clock uses the maximum clock rate.
#  update_clk   Name for this clock.  Each interrupt controller instance must
#               use a different name.

set intctl_inst                 [get_instance]

set sysclk_clock                master_clk

set sysclk_data                 [get_clocks $sysclk_clock]
set sysclk_source               [get_clock_info -targets $sysclk_data]

#   Generate the continuously running clock if it is desired.
#   Timings between the source clock and the generating clock are not
#   important.

set update_clk                  [get_instvalue update_clk]

set clk_out_target              "$intctl_inst|update_clk"

regsub -all "@" "$clk_out_target" "\\" clk_target

if {[get_collection_size [get_nodes $clk_target]] > 0} {
  puts $sdc_log "Creating clock '$update_clk' via '$sysclk_clock' on '$clk_target'\n"

  create_generated_clock -source "$sysclk_source" -name "$update_clk" \
                                                        "$clk_target"
} else {
  puts $sdc_log "Skipped clock '$update_clk' via '$sysclk_clock' on '$clk_target'\n"
}

# set clk_out_data                [get_clocks "$update_clk"]
#
# set_false_path -from $sysclk_data  -to $clk_out_data
# set_false_path -from $clk_out_data -to $sysclk_data
