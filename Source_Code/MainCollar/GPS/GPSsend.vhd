----------------------------------------------------------------------------
--
--! @file       GPSsend.vhd
--! @brief      Send a UBX message to a NEO-6T GPS.
--! @details    A message is sent to the GPS including an optional payload
--!             in memory.
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

library WORK ;
use WORK.gps_message_ctl_pkg.all ;  --  GPS message control definitions.


----------------------------------------------------------------------------
--
--! @brief      GPS Message Sender.
--! @details    Send a message to the GPS.
--!
--! @param      memaddr_bits_c  Bit width of the memory address.
--! @param      reset           Reset the entity to an initial state.
--! @param      clk             Clock used to move throuth states in the
--!                             entity and its components.
--! @param      outready_in     The communication port is ready for a
--!                             character.
--! @param      msgclass_in     Class of the message to send.
--! @param      msgid_in        ID of the message to sent.
--! @param      memstart_in     Starting address to read payload from.
--! @param      memlength_in    Length of the payload.
--! @param      meminput_in     Data byte read from memory that is
--!                             addressed.
--! @param      memrcv_in       Receive access to memory.
--! @param      memreq_out      Request access to memory.
--! @param      memaddr_out     Address of the byte of memory to read.
--! @param      memread_en_out  Enable the memory for reading.
--! @param      outchar_out     Character to send to the GPS.
--! @param      outsend_out     Send the charater.
--! @param      outdone_out     The message has been completely sent.
--
----------------------------------------------------------------------------

entity GPSsend is

  Generic (
    memaddr_bits_c  : natural := 8
  ) ;
  Port (
    reset           : in    std_logic ;
    clk             : in    std_logic ;
    outready_in     : in    std_logic ;
    msgclass_in     : in    std_logic_vector (7 downto 0) ;
    msgid_in        : in    std_logic_vector (7 downto 0) ;
    memstart_in     : in    std_logic_vector (memaddr_bits_c-1 downto 0) ;
    memlength_in    : in    unsigned (15 downto 0) ;
    meminput_in     : in    std_logic_vector (7 downto 0) ;
    memrcv_in       : in    std_logic ;
    memreq_out      : out   std_logic ;
    memaddr_out     : out   std_logic_vector (memaddr_bits_c-1 downto 0) ;
    memread_en_out  : out   std_logic ;
    outchar_out     : out   std_logic_vector (7 downto 0) ;
    outsend_out     : out   std_logic ;
    outdone_out     : out   std_logic
  ) ;

end entity GPSsend ;


architecture behavior of GPSsend is

  --  Send Message States.

  type SendState is   (
    SEND_STATE_WAIT_READY,
    SEND_STATE_GET_MEM,
    SEND_STATE_WAIT_MEM,
    SEND_STATE_START,
    SEND_STATE_SYNC,
    SEND_STATE_CLASS,
    SEND_STATE_ID,
    SEND_STATE_LEN_LOW,
    SEND_STATE_LEN_HIGH,
    SEND_STATE_PAYLOAD,
    SEND_STATE_CHECKSUM,
    SEND_STATE_CHECKSUM_B,
    SEND_STATE_DONE
  ) ;

  signal cur_state              : SendState ;
  signal next_state             : SendState ;

  --  Checksum processing.

  signal calc_checksum          : std_logic ;
  signal m_checksum_A           : unsigned (7 downto 0) ;
  signal m_checksum_B           : unsigned (7 downto 0) ;

  --  Message handling signals.

  signal msg_memaddr            : unsigned (memaddr_bits_c-1 downto 0) ;
  signal msg_length             : unsigned (15 downto 0) ;

  signal nextout                : std_logic_vector (7 downto 0) ;

  signal outready_fwl           : std_logic ;

