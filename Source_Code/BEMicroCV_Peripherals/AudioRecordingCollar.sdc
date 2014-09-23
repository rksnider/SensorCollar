set_time_format -unit ns -decimal_places 3

#   Main system clock.

set master_freq     50.0e6
set master_period   [expr {1.0e9 / $master_freq}]
set master_wave     [expr {$master_period / 2}]

create_clock -name master_clk                             \
             -period $master_period                       \
             -waveform { 0.000 $master_wave }             \
             [get_ports DDR3_CLK_50MHz]

#   GPS clocks.

set baud_rate       9600.0
set baud_per_byte   10.0
set rx_multiply     16.0
set parse_multiply  16.0

set byte_rate       [expr {$baud_rate / $baud_per_byte}]

set rx_clk_freq     [expr {$baud_rate * $rx_multiply}]
set tx_clk_freq     $baud_rate
set parse_clk_freq  [expr {$byte_rate * $parse_multiply}]

set rx_clk_div      [expr {int ($master_freq / $rx_clk_freq)}]
set tx_clk_div      [expr {int ($rx_clk_freq / $tx_clk_freq)}]
set parse_clk_div   [expr {int ($rx_clk_freq / $parse_clk_freq)}]

create_generated_clock -source [get_registers master_clk]         \
                       -divide_by $rx_clk_div -name rx_clk        \
                       [get_registers rx_clk]
create_generated_clock -source [get_registers rx_clk]             \
                       -divide_by $tx_clk_div -name tx_clk        \
                       [get_registers tx_clk]
create_generated_clock -source [get_registers rx_clk]             \
                       -divide_by $parse_clk_div -name parse_clk  \
                       [get_registers parse_clk]

#   The UART clocks are based on a baud rate of 9600 baud.
#     tx_clock = 9600      = 50,000,000 / 5208.333
#     rx_clock = 9666 * 16 = 50,000,000 /  325.521

#create_generated_clock -source [get_registers master_clk] -divide_by 5208 -name tx_clock [get_registers tx_clock]
#create_generated_clock -source [get_registers master_clk] -divide_by  326 -name rx_clock [get_registers rx_clock]

#   Millisecond clock is generated from the reset clock.

set milli_clk_freq    1000
set milli_clk_div     [expr {int {$master_freq / $milli_clk_freq)}]

create_generated_clock -source [get_registers master_clk]         \
                       -divide_by $milli_clk_div -name milli_clk  \
                       [get_registers milli_clk]


#   Millisecond generating clock from reset clock.

#create_generated_clock -source [get_registers master_clk] -divide_by 50000 -name milli_clock [get_registers milli_clock]
