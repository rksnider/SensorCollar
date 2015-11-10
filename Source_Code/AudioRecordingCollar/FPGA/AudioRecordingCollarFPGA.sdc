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
puts $sdc_log "name of executable is $::quartus(nameofexecutable)\n"
puts $sdc_log "sdc log file open at [clock format [clock seconds]] \n"

#if { 1 != [info exists instance_stack]} {

#   Read in all procedures used by SDC files.

source SDC_Procedures.sdc


#   Build an array of all constants shared between SDC and VHDL.

source sdc_values.tcl

foreach {name type value} $sdc_value_list {
  set shared_constants($name)     $value
}

#   Build an array of all the collar entity ports that map to I/O ports.

set portmap_tcl                   [lindex [glob PortMapping_*.tcl] 0]

source $portmap_tcl

set_ioports                       $ioport_list

#   Use timings as nanoseconds with three decimal places.

set decplaces     3

set_time_format -unit ns -decimal_places $decplaces

#   Main system clock.

set source_clk_freq     $shared_constants(source_clk_freq_c)

set source_clk_period   [expr 1.0e9 / $source_clk_freq]
set per                 [format "%.*f" $decplaces $source_clk_period]
set rise                [expr 0]
set fall                [expr $source_clk_period * 0.5]
set duty                [format "%.*f %.*f" $decplaces $rise $decplaces $fall]

set source_clk_target   [get_ports CLK_50MHZ_TO_FPGA]
set source_clk_name     source_clk

create_clock -name $source_clk_name -period $per -waveform $duty \
                   $source_clk_target

#create_clock -name source_clk -period 20.000 -waveform { 0.000 10.000 } \
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

set_instvalue                 source_clk_freq_g $source_clk_freq
set_instvalue                 source_clk        $source_clk_name

set_instvalue                 i2c_clk_io        "I2C_SDA"
set_instvalue                 pc_spi_clk        "PC_SPI_CLK"
set_instvalue                 sdram_clk         "SDRAM_CLK"
#set_instvalue                 sd_clk            "SDCARD_CLK_TO_FPGA"
set_instvalue                 sdh_clk           "SDCARD_DI_CLK_TO_FPGA"
set_instvalue                 gps_rx_io         "TXD_GPS_TO_FPGA"
set_instvalue                 gps_tx_out        "RXD_GPS_TO_FPGA"
set_instvalue                 ms_clk            "IM_SPI_SCLK_TO_FPGA"
set_instvalue                 magram_clk        "MRAM_SCK_TO_FPGA"
set_instvalue                 mic_clk           "MIC_CLK_TO_FPGA"
#set_instvalue                 radio_clk         "DATA_TX_CLK_TO_FPGA"

source Collar.sdc


# Breaking all paths between asynchronous signals and
# synchronized counterparts (*_s).

set sync_signals            [get_nets {*_s}]
set sync_vectors            [get_nets {*_s[*]}]
set sync_list               [add_to_collection $sync_signals $sync_vectors]

if {[get_collection_size $sync_list] > 0} {

  foreach_in_collection reg $sync_list {

    set sync_name           [get_object_info -name $reg]

    # regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:} "$sync_name" {\1} cell_path
    # set sync                [get_cells $cell_path]

    set sync                [get_cells "$sync_name"]

    if {[get_collection_size $sync] > 0} {
      set_false_path -through $sync
      puts $sdc_log "Breaking async paths '$sync_name'\n"
    } else {
      puts $sdc_log "'$cell_path' missing\n"
    }
  }
}

#   Set the I/O port delays for all devices.

foreach sdc_file    [glob *_dev.sdc] {
    puts $sdc_log "Processing $sdc_file\n"
    source $sdc_file
}

# #   Log any other information.

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

# }

puts $sdc_log "done at [clock format [clock seconds]] \n"

close $sdc_log
