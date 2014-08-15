-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions
-- and other software and tools, and its AMPP partner logic
-- functions, and any output files from any of the foregoing
-- (including device programming or simulation files), and any
-- associated documentation or information are expressly subject
-- to the terms and conditions of the Altera Program License
-- Subscription Agreement, Altera MegaCore Function License
-- Agreement, or other applicable license agreement, including,
-- without limitation, that your use is for the sole purpose of
-- programming logic devices manufactured by Altera and sold by
-- Altera or its authorized distributors.  Please refer to the
-- applicable agreement for further details.

library ieee;
use ieee.std_logic_1164.all;
library altera;
use altera.altera_syn_attributes.all;

entity BEMicroCV is
	port
	(
-- {ALTERA_IO_BEGIN} DO NOT REMOVE THIS LINE!

		DDR3_CLK_50MHz              : in    std_logic ;
		user_led_n                  : out   std_logic_vector (7 downto 0) ;
		dip_sw                      : in    std_logic_vector (2 downto 0) ;
		tact                        : in    std_logic_vector (1 downto 0) ;

		-- sd_clk                      : out   std_logic ;
		-- sd_cmd                      : inout std_logic ;
		-- sd_d                        : inout std_logic_vector (3 downto 0) ;
    -- sd_mon_clk                  : out   std_logic ;
    -- sd_mon_cmd                  : out   std_logic ;
    -- sd_mon_data                 : out   std_logic_vector (3 downto 0) ;

    psd_clk                     : out   std_logic ;
    psd_cmd                     : inout std_logic ;
    psd_data                    : inout std_logic_vector (3 downto 0) ;
    psd_vsw1                    : out   std_logic_vector (1 downto 0) ;
    -- psd_vsw2                    : out   std_logic_vector (1 downto 0) ;

    GPS_RX                      : in    std_logic ;
    GPS_TX                      : out   std_logic ;
    GPS_TIMEMARK                : out   std_logic ;
    -- GPS_RXD1                    : in    std_logic ;
    -- GPS_TXD1                    : out   std_logic ;
    -- GPS_ExtInt0                 : out   std_logic ;

    -- Inertial_XM_CS              : out   std_logic ;
    -- Inertial_XM_Int1            : in    std_logic ;
    -- Inertial_XM_Int2            : in    std_logic ;
    -- Inertial_XM_MISO            : in    std_logic ;
    -- Inertial_MOSI               : out   std_logic ;
    -- Inertial_Clk                : out   std_logic ;
    -- Inertial_G_CS               : out   std_logic ;
    -- Inertial_G_Int              : in    std_logic ;
    -- Inertial_DRdy               : in    std_logic ;
    -- Inertial_G_DEn              : out   std_logic ;
    -- Inertial_G_MISO             : in    std_logic ;

    InertialCS_XM               : out   std_logic ;
    InertialInt1_XM             : in    std_logic ;
    InertialInt2_XM             : in    std_logic ;
    InertialSPI_DO_XM           : in    std_logic ;
    InertialSPI_DI              : out   std_logic ;
    InertialSPI_Clk             : out   std_logic ;
    -- InertialCS_G                : out   std_logic ;
    InertialInt_G               : in    std_logic ;
    InertialDRdy_G              : in    std_logic ;
    -- InertialDEn_G               : out   std_logic ;
    InertialSPI_DO_G            : in    std_logic ;

    MagRAM_CS                   : out   std_logic ;
    MagRAM_MISO                 : in    std_logic ;
    MagRAM_WriteProt            : out   std_logic ;
    -- MagRAM_Hold                 : out   std_logic ;
    MagRAM_SPIclk               : out   std_logic ;
    MagRAM_MOSI                 : out   std_logic ;

    MicClk                      : out   std_logic ;
    MicData                     : in    std_logic

-- {ALTERA_IO_END} DO NOT REMOVE THIS LINE!

	) ;

-- {ALTERA_ATTRIBUTE_BEGIN} DO NOT REMOVE THIS LINE!
-- {ALTERA_ATTRIBUTE_END} DO NOT REMOVE THIS LINE!
end BEMicroCV;

