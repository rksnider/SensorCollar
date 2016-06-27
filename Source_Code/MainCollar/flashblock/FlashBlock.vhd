
-- @file       flashblock.vhd
-- @brief      Flashblock is the segment assembler for the collar project
-- @details
-- @author     Chris Casebeer
-- @date       10_28_2014
-- @copyright
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
--  Chris Casebeer
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  christopher.casebee1@msu.montana.edu
--
--


library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.


--A dual port ram is used.
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;
LIBRARY WORK ;
LIBRARY GENERAL ;
USE GENERAL.UTILITIES_PKG.ALL;          --  Use General Purpose Libraries
USE GENERAL.GPS_Clock_pkg.ALL;          --  Use GPS Clock information.
USE GENERAL.gps_message_ctl_pkg.ALL;
USE GENERAL.msg_ubx_tim_tm2_pkg.ALL;
USE GENERAL.msg_ubx_nav_sol_pkg.ALL;
USE GENERAL.compile_start_time_pkg.ALL;
USE GENERAL.magmem_buffer_def_pkg.all;    --Magnetic Memory Buffer Size and Locations.
USE GENERAL.PC_StatusControl_pkg.All ;       
USE GENERAL.txrx_p_buffer_def_pkg.all;



--
--! @brief      Assemble blocks of sensor data. Send to buffer.
--! @details
--! @param    fpga_time_length_bytes_g  Length of FPGA TIME COUNTER IN BYTES
--! @param    time_bytes_g            Bytes of current time.
--! @param    event_bytes_g           Bytes of event counts.
--! @param    rtc_time_bytes_g        Real Time Clock Word Length Bytes
--! @param    num_mics_active_g       Number of Microphones Current Active.
--! @param    counter_data_size_g     Event counter system data size.
--! @param    counter_address_size_g  Event counter system address size.
--! @param    counters_g              Event counter number of events defined.
--!
--! @param    gps_buffer_bytes_g            Size of GPS core buffer
--! @param    imu_axis_word_length_bytes_g  One IMU axis length bytes
--! @param    sdram_input_buffer_bytes_g    Size of input buffer to SDRAM
--!                                         Controller
--!
--! @param    audio_word_bytes_g  Size of an audio word in bytes.

--! @param    status_interval_ns_g Flashblock will in addition to log_status action, 
--!                               log a status packet so often at this inveral in seconds.
--! @param    wireless_update_interval_ms_g Interval at which to update the 
--!                                         wireless packet in dual port. 
--!
--! @param    clock_sys           System clock that drives the fastest ops.
--! @param    rst_n               Reset to initial conditions.
--! @param    clk_enable          Clock enable. Used to power on the machine
--!                               for now.
--! @param    log_status          Log Status. Will push a status packet.
--! @param    curtime_in          FPGA time from the FPGA time component
--! @param    curtime_latch_in    Latch curtime across clock domains.
--! @param    curtime_valid_in    Latched curtime is valid when set.
--! @param    curtime_vlatch_in   Latch curtime when valid not set.
--! @param    log_events          Log Events Flag
--!
--!
--! @param    gyro_data_rdy       xyz words from IMU ready
--! @param    accel_data_rdy      xyz words from IMU ready
--! @param    mag_data_rdy        xyz words from IMU ready
--! @param    temp_data_rdy       temp word from IMU ready
--!
--!
--! @param    gyro_data_x         x word from IMU gyro (Big endian)
--! @param    gyro_data_y         y word from IMU gyro (Big endian)
--! @param    gyro_data_z         z word from IMU gyro (Big endian)
--!
--! @param    accel_data_x        x word from IMU gyro (Big endian)
--! @param    accel_data_y        y word from IMU gyro (Big endian)
--! @param    accel_data_z        z word from IMU gyro (Big endian)
--!
--! @param    mag_data_x          x word from IMU gyro (Big endian)
--! @param    mag_data_y          y word from IMU gyro (Big endian)
--! @param    mag_data_z          z word from IMU gyro (Big endian)
--!
--! @param    temp_data           Temp word from the IMU.
--!
--! @param    audio_data_rdy      Audio word rdy
--! @param    audio_data          Audo word data (Big endian)
--!
--!
--! @param    flashblock_inbuf_data   Data input to the sdram input buffer
--! @param    flashblock_inbuf_wr_en  Write enable to the sdram input buffer
--! @param    flashblock_inbuf_clk    Clk to the sdram input buffer
--! @param    flashblock_inbuf_addr   Address bus to the sdram input buffer
--!
--! @param    flashblock_gpsbuf_addr  Address into GPS core memory
--! @param    flashblock_gpsbuf_rd_en Read Enable into GPS core memory
--! @param    flashblock_gpsbuf_clk
--! @param    gpsbuf_flashblock_data  Data from gps core memory.
--!
--! @param    gps_req_out             Request access to GPS memory.
--!
--! @param    gps_rec_in              Access granted to GPS memory.
--!
--! @param    posbank                 Position GPS memory change flag.
--!
--! @param    tmbank                  Time mark GPS memory change flag.
--!
--! @param    gyro_fpga_time          FPGA time associated with a gyro sample.
--! @param    accel_fpga_time         FPGA time associated with a accel sample.
--! @param    mag_fpga_time           FPGA time associated with a mag sample.
--! @param    temp_fpga_time          FPGA time associated with a temp sample.
--!
--! @param    rtc_time_in             Real Time Clock time word input into
--!                                   flashblock.
--!
--! @param    flashblock_counter_wr_rd_addr   Read and write address into
--!                                           the counter component.
--! @param    flashblock_counter_rd_en  Read enable into the counter
--!                                     component.
--! @param    flashblock_counter_wr_en  Write enable into the counter
--!                                     component.
--! @param    flashblock_counter_clk
--! @param    flashblock_counter_lock   Write enable into the counter
--!                                     component.
--! @param    flashblock_counter_data   Data into the counter component.
--! @param    counter_flashblock_data   Data from the counter component.
--!
--! @param    flashblock_sdram_2k_accumulated Signal 2k accumulated flag
--!                                           relayed to the
--!                                           sdram_controller
--!
--! @param    mem_req_a_out           Request the magnetic memory buffer
--! @param    mem_rec_a_in            Receive the magnetic memory buffer

--! @param    fb_magram_clk_a_out     Clk to the magnetic memory buffer.
--! @param    fb_magram_wr_en_a_out   Magmem wr_en
--! @param    fb_magram_rd_en_a_out   Magmem rd_en
--! @param    fb_magram_address_a_out Side A magnetic memory buffer address
--! @param    fb_magram_data_a_out    Data to magnetic memory buffer side A
--! @param    magram_fb_q_a_in        Data from magnetic memory buffer
--!                                   side A
--!
--!
--!
--! @param    force_wr_en       Force Write Enable to sdcram controller.
--!                             Flush physical memory.
--! @param    sdram_empty       When physical ram is empty sdram controller
--!                             signals sdram_empty.
--!
--! @param    crit_event        critical event signal.
--! @param    blocks_past_crit  Signal sent to sd_loader to allow
--!                             determining when when critical block has
--!                             been written.


--! txrx_req_a_out              Request the txrx double buffer.
--!  txrx_rec_a_in              Received the txrx double buffer.
    
--!  txrx_bank_out              The currently updated bank. Use this one.
--!                             Either append or use is_set() from utilities. 
    
--!  fb_txrx_clk_a_out          txrx buffer clk 
--!  fb_txrx_wr_en_a_out        txrx buffer wr_en
--!  fb_txrx_rd_en_a_out        txrx buffer rd_en
--!  fb_txrx_address_a_out      txrx buffer address 
--!  fb_txrx_data_a_out         txrx buffer data to 
    
    
    
--!  sdxc_serial_in            Sdxc serial number formed into wireless packet.
--!  sdxc_block_in             Last physical block location written to sd card. 
--!                            Formed into wireless packet.
    
--!  pc_controlreg_in          Control register put into wireless packet.

--!  voltage_mv_in            Battery Voltage assembled into wireless packet.
--!  rem_cap_mah_in           Battery capcity assembled into wireless packet.
--!  inst_cur_ma_in           Battery current usage assembled into wireless packet.


-- What does this component do?

-- This component is responsible for assembling segments from all the sensor
-- inputs into the system. The data structures assembled are described in
-- associated documention (SD_Card_Structure_-_v1.x.pdf)

--Two primary state machines direct flow. One state machine send_block_item
--is primarily responsible for pushing data out of the component and into the
--addressed buffer. Different states push different types of data. State transition order
--dictate the order in which the data is pushed out. Data structure is again
--noted in associated documentation.

--The send_item state machine is a smaller state machine. It is more involved
--with prioritizing incoming interrupts and jumped to the correct place in
--send_block_item.

--A large process audio_sample is concerned with catching the incoming data
--and putting it into circular buffers. Send_block_item state machine then
--reads from theses buffers to assembled the sensor segments. Data is read
--from circular buffer until read pointer equals write pointer.



-- How does force write and cricitcal block event work?
-- Force write is enabled in a critical event. This will empty all of the physical
-- ram. This is done by the sdram controller. However this takes some time. Blocks
-- will continue to form while sdram is emptying and being written to the sd card.
-- Thus the number blocks which form after the critical event was received must be
-- kept track of. One component who must know this information is the sdcard_loader.

-- Force write is kept on until the sdcard_controller replies with an empty flag.
-- At this point the entirety of the input buffer (to a 2k boundary) and
-- the output buffer will have been completely emptied to the sd_loader.
-- It is as this point that flashblock should signal sd_loader of the blocks
-- past critical block.

--IMU words are presented by the IMU controller in big endian format.
--They are written out of the flashblock starting high byte of x, low byte of x,
--

--Words are taken in Big endian. (IMU and Audio)
--These are then written out in little endian order inside the data segments.
--They then end up little endian on the microSD card.


--TODO:
--Implement overflow detection on the circular buffers.
--Fix the address on the event counter system (only one address line is
--available.
--Remove the direct write system from flashblock, this system has been
--removed.




entity FlashBlock is

  Generic (
    sysclk_freq_g             : natural := 36e5;
    fpga_time_length_bytes_g  : natural := 9;
    time_bytes_g              : natural := 9 ;
    event_bytes_g             : natural := 2 ;

    rtc_time_bytes_g          : natural := 4;
    num_mics_active_g         : natural := 2;

    counter_data_size_g       : natural     := 8 ;
    counter_address_size_g    : natural     := 9 ;
    counters_g                : natural     := 10 ;

    gps_buffer_bytes_g            : natural := 512;
    imu_axis_word_length_bytes_g  : natural := 2;
    sdram_input_buffer_bytes_g    : natural := 4096;
    audio_word_bytes_g            : natural := 2;
    
    status_update_interval_ms     : natural := 1000;
    wireless_update_interval_ms_g   : natural := 10000
  ) ;
  Port (
    clock_sys             : in    std_logic ;
    rst_n                 : in    std_logic ;
    clk_enable            : in    std_logic;
    startup_in            : in    std_logic;
    startup_done_out      : out   std_logic;
    log_status            : in    std_logic ;

    curtime_in            : in    std_logic_vector
                                      (gps_time_bytes_c*8-1 downto 0) ;
    curtime_latch_in      : in    std_logic ;
    curtime_valid_in      : in    std_logic ;
    curtime_vlatch_in     : in    std_logic ;
    log_events            : in    std_logic;

    gyro_data_rdy   : in    std_logic;
    accel_data_rdy  : in    std_logic;
    mag_data_rdy    : in    std_logic;
    temp_data_rdy   : in    std_logic;


    gyro_data_x     :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);
    gyro_data_y     :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);
    gyro_data_z     :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);

    accel_data_x    :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);
    accel_data_y    :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);
    accel_data_z    :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);

    mag_data_x      :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);
    mag_data_y      :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);
    mag_data_z      :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);

    temp_data       :in     std_logic_vector(
                            imu_axis_word_length_bytes_g*8 - 1 downto 0);

    audio_data_rdy          : in std_logic;
    audio_data              : in std_logic_vector(
                              num_mics_active_g*audio_word_bytes_g*8  - 1 downto 0);

    --Input Multi Buffer Interface
    flashblock_inbuf_data       : out    std_logic_vector(7 downto 0);
    flashblock_inbuf_wr_en      : out    std_logic;
    flashblock_inbuf_clk        : out    std_logic;
    --In the case of a 2*2k multi buffer, upper
    --3 bits will index through 0-15 (512 byte blocks)
    --Only increment on the entire address is needed.

    flashblock_inbuf_addr       : out   std_logic_vector(
                                        natural(trunc(log2(real(
                                        sdram_input_buffer_bytes_g-1))))
                                        downto 0);

    flashblock_gpsbuf_addr      : out   std_logic_vector(
                                        natural(trunc(log2(real(
                                        gps_buffer_bytes_g-1))))
                                        downto 0);
    flashblock_gpsbuf_rd_en     : out   std_logic;
    flashblock_gpsbuf_clk       : out   std_logic;
    gpsbuf_flashblock_data      : in    std_logic_vector(7 downto 0);


    gps_req_out       : out   std_logic;
    gps_rec_in        : in    std_logic;

    posbank     :in std_logic;
    tmbank      :in std_logic;

    gyro_fpga_time  :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    accel_fpga_time :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    mag_fpga_time :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    temp_fpga_time :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);

    rtc_time_in   : in std_logic_vector (rtc_time_bytes_g*8-1 downto 0);

    flashblock_counter_rd_wr_addr  : out   std_logic_vector(
                                        counter_address_size_g-1 downto 0);
    -- flashblock_counter_wr_addr  : out   std_logic_vector(
                                        -- counter_address_size_g-1 downto 0);
    flashblock_counter_rd_en    : out   std_logic;
    flashblock_counter_wr_en    : out   std_logic;
    flashblock_counter_clk      : out   std_logic;
    flashblock_counter_lock     : out   std_logic;
    flashblock_counter_data     : out   std_logic_vector(
                                        counter_data_size_g-1 downto 0);
    counter_flashblock_data     : in    std_logic_vector(
                                        counter_data_size_g-1 downto 0);

    flashblock_sdram_2k_accumulated : out  std_logic;

    mem_req_a_out           : out std_logic;
    mem_rec_a_in            : in std_logic;

    fb_magram_clk_a_out     : out std_logic;
    fb_magram_wr_en_a_out   : out std_logic;
    fb_magram_rd_en_a_out   : out std_logic;
    fb_magram_address_a_out : out std_logic_vector(natural(trunc(log2(real(
                                (magmem_buffer_bytes/magmem_buffer_num)-1)))) downto 0);
    fb_magram_data_a_out    : out std_logic_vector(7 downto 0);
    magram_fb_q_a_in        : in std_logic_vector(7 downto 0);

    -- --SDRAM Controller Interfacing
    -- dw_en : out  std_logic;
    -- dw_amt_valid  : out  std_logic;
    -- dw_amt_bytes  : out  std_logic_vector(natural(
                          -- trunc(log2(real(
                          -- sdram_input_buffer_bytes_g-1)))) downto 0);

    force_wr_en             : out  std_logic;
    sdram_empty_in          : in  std_logic;

    crit_event              : in  std_logic;
    blocks_past_crit : out std_logic_vector(7 downto 0);
    
    
    txrx_req_a_out           : out std_logic;  
    txrx_rec_a_in            : in std_logic;  
    
    txrx_bank_out            : out std_logic;  
    
    fb_txrx_clk_a_out     : out std_logic;
    fb_txrx_wr_en_a_out   : out std_logic;  
    fb_txrx_rd_en_a_out   : out std_logic;  
    fb_txrx_address_a_out : out std_logic_vector(natural(trunc(log2(real(txrx_double_buffer_size-1)))) downto 0);
    fb_txrx_data_a_out    : out std_logic_vector(7 downto 0);
    
    
    
    sdxc_serial_in            : in   std_logic_vector(31 downto 0);
    sdxc_block_in             : in   std_logic_vector(31 downto 0);
    
    pc_controlreg_in          : in   std_logic_vector (ControlSignalsCnt_c-1
                                                    downto 0);

    voltage_mv_in            : in   std_logic_vector (15 downto 0);
    rem_cap_mah_in           : in   std_logic_vector (15 downto 0);
    inst_cur_ma_in           : in   std_logic_vector (15 downto 0)


) ;

end entity FlashBlock ;


-- Flash blocks are written as 512 bytes with no continuation of data between
-- blocks.

-- Each flash block starts with a 4 byte sequence number between $00000001
-- and $FFFFFFFE. This is the address width of the microSD card
-- The bit patterns $00000000 and $FFFFFFFF are not used as
-- either can be used to fill unwritten blocks when the device is formatted.
-- Thus a valid sequence number indicates that the block has been written.
--
-- Blocks are written sequentially.  No blocks will normally be written after
-- an unwritten block.  (This latter situation may occur if a write fails
-- leaving a possibly unusable block in an unwritten state.)
--
-- The data in each block is written in segments.  At the end of each
-- segment is the segment trailer which identifies the type of segment that
-- precedes it.  Segment trailers always contain the length of the segment
-- (excluding the length of the segment trailer itself).  Putting them at
-- the end of the segments allows segments to be written as their data
-- accumulates rather than requiring the data to be buffered so that the
-- length can be determined and written before the data is.  The end of
-- each block (bytes 510 and 511) will always be a segment trailer.  If no
-- valid trailer is found here it indicates that the block is invalid and
-- must be ignored.

