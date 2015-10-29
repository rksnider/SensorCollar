----------------------------------------------------------------------------
--
--! @file       GPSmessages.vhd
--! @brief      Handles GPS messages sent to and recevied from the UBX GPS.
--! @details    Generates GPS messages to the UBX GPS and receives messages
--!             from it.
--! @author     Emery Newlon
--! @date       August 2014
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

library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;

library GENERAL ;
use GENERAL.Utilities_pkg.all ;     --  General use utilities.
use GENERAL.GPS_Clock_pkg.all ;     --  GPS type clock definitions.

library WORK ;
use WORK.SHARED_SDC_VALUES_PKG.ALL ;

use WORK.gps_message_ctl_pkg.all ;  --  GPS message control definitions.
use WORK.msg_ubx_nav_sol_pkg.all ;
use WORK.msg_ubx_nav_aopstatus_pkg.all ;
use WORK.msg_ubx_tim_tm2_pkg.all ;


----------------------------------------------------------------------------
--
--! @brief      GPS message manager.
--! @details    Handles messages to and from the UBX GPS.
--!
--! @param      clk_freq_g            Frequency of the clock signal.
--! @param      mem_addrbits_g        Number of address bits used for the
--!                                   GPS memory.
--! @param      mem_databits_g        Number of data bits used for the GPS
--!                                   memory.
--! @param      reset                 Reset the entity to an initial state.
--! @param      clk                   Clock used to move throuth states in
--!                                   the entity and its components.
--! @param      curtime_in            Time since reset in GPS time format.
--! @param      curtime_latch_in      Latch curtime across clock domains.
--! @param      curtime_valid_in      Latched curtime is valid when set.
--! @param      curtime_vlatch_in     Latch curtime when valid not set.
--! @param      gps_enable_in         Run the GPS system.
--! @param      gps_init_start_in     Start initializing the GPS.
--! @param      gps_init_done_in      The GPS has been initialized.
--! @param      pollinterval_in       Number of seconds between message
--!                                   polls.
--! @param      datavalid_out         The bank of memory with the newest
--!                                   valid data if two banks are available,
--!                                   otherwise set when data is valid.
--! @param      gpsmem_clk_out        Clock used to drive the memory from
--!                                   port A.
--! @param      gpsmem_addr_out       Address to read from memory port A.
--! @param      gpsmem_read_en_out    Read enable for memory port A.
--! @param      gpsmem_write_en_out   Write enable for memory port A.
--! @param      gpsmem_readfrom_in    Data read from memory on port A.
--! @param      gpsmem_writeto_out    Data written to memory on port A
--! @param      gps_rx_in             UART receive line from the GPS.
--! @param      gps_tx_out            UART transmit line to the GPS.
--! @param      timemarker_out        Signal sent to GPS to generate a time
--!                                   mark.
--! @param      aop_running_out       AssistNow Autonomous is currently
--!                                   running.
--! @param      busy_out              The GPS components are actively
--!                                   working.
--
----------------------------------------------------------------------------

entity GPSmessages is

  Generic (
    clk_freq_g            : natural := 50e6 ;
    mem_addrbits_g        : natural := 9 ;
    mem_databits_g        : natural := 8
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    curtime_in            : in    std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    curtime_latch_in      : in    std_logic ;
    curtime_valid_in      : in    std_logic ;
    curtime_vlatch_in     : in    std_logic ;

    gps_enable_in         : in    std_logic ;
    gps_init_start_in     : in    std_logic ;
    gps_init_done_out     : out   std_logic ;
    pollinterval_in       : in    unsigned (13 downto 0) ;
    datavalid_out         : out   std_logic_vector (msg_ram_blocks_c-1
                                                    downto 0) ;

    gpsmem_clk_out        : out   std_logic ;
    gpsmem_addr_out       : out   std_logic_vector (mem_addrbits_g-1
                                                    downto 0) ;
    gpsmem_read_en_out    : out   std_logic ;
    gpsmem_write_en_out   : out   std_logic ;
    gpsmem_readfrom_in    : in    std_logic_vector (mem_databits_g-1
                                                    downto 0) ;
    gpsmem_writeto_out    : out   std_logic_vector (mem_databits_g-1
                                                    downto 0) ;
    gps_rx_in             : in    std_logic ;
    gps_tx_out            : out   std_logic ;
    timemarker_out        : out   std_logic ;
    aop_running_out       : out   std_logic ;
    busy_out              : out   std_logic
  ) ;