architecture ppl_type of BEMicroCV is


  --  Acoustic Recorder Collar mapping.

  component Collar is

  Generic (
    master_clk_freq_g     : natural   := 10e6 ;
    button_cnt_g          : natural   :=  8
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
    sdram_addr_out        : out   std_logic_vector (13 downto 0) ;
    sdram_data_io         : inout std_logic_vector (15 downto 0) ;

    sd_clk                : out   std_logic ;
    sd_cmd_io             : inout std_logic ;
    sd_data_io            : inout std_logic_vector (3 downto 0) ;
    sd_vsw_out            : out   std_logic_vector (1 downto 0) ;

    sdh_clk               : out   std_logic ;
    sdh_cmd_io            : inout std_logic ;
    sdh_data_io           : inout std_logic_vector (3 downto 0) ;

    gps_rx_in             : in    std_logic ;
    gps_tx_out            : out   std_logic ;
    gps_timemark_out      : out   std_logic ;

    ms_clk                : out   std_logic ;
    ms_cs_out             : out   std_logic ;
    ms_mosi_out           : out   std_logic ;
    ms_miso_in            : in    std_logic ;
    ms_int_in             : in    std_logic ;

    ms_cs_accgyro_out     : out   std_logic ;
    ms_miso_accgyro_in    : in    std_logic ;
    ms_int1_accgyro_in    : in    std_logic ;
    ms_int2_accgyro_in    : in    std_logic ;

    ms_cs_mag_out         : out   std_logic ;
    ms_miso_mag_in        : in    std_logic ;
    ms_int_mag_in         : in    std_logic ;
    ms_drdy_mag_in        : in    std_logic ;

    magram_clk            : out   std_logic ;
    magram_cs_out         : out   std_logic ;
    magram_mosi_out       : out   std_logic ;
    magram_miso_in        : in    std_logic ;
    magram_writeprot_out  : out   std_logic ;

    mic_clk               : out   std_logic ;
    mic_right_in          : in    std_logic ;
    mic_left_in           : in    std_logic ;

    radio_clk             : out   std_logic ;
    radio_data_io         : inout std_logic_vector (4 downto 0)
  ) ;


  end component Collar ;

  -- signal sd_clock           : std_logic ;


-- {ALTERA_COMPONENTS_BEGIN} DO NOT REMOVE THIS LINE!
-- {ALTERA_COMPONENTS_END} DO NOT REMOVE THIS LINE!
begin
-- {ALTERA_INSTANTIATION_BEGIN} DO NOT REMOVE THIS LINE!
-- {ALTERA_INSTANTIATION_END} DO NOT REMOVE THIS LINE!

  inst : Collar
    Generic Map(
      master_clk_freq_g     => 50e6,
      button_cnt_g          => tact'length
    )
    Port Map (
      master_clk            => DDR3_CLK_50MHz,
      buttons_in            => not tact,

      batt_int_in           => '0',
      forced_start_in       => '0',

      i2c_clk_io            => '0',
      i2c_data_io           => '0',

      pc_statchg_in         => '0',
      pc_spi_miso_in        => '0',

      -- sd_clk                => sd_clock,
      -- sd_cmd                => sd_cmd,
      -- sd_data               => sd_d,

      sd_clk                => psd_clk,
      sd_cmd_io             => psd_cmd,
      sd_data_io            => psd_data,
      sd_vsw_out            => psd_vsw1,

      sdh_cmd_io            => '0',

      gps_rx_in             => gps_rx,
      gps_tx_out            => gps_tx,
      gps_timemark_out      => gps_timemark,

      -- gps_rx                => gps_rxd1,
      -- gps_tx                => gps_txd1,
      -- gps_timemark          => gps_extint0,

      -- ms_mosi               => Inertial_MOSI,
      -- ms_clk                => Inertial_Clk,
      -- ms_xm_miso            => Inertial_XM_MISO,
      -- ms_xm_cs              => Inertial_XM_CS,
      -- ms_xm_int1            => Inertial_XM_Int1,
      -- ms_xm_int2            => Inertial_XM_Int2,
      -- ms_g_miso             => Inertial_G_MISO,
      -- ms_g_cs               => Inertial_G_CS,
      -- ms_g_den              => Inertial_G_DEn,
      -- ms_g_drdy             => Inertial_DRdy,
      -- ms_g_int              => Inertial_G_Int,

      ms_clk                => InertialSPI_Clk,
      ms_cs_out             => InertialCS_XM,
      ms_mosi_out           => InertialSPI_DI,
      ms_miso_in            => InertialSPI_DO_XM,
      ms_int_in             => InertialInt1_XM,

      ms_miso_accgyro_in    => '0',
      ms_int1_accgyro_in    => '0',
      ms_int2_accgyro_in    => '0',

      ms_miso_mag_in        => '0',
      ms_int_mag_in         => '0',
      ms_drdy_mag_in        => '0',

      magram_clk            => MagRAM_SPIclk,
      magram_cs_out         => MagRAM_CS,
      magram_mosi_out       => MagRAM_MOSI,
      magram_miso_in        => MagRAM_MISO,
      magram_writeprot_out  => MagRAM_WriteProt,

      mic_clk               => MicClk,
      mic_right_in          => '0',
      mic_left_in           => '0'
    ) ;

  --  Copy the SD lines to the GPIO to allow the protocol analyser to
  --  be easily hooked up.

  -- sd_clk                    <= sd_clock ;

  -- sd_mon_clk                <= sd_clock ;
  -- sd_mon_cmd                <= sd_cmd ;
  -- sd_mon_data               <= sd_d ;

  --  Turn off those signals not used.

  user_led_n                <= (others => '1') ;


end ;
