----------------------------------------------------------------------------
--
--! @file       GPSpoll.vhd
--! @brief      Poll messages from the GPS.
--! @details    Poll messages from the GPS.  The set of messages to poll is
--!             specified by a bit vector.  The time between polls can be
--!             changed.
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

library GENERAL ;
use GENERAL.Utilities_pkg.all ;     --  General purpose definitons.
use GENERAL.GPS_Clock_pkg.all ;     --  GPS clock definitions.

library WORK ;
use WORK.gps_message_ctl_pkg.all ;  --  GPS message control definitions.


----------------------------------------------------------------------------
--
--! @brief      GPS Message Poller.
--! @details    Poll messages from the GPS.
--!
--! @param      memaddr_bits_g  Bit width of the memory address.
--! @param      reset           Reset the entity to an initial state.
--! @param      clk             Clock used to move throuth states in the
--!                             entity and its components.
--! @param      curtime_in      Current time since reset, continually
--!                             updated.
--! @param      pollinterval_in Number of seconds between poll starts.
--! @param      pollmessages_in Bit vector specifying which messages to
--!                             poll.
--! @param      sendreq_out     Request access to the message sender.
--! @param      sendrcv_in      The message sender is allocated to this
--!                             entity.
--! @param      memreq_out      Request access to memory.
--! @param      memrcv_in       Receive access to memory.
--! @param      memaddr_out     Address of the byte of memory to read.
--! @param      memread_en_out  Enable the memory for reading.
--! @param      meminput_in     Data byte read from memory that is
--!                             addressed.
--! @param      msgclass_out    Class of the message to send.
--! @param      msgid_out       ID of the message to sent.
--! @param      sendready_in    The message sender is ready for another
--!                             message.
--! @param      outsend_out     Send the message.
--
----------------------------------------------------------------------------

entity GPSpoll is

  Generic (
    memaddr_bits_g  : natural := 8
  ) ;
  Port (
    reset           : in    std_logic ;
    clk             : in    std_logic ;
    curtime_in      : in    std_logic_vector (gps_time_bits_c-1 downto 0) ;
    pollinterval_in : in    unsigned (13 downto 0) ;
    pollmessages_in : in    std_logic_vector (msg_count_c-1 downto 0) ;
    sendreq_out     : out   std_logic ;
    sendrcv_in      : in    std_logic ;
    memreq_out      : out   std_logic ;
    memrcv_in       : in    std_logic ;
    memaddr_out     : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
    memread_en_out  : out   std_logic ;
    meminput_in     : in    std_logic_vector (7 downto 0) ;
    msgclass_out    : out   std_logic_vector (7 downto 0) ;
    msgid_out       : out   std_logic_vector (7 downto 0) ;
    sendready_in    : in    std_logic ;
    outsend_out     : out   std_logic
  ) ;

end entity GPSpoll ;


