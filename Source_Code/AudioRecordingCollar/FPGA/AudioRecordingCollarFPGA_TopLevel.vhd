----------------------------------------------------------------------------
--
--! @file       AudioRecordingCollarFPGA_TopLevel.vhd
--! @brief      Mapping from FPGA pin names to Collar signals.
--! @details    Map FPGA pins to Collar Signals.
--! @author     Emery Newlon and Christopher Casebeer
--! @date       December 2014
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.


library WORK ;                        --! Local libraries.
use WORK.SHARED_SDC_VALUES_PKG.ALL ;  --! Values used by SDC as well.
use WORK.SDRAM_INFORMATION_PKG.ALL ;  --! SDRAM chip information.


----------------------------------------------------------------------------
--
--! @brief     PowerMonitorFPGA_TopLevel.
--! @details    Maps top level FPGA pins into Collar.vhd
--!             
--!
--! @param      CLK_50MHZ_TO_FPGA         Master clock for the system.
--!                               
--! @param      BAT_HIGH_TO_FPGA          Battery is above minimum voltage. 
--!                              
--! @param      FORCE_STARTUP_TO_FPGA     System force to run.
--!
--! @param      PC_STATUS_CHANGED       Power Controller status change
--!                                     detected.
--! @param      PC_SPI_NCS              SPI to Power Controller chip select.
--! @param      PC_SPI_CLK              SPI to PC clock.
--! @param      PC_SPI_DIN              SPI to PC MOSI.
--! @param      PC_SPI_DOUT             SPI to PC MISO.
--!
--!
--! @param      FLASH_C                 Flash clock.
--! @param      FLASH_S_N               Flash select
--! @param      PC_FLASH_DATA           Flash data
--! 
--! @param      I2C_SDA                I2C data.                 
--! @param      I2C_SCL                I2C clock.
--!
--! @param    FPGA_SPI_CLK             SPI 10 pin communication.
--! @param    FPGA_SPI_MOSI            SPI 10 pin communication.
--! @param    FPGA_TDO_SPI_MISO        SPI 10 pin communication.  
--! @param    FPGA_TMS_SPI_CS          SPI 10 pin communication.  
--!
--!                                   
--! @param      TXRX_MOSI_TO_FPGA         Data Transmitter connections.
--! @param      TXRX_CS_N_TO_FPGA         Data Transmitter connections.
--! @param      TXRX_GPIO3_TO_FPGA_CPLD   Data Transmitter connections.
--! @param      TXRX_SCLK_TO_FPGA         Data Transmitter connections.
--! @param      TXRX_MISO_TO_FPGA         Data Transmitter connections.
--!                                  
--! @param      SDCARD_DI_CLK_TO_FPGA   Directly connected SD card clock.
--! @param      SDCARD_DI_CMD_TO_FPGA   Directly connected SD card command.
--! @param      SDCARD_DI_DAT_TO_FPGA   Directly connected SD card data. 
--!   
--!
--!
--! @param      MRAM_SCK_TO_FPGA       Magnetic Memory SPI clock.
--! @param      MRAM_SI_TO_FPGA         Magnetic Memory SPI MOSI.
--! @param      MRAM_SO_TO_FPGA         Magnetic Memory SPI MISO.
--! @param      MRAM_CS_N_TO_FPGA       Magnetic Memory SPI chip select.
--! @param      MRAM_WP_N_TO_FPGA       Magnetic Memory SPI write protect.
--!
--!
--!
--! @param      SDRAM_CLK           SD RAM clock.
--! @param      SDRAM_CKE           SD RAM clock enable.
--! @param      SDRAM_command       SD RAM command.
--! @param      SDRAM_address       SD RAM address.
--! @param      SDRAM_bank          SD RAM bank.
--! @param      SDRAM_data          SD RAM data.
--! @param      SDRAM_mask          SD RAM byte mask.
--! 
--!
--! @param      MIC_CLK_TO_FPGA                 Microphone clock
--! @param      MIC_B_DATA_TO_FPGA              Sensor board MIC header
--! @param      MIC_A_DATA_TO_FPGA              On sensor board MIC
--!
--!
--! @param      IM_INT_M_TO_FPGA              Inertial Module Magnetic interrupt.
--! @param      IM_CS_A_G_TO_FPGA             IM Gyroscope SPI chip select.
--! @param      IM_INT1_A_G_TO_FPGA           IM Gyroscope interrupt 1.
--! @param      IM_SDO_M_TO_FPGA              IM Magnetic SPI MISO.
--! @param      IM_CS_M_TO_FPGA               IM Magnetic SPI chip select.
--! @param      IM_SPI_SDI_TO_FPGA            IM shared SPI MOSI.
--! @param      IM_DRDY_M_TO_FPGA             IM Magnetic data ready.
--! @param      IM_SDO_A_G_TO_FPGA            IM Gyroscope SPI MISO.
--! @param      IM_INT2_A_G_TO_FPGA           IM Gyroscope interrupt 2.
--! @param      IM_SPI_SCLK_TO_FPGA           IM shared SPI clock.  
--!
--!
--! @param      RXD_GPS_TO_FPGA               GPS UART receive.
--! @param      TXD_GPS_TO_FPGA               GPS UART transmit.
--! @param      TIMEPULSE_GPS_TO_FPGA         GPS Timepulse.
--! @param      EXTINT_GPS_TO_FPGA            GPS interrupt from FPGA.
--!
--!
--!
--
----------------------------------------------------------------------------

