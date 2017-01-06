#   Clock information passed through this entity.

set Collar_inst             [get_instance]

#   Power-up to all reset recovery times are not important.  Removal
#   recovery times are important.

set reset_inst              "GlobalClock:global_reset"
set reset_comp              "GlobalClock_altclkctrl_vch_component"
set reset_cell              "$Collar_inst|$reset_inst|$reset_comp|sd1"

regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
            "$reset_cell" {\1}    temp_path
regsub -all "@" "$temp_path" "\\" reset_path

set reset_cell_data         [get_pins "$reset_path|inclk"]
set reset_pin_data          [get_pins "$reset_path|outclk"]

set_false_path -through $reset_cell_data
set_false_path -from    $reset_pin_data  -setup

set_keyvalue reset          "$reset_path|outclk"

#   Remove all other resets from timing checks.

set reset_list              [list @use_SDRAM:sdram_reset]

foreach cell $reset_list {

  set reset_cell            "$Collar_inst|$cell"

  regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
              "$reset_cell" {\1}    temp_path
  regsub -all "@" "$temp_path" "\\" reset_path

  set reset_pin_data          [get_pins "$reset_path|combout"]

  puts $sdc_log "Linking broken through $reset_path\n"

  set_false_path -from        $reset_pin_data
}

#   Remove the on/off control lines from timing checks.

set onoff_cell                "$Collar_inst|PC_ControlSent"

regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
            "$onoff_cell" {\1}    temp_path
regsub -all "@" "$temp_path" "\\" cell_path

set cell_pin_data             [get_pins "$cell_path\[*]|combout"]

foreach_in_collection pin $cell_pin_data {
  set pin_name                [get_pin_info -name $pin]
  puts $sdc_log "Pin $pin: $pin_name\n"
}

set_false_path -through       $cell_pin_data
set_false_path -from          $cell_pin_data

#   Find source clock frequency.

set source_clock            [get_instvalue source_clk]

set source_clock_data       [get_clocks $source_clock]
set source_clock_period     [get_clock_info -period $source_clock_data]

set source_clock_freq       [expr {int(1.0e9 / \
                                       $source_clock_period)}]

#   Process SDC file for all collar instances.  Push the new instances onto
#   the instances stack beforehand and remove them afterwards.

#   Master clock.

set master_clk_freq_c       $shared_constants(source_clk_freq_c)

set collar_master_clk_name  master_clk
set collar_gated_clk_name   master_gated_clk
set collar_inv_clk_name     master_gated_inv_clk
push_instance               "GenClock:master_clock"

set_instvalue               out_clk_freq_g    $master_clk_freq_c
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

#   Process SDC file for GPS Memory MUX.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

set sdc_file              "ResourceMUX.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "ResourceMUX:@use_GPS_RAM:gps_resmux"

  set_instvalue           clk               "$collar_gated_clk_name"
  set_instvalue           resource_tbl_in   "gpsmemdst_clk_"

  source $sdc_file

  pop_instance
}

#   Process SDC file for Magnetic Memory MUX.  Push the new instance onto
#   the instances stack beforehand and remove it afterwards.

set sdc_file              "ResourceMUX.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "ResourceMUX:@use_MagMemBuffer:magmem_resmux"

  set_instvalue           clk               "$collar_spi_g_clk_name"
  set_instvalue           resource_tbl_in   "magmemsrc_clk_"

  source $sdc_file

  pop_instance
}

#   Process SDC file for Status/Control SPI.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

set sdc_file              "StatCtlSPI_FPGA.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "StatCtlSPI_FPGA:pc_spi"

  set_instvalue           clk "$collar_spi_g_clk_name"

  copy_instvalues         { "pc_spi_clk,sclk" }

  source $sdc_file

  pop_instance
}

#   Process SDC file for Logging Counter Array.

set sdc_file              "LoggingCounterArray.sdc"

if { [file exists "$sdc_file"] > 0} {

  push_instance           "LoggingCounterArray:@use_EventLogging:eventcnt"
  
  set_instvalue           clk [list "$collar_gated_clk_name" "eventcnt"]
  
  source $sdc_file
  
  pop_instance
}

#   The I2C bus.

set sdc_file              "i2c_master.sdc"

