#   Magnetic Memory Controller
#   Uses the spi_commands.sdc and spi_abstract.sdc TCL files
#   However this time new clks/ports are passed down.
#   This allows reuse of the same TCL scripts any time a entity uses SPI core.
#   


set mm_spi_port             [get_instvalue sclk]

set mm_spi_clock            "MagMem_SPI_clock"

push_instance               "spi_commands:spi_commands_slave"

set_instvalue               sclk [list $mm_spi_port $mm_spi_clock]

copy_instvalues             { "clk,clk" }

source spi_commands.sdc

pop_instance
