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

library IEEE ;                        --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;         --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;            --! Use numeric standard.



----------------------------------------------------------------------------
--
--! @brief      PowerMonitorFPGA_TopLevel.
--! @details    Maps top level FPGA pins into Collar.vhd
--!
--! @param      CLK_50MHZ_TO_FPGA       Master clock for the system.
--!
--! @param      BAT_HIGH_TO_FPGA        Battery is above minimum voltage.
--!
--! @param      FORCED_START_N_TO_FPGA  System force to run.
--!
--! @param      PC_STATUS_CHG           Power Controller status change
--!                                     detected.
--! @param      PC_SPI_NCS              SPI to Power Controller chip select.
--! @param      PC_SPI_CLK              SPI to PC clock.
--! @param      PC_SPI_DIN              SPI to PC MOSI.
--! @param      PC_SPI_DOUT             SPI to PC MISO.
--! @param      PC_FLASH_CLK            Flash clock through Power Ctl.
--! @param      PC_FLASH_CS_N           Flash chip select through PC.
--! @param      PC_FLASH_DATA           Flash data through PC.
--! @param      PC_FLASH_DIR            Flash data direction through PC.
--!                                     FPGA to Flash when '1'.
--!
--! @param      SDA_TO_FPGA_CPLD        I2C data.
--! @param      SCL_TO_FPGA_CPLD        I2C clock.
--!
--! @param      DATA_TX_DAT_TO_FPGA     Data Transmitter connections.
--!
--! @param      SDCARD_DI_CLK_TO_FPGA   Directly connected SD card clock.
--! @param      SDCARD_DI_CMD_TO_FPGA   Directly connected SD card command.
--! @param      SDCARD_DI_DAT_TO_FPGA   Directly connected SD card data.
--!
--! @param      SDCARD_CLK_TO_FPGA      Level shifted SD card clock.
--! @param      SDCARD_CMD_TO_FPGA      Level shifted SD card command.
--! @param      SDCARD_DAT_TO_FPGA      Level shifted SD card data.
--!
--! @param      MRAM_SCLK_TO_FPGA       Magnetic Memory SPI clock.
--! @param      MRAM_SI_TO_FPGA         Magnetic Memory SPI MOSI.
--! @param      MRAM_SO_TO_FPGA         Magnetic Memory SPI MISO.
--! @param      MRAM_CS_N_TO_FPGA       Magnetic Memory SPI chip select.
--! @param      MRAM_WP_N_TO_FPGA       Magnetic Memory SPI write protect.
--!
--! @param      SDRAM_CLK               SD RAM clock.
--! @param      SDRAM_CKE               SD RAM clock enable.
--! @param      SDRAM_command           SD RAM command.
--! @param      SDRAM_address           SD RAM address.
--! @param      SDRAM_bank              SD RAM bank.
--! @param      SDRAM_data              SD RAM data.
--! @param      SDRAM_mask              SD RAM byte mask.
--!
--! @param      MIC_CLK                 Microphone clock
--! @param      MIC_DATA_R              Righthand microphone data.
--! @param      MIC_DATA_L              Lefthand microphone data.
--!
--! @param      IM2_INT_M               Inertial Module Magnetic interrupt.
--! @param      IM2_CS_AG               IM Gyroscope SPI chip select.
--! @param      IM2_INT1_AG             IM Gyroscope interrupt 1.
--! @param      IM2_SDO_M               IM Magnetic SPI MISO.
--! @param      IM2_CS_M                IM Magnetic SPI chip select.
--! @param      IM2_SPI_SDI             IM shared SPI MOSI.
--! @param      IM2_DRDY_M              IM Magnetic data ready.
--! @param      IM2_SDO_AG              IM Gyroscope SPI MISO.
--! @param      IM2_INT2_AG             IM Gyroscope interrupt 2.
--! @param      IM2_SPI_SCLK            IM shared SPI clock.
--!
--!
--! @param      RXD_GPS_TO_FPGA         GPS UART receive.
--! @param      TXD_GPS_TO_FPGA         GPS UART transmit.
--! @param      TIMEPULSE_GPS_TO_FPGA   GPS Timepulse.
--! @param      EXTINT_GPS_TO_FPGA      GPS interrupt from FPGA.
--!
--! @param      GPIOSEL                 Bank Voltage Selectable GPIO.
--! @param      GPIO1P8                 1P8 GPIO.
--! @param      GPIO3P3                 3p3 GPIO.
--!
--
----------------------------------------------------------------------------