-- Documentation of the flashblock  segment layout is documented
-- in SD_Card_Structure_-_v1.x.doc.





--The concept of a critical block number flush is as follows.
--The flashblock will need to fill the current 2k buffer with padding.
--Flashblock needs to signal sdram_controller to flush_wr_en.
--Upon empty the output buffer/physical ram/and input buffer will all
--have been flushed. At empty, the output buffer has been read entirely
--into the sdloader buffers.

architecture behavior of FlashBlock is

  --  Block size in bytes.

  constant BLOCK_SIZE         : natural := 512 ;

  --  Segment trailer size in bytes for all segment trailers.

  constant SEG_TRAILER_SIZE   : natural := 2 ;

  -- Block Segment IDs.

  constant BLOCK_SEG_UNUSED   : std_logic_vector (7 downto 0) := x"01";

  constant BLOCK_SEG_STATUS   : std_logic_vector (7 downto 0) := x"02";

  constant BLOCK_SEG_GPS_TIME_MARK   : std_logic_vector (7 downto 0) := x"03";

  constant BLOCK_SEG_GPS_POSITION   : std_logic_vector (7 downto 0) := x"04";

  constant BLOCK_SEG_IMU_GYRO       : std_logic_vector (7 downto 0) := x"05";
  constant BLOCK_SEG_IMU_ACCEL      : std_logic_vector (7 downto 0) := x"06";
  constant BLOCK_SEG_IMU_MAG        : std_logic_vector (7 downto 0) := x"07";
  constant BLOCK_SEG_IMU_TEMP       : std_logic_vector (7 downto 0) := x"0A";

  constant BLOCK_SEG_EVENT          : std_logic_vector (7 downto 0) := x"0B";
  constant BLOCK_SEG_SHUTDOWN       : std_logic_vector (7 downto 0) := x"0C";

  constant BLOCK_SEG_AUDIO    : std_logic_vector (7 downto 0) := x"08" ;

  -- Sequence number of the current block.

  constant BLOCK_SEQNO_BYTES  : natural := 4 ;

  signal block_seqno          : unsigned (BLOCK_SEQNO_BYTES*8-1 downto 0) ;

  -- Padding control.

  --No longer needed if padding segment is always added to block.
  --constant PAD_SEG_MIN_SIZE   : natural := 1 + SEG_TRAILER_SIZE ;
  constant PAD_SEG_MIN_SIZE   : natural := SEG_TRAILER_SIZE;

  constant PAD_SEG_MAX_LENGTH : natural := 255 ;

  constant PADDING_BYTE       : std_logic_vector (7 downto 0) := (others => '0') ;

  signal block_padding_length : unsigned (7 downto 0) ;



  -- System Status Version, current time, event counts,
  -- and tens of microseconds between audio samples.

  constant STATUS_VER_BYTES     : natural := 2 ;
  constant STATUS_AUD_BYTES     : natural := 2 ;

  constant STATUS_COMPILE_BYTES : natural := 4;
  constant STATUS_COMMIT_BYTES : natural := 4;

  constant NUM_ACTIVE_MICS_BYTES  : natural := 1;
  constant DEVICES_ON_VECTOR_BYTES : natural := 2;
  constant BATTERY_STATUS_BYTES : natural := 2;
  constant OPERATING_STATE_BYTES : natural := 2;




-- constant STATUS_VERSION_NO    : std_logic_vector (
                                  --STATUS_VER_BYTES*8-1 downto 0)
                                  -- := x"0001" ;

--Each IMU sample segment is 1 sample long followed by the trailer.

constant IMU_GYRO_SEG_BYTES     : natural :=
          3*imu_axis_word_length_bytes_g  ;

constant IMU_ACCEL_SEG_BYTES     : natural :=
          3*imu_axis_word_length_bytes_g  ;

constant IMU_MAG_SEG_BYTES     : natural :=
          3*imu_axis_word_length_bytes_g  ;

constant IMU_TEMP_SEG_BYTES     : natural :=
          imu_axis_word_length_bytes_g  ;



constant SEG_LEN_GYRO     : unsigned (7 downto 0) :=
        TO_UNSIGNED (IMU_GYRO_SEG_BYTES, 8) ;

constant SEG_LEN_ACCEL     : unsigned (7 downto 0) :=
        TO_UNSIGNED (IMU_ACCEL_SEG_BYTES, 8) ;

constant SEG_LEN_MAG     : unsigned (7 downto 0) :=
        TO_UNSIGNED (IMU_MAG_SEG_BYTES, 8) ;

constant SEG_LEN_TEMP     : unsigned (7 downto 0) :=
        TO_UNSIGNED (IMU_TEMP_SEG_BYTES, 8) ;




constant GPS_NAV_SOL_BYTES     : natural :=
          gps_time_bytes_c + msg_ubx_nav_sol_ramused_c;

constant SEG_LEN_GPS_NAV_SOL      : unsigned (7 downto 0) :=
        TO_UNSIGNED (GPS_NAV_SOL_BYTES, 8) ;

constant GPS_TIM_TM2_BYTES     : natural :=
          gps_time_bytes_c + msg_ubx_tim_tm2_ramused_c;

constant SEG_LEN_GPS_TIM_TM2      : unsigned (7 downto 0) :=
        TO_UNSIGNED (GPS_TIM_TM2_BYTES, 8) ;



constant STATUS_SEG_BYTES     : natural :=
          STATUS_COMPILE_BYTES + STATUS_COMMIT_BYTES + 6*gps_time_bytes_c
          + rtc_time_bytes_g + NUM_ACTIVE_MICS_BYTES ;

constant BLOCK_LEN_STATUS     : unsigned (7 downto 0) :=
        TO_UNSIGNED (STATUS_SEG_BYTES, 8) ;



constant  SHUTDOWN_REASON_BYTES : natural := 1;

constant SHUTDOWN_SEG_BYTES     : natural :=
          SHUTDOWN_REASON_BYTES  ;

constant BLOCK_LEN_SHUTDOWN     : unsigned (7 downto 0) :=
        TO_UNSIGNED (SHUTDOWN_SEG_BYTES, 8) ;




signal status_written : std_logic;
signal status_written_follower  : std_logic;
signal log_status_follower    : std_logic ;
signal write_status           : std_logic ;
signal write_status_follower  : std_logic ;


signal events_written : std_logic;
signal events_written_follower  : std_logic;
signal events_data_write   :   std_logic;

signal log_events_follower    : std_logic ;

-- Device byte send to Flash flag.

signal device_byte_sending  : std_logic ;


--Hold over from the original design.
--Bytes destined for the input buffer are put here.
signal device_byte          :std_logic_vector(7 downto 0);
-- Byte of a data block to send and flag indicating it is ready to send.

signal block_byte           : std_logic_vector (7 downto 0) ;
signal block_byte_ready     : std_logic ;

signal block_bytes_left     : unsigned (9 downto 0) ;

--! Acknowledgement that the data block byte is being sent.

signal block_byte_ready_follower  : std_logic ;

--! Number of bytes in the current audio segment.

signal audio_seg_length     : unsigned (7 downto 0) ;

  --! Number of bytes in the current events segment.

signal events_seg_length     : unsigned (7 downto 0) ;

signal events_checked        : unsigned (7 downto 0) ;

signal start_follower       : std_logic;

--! Flash block writing states.

type BlockState is   (
  BLOCK_STATE_WAIT,
  BLOCK_STATE_BUFFER,
  BLOCK_STATE_SEQNO,

  BLOCK_STATE_PADDING,
  BLOCK_STATE_PADDING_ADD,
  BLOCK_STATE_SEG_PAD,
  BLOCK_STATE_LEN_PAD,

  -- BLOCK_STATE_EVENTS,
  BLOCK_STATE_SEG_ST,
  BLOCK_STATE_LEN_ST,

  BLOCK_STATE_AUDIO_PREFETCH,
  BLOCK_STATE_AUDIO_LAST,
  BLOCK_STATE_SEG_AUD,
  BLOCK_STATE_LEN_AUD,

  BLOCK_STATE_GYRO_PREFETCH,
  BLOCK_STATE_GYRO,
  BLOCK_STATE_GYRO_SEG_ST,
  BLOCK_STATE_GYRO_LEN_ST,
  BLOCK_STATE_ACCEL_PREFETCH,
  BLOCK_STATE_ACCEL,
  BLOCK_STATE_ACCEL_SEG_ST,
  BLOCK_STATE_ACCEL_LEN_ST,
  BLOCK_STATE_MAG_PREFETCH,
  BLOCK_STATE_MAG,
  BLOCK_STATE_MAG_SEG_ST,
  BLOCK_STATE_MAG_LEN_ST,
  BLOCK_STATE_TEMP_PREFETCH,
  BLOCK_STATE_TEMP,
  BLOCK_STATE_TEMP_SEG_ST,
  BLOCK_STATE_TEMP_LEN_ST,

  BLOCK_STATE_GPS_NAV_SOL_SETUP,
  BLOCK_STATE_GPS_NAV_SOL_FETCH,
  BLOCK_STATE_GPS_NAV_SOL_POSTIME_SETUP,
  BLOCK_STATE_GPS_NAV_SOL_POSTIME_FETCH,
  BLOCK_STATE_NAV_SOL_SEG_ST,
  BLOCK_STATE_NAV_SOL_LEN_ST,

  
  BLOCK_STATE_GPS_NAV_SOL_ECEF_SETUP_W,
  BLOCK_STATE_GPS_NAV_SOL_ECEF_FETCH_W,
  BLOCK_STATE_GPS_NAV_SOL_ECEFACC_SETUP_W,
  BLOCK_STATE_GPS_NAV_SOL_ECEFACC_FETCH,
  BLOCK_STATE_GPS_NAV_SOL_POSTIME_SETUP_W,
  BLOCK_STATE_GPS_NAV_SOL_POSTIME_FETCH_W,
  
  
  BLOCK_STATE_GPS_TIM_TM2_SETUP,
  BLOCK_STATE_GPS_TIM_TM2_FETCH,
  BLOCK_STATE_GPS_TIM_TM2_MARKTIME_SETUP,
  BLOCK_STATE_GPS_TIM_TM2_MARKTIME_FETCH,
  BLOCK_STATE_TIM_TM2_SEG_ST,
  BLOCK_STATE_TIM_TM2_LEN_ST,

  BLOCK_STATE_STATUS_COMPILE,
  BLOCK_STATE_STATUS_COMMIT,
  BLOCK_STATE_STATUS_FPGA_TIME,
  BLOCK_STATE_STATUS_ACCEL_TIME,
  BLOCK_STATE_STATUS_MAG_TIME,
  BLOCK_STATE_STATUS_GYRO_TIME,
  BLOCK_STATE_STATUS_TEMP_TIME,
  BLOCK_STATE_STATUS_AUDIO_TIME,
  BLOCK_STATE_STATUS_RTC_TIME,
  BLOCK_STATE_STATUS_MICS,

  --States used to enact direct write and force write modes.
  --BLOCK_STATE_DIRECT,
  --BLOCK_STATE_DIRECT_RESET,
  --BLOCK_STATE_DIRECT_END,
  BLOCK_STATE_FORCE,
  BLOCK_STATE_FORCE_DONE,
  BLOCK_STATE_PADDING_IMM,
  BLOCK_STATE_PADDING_ADD_IMM,
  BLOCK_STATE_SEG_PAD_IMM,
  BLOCK_STATE_LEN_PAD_IMM,

  BLOCK_STATE_EVENTS_SETUP,
  BLOCK_STATE_EVENTS_FETCH,
  BLOCK_STATE_EVENTS_INCREMENT,
  BLOCK_STATE_EVENTS_SEG_ST,
  BLOCK_STATE_EVENTS_LEN_ST

) ;

  signal cur_block_state        : BlockState ;
  signal next_block_state       : BlockState ;
  signal end_block_state        : BlockState ;

  --! Flash item writing states.

type ItemState is   (
  ITEM_STATE_STARTUP_WAIT,
  ITEM_STATE_WAIT,
  ITEM_STATE_CHECK_SPACE,
  ITEM_STATE_NEW_BLOCK,
  ITEM_STATE_PADDING_END,
  ITEM_STATE_AUDIO_END,
  ITEM_STATE_AUDIO_BYTE,
  ITEM_STATE_STATUS,
  ITEM_STATE_GYRO,
  ITEM_STATE_ACCEL,
  ITEM_STATE_MAG,
  ITEM_STATE_TEMP,
  ITEM_STATE_GPS_POS,
  ITEM_STATE_GPS_TIME_MARK,
  ITEM_STATE_EVENTS,
  ITEM_STATE_FORCE,
  ITEM_STATE_FORCE_DONE,
  ITEM_STATE_PAUSE,
  ITEM_STATE_LOGIC_BLOCK_FETCH_SETUP,
  ITEM_STATE_LOGIC_BLOCK_FETCH,
  ITEM_STATE_LOGIC_BLOCK_STORE_SETUP,
  ITEM_STATE_LOGIC_BLOCK_STORE
) ;




type PacketState is   (
  PACKETSTATE_WAIT,
  PACKETSTATE_REQ,
  
  PACKETSTATE_SERIAL_SETUP,
  PACKETSTATE_SERIAL,
  
  PACKETSTATE_GPSTIME_SETUP,
  PACKETSTATE_GPSTIME,
  
  PACKETSTATE_FPGACONTROL_SETUP,
  PACKETSTATE_FPGACONTROL,
  
  
  PACKETSTATE_VOLTAGE,
  PACKETSTATE_VOLTAGE_SETUP,
  PACKETSTATE_CURRENT,
  PACKETSTATE_CURRENT_SETUP,
  PACKETSTATE_CAP,
  PACKETSTATE_CAP_SETUP,
  
  PACKETSTATE_SDBLOCK_SETUP,
  PACKETSTATE_SDBLOCK,
  
  PACKETSTATE_ECEF_SETUP,
  PACKETSTATE_ECEF,
  
  PACKETSTATE_GPSACC_SETUP,
  PACKETSTATE_GPSACC,
  
  PACKETSTATE_NAVSOLTIME_SETUP,
  PACKETSTATE_NAVSOLTIME,
  
  PACKETSTATE_RTC_SETUP,
  PACKETSTATE_RTC,
  
  PACKETSTATE_FLIPBANK
) ;



signal cur_item_state             : ItemState ;
signal next_item_state            : ItemState ;
signal end_item_state             : ItemState ;


signal cur_packet_state             : PacketState ;


--! Number of bytes needed in the current block.

signal bytes_needed               : unsigned (7 downto 0) ;

constant EVENT_SAMPLE_BYTES      : natural  := 2;

--! Audio input processing signals and constants.

signal audio_written              : std_logic ;
signal audio_written_follower     : std_logic ;






signal audio_data_rdy_follower  : std_logic;


signal  gyro_data_rdy_follower   :  std_logic;
signal  accel_data_rdy_follower  :  std_logic;
signal  mag_data_rdy_follower    :  std_logic;
signal  temp_data_rdy_follower   :  std_logic;

signal  gyro_data_write     :   std_logic;
signal  accel_data_write    :   std_logic;
signal  mag_data_write      :   std_logic;
signal  temp_data_write     :   std_logic;

signal  gyro_data_write_follower     :  std_logic;
signal  accel_data_write_follower    :  std_logic;
signal  mag_data_write_follower      :  std_logic;
signal  temp_data_write_follower     :  std_logic;

signal  gyro_written     :  std_logic;
signal  accel_written    :  std_logic;
signal  mag_written      :  std_logic;
signal  temp_written     :  std_logic;

signal  gyro_written_follower     :  std_logic;
signal  accel_written_follower    :  std_logic;
signal  mag_written_follower      :  std_logic;
signal  temp_written_follower     :  std_logic;

signal  audio_data_write            : std_logic;
signal  audio_data_write_follower   : std_logic;



signal  gps_time_data_write :   std_logic;
signal  gps_pos_data_write  :   std_logic;

signal  gps_pos_written     :   std_logic;
signal  gps_time_written    :   std_logic;

signal  gps_pos_written_follower    :   std_logic;
signal  gps_time_written_follower   :   std_logic;

signal  tmbank_follower   :  std_logic;
signal  posbank_follower  :  std_logic;



signal  audio_data_process_request            :  std_logic;
signal  audio_data_process_request_follower   :  std_logic;

signal  audio_data_processed            :  std_logic;
signal  audio_data_processed_follower   :  std_logic;


signal  gyro_data_process_request           :  std_logic;
signal  gyro_data_process_request_follower  :  std_logic;

signal  gyro_data_processed             :  std_logic;
signal  gyro_data_processed_follower    :  std_logic;

signal  accel_data_process_request            :  std_logic;
signal  accel_data_process_request_follower   :  std_logic;

signal  accel_data_processed            :  std_logic;
signal  accel_data_processed_follower   :  std_logic;


