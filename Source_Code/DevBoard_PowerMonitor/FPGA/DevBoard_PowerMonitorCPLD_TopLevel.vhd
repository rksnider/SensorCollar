----------------------------------------------------------------------------
--
--! @file       DevBoard_PowerMonitorCPLD_TopLevel.vhd
--! @brief      Mapping from CPLD pin names to Power Controller signals.
--! @details    Map CPLD pins to Power Controller SIgnals.
--! @author     Emery Newlon
--! @date       October 2014
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

entity DevBoard_PowerMonitorCPLD_TopLevel is

  Port (

    --  Flash Connections

    FLASH_C                     : out   std_logic ;
    FLASH_PFL                   : inout std_logic_vector (3 downto 0) ;
    FLASH_FPGA                  : inout std_logic_vector (3 downto 0) ;
    FLASH_S_N                   : out   std_logic ;

    --  Clocks

    CLK_50MHZ                   : in    std_logic ;
    CLK_50MHZ_TO_FPGA           : out   std_logic ;

    --  FPGA Configuration Connections

    DCLK_FPGA                   : out   std_logic ;
    NSTATUS_FPGA                : in    std_logic ;
    CONF_DONE_FPGA              : in    std_logic ;
    INIT_DONE_FPGA              : in    std_logic ;
    NCONFIG_FPGA                : out   std_logic ;
    DATA0_FPGA                  : out   std_logic ;

    --  FPGA Flash Connections

    PC_FLASH_CLK                : inout std_logic ;
    PC_FLASH_CS_N               : inout std_logic ;
    PC_FLASH_DATA               : inout std_logic_vector (3 downto 0) ;
    PC_FLASH_DIR                : inout std_logic ;

    --  FPGA Status and SPI Connections

    PC_STATUS_CHG               : out   std_logic ;
    PC_SPI_CLK                  : inout std_logic ;
    PC_SPI_DIN                  : inout std_logic ;
    PC_SPI_DOUT                 : out   std_logic ;
    PC_SPI_NCS                  : inout std_logic ;

    --  I2C Bus Connections

    SDA_TO_FPGA_CPLD            : inout std_logic ;
    SCL_TO_FPGA_CPLD            : inout std_logic ;

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

    FORCED_START_N_TO_CPLD      : in    std_logic ;
    FORCED_START_N_TO_FPGA      : inout std_logic ;

    --  General Purpose I/O Connections

    CPLD_GPIO1                  : out    std_logic ;
    CPLD_GPIO2                  : out    std_logic ;
    CPLD_GPIO3                  : out    std_logic ;
    CPLD_GPIO4                  : out    std_logic ;
    CPLD_GPIO5                  : out    std_logic ;
    CPLD_GPIO6                  : out    std_logic ;
    CPLD_GPIO7                  : out    std_logic ;
    CPLD_GPIO8                  : out    std_logic
  ) ;

  end entity DevBoard_PowerMonitorCPLD_TopLevel ;

architecture structural of DevBoard_PowerMonitorCPLD_TopLevel is

  component PowerController is

    Generic (
      master_clk_freq_g     : natural   := 10e6
    ) ;
    Port (
      master_clk            : in    std_logic ;
      master_clk_out        : out   std_logic ;

      flash_clk_out         : out   std_logic ;
      flash_cs_out          : out   std_logic ;
      pfl_flash_data_io     : inout std_logic_vector (3 downto 0) ;
      fpga_flash_data_io    : inout std_logic_vector (3 downto 0) ;
      fpga_toflash_clk_in   : inout std_logic ;
      fpga_toflash_cs_in    : inout std_logic ;
      fpga_toflash_data_io  : inout std_logic_vector (3 downto 0) ;
      fpga_toflash_dir_in   : inout std_logic ;

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
		
		gpio_1				    : out   std_logic ;
		gpio_2				    : out   std_logic ;
		gpio_3				    : out   std_logic ;
		gpio_4				    : out   std_logic ;
		gpio_5				    : out   std_logic ;
		gpio_6				    : out   std_logic ;
		gpio_7				    : out   std_logic ;
		gpio_8				    : out   std_logic ;

      forced_start_in       : in    std_logic ;
      fpga_fs_out           : inout std_logic ;
      rtc_alarm_in          : in    std_logic

    ) ;

  end component PowerController ;

  --  Signals required for connecting I/O lines.

  signal pwr_drive_not    : std_logic ;
  signal solar_run_not    : std_logic ;