entity AudioRecordingCollarFPGA_TopLevel is

  Port (

    --   Clocks
     
    CLK_50MHZ_TO_FPGA    : in   std_logic;

    --  System Status

    FPGA_BATT_INT : in std_logic;
    FORCE_STARTUP_TO_FPGA : in std_logic;

    --Power Controller

    PC_STATUS_CHANGED : in std_logic;
    PC_SPI_NCS  : out std_logic;
    PC_SPI_CLK  : out std_logic;
    PC_SPI_DIN  : out std_logic;
    PC_SPI_DOUT : in std_logic;

    FLASH_C       :inout std_logic;
    FLASH_S_N     :inout std_logic;
    PC_FLASH_DATA :inout std_logic_vector(3 downto 0);
    PC_FLASH_DIR  :inout std_logic;

    --   I2C Bus

    I2C_SDA : inout std_logic;
    I2C_SCL : inout std_logic;

    --   ESH SPI (TDO and MISO shared line)

    FPGA_SPI_CLK  : in std_logic;
    FPGA_SPI_MOSI : in std_logic;
    FPGA_TDO_SPI_MISO : in std_logic;
    FPGA_TMS_SPI_CS : in std_logic;

    -- Data Transmitter Connections

    TXRX_MOSI_TO_FPGA : out std_logic;
    TXRX_CS_N_TO_FPGA : out std_logic;
    TXRX_GPIO3_TO_FPGA_CPLD : inout std_logic;
    TXRX_SCLK_TO_FPGA : out std_logic;
    TXRX_MISO_TO_FPGA : inout std_logic;
    
    --Direct SDCard Connections
    SDCARD_DI_CLK_TO_FPGA   : out std_logic;
    SDCARD_DI_CMD_TO_FPGA   : inout std_logic;
    SDCARD_DI_DAT_TO_FPGA   : inout std_logic_vector(3 downto 0);


    --  Magnetic RAM Connections

    MRAM_SCK_TO_FPGA  : out std_logic;
    MRAM_SI_TO_FPGA   : out std_logic;
    MRAM_SO_TO_FPGA   : inout std_logic;
    MRAM_CS_N_TO_FPGA : out std_logic;
    MRAM_WP_N_TO_FPGA : out std_logic;
        
    --  SDRAM Connections

    SDRAM_CLK                   : out   std_logic;
    SDRAM_CKE                   : out   std_logic;
    SDRAM_command               : out   std_logic_vector(3 downto 0);
    SDRAM_address               : out   std_logic_vector(12 downto 0);
    SDRAM_bank                  : out   std_logic_vector(1 downto 0);
    SDRAM_data                  : inout std_logic_vector(15 downto 0);
    SDRAM_mask                  : out   std_logic_vector(1 downto 0);


    --   Microphone Connections

    MIC_CLK_TO_FPGA    : out std_logic;
    MIC_B_DATA_TO_FPGA : inout std_logic;
    MIC_A_DATA_TO_FPGA : inout std_logic;


    --   Inertial Module 2

    -- IM2_INT_M     : inout   std_logic ;
    -- IM2_CS_AG     : out   std_logic ;
    -- IM2_INT1_AG   : inout   std_logic ;
    -- IM2_SDO_M     : inout   std_logic ;
    -- IM2_CS_M      : out   std_logic ;
    -- IM2_SPI_SDI   : out   std_logic ;
    -- IM2_DRDY_M    : inout   std_logic ;
    -- IM2_SDO_AG    : inout   std_logic ;
    -- IM2_INT2_AG   : inout   std_logic ;
    -- IM2_SPI_SCLK  : out   std_logic ;
    
    
        --   Inertial Module 

    IM_INT_M_TO_FPGA      : inout   std_logic ;
    IM_CS_A_G_TO_FPGA     : out     std_logic ;
    IM_INT1_A_G_TO_FPGA   : inout   std_logic ;
    IM_SDO_M_TO_FPGA      : inout   std_logic ;
    IM_CS_M_TO_FPGA       : out     std_logic ;
    IM_SPI_SDI_TO_FPGA    : out     std_logic ;
    IM_DRDY_M_TO_FPGA     : inout   std_logic ;
    IM_SDO_A_G_TO_FPGA    : inout   std_logic ;
    IM_INT2_A_G_TO_FPGA   : inout   std_logic ;
    IM_SPI_SCLK_TO_FPGA   : out     std_logic ;

    --   GPS

    RXD_GPS_TO_FPGA       : out std_logic;
    TXD_GPS_TO_FPGA       : inout  std_logic;
    TIMEPULSE_GPS_TO_FPGA : inout  std_logic;
    EXTINT_GPS_TO_FPGA    : out std_logic; 

    -- USB
    ESH_FPGA_USB_DMINUS   : out std_logic;
    ESH_FPGA_USB_DPLUS    : out std_logic



  ) ;

  end entity AudioRecordingCollarFPGA_TopLevel ;
  
  

  
  

