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
--! @param      FORCE_STARTUP_TO_FPGA    
--!
--! @param      PC_STATUS_CHANGED        
--! @param      PC_SPI_NCS         
--! @param      PC_SPI_CLK     
--! @param      FPGA_TDO_SPI_MISO    
--! @param      FPGA_SPI_MOSI   
--! @param      PC_FLASH_CLK    
--! @param      FLASH_S_N  
--! @param      PC_FLASH_DATA   
--!
--! @param      PC_FLASH_DIR     
--! @param      I2C_SDA     
--!                                   
--!                                  
--! @param      I2C_SCL   
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

entity AudioRecordingCollarFPGA_TopLevel is

  Port (

--   Clocks
 
CLK_50MHZ_TO_FPGA    : in   std_logic;

--  System Status

-- BAT_HIGH_TO_FPGA : in std_logic;
-- FORCE_STARTUP_TO_FPGA : in std_logic;

--Power Controller

-- PC_STATUS_CHANGED : in std_logic;
PC_SPI_NCS : out std_logic;
PC_SPI_CLK : out std_logic;
PC_SPI_DIN : out std_logic;
-- PC_SPI_DOUT : in std_logic;

-- FLASH_C :inout std_logic;
-- FLASH_S_N :inout std_logic;
-- PC_FLASH_DATA :inout std_logic_vector(3 downto 0);
-- PC_FLASH_DIR :inout std_logic;

--   I2C Bus

-- I2C_SDA : inout std_logic;
-- I2C_SCL : inout std_logic;

--   ESH SPI (TDO and MISO shared line)

FPGA_SPI_CLK  : in std_logic;
FPGA_SPI_MOSI : in std_logic;
FPGA_TDO_SPI_MISO : in std_logic;
FPGA_TMS_SPI_CS : in std_logic;

-- Data Transmitter Connections

--DATA_TX_DAT0_TO_FPGA : inout std_logic;
--DATA_TX_DAT1_TO_FPGA : inout std_logic;
--DATA_TX_DAT2_TO_FPGA : inout std_logic;
--DATA_TX_DAT3_TO_FPGA : inout std_logic;
--DATA_TX_DAT4_TO_FPGA : inout std_logic;
DATA_TX_DAT_TO_FPGA : inout std_logic_vector(4 downto 0);

--Direct SDCard Connections

-- SDCARD_DI_CLK_TO_FPGA : out std_logic;
-- SDCARD_DI_CMD_TO_FPGA  : inout std_logic;
-- SDCARD_DI_DAT_TO_FPGA : inout std_logic_vector(3 downto 0);
--SDCARD_DI_DAT1_TO_FPGA : inout std_logic;
--SDCARD_DI_DAT2_TO_FPGA : inout std_logic;
--SDCARD_DI_CD_DAT3_TO_FPGA : inout std_logic;

--Level Shifted SDCard Connections

-- SDCARD_CLK_TO_FPGA : out std_logic;
-- SDCARD_CMD_TO_FPGA : inout std_logic;
-- SDCARD_DAT_TO_FPGA : inout std_logic_vector(3 downto 0);
--SDCARD_DAT1_TO_FPGA : inout std_logic;
--SDCARD_DAT2_TO_FPGA : inout std_logic;
--SDCARD_CD_DAT3_TO_FPGA : inout std_logic;

--  Magnetic RAM Connections

-- MRAM_SCLK_TO_FPGA : out std_logic;
-- MRAM_SI_TO_FPGA : out std_logic;
-- MRAM_SO_TO_FPGA  :in std_logic;
-- MRAM_CS_N_TO_FPGA : out std_logic;
-- MRAM_WP_N_TO_FPGA : out std_logic;
    
--  SDRAM Connections


-- SDRAM_CLK : out std_logic; 
-- SDRAM_CKE : out std_logic;


-- SDRAM_command : out std_logic_vector(3 downto 0);
-- SDRAM_address : out std_logic_vector(12 downto 0);
-- SDRAM_bank : out std_logic_vector(1 downto 0);
-- SDRAM_data : inout std_logic_vector(15 downto 0);
-- SDRAM_mask : out std_logic_vector(1 downto 0);


--   Microphone Connections

-- MIC_CLK    : out std_logic;
-- MIC_DATA_R : in std_logic;
-- MIC_DATA_L : in std_logic;

--   Inertial Module 1

-- IM_SCLK_TO_FPGA : out std_logic;
-- IM_SDI_TO_FPGA : in std_logic;
-- IM_SDO_TO_FPGA : out std_logic;
-- IM_NCS_TO_FPGA : out std_logic;
-- IM_INT_TO_FPGA

--   Inertial Module 2

-- IM2_INT_M     : in   std_logic ;
-- IM2_CS_AG     : out   std_logic ;
-- IM2_INT1_AG   : in   std_logic ;
-- IM2_SDO_M     : in   std_logic ;
-- IM2_CS_M      : out   std_logic ;
-- IM2_SPI_SDI   : out   std_logic ;
-- IM2_DRDY_M    : in   std_logic ;
-- IM2_SDO_AG    : in   std_logic ;
-- IM2_INT2_AG   : in   std_logic ;
-- IM2_SPI_SCLK  : out   std_logic ;

--   GPS

-- RXD_GPS_TO_FPGA       : out std_logic;
-- TXD_GPS_TO_FPGA       : in  std_logic;
-- TIMEPULSE_GPS_TO_FPGA : in  std_logic;
-- EXTINT_GPS_TO_FPGA    : out std_logic; 

-- USB

ESH_FPGA_USB_DMINUS   : out std_logic;
ESH_FPGA_USB_DPLUS    : out std_logic


--  1.8V GPIO
-- GPIO1P8 : inout std_logic_vector(7 downto 0);

--  3.3V GPIO

-- GPIO3P3 : inout std_logic_vector(7 downto 0)

  ) ;

  end entity AudioRecordingCollarFPGA_TopLevel ;