architecture rtl of GPSpoll is

  --  Resource allocator to find next message to poll.

  component ResourceAllocator is

    Generic (
      requester_cnt_g : natural   :=  8 ;
      number_len_g    : natural   :=  3 ;
      prioritized_g   : std_logic := '1'
    ) ;
    Port (
      reset           : in    std_logic ;
      clk             : in    std_logic ;
      requesters_in   : in    std_logic_vector (requester_cnt_g-1
                                                downto 0) ;
      receivers_out   : out   std_logic_vector (requester_cnt_g-1
                                                downto 0) ;
      receiver_no_out : out   unsigned (number_len_g-1 downto 0)
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

  --  Gated clock for state machine.

  signal gated_clk        : std_logic ;
  signal gated_clk_en     : std_logic ;

  --  Output signals that must be read.

  signal mem_address      : unsigned (memaddr_out'length-1 downto 0) ;

  --  Conversion of GPS time as a standard logic vector to GPS_Time record.

  signal curtime          : GPS_Time ;

  --  Poll information.

  constant poll_zero_c    : std_logic_vector (msg_count_c-1 downto 0) :=
                                                  (others => '0') ;

  signal poll_select      : std_logic ;
  signal poll_init        : std_logic_vector (msg_count_c-1 downto 0) ;
  signal poll_input       : std_logic_vector (msg_count_c-1 downto 0) ;
  signal polled_messages  : std_logic_vector (msg_count_c-1 downto 0) ;
  signal message_number   : unsigned (msg_count_bits_c-1 downto 0) ;
  signal message_bit      : std_logic_vector (msg_count_c-1 downto 0) ;

  --  Timing information.

  signal newpoll          : std_logic ;
  signal pollcounter      : unsigned (pollinterval_in'length-1 downto 0) ;
  signal millicounter     : unsigned (9 downto 0) ;
  signal milliclock       : std_logic ;

begin

  --  Output signals that must be read.

  memaddr_out <= std_logic_vector (mem_address) ;

  --  Conversion of current time as a standard logic vector to GPS_Time.

  curtime     <= TO_GPS_TIME (curtime_in) ;

  --  The millisecond clock is derived from the reset clock.

  milliclock  <= curtime.millisecond_nanosecond (gps_time_nanobits_c - 1) ;

  --  Poll input is set to initial signals first.

  with poll_select select
    poll_input      <= poll_init when '0',
                       pollmessages_in and not polled_messages when others ;

  --  Resource allocator to find next message to poll.

  msg_select: ResourceAllocator
    Generic Map (
      requester_cnt_g => msg_count_c,
      number_len_g    => msg_count_bits_c,
      prioritized_g   => '0'
    )
    Port Map (
      reset           => reset,
      clk             => gated_clk,
      requesters_in   => poll_input,
      receivers_out   => message_bit,
      receiver_no_out => message_number
    ) ;


  --------------------------------------------------------------------------
  --  This process is clocked by milliseconds to determine when the current
  --  poll period has ended by counting the seconds since it started.
  --------------------------------------------------------------------------

  poll_period:  process (reset, milliclock)
  begin
    if (reset = '1') then
      millicounter      <= (others => '0') ;
      pollcounter       <= (others => '0') ;
      newpoll           <= '1' ;

    elsif (rising_edge (milliclock)) then
      newpoll           <= '0' ;

      if (millicounter /= 1000) then
        millicounter    <= millicounter + 1 ;
      else
        millicounter    <= (others => '0') ;

        if (pollcounter /= pollinterval_in) then
          pollcounter   <= pollcounter + 1 ;
        else
          pollcounter   <= (others => '0') ;
          newpoll       <= '1' ;
        end if ;
      end if ;
    end if ;
  end process poll_period ;

  --------------------------------------------------------------------------
  --  Gated clock is on when there is something that needs to be polled.
  --------------------------------------------------------------------------

  gate_clk : process (reset, clk)
  begin
    if (reset = '1') then
      gated_clk_en      <= '0' ;

    elsif (falling_edge (clk)) then
      if (newpoll = '1' or unsigned (poll_input) /= 0) then
        gated_clk_en    <= '1' ;

      elsif (poll_select = '1' and unsigned (message_bit) = 0) then
        gated_clk_en    <= '0' ;
      end if ;
    end if ;
  end process gate_clk ;

  gated_clk             <= clk and gated_clk_en ;


  --------------------------------------------------------------------------
  --  Determine the next message to poll on the GPS that has not been polled
  --  in this poll interval.  A zero poll interval disables polling.
  --------------------------------------------------------------------------

  poll_messages:  process (reset, gated_clk)
  begin
    if (reset = '1') then
      memreq_out            <= '0' ;
      memread_en_out        <= '0' ;
      mem_address           <= (others => '0') ;
      outsend_out           <= '0' ;
      sendreq_out           <= '0' ;
      polled_messages       <= (others => '0') ;
      poll_select           <= '0' ;
      poll_init             <= (others => '0') ;
      cur_state             <= POLL_STATE_START ;

    elsif (rising_edge (gated_clk)) then

      --  Clear the polled message mask when a new poll interval is started.

      if (newpoll = '1') then
        polled_messages     <= (others => '0') ;
      end if ;

      --  Poll selection and initiation states.

      case cur_state is

        --  Wait until things have settled down before starting operations.

        when POLL_STATE_START       =>
          if (message_bit /= poll_zero_c) then
            poll_init       <= (others => '0') ;

          elsif (message_bit = poll_zero_c and poll_init = poll_zero_c) then
            poll_select     <= '1' ;
            cur_state       <= POLL_STATE_WAIT ;
          else
            cur_state       <= POLL_STATE_START ;
          end if ;

        --  Wait until there is a request for a poll.

        when POLL_STATE_WAIT        =>
          if (pollinterval_in /= 0 and unsigned (message_bit) /= 0) then
            sendreq_out     <= '1' ;
            cur_state       <= POLL_STATE_GET_SENDER ;
          else
            sendreq_out     <= '0' ;
            cur_state       <= POLL_STATE_WAIT ;
          end if ;

        --  Wait until the message sender is available and ready.

        when POLL_STATE_GET_SENDER  =>
          if (sendrcv_in = '1') then
            cur_state       <= POLL_STATE_WAIT_SENDER ;
          else
            cur_state       <= POLL_STATE_GET_SENDER ;
          end if ;

        when POLL_STATE_WAIT_SENDER =>
          if (sendready_in = '1') then
            memreq_out      <= '1' ;
            cur_state       <= POLL_STATE_GET_MEM ;
          else
            cur_state       <= POLL_STATE_WAIT_SENDER ;
          end if ;

        --  Wait until access to memory is available.

        when POLL_STATE_GET_MEM     =>
          if (memrcv_in = '1') then
            mem_address     <= RESIZE (CONST_UNSIGNED (msg_rom_base_c +
                                                       msg_id_tbl_c, 1) +
                                       SHIFT_LEFT_LL (message_number, 1),
                                       mem_address'length) ;
            memread_en_out  <= '1' ;
            cur_state       <= POLL_STATE_GET_CLASS ;
          else
            cur_state       <= POLL_STATE_GET_MEM ;
          end if ;

        --  Read the message Class and ID from ROM.

        when POLL_STATE_GET_CLASS   =>
          msgclass_out      <= meminput_in ;
          mem_address       <= mem_address + 1 ;
          cur_state         <= POLL_STATE_GET_ID ;

        when POLL_STATE_GET_ID      =>
          msgid_out         <= meminput_in ;
          memread_en_out    <= '0' ;
          memreq_out        <= '0' ;
          outsend_out       <= '1' ;
          cur_state         <= POLL_STATE_POLL_START ;

        --  Wait until the poll has started and finished then mark the poll
        --  as having completed and remove it from those pending.

        when POLL_STATE_POLL_START  =>
          if (sendready_in = '0') then
            outsend_out     <= '0' ;
            cur_state       <= POLL_STATE_POLL_WAIT ;
          else
            cur_state       <= POLL_STATE_POLL_START ;
          end if ;

        when POLL_STATE_POLL_WAIT   =>
          if (sendready_in = '1') then
            sendreq_out     <= '0' ;
            cur_state       <= POLL_STATE_RELEASE ;
          else
            cur_state       <= POLL_STATE_POLL_WAIT ;
          end if ;

        when POLL_STATE_RELEASE     =>
          if (sendrcv_in = '0') then
            polled_messages <= polled_messages or message_bit ;
            cur_state       <= POLL_STATE_WAIT ;
          else
            cur_state       <= POLL_STATE_RELEASE ;
          end if ;
       end case ;
    end if ;
  end process poll_messages ;

end architecture rtl ;