entity DevBoard_PowerMonitorFPGA_TopLevel is

  Port (

    --   Clocks

    CLK_50MHZ_TO_FPGA           : in   std_logic;

    --  System Status

    BAT_HIGH_TO_FPGA            : in    std_logic;
    FORCED_START_N_TO_FPGA      : in    std_logic;

    --Power Controller

    PC_STATUS_CHG               : in    std_logic;
    PC_SPI_NCS                  : out   std_logic;
    PC_SPI_CLK                  : out   std_logic;
    PC_SPI_DIN                  : out   std_logic;
    PC_SPI_DOUT                 : in    std_logic;

    PC_FLASH_CLK                : inout std_logic;
    PC_FLASH_CS_N               : inout std_logic;
    PC_FLASH_DATA               : inout std_logic_vector(3 downto 0);
    PC_FLASH_DIR                : inout std_logic;

    --   I2C Bus

    SDA_TO_FPGA_CPLD            : inout std_logic;
    SCL_TO_FPGA_CPLD            : inout std_logic;

    -- Data Transmitter Connections

    DATA_TX_DAT_TO_FPGA         : inout std_logic_vector(4 downto 0);

    -- Direct SDCard Connections

    SDCARD_DI_CLK_TO_FPGA       : out   std_logic;
    SDCARD_DI_CMD_TO_FPGA       : inout std_logic;
    SDCARD_DI_DAT_TO_FPGA       : inout std_logic_vector(3 downto 0);


    -- Level Shifted SDCard Connections

    SDCARD_CLK_TO_FPGA          : out   std_logic;
    SDCARD_CMD_TO_FPGA          : inout std_logic;
    SDCARD_DAT_TO_FPGA          : inout std_logic_vector(3 downto 0);


    --  Magnetic RAM Connections

    MRAM_SCLK_TO_FPGA           : out   std_logic;
    MRAM_SI_TO_FPGA             : out   std_logic;
    MRAM_SO_TO_FPGA             : inout std_logic;
    MRAM_CS_N_TO_FPGA           : out   std_logic;
    MRAM_WP_N_TO_FPGA           : out   std_logic;

    --  SDRAM Connections

    SDRAM_CLK                   : out   std_logic;
    SDRAM_CKE                   : out   std_logic;
    SDRAM_command               : out   std_logic_vector(3 downto 0);
    SDRAM_address               : out   std_logic_vector(12 downto 0);
    SDRAM_bank                  : out   std_logic_vector(1 downto 0);
    SDRAM_data                  : inout std_logic_vector(15 downto 0);
    SDRAM_mask                  : out   std_logic_vector(1 downto 0);

    --   Microphone Connections

    MIC_CLK                     : out   std_logic;
    MIC_DATA_R                  : inout std_logic;
    MIC_DATA_L                  : inout std_logic;

    --   Inertial Module 1

    -- IM_SCLK_TO_FPGA             : out   std_logic;
    -- IM_SDI_TO_FPGA              : in    std_logic;
    -- IM_SDO_TO_FPGA              : out   std_logic;
    -- IM_NCS_TO_FPGA              : out   std_logic;
    -- IM_INT_TO_FPGA              : in    std_logic;

    --   Inertial Module 2

    IM2_INT_M                   : inout std_logic ;
    IM2_CS_AG                   : out   std_logic ;
    IM2_INT1_AG                 : inout std_logic ;
    IM2_SDO_M                   : inout std_logic ;
    IM2_CS_M                    : out   std_logic ;
    IM2_SPI_SDI                 : out   std_logic ;
    IM2_DRDY_M                  : inout std_logic ;
    IM2_SDO_AG                  : inout std_logic ;
    IM2_INT2_AG                 : inout std_logic ;
    IM2_SPI_SCLK                : out   std_logic ;

    --   GPS

    RXD_GPS_TO_FPGA             : out   std_logic;
    TXD_GPS_TO_FPGA             : inout std_logic;
    TIMEPULSE_GPS_TO_FPGA       : inout std_logic;
    EXTINT_GPS_TO_FPGA          : out   std_logic;

    -- Voltage Selectable GPIO

    GPIOSEL                     : out   std_logic_vector (15 downto 0);

    --  1.8V GPIO
    GPIO1P8                     : inout std_logic_vector(7 downto 0);

    --  3.3V GPIO

    GPIO3P3                     : inout std_logic_vector(7 downto 0)

  ) ;

  end entity DevBoard_PowerMonitorFPGA_TopLevel ;

architecture structural of DevBoard_PowerMonitorFPGA_TopLevel is

  --
  signal count : unsigned(7 downto 0);
  --

  


begin

  PC_SPI_NCS                  <= '1';
  PC_SPI_CLK                  <= '1';
  PC_SPI_DIN                  <= '1';


  GPIOSEL (0) <= count (7);
  

  --------------------------------------------------------------------------
  --  A simple counter test to test FPGA functionality via scope on GPIO.
  --------------------------------------------------------------------------

  count_test : process (CLK_50MHZ_TO_FPGA)
  begin
    if (rising_edge (CLK_50MHZ_TO_FPGA)) then
      count <= count + 1;
    end if;
  end process;

end architecture structural ;
