----------------------------------------------------------------------------
--
--! @file       DevBoard_PowerMonitorCPLDInit_TopLevel.vhd
--! @brief      Mapping from CPLD pin names to Flash Init signals.
--! @details    Map CPLD pins to Flash Init Signals.
--! @author     Emery Newlon
--! @date       December 2014
--! @copyright  Copyright (C) 2014 Ross K. Snider and Emery L. Newlon
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--  Emery Newlon
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  emery.newlon@msu.montana.edu
--
----------------------------------------------------------------------------

library IEEE ;                      --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;       --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;          --! Use numeric standard.

entity DevBoard_PowerMonitorCPLDInit_TopLevel is

  Port (

    --  Flash Connections

    FLASH_C                     : out   std_logic ;
    FLASH_PFL                   : inout std_logic_vector (3 downto 0) ;
    FLASH_S_N                   : out   std_logic ;

    --  Clocks

    CLK_50MHZ                   : in    std_logic ;
    --  FPGA Configuration Connections

    DCLK_FPGA                   : out   std_logic ;
    NSTATUS_FPGA                : in    std_logic ;
    CONF_DONE_FPGA              : in    std_logic ;
    INIT_DONE_FPGA              : in    std_logic ;
    NCONFIG_FPGA                : out   std_logic ;
    DATA0_FPGA                  : out   std_logic ;

    --  Device Power Control Connections

    GPS_CNTRL_TO_CPLD           : out   std_logic ;
    SDRAM_CNTRL_TO_CPLD         : out   std_logic ;
    MRAM_CNTRL_TO_CPLD          : out   std_logic ;
    MIC_R_CNTRL_TO_CPLD         : out   std_logic ;
    MIC_L_CNTRL_TO_CPLD         : out   std_logic ;
    CLOCK_CNTRL_TO_CPLD         : out   std_logic ;
    DATA_TX_CNTRL_TO_CPLD       : out   std_logic ;
    SDCARD_CNTRL_TO_CPLD        : out   std_logic ;
    LS_1P8V_CNTRL_TO_CPLD       : out   std_logic ;
    LS_3P3V_CNTRL_TO_CPLD       : out   std_logic ;
    FPGA_ON_TO_CPLD             : out   std_logic ;
    IM_ON_TO_CPLD               : out   std_logic ;

    OBUFFER_ENABLE_OUT_TO_CPLD  : out   std_logic ;

    --  Battery Control Connections

    MAIN_ON_TO_CPLD             : out   std_logic ;
    RECHARGE_EN_TO_CPLD         : out   std_logic ;

    --  Power Supply Control Connections

    VCC1P1_RUN_TO_CPLD          : out   std_logic ;
    VCC2P5_RUN_TO_CPLD          : out   std_logic ;
    VCC3P3_RUN_TO_CPLD          : out   std_logic ;
    PWR_GOOD_1P1_TO_CPLD        : in    std_logic ;
    PWR_GOOD_2P5_TO_CPLD        : in    std_logic ;
    PWR_GOOD_3P3_TO_CPLD        : in    std_logic ;
    BUCK_PWM_TO_CPLD            : out   std_logic

  ) ;

  end entity DevBoard_PowerMonitorCPLDInit_TopLevel ;

