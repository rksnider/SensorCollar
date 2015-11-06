---------------------------------
--
--! @file       $File$
--! @brief      Initialize and Control the ST Microelectronics LSM9DS1 IMU
--! @details    LSM9DS1 VHDL controller.
--! @copyright
--! @author     Chris Casebeer
--! @version    $Revision$

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
--  Chris Casebeer
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  christopher.casebee1@msu.montana.edu
--
---------------------------------




---------------------------------
--
--! @brief      Initialize and Control the ST Microelectronics LSM9DS1 IMU.
--! @details
--!
--! @param      IMU_AXIS_WORD_LENGTH_BYTES     The size of one axis of IMU device in bytes

--! @param      command_used_g        SPI_COMMANDS_GENERIC
--! @param      address_used_g        SPI_COMMANDS_GENERIC
--!
--! @param      command_width_bytes_g SPI_COMMANDS_GENERIC
--! @param      address_width_bytes_g SPI_COMMANDS_GENERIC
--! @param      data_length_bit_width_g SPI_COMMANDS_GENERIC
--!
--!
--!
--!
--! @param      clk                   System clock which drives entity.
--! @param      rst_n                 Active Low reset to reset entity
--! @param      startup               '1' causes state machine to once off push all
--!                                   non-default registers to the IMU over the SPI bus.
--! @param      curtime_in            FPGA time from the FPGA time component
--! @param      curtime_latch_in      Latch curtime across clock domains.
--! @param      curtime_valid_in      Latched curtime is valid when set.
--! @param      curtime_vlatch_in     Latch curtime when valid not set.
--! @param      gyro_data_rdy         Signal to flashblock that new gyro data is ready.
--! @param      accel_data_rdy        Signal to flashblock that new accel data is ready.
--! @param      mag_data_rdy          Signal to flashblock that new mag data is ready.
--! @param      temp_data_rdy         Signal to flashblock that new temp data is ready.
--!
--! @param      gyro_data_x           2 byte word for gyro X axis (2's complement) (Big endian)
--! @param      gyro_data_y           2 byte word for gyro Y axis (2's complement) (Big endian)
--! @param      gyro_data_z           2 byte word for gyro Z axis (2's complement) (Big endian)
--! @param      accel_data_x          2 byte word for accel X axis (2's complement) (Big endian)
--! @param      accel_data_y          2 byte word for accel Y axis (2's complement) (Big endian)
--! @param      accel_data_z          2 byte word for accel Z axis (2's complement) (Big endian)
--! @param      mag_data_x            2 byte word for mag X axis (2's complement) (Big endian)
--! @param      mag_data_y            2 byte word for mag Y axis (2's complement) (Big endian)
--! @param      mag_data_z            2 byte word for mag Z axis (2's complement) (Big endian)
--! @param      temp_data             2 byte word for temp X axis (2's complement) (Big endian)
--!
--! @param      sclk                  SCLK of the SPI interface. Tie to SCL/SPC of LSM9DS1.
--! @param      mosi                  MOSI. Tie to SDA/SDI/SDO of LSM9DS1.
--! @param      miso_XL_G             MISO of the XL_G SPI interface. Tie to SDO_A/G of LSM9DS1.
--! @param      miso_M                MISO of the M SPI interface. Tie to SDO_M of LSM9DS1.
--! @param      cs_XL_G               CS_N of the XL_G SPI interface. Tie to CS_A/G of LSM9DS1.
--! @param      cs_M                  sclk of the SPI interface. Tie to CS_M of LSM9DS1.
--!
--! @param      INT_M                 INT_M pin of the LSM9DS1
--! @param      DRDY_M                DRDY_M pin of the LSM9DS1
--! @param      INT1_A_G              INT1_A/G pin of the LSM9DS1
--! @param      INT2_A_G              INT2_A/G pin of the LSM9DS1
--!
--! @param      gyro_fpga_time        FPGA time associated with a gyro_data_rdy and its word.
--! @param      accel_fpga_time       FPGA time associated with a accel_data_rdy and its word.
--! @param      mag_fpga_time         FPGA time associated with a mag_data_rdy and its word.
--! @param      temp_fpga_time        FPGA time associated with a temp_data_rdy and its word.
--!
--!
--
---------------------------------




--This piece of VHDL code is to be used with the following two matlab scripts.
--LSM9DS1_XL_G_Register_Settings.m
--LSM9DS1_M_Register_Settings.m


-- Running these two scripts in the above order will generate an associated mif file
-- LSM9DS1_Register_Settings_Startup_Memory.mif

-- This file is read on entity startup to send the non-default registers to both the
-- Accelerometer Gyroscope portion of the IMU overs its SPI lines. Then the
-- non default registers are sent to the magnetometer. The IMU is split
-- into two separate devices each with its own register map and SPI chip select line.
-- Thus commands go to each device separately. The accelerometer/gyroscope device (XL_G)
-- and the magnetometer device (M) are handled separately.

-- The startup registers are sent first for the XL_G and then for the M. Both register
-- sets are pulled from the mif file generated by the scripts.


-- LSM9DS1 makes use of the spi abstraction layer spi_commands. This entity allows
-- pushing a command set to a slave device followed by payload bytes.

-- The spi_commands only allows for one MISO connection and one CS_N connection. However
-- with the IMU there are MISO/CS_N for each device. A multiplexer selects which
-- line the output of SPI_COMMANDS goes to depending on SPI_SELECT_XL_G_M. During
-- XL_G activity, SPI_SELECT_XL_G_M is set to '0', the cs_n coming from SPI_COMMAND is routed
-- to the DS1's CS_A/G pin. The MISO is taken from the SDO_A/G line. When SPI_SELECT_XL_G_M
-- is set to '1', the cs_m is used along with SDO_M.

-- The interrupt pins on the IMU are programmable. The state machine has been programmed
-- to recognize INT_1_A_G as gyroscope data ready and INT_2_A_G as accelerometer data rdy.

--All three data interrupts. Mag/XL/G are all positive logic. They are
--synchronized with one flip-flop before being read.


library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.


--A dual port ram is used.
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

LIBRARY GENERAL ;
--USE GENERAL.UTILITIES_PKG.ALL;          --  Use General Purpose Libraries
USE GENERAL.GPS_Clock_pkg.ALL;          --  Use GPS Clock information.



entity LSM9DS1_top is

  Generic (

  IMU_AXIS_WORD_LENGTH_BYTES  : natural := 2;


  command_used_g              : std_logic := '1';
  address_used_g              : std_logic := '0';
  command_width_bytes_g       : natural := 1;
  address_width_bytes_g       : natural := 1;
  data_length_bit_width_g     : natural := 10


  ) ;
  Port (
    clk                   : in    std_logic ;
    rst_n                 : in    std_logic ;

    startup               : in    std_logic;

    curtime_in            : in    std_logic_vector
                                      (gps_time_bytes_c*8-1 downto 0) ;
    curtime_latch_in      : in    std_logic ;
    curtime_valid_in      : in    std_logic ;
    curtime_vlatch_in     : in    std_logic ;


    gyro_data_rdy   : out     std_logic;
    accel_data_rdy  : out     std_logic;
    mag_data_rdy    : out     std_logic;
    temp_data_rdy   : out     std_logic;

    gyro_data_x     : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);
    gyro_data_y     : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);
    gyro_data_z     : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);

    accel_data_x    : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);
    accel_data_y    : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);
    accel_data_z    : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);

    mag_data_x      : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);
    mag_data_y      : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);
    mag_data_z      : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);

    temp_data       : out     std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8 - 1 downto 0);


    sclk            : out     std_logic;
    mosi            : out     std_logic;
    miso_XL_G       : in      std_logic;
    miso_M          : in      std_logic;
    cs_XL_G         : out     std_logic;
    cs_M            : out     std_logic;

    INT_M           : in      std_logic;
    DRDY_M          : in      std_logic;
    INT1_A_G        : in      std_logic;
    INT2_A_G        : in      std_logic;




    gyro_fpga_time  : out std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    accel_fpga_time : out std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    mag_fpga_time   : out std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    temp_fpga_time  : out std_logic_vector (gps_time_bytes_c*8-1 downto 0)



  ) ;

