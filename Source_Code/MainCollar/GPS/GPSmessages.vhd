------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Handles GPS messages sent to and recevied from the UBX GPS.
--! @details    Generates GPS messages to the UBX GPS and receives messages
--!             from it.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;

library WORK ;
use WORK.Utilities.all ;        --  General use utilities.

use WORK.GPS_Clock.all ;        --  GPS type clock definitions.

use WORK.gps_message_ctl.all ;  --  GPS message control definitions.
use WORK.msg_ubx_nav_sol.all ;
use WORK.msg_ubx_nav_aopstatus.all ;
use WORK.msg_ubx_tim_tm2.all ;


------------------------------------------------------------------------------
--
--! @brief      GPS message manager.
--! @details    Handles messages to and from the UBX GPS.
--!
--! @param      CLK_FREQ          Frequency of the clock signal.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move throuth states in the
--!                               entity and its components.
--! @param      curtime           Time since reset in GPS time format.
--! @param      pollinterval      Number of seconds between message polls.
--! @param      gpsmem_clock      Clock used to drive the memory from port B.
--! @param      gpsmem_addr       Address to read from memory port B.
--! @param      gpsmem_read_en    Read enable for memory port B.
--! @param      gps_rx            UART receive line from the GPS.
--! @param      gps_tx            UART transmit line to the GPS.
--! @param      timemarker        Signal sent to GPS to generate a time mark.
--! @param      aop_running       AssistNow Autonomous is currently running.
--! @param      gpsmem_read_from  Data read from memory on port B.
--
------------------------------------------------------------------------------

entity GPSmessages is

  Generic (
    CLK_FREQ              : natural := 50e6
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    curtime               : in    GPS_Time ;
    pollinterval          : in    unsigned (13 downto 0) ;
    gpsmem_clock          : in    std_logic ;
    gpsmem_addr           : in    std_logic_vector (8 downto 0) ;
    gpsmem_read_en        : in    std_logic ;
    gps_rx                : in    std_logic ;
    gps_tx                : out   std_logic ;
    timemarker            : out   std_logic ;
    aop_running           : out   std_logic ;
    gpsmem_read_from      : out   std_logic_vector (7 downto 0)
  ) ;

end entity GPSmessages ;


