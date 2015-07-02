----------------------------------------------------------------------------
--
--! @file       CrossConnectCheck.vhd
--! @brief      Check all Output pins for cross connection.
--! @details    Check all Output and Bidirectional pins for cross
--!             connections.
--! @author     Emery Newlon
--! @date       June 2015
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

library GENERAL ;                   --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      CrossConnectCheck.
--! @details    Check Output and Bidirection pins for cross connections.
--!             The bus hold circuitry is first driven with the same level
--!             for all lines.  Then the lines are put in high-impedence
--!             mode and checked to see if they changed value.  If they
--!             did there is some type of cross connection.
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
--! @param      MRAM_SCLK_TO_FPGA
--! @param      MRAM_SI_TO_FPGA
--! @param      MRAM_SO_TO_FPGA
--! @param      MRAM_CS_N_TO_FPGA
--! @param      MRAM_WP_N_TO_FPGA
--!
--! @param      SDRAM_CLK
--! @param      SDRAM_CKE
--! @param      SDRAM_command
--! @param      SDRAM_address
--! @param      SDRAM_bank
--! @param      SDRAM_data
--! @param      SDRAM_mask
--!
--! @param      MIC_CLK
--! @param      MIC_DATA_R
--! @param      MIC_DATA_L
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
--
----------------------------------------------------------------------------

entity CrossConnectCheck is

  Port (

    --   Clocks

    CLK_50MHZ_TO_FPGA         : in    std_logic;

    --  System Status

    -- BAT_HIGH_TO_FPGA          : in    std_logic;
    -- FORCED_START_N_TO_FPGA    : in    std_logic;

    --Power Controller

    -- PC_STATUS_CHG             : in    std_logic;
    -- PC_SPI_NCS                : out   std_logic;
    -- PC_SPI_CLK                : out   std_logic;
    -- PC_SPI_DIN                : out   std_logic;
    -- PC_SPI_DOUT               : in    std_logic;

    -- PC_FLASH_CLK              : inout std_logic;
    -- PC_FLASH_CS_N             : inout std_logic;
    -- PC_FLASH_DATA             : inout std_logic_vector (3 downto 0);
    -- PC_FLASH_DIR              : inout std_logic;

    --   I2C Bus

    -- SDA_TO_FPGA_CPLD          : inout std_logic;
    -- SCL_TO_FPGA_CPLD          : inout std_logic;

    -- Data Transmitter Connections

    -- DATA_TX_DAT0_TO_FPGA      : inout std_logic;
    -- DATA_TX_DAT1_TO_FPGA      : inout std_logic;
    -- DATA_TX_DAT2_TO_FPGA      : inout std_logic;
    -- DATA_TX_DAT3_TO_FPGA      : inout std_logic;
    -- DATA_TX_DAT4_TO_FPGA      : inout std_logic;
    -- DATA_TX_DAT_TO_FPGA       : inout std_logic_vector (4 downto 0);

    --Direct SDCard Connections

    -- SDCARD_DI_CLK_TO_FPGA     : out   std_logic;
    -- SDCARD_DI_CMD_TO_FPGA     : inout std_logic;
    -- SDCARD_DI_DAT_TO_FPGA     : inout std_logic_vector (3 downto 0);

    --Level Shifted SDCard Connections

    -- SDCARD_CLK_TO_FPGA        : out   std_logic;
    -- SDCARD_CMD_TO_FPGA        : inout std_logic;
    -- SDCARD_DAT_TO_FPGA        : inout std_logic_vector (3 downto 0);

    --  Magnetic RAM Connections

    -- MRAM_SCLK_TO_FPGA         : out   std_logic;
    -- MRAM_SI_TO_FPGA           : out   std_logic;
    -- MRAM_SO_TO_FPGA           : in    std_logic;
    -- MRAM_CS_N_TO_FPGA         : out   std_logic;
    -- MRAM_WP_N_TO_FPGA         : out   std_logic;

    --  SDRAM Connections

    SDRAM_CLK                 : inout   std_logic;
    SDRAM_CKE                 : inout   std_logic;

    SDRAM_command             : inout   std_logic_vector (3 downto 0);
    SDRAM_address             : inout   std_logic_vector (12 downto 0);
    SDRAM_bank                : inout   std_logic_vector (1 downto 0);
    SDRAM_data                : inout std_logic_vector (15 downto 0);
    SDRAM_mask                : inout   std_logic_vector (1 downto 0)
      -- ;

    --   Microphone Connections

    -- MIC_CLK                   : out   std_logic;
    -- MIC_DATA_R                : in    std_logic;
    -- MIC_DATA_L                : in    std_logic;

    --   Inertial Module 1

    -- IM_SCLK_TO_FPGA           : out   std_logic;
    -- IM_SDI_TO_FPGA            : in    std_logic;
    -- IM_SDO_TO_FPGA            : out   std_logic;
    -- IM_NCS_TO_FPGA            : out   std_logic;
    -- IM_INT_TO_FPGA

    --   Inertial Module 2

    -- IM2_INT_M                 : in    std_logic ;
    -- IM2_CS_AG                 : out   std_logic ;
    -- IM2_INT1_AG               : in    std_logic ;
    -- IM2_SDO_M                 : in    std_logic ;
    -- IM2_CS_M                  : out   std_logic ;
    -- IM2_SPI_SDI               : out   std_logic ;
    -- IM2_DRDY_M                : in    std_logic ;
    -- IM2_SDO_AG                : in    std_logic ;
    -- IM2_INT2_AG               : in    std_logic ;
    -- IM2_SPI_SCLK              : out   std_logic ;

    --   GPS

    -- RXD_GPS_TO_FPGA           : out   std_logic;
    -- TXD_GPS_TO_FPGA           : in    std_logic;
    -- TIMEPULSE_GPS_TO_FPGA     : in    std_logic;
    -- EXTINT_GPS_TO_FPGA        : out   std_logic;

    -- Voltage Selectable GPIO

    -- GPIOSEL                   : out   std_logic_vector (15 downto 0) ;

    --  1.8V GPIO

    -- GPIO1P8                   : out   std_logic_vector (7 downto 0) ;

    --  3.3V GPIO

    -- GPIO3P3                   : inout std_logic_vector (7 downto 0)

  ) ;

  end entity CrossConnectCheck ;

