#   I2C specific clock:
#     iclk      The information associated with it is the port it goes out
#               of and the clock name for it.

set sysclk_clock                [get_instvalue clk]

set i2c_clk_info                [get_instvalue iclk]
set i2c_clk_port                [lindex $i2c_clk_info 0]
set i2c_clock                   [lindex $i2c_clk_info 1]
set i2c_freq                    [lindex $i2c_clk_info 2]

set sysclk_data                 [get_clocks $sysclk_clock]
set sysclk_source               [get_clock_info -targets $sysclk_data]

# Determine the clock divider.

set sysclk_period               [get_clock_info -period  $sysclk_data]
set sysclk_freq                 [expr 1.0 / ($sysclk_period * 1.0e-9)]

set divisor                     [expr int( $sysclk_freq / $i2c_freq + 0.5)]

# Find the internal clock that drives the clock pin.

set i2c_inst                    [get_instance]
regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:}                        \
            "$i2c_inst" {\1}    temp_path
regsub -all "@" "$temp_path" "\\" i2c_path

set i2c_scl_path                "$i2c_path|scl_clk"
set i2c_scl                     [get_nodes $i2c_scl_path]

# Assign a generated clock to the internal path and the port.

puts $sdc_log "Creating clock '$i2c_clock' on port '$i2c_clk_port' from '$i2c_clk_info'\n"

if {$divisor > 1} {
  create_generated_clock -source $sysclk_source -name "${i2c_clock}_scl" \
                         -invert -divide_by $divisor "$i2c_scl"
} else {
  create_generated_clock -source $sysclk_source -name "${i2c_clock}_scl" \
                         -invert "$i2c_scl"
}

create_generated_clock -source $i2c_scl_path -name "$i2c_clock" \
                        "$i2c_clk_port"

set_keyvalue                    "$i2c_clk_port" "$i2c_clock"