architecture behavior of GPSmessages is

  --  Resource allicator/multiplexer allows multiple entries to share access to
  --  the same resource.

  component ResourceMUX is

    Generic (
      REQUESTER_CNT         : natural   :=  8 ;
      RESOURCE_BITS         : natural   :=  8
    ) ;
    Port (
      reset                 : in    std_logic ;
      clk                   : in    std_logic ;
      requesters            : in    std_logic_vector (REQUESTER_CNT-1 downto 0) ;
      resource_tbl          : in    std_logic_2D (REQUESTER_CNT-1 downto 0,
                                                  RESOURCE_BITS-1 downto 0) ;
      receivers             : out   std_logic_vector (REQUESTER_CNT-1 downto 0) ;
      resources             : out   std_logic_vector (RESOURCE_BITS-1 downto 0)
    ) ;

  end component ResourceMUX ;

  --  Memory component.

  component gps_ram IS
    PORT
    (
      address_a		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      address_b		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      clock_a		: IN STD_LOGIC  := '1';
      clock_b		: IN STD_LOGIC ;
      data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
      rden_a		: IN STD_LOGIC  := '1';
      rden_b		: IN STD_LOGIC  := '1';
      wren_a		: IN STD_LOGIC  := '0';
      wren_b		: IN STD_LOGIC  := '0';
      q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
      q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
    );
  END component gps_ram;

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
      MEMADDR_BITS          : natural := 8
    ) ;
    Port (
      reset                 : in    std_logic ;
      clk                   : in    std_logic ;
      curtime               : in    GPS_Time ;
      inbyte                : in    std_logic_vector (7 downto 0) ;
      inready               : in    std_logic ;
      meminput              : in    std_logic_vector (7 downto 0) ;
      memrcv                : in    std_logic ;
      memreq                : out   std_logic ;
      memoutput             : out   std_logic_vector (7 downto 0) ;
      memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
      memread_en            : out   std_logic ;
      memwrite_en           : out   std_logic ;
      datavalid             : out   std_logic_vector (MSG_RAM_BLOCKS-1 downto 0) ;
      tempbank              : out   std_logic ;
      msgnumber             : out   std_logic_vector (MSG_COUNT_BITS-1 downto 0) ;
      msgreceived           : out   std_logic
    ) ;

  end component GPSmessageParser ;

  --  Message sender.

  component GPSsend is

    Generic (
      MEMADDR_BITS          : natural := 8
    ) ;
    Port (
      reset                 : in    std_logic ;
      clk                   : in    std_logic ;
      outready              : in    std_logic ;
      msgclass              : in    std_logic_vector (7 downto 0) ;
      msgid                 : in    std_logic_vector (7 downto 0) ;
      memstart              : in    std_logic_vector (MEMADDR_BITS-1 downto 0) ;
      memlength             : in    unsigned (15 downto 0) ;
      meminput              : in    std_logic_vector (7 downto 0) ;
      memrcv                : in    std_logic ;
      memreq                : out   std_logic ;
      memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
      memread_en            : out   std_logic ;
      outchar               : out   std_logic_vector (7 downto 0) ;
      outsend               : out   std_logic ;
      outdone               : out   std_logic
    ) ;

  end component GPSsend ;

  --  Message poller.

  component GPSpoll is

    Generic (
      MEMADDR_BITS          : natural := 8
    ) ;
    Port (
      reset                 : in    std_logic ;
      clk                   : in    std_logic ;
      curtime               : in    GPS_Time ;
      pollinterval          : in    unsigned (13 downto 0) ;
      pollmessages          : in    std_logic_vector (MSG_COUNT-1 downto 0) ;
      sendready             : in    std_logic ;
      sendrcv               : in    std_logic ;
      meminput              : in    std_logic_vector (7 downto 0) ;
      memrcv                : in    std_logic ;
      memreq                : out   std_logic ;
      memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
      memread_en            : out   std_logic ;
      sendreq               : out   std_logic ;
      msgclass              : out   std_logic_vector (7 downto 0) ;
      msgid                 : out   std_logic_vector (7 downto 0) ;
      outsend               : out   std_logic
    ) ;

  end component GPSpoll ;

  --  Handle AssistNow Autonomous status messages.

  component AOPstatus is

    Generic (
      MEMADDR_BITS          : natural := 8 ;
      QUIET_COUNT           : natural := 8
    ) ;
    Port (
      clk                   : in    std_logic ;
      reset                 : in    std_logic ;
      msgnumber             : in    std_logic_vector (MSG_COUNT_BITS-1 downto 0) ;
      msgreceived           : in    std_logic ;
      tempbank              : in    std_logic ;
      memdata               : in    std_logic_vector (7 downto 0) ;
      memrcv                : in    std_logic ;
      memreq                : out   std_logic ;
      memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
      memread_en            : out   std_logic ;
      running               : out   std_logic
    ) ;

  end component AOPstatus ;

  --  Generate Time Marks periodically.

  component TimeMark is

    Generic (
      TIME_MARK_INTERVAL    : natural := 5 * 60 * 1000 ;
      MIN_POS_ACCURACY      : natural := 100 * 100 ;
      MAX_POS_AGE           : natural := 15 * 60 * 1000 ;
      MEMADDR_BITS          : natural := 8
    ) ;
    Port (
      clk                   : in    std_logic ;
      reset                 : in    std_logic ;
      curtime               : in    GPS_Time ;
      posbank               : in    std_logic ;
      tmbank                : in    std_logic ;
      memdata               : in    std_logic_vector (7 downto 0) ;
      memrcv                : in    std_logic ;
      memreq                : out   std_logic ;
      memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
      memread_en            : out   std_logic ;
      memwrite_en           : out   std_logic ;
      memoutput             : out   std_logic_vector (7 downto 0) ;
      marker                : out   std_logic ;
      req_position          : out   std_logic ;
      req_timemark          : out   std_logic
    ) ;

  end component TimeMark ;

  --  Memory requesters.

  constant MEMREQ_PARSER      : natural := 0 ;
  constant MEMREQ_SEND        : natural := MEMREQ_PARSER + 1 ;
  constant MEMREQ_POLL        : natural := MEMREQ_SEND + 1 ;
  constant MEMREQ_AOPSTAT     : natural := MEMREQ_POLL + 1 ;
  constant MEMREQ_TIMEMARK    : natural := MEMREQ_AOPSTAT + 1 ;

  constant MEM_USER_CNT       : natural := MEMREQ_TIMEMARK + 1 ;

  --  Memory control signals.

  constant MEMADDR_BITS       : natural := 9 ;
  constant MEMDATA_BITS       : natural := 8 ;
  constant MEM_IO_BITS        : natural := MEMADDR_BITS + MEMDATA_BITS + 2 ;

  signal memrequesters        : std_logic_vector (MEM_USER_CNT-1 downto 0) ;
  signal memreceivers         : std_logic_vector (MEM_USER_CNT-1 downto 0) ;

  signal memread_from         : std_logic_vector (MEMDATA_BITS-1 downto 0) ;

  signal meminput_tbl         : std_logic_2D (MEM_USER_CNT-1 downto 0,
                                              MEM_IO_BITS-1 downto 0) ;

  signal memselected          : std_logic_vector (MEM_IO_BITS-1 downto 0) ;

  alias  memaddr              : std_logic_vector (MEMADDR_BITS-1 downto 0) is
                                memselected      (MEMADDR_BITS-1 downto 0) ;
  alias  memwrite_to          : std_logic_vector (MEMDATA_BITS-1 downto 0) is
                                memselected      (MEMADDR_BITS +
                                                  MEMDATA_BITS-1 downto
                                                  MEMADDR_BITS) ;
  alias  memread_en           : std_logic is
                                memselected      (MEMADDR_BITS +
                                                  MEMDATA_BITS) ;
  alias  memwrite_en          : std_logic is
                                memselected      (MEMADDR_BITS +
                                                  MEMDATA_BITS + 1) ;

  --  Message requester I/O bits.  Requesters that do not write to memory use
  --  the memwrite_to_none and memwrite_en_none constants instead of signals
  --  that they generate themselves.

  constant memwrite_to_none   : std_logic_vector (MEMDATA_BITS-1 downto 0) :=
                                      (others => '0') ;
  constant memwrite_en_none   : std_logic := '0' ;

  signal memaddr_parser       : std_logic_vector (MEMADDR_BITS-1 downto 0) ;
  signal memwrite_to_parser   : std_logic_vector (MEMDATA_BITS-1 downto 0) ;
  signal memwrite_en_parser   : std_logic ;
  signal memread_en_parser    : std_logic ;
  signal memctl_parser        : std_logic_vector (MEM_IO_BITS-1 downto 0) ;

  signal memaddr_send         : std_logic_vector (MEMADDR_BITS-1 downto 0) ;
  signal memread_en_send      : std_logic ;
  signal memctl_send          : std_logic_vector (MEM_IO_BITS-1 downto 0) ;

  signal memaddr_poll         : std_logic_vector (MEMADDR_BITS-1 downto 0) ;
  signal memread_en_poll      : std_logic ;
  signal memctl_poll          : std_logic_vector (MEM_IO_BITS-1 downto 0) ;

  signal memaddr_aopstat      : std_logic_vector (MEMADDR_BITS-1 downto 0) ;
  signal memread_en_aopstat   : std_logic ;
  signal memctl_aopstat       : std_logic_vector (MEM_IO_BITS-1 downto 0) ;

  signal memaddr_timemark     : std_logic_vector (MEMADDR_BITS-1 downto 0) ;
  signal memwrite_to_timemark : std_logic_vector (MEMDATA_BITS-1 downto 0) ;
  signal memwrite_en_timemark : std_logic ;
  signal memread_en_timemark  : std_logic ;
  signal memctl_timemark      : std_logic_vector (MEM_IO_BITS-1 downto 0) ;

  --  GPS UART connecting signals.

  constant BAUD_RATE          : natural := 9600 ;
  constant RX_SAMPLE_CNT      : natural :=   16 ;
  constant RX_CLOCK_CNT       : natural :=
              natural (real (CLK_FREQ) /
                       real (BAUD_RATE * RX_SAMPLE_CNT * 2)) - 1 ;

  constant RX_CLOCK_BITS      : natural := const_bits (RX_CLOCK_CNT) ;

  constant TX_CLOCK_CNT       : natural := RX_SAMPLE_CNT - 1 ;
  constant TX_CLOCK_BITS      : natural := const_bits (TX_CLOCK_CNT) ;

  signal tx_clock             : std_logic ;
  signal tx_load              : std_logic ;
  signal tx_empty             : std_logic ;
  signal tx_data              : std_logic_vector (7 downto 0) ;
  signal tx_clock_counter     : unsigned (TX_CLOCK_BITS-1 downto 0) ;

  signal rx_clock             : std_logic ;
  signal rx_empty             : std_logic ;
  signal rx_data              : std_logic_vector (7 downto 0) ;
  signal rx_clock_counter     : unsigned (RX_CLOCK_BITS-1 downto 0) ;

  --  Parsed message information.

  signal databank             : std_logic_vector (MSG_RAM_BLOCKS-1 downto 0) ;
  signal tempbank             : std_logic ;

  signal msg_number           : std_logic_vector (MSG_COUNT_BITS-1 downto 0) ;
  signal msg_received         : std_logic ;

  --  Information about messages to send.

  constant SEND_POLL          : natural := 0 ;

  constant SENDCNT            : natural := SEND_POLL + 1 ;

  signal msgclass             : std_logic_vector (7 downto 0) ;
  signal msgid                : std_logic_vector (7 downto 0) ;
  signal memstart             : std_logic_vector (MEMADDR_BITS-1 downto 0) ;
  signal memlength            : unsigned (15 downto 0) ;
  signal sendready            : std_logic ;
  signal sendout              : std_logic ;
  signal sendreq              : std_logic_vector (SENDCNT-1 downto 0) ;
  signal sendrcv              : std_logic_vector (SENDCNT-1 downto 0) ;

  --  Information about messages to poll.

  signal pollmessages         : std_logic_vector (MSG_COUNT-1 downto 0) ;
  signal sendreq_poll         : std_logic ;
  signal sendrcv_poll         : std_logic ;
  signal msgclass_poll        : std_logic_vector (7 downto 0) ;
  signal msgid_poll           : std_logic_vector (7 downto 0) ;
  signal sendout_poll         : std_logic ;

  --  Information about timemark messages.

  signal tm_req_position      : std_logic ;
  signal tm_req_timemark      : std_logic ;