if { [file exists "$sdc_file"] > 0 } {

  set i2c_freq            400.0e3
  set i2c_clk             [get_instvalue i2c_clk_io]

  push_instance           "i2c_master:@use_I2C:i2c_master_i0"
  set_instvalue           clk           [list $collar_spi_clk_name]
  set_instvalue           iclk          [list $i2c_clk I2C_clock $i2c_freq]

  source $sdc_file

  pop_instance
}

#   The IMU Controller.

set sdc_file              "LSM9DS1_top.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "LSM9DS1_top:@use_Inertial:im"
  set_instvalue           clk               [list $collar_spi_clk_name]

  copy_instvalues         [list "ms_clk,sclk"]

  source $sdc_file

  pop_instance
}

#   The Magnetic Memory Controller.

set sdc_file              "magmem_controller.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "magmem_controller:@use_Magmem:magmem"
  set_instvalue           clk               [list $collar_spi_clk_name]

  copy_instvalues         [list "magram_clk,sclk"]

  source $sdc_file

  pop_instance
}

#   The Data Tansmitter

set sdc_file              "cc1120_top.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "CC1120_top:@use_Radio:txrx"
  set_instvalue           clk               [list $collar_spi_clk_name]

  copy_instvalues         [list "radio_clk,sclk"]

  source $sdc_file

  pop_instance
}

#   The Mems Microphone

set mic_clk_port          [get_instvalue mic_clk]

set sysclk_data           [get_clocks $collar_spi_clk_name]
set sysclk_source         [get_clock_info -targets $sysclk_data]

set mic_clk_clock         "mic_clock"

# Assign a generated clock to the port.

puts $sdc_log "Creating clock '$mic_clk_clock' on port '$mic_clk_port'\n"

create_generated_clock -source $sysclk_source -name "$mic_clk_clock" \
                       -invert "$mic_clk_port"

set_keyvalue              "$mic_clk_port" "$mic_clk_clock"


set sdc_file              "mems_microphone.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "mems_top_16:@use_PDMmic:mright"
  set_instvalue           clk               [list $collar_spi_clk_name]

  source $sdc_file

  pop_instance

  push_instance           "mems_top_16:@use_PDMmic:mleft"
  set_instvalue           clk               [list $collar_spi_clk_name]

  source $sdc_file

  pop_instance
}

#   FlashBlock

set sdc_file              "FlashBlock.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "FlashBlock:@use_FlashBlock:flashblk"
  set_instvalue           clock_sys         [list $collar_spi_clk_name]

  source $sdc_file

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

#   The SD Card Loader.

set sdc_file              "sd_loader.sdc"

if { [file exists "$sdc_file"] > 0 } {

  #   Voltage shifting.

  push_instance           "sd_loader:@use_SD:sdload"
  set_instvalue           clk               [list $collar_master_clk_name]
  set_instvalue           sd_outmem_buffready_out                       \
                                            [list sd_loader_buff_ready]

  source $sdc_file

  pop_instance

  #   Direct connect.

  push_instance           "sd_loader:@use_SDH:sdload"
  set_instvalue           clk               [list $collar_master_clk_name]
  set_instvalue           sd_outmem_buffready_out                       \
                                            [list sdh_loader_buff_ready]

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

  push_instance           "GPSmessages:@use_GPS:gps_ctl"
  set_instvalue           clk_freq_g        $master_clk_freq_c
  set_instvalue           clk               [list $collar_master_clk_name]

  copy_instvalues         { "gps_rx_io,gps_rx_in" "gps_tx_out,gps_tx_out" }

  source $sdc_file

  pop_instance
}

#   Define the power-up clock used to drive the reset line.  This must be
#   done after all other clocks have been defined.

set all_clocks              [all_clocks]

set pu_time_c               0.5
set pu_count_c              [expr {int( $master_clk_freq_c * $pu_time_c)}]
set pu_divide               [expr {min( $pu_count_c, 10000)}]

set master_data             [get_clocks $collar_master_clk_name]
set power_up_path           [get_clock_info -targets $master_data]
set power_up_target         "$Collar_inst|power_up"

set power_up_name           "power_up"

create_generated_clock -source "$power_up_path" -divide_by $pu_divide     \
                       -name   "$power_up_name" "$power_up_target"

set clock_data              [get_clocks "$power_up_name"]

set_false_path -from $clock_data -to $all_clocks
set_false_path -from $all_clocks -to $clock_data
