#   Clock information passed through this entity.

set Collar_inst             [get_instance]

#   Power-up to all reset recovery times are not important.  Removal
#   recovery times are important.

set reset_inst              "GlobalClock:global_reset"
set reset_comp              "GlobalClock_altclkctrl_vch_component"
set reset_pin               "sd1|outclk"
set reset_target            "$Collar_inst|$reset_inst|$reset_comp|$reset_pin"

regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
            "$reset_target" {\1}   temp_path
regsub -all "@" "$temp_path" "\\" reset_path

set reset_data              [get_pins $reset_path]

set_false_path -from $reset_data -setup

set_keyvalue reset          $reset_path

#   Find source clock frequency.

set source_clock            [get_instvalue source_clk]

set source_clock_data       [get_clocks $source_clock]
set source_clock_period     [get_clock_info -period $source_clock_data]

set source_clock_freq       [expr {int(1.0e9 / \
                                       $source_clock_period)}]

#   Process SDC file for all collar instances.  Push the new instances onto
#   the instances stack beforehand and remove them afterwards.

#   Master clock.

set collar_master_clk_name  master_clk
set collar_gated_clk_name   master_gated_clk
set collar_inv_clk_name     master_gated_inv_clk
push_instance               "GenClock:master_clock"

set_instvalue               out_clk_freq_g    $shared_constants(source_clk_freq_c)
set_instvalue               clk_out           [list $collar_master_clk_name]
set_instvalue               gated_clk_out     [list $collar_gated_clk_name]
set_instvalue               gated_clk_inv_out [list $collar_inv_clk_name]

copy_instvalues             { "source_clk_freq_g,clk_freq_g" \
                              "source_clk,clk" }

source GenClock.sdc

pop_instance

#   SPI clock.

set collar_spi_clk_name     spi_clk
set collar_spi_g_clk_name   spi_gated_clk
set collar_spi_gi_clk_name  spi_gated_inv_clk
push_instance               "GenClock:spi_clock"

set_instvalue               out_clk_freq_g    $shared_constants(spi_clk_freq_c)
set_instvalue               clk               [list $collar_master_clk_name]
set_instvalue               clk_out           [list $collar_spi_clk_name]
set_instvalue               gated_clk_out     [list $collar_spi_g_clk_name]
set_instvalue               gated_clk_inv_out [list $collar_spi_gi_clk_name]

copy_instvalues             { "source_clk_freq_g,clk_freq_g" }

source GenClock.sdc

pop_instance

#   Process SDC file for System Time.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "SystemTime:@use_StrClk:system_clock"
set_instvalue               clk               [list $collar_master_clk_name]

source SystemTime.sdc

pop_instance

#   Process SDC file for Status/Control SPI.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

set sdc_file              "StatCtlSPI_FPGA.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "StatCtlSPI_FPGA:pc_spi"

  set_instvalue           clk "$collar_spi_g_clk_name"

  copy_instvalues         { "pc_spi_clk,sclk" }

  source StatCtlSPI_FPGA.sdc

  pop_instance
}

#   The SDRAM Controller.

set sdc_file              "SDRAM_Controller.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "SDRAM_Controller:@use_SDRAM:sdcard_buffer"
  set_instvalue           sysclk            [list $collar_master_clk_name]

  copy_instvalues         [list "sdram_clk,sdram_clk_out"]

  source $sdc_file

  pop_instance
}

#   The SD Card Controller.

set sdc_file              "microsd_controller_dir.sdc"

if { [file exists "$sdc_file"] > 0 } {

  #   Voltage shifting.

  set sd_clk_port         [get_instvalue sd_clk]

  push_instance           "microsd_controller_dir:@use_SD:sdcard"

  set clk_divide          [expr {int($source_clk_freq / 400000.0 + 0.5)}]

  set_instvalue           clk_divide_g $clk_divide
  set_instvalue           sd_clk [list $sd_clk_port sd_400 sd_clk_dir]
  set_instvalue           clk               [list $collar_master_clk_name]

  source $sdc_file

  pop_instance

  #   Direct connect.

  set sdh_clk_port        [get_instvalue sdh_clk]

  push_instance           "microsd_controller_dir:@use_SDH:sdcard"

  set clk_divide          [expr {int($source_clk_freq / 400000.0 + 0.5)}]

  set_instvalue           clk_divide_g $clk_divide
  set_instvalue           sd_clk [list $sdh_clk_port sdh_400 sdh_clk_dir]
  set_instvalue           clk               [list $collar_master_clk_name]

  source $sdc_file

  pop_instance
}

#   The GPS Controller

set sdc_file              "GPSmessages.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "GPSmessages:gps_ctl"
  set_instvalue           clk               [list $collar_master_clk_name]

  copy_instvalues         { "gps_rx_in,gps_rx_in" "gps_tx_out,gps_tx_out" }

  source $sdc_file

  pop_instance
}
