set_time_format -unit ns -decimal_places 3

#   Main system clock.

create_clock -name sysclk -period 20.000 -waveform { 0.000 10.000 } [get_ports DDR3_CLK_50MHz]

#   The UART clocks are based on a baud rate of 9600 baud.
#     tx_clock = 9600      = 50,000,000 / 5208.333
#     rx_clock = 9666 * 16 = 50,000,000 /  325.521

create_generated_clock -source [get_registers sysclk] -divide_by 5208 -name tx_clock [get_registers tx_clock]
create_generated_clock -source [get_registers sysclk] -divide_by  326 -name rx_clock [get_registers rx_clock]

#   Millisecond generating clock from reset clock.

create_generated_clock -source [get_registers sysclk] -divide_by 50000 -name milli_clock [get_registers milli_clock]
