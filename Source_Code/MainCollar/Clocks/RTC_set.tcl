#   Set the RTC Time to the current epoch70 time
#
#   This script must be run by the quartus_stp command shell.
#     quartus_stp -t RTC_set.tcl
#
#   This command shell is located in the quartus bin dirctory, possibly
#     altera/quartus/quartus/bin64

#   Setup the USB Blaster hardware.
#   JTAG chain.

set usb_blaster     [lindex [get_hardware_names] 0]
set fpga            [lindex [get_device_names -hardware_name $usb_blaster] 1]

#   Determine the current time in hex.

set cur_time        [format "%08X" [clock seconds]]

#   Set the current time in the FPGA.

puts "Setting time on '$usb_blaster' '$fpga' to '$cur_time'"

start_insystem_source_probe -device_name $fpga -hardware_name $usb_blaster

write_source_data -instance_index 0 -value "000000000"  -value_in_hex
write_source_data -instance_index 0 -value "0$cur_time" -value_in_hex
write_source_data -instance_index 0 -value "1$cur_time" -value_in_hex
write_source_data -instance_index 0 -value "0$cur_time" -value_in_hex

end_insystem_source_probe
