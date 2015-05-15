#   Clock information passed through this entity.

# set spicmd_inst             [get_instance]

# regsub -all {[A-Za-z0-9_]+:} $spicmd_inst "" spicmd_inst_name


#   Process SDC file for SPI abstract.  Push the new instance onto the
#   instances stack beforehand and remove it afterwards.

push_instance               "spi_abstract:spi_slave"

copy_instvalues             { "clk,clk" "sclk,sclk" }

source spi_abstract.sdc

pop_instance