end entity LSM9DS1_top ;


architecture behavior of LSM9DS1_top is


    type IMU_STATE is   (
    IMU_STATE_WAIT,

    IMU_STATE_INIT_FETCH_XL_G_NUM_SETUP,
    IMU_STATE_INIT_FETCH_XL_G_NUM,

    IMU_STATE_INIT_FETCH_M_NUM_SETUP,
    IMU_STATE_INIT_FETCH_M_NUM,


    IMU_STATE_INIT_FETCH_XL_G,
    IMU_STATE_INIT_WRITE_XL_G,
    IMU_STATE_INIT_WAIT_XL_G,


    IMU_STATE_INIT_FETCH_M,
    IMU_STATE_INIT_WRITE_M,
    IMU_STATE_INIT_WAIT_M,

    IMU_STATE_FETCH_XL_SETUP,
    IMU_STATE_FETCH_XL,
    IMU_STATE_FETCH_XL_DONE,


    IMU_STATE_FETCH_G_SETUP,
    IMU_STATE_FETCH_G,
    IMU_STATE_FETCH_G_DONE,


    IMU_STATE_FETCH_M_SETUP,
    IMU_STATE_FETCH_M,
    IMU_STATE_FETCH_M_DONE


    );



  signal cur_imu_state   : IMU_STATE;
  signal next_imu_state  : IMU_STATE;


--Address where the number of registers to be initialized (number changed from default)
--for the magnetometer and the accelerometer/gyroscope is stored.
--2 8 bit numbers exist at memory locations 0 and 1. These represent the number of
--non default XL_G and M registers which exist in this memory.
  constant imu_initbuffer_xl_g_num_loc_c : std_logic_vector(7 downto 0) := x"00";
  constant imu_initbuffer_m_num_loc_c   : std_logic_vector(7 downto 0) := x"01";
  constant imu_initbuffer_data_start_loc_c : std_logic_vector(7 downto 0) := x"02";

  --Number of registers associated with a sensor and its data.
  --2 bytes for each axis of any single sensor.
  constant XL_G_M_register_count_c : natural := 6;

  constant IMU_REGISTER_SIZE_BYTES : natural := 1;

  --The beginning of the XYZ registers for the IMU devices.
  --The accelerometer XYZ registers start as x"28". They go for 6 bytes.
  constant XL_data_begin_addr : natural := 40; --x"28"
  constant G_data_begin_addr :natural := 24; --x"18";
  constant M_data_begin_addr : natural := 40; --x"28";


  --First bit of the LSM9DS1 command dictates if a read or a write occurs.
  --This is dictated in the device datasheet SPI protocol.
  constant RD_EN_BIT : std_logic := '1';
  constant WR_EN_BIT : std_logic := '0';


