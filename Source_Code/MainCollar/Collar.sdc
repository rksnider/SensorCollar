#   Clock information passed through this entity.

# set Collar_inst             [get_instance]

# regsub -all {[A-Za-z0-9_]+:} $Collar_inst "" Collar_inst_name


#   Process SDC file for all collar instances.  Push the new instances onto
#   the instances stack beforehand and remove them afterwards.

#   The SD Card Controller.

set sdc_file                "microsd_controller.sdc"

  if { [file exists "$sdc_file"] > 0 } {

    push_instance           "microsd_controller:sdcard"

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