end entity GPSmessages ;


architecture structural of GPSmessages is

  --  Clock generator generates clocks used by the GPS entities.

  component GPSclocks is
    Generic (
      clk_freq_g              : natural   := 10e6 ;
      gps_clk_freq_g          : natural   := 16 * 9600 ;
      parse_clk_freq_g        : natural   := 16 * (9600 / 10) ;
      tx_clk_freq_g           : natural   := 9600
    ) ;
    Port (
      reset                   : in    std_logic ;
      clk                     : in    std_logic ;
      gps_clk_en_in           : in    std_logic ;
      gps_clk_out             : out   std_logic ;
      tx_clk_on_in            : in    std_logic ;
      tx_clk_off_in           : in    std_logic ;
      tx_clk_out              : out   std_logic ;
      parse_clk_en_in         : in    std_logic ;
      parse_clk_out           : out   std_logic ;
      mem_clk_en_in           : in    std_logic ;
      mem_clk_out             : out   std_logic ;
      memalloc_clk_out        : out   std_logic
    ) ;
  end component GPSclocks ;

  --  Resource allicator/multiplexer allows multiple entries to share access
  --  to the same resource.

  component ResourceMUX is

    Generic (
      requester_cnt_g   : natural   :=  8 ;
      resource_bits_g   : natural   :=  8 ;
      clock_bitcnt_g    : natural   :=  0
    ) ;
    Port (
      reset             : in    std_logic ;
      clk               : in    std_logic ;
      requesters_in     : in    std_logic_vector (requester_cnt_g-1
                                                  downto 0) ;
      resource_tbl_in   : in    std_logic_2D (requester_cnt_g-1 downto 0,
                                              resource_bits_g-1 downto 0) ;
      receivers_out     : out   std_logic_vector (requester_cnt_g-1
                                                  downto 0) ;
      resources_out     : out   std_logic_vector (resource_bits_g-1
                                                  downto 0)
    ) ;

  end component ResourceMUX ;

  --  UART connection to the GPS.
  --    reset       Active high reset the device.
  --    txclk       Baud rate clock.  One cycle per bit output.
  --    ld_tx_data  Logic to load the data into the transmitter.
  --    tx_data     Data byte to send to the GPS.
  --    tx_enable   The UART is to send data.
  --    tx_out      Output signal line connected to the GPS.
  --    tx_empty    The transmitter has no data to send.
  --    rxclk       Baud rate sampling clock.  16 times the actual baud rate.
  --    uld_rx_data Signal to cause the data to be unloaded to the data byte.
  --    rx_data     Data byte received from the GPS.
  --    rx_enable   Allow the data reception.
  --    rx_in       Input signal line connected to the GPS.
  --    rx_empty    The receiver has no data in it.

  component uart is
      port (
          reset       :in  std_logic;
          txclk       :in  std_logic;
          ld_tx_data  :in  std_logic;
          tx_data     :in  std_logic_vector (7 downto 0);
          tx_enable   :in  std_logic;
          tx_out      :out std_logic;
          tx_empty    :out std_logic;
          rxclk       :in  std_logic;
          uld_rx_data :in  std_logic;
          rx_data     :out std_logic_vector (7 downto 0);
          rx_enable   :in  std_logic;
          rx_in       :in  std_logic;
          rx_empty    :out std_logic
      );
  end component ;

  --  GPS Message receiver and parser.

  component GPSmessageParser is

    Generic (
      memaddr_bits_g  : natural := 8
    ) ;
    Port (
      reset           : in    std_logic ;
      clk             : in    std_logic ;
      curtime_in      : in    std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
      markertime_in   : in    std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
      inbyte_in       : in    std_logic_vector (7 downto 0) ;
      inready_in      : in    std_logic ;
      inreceived_out  : out   std_logic ;
      meminput_in     : in    std_logic_vector (7 downto 0) ;
      memrcv_in       : in    std_logic ;
      memreq_out      : out   std_logic ;
      memoutput_out   : out   std_logic_vector (7 downto 0) ;
      memaddr_out     : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
      memread_en_out  : out   std_logic ;
      memwrite_en_out : out   std_logic ;
      datavalid_out   : out   std_logic_vector (msg_ram_blocks_c-1
                                                downto 0) ;
      tempbank_out    : out   std_logic ;
      msgnumber_out   : out   std_logic_vector (msg_count_bits_c-1
                                                downto 0) ;
      msgreceived_out : out   std_logic ;
      busy_out        : out   std_logic
    ) ;

  end component GPSmessageParser ;

  --  Message sender.

  component GPSsend is

    Generic (
      memaddr_bits_g  : natural := 8
    ) ;
    Port (
      reset           : in    std_logic ;
      clk             : in    std_logic ;
      outready_in     : in    std_logic ;
      msgclass_in     : in    std_logic_vector (7 downto 0) ;
      msgid_in        : in    std_logic_vector (7 downto 0) ;
      memstart_in     : in    std_logic_vector (memaddr_bits_g-1 downto 0) ;
      memlength_in    : in    unsigned (15 downto 0) ;
      meminput_in     : in    std_logic_vector (7 downto 0) ;
      memrcv_in       : in    std_logic ;
      memreq_out      : out   std_logic ;
      memaddr_out     : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
      memread_en_out  : out   std_logic ;
      outchar_out     : out   std_logic_vector (7 downto 0) ;
      outsend_out     : out   std_logic ;
      outdone_out     : out   std_logic
    ) ;

  end component GPSsend ;

  --  Message poller.

  component GPSpoll is

    Generic (
      memaddr_bits_g  : natural := 8
    ) ;
    Port (
      reset           : in    std_logic ;
      clk             : in    std_logic ;
      curtime_in      : in    std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
      pollinterval_in : in    unsigned (13 downto 0) ;
      pollmessages_in : in    std_logic_vector (msg_count_c-1 downto 0) ;
      sendready_in    : in    std_logic ;
      sendrcv_in      : in    std_logic ;
      meminput_in     : in    std_logic_vector (7 downto 0) ;
      memrcv_in       : in    std_logic ;
      memreq_out      : out   std_logic ;
      memaddr_out     : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
      memread_en_out  : out   std_logic ;
      sendreq_out     : out   std_logic ;
      msgclass_out    : out   std_logic_vector (7 downto 0) ;
      msgid_out       : out   std_logic_vector (7 downto 0) ;
      outsend_out     : out   std_logic ;
      busy_out        : out   std_logic
    ) ;

  end component GPSpoll ;

  --  Handle AssistNow Autonomous status messages.

  component AOPstatus is

    Generic (
      memaddr_bits_g  : natural := 8 ;
      quiet_count_g   : natural := 8
    ) ;
    Port (
      clk             : in    std_logic ;
      reset           : in    std_logic ;
      msgnumber_in    : in    std_logic_vector (msg_count_bits_c-1
                                                downto 0) ;
      msgreceived_in  : in    std_logic ;
      tempbank_in     : in    std_logic ;
      memdata_in      : in    std_logic_vector (7 downto 0) ;
      memrcv_in       : in    std_logic ;
      memreq_out      : out   std_logic ;
      memaddr_out     : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
      memread_en_out  : out   std_logic ;
      running_out     : out   std_logic ;
      busy_out        : out   std_logic
    ) ;

  end component AOPstatus ;

  --  Generate Time Marks periodically.

  component TimeMark is

    Generic (
      time_mark_interval_g  : natural := 5 * 60 * 1000 ;
      min_pos_accuracy_g    : natural := 100 * 100 ;
      max_pos_age_g         : natural := 15 * 60 * 1000 ;
      memaddr_bits_g        : natural := 8
    ) ;
    Port (
      clk                   : in    std_logic ;
      reset                 : in    std_logic ;
      curtime_in            : in    std_logic_vector (gps_time_bits_c-1
                                                      downto 0) ;
      curtime_latch_in      : in    std_logic ;
      curtime_valid_in      : in    std_logic ;
      curtime_vlatch_in     : in    std_logic ;

      posbank_in            : in    std_logic ;
      tmbank_in             : in    std_logic ;
      memdata_in            : in    std_logic_vector (7 downto 0) ;
      memrcv_in             : in    std_logic ;
      memreq_out            : out   std_logic ;
      memaddr_out           : out   std_logic_vector (memaddr_bits_g-1
                                                      downto 0) ;
      memread_en_out        : out   std_logic ;
      marker_out            : out   std_logic ;
      marker_time_out       : out   std_logic_vector (gps_time_bits_c-1
                                                      downto 0) ;
      req_position_out      : out   std_logic ;
      req_timemark_out      : out   std_logic ;
      busy_out              : out   std_logic
    ) ;

  end component TimeMark ;

  --  Initialize the GPS on command.

  component GPSinit is
    Generic (
      memaddr_bits_g  : natural := 8
    ) ;
    Port (
      reset           : in    std_logic ;
      clk             : in    std_logic ;
      curtime_in      : in    std_logic_vector (gps_time_bits_c-1 downto 0) ;
      init_start_in   : in    std_logic ;
      init_done_out   : out   std_logic ;
      sendreq_out     : out   std_logic ;
      sendrcv_in      : in    std_logic ;
      memreq_out      : out   std_logic ;
      memrcv_in       : in    std_logic ;
      memaddr_out     : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
      memread_en_out  : out   std_logic ;
      memwrite_en_out : out   std_logic ;
      meminput_in     : in    std_logic_vector (7 downto 0) ;
      memoutput_out   : out   std_logic_vector (7 downto 0) ;
      msgclass_out    : out   std_logic_vector (7 downto 0) ;
      msgid_out       : out   std_logic_vector (7 downto 0) ;
      msglength_out   : out   unsigned (15 downto 0) ;
      msgaddress_out  : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
      sendready_in    : in    std_logic ;
      outsend_out     : out   std_logic ;
      busy_out        : out   std_logic
    ) ;
  end component GPSinit ;

  --  Memory requesters.

  constant memreq_parser_c    : natural := 0 ;
  constant memreq_send_c      : natural := memreq_parser_c + 1 ;
  constant memreq_poll_c      : natural := memreq_send_c + 1 ;
  constant memreq_aopstat_c   : natural := memreq_poll_c + 1 ;
  constant memreq_timemark_c  : natural := memreq_aopstat_c + 1 ;
  constant memreq_init_c      : natural := memreq_timemark_c + 1 ;

  constant mem_user_cnt_c     : natural := memreq_init_c + 1 ;

  --  Memory control signals.

  constant mem_io_bits_c      : natural := mem_addrbits_g +
                                           mem_databits_g + 2 ;

  signal memrequesters        : std_logic_vector (mem_user_cnt_c-1
                                                  downto 0) ;
  signal memreceivers         : std_logic_vector (mem_user_cnt_c-1
                                                  downto 0) ;

  signal memread_from         : std_logic_vector (mem_databits_g-1
                                                  downto 0) ;

  signal meminput_tbl         : std_logic_2D (mem_user_cnt_c-1 downto 0,
                                              mem_io_bits_c-1 downto 0) ;

  signal memselected          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  alias  memaddr              : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) is
                                memselected      (mem_addrbits_g-1
                                                  downto 0) ;
  alias  memwrite_to          : std_logic_vector (mem_databits_g-1
                                                  downto 0) is
                                memselected      (mem_addrbits_g +
                                                  mem_databits_g-1 downto
                                                  mem_addrbits_g) ;
  alias  memread_en           : std_logic is
                                memselected      (mem_addrbits_g +
                                                  mem_databits_g) ;
  alias  memwrite_en          : std_logic is
                                memselected      (mem_addrbits_g +
                                                  mem_databits_g + 1) ;

  --  Message requester I/O bits.  Requesters that do not write to memory
  --  use the memwrite_to_none_c and memwrite_en_none_c constants instead of
  --  signals that they generate themselves.

  constant memwrite_to_none_c : std_logic_vector (mem_databits_g-1
                                                  downto 0) :=
                                      (others => '0') ;
  constant memwrite_en_none_c : std_logic := '0' ;

  signal memaddr_parser       : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) ;
  signal memwrite_to_parser   : std_logic_vector (mem_databits_g-1
                                                  downto 0) ;
  signal memwrite_en_parser   : std_logic ;
  signal memread_en_parser    : std_logic ;
  signal memctl_parser        : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_send         : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) ;
  signal memread_en_send      : std_logic ;
  signal memctl_send          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_poll         : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) ;
  signal memread_en_poll      : std_logic ;
  signal memctl_poll          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_aopstat      : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) ;
  signal memread_en_aopstat   : std_logic ;
  signal memctl_aopstat       : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_timemark     : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) ;
  signal memread_en_timemark  : std_logic ;
  signal memctl_timemark      : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_init         : std_logic_vector (mem_addrbits_g-1
                                                  downto 0) ;
  signal memwrite_to_init     : std_logic_vector (mem_databits_g-1
                                                  downto 0) ;
  signal memwrite_en_init     : std_logic ;
  signal memread_en_init      : std_logic ;
  signal memctl_init          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  --  GPS UART connecting signals.

  signal tx_load              : std_logic ;
  signal tx_empty             : std_logic ;
  signal tx_data              : std_logic_vector (7 downto 0) ;

  signal rx_ready             : std_logic ;
  signal rx_received          : std_logic ;
  signal rx_empty             : std_logic ;
  signal rx_data              : std_logic_vector (7 downto 0) ;

  --  Parsed message information.

  signal databank             : std_logic_vector (msg_ram_blocks_c-1
                                                  downto 0) ;
  signal tempbank             : std_logic ;

  signal msg_number           : std_logic_vector (msg_count_bits_c-1
                                                  downto 0) ;
  signal msg_received         : std_logic ;

  --  Information about messages to send.

  constant send_poll_c        : natural := 0 ;
  constant send_init_c        : natural := send_poll_c + 1 ;

  constant sendcnt_c          : natural := send_init_c + 1 ;

  constant send_classbits_c   : natural := 8 ;
  constant send_idbits_c      : natural := 8 ;
  constant send_startbits_c   : natural := mem_addrbits_g ;
  constant send_lengthbits_c  : natural := 16 ;
  constant send_outbits_c     : natural := 1 ;

  constant send_classstrt_c   : natural := 0 ;
  constant send_idstrt_c      : natural := send_classstrt_c +
                                           send_classbits_c ;
  constant send_startstrt_c   : natural := send_idstrt_c +
                                           send_idbits_c ;
  constant send_lengthstrt_c  : natural := send_startstrt_c +
                                           send_startbits_c ;
  constant send_outstrt_c     : natural := send_lengthstrt_c +
                                           send_lengthbits_c ;
  constant send_io_bits_c     : natural := send_outstrt_c +
                                           send_outbits_c ;

  signal sendready            : std_logic ;
  signal sendreq              : std_logic_vector (sendcnt_c-1 downto 0) ;
  signal sendrcv              : std_logic_vector (sendcnt_c-1 downto 0) ;

  signal sendinput_tbl        : std_logic_2D (sendcnt_c-1      downto 0,
                                              send_io_bits_c-1 downto 0) ;

  signal sendselected         : std_logic_vector (send_io_bits_c-1
                                                  downto 0) ;
  alias  msgclass             : std_logic_vector (send_classbits_c-1
                                                  downto 0) is
                                sendselected     (send_classstrt_c +
                                                  send_classbits_c-1 downto
                                                  send_classstrt_c) ;
  alias  msgid                : std_logic_vector (send_idbits_c-1
                                                  downto 0) is
                                sendselected     (send_idstrt_c +
                                                  send_idbits_c-1 downto
                                                  send_idstrt_c) ;
  alias  msgstart             : std_logic_vector (send_startbits_c-1
                                                  downto 0) is
                                sendselected     (send_startstrt_c +
                                                  send_startbits_c-1 downto
                                                  send_startstrt_c) ;
  alias  msglength            : std_logic_vector (send_lengthbits_c-1
                                                  downto 0) is
                                sendselected     (send_lengthstrt_c +
                                                  send_lengthbits_c-1 downto
                                                  send_lengthstrt_c) ;
  alias  sendout              : std_logic is
                                sendselected     (send_outstrt_c) ;

  constant send_nomsgstart_c  :
              std_logic_vector (send_startbits_c-1
                                downto 0) := (others => '0') ;
  constant send_nomsglength_c :
              std_logic_vector (send_lengthbits_c-1
                                downto 0) := (others => '0') ;

  --  Information about messages to poll.

  signal pollmessages         : std_logic_vector (msg_count_c-1 downto 0) ;
  signal msgclass_poll        : std_logic_vector (send_classbits_c-1
                                                  downto 0) ;
  signal msgid_poll           : std_logic_vector (send_idbits_c-1
                                                  downto 0) ;
  signal sendout_poll         : std_logic ;
  signal sendctl_poll         : std_logic_vector (send_io_bits_c-1
                                                  downto 0) ;

  --  Information about timemark messages.

  signal tm_req_position      : std_logic ;
  signal tm_req_timemark      : std_logic ;
  signal tm_marker_time       : std_logic_vector (gps_time_bits_c-1
                                                  downto 0) ;

  --  Information about initialization messages.

  signal msgclass_init        : std_logic_vector (send_classbits_c-1
                                                  downto 0) ;
  signal msgid_init           : std_logic_vector (send_idbits_c-1
                                                  downto 0) ;
  signal msgstart_init        : std_logic_vector (send_startbits_c-1
                                                  downto 0) ;
  signal msglength_init       : std_logic_vector (send_lengthbits_c-1
                                                  downto 0) ;
  signal sendout_init         : std_logic ;
  signal sendctl_init         : std_logic_vector (send_io_bits_c-1
                                                  downto 0) ;

  --  Clock generation information.
  --  The UART receiver requires 16 clock cycles to process a bit.  There
  --  are 10 input bits (baud) per received byte.
  --  The UART transmitter requires 1 clock cycle to process a bit.
  --  The parser requires 16 clock cycles to process a byte.
  --  Memory allocation and memory access run at the parser clock rate.
  --  The memory clock is the parser clock inverted.
  --  Clocks are gated on when they are in use by components.

  constant uart_rx_mult_c     : natural := 16 ;
  constant uart_bytebits_c    : natural := 10 ;

  constant parse_clk_mult_c   : natural := 16 ;

  signal gps_clk              : std_logic ;
  signal tx_clk               : std_logic ;
  signal parse_clk            : std_logic ;
  signal mem_clk              : std_logic ;
  signal memalloc_clk         : std_logic ;

  signal parse_clk_en         : std_logic ;
  signal mem_clk_en           : std_logic ;

  signal parser_busy          : std_logic ;
  signal aop_busy             : std_logic ;
  signal init_busy            : std_logic ;
  signal poll_busy            : std_logic ;
  signal timemark_busy        : std_logic ;

