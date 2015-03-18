------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Poll messages from the GPS.
--! @details    Poll messages from the GPS.  The set of messages to poll is
--!             specified by a bit vector.  The time between polls can be
--!             changed.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

library WORK ;
use WORK.Utilities.all ;        --  General purpose definitons.

use WORK.GPS_Clock.all ;        --  GPS clock definitions.
use WORK.gps_message_ctl.all ;  --  GPS message control definitions.


------------------------------------------------------------------------------
--
--! @brief      GPS Message Poller.
--! @details    Poll messages from the GPS.
--!
--! @param      MEMADDR_BITS  Bit width of the memory address.
--! @param      reset         Reset the entity to an initial state.
--! @param      clk           Clock used to move throuth states in the entity
--!                           and its components.
--! @param      curtime       Current time since reset, continually updated.
--! @param      pollinterval  Number of seconds between poll starts.
--! @param      pollmessages  Bit vector specifying which messages to poll.
--! @param      sendready     The message sender is ready for another message.
--! @param      sendrcv       The message sender is allocated to this entity.
--! @param      meminput      Data byte read from memory that is addressed.
--! @param      memrcv        Receive access to memory.
--! @param      memreq        Request access to memory.
--! @param      memaddr       Address of the byte of memory to read.
--! @param      memread_en    Enable the memory for reading.
--! @param      sendreq       Request access to the message sender.
--! @param      msgclass      Class of the message to send.
--! @param      msgid         ID of the message to sent.
--! @param      outsend       Send the message.
--
------------------------------------------------------------------------------

