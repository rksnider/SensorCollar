----------------------------------------------------------------------------
--
--! @file       AudioRecordingCollarCPLD_TopLevel.vhd
--! @brief      Mapping from CPLD pin names to Power Controller signals.
--! @details    Map CPLD pins to Power Controller Signals.
--! @author     Emery Newlon
--! @date       September 2015
--! @copyright  Copyright (C) 2015 Ross K. Snider and Emery L. Newlon
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

entity AudioRecordingCollarCPLD_TopLevel is

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

    PC_STATUS_CHANGED               : out   std_logic ;
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

    MAIN_ON                     : out   std_logic ;
    RECHARGE_EN                 : out   std_logic ;
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

  end entity AudioRecordingCollarCPLD_TopLevel ;

architecture structural of AudioRecordingCollarCPLD_TopLevel is

  component PowerController is

    Generic (
      master_clk_freq_g     : natural   := 10e6
    ) ;
    Port (
      master_clk            : in    std_logic ;
      master_clk_out        : out   std_logic ;

      pfl_flash_clk_io      : inout std_logic ;
      pfl_flash_cs_io       : inout std_logic ;
      pfl_flash_data_io     : inout std_logic_vector (3 downto 0) ;
      ext_flash_clk_io      : inout std_logic ;
      ext_flash_cs_io       : inout std_logic ;
      ext_flash_data_io     : inout std_logic_vector (3 downto 0) ;

      fpga_cnf_dclk_out     : out   std_logic ;
      fpga_cnf_data_out     : out   std_logic ;
      fpga_cnf_nstatus_in   : in    std_logic ;
      fpga_cnf_conf_done_in : in    std_logic ;
      fpga_cnf_init_done_in : in    std_logic ;
      fpga_cnf_nconfig_out  : out   std_logic ;

      statchg_out           : out   std_logic ;
      spi_clk_in            : inout std_logic ;
      spi_cs_in             : inout std_logic ;
      spi_mosi_in           : inout std_logic ;
      spi_miso_out          : out   std_logic ;

      i2c_clk_io            : inout std_logic ;
      i2c_data_io           : inout std_logic ;

      bat_power_out         : out   std_logic ;
      bat_recharge_out      : out   std_logic ;
      bat_int_in            : in    std_logic ;
      bat_int_fpga_out      : inout std_logic ;
      bat_low_in            : in    std_logic ;
      bat_good_in           : in    std_logic ;

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
      pwr_ls_3p3_out        : out   std_logic ;

      solar_max_in          : in    std_logic ;
      solar_on_in           : in    std_logic ;
      solar_run_out         : out   std_logic ;

      gpio_1                : out   std_logic ;
      gpio_2                : out   std_logic ;
      gpio_3                : out   std_logic ;
      gpio_4                : out   std_logic ;
      gpio_5                : out    std_logic ;
      gpio_6                : out   std_logic ;
      gpio_7                : out   std_logic ;
      gpio_8                : out   std_logic ;

      forced_start_in       : in    std_logic ;
      fpga_fs_out           : inout std_logic ;
      rtc_alarm_in          : in    std_logic

    ) ;

  end component PowerController ;

  --  Signals required for connecting I/O lines.

  signal pwr_drive_not    : std_logic ;
  signal solar_run_not    : std_logic ;

  signal imu_power        : std_logic;

begin





  --  Invert output signals between the power controller and the outside
  --  world.

  OBUFFER_ENABLE_OUT_TO_CPLD  <= not pwr_drive_not ;
  SOLAR_CTRL_SHDN_N_TO_CPLD   <= not solar_run_not ;

  --  Mapping between pins and power controller port signals.
  
  IM_2P5V_TO_CPLD <= imu_power;
  IM_1P8V_TO_CPLD <= imu_power;
  

  PC : PowerController

    Generic Map (
      master_clk_freq_g     => 50e6
    )
    Port Map (
      master_clk            => CLK_50MHZ,
      master_clk_out        => CLK_50MHZ_TO_FPGA,

      pfl_flash_clk_io      => FLASH_C,
      pfl_flash_cs_io       => FLASH_S_N,
      pfl_flash_data_io     => FLASH_PFL,
      ext_flash_data_io     => FLASH_FPGA,
      ext_flash_clk_io      => PC_FLASH_CLK,
      ext_flash_cs_io       => PC_FLASH_CS_N,
--      fpga_toflash_data_io  => PC_FLASH_DATA,
--      fpga_toflash_dir_in   => PC_FLASH_DIR,

      fpga_cnf_dclk_out     => FPGA_DCLK,
      fpga_cnf_data_out     => FPGA_DATA0,
      fpga_cnf_nstatus_in   => FPGA_NSTATUS,
      fpga_cnf_conf_done_in => FPGA_CONF_DONE,
      fpga_cnf_init_done_in => FPGA_INIT_DONE,
      fpga_cnf_nconfig_out  => FPGA_NCONFIG,

      statchg_out           => PC_STATUS_CHANGED,
      spi_clk_in            => PC_SPI_CLK,
      spi_cs_in             => PC_SPI_NCS,
      spi_mosi_in           => PC_SPI_DIN,
      spi_miso_out          => PC_SPI_DOUT,

      i2c_clk_io            => I2C_SCL,
      i2c_data_io           => I2C_SDA,

      bat_power_out         => MAIN_ON,
      bat_recharge_out      => RECHARGE_EN,
      bat_int_in            => BAT_HIGH_TO_CPLD,
      bat_int_fpga_out      => BAT_HIGH_TO_FPGA,
      bat_low_in            => BAT_LOW_TO_CPLD,
      bat_good_in           => not BATT_GD_N_TO_CPLD,

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
      pwr_im_out            => imu_power,
      pwr_gps_out           => GPS_CNTRL_TO_CPLD,
      pwr_datatx_out        => DATA_TX_CNTRL_TO_CPLD,
      pwr_micR_out          => MIC_B_CNTRL,
      pwr_micL_out          => MIC_A_CTRL,
      pwr_sdcard_out        => SDCARD_CNTRL_TO_CPLD,
      --pwr_ls_1p8_out        => ls_1p8v_cntrl_to_cpld_not,
      --pwr_ls_3p3_out        => LS_3P3V_CNTRL_TO_CPLD,

      solar_max_in          => SOLAR_PGOOD_TO_CPLD,
      solar_on_in           => SOLAR_CTRL_ON_TO_CPLD,
      solar_run_out         => solar_run_not,


      --gpio_5                => '0',


      forced_start_in       => ESH_FORCE_STARTUP,
      fpga_fs_out           => ESH_FORCE_STARTUP_TO_FPGA,
      rtc_alarm_in          => not RTC_ALARM_TO_CPLD

    ) ;


end architecture structural ;