architecture structural of AudioRecordingCollarFPGA_TopLevel is

--
signal count : unsigned(7 downto 0);
--

--component Collar is
--
--  Generic (
--    master_clk_freq_g     : natural   := 10e6 ;
--    button_cnt_g          : natural   :=  8
--  ) ;
--  Port (
--    master_clk            : in    std_logic ;
--    buttons_in            : in    std_logic_vector (button_cnt_g-1
--                                                      downto 0) ;
--
--    batt_int_in           : in    std_logic ;
--    forced_start_in       : in    std_logic ;
--
--    i2c_clk_io            : inout std_logic ;
--    i2c_data_io           : inout std_logic ;
--
--    pc_statchg_in         : in    std_logic ;
--    pc_spi_clk            : out   std_logic ;
--    pc_spi_cs_out         : out   std_logic ;
--    pc_spi_mosi_out       : out   std_logic ;
--    pc_spi_miso_in        : in    std_logic ;
--
--    FLASH_C          : out   std_logic ;
--    pc_flash_cs_out       : out   std_logic ;
--    pc_flash_data_io      : inout std_logic_vector (3 downto 0) ;
--    pc_flash_dir_out      : out   std_logic ;
--
--    sdram_clk             : out   std_logic ;
--    sdram_clk_en_out      : out   std_logic ;
--    sdram_command_out     : out   std_logic_vector (3 downto 0) ;
--    sdram_mask_out        : out   std_logic_vector (1 downto 0) ;
--    sdram_bank_out        : out   std_logic_vector (1 downto 0) ;
--    sdram_addr_out        : out   std_logic_vector (12 downto 0) ;
--    sdram_data_io         : inout std_logic_vector (15 downto 0) ;
--
--    sd_clk                : out   std_logic ;
--    sd_cmd_io             : inout std_logic ;
--    sd_data_io            : inout std_logic_vector (3 downto 0) ;
--    sd_vsw_out            : out   std_logic_vector (1 downto 0) ;
--
--    sdh_clk               : out   std_logic ;
--    sdh_cmd_io            : inout std_logic ;
--    sdh_data_io           : inout std_logic_vector (3 downto 0) ;
--
--    gps_rx_in             : in    std_logic ;
--    gps_tx_out            : out   std_logic ;
--    gps_timemark_out      : out   std_logic ;
--
--    ms_clk                : out   std_logic ;
--    ms_cs_out             : out   std_logic ;
--    ms_mosi_out           : out   std_logic ;
--    --ms_miso_in            : in    std_logic ;
--    --ms_int_in             : in    std_logic ;
--
--    ms_cs_accgyro_out     : out   std_logic ;
--    ms_miso_accgyro_in    : in    std_logic ;
--    ms_int1_accgyro_in    : in    std_logic ;
--    ms_int2_accgyro_in    : in    std_logic ;
--
--    ms_cs_mag_out         : out   std_logic ;
--    ms_miso_mag_in        : in    std_logic ;
--    ms_int_mag_in         : in    std_logic ;
--    ms_drdy_mag_in        : in    std_logic ;
--
--    magram_clk            : out   std_logic ;
--    magram_cs_out         : out   std_logic ;
--    magram_mosi_out       : out   std_logic ;
--    magram_miso_in        : in    std_logic ;
--    magram_writeprot_out  : out   std_logic ;
--
--    mic_clk               : out   std_logic ;
--    mic_right_in          : in    std_logic ;
--    mic_left_in           : in    std_logic ;
--
--    radio_clk             : out   std_logic ;
--    radio_data_io         : inout std_logic_vector (3 downto 0)
--  ) ;
--
--end component;


