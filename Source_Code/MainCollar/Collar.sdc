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
push_instance               "GenClock:spi_clock"

set_instvalue               out_clk_freq_g  $shared_constants(spi_clk_freq_c)
set_instvalue               clk_out         [list $collar_spi_clk_name]
set_instvalue               gated_clk_out   { }

copy_instvalues             { "master_clk_freq_g,clk_freq_g" \
                              "master_clk,clk" }

source GenClock.sdc

pop_instance

#   The SD Card Controller.

set sdc_file                "microsd_controller.sdc"

  if { [file exists "$sdc_file"] > 0 } {

    push_instance           "microsd_controller:sdcard"

    set clk_divide          [expr {int($master_clk_freq / 400000.0 + \
                                                          0.5)}]

    set_instance            CLK_DIVIDE $clk_divide

    #set sd_driven_clk       "sd_clk"
    set sd_driven_clk       "sdh_clk"

    copy_instvalues         [list "master_clk,clk" "$sd_driven_clk,sd_clk"]

    source $sdc_file

    pop_instance
  }
}

#   The GPS Controller

set sdc_file                "GPSmessages.sdc"

  if { [file exists "$sdc_file"] > 0 } {

    push_instance           "GPSmessages:gps_ctl"

    copy_instvalues         { "master_clk,clk" "gps_rx_in,gps_rx_in" \
                              "gps_tx_out,gps_tx_out" }

    source $sdc_file

    pop_instance
  }
}
