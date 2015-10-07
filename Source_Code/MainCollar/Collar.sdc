#   Clock information passed through this entity.

set Collar_inst             [get_instance]

# regsub -all {[A-Za-z0-9_]+:} $Collar_inst "" Collar_inst_name


#   Power-up to all reset recovery times are not important.  Removal
#   recovery times are important.

set_false_path -from [get_registers "$Collar_inst|power_up"] -setup

#   Find master clock frequency.

set master_clock            [get_instvalue master_clk]

set master_clock_data       [get_clocks $master_clock]
set master_clock_period     [get_clock_info -period $master_clock_data]

set master_clock_freq       [expr {int(1.0e9 / \
                                       $master_clock_period)}]

#   Process SDC file for all collar instances.  Push the new instances onto
#   the instances stack beforehand and remove them afterwards.

#   SPI clock.

set collar_spi_clk_name     spi_clk
set collar_spi_g_clk_name   spi_gated_clk
set collar_spi_gi_clk_name  spi_gated_inv_clk
push_instance               "GenClock:spi_clock"

set_instvalue               out_clk_freq_g    $shared_constants(spi_clk_freq_c)
set_instvalue               clk_out           [list $collar_spi_clk_name]
set_instvalue               gated_clk_out     [list $collar_spi_g_clk_name]
set_instvalue               gated_clk_inv_out [list $collar_spi_gi_clk_name]

copy_instvalues             { "master_clk_freq_g,clk_freq_g" \
                              "master_clk,clk" }

source GenClock.sdc

pop_instance

#   Master clock.

set collar_master_clk_name  master_gated_clk
set collar_inv_clk_name     master_gated_inv_clk
push_instance               "GenClock:master_gated_clock"

set_instvalue               out_clk_freq_g    $shared_constants(master_clk_freq_c)
set_instvalue               gated_clk_out     [list $collar_master_clk_name]
set_instvalue               gated_clk_inv_out [list $collar_inv_clk_name]

copy_instvalues             { "master_clk_freq_g,clk_freq_g" \
                              "master_clk,clk" }

source GenClock.sdc

pop_instance

#   Process SDC file for System Time.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "SystemTime:@use_StrClk:system_clock"

copy_instvalues             { "master_clk,clk" }

source SystemTime.sdc

pop_instance

#   The SDRAM Controller.

set sdc_file              "SDRAM_Controller.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "SDRAM_Controller:@use_SDRAM:sdcard_buffer"

  copy_instvalues         [list "master_clk,sysclk" \
                                "sdram_clk,sdram_clk_out"]

  source $sdc_file

  pop_instance
}

#   Process SDC file for Status/Control SPI.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "StatCtlSPI_FPGA:pc_spi"

set_instvalue               clk "$collar_spi_clk_name"

copy_instvalues             { "pc_spi_clk,sclk" }

source StatCtlSPI_FPGA.sdc

pop_instance

#   The SDRAM Controller.

set sdc_file              "SDRAM_Controller.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "SDRAM_Controller:@use_SDRAM:sdcard_buffer"

  copy_instvalues         [list "master_clk,sysclk" \
                                "sdram_clk,sdram_clk_out"]

  source $sdc_file

  pop_instance
}

#   The SD Card Controller.

set sdc_file              "microsd_controller_dir.sdc"

if { [file exists "$sdc_file"] > 0 } {

  #   Voltage shifting.

  set sd_clk_port         [get_instvalue sd_clk]

  push_instance           "microsd_controller_dir:@use_SD:sdcard"

  set clk_divide          [expr {int($master_clk_freq / 400000.0 + 0.5)}]

  set_instvalue           clk_divide_g $clk_divide
  set_instvalue           sd_clk [list $sd_clk_port sd_400 sd_clk_dir]

  copy_instvalues         [list "master_clk,clk"]

  source $sdc_file

  pop_instance

  #   Direct connect.

  set sdh_clk_port        [get_instvalue sdh_clk]

  push_instance           "microsd_controller_dir:@use_SDH:sdcard"

  set clk_divide          [expr {int($master_clk_freq / 400000.0 + 0.5)}]

  set_instvalue           clk_divide_g $clk_divide
  set_instvalue           sd_clk [list $sdh_clk_port sdh_400 sdh_clk_dir]

  copy_instvalues         [list "master_clk,clk"]

  source $sdc_file

  pop_instance
}

#   The GPS Controller

set sdc_file              "GPSmessages.sdc"

if { [file exists "$sdc_file"] > 0 } {

  push_instance           "GPSmessages:gps_ctl"

  copy_instvalues         { "master_clk,clk" "gps_rx_in,gps_rx_in" \
                            "gps_tx_out,gps_tx_out" }

  source $sdc_file

  pop_instance
}