architecture structural of AudioRecordingCollarFPGA_TopLevel is


component Collar is

  Generic (
    master_clk_freq_g     : natural           := 10e6 ;
    button_cnt_g          : natural           :=  8 ;
    sdram_space_g         : SDRAM_Capacity_t  := SDRAM_16_Capacity_c ;
    sdram_times_g         : SDRAM_Timing_t    := SDRAM_75_2_Timing_c
  ) ;
  Port (
    master_clk            : in    std_logic ;
    buttons_in            : in    std_logic_vector (button_cnt_g-1
                                                      downto 0) ;

    batt_int_in           : in    std_logic ;
    forced_start_in       : in    std_logic ;

    i2c_clk_io            : inout std_logic ;
    i2c_data_io           : inout std_logic ;

    pc_statchg_in         : in    std_logic ;
    pc_spi_clk            : out   std_logic ;
    pc_spi_cs_out         : out   std_logic ;
    pc_spi_mosi_out       : out   std_logic ;
    pc_spi_miso_in        : in    std_logic ;

    pc_flash_clk          : out   std_logic ;
    pc_flash_cs_out       : out   std_logic ;
    pc_flash_data_io      : inout std_logic_vector (3 downto 0) ;
    pc_flash_dir_out      : out   std_logic ;

    sdram_clk             : out   std_logic ;
    sdram_clk_en_out      : out   std_logic ;
    sdram_command_out     : out   std_logic_vector (3 downto 0) ;
    sdram_mask_out        : out   std_logic_vector (1 downto 0) ;
    sdram_bank_out        : out   std_logic_vector (1 downto 0) ;

    sdram_addr_out        : out   std_logic_vector (12 downto 0) ;
    sdram_data_io         : inout std_logic_vector (15 downto 0) ;

    sd_clk                : out   std_logic ;
    sd_cmd_io             : inout std_logic ;
    sd_data_io            : inout std_logic_vector (3 downto 0) ;

    sdh_clk               : out   std_logic ;
    sdh_cmd_io            : inout std_logic ;
    sdh_data_io           : inout std_logic_vector (3 downto 0) ;

    gps_rx_io             : inout std_logic ;
    gps_tx_out            : out   std_logic ;
    gps_timemark_out      : out   std_logic ;
    gps_timepulse_io      : inout std_logic ;

    ms_clk                : out   std_logic ;
    ms_cs_out             : out   std_logic ;
    ms_mosi_out           : out   std_logic ;
    --ms_miso_in            : in    std_logic ;
    --ms_int_in             : in    std_logic ;

    ms_cs_accgyro_out     : out   std_logic ;
    ms_miso_accgyro_io    : inout std_logic ;
    ms_int1_accgyro_io    : inout std_logic ;
    ms_int2_accgyro_io    : inout std_logic ;

    ms_cs_mag_out         : out   std_logic ;
    ms_miso_mag_io        : inout std_logic ;
    ms_int_mag_io         : inout std_logic ;
    ms_drdy_mag_io        : inout std_logic ;

    magram_clk            : out   std_logic ;
    magram_cs_out         : out   std_logic ;
    magram_mosi_out       : out   std_logic ;
    magram_miso_io        : inout std_logic ;
    magram_writeprot_out  : out   std_logic ;

    mic_clk               : out   std_logic ;
    mic_right_io          : inout std_logic ;
    mic_left_io           : inout std_logic ;

    radio_clk             : out   std_logic ;
    radio_data_io         : inout std_logic_vector (3 downto 0)
  ) ;

