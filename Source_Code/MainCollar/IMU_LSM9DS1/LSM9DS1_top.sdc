#   LSM9DS1_top
#   Uses the spi_commands.sdc and spi_abstract.sdc TCL files
#   However this time new clks/ports are passed down.
#   This allows reuse of the same TCL scripts any time a entity uses SPI core.
#   


set im_spi_port             [get_instvalue sclk]

set im_spi_clock            "IMU_SPI_clock"

push_instance               "spi_commands:spi_commands_slave_XL_G"

set_instvalue               sclk [list $im_spi_port $im_spi_clock]

copy_instvalues             { "clk,clk" }

source spi_commands.sdc

pop_instance