begin

  --  Memory multiplexer allows multiple entities to share access to the same
  --  memory module.

  memmux : ResourceMUX
    Generic Map (
      REQUESTER_CNT           => MEM_USER_CNT,
      RESOURCE_BITS           => MEM_IO_BITS
    )
    Port Map (
      reset                   => reset,
      clk                     => clk,
      requesters              => memrequesters,
      resource_tbl            => meminput_tbl,
      receivers               => memreceivers,
      resources               => memselected
    ) ;

  --  Memory component.  Clock is triggered on negative going edge to allow
  --  input signals to propagate in one half clock cycle and to produce
  --  output by the next clock cycle.  The memory is fast enough to produce
  --  output in less than one half clock cycle.

  memory : gps_ram
    Port Map (
      address_a		            => memaddr,
      address_b		            => gpsmem_addr,
      clock_a		              => not clk,
      clock_b		              => gpsmem_clock,
      data_a		              => memwrite_to,
      data_b		              => (others => '0'),
      rden_a		              => memread_en,
      rden_b		              => gpsmem_read_en,
      wren_a		              => memwrite_en,
      wren_b		              => '0',
      q_a		                  => memread_from,
      q_b		                  => gpsmem_read_from
    ) ;

  --  UART connecting the GPS to the sender and receive parser.

  gps_uart : uart
    Port Map (
      reset                   => reset,
      txclk                   => tx_clock,
      ld_tx_data              => tx_load,
      tx_data                 => tx_data,
      tx_enable               => '1',
      tx_out                  => gps_tx,
      tx_empty                => tx_empty,
      rxclk                   => rx_clock,
      uld_rx_data             => not rx_empty,
      rx_data                 => rx_data,
      rx_enable               => '1',
      rx_in                   => gps_rx,
      rx_empty                => rx_empty
    ) ;

  --  GPS Message receiver and parser.

  gps_parser : GPSmessageParser
    Generic Map (
      MEMADDR_BITS            => MEMADDR_BITS
    )
    Port Map (
      reset                   => reset,
      clk                     => clk,
      curtime                 => curtime,
      inbyte                  => rx_data,
      inready                 => rx_empty,
      meminput                => memread_from,
      memrcv                  => memreceivers  (MEMREQ_PARSER),
      memreq                  => memrequesters (MEMREQ_PARSER),
      memoutput               => memwrite_to_parser,
      memaddr                 => memaddr_parser,
      memread_en              => memread_en_parser,
      memwrite_en             => memwrite_en_parser,
      datavalid               => databank,
      tempbank                => tempbank,
      msgnumber               => msg_number,
      msgreceived             => msg_received
    ) ;

  memctl_parser               <= memwrite_en_parser & memread_en_parser &
                                 memwrite_to_parser & memaddr_parser ;

  set2D_element (MEMREQ_PARSER, memctl_parser, meminput_tbl) ;

  --  Message sender.

  gps_send : GPSsend
    Generic Map (
      MEMADDR_BITS            => MEMADDR_BITS
    )
    Port Map (
      reset                   => reset or (not sendout),
      clk                     => clk,
      outready                => tx_empty,
      msgclass                => msgclass,
      msgid                   => msgid,
      memstart                => memstart,
      memlength               => memlength,
      meminput                => memread_from,
      memrcv                  => memreceivers  (MEMREQ_SEND),
      memreq                  => memrequesters (MEMREQ_SEND),
      memaddr                 => memaddr_send,
      memread_en              => memread_en_send,
      outchar                 => tx_data,
      outsend                 => tx_load,
      outdone                 => sendready
    ) ;

  memctl_send                 <= memwrite_en_none & memread_en_send &
                                 memwrite_to_none & memaddr_send ;

  set2D_element (MEMREQ_SEND, memctl_send, meminput_tbl) ;

  --  Message poller.

  gps_poll : GPSpoll
    Generic Map (
      MEMADDR_BITS            => MEMADDR_BITS
    )
    Port Map (
      reset                   => reset,
      clk                     => clk,
      curtime                 => curtime,
      pollinterval            => pollinterval,
      pollmessages            => pollmessages,
      sendready               => sendready,
      sendrcv                 => sendrcv_poll,
      meminput                => memread_from,
      memrcv                  => memreceivers  (MEMREQ_POLL),
      memreq                  => memrequesters (MEMREQ_POLL),
      memaddr                 => memaddr_poll,
      memread_en              => memread_en_poll,
      sendreq                 => sendreq_poll,
      msgclass                => msgclass_poll,
      msgid                   => msgid_poll,
      outsend                 => sendout_poll
    ) ;

  memctl_poll                 <= memwrite_en_none & memread_en_poll &
                                 memwrite_to_none & memaddr_poll ;

  set2D_element (MEMREQ_POLL, memctl_poll, meminput_tbl) ;

  --  Normally the message send information would be run through a multiplexer
  --  to choose which sender's message will be sent.  However, there is
  --  currently only a single sender so the signals are mapped directly.

  msgclass                    <= msgclass_poll ;
  msgid                       <= msgid_poll ;
  memstart                    <= (others => '0') ;
  memlength                   <= (others => '0') ;

  sendreq (SEND_POLL)         <= sendreq_poll ;
  sendrcv_poll                <= sendrcv (SEND_POLL) ;

  sendrcv (SEND_POLL)         <= sendreq (SEND_POLL) ;

  sendout                     <= sendout_poll ;

  --  Handle AssistNow Autonomous status messages.

  gps_aopstatus : AOPstatus
    Generic Map (
      MEMADDR_BITS            => MEMADDR_BITS,
      QUIET_COUNT             => 5
    )
    Port Map (
      clk                     => clk,
      reset                   => reset,
      msgnumber               => msg_number,
      msgreceived             => msg_received,
      tempbank                => tempbank,
      memdata                 => memread_from,
      memrcv                  => memreceivers  (MEMREQ_AOPSTAT),
      memreq                  => memrequesters (MEMREQ_AOPSTAT),
      memaddr                 => memaddr_aopstat,
      memread_en              => memread_en_aopstat,
      running                 => aop_running
    ) ;

  memctl_aopstat              <= memwrite_en_none & memread_en_aopstat &
                                 memwrite_to_none & memaddr_aopstat ;

  set2D_element (MEMREQ_AOPSTAT, memctl_aopstat, meminput_tbl) ;

  --  Time mark generator.

  gps_timemark : TimeMark
    Generic Map (
      MEMADDR_BITS            => MEMADDR_BITS
    )
    Port Map (
      clk                     => clk,
      reset                   => reset,
      curtime                 => curtime,
      posbank                 => databank (MSG_UBX_NAV_SOL_RAMBLOCK),
      tmbank                  => databank (MSG_UBX_TIM_TM2_RAMBLOCK),
      memdata                 => memread_from,
      memrcv                  => memreceivers  (MEMREQ_TIMEMARK),
      memreq                  => memrequesters (MEMREQ_TIMEMARK),
      memaddr                 => memaddr_timemark,
      memread_en              => memread_en_timemark,
      memwrite_en             => memwrite_en_timemark,
      memoutput               => memwrite_to_timemark,
      marker                  => timemarker,
      req_position            => tm_req_position,
      req_timemark            => tm_req_timemark
    ) ;

  memctl_timemark             <= memwrite_en_timemark & memread_en_timemark &
                                 memwrite_to_timemark & memaddr_timemark ;

  set2D_element (MEMREQ_TIMEMARK, memctl_timemark, meminput_tbl) ;

  --  Poll request combination signals.  Always poll for position and
  --  AssistNow status info.

  pollmessages (MSG_UBX_NAV_SOL_NUMBER)       <= tm_req_position or '1' ;
  pollmessages (MSG_UBX_NAV_AOPSTATUS_NUMBER) <= '1' ;
  pollmessages (MSG_UBX_TIM_TM2_NUMBER)       <= tm_req_timemark ;

  --  Implement the GPS UART clocks.

  uart_clocks : process (reset, clk)
  begin
    if reset = '1' then
      rx_clock                <= '0' ;
      rx_clock_counter        <= (others => '0') ;
      tx_clock                <= '0' ;
      tx_clock_counter        <= (others => '0') ;

    elsif clk'event and clk = '1' then

      --  Toggle the clock line when the counters reach their max
      --  values.  Otherwise simply increment the clock counters.

      if rx_clock_counter /= RX_CLOCK_CNT then
        rx_clock_counter      <= rx_clock_counter + 1 ;
      else
        rx_clock_counter      <= (others => '0') ;

        rx_clock              <= not rx_clock ;

        if tx_clock_counter /= TX_CLOCK_CNT then
          tx_clock_counter    <= tx_clock_counter + 1 ;
        else
          tx_clock_counter    <= (others => '0') ;

          tx_clock            <= not tx_clock ;
        end if ;
      end if ;
    end if ;
  end process uart_clocks ;


end behavior ;