end component;



signal count : unsigned(7 downto 0);


begin

--Simple Counter Test
ESH_FPGA_USB_DPLUS <= count(7);

C : Collar
    Generic Map(
      master_clk_freq_g         => master_clk_freq_c,
      button_cnt_g              => 8,
      sdram_space_g             => SDRAM_16_Capacity_c,
      sdram_times_g             => SDRAM_75_3_Timing_c
    )
    Port Map(
      master_clk                => CLK_50MHZ_TO_FPGA,
      buttons_in                => (others => '0'),

      batt_int_in               => FPGA_BATT_INT,
      forced_start_in           => FORCE_STARTUP_TO_FPGA,

      i2c_clk_io                => I2C_SDA,
      i2c_data_io               => I2C_SCL,

      pc_statchg_in             => PC_STATUS_CHANGED,
      pc_spi_clk                => PC_SPI_CLK,
      pc_spi_cs_out             => PC_SPI_NCS,
      pc_spi_mosi_out           => PC_SPI_DIN,
      pc_spi_miso_in            => PC_SPI_DOUT,

      pc_flash_clk              => FLASH_C,
      pc_flash_cs_out           => FLASH_S_N,
      pc_flash_data_io          => PC_FLASH_DATA,
      pc_flash_dir_out          => PC_FLASH_DIR,

      sdram_clk                 => SDRAM_CLK,
      sdram_clk_en_out          => SDRAM_CKE,
      sdram_command_out         => SDRAM_command,
      sdram_mask_out            => SDRAM_mask,
      sdram_bank_out            => SDRAM_bank,
      sdram_addr_out            => SDRAM_address,
      sdram_data_io             => SDRAM_data,

      -- sd_clk                    => SDCARD_CLK_TO_FPGA,
      -- sd_cmd_io                 => SDCARD_CMD_TO_FPGA,
      -- sd_data_io                => SDCARD_DAT_TO_FPGA (3 downto 0),

      sdh_clk                   => SDCARD_DI_CLK_TO_FPGA,
      sdh_cmd_io                => SDCARD_DI_CMD_TO_FPGA,
      sdh_data_io               => SDCARD_DI_DAT_TO_FPGA (3 downto 0),

      gps_rx_io                 => TXD_GPS_TO_FPGA,
      gps_tx_out                => RXD_GPS_TO_FPGA,
      gps_timemark_out          => EXTINT_GPS_TO_FPGA,
      gps_timepulse_io          => TIMEPULSE_GPS_TO_FPGA,

      ms_clk                    => IM_SPI_SCLK_TO_FPGA,
      ms_mosi_out               => IM_SPI_SDI_TO_FPGA,

      ms_cs_accgyro_out         => IM_CS_A_G_TO_FPGA,
      ms_miso_accgyro_io        => IM_SDO_A_G_TO_FPGA,
      ms_int1_accgyro_io        => IM_INT1_A_G_TO_FPGA,
      ms_int2_accgyro_io        => IM_INT2_A_G_TO_FPGA,

      ms_cs_mag_out             => IM_CS_M_TO_FPGA,
      ms_miso_mag_io            => IM_SDO_M_TO_FPGA,
      ms_int_mag_io             => IM_INT_M_TO_FPGA,
      ms_drdy_mag_io            => IM_DRDY_M_TO_FPGA,

      magram_clk                => MRAM_SCK_TO_FPGA,
      magram_cs_out             => MRAM_CS_N_TO_FPGA,
      magram_mosi_out           => MRAM_SI_TO_FPGA,
      magram_miso_io            => MRAM_SO_TO_FPGA,
      magram_writeprot_out      => MRAM_WP_N_TO_FPGA,

      mic_clk                   => MIC_CLK_TO_FPGA,
      mic_right_io              => MIC_B_DATA_TO_FPGA,
      mic_left_io               => MIC_A_DATA_TO_FPGA

      --radio_clk                 => TXRX_SCLK_TO_FPGA(0),
      --radio_data_io             => (others => '0')
    );
    
    
process(CLK_50MHZ_TO_FPGA)
begin
  if (CLK_50MHZ_TO_FPGA'event and CLK_50MHZ_TO_FPGA = '1') then
    count <= count + 1;
  end if;
end process;


    
    
end architecture structural ;
