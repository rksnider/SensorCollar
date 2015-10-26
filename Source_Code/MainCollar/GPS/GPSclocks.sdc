#   GPS specific clocks:
#     gps_clk           Gated clock.
#     gps_tx_clk        Gated clock.
#     gps_parse_clk     Gated clock.
#     gps_memalloc_clk  Gated clock.
#     gps_memory_clk    Gated, inverted clock.

set sysclk_clock        [get_instvalue clk]
set gps_rx_port         [get_instvalue gps_clk_out]
set gps_tx_port         [get_instvalue tx_clk_out]

#   Specify the clocks that can't interact well in TimeQuest with the
#   clocks defined in this file.

set interact_list       [list StartupTime_milli_clk StartupTime_milli8_clk]
set interact_data       [get_clocks $interact_list]

#   Determine the output clocks and frequencies.

set gps_clk_name        "gps_clk"
set gps_tx_clk_name     "gps_tx_clk"
set gps_parse_clk_name  "gps_parse_clk"
set gps_alloc_clk_name  "gps_memalloc_clk"
set gps_memory_clk_name "gps_memory_clk"

set gps_tx_clk_freq     $shared_constants(gps_baud_rate_c)
set gps_clk_freq        [expr {int($gps_tx_clk_freq * 16.0)}]
set gps_parse_clk_freq  [expr {int($gps_tx_clk_freq * 16.0 / 10.0)}]

#   Create the GPS clock used for the RX port and creation of other GPS
#   clocks.

push_instance           "GenClock:gpsclk_gen"

set_instvalue           out_clk_freq_g    $gps_clk_freq
set_instvalue           gated_clk_out     [list $gps_clk_name]

copy_instvalues         { "clk_freq_g,clk_freq_g" "clk,clk" }

source GenClock.sdc

set_keyvalue            "$gps_rx_port"    "$gps_clk_name"

if {[get_collection_size $interact_data] > 0} {
  set clock_data        [get_clocks $gps_clk_name]

  set_false_path -from  $clock_data -to   $interact_data
  set_false_path -to    $clock_data -from $interact_data
}

pop_instance

#   Create the GPS clock used for the TX port.

push_instance           "GenClock:txclk_gen"

set_instvalue           clk_freq_g        $gps_clk_freq
set_instvalue           clk               [list $gps_clk_name]

set_instvalue           out_clk_freq_g    $gps_tx_clk_freq
set_instvalue           gated_clk_out     [list $gps_tx_clk_name]

source GenClock.sdc

set_keyvalue            "$gps_tx_port"    "$gps_tx_clk_name"

if {[get_collection_size $interact_data] > 0} {
  set clock_data        [get_clocks $gps_tx_clk_name]

  set_false_path -from  $clock_data -to   $interact_data
  set_false_path -to    $clock_data -from $interact_data
}

pop_instance

#   Create the GPS Parse clock used by most GPS components.

push_instance           "GenClock:parseclk_gen"

set_instvalue           clk_freq_g        $gps_clk_freq
set_instvalue           clk               [list $gps_clk_name]

set_instvalue           out_clk_freq_g    $gps_parse_clk_freq
set_instvalue           gated_clk_out     [list $gps_parse_clk_name]

source GenClock.sdc

if {[get_collection_size $interact_data] > 0} {
  set clock_data        [get_clocks $gps_parse_clk_name]

  set_false_path -from  $clock_data -to   $interact_data
  set_false_path -to    $clock_data -from $interact_data
}

pop_instance

#   Create the GPS memory clocks.

push_instance           "GenClock:memclk_gen"

set_instvalue           clk_freq_g        $gps_parse_clk_freq
set_instvalue           clk               [list $gps_parse_clk_name]

set_instvalue           out_clk_freq_g    $gps_parse_clk_freq
set_instvalue           gated_clk_out     [list $gps_alloc_clk_name]
set_instvalue           gated_clk_inv_out [list $gps_memory_clk_name]

source GenClock.sdc

if {[get_collection_size $interact_data] > 0} {
  set clock_data        [get_clocks [list $gps_alloc_clk_name           \
                                          $gps_memory_clk_name]]

  set_false_path -from  $clock_data -to   $interact_data
  set_false_path -to    $clock_data -from $interact_data
}

pop_instance