--Magnetometer multiple register read enable bit.
  constant MS_AUTOINCREMENT_BIT : std_logic := '1';


  --These numbers are stored as 16 bit values in memory.
  signal  xl_g_init_number : unsigned (7 downto 0);
  signal  m_init_number     : unsigned (7 downto 0);
  signal  spi_commands_complete : unsigned( 7 downto 0);


--Signals for the one port init buffer.
  signal imu_initbuffer_address_std : std_logic_vector(7 downto 0);
  signal imu_initbuffer_address : unsigned(7 downto 0);
  signal imu_initbuffer_rd_en : std_logic;
  signal imu_initbuffer_wr_en : std_logic;
  signal imu_initbuffer_q : std_logic_vector(15 downto 0);
  signal imu_initbuffer_data : std_logic_vector(15 downto 0);
  signal initbuffer_clk : std_logic;


  signal gyro_sample : std_logic_vector(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);
  signal accel_sample : std_logic_vector(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);
  signal mag_sample : std_logic_vector(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);
  signal temp_sample : std_logic_vector(IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);


  --Interrupt tracking associated signals
  signal INT_M_follower : std_logic;
  signal INT_M_req : std_logic;
  signal INT_M_processed : std_logic;
  signal INT_M_processed_follower : std_logic;

  signal INT1_A_G_follower : std_logic;
  signal gyro_req : std_logic;
  signal gyro_processed : std_logic;
  signal gyro_processed_follower : std_logic;

  signal INT2_A_G_follower : std_logic;
  signal accel_req : std_logic;
  signal accel_processed : std_logic;
  signal accel_processed_follower : std_logic;

  signal DRDY_M_follower : std_logic;
  signal DRDY_M_req : std_logic;
  signal DRDY_M_processed : std_logic;
  signal DRDY_M_processed_follower : std_logic;

--Intermediate port mapping signals of the spi_commands entity. These are
--how I interact with that entity.
  signal    command_spi_signal      : std_logic_vector(command_width_bytes_g*8-1 downto 0);
  signal    address_spi_signal      : std_logic_vector(address_width_bytes_g*8-1 downto 0);
  signal    address_en_spi_signal   : std_logic;
  signal    data_length_spi_signal  : std_logic_vector(data_length_bit_width_g - 1 downto 0);
  signal    master_slave_data_spi_signal : std_logic_vector(7 downto 0);
  signal    master_slave_data_rdy_spi_signal :  std_logic;
  signal    master_slave_data_ack_spi_signal : std_logic;
  signal    master_slave_data_ack_spi_signal_follower : std_logic;
  signal    command_busy_spi_signal :   std_logic;
  signal    command_done_spi_signal :   std_logic;
  signal    command_done_spi_signal_follower :   std_logic;
  signal    slave_master_data_spi_signal :std_logic_vector(7 downto 0);
  signal    slave_master_data_ack_spi_signal :std_logic;


  signal startup_en : std_logic;
  signal startup_follower : std_logic;

  --Processed signals allow servicing the startup signal in.
  signal  startup_processed : std_logic;
  signal  startup_processed_follower : std_logic;
  --Startup complete indicate that main state machine can begin
  --looking for interrupts.
  signal  startup_complete : std_logic;


  --These signals
  signal miso_signal : std_logic;
  signal cs_n_signal : std_logic;

  --SPI Routing signals
  --'0' is XL_G, '1' is M
  signal SPI_SELECT_XL_G_M : std_logic;