entity GPSpoll is

  Generic (
    MEMADDR_BITS          : natural := 9
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    curtime               : in    std_logic_vector (GPS_TIME_BITS-1 downto 0) ;
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

end entity GPSpoll ;


architecture behavior of GPSpoll is

  --  Resource allocator to find next message to poll.

  component ResourceAllocator is

    Generic (
      REQUESTER_CNT       : natural   :=  8 ;
      NUMBER_LEN          : natural   :=  3 ;
      PRIORITIZED         : std_logic := '1'
    ) ;
    Port (
      reset               : in    std_logic ;
      clk                 : in    std_logic ;
      requesters          : in    std_logic_vector (REQUESTER_CNT-1 downto 0) ;
      receivers           : out   std_logic_vector (REQUESTER_CNT-1 downto 0) ;
      receiver_no         : out   unsigned (NUMBER_LEN-1 downto 0)
    ) ;

  end component ResourceAllocator ;

   --  Poll Generation States.

  type PollState is   (
    POLL_STATE_START,
    POLL_STATE_WAIT,
    POLL_STATE_GET_SENDER,
    POLL_STATE_WAIT_SENDER,
    POLL_STATE_GET_MEM,
    POLL_STATE_GET_CLASS,
    POLL_STATE_GET_ID,
    POLL_STATE_POLL_START,
    POLL_STATE_POLL_WAIT,
    POLL_STATE_RELEASE
  ) ;

  signal cur_state        : PollState ;

  --  Output signals that must be read.

  signal  mem_address     : unsigned (memaddr'length-1 downto 0) ;

  --  Poll information.

  constant poll_zero      : std_logic_vector (MSG_COUNT-1 downto 0) :=
                                          (others => '0') ;

  signal poll_select      : std_logic ;
  signal poll_init        : std_logic_vector (MSG_COUNT-1 downto 0) ;
  signal poll_input       : std_logic_vector (MSG_COUNT-1 downto 0) ;
  signal polled_messages  : std_logic_vector (MSG_COUNT-1 downto 0) ;
  signal message_number   : unsigned (MSG_COUNT_BITS-1 downto 0) ;
  signal message_bit      : std_logic_vector (MSG_COUNT-1 downto 0) ;

  --  Timing information.

  signal newpoll          : std_logic ;
  signal pollcounter      : unsigned (pollinterval'length-1 downto 0) ;
  signal millicounter     : unsigned (9 downto 0) ;
  signal milliclock       : std_logic ;

begin

  --  Output signals that must be read.

  memaddr     <= std_logic_vector (mem_address) ;

  --  The millisecond clock is derived from the reset clock.

  milliclock  <= curtime (GPS_TIME_NANOBITS-1) ;

  --  Poll input is set to initial signals first.
  
  with poll_select select
    poll_input      <= poll_init when '0',
                       pollmessages and not polled_messages when others ;

  --  Resource allocator to find next message to poll.

  msg_select: ResourceAllocator
    Generic Map (
      REQUESTER_CNT       => MSG_COUNT,
      NUMBER_LEN          => MSG_COUNT_BITS,
      PRIORITIZED         => '0'
    )
    Port Map (
      reset               => reset,
      clk                 => clk,
      requesters          => poll_input,
      receivers           => message_bit,
      receiver_no         => message_number
    ) ;


  ------------------------------------------------------------------------------
  --
  --! @brief      Determine when the current poll period has ended.
  --! @details    This process is clocked by milliseconds to determine when
  --!             the current poll period has ended by counting the seconds
  --!             since it started.
  --!
  --! @param      reset         Reset the Parser.
  --! @param      milliclock    Millisecond clock that drives the counters.
  --
  ------------------------------------------------------------------------------

  poll_period:  process (reset, milliclock)
  begin
    if reset = '1' then
      millicounter      <= (others => '0') ;
      pollcounter       <= (others => '0') ;
      newpoll           <= '1' ;

    elsif milliclock'event and milliclock = '1' then
      newpoll           <= '0' ;

      if millicounter /= 10 then
        millicounter    <= millicounter + 1 ;
      else
        millicounter    <= (others => '0') ;

        if pollcounter /= pollinterval then
          pollcounter   <= pollcounter + 1 ;
        else
          pollcounter   <= (others => '0') ;
          newpoll       <= '1' ;
        end if ;
      end if ;
    end if ;
  end process poll_period ;


  ------------------------------------------------------------------------------
  --
  --! @brief      Poll the next message on the GPS.
  --! @details    Determine the next message to poll on the GPS that has not
  --!             been polled in this poll interval.  A zero poll interval
  --!             disables polling.
  --!
  --! @param      reset         Reset the Parser.
  --! @param      clk           Multi-state per character clock.
  --
  ------------------------------------------------------------------------------

  poll_messages:  process (reset, clk)
  begin
    if reset = '1' then
      memreq                <= '0' ;
      memread_en            <= '0' ;
      mem_address           <= (others => '0') ;
      outsend               <= '0' ;
      sendreq               <= '0' ;
      polled_messages       <= (others => '0') ;
      poll_select           <= '0' ;
      poll_init             <= (others => '1') ;
      cur_state             <= POLL_STATE_START ;

    elsif clk'event and clk = '1' then

      --  Clear the polled message mask when a new poll interval is started.

      if newpoll = '1' then
        polled_messages     <= (others => '0') ;
      end if ;

      --  Poll selection and initiation states.

      case cur_state is

        --  Wait until things have settled down before starting operations.
        
        when POLL_STATE_START       =>
          if message_bit /= poll_zero then
            poll_init       <= (others => '0') ;
          
          elsif message_bit = poll_zero and poll_init = poll_zero then
            poll_select     <= '1' ;
            cur_state       <= POLL_STATE_WAIT ;
          else
            cur_state       <= POLL_STATE_START ;
          end if ;

        --  Wait until there is a request for a poll.

        when POLL_STATE_WAIT        =>
          if pollinterval /= 0 and unsigned (message_bit) /= 0 then
            sendreq         <= '1' ;
            cur_state       <= POLL_STATE_GET_SENDER ;
          else
            sendreq         <= '0' ;
            cur_state       <= POLL_STATE_WAIT ;
          end if ;

        --  Wait until the message sender is available and ready.

        when POLL_STATE_GET_SENDER  =>
          if sendrcv = '1' then
            cur_state       <= POLL_STATE_WAIT_SENDER ;
          else
            cur_state       <= POLL_STATE_GET_SENDER ;
          end if ;

        when POLL_STATE_WAIT_SENDER =>
          if sendready = '1' then
            memreq          <= '1' ;
            cur_state       <= POLL_STATE_GET_MEM ;
          else
            cur_state       <= POLL_STATE_WAIT_SENDER ;
          end if ;

        --  Wait until access to memory is available.

        when POLL_STATE_GET_MEM     =>
          if memrcv = '1' then
            mem_address     <= RESIZE (CONST_UNSIGNED (MSG_ROM_BASE +
                                                       MSG_ID_TBL, 1) +
                                       SHIFT_LEFT_LL (message_number, 1),
                                       mem_address'length) ;
            memread_en      <= '1' ;
            cur_state       <= POLL_STATE_GET_CLASS ;
          else
            cur_state       <= POLL_STATE_GET_MEM ;
          end if ;

        --  Read the message Class and ID from ROM.

        when POLL_STATE_GET_CLASS   =>
          msgclass          <= meminput ;
          mem_address       <= mem_address + 1 ;
          cur_state         <= POLL_STATE_GET_ID ;

        when POLL_STATE_GET_ID      =>
          msgid             <= meminput ;
          memread_en        <= '0' ;
          memreq            <= '0' ;
          outsend           <= '1' ;
          cur_state         <= POLL_STATE_POLL_START ;

        --  Wait until the poll has started and finished then mark the poll as
        --  having completed and remove it from those pending.

        when POLL_STATE_POLL_START  =>
          if sendready = '0' then
            outsend         <= '0' ;
            cur_state       <= POLL_STATE_POLL_WAIT ;
          else
            cur_state       <= POLL_STATE_POLL_START ;
          end if ;

        when POLL_STATE_POLL_WAIT   =>
          if sendready = '1' then
            sendreq         <= '0' ;
            polled_messages <= polled_messages or message_bit ;
            cur_state       <= POLL_STATE_RELEASE ;
          else
            cur_state       <= POLL_STATE_POLL_WAIT ;
          end if ;

        when POLL_STATE_RELEASE     =>
          if sendrcv = '0' then
            cur_state       <= POLL_STATE_WAIT ;
          else
            cur_state       <= POLL_STATE_RELEASE ;
          end if ;
       end case ;
    end if ;
  end process poll_messages ;

end behavior ;