architecture structural of DevBoard_PowerMonitorCPLDInit_TopLevel is

  component FlashInit is

    Generic (
      master_clk_freq_g     : natural   := 10e6
    ) ;
    Port (
      master_clk            : in    std_logic ;                   
      flash_clk_out         : out   std_logic ;
      flash_cs_out          : out   std_logic ;
      pfl_flash_data_io     : inout std_logic_vector (3 downto 0) ;

      fpga_cnf_dclk_out     : out   std_logic ;
      fpga_cnf_data_out     : out   std_logic ;
      fpga_cnf_nstatus_in   : in    std_logic ;
      fpga_cnf_conf_done_in : in    std_logic ;
      fpga_cnf_init_done_in : in    std_logic ;
      fpga_cnf_nconfig_out  : out   std_logic ;

      bat_power_out         : out   std_logic ;
      bat_recharge_out      : out   std_logic ;

      pwr_1p1_run_out       : out   std_logic ;
      pwr_1p1_good_in       : in    std_logic ;
      pwr_2p5_run_out       : out   std_logic ;
      pwr_2p5_good_in       : in    std_logic ;
      pwr_3p3_run_out       : out   std_logic ;
      pwr_3p3_good_in       : in    std_logic ;
      pwr_pwm_out           : out   std_logic ;

      pwr_drive_out         : out   std_logic ;
      pwr_clock_out         : out   std_logic ;
      pwr_fpga_out          : out   std_logic ;
      pwr_sdram_out         : out   std_logic ;
      pwr_mram_out          : out   std_logic ;
      pwr_im_out            : out   std_logic ;
      pwr_gps_out           : out   std_logic ;
      pwr_datatx_out        : out   std_logic ;
      pwr_micR_out          : out   std_logic ;
      pwr_micL_out          : out   std_logic ;
      pwr_sdcard_out        : out   std_logic ;
      pwr_ls_1p8_out        : out   std_logic ;
      pwr_ls_3p3_out        : out   std_logic

    ) ;

  end component FlashInit ;

  --  Signals required for connecting I/O lines.

  signal pwr_drive_not    : std_logic ;

begin

  --  Invert output signals between the power controller and the outside
  --  world.

  OBUFFER_ENABLE_OUT_TO_CPLD  <= not pwr_drive_not ;

  --  Mapping between pins and power controller port signals.

  PC : FlashInit

    Generic Map (
      master_clk_freq_g     => 50e6
    )
    Port Map (
      master_clk            => CLK_50MHZ,
      flash_clk_out         => FLASH_C,
      flash_cs_out          => FLASH_S_N,
      pfl_flash_data_io     => FLASH_PFL,

      fpga_cnf_dclk_out     => DCLK_FPGA,
      fpga_cnf_data_out     => DATA0_FPGA,
      fpga_cnf_nstatus_in   => NSTATUS_FPGA,
      fpga_cnf_conf_done_in => CONF_DONE_FPGA,
      fpga_cnf_init_done_in => INIT_DONE_FPGA,
      fpga_cnf_nconfig_out  => NCONFIG_FPGA,

      bat_power_out         => MAIN_ON_TO_CPLD,
      bat_recharge_out      => RECHARGE_EN_TO_CPLD,

      pwr_1p1_run_out       => VCC1P1_RUN_TO_CPLD,
      pwr_1p1_good_in       => PWR_GOOD_1P1_TO_CPLD,
      pwr_2p5_run_out       => VCC2P5_RUN_TO_CPLD,
      pwr_2p5_good_in       => PWR_GOOD_2P5_TO_CPLD,
      pwr_3p3_run_out       => VCC3P3_RUN_TO_CPLD,
      pwr_3p3_good_in       => PWR_GOOD_3P3_TO_CPLD,
      pwr_pwm_out           => BUCK_PWM_TO_CPLD,

      pwr_drive_out         => pwr_drive_not,
      pwr_clock_out         => CLOCK_CNTRL_TO_CPLD,
      pwr_fpga_out          => FPGA_ON_TO_CPLD,
      pwr_sdram_out         => SDRAM_CNTRL_TO_CPLD,
      pwr_mram_out          => MRAM_CNTRL_TO_CPLD,
      pwr_im_out            => IM_ON_TO_CPLD,
      pwr_gps_out           => GPS_CNTRL_TO_CPLD,
      pwr_datatx_out        => DATA_TX_CNTRL_TO_CPLD,
      pwr_micR_out          => MIC_R_CNTRL_TO_CPLD,
      pwr_micL_out          => MIC_L_CNTRL_TO_CPLD,
      pwr_sdcard_out        => SDCARD_CNTRL_TO_CPLD,
      pwr_ls_1p8_out        => LS_1P8V_CNTRL_TO_CPLD,
      pwr_ls_3p3_out        => LS_3P3V_CNTRL_TO_CPLD

    ) ;


end architecture structural ;