--Byte counts related to transferring bytes.
  signal byte_count : unsigned (data_length_bit_width_g-1 downto 0);
  signal byte_number : unsigned (data_length_bit_width_g-1 downto 0);
  --Counts used to keep track of read bytes off MISO.
  signal byte_read_count  : unsigned (data_length_bit_width_g-1 downto 0);
  signal byte_read_number : unsigned (data_length_bit_width_g-1 downto 0);


  signal INT1_A_G_sync  : std_logic;
  signal INT2_A_G_sync  : std_logic;
  signal DRDY_M_sync  : std_logic;

  component spi_commands is
  generic(
    command_used_g        : std_logic := '1';
    address_used_g        : std_logic := '0';
    command_width_bytes_g : natural := 1;
    address_width_bytes_g : natural := 1;
    data_length_bit_width_g : natural := 10;
    cpol_cpha             : std_logic_vector(1 downto 0) := "00"
  );
	port(
    clk	            :in	std_logic;
    rst_n 	        :in	std_logic;
    command_in            : in  std_logic_vector(command_width_bytes_g*8-1 downto 0);
    address_in            : in  std_logic_vector(address_width_bytes_g*8-1 downto 0);
    address_en_in         : in  std_logic;
    data_length_in        : in  std_logic_vector(data_length_bit_width_g - 1 downto 0);
    master_slave_data_in  : in std_logic_vector(7 downto 0);
    master_slave_data_rdy_in  : in  std_logic;
    master_slave_data_ack_out :out  std_logic;
    command_busy_out      : out std_logic;
    command_done          : out std_logic;
    slave_master_data_out : out std_logic_vector(7 downto 0);
    slave_master_data_ack_out : out std_logic;
    miso 				:in	  std_logic;
    mosi 				:out  std_logic;
    sclk 				:out  std_logic;
    cs_n 				:out  std_logic
		);
  end component;

  --  System time from across clock domains.

  signal current_FPGA_time  : std_logic_vector (curtime_in'length-1
                                                downto 0) ;

  component CrossChipReceive is
    Generic (
      data_bits_g           : natural := 8
    ) ;
    Port (
      clk                   : in    std_logic ;
      data_latch_in         : in    std_logic ;
      data_valid_in         : in    std_logic ;
      valid_latch_in        : in    std_logic ;
      data_in               : in    std_logic_vector (data_bits_g-1
                                                      downto 0) ;
      data_out              : out   std_logic_vector (data_bits_g-1
                                                      downto 0) ;
      data_ready_out        : out   std_logic
    ) ;
  end component CrossChipReceive ;


begin


  --  System time from across clock domains.

  get_curtime : CrossChipReceive
    Generic Map (
      data_bits_g           => curtime_in'length
    )
    Port Map (
      clk                   => clk,
      data_latch_in         => curtime_latch_in,
      data_valid_in         => curtime_valid_in,
      valid_latch_in        => curtime_vlatch_in,
      data_in               => curtime_in,
      data_out              => current_FPGA_time
    ) ;


imu_initbuffer_address_std <= std_logic_vector(imu_initbuffer_address);
initbuffer_clk <= not clk;


spi_commands_slave_XL_G : spi_commands

  generic map (
  command_used_g        => command_used_g,
  address_used_g        => address_used_g,
  command_width_bytes_g => command_width_bytes_g,
  address_width_bytes_g => address_width_bytes_g,
  data_length_bit_width_g => data_length_bit_width_g,
  cpol_cpha            => "00"
  )
	port map(
    clk	            => clk,
    rst_n 	        => rst_n,

    command_in      => command_spi_signal,
    address_in      => address_spi_signal,
    address_en_in   => address_en_spi_signal,
    data_length_in  => data_length_spi_signal,

    master_slave_data_in      =>  master_slave_data_spi_signal,
    master_slave_data_rdy_in  =>  master_slave_data_rdy_spi_signal,
    master_slave_data_ack_out =>  master_slave_data_ack_spi_signal,
    command_busy_out          =>  command_busy_spi_signal,
    command_done              =>  command_done_spi_signal,
    slave_master_data_out     =>  slave_master_data_spi_signal,
    slave_master_data_ack_out =>  slave_master_data_ack_spi_signal,

    miso 				  => miso_signal,
    mosi 					=> mosi,
    sclk 					=> sclk,
    cs_n 					=> cs_n_signal

		);

--This memory holds the non-default registers for the IMU. These
--are set on startup. This memory is initialized with a mif file.
	altsyncram_component : altsyncram
	GENERIC MAP (
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "LSM9DS1_Register_Settings_Startup_Memory.mif",
		intended_device_family => "Cyclone V",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 256,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 8,
		width_a => 16,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => imu_initbuffer_address_std,
		clock0 => initbuffer_clk,
		data_a => imu_initbuffer_data,
		wren_a => imu_initbuffer_wr_en,
		rden_a => imu_initbuffer_rd_en,
		q_a => imu_initbuffer_q
	);


---------------------------------
--
--! @brief    Interact with the LSM9DS1 IMU. Make use of SPI abstractions.
--!
--! @details  Do the following things.
--!           Initialize the registers of the IMU which differ from default.
--!           Respond to XL, G, and M data rdy interrupts.
--!           Receive these data and push them out top of entity.
--!
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
---------------------------------



