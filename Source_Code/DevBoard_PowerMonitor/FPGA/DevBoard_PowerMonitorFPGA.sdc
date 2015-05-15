#   Project top level SDC file.  Defines timing at the top level.
#   Timing for sub-modules is included by this file (and other
#   sub-files these include).
#
#   All input and output clocks must be defined.  Each will be specified
#   as a false path as well to prevent the Time Analyser from considering
#   them as unconstrained paths.  (They have no input or output delays in
#   relation to other clocks.)
#   Input clocks used to constrain other pins must have virtual clocks
#   defined for them.  The delays associated with the input clock will be
#   set on the virtual clock.  Each external source for such an input clock
#   will likely have its own set of delays and thus need its own virtual
#   clock.
#   Output clocks will likely only have one set of delays these can be
#   set on the output clocks directly.
#
#   All input and output data pins must be constrained by delays associated
#   with a clock.  Either a virtual input clock or generated output clock.

set sdc_log [open "output_files/sdc_log.txt" w]

#   Read in all procedures used by SDC files.

source SDC_Procedures.sdc

#   Use timings as nanoseconds with three decimal places.

set decplaces     3

set_time_format -unit ns -decimal_places $decplaces

#   Main system clock.

set master_clk_freq     50.0e6

set master_clk_period   [expr 1.0e9 / $master_clk_freq]
set per                 [format "%.*f" $decplaces $master_clk_period]
set rise                [expr 0]
set fall                [expr $master_clk_period * 0.5]
set duty                [format "%.*f %.*f" $decplaces $rise $decplaces $fall]

set master_clk_target   [get_ports CLK_50MHZ_TO_FPGA]

create_clock -name master_clk -period $per -waveform $duty $master_clk_target
#create_clock -name master_clk -period 20.000 -waveform { 0.000 10.000 } \
#             [get_ports CLK_50MHZ_TO_FPGA]

#   The 'inst_mapping' array contains information needed by other levels.
#   The 'instance_stack' list is a stack of the instances from the top level
#   down.  A new top is added at the beginning of the list before each
#   source of the component instance's SDC file and remove or replaced
#   before return or the next SDC file is processed.
#
#   Information about entity ports is associated with those port names
#   and the instance they are for.  (set_instvalue)
#   Information about off-chip pins is associated with those port names
#   directly.  (set_keyvalue)

set top_level_inst            "Collar:C"
push_instance                 $top_level_inst

set_instvalue                 master_clk      $master_clk_target

set_instvalue                 i2c_clk_io      "SDA_TO_FPGA_CPLD"
set_instvalue                 pc_spi_clk      "PC_SPI_CLK"
set_instvalue                 sdram_clk       "SDRAM_CLK"
set_instvalue                 sd_clk          "SDCARD_CLK_TO_FPGA"
set_instvalue                 sdh_clk         "SDCARD_DI_CLK_TO_FPGA"
set_instvalue                 gps_rx_in       "TXD_GPS_TO_FPGA"
set_instvalue                 gps_tx_out      "RXD_GPS_TO_FPGA"
set_instvalue                 ms_clk          "IM2_SPI_SCLK"
set_instvalue                 magram_clk      "MRAM_SCLK_TO_FPGA"
set_instvalue                 mic_clk         "MIC_CLK"
set_instvalue                 radio_clk       "DATA_TX_CLK_TO_FPGA"

source Collar.sdc

#   Set the I/O port delays for all devices.

foreach sdc_file    [glob *_dev.sdc] {

    source $sdc_file
}

#   Log any other information.

# puts $sdc_log "All clocks:"
# foreach_in_collection clk [all_clocks] {
  # puts $sdc_log [get_clock_info -name $clk]
  # foreach_in_collection target [get_clock_info -targets $clk] {
    # puts $sdc_log "  $target"
  # }
# }

# puts $sdc_log "\nAll inputs:"
# foreach_in_collection in [all_inputs] {
  # puts $sdc_log [get_port_info -name $in]
# }

# puts $sdc_log "\nAll outputs:"
# foreach_in_collection out [all_outputs] {
  # puts $sdc_log [get_port_info -name $out]
# }

# puts $sdc_log "\nAll ports:"
# foreach_in_collection port [get_ports *] {
  # puts $sdc_log "[get_port_info -name $port] : $port"
# }

# puts $sdc_log "\nAll pins:"
# foreach_in_collection pin [get_pins -compatibility_mode *] {
  # puts $sdc_log "[get_pin_info -name $pin] : $pin"
# }

# puts $sdc_log "\nAll registers:"
# foreach_in_collection reg [all_registers] {
  # puts $sdc_log "[get_register_info -name $reg] : $reg"
# }

# puts $sdc_log "\nAll cells:"
# foreach_in_collection cell [get_cells -compatibility_mode *] {
  # puts $sdc_log "[get_cell_info -name $cell] : $cell"
# }

# puts $sdc_log "\nAll nets:"
# foreach_in_collection net [get_nets *] {
  # puts $sdc_log "[get_net_info -name $net] : $net"
# }

# puts $sdc_log "\nAll nodes:"
# foreach_in_collection node [get_nodes *] {
  # puts $sdc_log "[get_node_info -name $node] : [get_node_info -type $node] : $node"
# }


close $sdc_log