begin

  --  Invert output signals between the power controller and the outside
  --  world.

  OBUFFER_ENABLE_OUT_TO_CPLD  <= not pwr_drive_not ;
  SOLAR_CTRL_SHDN_N_TO_CPLD   <= not solar_run_not ;

  --  Mapping between pins and power controller port signals.

  PC : PowerController

    Generic Map (
      master_clk_freq_g     => 50e6
    )
    Port Map (
      master_clk            => CLK_50MHZ,
      master_clk_out        => CLK_50MHZ_TO_FPGA,

      flash_clk_out         => FLASH_C,
      flash_cs_out          => FLASH_S_N,
      pfl_flash_data_io     => FLASH_PFL,
      fpga_flash_data_io    => FLASH_FPGA,
      fpga_toflash_clk_in   => PC_FLASH_CLK,
      fpga_toflash_cs_in    => PC_FLASH_CS_N,
      fpga_toflash_data_io  => PC_FLASH_DATA,
      fpga_toflash_dir_in   => PC_FLASH_DIR,

      fpga_cnf_dclk_out     => DCLK_FPGA,
      fpga_cnf_data_out     => DATA0_FPGA,
      fpga_cnf_nstatus_in   => NSTATUS_FPGA,
      fpga_cnf_conf_done_in => CONF_DONE_FPGA,
      fpga_cnf_init_done_in => INIT_DONE_FPGA,
      fpga_cnf_nconfig_out  => NCONFIG_FPGA,

      statchg_out           => PC_STATUS_CHG,
      spi_clk_in            => PC_SPI_CLK,
      spi_cs_in             => PC_SPI_NCS,
      spi_mosi_in           => PC_SPI_DIN,
      spi_miso_out          => PC_SPI_DOUT,

      i2c_clk_io            => SCL_TO_FPGA_CPLD,
      i2c_data_io           => SDA_TO_FPGA_CPLD,

      bat_power_out         => MAIN_ON_TO_CPLD,
      bat_recharge_out      => RECHARGE_EN_TO_CPLD,
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
      pwr_im_out            => IM_ON_TO_CPLD,
      pwr_gps_out           => GPS_CNTRL_TO_CPLD,
      pwr_datatx_out        => DATA_TX_CNTRL_TO_CPLD,
      pwr_micR_out          => MIC_R_CNTRL_TO_CPLD,
      pwr_micL_out          => MIC_L_CNTRL_TO_CPLD,
      pwr_sdcard_out        => SDCARD_CNTRL_TO_CPLD,
      pwr_ls_1p8_out        => LS_1P8V_CNTRL_TO_CPLD,
      pwr_ls_3p3_out        => LS_3P3V_CNTRL_TO_CPLD,

      solar_max_in          => SOLAR_PGOOD_TO_CPLD,
      solar_on_in           => SOLAR_CTRL_ON_TO_CPLD,
      solar_run_out         => solar_run_not,
		gpio_1				    => CPLD_GPIO1,
		gpio_2				    => CPLD_GPIO2,
		gpio_3				    => CPLD_GPIO3,
		gpio_4				    => CPLD_GPIO4,
		gpio_5				    => CPLD_GPIO5,
		gpio_6				    => CPLD_GPIO6,
		gpio_7				    => CPLD_GPIO7,
		gpio_8				    => CPLD_GPIO8,

      forced_start_in       => not FORCED_START_N_TO_CPLD,
      fpga_fs_out           => FORCED_START_N_TO_FPGA,
      rtc_alarm_in          => not RTC_ALARM_TO_CPLD

    ) ;


end architecture structural ;