LSM9DS1_state_machine:  process (clk, rst_n)
begin
  if (rst_n = '0') then


  byte_count <= to_unsigned(0,byte_count'length);
  byte_number <= to_unsigned(0,byte_number'length);
  cur_imu_state <= IMU_STATE_WAIT;

  command_spi_signal  <= (others => '0');
  master_slave_data_spi_signal  <= (others => '0');
  address_en_spi_signal <= '0';
  data_length_spi_signal  <= (others => '0');
  master_slave_data_rdy_spi_signal <= '0';


  xl_g_init_number  <= (others => '0');
  m_init_number  <= (others => '0');

  accel_sample  <= (others => '0');
  accel_data_x  <= (others => '0');
  accel_data_y  <= (others => '0');
  accel_data_z  <= (others => '0');

  gyro_sample  <= (others => '0');
  gyro_data_x  <= (others => '0');
  gyro_data_y  <= (others => '0');
  gyro_data_z  <= (others => '0');

  mag_sample  <= (others => '0');
  mag_data_x  <= (others => '0');
  mag_data_y  <= (others => '0');
  mag_data_z  <= (others => '0');

byte_count <= to_unsigned(0,byte_count'length);
byte_number <= to_unsigned(0,byte_number'length);

byte_read_count <= to_unsigned(0,byte_count'length);
byte_read_number <= to_unsigned(0,byte_number'length);



DRDY_M_processed    <= '0';
accel_processed <= '0';
gyro_processed <= '0';
startup_processed <= '0';

imu_initbuffer_address  <= (others => '0');
startup_complete <= '0';


command_done_spi_signal_follower <= '0';



  elsif (clk'event and clk = '1') then

--Default signal states.
master_slave_data_rdy_spi_signal <= '0';

  if (startup_processed = '1' and startup_processed_follower = '1') then
    startup_processed <= '0';
  end if;


  if (gyro_processed = '1' and gyro_processed_follower = '1') then
    gyro_processed <= '0';
  end if;

  if (accel_processed = '1' and accel_processed_follower = '1') then
    accel_processed <= '0';
  end if;

  if (DRDY_M_processed = '1' and DRDY_M_processed_follower = '1') then
    DRDY_M_processed <= '0';
  end if;



    case cur_imu_state is

      when IMU_STATE_WAIT          =>


      if (startup_en = '1') then
        cur_imu_state  <=  IMU_STATE_INIT_FETCH_XL_G_NUM_SETUP;
      elsif (startup_complete = '1') then
        --INT1_A_G has been set to G data ready.
        if  (gyro_req = '1') then
          cur_imu_state  <=  IMU_STATE_FETCH_G_SETUP;
        --INT2_A_G has been set to XL data ready.
        elsif (accel_req = '1') then
          cur_imu_state  <=  IMU_STATE_FETCH_XL_SETUP;
        elsif (DRDY_M_req = '1') then
          cur_imu_state  <=  IMU_STATE_FETCH_M_SETUP;
        end if;
      end if;


    when IMU_STATE_INIT_FETCH_XL_G_NUM_SETUP =>

        imu_initbuffer_address <= unsigned(imu_initbuffer_xl_g_num_loc_c);
        cur_imu_state <= IMU_STATE_INIT_FETCH_XL_G_NUM;
        --Startup_processed moved here to allow enough time for startup_en
        --to go low before IMU_STATE_WAIT checks it again.
        startup_processed <= '1';

    when IMU_STATE_INIT_FETCH_XL_G_NUM =>

      byte_count <= to_unsigned(0,byte_count'length);
      byte_number <= resize(unsigned(imu_initbuffer_q),byte_number'length);

      --I only read 8 bits of data here from a 16 bit spot. I do this because
      --I use this number in addressing into a 256 spot ram and I do not need
      --bits 15 through 8.
      xl_g_init_number <= unsigned(imu_initbuffer_q(7 downto 0));
      cur_imu_state <= IMU_STATE_INIT_FETCH_XL_G;

      imu_initbuffer_address <= unsigned(imu_initbuffer_data_start_loc_c);

    when IMU_STATE_INIT_FETCH_XL_G =>


          if(byte_count = byte_number) then
            cur_imu_state <= IMU_STATE_INIT_FETCH_M_NUM_SETUP;
          else
            cur_imu_state <= IMU_STATE_INIT_WRITE_XL_G;
          end if;



    when IMU_STATE_INIT_WRITE_XL_G =>

      if (command_busy_spi_signal = '0') then
          command_spi_signal <= WR_EN_BIT & imu_initbuffer_q(14 downto 8);
          master_slave_data_spi_signal <= imu_initbuffer_q(7 downto 0);
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(IMU_REGISTER_SIZE_BYTES,data_length_spi_signal'length));
          imu_initbuffer_address <= imu_initbuffer_address + 1;
          master_slave_data_rdy_spi_signal <= '1';
          cur_imu_state <= IMU_STATE_INIT_WAIT_XL_G;
          byte_count <= byte_count + 1;

      end if;

       when IMU_STATE_INIT_WAIT_XL_G =>

      --Wait for a register to complete going out before continuing.
      --This is necessary for cs_n multiplexing.
      --This is necessary as no spi_command ack's come back for command only.
      --if (command_done_spi_signal_follower /= command_done_spi_signal) then
        --command_done_spi_signal_follower <= command_done_spi_signal;
        if(command_done_spi_signal = '1') then
          cur_imu_state <= IMU_STATE_INIT_FETCH_XL_G;
        end if;
     -- end if;


    when IMU_STATE_INIT_FETCH_M_NUM_SETUP =>

      imu_initbuffer_address <= unsigned(imu_initbuffer_m_num_loc_c);
      cur_imu_state <= IMU_STATE_INIT_FETCH_M_NUM;

    when IMU_STATE_INIT_FETCH_M_NUM =>
      byte_count <= to_unsigned(0,byte_count'length);
      byte_number <= resize(unsigned(imu_initbuffer_q),byte_number'length);

      m_init_number <= unsigned(imu_initbuffer_q(7 downto 0));
      cur_imu_state <= IMU_STATE_INIT_FETCH_M;
      --Start address is base address plus number of xl_g locations previously processed.
      imu_initbuffer_address <= unsigned(imu_initbuffer_data_start_loc_c) + xl_g_init_number ;

    when IMU_STATE_INIT_FETCH_M =>


          if(byte_count = byte_number) then
          --Don't service interrupts till we've set up the registers.
            startup_complete <= '1';
            cur_imu_state <= IMU_STATE_WAIT;
          else
            cur_imu_state <= IMU_STATE_INIT_WRITE_M;
          end if;


    when IMU_STATE_INIT_WRITE_M =>

      if (command_busy_spi_signal = '0') then
          command_spi_signal <= WR_EN_BIT & imu_initbuffer_q(14 downto 8);
          master_slave_data_spi_signal <= imu_initbuffer_q(7 downto 0);
          address_en_spi_signal <= '0';

          data_length_spi_signal <= std_logic_vector(to_unsigned(IMU_REGISTER_SIZE_BYTES,data_length_spi_signal'length));
          imu_initbuffer_address <= imu_initbuffer_address + 1;
          master_slave_data_rdy_spi_signal <= '1';

          byte_count <= byte_count + 1;
          cur_imu_state <= IMU_STATE_INIT_WAIT_M;
      end if;


    when IMU_STATE_INIT_WAIT_M =>

      --Wait for a register to complete going out before continuing.
      --This is necessary for cs_n multiplexing.
      --This is necessary as no spi_command ack's come back for command only.
       --if (command_done_spi_signal_follower /= command_done_spi_signal) then
          --command_done_spi_signal_follower <= command_done_spi_signal;
          if(command_done_spi_signal = '1') then
            cur_imu_state <= IMU_STATE_INIT_FETCH_M;
          end if;
        --end if;




    when IMU_STATE_FETCH_XL_SETUP =>

      byte_read_count <= to_unsigned(0,byte_count'length);
      byte_read_number <= to_unsigned(XL_G_M_register_count_c,byte_number'length);
      --Allows the first byte to go to the 0 address.
      --Address is incremented on first read byte.

        if (command_busy_spi_signal = '0') then
          command_spi_signal <= RD_EN_BIT & std_logic_vector(to_unsigned(XL_data_begin_addr,command_spi_signal'length - 1));
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(XL_G_M_register_count_c,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";

          master_slave_data_rdy_spi_signal <= '1';
          cur_imu_state <= IMU_STATE_FETCH_XL;

        end if;

    --After pushing a command set and first data byte to the SPI_COMMANDS entity, we then wait for
    --6 associated MISO bytes to come back to us. We must remember that the slave_master_data_ack_spi_signal
    --only goes high on the data/payload portion of the SPI stream. No ack's come back associated with command
    --or address bytes sent out the SPI bus. We can thus just count 6 ack's and know that we grabbed the 6 XYZ bytes.
    --This is what is happening here.
    --This assumes that the address is auto incrementing.


    when IMU_STATE_FETCH_XL =>

      if(byte_read_count = byte_read_number) then
        cur_imu_state <= IMU_STATE_FETCH_XL_DONE;
        accel_processed <= '1';
      elsif (slave_master_data_ack_spi_signal = '1') then
      --Big endian/Little Endian (Configurable with register 22h on the XL/G.
      --Little endian.
        accel_sample <= slave_master_data_spi_signal & accel_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 8);
        --Big endian.
        --accel_sample <= accel_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1-8 downto 0) & slave_master_data_spi_signal;
        byte_read_count <= byte_read_count + 1;
      end if;

      if (master_slave_data_ack_spi_signal_follower /= master_slave_data_ack_spi_signal) then
      master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
              --Push x00 to the spi slave to receive the READ bytes back.
        if(master_slave_data_ack_spi_signal = '1') then
          master_slave_data_spi_signal <= x"00";
          master_slave_data_rdy_spi_signal <= '1';
        end if;
      else
      master_slave_data_rdy_spi_signal <= '0';
      end if;


    --Assume little endian input for IMU_STATE_FETCH_XL. Generates Big endian words.
    --Puts big endian on the xyz ports.
    when IMU_STATE_FETCH_XL_DONE =>
    accel_data_z <=   accel_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 2*IMU_AXIS_WORD_LENGTH_BYTES*8);
    accel_data_y <=   accel_sample(2*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 1*IMU_AXIS_WORD_LENGTH_BYTES*8);
    accel_data_x <=   accel_sample(1*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);
    cur_imu_state <=  IMU_STATE_WAIT;



    when IMU_STATE_FETCH_G_SETUP =>

      byte_read_count <= to_unsigned(0,byte_count'length);
      byte_read_number <= to_unsigned(XL_G_M_register_count_c,byte_number'length);

        if (command_busy_spi_signal = '0') then
          command_spi_signal <= RD_EN_BIT & std_logic_vector(to_unsigned(G_data_begin_addr,command_spi_signal'length - 1));
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(XL_G_M_register_count_c,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";

          master_slave_data_rdy_spi_signal <= '1';
          cur_imu_state <= IMU_STATE_FETCH_G;

        end if;


    when IMU_STATE_FETCH_G =>

    if(byte_read_count = byte_read_number) then
        cur_imu_state <= IMU_STATE_FETCH_G_DONE;
        gyro_processed <= '1';
      elsif (slave_master_data_ack_spi_signal = '1') then
       --Big endian/Little Endian (Configurable with register 22h on the XL/G.
      --Little endian.
       gyro_sample <= slave_master_data_spi_signal & gyro_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 8);
       --Big endian.
        --gyro_sample <= gyro_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1-8 downto 0) & slave_master_data_spi_signal;
        byte_read_count <= byte_read_count + 1;
      end if;

      if (master_slave_data_ack_spi_signal_follower /= master_slave_data_ack_spi_signal) then
      master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
              --Push x00 to the spi slave to receive the READ bytes back.
        if(master_slave_data_ack_spi_signal = '1') then
          master_slave_data_spi_signal <= x"00";
          master_slave_data_rdy_spi_signal <= '1';
        end if;
      else
      master_slave_data_rdy_spi_signal <= '0';
      end if;

      --Assume little endian input for IMU_STATE_FETCH_G. Generates Big endian words.
    when IMU_STATE_FETCH_G_DONE =>
    gyro_data_z <=   gyro_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 2*IMU_AXIS_WORD_LENGTH_BYTES*8);
    gyro_data_y <=   gyro_sample(2*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 1*IMU_AXIS_WORD_LENGTH_BYTES*8);
    gyro_data_x <=   gyro_sample(1*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);
    cur_imu_state <=  IMU_STATE_WAIT;




    when IMU_STATE_FETCH_M_SETUP =>

      byte_read_count <= to_unsigned(0,byte_count'length);
      byte_read_number <= to_unsigned(XL_G_M_register_count_c,byte_number'length);

        if (command_busy_spi_signal = '0') then
          command_spi_signal <= RD_EN_BIT & MS_AUTOINCREMENT_BIT & std_logic_vector(to_unsigned(M_data_begin_addr,command_spi_signal'length - 2));
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(XL_G_M_register_count_c,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";

          master_slave_data_rdy_spi_signal <= '1';
          cur_imu_state <= IMU_STATE_FETCH_M;

        end if;

    when IMU_STATE_FETCH_M =>

       if(byte_read_count = byte_read_number) then
        cur_imu_state <= IMU_STATE_FETCH_M_DONE;
        DRDY_M_processed <= '1';
      elsif (slave_master_data_ack_spi_signal = '1') then

      --Big endian/Little Endian (Configurable with register 22h on the XL/G.
      --Little endian.
        mag_sample <= slave_master_data_spi_signal & mag_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 8) ;
       --Big endian.
       --mag_sample <= mag_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1-8 downto 0) & slave_master_data_spi_signal;
        byte_read_count <= byte_read_count + 1;
      end if;

      if (master_slave_data_ack_spi_signal_follower /= master_slave_data_ack_spi_signal) then
      master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
              --Push x00 to the spi slave to receive the READ bytes back.
        if(master_slave_data_ack_spi_signal = '1') then
          master_slave_data_spi_signal <= x"00";
          master_slave_data_rdy_spi_signal <= '1';
        end if;
      else
      master_slave_data_rdy_spi_signal <= '0';
      end if;

    when IMU_STATE_FETCH_M_DONE =>
    mag_data_z <=   mag_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 2*IMU_AXIS_WORD_LENGTH_BYTES*8);
    mag_data_y <=   mag_sample(2*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 1*IMU_AXIS_WORD_LENGTH_BYTES*8);
    mag_data_x <=   mag_sample(1*IMU_AXIS_WORD_LENGTH_BYTES*8-1 downto 0);
    cur_imu_state <=  IMU_STATE_WAIT;



      end case ;
  end if ;
end process LSM9DS1_state_machine ;




---------------------------------
--
--! @brief    The output logic for the cur_imu_state state machine.
--! @details  Signals associated with certain states are set/deset here.
--!           Signals of importance include rd_en on the 2port memory
--!           and the SPI one to many mux select bit.


--! @param    clk       Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--!
--!
---------------------------------

imu_machine_output:  process (cur_imu_state)
begin

imu_initbuffer_rd_en <= '0';

gyro_data_rdy <= '0';
accel_data_rdy <= '0';
mag_data_rdy <= '0';

imu_initbuffer_wr_en <= '0';

--Set default bus to XL_G.
SPI_SELECT_XL_G_M <= '0';

case cur_imu_state is


    when IMU_STATE_WAIT =>

    when IMU_STATE_INIT_FETCH_XL_G_NUM_SETUP  =>
    imu_initbuffer_rd_en <= '1';
    when IMU_STATE_INIT_FETCH_XL_G_NUM  =>
    imu_initbuffer_rd_en <= '1';

    when IMU_STATE_INIT_FETCH_M_NUM_SETUP  =>
    imu_initbuffer_rd_en <= '1';
    when IMU_STATE_INIT_FETCH_M_NUM  =>
    imu_initbuffer_rd_en <= '1';

    when IMU_STATE_INIT_FETCH_XL_G  =>
    imu_initbuffer_rd_en <= '1';
    when IMU_STATE_INIT_WRITE_XL_G  =>
    imu_initbuffer_rd_en <= '1';
    SPI_SELECT_XL_G_M <= '0';
    when IMU_STATE_INIT_WAIT_XL_G  =>
    SPI_SELECT_XL_G_M <= '0';

    when IMU_STATE_INIT_FETCH_M  =>
    imu_initbuffer_rd_en <= '1';
    when IMU_STATE_INIT_WRITE_M  =>
    imu_initbuffer_rd_en <= '1';
    SPI_SELECT_XL_G_M <= '1';
    when IMU_STATE_INIT_WAIT_M  =>
    SPI_SELECT_XL_G_M <= '1';




    when IMU_STATE_FETCH_XL_SETUP  =>
    SPI_SELECT_XL_G_M <= '0';
    when IMU_STATE_FETCH_XL  =>
    SPI_SELECT_XL_G_M <= '0';
    when IMU_STATE_FETCH_XL_DONE  =>
    accel_data_rdy <= '1';


    when IMU_STATE_FETCH_G_SETUP  =>
    SPI_SELECT_XL_G_M <= '0';
    when IMU_STATE_FETCH_G  =>
    SPI_SELECT_XL_G_M <= '0';
    when IMU_STATE_FETCH_G_DONE  =>
    gyro_data_rdy <= '1';


    when IMU_STATE_FETCH_M_SETUP  =>
    SPI_SELECT_XL_G_M <= '1';
    when IMU_STATE_FETCH_M  =>
    SPI_SELECT_XL_G_M <= '1';
    when IMU_STATE_FETCH_M_DONE =>
    mag_data_rdy <= '1';




end case;



end process imu_machine_output ;


---------------------------------
--!
--! @brief      data_rdy_catch
--!
--! @details    Catch the data_rdy_interrupts coming from the IMU.
--!             Log the fpga_time immediately.
--!             Then signal state machine to read the appropriate data from IMU
--!             over SPI.
--!
--!
--! @param    clk       Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--!
---------------------------------

data_rdy_catch: process (clk, rst_n)
begin
  if rst_n = '0' then

DRDY_M_req <= '0';
gyro_req <= '0';
accel_req <= '0';


startup_processed_follower <= '0';

INT1_A_G_follower <= '0';
INT2_A_G_follower <= '0';
DRDY_M_follower <= '0';

startup_en <= '0';


gyro_processed_follower <= '0';
accel_processed_follower <= '0';
DRDY_M_processed_follower   <= '0';



INT1_A_G_sync   <= '0';
INT2_A_G_sync   <= '0';
DRDY_M_sync     <= '0';





  elsif clk'event and clk = '1' then


  --Synchronize asynch interrupts.


INT1_A_G_sync   <= INT1_A_G;
INT2_A_G_sync   <= INT2_A_G;
DRDY_M_sync     <= DRDY_M;


    if (startup_follower /= startup) then
      startup_follower <= startup;

      if (startup = '1') then
      startup_en <= '1';
      end if;

    elsif(startup_processed_follower /= startup_processed) then
     startup_processed_follower <= startup_processed ;
      if (startup_processed = '1') then
          startup_en          <= '0' ;
      end if ;
    end if;


    --DRDY_M is always associated with magnetometer data.

    if (DRDY_M_follower /= DRDY_M_sync) then
      DRDY_M_follower <= DRDY_M_sync;
      if (DRDY_M_sync = '1') then
        mag_fpga_time <= current_fpga_time;
        DRDY_M_req <= '1';
      end if;
    elsif (DRDY_M_processed_follower /= DRDY_M_processed) then
      DRDY_M_processed_follower <= DRDY_M_processed;
        if (DRDY_M_processed = '1') then
          DRDY_M_req <= '0';
        end if;
    end if;

    --This assumes that data_rdy on INT1_A_G_follower has been programmed
    --to be gyro data rdy. Please check associated matlab startup register
    --definition scripts and the documentation.

    if (INT1_A_G_follower /= INT1_A_G_sync) then
      INT1_A_G_follower <= INT1_A_G_sync;
      if (INT1_A_G_sync = '1') then
        gyro_fpga_time <= current_fpga_time;
        gyro_req <= '1';
      end if;
    elsif (gyro_processed_follower /= gyro_processed) then
      gyro_processed_follower <= gyro_processed;
        if (gyro_processed = '1') then
          gyro_req <= '0';
        end if;
    end if;

    --This assumes that data_rdy on INT2_A_G_follower has been programmed
    --to be accel data rdy. Please check associated matlab startup register
    --definition scripts and the documentation.
    if (INT2_A_G_follower /= INT2_A_G_sync) then
      INT2_A_G_follower <= INT2_A_G_sync;
      if (INT2_A_G_sync = '1') then
        accel_fpga_time <= current_fpga_time;
        accel_req <= '1';
      end if;
    elsif (accel_processed_follower /= accel_processed) then
      accel_processed_follower <= accel_processed;
        if (accel_processed = '1') then
          accel_req <= '0';
        end if;
    end if;


  end if ;
end process data_rdy_catch ;

--When SPI_SELECT_XL_G_M is '0', set up SPI bus to XL_G device.
--When SPI_SELECT_XL_G_M is '1', set up SPI bus to M device.

with SPI_SELECT_XL_G_M select
			cs_M  <=	cs_n_signal when '1',
                '1' when others;

with SPI_SELECT_XL_G_M select
			cs_XL_G  <=	cs_n_signal when '0',
                '1' when others;


with SPI_SELECT_XL_G_M select
			miso_signal  <=	miso_M when '1',
						miso_XL_G when others;




end behavior ;