architecture structural of CrossConnectCheck is

  component CheckConnect is

    Generic (
      bits_g                    : natural := 10
    ) ;
    Port (
      clk                       : in    std_logic ;
      check_io                  : inout std_logic_vector (bits_g-1 downto 0)
    ) ;
  end component CheckConnect ;

  --  Determine where the I/O pins will go in a combined vector.

  constant sdram_clkstr_c     : natural := 0 ;
  constant sdram_ckestr_c     : natural := sdram_clkstr_c + 1 ;
  constant sdram_commandstr_c : natural := sdram_ckestr_c + 1 ;
  constant sdram_commandend_c : natural := sdram_commandstr_c +
                                           SDRAM_command'length - 1 ;
  constant sdram_addressstr_c : natural := sdram_commandend_c + 1 ;
  constant sdram_addressend_c : natural := sdram_addressstr_c +
                                           SDRAM_address'length - 1 ;
  constant sdram_bankstr_c    : natural := sdram_addressend_c + 1 ;
  constant sdram_bankend_c    : natural := sdram_bankstr_c +
                                           SDRAM_bank'length - 1 ;
  constant sdram_datastr_c    : natural := sdram_bankend_c + 1 ;
  constant sdram_dataend_c    : natural := sdram_datastr_c +
                                           SDRAM_data'length - 1 ;
  constant sdram_maskstr_c    : natural := sdram_dataend_c + 1 ;
  constant sdram_maskend_c    : natural := sdram_maskstr_c +
                                           SDRAM_mask'length - 1 ;

  constant check_size_c       : natural := sdram_maskend_c + 1 ;

begin

  chkcon : CheckConnect
    Generic Map (
      bits_g                      => check_size_c
    )
    Port Map (
      clk                         => CLK_50MHZ_TO_FPGA,
      check_io (sdram_clkstr_c)   => SDRAM_clk,
      check_io (sdram_ckestr_c)   => SDRAM_cke,
      check_io (sdram_commandend_c downto sdram_commandstr_c)
                                  => SDRAM_command,
      check_io (sdram_addressend_c downto sdram_addressstr_c)
                                  => SDRAM_address,
      check_io (sdram_bankend_c    downto sdram_bankstr_c)
                                  => SDRAM_bank,
      check_io (sdram_dataend_c    downto sdram_datastr_c)
                                  => SDRAM_data,
      check_io (sdram_maskend_c    downto sdram_maskstr_c)
                                  => SDRAM_mask
    ) ;

end architecture structural ;
