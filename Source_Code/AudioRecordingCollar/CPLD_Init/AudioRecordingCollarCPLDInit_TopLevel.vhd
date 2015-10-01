----------------------------------------------------------------------------
--
--! @file       AudioRecordingCollarCPLDInit_TopLevel.vhd
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

entity AudioRecordingCollarCPLDInit_TopLevel is

    Port (

    --  Flash Connections

    FLASH_C                     : inout std_logic ;
    FLASH_PFL                   : inout std_logic_vector (3 downto 0) ;
    FLASH_FPGA                  : inout std_logic_vector (3 downto 0) ;
    FLASH_S_N                   : inout std_logic ;

    --  Clocks

    CLK_50MHZ                   : in    std_logic ;
    CLK_50MHZ_TO_FPGA           : out   std_logic ;

    --  FPGA Configuration Connections

    FPGA_DCLK                   : out   std_logic ;
    FPGA_NSTATUS                : in    std_logic ;
    FPGA_CONF_DONE              : in    std_logic ;
    FPGA_INIT_DONE              : in    std_logic ;
    FPGA_NCONFIG                : out   std_logic ;
    FPGA_DATA0                  : out   std_logic ;

    --  FPGA Flash Connections

    PC_FLASH_CLK                : inout std_logic ;
    PC_FLASH_CS_N               : inout std_logic ;
--    PC_FLASH_DATA               : inout std_logic_vector (3 downto 0) ;
--    PC_FLASH_DIR                : inout std_logic ;

    --  FPGA Status and SPI Connections

    PC_STATUS_CHANGED           : out   std_logic ;
    PC_SPI_CLK                  : inout std_logic ;
    PC_SPI_DIN                  : inout std_logic ;
    PC_SPI_DOUT                 : out   std_logic ;
    PC_SPI_NCS                  : inout std_logic ;

    --  I2C Bus Connections

    I2C_SDA            : inout std_logic ;
    I2C_SCL            : inout std_logic ;

    --  Device Power Control Connections

    GPS_CNTRL_TO_CPLD           : out   std_logic ;
    SDRAM_CNTRL_TO_CPLD         : out   std_logic ;
    MRAM_CNTRL_TO_CPLD          : out   std_logic ;
    MIC_B_CNTRL                 : out   std_logic ;
    MIC_A_CTRL                  : out   std_logic ;
    CLOCK_CNTRL_TO_CPLD         : out   std_logic ;
    DATA_TX_CNTRL_TO_CPLD       : out   std_logic ;
    SDCARD_CNTRL_TO_CPLD        : out   std_logic ;
    FPGA_ON_TO_CPLD             : out   std_logic ;
    IM_2P5V_TO_CPLD             : out   std_logic ;
    IM_1P8V_TO_CPLD             : out   std_logic ;

    OBUFFER_ENABLE_OUT_TO_CPLD  : out   std_logic ;

    --  Battery Control Connections

    MAIN_ON_TO_CPLD             : out   std_logic ;
    RECHARGE_EN_TO_CPLD         : out   std_logic ;
    BAT_HIGH_TO_CPLD            : in    std_logic ;
    BAT_HIGH_TO_FPGA            : inout std_logic ;
    BAT_LOW_TO_CPLD             : in    std_logic ;
    BATT_GD_N_TO_CPLD           : in    std_logic ;

    --  Power Supply Control Connections

    VCC1P1_RUN_TO_CPLD          : out   std_logic ;
    VCC2P5_RUN_TO_CPLD          : out   std_logic ;
    VCC3P3_RUN_TO_CPLD          : out   std_logic ;
    PWR_GOOD_1P1_TO_CPLD        : in    std_logic ;
    PWR_GOOD_2P5_TO_CPLD        : in    std_logic ;
    PWR_GOOD_3P3_TO_CPLD        : in    std_logic ;
    BUCK_PWM_TO_CPLD            : out   std_logic ;

    --  Solar Controller Connections

    SOLAR_PGOOD_TO_CPLD         : in    std_logic ;
    SOLAR_CTRL_ON_TO_CPLD       : in    std_logic ;
    SOLAR_CTRL_SHDN_N_TO_CPLD   : out   std_logic ;

    --  Real Time Clock Connections

    RTC_ALARM_TO_CPLD           : in    std_logic ;

    --  Off Board Connections

    ESH_FORCE_STARTUP      : in    std_logic ;
    ESH_FORCE_STARTUP_TO_FPGA      : inout std_logic 

  ) ;

  end entity AudioRecordingCollarCPLDInit_TopLevel ;

architecture structural of AudioRecordingCollarCPLDInit_TopLevel is

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

      fpga_cnf_dclk_out     => FPGA_DCLK,
      fpga_cnf_data_out     => FPGA_DATA0,
      fpga_cnf_nstatus_in   => FPGA_NSTATUS,
      fpga_cnf_conf_done_in => FPGA_CONF_DONE,
      fpga_cnf_init_done_in => FPGA_INIT_DONE,
      fpga_cnf_nconfig_out  => FPGA_NCONFIG,

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
      pwr_im_out            => IM_2P5V_TO_CPLD,
      pwr_gps_out           => GPS_CNTRL_TO_CPLD,
      pwr_datatx_out        => DATA_TX_CNTRL_TO_CPLD,
      pwr_micR_out          => MIC_B_CNTRL,
      pwr_micL_out          => MIC_A_CTRL,
      pwr_sdcard_out        => SDCARD_CNTRL_TO_CPLD
      --pwr_ls_1p8_out        => LS_1P8V_CNTRL_TO_CPLD,
      --pwr_ls_3p3_out        => LS_3P3V_CNTRL_TO_CPLD

    ) ;


end architecture structural ;
