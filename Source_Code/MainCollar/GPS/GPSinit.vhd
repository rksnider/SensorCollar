----------------------------------------------------------------------------
--
--! @file       GPSinit.vhd
--! @brief      Initialize the GPS.
--! @details    Initialize the GPS by sending configuration messages to it.
--! @author     Emery Newlon
--! @date       Octover 2015
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
--! @brief      GPS Initializer.
--! @details    Initialize the GPS by sending CFG messages to it.
--!
--! @param      memaddr_bits_g    Bit width of the memory address.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move through states in the
--!                               entity and its components.
--! @param      curtime_in        Current time since reset, continually
--!                               updated.
--! @param      dlatch_in         Latch the current time.
--! @param      vlatch_in         Latch the last latched current time.
--! @param      valid_in          The current time is valid now.
--! @param      init_start_in     Start the initialization process.
--! @param      init_done_out     The initialization process has finished.
--! @param      init_select_in    Number of the initialization sequence to
--!                               use.
--! @param      gps_timepulse_in  Timepulse signal from the GPS.
--! @param      sendreq_out       Request access to the message sender.
--! @param      sendrcv_in        The message sender is allocated to this
--!                               entity.
--! @param      memreq_out        Request access to memory.
--! @param      memrcv_in         Receive access to memory.
--! @param      memaddr_out       Address of the byte of memory access.
--! @param      memread_en_out    Enable the memory for reading.
--! @param      memwrite_en_out   Enable the memory for writing.
--! @param      meminput_in       Data byte read from memory that is
--!                               addressed.
--! @param      memoutput_out     Data byte to write to the addessed memory.
--! @param      msgclass_out      Class of the message to send.
--! @param      msgid_out         ID of the message to sent.
--! @param      msglength_out     Payload length of the message to send.
--! @param      msgaddress_out    Address the payload starts at.
--! @param      sendready_in      The message sender is ready for another
--!                               message.
--! @param      outsend_out       Send the message.
--! @param      busy_out          The entity is busy processing.
--
----------------------------------------------------------------------------

entity GPSinit is

  Generic (
    memaddr_bits_g    : natural := 10
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    curtime_in        : in    std_logic_vector (gps_time_bits_c-1 downto 0) ;
    dlatch_in         : in    std_logic ;
    vlatch_in         : in    std_logic ;
    valid_in          : in    std_logic ;
    init_start_in     : in    std_logic ;
    init_done_out     : out   std_logic_vector (msg_init_table_c'length-1
                                                downto 0) ;
    init_select_in    : in    unsigned (msg_init_bits_c-1 downto 0) ;
    gps_timepulse_in  : in    std_logic ;
    sendreq_out       : out   std_logic ;
    sendrcv_in        : in    std_logic ;
    memreq_out        : out   std_logic ;
    memrcv_in         : in    std_logic ;
    memaddr_out       : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
    memread_en_out    : out   std_logic ;
    memwrite_en_out   : out   std_logic ;
    meminput_in       : in    std_logic_vector (7 downto 0) ;
    memoutput_out     : out   std_logic_vector (7 downto 0) ;
    msgclass_out      : out   std_logic_vector (7 downto 0) ;
    msgid_out         : out   std_logic_vector (7 downto 0) ;
    msglength_out     : out   unsigned (15 downto 0) ;
    msgaddress_out    : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
    sendready_in      : in    std_logic ;
    outsend_out       : out   std_logic ;
    busy_out          : out   std_logic
  ) ;

end entity GPSinit ;