signal  mag_data_process_request            :  std_logic;
signal  mag_data_process_request_follower   :  std_logic;

signal  mag_data_processed            :  std_logic;
signal  mag_data_processed_follower   :  std_logic;

signal  temp_data_process_request           :  std_logic;
signal  temp_data_process_request_follower  :  std_logic;

signal  temp_data_processed           :  std_logic;
signal  temp_data_processed_follower  :  std_logic;


signal gyro_sample : std_logic_vector(
                          3*imu_axis_word_length_bytes_g*8-1 downto 0);
signal accel_sample : std_logic_vector(
                          3*imu_axis_word_length_bytes_g*8-1 downto 0);
signal mag_sample : std_logic_vector(
                          3*imu_axis_word_length_bytes_g*8-1 downto 0);
signal temp_sample : std_logic_vector(
                          imu_axis_word_length_bytes_g*8-1 downto 0);

signal gyro_sample_fpga_time :  std_logic_vector(
                                gps_time_bytes_c*8-1 downto 0);
signal accel_sample_fpga_time : std_logic_vector(
                                gps_time_bytes_c*8-1 downto 0);
signal mag_sample_fpga_time :   std_logic_vector(
                                gps_time_bytes_c*8-1 downto 0);
signal temp_sample_fpga_time :  std_logic_vector(
                                gps_time_bytes_c*8-1 downto 0);

signal audo_sample_fpga_time  : std_logic_vector(
                                gps_time_bytes_c*8-1 downto 0);

signal imu_sample_time_buffer : std_logic_vector(
                                ((3*imu_axis_word_length_bytes_g)
                                +(gps_time_bytes_c)) *8 -1 downto 0);




signal flashblock_inbuf_addr_internal  : unsigned(natural(
                                        trunc(log2(real(
                                        sdram_input_buffer_bytes_g-1))))
                                        downto 0);
signal flashblock_gpsbuf_addr_internal : unsigned(natural(
                                        trunc(log2(real(
                                        gps_buffer_bytes_g-1))))
                                        downto 0);

signal flashblock_counter_wr_addr_internal  :  unsigned(
                                                counter_address_size_g-1
                                                downto 0);

signal flashblock_counter_rd_addr_internal  :  unsigned(
                                                counter_address_size_g-1
                                                downto 0);

signal flashblock_counter_rd_wr_addr_internal  : unsigned(
                                                counter_address_size_g-1
                                                downto 0);


--Ultimately here we want to generically specify multiple circular
--buffers within one space of ram.
--We divide up the space into a number of buffers and then have read
--and write pointers into each
--specific circular buffer.

--Oft forgotten but.....if we want to address 2^4 - 1 things,
--we can do this with (3 downto 0)
--2^4 -1 allows (3 downto 0) to encode 0-15.
--We can use this to calculate any address.  Or calculate two address spaces.
--Here I calculate an upper set of bits which allow for N circular buffers.
--I than calculate a lower set of bits to allow for N samples in a buffer.
--I can select which buffer I am in, by simple counting in the upper bits.
constant CIRC_BUFFER_BYTES        : natural := 1024;
constant CIRC_BUFFER_SAMPLES      : natural := 16;
constant CIRC_BUFFER_WIDTH_BYTES   : natural := 8;


signal  circbuffer_flashblock_data_internal     : std_logic_vector(CIRC_BUFFER_WIDTH_BYTES*8-1 downto 0);
signal  flashblock_circbuffer_data_internal     : std_logic_vector(CIRC_BUFFER_WIDTH_BYTES*8-1 downto 0);
signal  flashblock_circbuffer_wr_en_internal    : std_logic;
signal  flashblock_circbuffer_rd_en_internal    : std_logic;

signal circ_buffer_rd_audio  :  unsigned(natural(trunc(log2(real(CIRC_BUFFER_SAMPLES-1)))) downto 0);
signal circ_buffer_wr_audio  :  unsigned(natural(trunc(log2(real(CIRC_BUFFER_SAMPLES-1)))) downto 0);



--These signals allow addressing into one of the circular buffers. We only need to address the number of
--samples interested in.
--These are unsigned and incrementable. They also rollover.
signal circ_buffer_rd_accel  :  unsigned(natural(trunc(log2(real(
                                CIRC_BUFFER_SAMPLES-1)))) downto 0);
signal circ_buffer_wr_accel  :  unsigned(natural(trunc(log2(real(
                                CIRC_BUFFER_SAMPLES-1)))) downto 0);

signal circ_buffer_rd_gyro  :   unsigned(natural(trunc(log2(real(
                                CIRC_BUFFER_SAMPLES-1)))) downto 0);
signal circ_buffer_wr_gyro  :   unsigned(natural(trunc(log2(real(
                                CIRC_BUFFER_SAMPLES-1)))) downto 0);

signal circ_buffer_rd_mag  :    unsigned(natural(trunc(log2(real(
                                CIRC_BUFFER_SAMPLES-1)))) downto 0);
signal circ_buffer_wr_mag  :    unsigned(natural(trunc(log2(real(
                                CIRC_BUFFER_SAMPLES-1)))) downto 0);

signal circ_buffer_rd_temp  : unsigned(natural(trunc(log2(real(
                              CIRC_BUFFER_SAMPLES-1)))) downto 0);
signal circ_buffer_wr_temp  : unsigned(natural(trunc(log2(real(
                              CIRC_BUFFER_SAMPLES-1)))) downto 0);




--These are the partial addresses which are sent to the ram. They take assginment
--from the unsigned values above (ie circ_buffer_rd_accel) which store the current positions in the circular
--buffers.
signal flashblock_circbuffer_sample_rd    :   std_logic_vector(natural(trunc(log2(real(
                              CIRC_BUFFER_SAMPLES-1)))) downto 0);

signal flashblock_circbuffer_buffer_rd    :  std_logic_vector(natural(trunc(log2(real(
                              (CIRC_BUFFER_BYTES/CIRC_BUFFER_WIDTH_BYTES)
                              /CIRC_BUFFER_SAMPLES-1)))) downto 0);

signal flashblock_circbuffer_sample_wr    :  std_logic_vector(natural(trunc(log2(real(
                              CIRC_BUFFER_SAMPLES-1)))) downto 0);

signal flashblock_circbuffer_buffer_wr    :  std_logic_vector(natural(trunc(log2(real(
                              (CIRC_BUFFER_BYTES/CIRC_BUFFER_WIDTH_BYTES)
                              /CIRC_BUFFER_SAMPLES-1)))) downto 0);