begin



--ESH_FPGA_USB_DMINUS <= '0';
--ESH_FPGA_USB_DPLUS  <= '0';


ESH_FPGA_USB_DMINUS <= count(7);
ESH_FPGA_USB_DPLUS  <= count(6);

PC_SPI_NCS  <= '1';
PC_SPI_CLK 	<= '1';
PC_SPI_DIN 	<= '1';



--C:Collar
--
--Generic Map(
--    master_clk_freq_g   => 50e6 ,
--    button_cnt_g       => 8
--)
--Port Map(
--
--    master_clk   => CLK_50MHZ_TO_FPGA,
--    buttons_in           => (others => '0'),
--
--    batt_int_in          => BAT_HIGH_TO_FPGA,
--    forced_start_in      => FORCE_STARTUP_TO_FPGA,
--
--    i2c_clk_io           => I2C_SDA,
--    i2c_data_io          => I2C_SCL,
--    
--    
--    pc_statchg_in         => PC_STATUS_CHANGED,
--    pc_spi_clk            => PC_SPI_CLK ,
--    pc_spi_cs_out         => PC_SPI_NCS,
--    pc_spi_mosi_out       => FPGA_TDO_SPI_MISO,
--    pc_spi_miso_in        => FPGA_SPI_MOSI,
--
--    pc_flash_clk          => FLASH_C,
--    pc_flash_cs_out       => FLASH_S_N,
--    pc_flash_data_io      => PC_FLASH_DATA,
--    pc_flash_dir_out      => PC_FLASH_DIR,
--
--    sdram_clk             => SDRAM_CLK ,
--    sdram_clk_en_out      => SDRAM_CKE ,
--    sdram_command_out     => SDRAM_command,
--    sdram_mask_out        => SDRAM_mask,
--    sdram_bank_out        => SDRAM_bank,
--    sdram_addr_out        => SDRAM_address,
--    sdram_data_io         => SDRAM_data,
--
--    sd_clk                => SDCARD_CLK_TO_FPGA,
--    sd_cmd_io             => SDCARD_CMD_TO_FPGA,
--    sd_data_io            => SDCARD_DAT_TO_FPGA(3 downto 0),
--    --sd_vsw_out            : out   std_logic_vector (1 downto 0),
--
--    sdh_clk              => SDCARD_DI_CLK_TO_FPGA,
--    sdh_cmd_io           => SDCARD_DI_CMD_TO_FPGA,
--    sdh_data_io          => SDCARD_DI_DAT_TO_FPGA(3 downto 0),
--
--    gps_rx_in             => TXD_GPS_TO_FPGA,
--    gps_tx_out            => RXD_GPS_TO_FPGA,
--    --Double Check.
--    gps_timemark_out      => EXTINT_GPS_TO_FPGA,
--
--    ms_clk                => IM2_SPI_SCLK,
--    --ms_cs_out             : out   std_logic ;
--    ms_mosi_out           =>  IM2_SPI_SDI, 
--    --ms_miso_in            : in    std_logic ;
--    --ms_int_in             : in    std_logic ;
--
--
--    ms_cs_accgyro_out     =>  IM2_CS_AG,
--    ms_miso_accgyro_in    => IM2_SDO_AG, 
--    ms_int1_accgyro_in    =>  IM2_INT1_AG,
--    ms_int2_accgyro_in    =>  IM2_INT2_AG,
--
--    ms_cs_mag_out         =>  IM2_CS_M, 
--    ms_miso_mag_in        =>  IM2_SDO_M, 
--    ms_int_mag_in         =>   IM2_INT_M,
--    ms_drdy_mag_in        =>  IM2_DRDY_M,
--
--    magram_clk            => MRAM_SCLK_TO_FPGA,
--    magram_cs_out         => MRAM_CS_N_TO_FPGA,
--    magram_mosi_out       => MRAM_SI_TO_FPGA,
--    magram_miso_in        => MRAM_SO_TO_FPGA,
--    magram_writeprot_out  => MRAM_WP_N_TO_FPGA,
--
--    mic_clk               => MIC_CLK,
--    mic_right_in          => MIC_DATA_R,
--    mic_left_in           => MIC_DATA_L,
--
--    radio_clk             => DATA_TX_DAT_TO_FPGA(0),
--    radio_data_io         => DATA_TX_DAT_TO_FPGA(4 downto 1)
--
--);


  --A simple counter test to test FPGA functionality via scope on GPIO.
  count_test: process(CLK_50MHZ_TO_FPGA)
    begin
      if (rising_edge(CLK_50MHZ_TO_FPGA)) then
          count <= count + 1;
		end if;
    end process;
end architecture structural ;
