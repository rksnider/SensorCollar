#   SD Card Timing information.
#   Perform SD Card data constraining at the pins.

set clock_name                [get_keyvalue "PC_SPI_CLK"]

set clock_data                [get_clocks $clock_name]
set clock_period              [get_clock_info -period $clock_data]

derive_clock_uncertainty