architecture rtl of GPSinit is

  --  Initialization signal catcher.  The signal may be shorter than the
  --  clock period used for this entity.  An asynchronous SR flip flop will
  --  still be able to catch the signal.

  signal init_started       : std_logic := '0' ;
  signal start_init         : std_logic ;
  signal timepulse_last     : std_logic ;
  signal init_bit           : unsigned (msg_init_table_c'length-1 downto 0) ;
  signal init_bit_last      : unsigned (msg_init_table_c'length-1 downto 0) ;
  signal init_done          : unsigned (msg_init_table_c'length-1 downto 0) ;

  component SR_FlipFlop is
    Generic (
      set_edge_detect_g     : std_logic := '0' ;
      clear_edge_detect_g   : std_logic := '0'
    ) ;
    Port (
      reset_in              : in    std_logic ;
      set_in                : in    std_logic ;
      result_rd_out         : out   std_logic ;
      result_sd_out         : out   std_logic
    ) ;
  end component SR_FlipFlop ;

  --  Catch part of the startup time to use as a timer.

  signal delay            : unsigned (6 downto 0) ;
  signal milli_count      : std_logic_vector (delay'length-1 downto 0) ;

  component CrossChipReceive is
    Generic (
      data_bits_g             : natural := 8
    ) ;
    Port (
      clk                     : in    std_logic ;
      data_latch_in           : in    std_logic ;
      data_valid_in           : in    std_logic ;
      valid_latch_in          : in    std_logic ;
      data_in                 : in    std_logic_vector (data_bits_g-1
                                                        downto 0) ;
      data_out                : out   std_logic_vector (data_bits_g-1
                                                        downto 0) ;
      data_ready_out          : out   std_logic
    ) ;
  end component CrossChipReceive ;

  --  Poll Generation States.

  type InitState is   (
    INIT_STATE_WAIT,
    INIT_STATE_START,
    INIT_STATE_START_DELAY,
    INIT_STATE_GET_SENDER,
    INIT_STATE_WAIT_SENDER,
    INIT_STATE_GET_MEM,
    INIT_STATE_GET_CLASS,
    INIT_STATE_GET_ID,
    INIT_STATE_LOW_LENGTH,
    INIT_STATE_HIGH_LENGTH,
    INIT_STATE_GET_PAYLOAD,
    INIT_STATE_GET_CTL,
    INIT_STATE_PUT_ZERO,
    INIT_STATE_GET_CHAR,
    INIT_STATE_PUT_CHAR,
    INIT_STATE_MSG_SEND,
    INIT_STATE_MSG_DONE,
    INIT_STATE_DELAY
  ) ;

  signal cur_state        : InitState ;

  --  Entity busy indicators.

  signal process_busy     : std_logic := '0' ;

  --  Memory access signals.

  signal mem_address      : unsigned (memaddr_out'length-1 downto 0) ;
  signal mem_inaddress    : unsigned (memaddr_out'length-1 downto 0) ;
  signal mem_outaddress   : unsigned (memaddr_out'length-1 downto 0) ;

  --  Message signals.

  signal payload_length   : unsigned (msglength_out'length-1 downto 0) ;
  signal bytecount        : unsigned (6 downto 0) ;
  signal last_message     : std_logic ;

  --  Conversion of GPS time as a standard logic vector to GPS_Time record.

  signal curtime          : GPS_Time ;

begin

  --  Output signals that must be read.

  memaddr_out <= std_logic_vector (mem_address) ;

  --  Conversion of current time as a standard logic vector to GPS_Time.

  curtime     <= TO_GPS_TIME (curtime_in) ;

  --  Catch the initialization signal.  The signal may be shorter than the
  --  clock period used for this entity.  An asynchronous SR flip flop will
  --  still be able to catch the signal.
  --  The result will be set if the initialize start signal is set or the
  --  timepulse signal has changed since the last initialization.

  init_sig : SR_FlipFlop
    Port Map (
      reset_in              => init_started,
      set_in                => init_start_in or (gps_timepulse_in xor
                                                 timepulse_last),
      result_rd_out         => start_init
    ) ;

  --  Catch a part of the startup time to use as a timer.

  delay_catch : CrossChipReceive
    Generic Map (
      data_bits_g             => delay'length
    )
    Port Map (
      clk                     => clk,
      data_latch_in           => dlatch_in,
      data_valid_in           => vlatch_in,
      valid_latch_in          => valid_in,
      data_in                 => curtime.week_millisecond (delay'length-1
                                                           downto 0),
      data_out                => milli_count
    ) ;

  --  Initialation bit for current initialization.

  init_bit          <= SHIFT_LEFT (TO_UNSIGNED (1, init_bit'length),
                                   TO_INTEGER  (init_select_in)) ;

  init_done_out     <= std_logic_vector (init_done) ;

  --  Entity busy.

  busy_out          <= start_init or process_busy ;


  --------------------------------------------------------------------------
  --  Send the initialization messages.
  --------------------------------------------------------------------------

  init_messages:  process (reset, clk)
  begin
    if (reset = '1') then
      init_started          <= '0' ;
      init_done             <= (others => '0') ;
      init_bit_last         <= (others => '0') ;
      memreq_out            <= '0' ;
      memread_en_out        <= '0' ;
      memwrite_en_out       <= '0' ;
      mem_address           <= (others => '0') ;
      outsend_out           <= '0' ;
      sendreq_out           <= '0' ;
      process_busy          <= '1' ;
      cur_state             <= INIT_STATE_WAIT ;

    elsif (rising_edge (clk)) then

      --  Initialization states.

      case (cur_state) is

        --  Wait until initialization requested.

        when INIT_STATE_WAIT        =>
          if (start_init = '1') then
            process_busy      <= '1' ;
            init_started      <= '1' ;
            init_done         <= init_done and not init_bit ;
            init_bit_last     <= init_bit ;
            mem_inaddress     <=
              CONST_UNSIGNED (msg_rom_base_c) +
              TO_UNSIGNED (msg_init_table_c (TO_INTEGER (init_select_in)),
                           mem_inaddress'length) ;
            sendreq_out       <= '1' ;
            cur_state         <= INIT_STATE_START ;
          else
            init_started      <= '0' ;
            process_busy      <= '0' ;
            cur_state         <= INIT_STATE_WAIT ;
          end if ;

        --  Wait for the GPS to start up.

        when INIT_STATE_START       =>
          delay               <= unsigned (milli_count) - 1 ;
          cur_state           <= INIT_STATE_START_DELAY ;

        when INIT_STATE_START_DELAY =>
          if (unsigned (milli_count) = delay) then
            cur_state         <= INIT_STATE_GET_SENDER ;
          else
            cur_state         <= INIT_STATE_START_DELAY ;
          end if ;

        --  Wait until the message sender is available and ready.

        when INIT_STATE_GET_SENDER  =>
          if (sendrcv_in = '1') then
            cur_state         <= INIT_STATE_WAIT_SENDER ;
          else
            cur_state         <= INIT_STATE_GET_SENDER ;
          end if ;

        when INIT_STATE_WAIT_SENDER =>
          if (sendready_in = '1') then
            memreq_out        <= '1' ;
            cur_state         <= INIT_STATE_GET_MEM ;
          else
            cur_state         <= INIT_STATE_WAIT_SENDER ;
          end if ;

        --  Wait until access to memory is available.

        when INIT_STATE_GET_MEM     =>
          if (memrcv_in = '1') then
            mem_address       <= mem_inaddress ;
            memread_en_out    <= '1' ;
            cur_state         <= INIT_STATE_GET_CLASS ;
          else
            cur_state         <= INIT_STATE_GET_MEM ;
          end if ;

        --  Read the message Class, ID, and Payload Length from ROM.

        when INIT_STATE_GET_CLASS   =>
          msgclass_out        <= meminput_in ;
          mem_address         <= mem_address + 1 ;
          cur_state           <= INIT_STATE_GET_ID ;

        when INIT_STATE_GET_ID      =>
          msgid_out           <= meminput_in ;
          mem_address         <= mem_address + 1 ;
          cur_state           <= INIT_STATE_LOW_LENGTH ;

        when INIT_STATE_LOW_LENGTH  =>
          payload_length (7 downto 0)   <= unsigned (meminput_in) ;
          mem_address         <= mem_address + 1 ;
          cur_state           <= INIT_STATE_HIGH_LENGTH ;

        when INIT_STATE_HIGH_LENGTH =>
          payload_length (15 downto 8)  <= unsigned (meminput_in) ;
          mem_inaddress       <= mem_address + 1 ;
          mem_outaddress      <=
                RESIZE (CONST_UNSIGNED (msg_ram_base_c +
                                        msg_ram_msgbuff_addr_c),
                        mem_outaddress'length) ;
          cur_state           <= INIT_STATE_GET_PAYLOAD ;

        --  Read the payload from ROM.

        when INIT_STATE_GET_PAYLOAD =>
          msglength_out       <= payload_length ;
          msgaddress_out      <= std_logic_vector (mem_outaddress) ;
          mem_address         <= mem_inaddress ;
          cur_state           <= INIT_STATE_GET_CTL ;

        when INIT_STATE_GET_CTL     =>
          mem_inaddress       <= mem_inaddress + 1 ;

          if (payload_length /= 0) then
            bytecount         <= unsigned (meminput_in (6 downto 0)) ;
            payload_length    <= payload_length -
                                 unsigned (meminput_in (6 downto 0)) ;

            if (meminput_in (7) = '1') then
              mem_address     <= mem_inaddress + 1 ;
              mem_inaddress   <= mem_inaddress + 2 ;
              cur_state       <= INIT_STATE_GET_CHAR ;
            else
              memread_en_out  <= '0' ;
              memwrite_en_out <= '1' ;
              mem_address     <= mem_outaddress ;
              mem_outaddress  <= mem_outaddress +
                                 unsigned (meminput_in (6 downto 0)) ;
              memoutput_out   <= (others => '0') ;
              cur_state       <= INIT_STATE_PUT_ZERO ;
            end if ;
          else
            memread_en_out    <= '0' ;
            memreq_out        <= '0' ;
            outsend_out       <= '1' ;
            last_message      <= not meminput_in (7) ;
            cur_state         <= INIT_STATE_MSG_SEND ;
          end if ;

        --  Add a number of zeros to the message.

        when INIT_STATE_PUT_ZERO    =>
          if (bytecount /= 1) then
            bytecount         <= bytecount - 1 ;
            mem_address       <= mem_address + 1 ;
            cur_state         <= INIT_STATE_PUT_ZERO ;
          else
            memread_en_out    <= '1' ;
            memwrite_en_out   <= '0' ;
            mem_address       <= mem_inaddress ;
            cur_state         <= INIT_STATE_GET_CTL ;
          end if ;

        --  Add a number of characters from the ROM to the message.

        when INIT_STATE_GET_CHAR    =>
          if (bytecount /= 0) then
            bytecount         <= bytecount - 1 ;
            memoutput_out     <= meminput_in ;
            memread_en_out    <= '0' ;
            memwrite_en_out   <= '1' ;
            mem_address       <= mem_outaddress ;
            mem_outaddress    <= mem_outaddress + 1 ;
            cur_state         <= INIT_STATE_PUT_CHAR ;
          else
            mem_inaddress     <= mem_address ;
            cur_state         <= INIT_STATE_GET_CTL ;
          end if ;

        when INIT_STATE_PUT_CHAR    =>
          memread_en_out      <= '1' ;
          memwrite_en_out     <= '0' ;
          mem_address         <= mem_inaddress ;
          mem_inaddress       <= mem_inaddress + 1 ;
          cur_state           <= INIT_STATE_GET_CHAR ;

        --  Transmit the message to the GPS and wait for a short while to
        --  allow the GPS to process it.

        when INIT_STATE_MSG_SEND    =>
          if (sendready_in = '0') then
            outsend_out       <= '0' ;
            cur_state         <= INIT_STATE_MSG_DONE ;
          else
            cur_state         <= INIT_STATE_MSG_SEND ;
          end if ;

        when INIT_STATE_MSG_DONE    =>
          if (sendready_in = '1') then
            if (last_message = '1') then
              timepulse_last  <= gps_timepulse_in ;
              sendreq_out     <= '0' ;
              init_done       <= init_done or init_bit_last ;
              cur_state       <= INIT_STATE_WAIT ;
            else
              delay           <= unsigned (milli_count) - 1 ;
              cur_state       <= INIT_STATE_DELAY ;
            end if ;
          else
            cur_state         <= INIT_STATE_MSG_DONE ;
          end if ;

        when INIT_STATE_DELAY       =>
          if (unsigned (milli_count) = delay) then
            memreq_out        <= '1' ;
            cur_state         <= INIT_STATE_GET_MEM ;
          else
            cur_state         <= INIT_STATE_DELAY ;
          end if ;

      end case ;
    end if ;
  end process init_messages ;

end architecture rtl ;
