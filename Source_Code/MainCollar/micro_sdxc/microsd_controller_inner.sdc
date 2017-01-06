#   SD Controller specific clocks:
#     clk       The information associated with it is the port it goes out
#               of and the clock names for it.



set microsd_inst              [get_instance]

# regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:} $microsd_inst \
#             {\1} microsd_inst_name

#   Find information about the entity's clock.

set sysclk_clock              [get_instvalue clk]

set sdclk_info                [get_instvalue sclk]

#set sdclk_name                [lindex $sdclk_info 0]
set sdclk_port                [lindex $sdclk_info 0]
#The following 2 elements are names we are going to associate with the
#generated clocks.
set sdclk_400                 [lindex $sdclk_info 1]
set sdclk_dir                 [lindex $sdclk_info 2]


set sdclk_dir_400             "${sdclk_dir}_400"

set sysclk_data               [get_clocks $sysclk_clock]
set sysclk_source             [get_clock_info -targets $sysclk_data]

#   Assign two generated clocks to the port.

#   400K clock.

set sd_400_divideby           [get_instvalue clk_divide_g]

set sysclk_freq               [expr 1.0 / (1.0e-9 *                     \
                                  [get_clock_info -period $sysclk_data])]

push_instance                 "GenClock:clk_400_gen"

set_instvalue clk_freq_g      [expr int( $sysclk_freq)]
set_instvalue out_clk_freq_g  [expr int( $sysclk_freq /                 \
                                  (1.0 * $sd_400_divideby))]

set_instvalue                 gated_clk_out     [list $sdclk_400]

copy_instvalues               { "clk,clk" }

source GenClock.sdc

pop_instance

#   I/O port clocks.

set sdclk_400_data            [get_clocks $sdclk_400]

if {[get_collection_size $sdclk_400_data] > 0} {
  set sdclk_400_source        [get_clock_info -targets $sdclk_400_data]
  set sdclk_400_period        [get_clock_info -period  $sdclk_400_data]

  create_generated_clock -name "$sdclk_dir" -source "$sysclk_source"      \
                         "$sdclk_port"
  create_generated_clock -name "$sdclk_dir_400"                           \
                         -source "$sdclk_400_source" -add "$sdclk_port"

  puts $sdc_log "Creating Clocks '$sdclk_dir' and '$sdclk_dir_400' on '$sdclk_port'\n"

  set sdclk_data              [get_clocks $sdclk_dir]
  set sdclk_period            [get_clock_info -period $sdclk_data]


  set sd_clk_ext_in_name      sdclk_dir_in_ext
  set sd_clk_400_ext_in_name  sd_clk_400_in_ext

  set sd_clk_ext_out_name     sdclk_dir_out_ext
  set sd_clk_400_ext_out_name sd_clk_400_out_ext

  # Create Virtual clocks for input_delay constraints.
  create_clock -period $sdclk_period     -name $sd_clk_ext_in_name
  create_clock -period $sdclk_400_period -name $sd_clk_400_ext_in_name

  # Create Virtual clocks for the output delay constrains.
  create_clock -period $sdclk_period     -name $sd_clk_ext_out_name
  create_clock -period $sdclk_400_period -name $sd_clk_400_ext_out_name

  # A mutliplexer at microsd_controller_inner requires separation between
  # fast and 400k sd clocks.
  set_clock_groups -exclusive -group [list $sdclk_dir $sysclk_clock       \
                                           $sd_clk_ext_in_name            \
                                           $sd_clk_ext_out_name]          \
                              -group [list $sdclk_dir_400 $sdclk_400      \
                                           $sd_clk_400_ext_in_name        \
                                           $sd_clk_400_ext_out_name]

  # Use the set_keyvalue so we can get at these from SDcard_dev.sdc
  set_keyvalue  "$sdclk_port" [list "$sysclk_clock" "$sdclk_400"          \
                                    "$sdclk_dir" "$sdclk_dir_400"         \
                                    "$sd_clk_ext_in_name"                 \
                                    "$sd_clk_400_ext_in_name"             \
                                    "$sd_clk_ext_out_name"                \
                                    "$sd_clk_400_ext_out_name"]
} else {
  puts $sdc_log "Skipping Clocks '$sdclk_dir' and '$sdclk_dir_400' on '$sdclk_port'\n"
}
