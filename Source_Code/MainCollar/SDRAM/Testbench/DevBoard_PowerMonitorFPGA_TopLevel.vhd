----------------------------------------------------------------------------
--
--! @file       DevBoard_FPGA_TopLevel.vhd
--! @brief      Mapping from FPGA pin names to Collar signals.
--! @details    Map FPGA pins to Collar Signals.
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


----------------------------------------------------------------------------
--
--! @brief     PowerMonitorFPGA_TopLevel.
--! @details    Maps top level FPGA pins into Collar.vhd
--!
--!
--! @param      CLK_50MHZ_TO_FPGA
--!
--! @param      BAT_HIGH_TO_FPGA
--!
--! @param      FORCED_START_N_TO_FPGA
--!
--! @param      PC_STATUS_CHG
--! @param      PC_SPI_NCS
--! @param      PC_SPI_CLK
--! @param      PC_SPI_DIN
--! @param      PC_SPI_DOUT
--! @param      PC_FLASH_CLK
--! @param      PC_FLASH_CS_N
--! @param      PC_FLASH_DATA
--!
--! @param      PC_FLASH_DIR
--! @param      SDA_TO_FPGA_CPLD
--!
--!
--! @param      SCL_TO_FPGA_CPLD
--!
--! @param      DATA_TX_DAT_TO_FPGA
--!                                  .
--! @param      SDCARD_DI_CLK_TO_FPGA
--! @param      SDCARD_DI_CMD_TO_FPGA
--! @param      SDCARD_DI_DAT_TO_FPGA
--!
--! @param      SDCARD_CLK_TO_FPGA
--! @param      SDCARD_CMD_TO_FPGA
--! @param      SDCARD_DAT_TO_FPGA
--!
--!
--! @param      MRAM_SCLK_TO_FPGA
--! @param      MRAM_SI_TO_FPGA
--! @param      MRAM_SO_TO_FPGA
--! @param      MRAM_CS_N_TO_FPGA
--! @param      MRAM_WP_N_TO_FPGA
--!
--!
--!
--! @param      SDRAM_CLK
--! @param      SDRAM_CKE
--! @param      SDRAM_command
--! @param      SDRAM_address
--! @param      SDRAM_bank
--! @param      SDRAM_data
--! @param      SDRAM_mask
--!
--!
--! @param      MIC_CLK
--! @param      MIC_DATA_R
--! @param      MIC_DATA_L
--!
--!
--! @param      IM2_INT_M
--! @param      IM2_CS_AG
--! @param      IM2_INT1_AG
--! @param      IM2_SDO_M
--! @param      IM2_CS_M
--! @param      IM2_SPI_SDI
--! @param      IM2_DRDY_M
--! @param      IM2_SDO_AG
--! @param      IM2_INT2_AG
--! @param      IM2_SPI_SCLK
--!
--!
--! @param      RXD_GPS_TO_FPGA
--! @param      TXD_GPS_TO_FPGA
--! @param      TIMEPULSE_GPS_TO_FPGA
--! @param      EXTINT_GPS_TO_FPGA
--!
--! @param      GPIOSEL_0     Bank Voltage Selectable GPIO
--! @param      GPIOSEL_1     Bank Voltage Selectable GPIO
--! @param      GPIOSEL_2     Bank Voltage Selectable GPIO
--! @param      GPIOSEL_3     Bank Voltage Selectable GPIO
--!
--!
--
----------------------------------------------------------------------------

entity DevBoard_PowerMonitorFPGA_TopLevel is

  Port (

    --   Clocks

    CLK_50MHZ_TO_FPGA    : in   std_logic ;

    --  SDRAM Connections

    SDRAM_CLK           : out   std_logic ;
    SDRAM_CKE           : out   std_logic ;

    SDRAM_command       : out   std_logic_vector (3 downto 0) ;
    SDRAM_address       : out   std_logic_vector (12 downto 0) ;
    SDRAM_bank          : out   std_logic_vector (1 downto 0) ;
    SDRAM_data          : inout std_logic_vector (15 downto 0) ;
    SDRAM_mask          : out   std_logic_vector (1 downto 0) ;

    --  Power Controller/FPGA SPI connection.

    PC_STATUS_CHG       : in    std_logic ;
    PC_SPI_NCS          : out   std_logic ;
    PC_SPI_CLK          : out   std_logic ;
    PC_SPI_DIN          : in    std_logic ;
    PC_SPI_DOUT         : out   std_logic ;

    --  Voltage Selectable, 1.8V, and 3.3V GPIO

    GPIOSEL             : out   std_logic_vector (15 downto 0) ;

    --  1.8V GPIO

    GPIO1P8             : out   std_logic_vector (7 downto 0) ;

    --  3.3V GPIO

    GPIO3P3             : out   std_logic_vector (7 downto 0)

  ) ;

  end entity DevBoard_PowerMonitorFPGA_TopLevel ;

