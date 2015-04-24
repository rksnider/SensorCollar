# Create design library
vmap altera_mf ./vsim/vhdl_libs/altera_mf
vlib work

vcom -work ./general ./general/GPS_Clock_pkg.vhd
# Create and open project
project new . compile_project
project open compile_project
# Add source files to project
project addfile ./LSM9DS1_top.vhd
project addfile ./spi_abstract.vhd
project addfile ./spi_commands.vhd
# Calculate compilation order
project calculateorder
set compcmd [project compileall -n]
# Close project
project close
# Compile all files and report error
if [catch {eval $compcmd}] {
    exit -code 1
}
