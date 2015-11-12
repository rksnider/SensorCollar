#   Clocks and timings used by FlashBlock
#

set flashblock_inst           [get_instance]

set clk_name                  [get_instvalue clock_sys]
set clk_data                  [get_clocks "$clk_name"]
set clk_target                [get_clock_info -targets $clk_data]

#   Define buffer ready as a clock.

set sdram_buff_ready          "flashblock_sdram_2k_accumulated"
set sdram_buff_ready_target   "$flashblock_inst|$sdram_buff_ready"

regsub -all "@" "$sdram_buff_ready_target" "\\" buffready_target

create_generated_clock -source $clk_target \
                       -name flashblock_buff_ready $buffready_target
