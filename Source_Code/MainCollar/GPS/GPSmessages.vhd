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
use GENERAL.Utilities.all ;     --  General use utilities.
use GENERAL.GPS_Clock.all ;     --  GPS type clock definitions.

library WORK ;
use WORK.gps_message_ctl.all ;  --  GPS message control definitions.
use WORK.msg_ubx_nav_sol.all ;
use WORK.msg_ubx_nav_aopstatus.all ;
use WORK.msg_ubx_tim_tm2.all ;


----------------------------------------------------------------------------
--
--! @brief      GPS message manager.
--! @details    Handles messages to and from the UBX GPS.
--!
--! @param      clk_freq_g            Frequency of the clock signal.
--! @param      uart_rx_mult_g        Buad rate multiplier for UART
--!                                   receiver.
--! @param      mem_addrbits_g        Number of address bits used for the
--!                                   GPS memory.
--! @param      mem_databits_g        Number of data bits used for the GPS
--!                                   memory.
--! @param      reset                 Reset the entity to an initial state.
--! @param      clk                   Clock used to move throuth states in
--!                                   the entity and its components.
--! @param      curtime_in            Time since reset in GPS time format.
--! @param      pollinterval_in       Number of seconds between message
--!                                   polls.
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
--
----------------------------------------------------------------------------

entity GPSmessages is

  Generic (
    clk_freq_g            : natural := 50e6 ;
    uart_rx_mult_g        : natural := 16 ;
    mem_addrbits_g        : natural := 9 ;
    mem_databits_g        : natural := 8
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    curtime_in            : in    std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    pollinterval_in       : in    unsigned (13 downto 0) ;
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
    aop_running_out       : out   std_logic
  ) ;

end entity GPSmessages ;


