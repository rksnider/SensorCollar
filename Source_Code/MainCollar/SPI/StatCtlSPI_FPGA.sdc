#   Clock information passed through this entity.

# set statctl_spi_inst        [get_instance]

# regsub -all {^[A-Za-z0-9_]+:|(\|)[A-Za-z0-9_]+:} $statctl_spi_inst \
#             {\1} statctl_spi_inst_name


#   Process SDC file for SPI command.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

set pc_spi_port             [get_instvalue sclk]
set pc_spi_clock            "PC_SPI_clock"

push_instance               "spi_commands:spi_commands_master_statctl_fpga"

set_instvalue               sclk [list $pc_spi_port $pc_spi_clock]

copy_instvalues             { "clk,clk" }

source spi_commands.sdc

pop_instance