begin

  --  Output signals that must be read.

  memaddr_out             <= std_logic_vector (msg_memaddr) ;


  --------------------------------------------------------------------------
  --  Send the message to the GPS one byte at a time.
  --------------------------------------------------------------------------

  send_message:  process (reset, clk)
  begin
    if (reset = '1') then
      outready_fwl    <= '0' ;
      memreq_out      <= '0' ;
      memread_en_out  <= '0' ;
      msg_memaddr     <= (others => '0') ;
      outchar_out     <= (others => '0') ;
      outsend_out     <= '0' ;
      outdone_out     <= '0' ;
      cur_state       <= SEND_STATE_GET_MEM ;
      next_state      <= SEND_STATE_START ;

    elsif (rising_edge (clk)) then

      --  Always wait for output ready unless changed within a state.
      --  In most cases the output must be sent before a state can proceed.
      --  Thus the state machine waits in the WAIT_READY state until a the
      --  transmitter is ready for output, sends the output byte, then
      --  proceeds to the next specified state.  In some states multiple
      --  clock cycles are needed to process the information received.  In
      --  those cases waiting for output to be ready is skipped.  The state
      --  machine proceeds at the clock rate instead.
      --  THIS CHANGE DOES NOT TAKE PLACE UNTIL THE END OF THE PROCESS!
      --  IT CAN BE OVERRIDDEN IF SET AGAIN BEFORE THE END OF THE PROCESS!

      cur_state               <= SEND_STATE_WAIT_READY ;

      --  Parsing state machine.

      case cur_state is

        --  Wait until output can be sent.  Add the new byte value to the
        --  checksum if currently calculating the checksum.  Then send the
        --  byte out.

        when SEND_STATE_WAIT_READY    =>
          memreq_out          <= '0' ;

          if (outready_fwl /= outready_in) then
            outready_fwl      <= outready_in ;

            if (outready_in = '1') then
              if (calc_checksum = '1') then
                m_checksum_B  <= m_checksum_B + m_checksum_A +
                                 unsigned (nextout) ;
                m_checksum_A  <= m_checksum_A + unsigned (nextout) ;
              end if ;

              outchar_out     <= nextout ;
              outsend_out     <= '1' ;

              cur_state       <= SEND_STATE_GET_MEM ;
            else
              outsend_out     <= '0' ;
            end if ;
          end if ;

        when SEND_STATE_GET_MEM       =>
          if (memrcv_in = '0') then
            memreq_out        <= '1' ;
            cur_state         <= SEND_STATE_WAIT_MEM ;
          else
            cur_state         <= SEND_STATE_GET_MEM ;
          end if ;

        when SEND_STATE_WAIT_MEM      =>
          if (memrcv_in = '1') then
            cur_state         <= next_state ;
          else
            cur_state         <= SEND_STATE_WAIT_MEM ;
          end if ;

        --  Send the message start and sync bytes.

        when SEND_STATE_START         =>
          nextout             <= msg_ubx_sync_1_c ;
          next_state          <= SEND_STATE_SYNC ;

        when SEND_STATE_SYNC          =>
          nextout             <= msg_ubx_sync_2_c ;
          calc_checksum       <= '1' ;
          next_state          <= SEND_STATE_CLASS ;

        --  Send the message class and ID.

        when SEND_STATE_CLASS         =>
          m_checksum_A        <= (others => '0') ;
          m_checksum_B        <= (others => '0') ;
          nextout             <= msgclass_in ;
          next_state          <= SEND_STATE_ID ;

        when SEND_STATE_ID            =>
          nextout             <= msgid_in ;
          next_state          <= SEND_STATE_LEN_LOW ;

        --  Send the message length.

        when SEND_STATE_LEN_LOW       =>
          nextout             <=
                std_logic_vector (memlength_in (7 downto 0)) ;
          next_state          <= SEND_STATE_LEN_HIGH ;

        when SEND_STATE_LEN_HIGH      =>
          nextout             <=
                std_logic_vector (memlength_in (15 downto 8)) ;
          msg_memaddr         <= unsigned (memstart_in) ;
          msg_length          <= memlength_in ;
          memread_en_out      <= '1' ;
          next_state          <= SEND_STATE_PAYLOAD ;

        --  Find the message parsing information in ROM.

        when SEND_STATE_PAYLOAD       =>
          if (msg_length = 0) then
            calc_checksum     <= '0' ;
            memread_en_out    <= '0' ;
            cur_state         <= SEND_STATE_CHECKSUM ;
          else
            nextout           <= meminput_in ;
            msg_memaddr       <= msg_memaddr + 1 ;
            msg_length        <= msg_length - 1 ;
            next_state        <= SEND_STATE_PAYLOAD ;
          end if ;

        --  The payload has been completely sent.  Now send the checksum.

        when SEND_STATE_CHECKSUM      =>
          nextout             <= std_logic_vector (m_checksum_A) ;
          next_state          <= SEND_STATE_CHECKSUM_B ;

        when SEND_STATE_CHECKSUM_B    =>
          nextout             <= std_logic_vector (m_checksum_B) ;
          next_state          <= SEND_STATE_DONE ;

        --  Message has been completely sent.

        when SEND_STATE_DONE          =>
          memreq_out          <= '0' ;
          outsend_out         <= '0' ;
          outdone_out         <= '1' ;
          cur_state           <= SEND_STATE_DONE ;

       end case ;
    end if ;
  end process send_message ;

end architecture rtl ;
