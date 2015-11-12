#   Clocks and timings used by SD Loader
#

set sd_loader_inst            [get_instance]

set clk_name                  [get_instvalue clk]
set clk_data                  [get_clocks "$clk_name"]
set clk_target                [get_clock_info -targets $clk_data]

#   Define buffer ready as a clock.

set sdram_buff_ready          "sd_outmem_buffready_out"
set sdram_buff_ready_target   "$sd_loader_inst|$sdram_buff_ready"

regsub -all "@" "$sdram_buff_ready_target" "\\" buffready_target

set buff_ready_clk            [get_instvalue $sdram_buff_ready]

if {[get_collection_size [get_nodes -nowarn "$buffready_target"]] > 0} {
  create_generated_clock -source "$clk_target" \
                         -name "$buff_ready_clk" "$buffready_target"
}