begin

  gpsmem_addr_out             <= memaddr ;
  gpsmem_read_en_out          <= memread_en ;
  gpsmem_write_en_out         <= memwrite_en ;
  gpsmem_writeto_out          <= memwrite_to ;

  datavalid_out               <= databank ;

  busy_out                    <= parse_clk_en ;

  --  Generated clocks used by the GPS components.

  parse_clk_en                <= '1' when (rx_ready       = '1' or
                                           parser_busy    = '1' or
                                           aop_busy       = '1' or
                                           init_busy      = '1' or
                                           poll_busy      = '1' or
                                           timemark_busy  = '1' or
                                           unsigned (sendreq) /= 0 or
                                           unsigned (sendrcv) /= 0) else
                                 '0' ;

  mem_clk_en                  <= '1' when (unsigned (memrequesters) /= 0 or
                                           unsigned (memreceivers)  /= 0)
                                     else '0' ;

  gpsclks : GPSclocks
    Generic Map (
      clk_freq_g              => clk_freq_g,
      gps_clk_freq_g          => uart_rx_mult_c * gps_baud_rate_c,
      parse_clk_freq_g        => parse_clk_mult_c *
                                (gps_baud_rate_c / uart_bytebits_c),
      tx_clk_freq_g           => gps_baud_rate_c
    )
    Port Map (
      reset                   => reset,
      clk                     => clk,
      gps_clk_en_in           => gps_enable_in,
      gps_clk_out             => gps_clk,
      tx_clk_on_in            => tx_load,
      tx_clk_off_in           => tx_empty,
      tx_clk_out              => tx_clk,
      parse_clk_en_in         => parse_clk_en,
      parse_clk_out           => parse_clk,
      mem_clk_en_in           => mem_clk_en,
      mem_clk_out             => gpsmem_clk_out,
      memalloc_clk_out        => memalloc_clk
    ) ;

  --  Memory multiplexer allows multiple entities to share access to the
  --  same memory module.

  memmux : ResourceMUX
    Generic Map (
      requester_cnt_g         => mem_user_cnt_c,
      resource_bits_g         => mem_io_bits_c
    )
    Port Map (
      reset                   => reset,
      clk                     => memalloc_clk,
      requesters_in           => memrequesters,
      resource_tbl_in         => meminput_tbl,
      receivers_out           => memreceivers,
      resources_out           => memselected
    ) ;

  --  UART connecting the GPS to the sender and receive parser.

  gps_uart : uart
    Port Map (
      reset                   => reset,
      txclk                   => tx_clk,
      ld_tx_data              => tx_load,
      tx_data                 => tx_data,
      tx_enable               => '1',
      tx_out                  => gps_tx_out,
      tx_empty                => tx_empty,
      rxclk                   => gps_clk,
      uld_rx_data             => not rx_empty,
      rx_data                 => rx_data,
      rx_enable               => '1',
      rx_in                   => gps_rx_in,
      rx_empty                => rx_empty
    ) ;

  process (reset, gps_clk)
  begin
    if (reset = '1') then
      rx_ready    <= '0' ;

    elsif (rising_edge (gps_clk)) then
      if (rx_empty = '0') then
        rx_ready  <= '1' ;

      elsif (rx_received = '1') then
        rx_ready  <= '0' ;

      end if ;
    end if ;
  end process ;

  --  GPS Message receiver and parser.

  gps_parser : GPSmessageParser
    Generic Map (
      memaddr_bits_g          => mem_addrbits_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      curtime_in              => curtime_in,
      markertime_in           => tm_marker_time,
      inbyte_in               => rx_data,
      inready_in              => rx_ready,
      inreceived_out          => rx_received,
      meminput_in             => gpsmem_readfrom_in,
      memrcv_in               => memreceivers  (memreq_parser_c),
      memreq_out              => memrequesters (memreq_parser_c),
      memoutput_out           => memwrite_to_parser,
      memaddr_out             => memaddr_parser,
      memread_en_out          => memread_en_parser,
      memwrite_en_out         => memwrite_en_parser,
      datavalid_out           => databank,
      tempbank_out            => tempbank,
      msgnumber_out           => msg_number,
      msgreceived_out         => msg_received,
      busy_out                => parser_busy
    ) ;

  memctl_parser               <= memwrite_en_parser & memread_en_parser &
                                 memwrite_to_parser & memaddr_parser ;

  set2D_element (memreq_parser_c, memctl_parser, meminput_tbl) ;

  --  GPS Message sender multiplexer allows multiple entities to share
  --  access to the message sender module.

  sendmux : ResourceMUX
    Generic Map (
      requester_cnt_g         => sendcnt_c,
      resource_bits_g         => send_io_bits_c
    )
    Port Map (
      reset                   => reset,
      clk                     => memalloc_clk,
      requesters_in           => sendreq,
      resource_tbl_in         => sendinput_tbl,
      receivers_out           => sendrcv,
      resources_out           => sendselected
    ) ;

  --  Message sender.

  gps_send : GPSsend
    Generic Map (
      memaddr_bits_g          => mem_addrbits_g
    )
    Port Map (
      reset                   => reset or (not sendout),
      clk                     => parse_clk,
      outready_in             => tx_empty,
      msgclass_in             => msgclass,
      msgid_in                => msgid,
      memstart_in             => msgstart,
      memlength_in            => unsigned (msglength),
      meminput_in             => gpsmem_readfrom_in,
      memrcv_in               => memreceivers  (memreq_send_c),
      memreq_out              => memrequesters (memreq_send_c),
      memaddr_out             => memaddr_send,
      memread_en_out          => memread_en_send,
      outchar_out             => tx_data,
      outsend_out             => tx_load,
      outdone_out             => sendready
    ) ;

  memctl_send                 <= memwrite_en_none_c & memread_en_send &
                                 memwrite_to_none_c & memaddr_send ;

  set2D_element (memreq_send_c, memctl_send, meminput_tbl) ;

  --  Message poller.

  gps_poll : GPSpoll
    Generic Map (
      memaddr_bits_g          => mem_addrbits_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      curtime_in              => curtime_in,
      pollinterval_in         => pollinterval_in,
      pollmessages_in         => pollmessages,
      sendready_in            => sendready,
      sendrcv_in              => sendrcv (send_poll_c),
      meminput_in             => gpsmem_readfrom_in,
      memrcv_in               => memreceivers  (memreq_poll_c),
      memreq_out              => memrequesters (memreq_poll_c),
      memaddr_out             => memaddr_poll,
      memread_en_out          => memread_en_poll,
      sendreq_out             => sendreq (send_poll_c),
      msgclass_out            => msgclass_poll,
      msgid_out               => msgid_poll,
      outsend_out             => sendout_poll,
      busy_out                => poll_busy
    ) ;

  memctl_poll                 <= memwrite_en_none_c & memread_en_poll &
                                 memwrite_to_none_c & memaddr_poll ;

  set2D_element (memreq_poll_c, memctl_poll, meminput_tbl) ;

  --  GPS message sender multiplexing entry.

  sendctl_poll                <= sendout_poll       & send_nomsglength_c  &
                                 send_nomsgstart_c  & msgid_poll          &
                                 msgclass_poll ;

  set2D_element (send_poll_c, sendctl_poll, sendinput_tbl) ;

  --  Handle AssistNow Autonomous status messages.

  gps_aopstatus : AOPstatus
    Generic Map (
      memaddr_bits_g          => mem_addrbits_g,
      quiet_count_g           => 5
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      msgnumber_in            => msg_number,
      msgreceived_in          => msg_received,
      tempbank_in             => tempbank,
      memdata_in              => gpsmem_readfrom_in,
      memrcv_in               => memreceivers  (memreq_aopstat_c),
      memreq_out              => memrequesters (memreq_aopstat_c),
      memaddr_out             => memaddr_aopstat,
      memread_en_out          => memread_en_aopstat,
      running_out             => aop_running_out,
      busy_out                => aop_busy
    ) ;

  memctl_aopstat              <= memwrite_en_none_c & memread_en_aopstat &
                                 memwrite_to_none_c & memaddr_aopstat ;

  set2D_element (memreq_aopstat_c, memctl_aopstat, meminput_tbl) ;

  --  Time mark generator.

  gps_timemark : TimeMark
    Generic Map (
      memaddr_bits_g          => mem_addrbits_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      curtime_in              => curtime_in,
      curtime_latch_in        => curtime_latch_in,
      curtime_valid_in        => curtime_valid_in,
      curtime_vlatch_in       => curtime_vlatch_in,
      posbank_in              => databank (msg_ubx_nav_sol_ramblock_c),
      tmbank_in               => databank (msg_ubx_tim_tm2_ramblock_c),
      memdata_in              => gpsmem_readfrom_in,
      memrcv_in               => memreceivers  (memreq_timemark_c),
      memreq_out              => memrequesters (memreq_timemark_c),
      memaddr_out             => memaddr_timemark,
      memread_en_out          => memread_en_timemark,
      marker_out              => timemarker_out,
      marker_time_out         => tm_marker_time,
      req_position_out        => tm_req_position,
      req_timemark_out        => tm_req_timemark,
      busy_out                => timemark_busy
    ) ;

  memctl_timemark             <= memwrite_en_none_c &
                                 memread_en_timemark &
                                 memwrite_to_none_c & memaddr_timemark ;

  set2D_element (memreq_timemark_c, memctl_timemark, meminput_tbl) ;

  --  GPS Initializer.

  gps_init : GPSinit
    Generic Map (
      memaddr_bits_g            => mem_addrbits_g
    )
    Port Map (
      reset                     => reset,
      clk                       => parse_clk,
      curtime_in                => curtime_in,
      init_start_in             => gps_init_start_in,
      init_done_out             => gps_init_done_out,
      sendreq_out               => sendreq (send_init_c),
      sendrcv_in                => sendrcv (send_init_c),
      memreq_out                => memrequesters (memreq_init_c),
      memrcv_in                 => memreceivers  (memreq_init_c),
      memaddr_out               => memaddr_init,
      memread_en_out            => memread_en_init,
      memwrite_en_out           => memwrite_en_init,
      meminput_in               => gpsmem_readfrom_in,
      memoutput_out             => memwrite_to_init,
      msgclass_out              => msgclass_init,
      msgid_out                 => msgid_init,
      unsigned (msglength_out)  => msglength_init,
      msgaddress_out            => msgstart_init,
      sendready_in              => sendready,
      outsend_out               => sendout_init,
      busy_out                  => init_busy
    ) ;

  memctl_init                   <= memwrite_en_init   & memread_en_init   &
                                   memwrite_to_init   & memaddr_init ;

  set2D_element (memreq_init_c, memctl_init, meminput_tbl) ;

  --  GPS message sender multiplexing entry.

  sendctl_init                <= sendout_init       & msglength_init      &
                                 msgstart_init      & msgid_init          &
                                 msgclass_init ;

  set2D_element (send_init_c, sendctl_init, sendinput_tbl) ;

  --  Poll request combination signals.  Always poll for position and
  --  AssistNow status info.

  pollmessages (msg_ubx_nav_sol_number_c)       <= tm_req_position or '1' ;
  pollmessages (msg_ubx_nav_aopstatus_number_c) <= '1' ;
  pollmessages (msg_ubx_tim_tm2_number_c)       <= tm_req_timemark ;


end architecture structural ;