--These are simply used to simply always store the concat of the
--flashblock_circbuffer_sample_rd & flashblock_circbuffer_buffer_rd
--Used as input to the two port ram. This cures a modelsim error wherby the input
--port map to a 2port ram cannot be a concatenation.
signal flashblock_circbuffer_wr_address    :  std_logic_vector(
                          flashblock_circbuffer_buffer_wr'length +
                          flashblock_circbuffer_sample_wr'length -1 downto 0);

signal flashblock_circbuffer_rd_address    :  std_logic_vector(
                            flashblock_circbuffer_buffer_wr'length +
                            flashblock_circbuffer_sample_wr'length -1 downto 0);

signal circbuffer_clk : std_logic;


constant circbuffer_audio_select  :  std_logic_vector(
                            flashblock_circbuffer_buffer_rd'length - 1 downto 0)
                            := std_logic_vector(to_unsigned(0,
                            flashblock_circbuffer_buffer_rd'length));

constant circbuffer_accel_select  :  std_logic_vector(
                            flashblock_circbuffer_buffer_rd'length - 1 downto 0)
                            := std_logic_vector(to_unsigned(1,
                            flashblock_circbuffer_buffer_rd'length));

constant circbuffer_gyro_select  :  std_logic_vector(
                            flashblock_circbuffer_buffer_rd'length - 1 downto 0)
                            := std_logic_vector(to_unsigned(2,
                            flashblock_circbuffer_buffer_rd'length));

constant circbuffer_mag_select  :  std_logic_vector(
                            flashblock_circbuffer_buffer_rd'length - 1 downto 0)
                            := std_logic_vector(to_unsigned(3,
                            flashblock_circbuffer_buffer_rd'length));

constant circbuffer_temp_select  :  std_logic_vector(
                            flashblock_circbuffer_buffer_rd'length - 1 downto 0)
                            := std_logic_vector(to_unsigned(4,
                            flashblock_circbuffer_buffer_rd'length));






--Signals relating to servicing direct write and force modes of sdram.
--SDRAM can only service 2k at a time, so this is why 2k is of interest.
alias   accumulated_2k :  std_logic is flashblock_inbuf_addr_internal(11);
alias   address_2k  : unsigned(10 downto 0) is flashblock_inbuf_addr_internal(10 downto 0);
signal  accumulated_2k_follower  : std_logic;




signal block_padding_length_imm : unsigned (7 downto 0);

signal crit_event_follower : std_logic;

signal crit_event_write  : std_logic;


signal crit_event_written : std_logic;
signal crit_event_written_follower : std_logic;


--New signals related to allowing continued block formation
--during force_wr.
signal  force_wr_en_signal : std_logic;
signal  blocks_past_crit_signal   : unsigned (7 downto 0);

signal sdram_empty_follower : std_logic;
signal empty_done : std_logic;
signal empty_serviced : std_logic;
signal empty_serviced_follower : std_logic;

--These are the signals that flashblock requires to interface with
--the magnetic memory buffer.

signal fb_magram_address_a : unsigned(natural(trunc(log2(real(
                            (magmem_buffer_bytes/magmem_buffer_num)-1))))
                            downto 0);

signal startup_done       : std_logic;


signal last_seqno         : std_logic_vector(31 downto 0);


--Millisecond Counter for Status Log.
constant ms_count_c       : natural :=
          natural (real (sysclk_freq_g)/1.0e3) ;
constant status_up_count       : natural := status_update_interval_ms 
                                            * ms_count_c;
signal status_up_counter : unsigned(natural(trunc(log2(real(
                                status_up_count)))) downto 0);
                                
--Wireless Packet Related Signals--
--Millisecond Counter for Wireless Packet.
constant wpacket_up_count       : natural := wireless_update_interval_ms_g 
                                            * ms_count_c;
signal wpacket_up_counter : unsigned(natural(trunc(log2(real(
                                wpacket_up_count)))) downto 0);
                                
                                
--Wireless Packet Signalling Lines. 
signal wp_written : std_logic;
signal wp_written_follower  : std_logic;
signal write_wp      : std_logic ;
signal write_wp_follower  : std_logic ;
                                
                                
signal     sdxc_serial_reg           :    std_logic_vector(31 downto 0);

signal     sdxc_block_reg            :    std_logic_vector(31 downto 0);
signal     voltage_mv_reg            :    std_logic_vector (15 downto 0);
signal     rem_cap_mah_reg           :    std_logic_vector (15 downto 0);
signal     inst_cur_ma_reg           :    std_logic_vector (15 downto 0);
signal     rtc_reg                   :    std_logic_vector (rtc_time_bytes_g*8-1 downto 0);

signal     sdxc_serial_push           :    std_logic_vector(31 downto 0);  
signal     sdxc_block_push            :    std_logic_vector(31 downto 0);
signal     voltage_mv_push            :    std_logic_vector (15 downto 0);
signal     rem_cap_mah_push           :    std_logic_vector (15 downto 0);
signal     inst_cur_ma_push           :    std_logic_vector (15 downto 0);
signal     rtc_push                   :    std_logic_vector (rtc_time_bytes_g*8-1 downto 0);
signal     current_FPGA_time_push           :    std_logic_vector(gps_time_bytes_c*8-1 downto 0);    

                                
signal     sdxc_serial_reg_s           :    std_logic_vector(31 downto 0);
signal     wp_gps_time_reg_s           :    std_logic_vector(gps_time_bytes_c*8-1 downto 0);    
signal     sdxc_block_reg_s            :    std_logic_vector(31 downto 0);
signal     voltage_mv_reg_s            :    std_logic_vector (15 downto 0);
signal     rem_cap_mah_reg_s           :    std_logic_vector (15 downto 0);
signal     inst_cur_ma_reg_s           :    std_logic_vector (15 downto 0);
signal     rtc_reg_s                   :    std_logic_vector (rtc_time_bytes_g*8-1 downto 0);


signal    control_register_s    :  std_logic_vector(ControlSignalsCnt_c-1 downto 0);
signal    control_register      :  std_logic_vector(ControlSignalsCnt_c-1 downto 0);
constant control_register_byte_count_c      : natural :=
                                                      (ControlSignalsCnt_c + 7) / 8;
signal    control_register_push :  std_logic_vector(control_register_byte_count_c*8-1 downto 0);
    
signal     navsol_ecefXYZ_reg    :    std_logic_vector ((MUNSol_ecefX_size_c + MUNSol_ecefY_size_c + 
                                        MUNSol_ecefZ_size_c) * 8-1 downto 0);
                                        
                                        
signal     navsol_ecefXYZ_push    :    std_logic_vector ((MUNSol_ecefX_size_c + MUNSol_ecefY_size_c + 
                                        MUNSol_ecefZ_size_c) * 8-1 downto 0);
                                
signal     navsol_pAcc_reg    :    std_logic_vector ((MUNSol_pAcc_size_c) * 8-1 downto 0); 
signal     navsol_pAcc_reg_push    :    std_logic_vector ((MUNSol_pAcc_size_c) * 8-1 downto 0);
                                    


signal    nav_sol_time      :  std_logic_vector(gps_time_bytes_c*8-1 downto 0);
signal    nav_sol_time_push :  std_logic_vector(gps_time_bytes_c*8-1 downto 0);

--Address into txrx bank is txrx_bank & fb_txrx_address_a;
signal    txrx_bank         : std_logic;
signal    fb_txrx_address_a : unsigned(natural(trunc(log2(real(
                            (txrx_single_buffer_size)-1))))
                            downto 0);    
                            
                            

--  Multi-byte transfer signals.
--  For wireless packet state machine. 
signal byte_count_w             : unsigned (7 downto 0) ;
signal byte_number_w            : unsigned (7 downto 0) ;
                            
                            
--Wireless Packet Related Signals--  





--Count the number of GPS events for debug.
signal navsol_cnt   : unsigned(7 downto 0);
signal tim_tm2_cnt  : unsigned(7 downto 0);

attribute noprune: boolean;
attribute noprune of navsol_cnt : signal is true;
attribute noprune of tim_tm2_cnt : signal is true;






--
--
--General means to insert multi-byte items into the block.
--A number of multi-byte items may need to be inserted into the
--block.  A buffer large enough to handle all of them is
--defined and a signal to contain the number of bytes of the
--current transfer is defined as well.  The maximum natural
--function determines the size that the buffer will need to be.
--
--

type NaturalArray is array (natural range <>) of natural ;

--Computes the number of bytes needed to allocate for the segment buffer.

function MAX_NATURAL (tbl : NaturalArray) return natural is
variable max_value : natural := 0 ;
begin
for index in tbl'range loop
  if max_value < tbl (index) then
    max_value := tbl (index) ;
  end if ;
end loop ;
return max_value ;
end MAX_NATURAL ;


constant BYTE_LENGTH_TBL : NaturalArray :=
    (time_bytes_g, BLOCK_SEQNO_BYTES,
    STATUS_VER_BYTES,
    event_bytes_g,
    STATUS_AUD_BYTES,
    3*imu_axis_word_length_bytes_g,
    rtc_time_bytes_g,
    NUM_ACTIVE_MICS_BYTES,
    STATUS_COMPILE_BYTES,
    STATUS_COMMIT_BYTES,
    gps_time_bytes_c) ;

constant BYTE_BUFFER_SIZE     : natural := MAX_NATURAL (BYTE_LENGTH_TBL) ;

signal byte_buffer            : std_logic_vector (BYTE_BUFFER_SIZE*8-1 downto 0) ;

--  Multi-byte transfer signals.
--  For block state machine.
signal byte_count             : unsigned (7 downto 0) ;
signal byte_number            : unsigned (7 downto 0) ;


--  Multi-byte transfer signals.
--  For item state machine.
signal byte_count_i             : unsigned (7 downto 0) ;
signal byte_number_i            : unsigned (7 downto 0) ;

  --  Cross clock domain signals.

  signal mem_rec_a_s        : std_logic ;
  signal mem_rec_a          : std_logic ;
  signal gps_rec_s          : std_logic ;
  signal gps_rec            : std_logic ;
  signal sdram_empty_s      : std_logic ;
  signal sdram_empty        : std_logic ;
  signal rtc_time_last_s    : std_logic ;
  signal rtc_time_last      : std_logic ;

  signal rtc_time_last_fwl  : std_logic ;
  signal rtc_time_s         : std_logic_vector (rtc_time_in'length-1
                                                downto 0) ;

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
      clk                   => clock_sys,
      data_latch_in         => curtime_latch_in,
      data_valid_in         => curtime_valid_in,
      valid_latch_in        => curtime_vlatch_in,
      data_in               => curtime_in,
      data_out              => current_FPGA_time
    ) ;

  --------------------------------------------------------------------------
  --  Synchronize cross clock domain signals.
  --------------------------------------------------------------------------

  cross_clock : process (rst_n, clock_sys)
  begin
    if (rst_n = '0') then
      mem_rec_a_s       <= '0' ;
      mem_rec_a         <= '0' ;
      gps_rec_s         <= '0' ;
      gps_rec           <= '0' ;
      sdram_empty_s     <= '0' ;
      sdram_empty       <= '0' ;
      rtc_time_last_s   <= '0' ;
      rtc_time_last     <= '0' ;
      rtc_time_last_fwl <= '0' ;
      rtc_time_s        <= (others => '0') ;
    elsif (falling_edge (clock_sys)) then
      mem_rec_a         <= mem_rec_a_s ;
      gps_rec           <= gps_rec_s ;
      sdram_empty       <= sdram_empty_s ;
      rtc_time_last     <= rtc_time_last_s ;
    elsif (rising_edge (clock_sys)) then
      mem_rec_a_s       <= mem_rec_a_in ;
      gps_rec_s         <= gps_rec_in ;
      sdram_empty_s     <= sdram_empty_in ;
      rtc_time_last_s   <= rtc_time_in (0) ;

      if (rtc_time_last_fwl /= rtc_time_last) then
        rtc_time_last_fwl   <= rtc_time_last ;

        rtc_time_s      <= rtc_time_in ;
      end if ;
    end if ;
  end process cross_clock ;


--IMU and Audio data are buffered here in a circular manner.
circbuffer : altsyncram
GENERIC MAP (
  address_aclr_b => "NONE",
  address_reg_b => "CLOCK0",
  clock_enable_input_a => "BYPASS",
  clock_enable_input_b => "BYPASS",
  clock_enable_output_b => "BYPASS",
  intended_device_family => "Cyclone V",
  lpm_type => "altsyncram",
  numwords_a => 128,
  numwords_b => 128,
  operation_mode => "DUAL_PORT",
  outdata_aclr_b => "NONE",
  outdata_reg_b => "UNREGISTERED",
  power_up_uninitialized => "FALSE",
  rdcontrol_reg_b => "CLOCK0",
  read_during_write_mode_mixed_ports => "DONT_CARE",
  widthad_a => 7,
  widthad_b => 7,
  width_a => 64,
  width_b => 64,
  width_byteena_a => 1
  )
PORT MAP (
  address_a => flashblock_circbuffer_wr_address,
  clock0 =>  circbuffer_clk,
  data_a => flashblock_circbuffer_data_internal,
  rden_b => flashblock_circbuffer_rd_en_internal,
  wren_a => flashblock_circbuffer_wr_en_internal,
  address_b => flashblock_circbuffer_rd_address,
  q_b => circbuffer_flashblock_data_internal
  );



--  Event counters need to be locked when they are moved one byte at a
--  time.  This prevents a counter spanning two blocks from being
--  changed while it is being moved.  Until byte-by-byte moving is
--  being done locking is not needed.


flashblock_inbuf_data       <= block_byte;
flashblock_inbuf_wr_en      <= device_byte_sending;
flashblock_inbuf_clk        <= not clock_sys;

--Take the internal memory pointers and map them out.
flashblock_inbuf_addr <= std_logic_vector(flashblock_inbuf_addr_internal);
flashblock_gpsbuf_addr <= std_logic_vector(flashblock_gpsbuf_addr_internal);

flashblock_counter_rd_wr_addr <= std_logic_vector(flashblock_counter_rd_wr_addr_internal);

 --For some reason in modelsim 10.1c,
 --concat AND not operations in the port map give global static errors.
circbuffer_clk <= not clock_sys;
flashblock_circbuffer_rd_address <= flashblock_circbuffer_buffer_rd
                                    & flashblock_circbuffer_sample_rd;
flashblock_circbuffer_wr_address <= flashblock_circbuffer_buffer_wr
                                    & flashblock_circbuffer_sample_wr;



force_wr_en <= force_wr_en_signal;
blocks_past_crit <= std_logic_vector(blocks_past_crit_signal);



--Signal mapping for the magnetic memory interfacing.
fb_magram_address_a_out <= std_logic_vector(fb_magram_address_a);
fb_magram_clk_a_out <= not(clock_sys);
flashblock_gpsbuf_clk <= not(clock_sys);


fb_txrx_clk_a_out <= not(clock_sys);
txrx_bank_out <= txrx_bank;
fb_txrx_address_a_out <= txrx_bank & std_logic_vector(fb_txrx_address_a);
  

--
--Send a byte to the Flash device when one is ready.
--Check all data sources and send a byte to the data bus
--when one of the sources indicates it has a byte to send.
--
--

startup_done_out <= startup_done;



send_device_byte:  process (clock_sys, rst_n)
begin
  if (rst_n = '0') then
    device_byte_sending       <= '0' ;
    block_byte_ready_follower <= '0' ;
    device_byte               <= (others => '0') ;
    flashblock_inbuf_addr_internal <= (others => '0');
    accumulated_2k_follower <= '0';
    flashblock_sdram_2k_accumulated <= '0';
    block_bytes_left          <= TO_UNSIGNED (BLOCK_SIZE,
                                              block_bytes_left'length);

  elsif (clock_sys'event and clock_sys = '1') then
    if (clk_enable) = '1' then
      device_byte_sending     <= '0' ;
      flashblock_sdram_2k_accumulated <= '0';
      --Increment the address only AFTER the previous byte has gone out.
      if (device_byte_sending = '1') then
        flashblock_inbuf_addr_internal <= flashblock_inbuf_addr_internal + 1;
        if (accumulated_2k_follower /= accumulated_2k) then
          accumulated_2k_follower <= accumulated_2k;
          flashblock_sdram_2k_accumulated <= '1';
        end if;
      end if;
      if (block_byte_ready_follower /= block_byte_ready) then
        block_byte_ready_follower <= block_byte_ready ;
        if (block_byte_ready = '1') then
          device_byte_sending <= '1' ;
          device_byte         <= block_byte ;
          if (block_bytes_left = 1) then
            block_bytes_left  <= TO_UNSIGNED (BLOCK_SIZE,
                                  block_bytes_left'length) ;
          else
            block_bytes_left  <= block_bytes_left - 1 ;
          end if ;
        end if ;
      end if ;
    end if ;
  end if;

end process send_device_byte ;


--
--Send a data item to the Flash block.
--This state machine handles the actual data movement of the
--assembly. Data is fetched out of buffers, either the entities circular
--buffer or out of the GPS's buffer, and then placed into a byte shift
--buffer which sends the data out to the inbuf of sdram.
--Other functionality includes the ability to add segments such
--as initial block number and padding.


send_block_item:  process (clock_sys, rst_n)
begin
  if (rst_n = '0') then
    cur_block_state       <= BLOCK_STATE_WAIT ;
    end_block_state       <= BLOCK_STATE_WAIT ;
    block_byte_ready      <= '0' ;
    block_byte            <= (others => '0') ;
    --clear_events          <= '0' ;
    audio_seg_length      <= (others => '0') ;
    audio_written         <= '0' ;


    gyro_written        <= '0' ;
    accel_written       <= '0' ;
    mag_written         <= '0' ;
    temp_written        <= '0' ;

    gps_time_written <= '0';
    gps_pos_written <= '0';

    status_written <= '0';

    flashblock_counter_rd_wr_addr_internal       <= (others => '0') ;
    events_written       <= '0' ;

    flashblock_counter_rd_en <= '0';
    flashblock_counter_wr_en <= '0';
    flashblock_counter_lock <= '0';


    events_checked <= (others => '0') ;
    events_seg_length <= (others => '0') ;

    flashblock_gpsbuf_rd_en <= '0';

    circ_buffer_rd_audio <= (others => '0') ;

    circ_buffer_rd_gyro <= (others => '0') ;
    circ_buffer_rd_accel <= (others => '0') ;
    circ_buffer_rd_mag <= (others => '0') ;
    circ_buffer_rd_temp <= (others => '0') ;


    flashblock_circbuffer_buffer_rd <= (others => '0') ;
    flashblock_circbuffer_sample_rd <= (others => '0') ;
    flashblock_circbuffer_rd_en_internal <= '0';

    crit_event_written <= '0';

    force_wr_en_signal <= '0';

    force_wr_en_signal <= '0';
    empty_serviced <= '0';
    blocks_past_crit_signal <= to_unsigned(0,blocks_past_crit_signal'length);


    navsol_ecefXYZ_reg    <= (others => '0') ;                         
    navsol_pAcc_reg       <= (others => '0') ;
    nav_sol_time          <= (others => '0') ;
    
  
  


  elsif (clock_sys'event and clock_sys = '1') then
    if (clk_enable) = '1' then

      --  Clear asserted signals when they have been acknowledged.

      if (block_byte_ready = '1' and block_byte_ready_follower = '1') then
        block_byte_ready    <= '0' ;
      end if ;

      --Acknowledge that audio written has been received by lower process.
      --This is simply acknowledgement.
      if (audio_written = '1' and audio_written_follower = '1') then
        audio_written       <= '0' ;
      end if ;

      if (gyro_written = '1' and gyro_written_follower = '1') then
        gyro_written       <= '0' ;
      end if ;

      if (accel_written = '1' and accel_written_follower = '1') then
        accel_written       <= '0' ;
      end if ;

      if (mag_written = '1' and mag_written_follower = '1') then
        mag_written       <= '0' ;
      end if ;

      if (temp_written = '1' and temp_written_follower = '1') then
        temp_written       <= '0' ;
      end if ;

      if (gps_pos_written = '1' and gps_pos_written_follower = '1') then
        gps_pos_written       <= '0' ;
      end if ;

      if (gps_time_written = '1' and gps_time_written_follower = '1') then
        gps_time_written       <= '0' ;
      end if ;

      if (status_written = '1' and status_written_follower = '1') then
        status_written       <= '0' ;
      end if ;

      if (events_written = '1' and events_written_follower = '1') then
        events_written       <= '0' ;
      end if ;

      if (crit_event_written = '1' and crit_event_written_follower = '1') then
        crit_event_written       <= '0' ;
      end if ;

      if (empty_serviced_follower= '1' and empty_serviced = '1') then
        empty_serviced <= '0';
      end if;



    if (block_byte_ready = '0' and block_byte_ready_follower = '0') then

      --  Send another byte from an item.

      case cur_block_state is

        --  Switch to the next state if there is one.

        when BLOCK_STATE_WAIT         =>
          cur_block_state     <= next_block_state ;

        --  Write out the bytes in the byte buffer.

        when BLOCK_STATE_BUFFER       =>

          block_byte          <= byte_buffer (7 downto 0) ;
          block_byte_ready    <= '1' ;

          if (byte_count = byte_number) then
            cur_block_state   <= end_block_state ;
          else
            byte_count        <= byte_count + 1 ;
            byte_buffer (byte_buffer'length-8-1 downto 0) <=
                byte_buffer (byte_buffer'length-1 downto 8) ;
          end if ;

        --  Write out the block header sequence number.

        when BLOCK_STATE_SEQNO        =>
          byte_buffer (BLOCK_SEQNO_BYTES*8-1 downto 0) <=
                                    STD_LOGIC_VECTOR (block_seqno) ;
          byte_number       <= TO_UNSIGNED (BLOCK_SEQNO_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_WAIT ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        --  Write out padding.

        when BLOCK_STATE_PADDING      =>
          cur_block_state   <= BLOCK_STATE_PADDING_ADD ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;

        when BLOCK_STATE_PADDING_ADD  =>
          --Byte count init to 1. Then increments within this state.
          if (block_padding_length = 0) then
            cur_block_state <= BLOCK_STATE_SEG_PAD ;
          elsif byte_count = block_padding_length then
            cur_block_state <= BLOCK_STATE_SEG_PAD ;
            block_byte      <= PADDING_BYTE ;
            block_byte_ready  <= '1' ;
          else
            byte_count      <= byte_count + 1 ;
            block_byte      <= PADDING_BYTE ;
            block_byte_ready  <= '1' ;
          end if ;

        when BLOCK_STATE_SEG_PAD      =>
          cur_block_state   <= BLOCK_STATE_LEN_PAD ;
          --Send the segment trailer ID.
          block_byte        <= BLOCK_SEG_UNUSED ;
          block_byte_ready  <= '1' ;

        when BLOCK_STATE_LEN_PAD      =>
        -- --If we are in direct wr mode, we need to check to see if we
        -- --can leave it after ending another block. Padding is always inserted
        -- --at the end of a block.
          -- if (dw_en_internal = '1') then
            -- cur_block_state   <= BLOCK_STATE_DIRECT ;
          -- else
            --Here I increment the blocks_past_crit signal.
            if (force_wr_en_signal = '1') then
              blocks_past_crit_signal <= blocks_past_crit_signal + 1;
            end if;
            cur_block_state   <= BLOCK_STATE_WAIT ;
          --end if;
          --Send the segment trailer ID.
          block_byte        <= STD_LOGIC_VECTOR (block_padding_length) ;
          block_byte_ready  <= '1' ;

        --Write out the status segment. This is a long string
        --of states. Each state is responsible for one field of the status
        --segment. The docs for sd_card_structure are available with this code.

        when BLOCK_STATE_STATUS_COMPILE       =>
          byte_buffer (STATUS_COMPILE_BYTES*8-1 downto 0) <=
          std_logic_vector(to_unsigned(compile_timestamp_c,STATUS_COMPILE_BYTES*8));
          byte_number       <= TO_UNSIGNED (STATUS_COMPILE_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_COMMIT ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;
          status_written <= '1';

        -- Write out the system status time.

        when BLOCK_STATE_STATUS_COMMIT         =>
          byte_buffer (STATUS_COMMIT_BYTES*8-1 downto 0) <=
          std_logic_vector(to_unsigned(commit_timestamp_c,STATUS_COMMIT_BYTES*8));
          byte_number       <= TO_UNSIGNED (STATUS_COMMIT_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_FPGA_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_FPGA_TIME         =>
          byte_buffer (gps_time_bytes_c*8-1 downto 0) <= current_fpga_time;
          byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_ACCEL_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_ACCEL_TIME         =>
          byte_buffer (gps_time_bytes_c*8-1 downto 0) <= accel_fpga_time;
          byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_MAG_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_MAG_TIME         =>
          byte_buffer (gps_time_bytes_c*8-1 downto 0) <= mag_fpga_time;
          byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_GYRO_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_GYRO_TIME         =>
          byte_buffer (gps_time_bytes_c*8-1 downto 0) <= gyro_fpga_time;
          byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_TEMP_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_TEMP_TIME         =>
          byte_buffer (gps_time_bytes_c*8-1 downto 0) <= temp_fpga_time;
          byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_AUDIO_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_AUDIO_TIME         =>
          byte_buffer (gps_time_bytes_c*8-1 downto 0) <= audo_sample_fpga_time;
          byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_RTC_TIME ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_RTC_TIME         =>
          byte_buffer (rtc_time_bytes_g*8-1 downto 0) <= rtc_time_s;
          byte_number       <= TO_UNSIGNED (rtc_time_bytes_g,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_STATUS_MICS ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;

        when BLOCK_STATE_STATUS_MICS         =>
          byte_buffer (NUM_ACTIVE_MICS_BYTES*8-1 downto 0) <=
          std_logic_vector(to_unsigned(num_mics_active_g,NUM_ACTIVE_MICS_BYTES*8));
          byte_number       <= TO_UNSIGNED (NUM_ACTIVE_MICS_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_SEG_ST ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;


        --  Write out the system status segment ID and length.

        when BLOCK_STATE_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_LEN_ST ;
          block_byte        <= BLOCK_SEG_STATUS ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_LEN_ST       =>
          block_byte        <= STD_LOGIC_VECTOR (BLOCK_LEN_STATUS) ;
          block_byte_ready  <= '1' ;

          if(crit_event_write = '1') then
            cur_block_state   <= BLOCK_STATE_PADDING_IMM ;
          else
            cur_block_state   <= BLOCK_STATE_WAIT ;
          end if;

        --Immediately pad out segment. Do not return to item machine.
        when BLOCK_STATE_PADDING_IMM      =>

          cur_block_state   <= BLOCK_STATE_PADDING_ADD_IMM ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          if block_bytes_left >= (PAD_SEG_MAX_LENGTH
                                  + SEG_TRAILER_SIZE
                                  + PAD_SEG_MIN_SIZE) then

            block_padding_length_imm  <= TO_UNSIGNED (PAD_SEG_MAX_LENGTH,
                                                block_padding_length'length) ;

          elsif(block_bytes_left = PAD_SEG_MAX_LENGTH + SEG_TRAILER_SIZE + 1) then

            block_padding_length_imm  <= TO_UNSIGNED (PAD_SEG_MAX_LENGTH - 1,
                                                block_padding_length'length) ;

          else

            --We are writing to end of block, signal crit_event_written.
            --Needed to pad all the way to end of block. Max pad segment
            --size is 255.
            crit_event_written <= '1';
            --  Keep the compiler from complaining
            --  that the number is too big to fit.
            block_padding_length_imm  <=
            block_bytes_left (block_padding_length'length-1 downto 0) -
            SEG_TRAILER_SIZE ;

          end if ;


        when BLOCK_STATE_PADDING_ADD_IMM   =>
          if block_padding_length_imm = 0 then
            cur_block_state <= BLOCK_STATE_SEG_PAD_IMM;
          elsif byte_count = block_padding_length_imm then
            cur_block_state <= BLOCK_STATE_SEG_PAD_IMM;
            block_byte      <= PADDING_BYTE ;
            block_byte_ready  <= '1' ;
          else
            byte_count      <= byte_count + 1 ;
            block_byte      <= PADDING_BYTE ;
            block_byte_ready  <= '1' ;
          end if ;

        when BLOCK_STATE_SEG_PAD_IMM       =>
          cur_block_state   <= BLOCK_STATE_LEN_PAD_IMM ;
          --Send the segment trailer ID.
          block_byte        <= BLOCK_SEG_UNUSED ;
          block_byte_ready  <= '1' ;

        when BLOCK_STATE_LEN_PAD_IMM       =>
          --Checking if we actually wrote all the way to end of block.
          if (crit_event_write = '1') then
           cur_block_state <= BLOCK_STATE_PADDING_IMM;
          else
            cur_block_state <= BLOCK_STATE_FORCE;
          end if;

          --cur_block_state   <= BLOCK_STATE_FORCE ;
          --Send the segment trailer ID.
          block_byte        <= STD_LOGIC_VECTOR (block_padding_length_imm) ;
          block_byte_ready  <= '1' ;


        --Force write is enabled. The calculation of the 2k boundary
        --cannot occur here. Force write will take some amount of time. Thus
        --the next complete block formed will be the first dw_en pulse.
        when BLOCK_STATE_FORCE       =>
          blocks_past_crit_signal <= to_unsigned(0,blocks_past_crit_signal'length);
          force_wr_en_signal <= '1';
          cur_block_state <= BLOCK_STATE_WAIT;


        when BLOCK_STATE_FORCE_DONE       =>
          empty_serviced <= '1';
          force_wr_en_signal <= '0';
          -- if (address_2k =0) then
          -- --Reset dw_en_internal to '0' by going to state BLOCK_STATE_DIRECT_RESET.
          -- --This serves only to help sdloader.
          -- cur_block_state <=  BLOCK_STATE_DIRECT_RESET;
          -- force_wr_en_signal <= '0';
          -- --Wait for sdram_empty before any assert of dw_en. This way
          -- --sdloader will have gotten the last data_rdy and data_nbytes
          -- --associated with the force_wr before calculating critical block
          -- --number.
          -- dw_amt_bytes <= std_logic_vector(to_unsigned(0,dw_amt_bytes'length));
          --Turn on dw_en. This way, sd_loader will sense and sampled blocks_past_crit
          --calculating the critical block.
          --dw_en_internal <= '1';
          -- dw_amt_valid <= '1';
          cur_block_state <=  BLOCK_STATE_WAIT;

          -- else
          -- cur_block_state <=  BLOCK_STATE_DIRECT;
          -- force_wr_en_signal <= '0';

          -- dw_amt_bytes <= std_logic_vector(to_unsigned(0,dw_amt_bytes'length));
          -- dw_en_internal <= '1';
          -- dw_amt_valid <= '1';
          -- end if;


      -- --The normal processing of more blocks simply accumulates dw_amt_bytes
      -- --and pulses the new amt to the sdram_controller.
      -- --This continues until a multiple of 2k has been written out and
      -- --direct write mode is turned off.
        -- when BLOCK_STATE_DIRECT  =>
          -- if (address_2k =0) then
            -- dw_en_internal <= '1';
            -- dw_amt_valid <= '1';
            -- dw_amt_bytes <= std_logic_vector(to_unsigned(2048,dw_amt_bytes'length));
            -- cur_block_state <=  BLOCK_STATE_DIRECT_END;
          -- else
            -- dw_en_internal <= '1';
            -- dw_amt_valid <= '1';
            -- dw_amt_bytes <= std_logic_vector(resize(address_2k,dw_amt_bytes'length));
            -- cur_block_state <=  BLOCK_STATE_DIRECT_RESET;
          -- end if;

          -- --A better way of doing this probably exists. However I wanted to
          -- --keep the pulse off next to where it is used. The dw_amt_valid
          -- --has to go out in the address_2k=0 case as well.
        -- when BLOCK_STATE_DIRECT_RESET       =>
          -- dw_amt_valid <= '0';
          -- cur_block_state <=  BLOCK_STATE_WAIT;

        -- when BLOCK_STATE_DIRECT_END =>
          -- dw_amt_valid <= '0';
          -- dw_en_internal <= '0';
          -- cur_block_state <= BLOCK_STATE_WAIT;


        --  Write out the oldest audio byte after previous write has
        --  been acknowledged.

        when BLOCK_STATE_AUDIO_PREFETCH =>

          flashblock_circbuffer_buffer_rd <= circbuffer_audio_select;
          flashblock_circbuffer_sample_rd <= std_logic_vector(circ_buffer_rd_audio);
          circ_buffer_rd_audio <= circ_buffer_rd_audio + 1;
          flashblock_circbuffer_rd_en_internal <= '1';
          cur_block_state   <= BLOCK_STATE_AUDIO_LAST ;

        when BLOCK_STATE_AUDIO_LAST   =>
          if (audio_written = '0' and
            audio_written_follower = '0') then
          --Depending on buffer level, write the audio word.
          --Might want to turn off rd_en by default in the upper process area.
          --Multiple states will possibly make use of rd_en.
           flashblock_circbuffer_rd_en_internal <= '0';

           byte_buffer (audio_word_bytes_g*num_mics_active_g*8-1 downto 0) <=
                circbuffer_flashblock_data_internal(audio_word_bytes_g*num_mics_active_g*8-1 downto 0) ;

            byte_number       <= TO_UNSIGNED (audio_word_bytes_g*num_mics_active_g,
                                              byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
            end_block_state   <= BLOCK_STATE_WAIT ;
            cur_block_state   <= BLOCK_STATE_BUFFER ;
            audio_seg_length  <= 
                    audio_seg_length + 
                    to_unsigned(audio_word_bytes_g*num_mics_active_g,
                    audio_seg_length'length) ;
            --For multibyte data you must go to BLOCK_STATE_BUFFER
            --and have it send the block byte ready!
            --block_byte_ready  <= '1' ;
            audio_written     <= '1' ;
          end if ;

        when BLOCK_STATE_SEG_AUD      =>
          cur_block_state   <= BLOCK_STATE_LEN_AUD ;
          block_byte        <= BLOCK_SEG_AUDIO ;
          block_byte_ready  <= '1' ;

        when BLOCK_STATE_LEN_AUD      =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (audio_seg_length) ;
          block_byte_ready  <= '1' ;
          audio_seg_length  <= (others => '0') ;


        when BLOCK_STATE_GYRO_PREFETCH      =>

          flashblock_circbuffer_buffer_rd <= circbuffer_gyro_select;
          flashblock_circbuffer_sample_rd <=
                                    std_logic_vector(circ_buffer_rd_gyro);
          circ_buffer_rd_gyro <= circ_buffer_rd_gyro + 1;
          flashblock_circbuffer_rd_en_internal <= '1';
          cur_block_state   <= BLOCK_STATE_GYRO ;



        when BLOCK_STATE_GYRO      =>

          flashblock_circbuffer_rd_en_internal <= '0';

          byte_buffer (IMU_GYRO_SEG_BYTES*8-1 downto 0) <=
                circbuffer_flashblock_data_internal(IMU_GYRO_SEG_BYTES*8-1 downto 0) ;

          byte_number       <= TO_UNSIGNED (IMU_GYRO_SEG_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;

          end_block_state   <= BLOCK_STATE_GYRO_SEG_ST ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;
          gyro_written     <= '1' ;



        --Append Gyro Segment Type Trailer
        when BLOCK_STATE_GYRO_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_GYRO_LEN_ST ;
          block_byte        <= BLOCK_SEG_IMU_GYRO ;
          block_byte_ready  <= '1' ;


        --Append Gyro Segment Length Trailer
        when BLOCK_STATE_GYRO_LEN_ST       =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (SEG_LEN_GYRO) ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_ACCEL_PREFETCH      =>

          flashblock_circbuffer_buffer_rd <= circbuffer_accel_select;
          flashblock_circbuffer_sample_rd <= std_logic_vector(circ_buffer_rd_accel);
          circ_buffer_rd_accel <= circ_buffer_rd_accel + 1;
          flashblock_circbuffer_rd_en_internal <= '1';
          cur_block_state   <= BLOCK_STATE_ACCEL ;

        when BLOCK_STATE_ACCEL       =>
          flashblock_circbuffer_rd_en_internal <= '0';
          byte_buffer (IMU_ACCEL_SEG_BYTES*8-1 downto 0) <=
          circbuffer_flashblock_data_internal(IMU_ACCEL_SEG_BYTES*8-1 downto 0) ;
          byte_number       <= TO_UNSIGNED (IMU_ACCEL_SEG_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_ACCEL_SEG_ST ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;
          accel_written     <= '1' ;

        when BLOCK_STATE_ACCEL_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_ACCEL_LEN_ST ;
          block_byte        <= BLOCK_SEG_IMU_ACCEL ;
          block_byte_ready  <= '1' ;


        --Append Gyro Segment Length Trailer
        when BLOCK_STATE_ACCEL_LEN_ST       =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (SEG_LEN_ACCEL) ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_MAG_PREFETCH      =>

          flashblock_circbuffer_buffer_rd <= circbuffer_mag_select;
          flashblock_circbuffer_sample_rd <= std_logic_vector(circ_buffer_rd_mag);
          circ_buffer_rd_mag <= circ_buffer_rd_mag + 1;
          flashblock_circbuffer_rd_en_internal <= '1';
          cur_block_state   <= BLOCK_STATE_MAG ;

        when BLOCK_STATE_MAG       =>
          flashblock_circbuffer_rd_en_internal <= '0';

          byte_buffer (IMU_MAG_SEG_BYTES*8-1 downto 0) <=
                circbuffer_flashblock_data_internal(IMU_MAG_SEG_BYTES*8-1 downto 0) ;
          byte_number       <= TO_UNSIGNED (IMU_MAG_SEG_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_MAG_SEG_ST ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;
          mag_written <= '1';


        when BLOCK_STATE_MAG_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_MAG_LEN_ST ;
          block_byte        <= BLOCK_SEG_IMU_MAG ;
          block_byte_ready  <= '1' ;


        --Append Gyro Segment Length Trailer
        when BLOCK_STATE_MAG_LEN_ST       =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (SEG_LEN_MAG) ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_TEMP_PREFETCH      =>

          flashblock_circbuffer_buffer_rd <= circbuffer_temp_select;
          flashblock_circbuffer_sample_rd <=
                                std_logic_vector(circ_buffer_rd_temp);
          circ_buffer_rd_temp <= circ_buffer_rd_temp + 1;
          flashblock_circbuffer_rd_en_internal <= '1';
          cur_block_state   <= BLOCK_STATE_TEMP ;

        when BLOCK_STATE_TEMP       =>
          flashblock_circbuffer_rd_en_internal <= '0';

          byte_buffer (IMU_TEMP_SEG_BYTES*8-1 downto 0) <=
                circbuffer_flashblock_data_internal(IMU_TEMP_SEG_BYTES*8-1 downto 0) ;
          byte_number       <= TO_UNSIGNED (IMU_TEMP_SEG_BYTES,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end_block_state   <= BLOCK_STATE_TEMP_SEG_ST ;
          cur_block_state   <= BLOCK_STATE_BUFFER ;
          temp_written    <= '1';

        when BLOCK_STATE_TEMP_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_TEMP_LEN_ST ;
          block_byte        <= BLOCK_SEG_IMU_TEMP ;
          block_byte_ready  <= '1' ;


        --Append Gyro Segment Length Trailer
        when BLOCK_STATE_TEMP_LEN_ST       =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (SEG_LEN_TEMP) ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_GPS_NAV_SOL_SETUP =>
          gps_req_out <= '1';
          if (gps_rec = '1') then
            gps_req_out <= '0';
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_FETCH;
            flashblock_gpsbuf_rd_en <= '1';
            gps_pos_written <= '1';
            flashblock_gpsbuf_addr_internal <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ubx_nav_sol_ramaddr_c +
                                            if_set (posbank,
                                                    msg_ubx_nav_sol_ramused_c),
                                            flashblock_gpsbuf_addr_internal'length) ;

            byte_number       <= TO_UNSIGNED (msg_ubx_nav_sol_ramused_c,
                               byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end if;

        when BLOCK_STATE_GPS_NAV_SOL_FETCH =>

          if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_POSTIME_SETUP ;
            flashblock_gpsbuf_rd_en <= '0';
            --Send the last byte.
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;

          else
            byte_count        <= byte_count + 1 ;
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ;

        when BLOCK_STATE_GPS_NAV_SOL_POSTIME_SETUP =>
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_POSTIME_FETCH;
            flashblock_gpsbuf_rd_en <= '1';
            flashblock_gpsbuf_addr_internal       <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ram_postime_addr_c +
                                            if_set (posbank,
                                            msg_ram_postime_size_c),
                                            flashblock_gpsbuf_addr_internal'length) ;

            byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                              byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;

        when BLOCK_STATE_GPS_NAV_SOL_POSTIME_FETCH =>

          if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_NAV_SOL_SEG_ST ;
            flashblock_gpsbuf_rd_en <= '0';
            --Send the last byte.
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;

          else
            byte_count        <= byte_count + 1 ;
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ;


        when BLOCK_STATE_NAV_SOL_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_NAV_SOL_LEN_ST ;
          block_byte        <= BLOCK_SEG_GPS_POSITION ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_NAV_SOL_LEN_ST       =>
          --cur_block_state   <= BLOCK_STATE_WAIT ;
          cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_ECEF_SETUP_W ;
          block_byte        <= STD_LOGIC_VECTOR (SEG_LEN_GPS_NAV_SOL) ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_GPS_NAV_SOL_ECEF_SETUP_W => 
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_ECEF_FETCH_W;
            flashblock_gpsbuf_rd_en <= '1';          
            flashblock_gpsbuf_addr_internal      <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ubx_nav_sol_ramaddr_c +
                                            if_set (posbank,
                                                    msg_ubx_nav_sol_ramused_c) + 
                                                    MUNSol_ecefX_offset_c,
                                            flashblock_gpsbuf_addr_internal'length) ;            
          
            byte_number       <= TO_UNSIGNED (MUNSol_ecefX_size_c + 
                                              MUNSol_ecefY_size_c + 
                                              MUNSol_ecefZ_size_c,
                                              byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          
        when BLOCK_STATE_GPS_NAV_SOL_ECEF_FETCH_W => 

          if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_ECEFACC_SETUP_W ;
            flashblock_gpsbuf_rd_en <= '0'; 
           
            navsol_ecefXYZ_reg   <= gpsbuf_flashblock_data & navsol_ecefXYZ_reg(navsol_ecefXYZ_reg'length-1 downto 8);
          else
            byte_count        <= byte_count + 1 ;
           
            navsol_ecefXYZ_reg   <= gpsbuf_flashblock_data & navsol_ecefXYZ_reg(navsol_ecefXYZ_reg'length-1 downto 8);
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ; 
          
          
        when BLOCK_STATE_GPS_NAV_SOL_ECEFACC_SETUP_W => 
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_ECEFACC_FETCH;
            flashblock_gpsbuf_rd_en <= '1';          
            flashblock_gpsbuf_addr_internal       <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ubx_nav_sol_ramaddr_c +
                                            if_set (posbank,
                                                    msg_ubx_nav_sol_ramused_c) + 
                                                    MUNSol_pAcc_offset_c,
                                            flashblock_gpsbuf_addr_internal'length) ;              
          
            byte_number       <= TO_UNSIGNED (MUNSol_pAcc_size_c,
                                              byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          
        when BLOCK_STATE_GPS_NAV_SOL_ECEFACC_FETCH => 

          if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_POSTIME_SETUP_W ;
            flashblock_gpsbuf_rd_en <= '0'; 

          navsol_pAcc_reg <= gpsbuf_flashblock_data & navsol_pAcc_reg(navsol_pAcc_reg'length-1 downto 8);    
            
          else
          byte_count        <= byte_count + 1 ;
          
          navsol_pAcc_reg <= gpsbuf_flashblock_data & navsol_pAcc_reg(navsol_pAcc_reg'length-1 downto 8);
                                                    
          
            
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ; 
          
          
          
          
        when BLOCK_STATE_GPS_NAV_SOL_POSTIME_SETUP_W => 
            cur_block_state   <= BLOCK_STATE_GPS_NAV_SOL_POSTIME_FETCH_W;
            flashblock_gpsbuf_rd_en <= '1';          
            flashblock_gpsbuf_addr_internal       <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ram_postime_addr_c +
                                            if_set (posbank,
                                            msg_ram_postime_size_c),
                                            flashblock_gpsbuf_addr_internal'length) ;           
          
            byte_number       <= TO_UNSIGNED (gps_time_bytes_c,
                                              byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          
        when BLOCK_STATE_GPS_NAV_SOL_POSTIME_FETCH_W => 

          if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_WAIT ;
            flashblock_gpsbuf_rd_en <= '0'; 

            
            nav_sol_time <= gpsbuf_flashblock_data & nav_sol_time(nav_sol_time'length-1-8 downto 0);
            
            
          else
            byte_count        <= byte_count + 1 ;
                       
            nav_sol_time <= gpsbuf_flashblock_data & nav_sol_time(nav_sol_time'length-1-8 downto 0);

            
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ; 
          


          
        when BLOCK_STATE_GPS_TIM_TM2_SETUP =>

        gps_req_out <= '1';
          if (gps_rec = '1') then
            gps_req_out <= '0';
            cur_block_state   <= BLOCK_STATE_GPS_TIM_TM2_FETCH;
            flashblock_gpsbuf_rd_en <= '1';
            gps_time_written <= '1';
            flashblock_gpsbuf_addr_internal     <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ubx_tim_tm2_ramaddr_c +
                                            if_set (tmbank,
                                                    msg_ubx_tim_tm2_ramused_c),
                                            flashblock_gpsbuf_addr_internal'length) ;

            byte_number       <= TO_UNSIGNED (msg_ubx_tim_tm2_ramused_c,
                                              byte_number'length) ;
            byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
          end if;


        when BLOCK_STATE_GPS_TIM_TM2_FETCH =>

         if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_GPS_TIM_TM2_MARKTIME_SETUP ;
            flashblock_gpsbuf_rd_en <= '0';
            --Send the last byte.
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;

          else
            byte_count        <= byte_count + 1 ;
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ;

        when BLOCK_STATE_GPS_TIM_TM2_MARKTIME_SETUP =>

          cur_block_state   <= BLOCK_STATE_GPS_TIM_TM2_MARKTIME_FETCH;
          flashblock_gpsbuf_rd_en <= '1';
          flashblock_gpsbuf_addr_internal       <= TO_UNSIGNED (msg_ram_base_c +
                                          msg_ram_marktime_addr_c +
                                          if_set (tmbank,
                                          msg_ram_marktime_size_c),
                                          flashblock_gpsbuf_addr_internal'length) ;

          byte_number       <= TO_UNSIGNED (msg_ram_marktime_size_c,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (1, byte_count'length) ;

        when BLOCK_STATE_GPS_TIM_TM2_MARKTIME_FETCH =>

          if (byte_count = byte_number) then
            cur_block_state   <= BLOCK_STATE_TIM_TM2_SEG_ST ;
            flashblock_gpsbuf_rd_en <= '0';
            --Send the last byte.
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;

          else
            byte_count        <= byte_count + 1 ;
            block_byte_ready  <= '1' ;
            block_byte        <= gpsbuf_flashblock_data ;
            flashblock_gpsbuf_addr_internal <= flashblock_gpsbuf_addr_internal + 1;
          end if ;


        when BLOCK_STATE_TIM_TM2_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_TIM_TM2_LEN_ST ;
          block_byte        <= BLOCK_SEG_GPS_TIME_MARK ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_TIM_TM2_LEN_ST       =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (SEG_LEN_GPS_TIM_TM2) ;
          block_byte_ready  <= '1' ;

        when BLOCK_STATE_EVENTS_SETUP =>
          flashblock_counter_lock <= '1';
          flashblock_counter_rd_en <= '1';
          cur_block_state   <= BLOCK_STATE_EVENTS_FETCH;

        when BLOCK_STATE_EVENTS_INCREMENT =>
          flashblock_counter_rd_en <= '1';
          flashblock_counter_wr_en <= '0';
          cur_block_state   <= BLOCK_STATE_EVENTS_FETCH ;
          flashblock_counter_rd_wr_addr_internal <=
                            flashblock_counter_rd_wr_addr_internal + 1;



        when BLOCK_STATE_EVENTS_FETCH =>
          flashblock_counter_rd_en <= '0';
          flashblock_counter_wr_en <= '0';

          --If we can't fit an event, a trailer, and a min pad, then cap
          -- the current segment.
          if (block_bytes_left >=  (EVENT_SAMPLE_BYTES +
                                  SEG_TRAILER_SIZE +
                                  PAD_SEG_MIN_SIZE)) then


            if (events_checked = to_unsigned(counters_g,events_checked'length)) then
              --All the events defined have been checked. Reset counter.
              cur_block_state   <= BLOCK_STATE_EVENTS_SEG_ST ;
              flashblock_counter_rd_wr_addr_internal       <= (others => '0')  ;
              events_written       <= '1' ;
              events_checked <= (others => '0') ;


            elsif (counter_flashblock_data = std_logic_vector(
                      to_unsigned(0,counter_flashblock_data'length))) then
              --The counter is zero, proceed on.
              flashblock_counter_rd_wr_addr_internal <= flashblock_counter_rd_wr_addr_internal + 1;
              flashblock_counter_rd_en <= '1';
              events_checked <= events_checked + 1;

            else
              --The counter is not zero. Store the counter position and
              --its value. Also zero it.
              events_seg_length <= events_seg_length + 2;
              events_checked <= events_checked + 1;
              byte_buffer (EVENT_SAMPLE_BYTES*8-1 downto 0) <=
                                         counter_flashblock_data &
                                         std_logic_vector(
                                         flashblock_counter_rd_wr_addr_internal(
                                         7 downto 0)) ;
              byte_number       <= TO_UNSIGNED (EVENT_SAMPLE_BYTES,byte_number'length) ;
              byte_count        <= TO_UNSIGNED (1, byte_count'length) ;


              flashblock_counter_wr_en <= '1';
              --flashblock_counter_wr_addr_internal <= flashblock_counter_rd_addr_internal;
              flashblock_counter_data <=  (others => '0') ;




              end_block_state   <= BLOCK_STATE_EVENTS_INCREMENT ;
              cur_block_state   <= BLOCK_STATE_BUFFER ;

            end if;
          else
            cur_block_state   <= BLOCK_STATE_EVENTS_SEG_ST ;
            flashblock_counter_lock <= '0';
          end if;



        when BLOCK_STATE_EVENTS_SEG_ST       =>
          cur_block_state   <= BLOCK_STATE_EVENTS_LEN_ST ;
          block_byte        <= BLOCK_SEG_EVENT ;
          block_byte_ready  <= '1' ;


        when BLOCK_STATE_EVENTS_LEN_ST       =>
          cur_block_state   <= BLOCK_STATE_WAIT ;
          block_byte        <= STD_LOGIC_VECTOR (events_seg_length) ;
          block_byte_ready  <= '1' ;
          events_seg_length <= (others => '0') ;


        end case ;

      end if ;
    end if;
  end if ;

end process send_block_item ;



--
--Item state controls most flow of block formation.
--This state machine does many things which include: watching
--for segment insert interrupt bits, checking space for new segments
--branching accordingly.
--
--


send_item:  process (clock_sys, rst_n)
begin
  if (rst_n = '0') then
    cur_item_state        <= ITEM_STATE_STARTUP_WAIT ;
    next_item_state       <= ITEM_STATE_WAIT ;
    end_item_state        <= ITEM_STATE_WAIT ;
    next_block_state      <= BLOCK_STATE_WAIT ;
    write_status_follower <= '0' ;
    audio_data_write_follower <= '0';
    block_seqno           <= (others => '0') ;
    startup_done          <= '0';


    byte_count_i          <= (others => '0') ;
    byte_number_i         <= (others => '0') ;

  elsif (clock_sys'event and clock_sys = '1') then
    if (clk_enable) = '1' then

    --Wait until the block item process is idle before starting another
    --item send.
    --A lag between next_block_state reaching cur_block_state requires
    --us to check that no next_block_state is queued.

    --Always return here when off send_block_item is engaged.
    --Wait until the previous block is serviced AND count updated before
    --continuing.
      if cur_block_state /= BLOCK_STATE_WAIT or block_byte_ready = '1'  then
        next_block_state    <= BLOCK_STATE_WAIT ;
      else

      --  Send another item.

      case cur_item_state is

        --  Wait until no actions are in progress.

        when ITEM_STATE_PAUSE =>
          cur_item_state <= next_item_state;
          
          
        when ITEM_STATE_STARTUP_WAIT =>
          if (startup_in = '1') then
            cur_item_state      <= ITEM_STATE_WAIT ;
          end if;

        when ITEM_STATE_WAIT          =>

          --  Start a new block.
          if (startup_done = '0') then
             cur_item_state      <= ITEM_STATE_LOGIC_BLOCK_FETCH_SETUP ;

          elsif (block_bytes_left = BLOCK_SIZE) then
            cur_item_state    <= ITEM_STATE_NEW_BLOCK ;

          elsif(crit_event_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then

                bytes_needed        <= TO_UNSIGNED (STATUS_SEG_BYTES,
                                                      bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_FORCE ;
              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;

              end if ;
            end if;


          elsif(empty_done = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                and next_block_state = BLOCK_STATE_WAIT) then
              -- if (audio_seg_length = 0) then

                -- bytes_needed        <= TO_UNSIGNED (STATUS_SEG_BYTES,
                                                      -- bytes_needed'length) ;
                -- cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
              cur_item_state      <= ITEM_STATE_FORCE_DONE ;
              -- else
                -- cur_item_state      <= ITEM_STATE_AUDIO_END ;

            end if ;
            --end if;

          elsif (events_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                and next_block_state = BLOCK_STATE_WAIT) then
                    if (audio_seg_length = 0) then

                    bytes_needed        <= TO_UNSIGNED (EVENT_SAMPLE_BYTES,
                                                        bytes_needed'length) ;

                    cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                    end_item_state      <= ITEM_STATE_EVENTS ;

                    else
                     cur_item_state      <= ITEM_STATE_AUDIO_END ;

                    end if ;

            end if;


          --The interrupt is left high until it is serviced.
          elsif (audio_data_write = '1') then
            --Only proceed if we REALLY are in BLOCK_STATE_WAIT
           if (cur_block_state = BLOCK_STATE_WAIT
                                and next_block_state = BLOCK_STATE_WAIT) then

            --This path will never run.
            if (audio_seg_length /= 0 and block_bytes_left  = SEG_TRAILER_SIZE) then

              bytes_needed        <= TO_UNSIGNED (audio_word_bytes_g*num_mics_active_g,
                                      bytes_needed'length) ;

              cur_item_state      <= ITEM_STATE_AUDIO_END ;

              --If the audio block is at its max length of 255, cap it.
              --to_unsigned(,+1) to avert the overflow.
              elsif ((to_unsigned(audio_word_bytes_g*num_mics_active_g,audio_seg_length'length+1)
                    + audio_seg_length) > 255) then
                cur_item_state        <= ITEM_STATE_AUDIO_END ;

              else
                bytes_needed        <= TO_UNSIGNED (audio_word_bytes_g*num_mics_active_g,
                                  bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_AUDIO_BYTE ;
              end if ;
            end if;


          elsif (gyro_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then

                bytes_needed        <= TO_UNSIGNED (IMU_GYRO_SEG_BYTES,
                                                    bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_GYRO ;

              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;
              end if ;

            end if;





          elsif (accel_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                  and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then

                bytes_needed        <= TO_UNSIGNED (IMU_ACCEL_SEG_BYTES,
                                                  bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_ACCEL ;

              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;
              end if ;
            end if;

          elsif (mag_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                  and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then
                bytes_needed        <= TO_UNSIGNED (IMU_MAG_SEG_BYTES,
                                                  bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_MAG ;
              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;

              end if ;
            end if;


          elsif (temp_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT
                                and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then

                bytes_needed        <= TO_UNSIGNED (IMU_TEMP_SEG_BYTES,
                                                    bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_TEMP ;

              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;

              end if ;
            end if;

          elsif (gps_pos_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then

                bytes_needed        <= TO_UNSIGNED (GPS_NAV_SOL_BYTES,
                                                bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_GPS_POS ;

              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;

              end if ;
            end if;

          elsif (gps_time_data_write = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then
                
                bytes_needed        <= TO_UNSIGNED (GPS_TIM_TM2_BYTES,
                                                    bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_GPS_TIME_MARK ;
                
              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;

              end if ;
            end if;

          elsif (write_status = '1') then
            if (cur_block_state = BLOCK_STATE_WAIT and next_block_state = BLOCK_STATE_WAIT) then
              if (audio_seg_length = 0) then

                bytes_needed        <= TO_UNSIGNED (STATUS_SEG_BYTES,
                                                    bytes_needed'length) ;
                cur_item_state      <= ITEM_STATE_CHECK_SPACE ;
                end_item_state      <= ITEM_STATE_STATUS ;

              else
                cur_item_state      <= ITEM_STATE_AUDIO_END ;

              end if ;

            end if;
          end if ;

        --  Terminate the current block if there is no room
        --  for the needed space.

        when ITEM_STATE_CHECK_SPACE   =>
          if (block_bytes_left >=  bytes_needed + SEG_TRAILER_SIZE + PAD_SEG_MIN_SIZE) --or
             --block_bytes_left >= bytes_needed + SEG_TRAILER_SIZE +
                                                --PAD_SEG_MIN_SIZE
                                                then
            cur_item_state        <= end_item_state ;

            --If an audio segment is open we need to close it.



          else
            cur_item_state        <= ITEM_STATE_PAUSE ;
            next_item_state        <= ITEM_STATE_PADDING_END ;

            if (audio_seg_length /= 0) then
              next_block_state    <= BLOCK_STATE_SEG_AUD ;
            end if ;
          end if ;

        --  Add an audio byte to the block.

        when ITEM_STATE_AUDIO_BYTE    =>


          cur_item_state          <= ITEM_STATE_PAUSE ;
          next_item_state         <= ITEM_STATE_WAIT;

          next_block_state  <=  BLOCK_STATE_AUDIO_PREFETCH;


        --  End the block with an audio segment.

        when ITEM_STATE_AUDIO_END     =>
          cur_item_state          <= ITEM_STATE_WAIT ;
          next_block_state        <= BLOCK_STATE_SEG_AUD ;

        --  End the block with padding segments.

        when ITEM_STATE_PADDING_END   =>
          next_block_state        <= BLOCK_STATE_PADDING ;


          if (block_bytes_left > PAD_SEG_MAX_LENGTH + SEG_TRAILER_SIZE) then
            block_padding_length  <= TO_UNSIGNED (PAD_SEG_MAX_LENGTH,
                                                  block_padding_length'length) ;
          else

                cur_item_state        <= ITEM_STATE_WAIT ;
                block_padding_length  <=
                  --Padding Segment Trailer ALWAYS at end of block.
                    block_bytes_left (block_padding_length'length-1 downto 0) -
                    SEG_TRAILER_SIZE ;    --  Keep the compiler from complaining
                                          --  that the number is too big to fit.
          end if ;

        --  Write out the status segment and store the logical block.

        when ITEM_STATE_STATUS        =>
          --cur_item_state          <= ITEM_STATE_WAIT ;
          last_seqno              <= std_logic_vector(block_seqno);
          cur_item_state          <= ITEM_STATE_LOGIC_BLOCK_STORE_SETUP ;
          next_block_state        <= BLOCK_STATE_STATUS_COMPILE ;

        when ITEM_STATE_GYRO        =>
          cur_item_state          <= ITEM_STATE_WAIT ;
          next_block_state        <= BLOCK_STATE_GYRO_PREFETCH ;

        when ITEM_STATE_ACCEL        =>
          cur_item_state          <= ITEM_STATE_WAIT ;
          next_block_state        <= BLOCK_STATE_ACCEL_PREFETCH ;

        when ITEM_STATE_MAG        =>
          cur_item_state          <= ITEM_STATE_WAIT ;
          next_block_state        <= BLOCK_STATE_MAG_PREFETCH ;

        when ITEM_STATE_TEMP        =>
          cur_item_state          <= ITEM_STATE_WAIT ;
          next_block_state        <= BLOCK_STATE_TEMP_PREFETCH ;

        --  Start a new block.

          --I insert extra pause state here to give cur_block_state
          --time to transition and keep us from triggering ITEM_STATE_NEW_BLOCK
          --twice.
        when ITEM_STATE_NEW_BLOCK     =>
          cur_item_state          <= ITEM_STATE_PAUSE ;
          --next_item_state         <= end_item_state;
          next_item_state         <= ITEM_STATE_WAIT;
          next_block_state        <= BLOCK_STATE_SEQNO ;
          block_seqno             <= block_seqno + 1 ;


        when ITEM_STATE_GPS_POS     =>
          cur_item_state          <= ITEM_STATE_PAUSE ;
          --next_item_state         <= end_item_state;
          next_item_state         <= ITEM_STATE_WAIT;
          next_block_state        <= BLOCK_STATE_GPS_NAV_SOL_SETUP ;

        when ITEM_STATE_GPS_TIME_MARK     =>
          cur_item_state          <= ITEM_STATE_PAUSE ;
          --next_item_state         <= end_item_state;
          next_item_state         <= ITEM_STATE_WAIT;
          next_block_state        <= BLOCK_STATE_GPS_TIM_TM2_SETUP ;

        when ITEM_STATE_EVENTS    =>
          cur_item_state          <= ITEM_STATE_PAUSE ;
          --next_item_state         <= end_item_state;
          next_item_state         <= ITEM_STATE_WAIT;
          next_block_state        <= BLOCK_STATE_EVENTS_SETUP ;


       when ITEM_STATE_FORCE_DONE    =>
          cur_item_state          <= ITEM_STATE_PAUSE ;
          --next_item_state         <= end_item_state;
          next_item_state         <= ITEM_STATE_WAIT;
          next_block_state        <= BLOCK_STATE_FORCE_DONE ;

        --Here we jump into BLOCK_STATE_COMPILE. We'll check for
        --crit_event flag later once status segment is built.
        when ITEM_STATE_FORCE    =>
          cur_item_state          <= ITEM_STATE_PAUSE ;
          --next_item_state         <= end_item_state;
          next_item_state         <= ITEM_STATE_WAIT;
          next_block_state        <= BLOCK_STATE_STATUS_COMPILE ;

        -- --Below are the states to retrieve and store the logical
        -- --block address number to magnetic memory buffer. 

        when ITEM_STATE_LOGIC_BLOCK_FETCH_SETUP =>
          mem_req_a_out     <= '1';
          if (mem_rec_a = '1') then
            cur_item_state <= ITEM_STATE_LOGIC_BLOCK_FETCH;
          end if;

          fb_magram_address_a     <= TO_UNSIGNED (logical_block_location_c,
                                          fb_magram_address_a'length) ;

          byte_number_i       <= TO_UNSIGNED (logical_block_length_bytes_c,
                                            byte_number_i'length) ;
          byte_count_i        <= TO_UNSIGNED (0, byte_count_i'length) ;
          startup_done      <= '1';
          fb_magram_rd_en_a_out <= '1';




        when ITEM_STATE_LOGIC_BLOCK_FETCH =>

          if (byte_count_i = byte_number_i) then
            cur_item_state   <= ITEM_STATE_WAIT ;
            block_seqno <= unsigned(last_seqno);
            mem_req_a_out     <= '0';
            fb_magram_rd_en_a_out <= '0';
          else
          --The 4 bytes value is stored little endian.
            fb_magram_rd_en_a_out <= '1';
            last_seqno    <=  magram_fb_q_a_in
            & last_seqno(31 downto 8);
            byte_count_i        <= byte_count_i + 1 ;
            fb_magram_address_a <= fb_magram_address_a + 1;
          end if ;

      when ITEM_STATE_LOGIC_BLOCK_STORE_SETUP =>

        mem_req_a_out     <= '1';
        if (mem_rec_a = '1') then
          cur_item_state <= ITEM_STATE_LOGIC_BLOCK_STORE;
        else
        fb_magram_wr_en_a_out <= '1';
        fb_magram_address_a   <= TO_UNSIGNED (logical_block_location_c,
                                            fb_magram_address_a'length) ;
        byte_number_i       <= TO_UNSIGNED (logical_block_length_bytes_c,
                                          byte_number'length) ;

        byte_count_i        <= TO_UNSIGNED (1, byte_count'length) ;

        fb_magram_data_a_out <=  last_seqno(7 downto 0);

        last_seqno <= x"00" & last_seqno(31 downto 8);
        end if;

      when ITEM_STATE_LOGIC_BLOCK_STORE =>
        if (byte_count_i = byte_number_i) then
          cur_item_state   <= ITEM_STATE_WAIT ;
          mem_req_a_out     <= '0';
          fb_magram_wr_en_a_out <= '0';
        else
          fb_magram_wr_en_a_out <= '1';
        --The 4 bytes value is stored little endian.
          fb_magram_data_a_out <=  last_seqno(7 downto 0);
          last_seqno <= x"00" & last_seqno(31 downto 8);
          byte_count_i        <= byte_count_i + 1 ;
          fb_magram_address_a <= fb_magram_address_a + 1;
        end if ;





      end case ;
    end if ;
  end if ;
  end if;
end process send_item ;


--Update the wireless packet. On go, latch in all values from all domains.
--along with the GPS time, then assemble the wireless packet. 

--Synchronize all signals into this domain. 
--_s signals are set_false_path into the TCL files of thei project. 
--Latch all signals upon starting to build the packet. 
--Build the packet. 
update_wp:  process (clock_sys, rst_n)
begin
  if rst_n = '0' then

    sdxc_serial_reg           <= (others => '0');
    sdxc_block_reg            <= (others => '0');
    voltage_mv_reg            <= (others => '0');
    rem_cap_mah_reg           <= (others => '0');
    inst_cur_ma_reg           <= (others => '0');
    rtc_reg                   <= (others => '0');

    sdxc_serial_push            <= (others => '0'); 
    current_FPGA_time_push      <= (others => '0');
    sdxc_block_push             <= (others => '0');
    voltage_mv_push             <= (others => '0');
    rem_cap_mah_push            <= (others => '0');
    inst_cur_ma_push            <= (others => '0');
    rtc_push                    <= (others => '0');

    sdxc_serial_reg_s           <= (others => '0');

    sdxc_block_reg_s            <= (others => '0');
    voltage_mv_reg_s            <= (others => '0');
    rem_cap_mah_reg_s           <= (others => '0');
    inst_cur_ma_reg_s           <= (others => '0');
    rtc_reg_s                   <= (others => '0');


    control_register_s    <= (others => '0');
    control_register      <= (others => '0');
    control_register_push  <= (others => '0');
                           
    navsol_ecefXYZ_push      <= (others => '0');
                                
    navsol_pAcc_reg_push  <= (others => '0');           
    nav_sol_time_push    <= (others => '0');           
    
    wp_written <= '0';
    txrx_bank <= '0';
    txrx_req_a_out     <= '0';
    
    fb_txrx_wr_en_a_out  <= '0';
    fb_txrx_rd_en_a_out  <= '0';
    
  elsif (clock_sys'event and clock_sys = '0') then

    sdxc_serial_reg     <=    sdxc_serial_reg_s;                
    sdxc_block_reg      <=    sdxc_block_reg_s;           
    voltage_mv_reg      <=    voltage_mv_reg_s;           
    rem_cap_mah_reg     <=    rem_cap_mah_reg_s;         
    inst_cur_ma_reg     <=    inst_cur_ma_reg_s;          
    rtc_reg             <=    rtc_reg_s;  
    control_register    <=    control_register_s;

  elsif (clock_sys'event and clock_sys = '1') then
  
    sdxc_serial_reg_s           <= sdxc_serial_in ;
    sdxc_block_reg_s            <= sdxc_block_in ;
    voltage_mv_reg_s            <= voltage_mv_in ;
    rem_cap_mah_reg_s           <= rem_cap_mah_in ;
    inst_cur_ma_reg_s           <= inst_cur_ma_in ;
    rtc_reg_s                   <= rtc_time_s ;
    control_register_s          <= pc_controlreg_in;
    
    
    if (clk_enable) = '1' then
      case cur_packet_state is
    
    
      when PACKETSTATE_WAIT =>
      
      if (write_wp = '1') then 
        cur_packet_state <= PACKETSTATE_REQ;
      end if;
      
      when PACKETSTATE_REQ =>
        txrx_req_a_out     <= '1';
        
        sdxc_serial_push     <=    sdxc_serial_reg;                 
        sdxc_block_push      <=    sdxc_block_reg;           
        voltage_mv_push      <=    voltage_mv_reg;           
        rem_cap_mah_push     <=    rem_cap_mah_reg;         
        inst_cur_ma_push     <=    inst_cur_ma_reg;          
        rtc_push         <=    rtc_reg;  
        current_FPGA_time_push  <= current_FPGA_time;
        navsol_pAcc_reg_push <= navsol_pAcc_reg;
        navsol_ecefXYZ_push <= navsol_ecefXYZ_reg;
        nav_sol_time_push <= nav_sol_time;
        control_register_push(control_register'length-1 downto 0) <=  control_register;
         

        if ( txrx_rec_a_in = '1') then 
          cur_packet_state <= PACKETSTATE_SERIAL_SETUP;
        end if; 

        
        
      when PACKETSTATE_SERIAL_SETUP =>
        --Leave wr_en on till end of packet.
        fb_txrx_wr_en_a_out <= '1';
        
        cur_packet_state <= PACKETSTATE_SERIAL;

        fb_txrx_address_a   <= TO_UNSIGNED (microsd_serial_location_c,
                                            fb_txrx_address_a'length) ;            
        byte_number_w       <= TO_UNSIGNED (microsd_serial_length_bytes_c,
                                          byte_number_w'length) ;
                                          
        byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
        
        fb_txrx_data_a_out  <=  sdxc_serial_push(7 downto 0); 
        
        sdxc_serial_push <= x"00" & sdxc_serial_push(31 downto 8);
          

      
      when PACKETSTATE_SERIAL =>
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_RTC_SETUP ;
        else

          fb_txrx_data_a_out <=  sdxc_serial_push(7 downto 0); 
          sdxc_serial_push <= x"00" & sdxc_serial_push(31 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;

        
        
        
        
      when PACKETSTATE_RTC_SETUP =>
      
          cur_packet_state <= PACKETSTATE_RTC;

          fb_txrx_address_a   <= TO_UNSIGNED (rtc_time_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (rtc_time_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  rtc_push(7 downto 0); 
          
          rtc_push <= x"00" & rtc_push(rtc_push'length-1 downto 8);   
        
        
        when PACKETSTATE_RTC =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_GPSTIME_SETUP ;
        else

          fb_txrx_data_a_out <=  rtc_push(7 downto 0); 
          rtc_push <= x"00" & rtc_push(rtc_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
      when PACKETSTATE_GPSTIME_SETUP =>
      
       cur_packet_state <= PACKETSTATE_GPSTIME;

        fb_txrx_address_a   <= TO_UNSIGNED (packet_gen_time_location_c,
                                            fb_txrx_address_a'length) ;            
        byte_number_w       <= TO_UNSIGNED (packet_gen_time_length_bytes_c,
                                          byte_number_w'length) ;
                                          
        byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
        
        fb_txrx_data_a_out  <=  current_FPGA_time_push(7 downto 0); 
        
        current_FPGA_time_push <= x"00" & current_FPGA_time_push(current_FPGA_time_push'length-1 downto 8);  
        
        
      when PACKETSTATE_GPSTIME =>
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_VOLTAGE_SETUP ;
        else

          fb_txrx_data_a_out <=  current_FPGA_time_push(7 downto 0); 
          current_FPGA_time_push <= x"00" & current_FPGA_time_push(current_FPGA_time_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;


        
        when PACKETSTATE_VOLTAGE_SETUP =>
      
        cur_packet_state <= PACKETSTATE_VOLTAGE;

        fb_txrx_address_a   <= TO_UNSIGNED (battery_voltage_location_c,
                                            fb_txrx_address_a'length) ;            
        byte_number_w       <= TO_UNSIGNED (battery_voltage_length_bytes_c,
                                          byte_number_w'length) ;
                                          
        byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
        
        fb_txrx_data_a_out  <=  voltage_mv_push(7 downto 0); 
        
        voltage_mv_push <= x"00" & voltage_mv_push(voltage_mv_push'length-1 downto 8);  
        

        when PACKETSTATE_VOLTAGE =>

        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_CAP_SETUP ;
        else

          fb_txrx_data_a_out <=  voltage_mv_push(7 downto 0); 
          voltage_mv_push <= x"00" & voltage_mv_push(voltage_mv_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
        when PACKETSTATE_CURRENT_SETUP =>
      
          cur_packet_state <= PACKETSTATE_CURRENT;

          fb_txrx_address_a   <= TO_UNSIGNED (battery_current_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (battery_current_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  inst_cur_ma_push(7 downto 0); 
          
          inst_cur_ma_push <= x"00" & inst_cur_ma_push(inst_cur_ma_push'length-1 downto 8);   
        
        
        when PACKETSTATE_CURRENT =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_SDBLOCK_SETUP ;
        else

          fb_txrx_data_a_out <=  inst_cur_ma_push(7 downto 0); 
          inst_cur_ma_push <= x"00" & inst_cur_ma_push(inst_cur_ma_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
        when PACKETSTATE_CAP_SETUP =>
      
          cur_packet_state <= PACKETSTATE_CAP;

          fb_txrx_address_a   <= TO_UNSIGNED (battery_capacity_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (battery_capacity_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  rem_cap_mah_push(7 downto 0); 
          
          rem_cap_mah_push <= x"00" & rem_cap_mah_push(rem_cap_mah_push'length-1 downto 8);   
        
        
        when PACKETSTATE_CAP =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_CURRENT_SETUP ;
        else

          fb_txrx_data_a_out <=  rem_cap_mah_push(7 downto 0); 
          rem_cap_mah_push <= x"00" & rem_cap_mah_push(rem_cap_mah_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        when PACKETSTATE_SDBLOCK_SETUP =>
      
          cur_packet_state <= PACKETSTATE_SDBLOCK;

          fb_txrx_address_a   <= TO_UNSIGNED (microsd_last_block_written_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (microsd_last_block_written_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  sdxc_block_push(7 downto 0); 
          
          sdxc_block_push <= x"00" & sdxc_block_push(sdxc_block_push'length-1 downto 8);   
        
        
        when PACKETSTATE_SDBLOCK =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_ECEF_SETUP ;
        else

          fb_txrx_data_a_out <=  sdxc_block_push(7 downto 0); 
          sdxc_block_push <= x"00" & sdxc_block_push(sdxc_block_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
        when PACKETSTATE_ECEF_SETUP =>
      
          cur_packet_state <= PACKETSTATE_ECEF;

          fb_txrx_address_a   <= TO_UNSIGNED (gps_pos_ecef_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (gps_pos_ecef_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  navsol_ecefXYZ_push(7 downto 0); 
          
          navsol_ecefXYZ_push <= x"00" & navsol_ecefXYZ_push(navsol_ecefXYZ_push'length-1 downto 8);   
        
        
        when PACKETSTATE_ECEF =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_GPSACC_SETUP ;
        else

          fb_txrx_data_a_out <=  navsol_ecefXYZ_push(7 downto 0); 
          navsol_ecefXYZ_push <= x"00" & navsol_ecefXYZ_push(navsol_ecefXYZ_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
        when PACKETSTATE_GPSACC_SETUP =>
      
          cur_packet_state <= PACKETSTATE_GPSACC;

          fb_txrx_address_a   <= TO_UNSIGNED (gps_accuracy_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (gps_accuracy_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  navsol_pAcc_reg_push(7 downto 0); 
          
          navsol_pAcc_reg_push <= x"00" & navsol_pAcc_reg_push(navsol_pAcc_reg_push'length-1 downto 8);   
        
        
        when PACKETSTATE_GPSACC =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_NAVSOLTIME_SETUP ;
        else

          fb_txrx_data_a_out <=  navsol_pAcc_reg_push(7 downto 0); 
          navsol_pAcc_reg_push <= x"00" & navsol_pAcc_reg_push(navsol_pAcc_reg_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
        when PACKETSTATE_NAVSOLTIME_SETUP =>
      
          cur_packet_state <= PACKETSTATE_NAVSOLTIME;

          fb_txrx_address_a   <= TO_UNSIGNED (gps_pos_time_location_c,
                                              fb_txrx_address_a'length) ;            
          byte_number_w       <= TO_UNSIGNED (gps_pos_time_length_bytes_c,
                                            byte_number_w'length) ;
                                            
          byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
          
          fb_txrx_data_a_out  <=  nav_sol_time_push(7 downto 0); 
          
          nav_sol_time_push <= x"00" & nav_sol_time_push(nav_sol_time_push'length-1 downto 8);   
        
        
        when PACKETSTATE_NAVSOLTIME =>
        
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_FPGACONTROL_SETUP ;
        else

          fb_txrx_data_a_out <=  nav_sol_time_push(7 downto 0); 
          nav_sol_time_push <= x"00" & nav_sol_time_push(nav_sol_time_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
        
      when PACKETSTATE_FPGACONTROL_SETUP =>
      
        cur_packet_state <= PACKETSTATE_FPGACONTROL;

        fb_txrx_address_a   <= TO_UNSIGNED (control_register_location_c,
                                            fb_txrx_address_a'length) ;            
        byte_number_w       <= TO_UNSIGNED (control_register_length_bytes_c,
                                          byte_number_w'length) ;
                                          
        byte_count_w        <= TO_UNSIGNED (1, byte_count'length) ;
        
        fb_txrx_data_a_out  <=  control_register_push(7 downto 0); 
        
        control_register_push <= x"00" & control_register_push(control_register_push'length-1 downto 8);  
        
        
      when PACKETSTATE_FPGACONTROL =>
        if (byte_count_w = byte_number_w) then
          cur_packet_state   <= PACKETSTATE_FLIPBANK ;
        else

          fb_txrx_data_a_out <=  control_register_push(7 downto 0); 
          control_register_push <= x"00" & control_register_push(control_register_push'length-1 downto 8);
          byte_count_w        <= byte_count_w + 1 ;
          fb_txrx_address_a <= fb_txrx_address_a + 1;
        end if ;
        
        
      when PACKETSTATE_FLIPBANK =>
        fb_txrx_wr_en_a_out <= '0';
        cur_packet_state   <= PACKETSTATE_WAIT ;
        txrx_bank <= not txrx_bank;
        txrx_req_a_out     <= '0';
        wp_written <= '1';
        
    
    
      end case ;
    end if;
    end if;
end process update_wp ;
--
--Determine when a status segment should be written.
--Initiate a status segment write when requested.
--This process also initiates handling critical events in
--

update_status:  process (clock_sys, rst_n)
begin
  if rst_n = '0' then
    log_status_follower     <= '0' ;
    write_status            <= '0' ;
    status_written_follower <= '0';
    crit_event_write <= '0';
    crit_event_follower <= '0';
    crit_event_written_follower <= '0';
    

    status_up_counter  <= (others => '0');
    
  elsif clock_sys'event and clock_sys = '1' then
    if (clk_enable) = '1' then
    status_up_counter <= status_up_counter + 1;
    
      if (status_written_follower /= status_written) then
        status_written_follower <= status_written;
        if(status_written = '1') then
          write_status          <= '0' ;
        end if;
      elsif (log_status_follower /= log_status) then
        log_status_follower   <= log_status ;
          if log_status = '1' then
            write_status        <= '1' ;
          end if ;
          
          --Modelsim Test--
      -- elsif( status_up_counter = to_unsigned(400,
                                                -- status_up_counter'length)) then
          -- write_status        <= '1' ;
        -- status_up_counter <= (others => '0');
          --Modelsim Test--
      elsif( status_up_counter = to_unsigned(status_up_count,
                                                status_up_counter'length)) then
        write_status        <= '1';
        status_up_counter <= (others => '0');
      end if ;

      if (crit_event_written_follower /= crit_event_written) then
        crit_event_written_follower <= crit_event_written;
          if(crit_event_written = '1') then
            crit_event_write          <= '0' ;
          end if;
      elsif (crit_event_follower /= crit_event) then
        crit_event_follower   <= crit_event ;
        if (crit_event = '1') then
          crit_event_write          <= '1' ;
        end if ;
      end if ;
    end if ;
  end if;
end process update_status ;


-- Signal Wireless Packet Update at interval.
update_wireless_p:  process (clock_sys, rst_n)
begin
  if (rst_n) = '0' then
    write_wp      <= '0' ;
    wp_written_follower <= '0';
    wpacket_up_counter <= (others => '0');
  elsif clock_sys'event and clock_sys = '1' then
      if (clk_enable) = '1' then
          wpacket_up_counter <= wpacket_up_counter + 1;
        if (wp_written_follower /= wp_written) then
          wp_written_follower <= wp_written;
          if(wp_written = '1') then
            write_wp          <= '0' ;
          end if;
      
            -- --Modelsim Test--
        -- elsif( wpacket_up_counter = to_unsigned(400,
                                                  -- wpacket_up_counter'length)) then
          -- write_wp        <= '1' ;
          -- wpacket_up_counter <= (others => '0');
            --Modelsim Test--
        elsif( wpacket_up_counter = to_unsigned(wpacket_up_count,
                                                  wpacket_up_counter'length)) then
          write_wp        <= '1' ;
          wpacket_up_counter <= (others => '0');
        end if ;      
      end if ;
    end if;
end process update_wireless_p ;


  
--
--
--Handle events trigger.
--Do not deassert interrupt until serviced.
--
--


handle_events:  process (clock_sys, rst_n)
  begin
    if rst_n = '0' then

      events_data_write             <= '0' ;
      events_written_follower       <= '0' ;

      log_events_follower <= '0';

    elsif (clock_sys'event and clock_sys = '1') then
      if (clk_enable) = '1' then

        if (events_written_follower /= events_written) then
         events_written_follower      <= events_written ;
          if (events_written = '1') then
            events_data_write         <= '0' ;
          end if;

        elsif (log_events_follower /= log_events) then
          log_events_follower   <= log_events ;

          if log_events = '1' then
            events_data_write        <= '1' ;
          end if ;
        end if ;
      end if;
    end if ;
end process handle_events ;

--
--Receive IMU and Audio data. Place into circular buffers. After
--the data is placed in circ buffers, signal state machine to
--process that data out of circ buffer and into block.
--No circular buffer overrun detection has been coded yet. That is a to do.
---

process_samples: process (clock_sys, rst_n)
begin
  if (rst_n = '0') then
    audio_written_follower    <= '0' ;

    audio_data_write      <= '0';

    gyro_data_write             <= '0' ;
    gyro_written_follower       <= '0' ;

    circ_buffer_wr_audio <= (others => '0');

    circ_buffer_wr_gyro <= (others => '0');
    circ_buffer_wr_accel <= (others => '0');
    circ_buffer_wr_mag <= (others => '0');
    circ_buffer_wr_temp <= (others => '0');

    accel_data_write            <= '0' ;
    accel_written_follower      <= '0' ;

    mag_data_write              <= '0' ;
    mag_written_follower        <= '0' ;

    temp_data_write             <= '0' ;
    temp_written_follower       <= '0' ;

    audio_data_process_request     <= '0' ;
    audio_data_process_request_follower    <= '0' ;

    audio_data_processed    <= '0' ;
    audio_data_processed_follower    <= '0' ;

    gyro_data_process_request    <= '0' ;
    gyro_data_process_request_follower    <= '0' ;

    gyro_data_processed    <= '0' ;
    gyro_data_processed_follower    <= '0' ;

    accel_data_process_request     <= '0' ;
    accel_data_process_request_follower    <= '0' ;

    accel_data_processed     <= '0' ;
    accel_data_processed_follower    <= '0' ;

    mag_data_process_request    <= '0' ;
    mag_data_process_request_follower   <= '0' ;

    mag_data_processed    <= '0' ;
    mag_data_processed_follower    <= '0' ;

    temp_data_process_request    <= '0' ;
    temp_data_process_request_follower    <= '0' ;

    temp_data_processed     <= '0' ;
    temp_data_processed_follower    <= '0' ;

    flashblock_circbuffer_wr_en_internal <= '0';

    flashblock_circbuffer_buffer_wr <= (others => '0');
    flashblock_circbuffer_sample_wr <= (others => '0');
    flashblock_circbuffer_data_internal <= (others => '0');




    sdram_empty_follower  <= '0';
    empty_serviced_follower  <= '0';
    empty_done <= '0';

    start_follower <= '0';


  elsif clock_sys'event and clock_sys = '1' then
    if (clk_enable) = '1' then


      flashblock_circbuffer_wr_en_internal <= '0';


      if (audio_data_processed_follower = '1'
                                      and audio_data_processed = '1') then
        audio_data_processed <= '0';
      end if;

      if (gyro_data_processed_follower = '1'
                                      and gyro_data_processed = '1') then
        gyro_data_processed <= '0';
      end if;

      if (accel_data_processed_follower = '1'
                                      and accel_data_processed = '1') then
        accel_data_processed <= '0';
      end if;

      if (mag_data_processed_follower = '1'
                                      and mag_data_processed = '1') then
        mag_data_processed <= '0';
      end if;

      if (temp_data_processed_follower = '1'
                                      and temp_data_processed = '1') then
        temp_data_processed <= '0';
      end if;



      if (audio_data_rdy_follower /= audio_data_rdy) then
        audio_data_rdy_follower <= audio_data_rdy;

        if (audio_data_rdy = '1') then
          audio_data_process_request <= '1';
          audo_sample_fpga_time <= current_fpga_time;
        end if;

      elsif (audio_data_processed_follower /= audio_data_processed) then
          audio_data_processed_follower <= audio_data_processed;
          if (audio_data_processed = '1') then
            audio_data_process_request <= '0';
            audio_data_write <= '1';
          end if;

      elsif(audio_written_follower /= audio_written) then
        audio_written_follower      <= audio_written ;
        if (audio_written = '1') then
          if ( circ_buffer_rd_audio = circ_buffer_wr_audio) then
            audio_data_write          <= '0' ;
          end if;
        end if ;
      end if;



      if (gyro_data_rdy_follower /= gyro_data_rdy) then
        gyro_data_rdy_follower <= gyro_data_rdy;

        if (gyro_data_rdy = '1') then
          gyro_data_process_request <= '1';
        end if;

      elsif (gyro_data_processed_follower /= gyro_data_processed) then
        gyro_data_processed_follower <= gyro_data_processed;
        if (gyro_data_processed = '1') then
          gyro_data_process_request <= '0';
          gyro_data_write <= '1';
        end if;

      elsif(gyro_written_follower /= gyro_written) then
        gyro_written_follower      <= gyro_written ;
        if (gyro_written = '1') then
          if ( circ_buffer_rd_gyro = circ_buffer_wr_gyro) then
            gyro_data_write          <= '0' ;
          end if;
        end if ;

      end if;

    if (accel_data_rdy_follower /= accel_data_rdy) then
      accel_data_rdy_follower <= accel_data_rdy;

      if (accel_data_rdy = '1') then
        accel_data_process_request <= '1';
      end if;

    elsif (accel_data_processed_follower /= accel_data_processed) then
        accel_data_processed_follower <= accel_data_processed;
        if (accel_data_processed = '1') then
          accel_data_process_request <= '0';
          accel_data_write <= '1';
        end if;

    elsif(accel_written_follower /= accel_written) then
      accel_written_follower      <= accel_written ;
      if (accel_written = '1') then
        if ( circ_buffer_rd_accel = circ_buffer_wr_accel) then
          accel_data_write          <= '0' ;
        end if;
      end if ;

    end if;

    if (mag_data_rdy_follower /= mag_data_rdy) then
      mag_data_rdy_follower <= mag_data_rdy;

      if (mag_data_rdy = '1') then
        mag_data_process_request <= '1';
      end if;

    elsif (mag_data_processed_follower /= mag_data_processed) then
      mag_data_processed_follower <= mag_data_processed;
      if (mag_data_processed = '1') then
        mag_data_process_request <= '0';
        mag_data_write <= '1';
      end if;

    elsif(mag_written_follower /= mag_written) then
      mag_written_follower      <= mag_written ;
      if (mag_written = '1') then
        if ( circ_buffer_rd_mag = circ_buffer_wr_mag) then
          mag_data_write          <= '0' ;
        end if;
      end if ;

    end if;

    if (temp_data_rdy_follower /= temp_data_rdy) then
      temp_data_rdy_follower <= temp_data_rdy;

      if (temp_data_rdy = '1') then
        temp_data_process_request <= '1';
      end if;

    elsif (temp_data_processed_follower /= temp_data_processed) then
      temp_data_processed_follower <= temp_data_processed;
      if (temp_data_processed = '1') then
        temp_data_process_request <= '0';
        temp_data_write <= '1';
      end if;

    elsif(temp_written_follower /= temp_written) then
      temp_written_follower      <= temp_written ;
      if (temp_written = '1') then
        if ( circ_buffer_rd_temp = circ_buffer_wr_temp) then
          temp_data_write          <= '0' ;
        end if;
      end if ;

    end if;

    if(sdram_empty_follower /= sdram_empty) then
      sdram_empty_follower <= sdram_empty;
      if (sdram_empty = '1') then
        empty_done <= '1';
      end if;
    elsif (empty_serviced_follower /= empty_serviced) then
      empty_serviced_follower <= empty_serviced;
      if(empty_serviced = '1') then
        empty_done <= '0';
      end if;
    end if;

    if  (audio_data_process_request_follower /= audio_data_process_request) then
      audio_data_process_request_follower <= audio_data_process_request;
      if (audio_data_process_request = '1') then

        circ_buffer_wr_audio <= circ_buffer_wr_audio + 1;
        flashblock_circbuffer_wr_en_internal <= '1';
        flashblock_circbuffer_buffer_wr <= circbuffer_audio_select;
        flashblock_circbuffer_sample_wr <= std_logic_vector(circ_buffer_wr_audio);
        flashblock_circbuffer_data_internal <= std_logic_vector(
                                            resize(unsigned(audio_data),
                                            flashblock_circbuffer_data_internal
                                            'length));
        audio_data_processed <= '1';

      end if;

    elsif  (gyro_data_process_request_follower /= gyro_data_process_request) then
      gyro_data_process_request_follower <= gyro_data_process_request;

        if (gyro_data_process_request = '1') then

          circ_buffer_wr_gyro <= circ_buffer_wr_gyro + 1;
          flashblock_circbuffer_wr_en_internal <= '1';
          flashblock_circbuffer_buffer_wr <= circbuffer_gyro_select;
          flashblock_circbuffer_sample_wr <= std_logic_vector(circ_buffer_wr_gyro);
          flashblock_circbuffer_data_internal <= std_logic_vector(
                                                  resize(unsigned(
                                                  gyro_data_x &
                                                  gyro_data_y &
                                                  gyro_data_z)
                                                  ,flashblock_circbuffer_data_internal'length));
          gyro_data_processed       <= '1' ;
        end if;

    elsif  (accel_data_process_request_follower /= accel_data_process_request) then
      accel_data_process_request_follower <= accel_data_process_request;

        if (accel_data_process_request = '1') then

          circ_buffer_wr_accel <= circ_buffer_wr_accel + 1;
          flashblock_circbuffer_wr_en_internal <= '1';
          flashblock_circbuffer_buffer_wr <= circbuffer_accel_select;
          flashblock_circbuffer_sample_wr <= std_logic_vector(circ_buffer_wr_accel);
          flashblock_circbuffer_data_internal <= std_logic_vector(
                                                  resize(unsigned(
                                                  accel_data_x &
                                                  accel_data_y &
                                                  accel_data_z)
                                                  ,flashblock_circbuffer_data_internal
                                                  'length));
          accel_data_processed       <= '1' ;
        end if;

    elsif  (mag_data_process_request_follower /= mag_data_process_request) then
      mag_data_process_request_follower <= mag_data_process_request;

        if (mag_data_process_request = '1') then

          circ_buffer_wr_mag <= circ_buffer_wr_mag + 1;
          flashblock_circbuffer_wr_en_internal <= '1';
          flashblock_circbuffer_buffer_wr <= circbuffer_mag_select;
          flashblock_circbuffer_sample_wr <= std_logic_vector(circ_buffer_wr_mag);
          flashblock_circbuffer_data_internal <=  std_logic_vector(
                                                  resize(unsigned(
                                                  mag_data_x &
                                                  mag_data_y &
                                                  mag_data_z)
                                                  ,flashblock_circbuffer_data_internal
                                                  'length));
          mag_data_processed       <= '1' ;
        end if;

    elsif  (temp_data_process_request_follower /= temp_data_process_request) then
      temp_data_process_request_follower <= temp_data_process_request;

        if (temp_data_process_request = '1') then

          circ_buffer_wr_temp <= circ_buffer_wr_temp + 1;
          flashblock_circbuffer_wr_en_internal <= '1';
          flashblock_circbuffer_buffer_wr <= circbuffer_temp_select;
          flashblock_circbuffer_sample_wr <= std_logic_vector(circ_buffer_wr_temp);
          flashblock_circbuffer_data_internal <=  std_logic_vector(
                                                  resize(unsigned(
                                                  temp_data)
                                                  ,flashblock_circbuffer_data_internal
                                                  'length));
          temp_data_processed       <= '1' ;
        end if;

      end if;

    end if;
  end if ;
end process process_samples ;


--Track new GPS data. GPS data is read from ram in GPS entity.
--This data exists in double buffers with the most recently updated
--buffer signalled by either a tmbank or posbank toggle.
--This process watches for those toggles and then signals for state
--machines to process the data out of those buffers and into block.
--
--
read_in_GPS_data:  process (clock_sys, rst_n)
begin
  if (rst_n = '0') then
    gps_pos_data_write             <= '0' ;
    gps_pos_written_follower       <= '0' ;


    gps_time_data_write             <= '0' ;
    gps_time_written_follower       <= '0' ;

    posbank_follower <= '0';
    tmbank_follower <= '0';

    navsol_cnt    <= (others => '0') ;
    tim_tm2_cnt   <= (others => '0') ;

  elsif (clock_sys'event and clock_sys = '1') then
    if (clk_enable) = '1' then

      if (gps_time_written_follower /= gps_time_written) then
        gps_time_written_follower  <= gps_time_written ;
        if (gps_time_written = '1') then
          gps_time_data_write         <= '0' ;
        end if;
      --If tmbank changes the data has been refreshed.
      elsif tmbank_follower /= tmbank then
        tmbank_follower   <= tmbank ;
        gps_time_data_write        <= '1' ;
        tim_tm2_cnt <= tim_tm2_cnt + 1;
      end if ;

      if (gps_pos_written_follower /= gps_pos_written) then
        gps_pos_written_follower  <= gps_pos_written ;
        if (gps_pos_written = '1') then
          gps_pos_data_write         <= '0' ;
        end if;
      --If posbank changes the data has been refreshed.
      elsif posbank_follower /= posbank then
        posbank_follower   <= posbank ;
        gps_pos_data_write        <= '1' ;
        navsol_cnt <= navsol_cnt + 1;
      end if ;
    end if ;
  end if;
end process read_in_GPS_data ;



end behavior ;
