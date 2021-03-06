#   cc1120_top
#   Uses the spi_commands.sdc and spi_abstract.sdc TCL files
#   However this time new clks/ports are passed down.
#   This allows reuse of the same TCL scripts any time a entity uses SPI core.
#   


set txrx_spi_port           [get_instvalue sclk]

set txrx_spi_clock          "TXRX_SPI_clk"

push_instance               "spi_commands:spi_commands_slave"

set_instvalue               sclk [list $txrx_spi_port $txrx_spi_clock]

copy_instvalues             { "clk,clk" }

source spi_commands.sdc

pop_instance
