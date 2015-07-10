#   Power Controller SPI Timing information.
#   Perform SPI data constraining at the pins.

set clock_name                [get_keyvalue "PC_SPI_CLK"]

set clock_data                [get_clocks $clock_name]
set clock_period              [get_clock_info -period $clock_data]

derive_clock_uncertainty

#   Max V 5M570Z 1.8V CPLD timing delays in nanoseconds from "Timing Model
#   and Specifications" of the "MAX V Device Handbook".

set t_LE_LUT_max              2.247     ;#  LE Timing
set t_LE_COMB_max             0.309
set t_LE_CLR_min              0.545
set t_LE_PRE_min              0.545
set t_LE_SU_min               0.321
set t_LE_H_min                0.000
set t_LE_CO_max               0.494
set t_LE_CLKHL_min            0.339
set t_LE_C_max                1.741

set t_IOE_FASTIO_max          0.428     ;#  IOE Timing
set t_IOE_IN_max              0.986
set t_IOE_GLOB_max            3.322
set t_IOE_IOE_max             1.410
set t_IOE_DL_max              0.509
set t_IOE_OD_max              1.543
set t_IOE_XZ_max              [expr 1.276 + 0.685]
set t_IOE_ZX_max              [expr 1.353 + 0.025]

set t_RD_C4_max               1.973     ;#  Internal Routing Timing
set t_RD_R4_max               1.479
set t_RD_LOCAL_max            2.947

#                                           Global Clock External Timing
set t_P2P_PD1_max             [expr 17.700 + 0.368]
set t_P2P_PD2_max             [expr  8.500 + 0.368]
set t_P2P_SU_min              [expr  4.400 + 0.368]
set t_P2P_H_min               0.000
set t_P2P_CO_min              [expr  2.000 + 0.694]
set t_P2P_CO_max              [expr  8.700 + 0.694]
set t_P2P_CH_min              0.399
set t_P2P_CL_min              0.399

#   Set the timings for the pins accessed via the clock.
#     Set Quartus II TimeQuest Timing Analyzer Cookbook - I/O Constraints
#
#     The clock originates in the FPGA but this is not important from
#     the timing prospective.  An inverse clock is used to talk to the
#     PC SPI.  From the FPGA prospective this means the clock takes half a
#     clock cycle to reach the device and a full clock cycle to reach the
#     FPGA for input.  For the output the clock is received by the FPGA
#     with no delay and by the device with half a clock cycle delay.

set CLKin_src_PhaseDelay        [expr $clock_period * 180.0 / 360.0]

set CLKin_src_max               0.180         ;#  CLKAs in example
set CLKin_src_min               0.120

set CLKin_dst_max               0.000         ;#  CLKAd
set CLKin_dst_min               0.000

set CLKin_dev_max               $t_P2P_CO_max ;#  tCOa
set CLKin_dev_min               $t_P2P_CO_min
set CLKin_brd_max               0.180         ;#  BDa
set CLKin_brd_min               0.120


set CLKout_src_PhaseDelay       [expr $clock_period * 180.0 / 360.0]

set CLKout_src_max              0.000           ;#  CLKBs
set CLKout_src_min              0.000

set CLKout_dst_max              0.100           ;#  CLKBd
set CLKout_dst_min              0.080

set CLKout_dev_max              $t_P2P_SU_min   ;#  tSUb
set CLKout_dev_hld              $t_P2P_H_min    ;#  tHb
set CLKout_brd_max              0.100           ;#  BDb
set CLKout_brd_min              0.080

#   Set the delays for the I/O ports.

set_false_path -to    [get_ports PC_SPI_CLK]
set_false_path -from  [get_ports PC_STATUS_CHG]

set output_port_list          {PC_SPI_NCS PC_SPI_DIN}

set input_port_list           {PC_SPI_DOUT}

set in_min_delay              [expr $CLKin_src_min + $CLKin_dev_min + \
                                    $CLKin_brd_min - $CLKin_dst_max]

set in_max_delay              [expr $CLKin_src_max + $CLKin_dev_max + \
                                    $CLKin_brd_max - $CLKin_dst_min]

set_input_delay -clock $clock_name -min $in_min_delay \
                [get_ports $input_port_list]

set_input_delay -clock $clock_name -max $in_max_delay \
                [get_ports $input_port_list]


set out_min_delay             [expr $CLKout_brd_min + $CLKout_dev_hld + \
                                    $CLKout_dst_min - $CLKout_src_max]

set out_max_delay             [expr $CLKout_brd_max + $CLKout_dev_max + \
                                    $CLKout_dst_max - $CLKout_src_min]

set_output_delay -clock $clock_name -min $out_min_delay \
                 -add_delay [get_ports $output_port_list]

set_output_delay -clock $clock_name -max $out_max_delay \
                 -add_delay [get_ports $output_port_list]

#   The reset port can interact badly with SPI lines.

set reset_line                  {*|power_up}

set_false_path -from [get_registers "$reset_line"] \
               -to   [get_ports $output_port_list]