architecture structural of DevBoard_PowerMonitorFPGA_TopLevel is

  component SDRAM_ControllerTest_tb is

    Generic (
      master_clk_freq_g     : natural   := 10e6 ;
      button_cnt_g          : natural   :=  8
    ) ;
    Port (
      master_clk            : in    std_logic ;
      buttons_in            : in    std_logic_vector (button_cnt_g-1
                                                      downto 0) ;

      sdram_clk             : out   std_logic ;
      sdram_clk_en_out      : out   std_logic ;
      sdram_command_out     : out   std_logic_vector (3 downto 0) ;
      sdram_mask_out        : out   std_logic_vector (1 downto 0) ;
      sdram_bank_out        : out   std_logic_vector (1 downto 0) ;

      sdram_addr_out        : out   std_logic_vector (12 downto 0) ;
      sdram_data_io         : inout std_logic_vector (15 downto 0) ;

      PC_StatusChg_in       : in    std_logic ;
      PC_SPI_clk_out        : out   std_logic ;
      PC_SPI_mosi_out       : out   std_logic ;
      PC_SPI_miso_in        : in    std_logic ;
      PC_SPI_cs_n_out       : out   std_logic ;

      log_clk_out           : out   std_logic ;
      log_clk_en_out        : out   std_logic ;
      log_command_out       : out   std_logic_vector (3 downto 0) ;
      log_mask_out          : out   std_logic_vector (1 downto 0) ;
      log_bank_out          : out   std_logic_vector (1 downto 0) ;
      log_addr_out          : out   std_logic_vector (12 downto 0) ;
      log_data_out          : out   std_logic_vector (15 downto 0) ;
      log_empty_out         : out   std_logic ;
      log_forceout_out      : out   std_logic ;
      log_fail_out          : out   std_logic

    ) ;

  end component SDRAM_ControllerTest_tb ;

  signal clock_out          : std_logic ;
  signal data_out           : std_logic_vector (15 downto 0) ;

begin

  GPIO1P8 (0)               <= clock_out ;
  GPIOSEL (15)              <= clock_out ;

  GPIO3P3 (2 downto 0)      <= data_out (2 downto 0) ;
  GPIO3P3 (4 downto 3)      <= data_out (9 downto 8) ;


  sdram_tb : SDRAM_ControllerTest_tb

    Generic Map (
      master_clk_freq_g     => 50e6,
      button_cnt_g          => 1
    )
    Port Map (
      master_clk            => CLK_50MHZ_TO_FPGA,
      buttons_in            => "0",

      sdram_clk             => SDRAM_CLK,
      sdram_clk_en_out      => SDRAM_CKE,
      sdram_command_out     => SDRAM_command,
      sdram_mask_out        => SDRAM_mask,
      sdram_bank_out        => SDRAM_bank,

      sdram_addr_out        => SDRAM_address,
      sdram_data_io         => SDRAM_data,

      PC_StatusChg_in       => PC_STATUS_CHG,
      PC_SPI_clk_out        => PC_SPI_CLK,
      PC_SPI_mosi_out       => PC_SPI_DOUT,
      PC_SPI_miso_in        => PC_SPI_DIN,
      PC_SPI_cs_n_out       => PC_SPI_NCS,

      log_clk_out           => clock_out,
      log_clk_en_out        => GPIO1P8 (1),
      log_command_out       => GPIO1P8 (5 downto 2),
      log_mask_out          => GPIO1P8 (7 downto 6),
      log_bank_out          => GPIOSEL (14 downto 13),
      log_addr_out          => GPIOSEL (12 downto 0),
      log_data_out          => data_out,
      log_empty_out         => GPIO3P3 (5),
      log_forceout_out      => GPIO3P3 (6),
      log_fail_out          => GPIO3P3 (7)

    ) ;


end architecture structural ;