architecture structural of GPSmessages is

  --  Resource allicator/multiplexer allows multiple entries to share access
  --  to the same resource.

  component ResourceMUX is

    Generic (
      requester_cnt_g   : natural   :=  8 ;
      resource_bits_g   : natural   :=  8
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
      inbyte_in          : in    std_logic_vector (7 downto 0) ;
      inready_in         : in    std_logic ;
      meminput_in        : in    std_logic_vector (7 downto 0) ;
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
      msgreceived_out : out   std_logic
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
      outsend_out     : out   std_logic
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
      running_out     : out   std_logic
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
      posbank_in            : in    std_logic ;
      tmbank_in             : in    std_logic ;
      memdata_in            : in    std_logic_vector (7 downto 0) ;
      memrcv_in             : in    std_logic ;
      memreq_out            : out   std_logic ;
      memaddr_out           : out   std_logic_vector (memaddr_bits_g-1
                                                      downto 0) ;
      memread_en_out        : out   std_logic ;
      memwrite_en_out       : out   std_logic ;
      memoutput_out         : out   std_logic_vector (7 downto 0) ;
      marker_out            : out   std_logic ;
      req_position_out      : out   std_logic ;
      req_timemark_out      : out   std_logic
    ) ;

  end component TimeMark ;

  --  Memory requesters.

  constant memreq_parser_c    : natural := 0 ;
  constant memreq_send_c      : natural := memreq_parser_c + 1 ;
  constant memreq_poll_c      : natural := memreq_send_c + 1 ;
  constant memreq_aopstat_c   : natural := memreq_poll_c + 1 ;
  constant memreq_timemark_c  : natural := memreq_aopstat_c + 1 ;

  constant mem_user_cnt_c     : natural := memreq_timemark_c + 1 ;

  --  Memory control signals.

  constant mem_io_bits_c      : natural := memaddr_bits_g +
                                           memdata_bits_g + 2 ;

  signal memrequesters        : std_logic_vector (mem_user_cnt_c-1
                                                  downto 0) ;
  signal memreceivers         : std_logic_vector (mem_user_cnt_c-1
                                                  downto 0) ;

  signal memread_from         : std_logic_vector (memdata_bits_g-1
                                                  downto 0) ;

  signal meminput_tbl         : std_logic_2D (mem_user_cnt_c-1 downto 0,
                                              mem_io_bits_c-1 downto 0) ;

  signal memselected          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  alias  memaddr              : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) is
                                memselected      (memaddr_bits_g-1
                                                  downto 0) ;
  alias  memwrite_to          : std_logic_vector (memdata_bits_g-1
                                                  downto 0) is
                                memselected      (memaddr_bits_g +
                                                  memdata_bits_g-1 downto
                                                  memaddr_bits_g) ;
  alias  memread_en           : std_logic is
                                memselected      (memaddr_bits_g +
                                                  memdata_bits_g) ;
  alias  memwrite_en          : std_logic is
                                memselected      (memaddr_bits_g +
                                                  memdata_bits_g + 1) ;

  --  Message requester I/O bits.  Requesters that do not write to memory
  --  use the memwrite_to_none_c and memwrite_en_none_c constants instead of
  --  signals that they generate themselves.

  constant memwrite_to_none_c : std_logic_vector (memdata_bits_g-1
                                                  downto 0) :=
                                      (others => '0') ;
  constant memwrite_en_none_c : std_logic := '0' ;

  signal memaddr_parser       : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) ;
  signal memwrite_to_parser   : std_logic_vector (memdata_bits_g-1
                                                  downto 0) ;
  signal memwrite_en_parser   : std_logic ;
  signal memread_en_parser    : std_logic ;
  signal memctl_parser        : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_send         : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) ;
  signal memread_en_send      : std_logic ;
  signal memctl_send          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_poll         : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) ;
  signal memread_en_poll      : std_logic ;
  signal memctl_poll          : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_aopstat      : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) ;
  signal memread_en_aopstat   : std_logic ;
  signal memctl_aopstat       : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  signal memaddr_timemark     : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) ;
  signal memwrite_to_timemark : std_logic_vector (memdata_bits_g-1
                                                  downto 0) ;
  signal memwrite_en_timemark : std_logic ;
  signal memread_en_timemark  : std_logic ;
  signal memctl_timemark      : std_logic_vector (mem_io_bits_c-1
                                                  downto 0) ;

  --  GPS UART connecting signals.  The transmitter runs at the baud rate.
  --  Clock counts are for half a clock cycle.

  constant tx_clk_cnt_c       : natural := (uart_rx_mult_g / 2) - 1 ;
  constant tx_clk_bits_c      : natural := const_bits (tx_clk_cnt_c) ;

  signal tx_clk               : std_logic ;
  signal tx_gated_clk         : std_logic ;
  signal tx_gated_clk_en      : std_logic ;

  signal tx_load              : std_logic ;
  signal tx_empty             : std_logic ;
  signal tx_data              : std_logic_vector (7 downto 0) ;
  signal tx_clk_counter       : unsigned (tx_clk_bits_c-1 downto 0) ;

  signal rx_empty             : std_logic ;
  signal rx_unload            : std_logic ;
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

  constant sendcnt_c          : natural := send_poll_c + 1 ;

  signal msgclass             : std_logic_vector (7 downto 0) ;
  signal msgid                : std_logic_vector (7 downto 0) ;
  signal memstart             : std_logic_vector (memaddr_bits_g-1
                                                  downto 0) ;
  signal memlength            : unsigned (15 downto 0) ;
  signal sendready            : std_logic ;
  signal sendout              : std_logic ;
  signal sendreq              : std_logic_vector (sendcnt_c-1 downto 0) ;
  signal sendrcv              : std_logic_vector (sendcnt_c-1 downto 0) ;

  --  Information about messages to poll.

  signal pollmessages         : std_logic_vector (msg_count_c-1 downto 0) ;
  signal sendreq_poll         : std_logic ;
  signal sendrcv_poll         : std_logic ;
  signal msgclass_poll        : std_logic_vector (7 downto 0) ;
  signal msgid_poll           : std_logic_vector (7 downto 0) ;
  signal sendout_poll         : std_logic ;

  --  Information about timemark messages.

  signal tm_req_position      : std_logic ;
  signal tm_req_timemark      : std_logic ;

  --  Information about GPS parsing.  The parser requires 16 clock cycles
  --  to process a byte.  There are 10 input bits (baud) per received byte.
  --  Counts are for half a clock cycle.

  constant parse_per_rx_cnt_c : natural :=
      natural (trunc ((real (uart_rx_mult_g) * 10.0) / (16.0 * 2.0)) ;

  constant parse_clk_cnt_c    : natural := parse_per_rx_cnt_c - 1 ;
  constant parse_clk_bits_c   : natural := const_bits (parse_clk_cnt_c) ;

  signal parse_clk            : std_logic ;
  signal parse_clk_counter    : unsigned (parse_clk_bits_c-1 downto 0) ;

  signal mem_gated_clk_en     : std_logic ;

begin

  --  Memory component.  Clock is triggered on negative going edge to allow
  --  input signals to propagate in one half clock cycle and to produce
  --  output by the next clock cycle.  The memory is fast enough to produce
  --  output in less than one half clock cycle.

  gpsram_clk                  <= (not parse_clk) and mem_gated_clk_en ;

  --  Memory multiplexer allows multiple entities to share access to the
  --  same memory module.

  memmux : ResourceMUX
    Generic Map (
      requester_cnt_g         => mem_user_cnt_c,
      resource_bits_g         => mem_io_bits_c
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      requesters_in           => memrequesters,
      resource_tbl_in         => meminput_tbl,
      receivers_out           => memreceivers,
      resources_out           => memselected
    ) ;

  --  UART connecting the GPS to the sender and receive parser.

  gps_uart : uart
    Port Map (
      reset                   => reset,
      txclk                   => tx_gated_clk,
      ld_tx_data              => tx_load,
      tx_data                 => tx_data,
      tx_enable               => '1',
      tx_out                  => gps_tx_out,
      tx_empty                => tx_empty,
      rxclk                   => clk,
      uld_rx_data             => rx_unload,
      rx_data                 => rx_data,
      rx_enable               => '1',
      rx_in                   => gps_rx_in,
      rx_empty                => rx_empty
    ) ;

  --  GPS Message receiver and parser.

  gps_parser : GPSmessageParser
    Generic Map (
      memaddr_bits_g          => memaddr_bits_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      curtime_in              => curtime_in,
      inbyte_in               => rx_data,
      inready_in              => not rx_empty,
      inreceived_out          => rx_unload,
      meminput_in             => memread_from,
      memrcv_in               => memreceivers  (memreq_parser_c),
      memreq_out              => memrequesters (memreq_parser_c),
      memoutput_out           => memwrite_to_parser,
      memaddr_out             => memaddr_parser,
      memread_en_out          => memread_en_parser,
      memwrite_en_out         => memwrite_en_parser,
      datavalid               => databank,
      tempbank                => tempbank,
      msgnumber               => msg_number,
      msgreceived             => msg_received
    ) ;

  memctl_parser               <= memwrite_en_parser & memread_en_parser &
                                 memwrite_to_parser & memaddr_parser ;

  set2D_element (memreq_parser_c, memctl_parser, meminput_tbl) ;

  --  Message sender.

  gps_send : GPSsend
    Generic Map (
      memaddr_bits_g          => memaddr_bits_g
    )
    Port Map (
      reset                   => reset or (not sendout),
      clk                     => parse_clk,
      outready_in             => tx_empty,
      msgclass_in             => msgclass,
      msgid_in                => msgid,
      memstart_in             => memstart,
      memlength_in            => memlength,
      meminput_in             => memread_from,
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
      memaddr_bits_g          => memaddr_bits_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      curtime_in              => curtime_in,
      pollinterval_in         => pollinterval_in,
      pollmessages_in         => pollmessages,
      sendready_in            => sendready,
      sendrcv_in              => sendrcv_poll,
      meminput_in             => memread_from,
      memrcv_in               => memreceivers  (memreq_poll_c),
      memreq_out              => memrequesters (memreq_poll_c),
      memaddr_out             => memaddr_poll,
      memread_en_out          => memread_en_poll,
      sendreq_out             => sendreq_poll,
      msgclass_out            => msgclass_poll,
      msgid_out               => msgid_poll,
      outsend_out             => sendout_poll
    ) ;

  memctl_poll                 <= memwrite_en_none_c & memread_en_poll &
                                 memwrite_to_none_c & memaddr_poll ;

  set2D_element (memreq_poll_c, memctl_poll, meminput_tbl) ;

  --  Normally the message send information would be run through a
  --  multiplexer to choose which sender's message will be sent.  However,
  --  there is currently only a single sender so the signals are mapped
  --  directly.

  msgclass                    <= msgclass_poll ;
  msgid                       <= msgid_poll ;
  memstart                    <= (others => '0') ;
  memlength                   <= (others => '0') ;

  sendreq (send_poll_c)       <= sendreq_poll ;
  sendrcv_poll                <= sendrcv (send_poll_c) ;

  sendrcv (send_poll_c)       <= sendreq (send_poll_c) ;

  sendout                     <= sendout_poll ;

  --  Handle AssistNow Autonomous status messages.

  gps_aopstatus : AOPstatus
    Generic Map (
      memaddr_bits_g          => memaddr_bits_g,
      quiet_count_g           => 5
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      msgnumber_in            => msg_number,
      msgreceived_in          => msg_received,
      tempbank_in             => tempbank,
      memdata_in              => memread_from,
      memrcv_in               => memreceivers  (memreq_aopstat_c),
      memreq_out              => memrequesters (memreq_aopstat_c),
      memaddr_out             => memaddr_aopstat,
      memread_en_out          => memread_en_aopstat,
      running_out             => aop_running_out
    ) ;

  memctl_aopstat              <= memwrite_en_none_c & memread_en_aopstat &
                                 memwrite_to_none_c & memaddr_aopstat ;

  set2D_element (memreq_aopstat_c, memctl_aopstat, meminput_tbl) ;

  --  Time mark generator.

  gps_timemark : TimeMark
    Generic Map (
      memaddr_bits_g          => memaddr_bits_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      curtime_in              => curtime_in,
      posbank_in              => databank (msg_ubx_nav_sol_ramblock_c),
      tmbank_in               => databank (msg_ubx_tim_tm2_ramblock_c),
      memdata_in              => memread_from,
      memrcv_in               => memreceivers  (memreq_timemark_c),
      memreq_out              => memrequesters (memreq_timemark_c),
      memaddr_out             => memaddr_timemark,
      memread_en_out          => memread_en_timemark,
      memwrite_en_out         => memwrite_en_timemark,
      memoutput_out           => memwrite_to_timemark,
      marker_out              => timemarker_out,
      req_position_out        => tm_req_position,
      req_timemark_out        => tm_req_timemark
    ) ;

  memctl_timemark             <= memwrite_en_timemark &
                                 memread_en_timemark &
                                 memwrite_to_timemark & memaddr_timemark ;

  set2D_element (memreq_timemark_c, memctl_timemark, meminput_tbl) ;

  --  Poll request combination signals.  Always poll for position and
  --  AssistNow status info.

  pollmessages (msg_ubx_nav_sol_number_c)       <= tm_req_position or '1' ;
  pollmessages (msg_ubx_nav_aopstatus_number_c) <= '1' ;
  pollmessages (msg_ubx_tim_tm2_number_c)       <= tm_req_timemark ;

  --------------------------------------------------------------------------
  --  Implement the GPS UART tx clock.
  --------------------------------------------------------------------------

  uart_tx_clk : process (reset, clk)
  begin
    if (reset = '1') then
      tx_clk                  <= '0' ;
      tx_clk_counter          <= (others => '0') ;

    elsif (rising_edge (clk)) then

      --  Toggle the clock line when the counter reach its max
      --  value.  Otherwise simply increment the clock counter.

      if (tx_clk_counter /= tx_clk_cnt_c) then
        tx_clk_counter      <= tx_clk_counter + 1 ;
      else
        tx_clk_counter      <= (others => '0') ;

        tx_clk              <= not tx_clk ;
      end if ;
    end if ;
  end process uart_tx_clk ;

  --  Enable the gated transmitter clock when time to load a byte and
  --  disable it after the byte is sent.

  uart_tx_gated_clk : process (reset, tx_clk)
  begin
    if (reset = '1') then
      tx_gated_clk_en       <= '0' ;

    elsif (falling_edge (tx_clk))
      if (tx_load = '1') then
        tx_gated_clk_en     <= '1' ;

      elsif (tx_empty = '1') then
        tx_gated_clk_en     <= '0' ;
      end if ;
    end if ;
  end process uart_tx_gated_clk ;

  tx_gated_clk              <= tx_clk and tx_gated_clk_en ;


  --------------------------------------------------------------------------
  --  Implement the GPS parser clock.
  --------------------------------------------------------------------------

  gps_parse_clk : process (reset, clk)
  begin
    if (reset = '1') then
      parse_clk             <= '0' ;
      parse_clk_counter     <= (others => '0') ;

    elsif (rising_edge (clk)) then

      --  Toggle the clock line when the counter reach its max
      --  value.  Otherwise simply increment the clock counter.

      if (parse_clk_counter /= parse_clk_cnt_c) then
        parse_clk_counter   <= parse_clk_counter + 1 ;
      else
        parse_clk_counter      <= (others => '0') ;

        parse_clk              <= not parse_clk ;
      end if ;
    end if ;
  end process gps_parse_clk ;

  --  Enable the gated memory clock when there is at least one memory
  --  requester, and disable it when there are none.  The memory clock is
  --  inverted from the parse clock requiring the gating clock edge to be
  --  rising rather than falling.

  mem_gated_clk : process (reset, parse_clk)
  begin
    if (reset = '1') then
      mem_gated_clk_en      <= '0' ;

    elsif (rising_edge (parse_clk))
      if (memrequesters = 0) then
        mem_gated_clk_en    <= '0' ;
      else
        mem_gated_clk_en    <= '1' ;
      end if ;
    end if ;
  end process mem_gated_clk ;


end architecture structural ;
