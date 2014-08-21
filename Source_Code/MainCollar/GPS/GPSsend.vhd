------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Send a UBX message to a NEO-6T GPS.
--! @details    A message is sent to the GPS including an optional payload
--!             in memory.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

use WORK.gps_message_ctl.all ;  --  GPS message control definitions.


------------------------------------------------------------------------------
--
--! @brief      GPS Message Sender.
--! @details    Send a message to the GPS.
--!
--! @param      MEMADDR_BITS  Bit width of the memory address.
--! @param      reset         Reset the entity to an initial state.
--! @param      clk           Clock used to move throuth states in the entity
--!                           and its components.
--! @param      outready      The communication port is ready for a character.
--! @param      msgclass      Class of the message to send.
--! @param      msgid         ID of the message to sent.
--! @param      memstart      Starting address to read payload from.
--! @param      memlength     Length of the payload.
--! @param      meminput      Data byte read from memory that is addressed.
--! @param      memrcv        Receive access to memory.
--! @param      memreq        Request access to memory.
--! @param      memaddr       Address of the byte of memory to read.
--! @param      memread_en    Enable the memory for reading.
--! @param      outchar       Character to send to the GPS.
--! @param      outsend       Send the charater.
--! @param      outdone       The message has been completely sent.
--
------------------------------------------------------------------------------

entity GPSsend is

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

  signal cur_state        : SendState ;
  signal next_state       : SendState ;

  --  Checksum processing.

  signal calc_checksum          : std_logic ;
  signal m_checksum_A           : unsigned (7 downto 0) ;
  signal m_checksum_B           : unsigned (7 downto 0) ;

  --  Message handling signals.

  signal msg_memaddr            : unsigned (MEMADDR_BITS-1 downto 0) ;
  signal msg_length             : unsigned (15 downto 0) ;

  signal nextout                : std_logic_vector (7 downto 0) ;

  signal outready_fwl           : std_logic ;

begin

  --  Output signals that must be read.

  memaddr             <= std_logic_vector (msg_memaddr) ;


  ------------------------------------------------------------------------------
  --
  --! @brief      Send the message to the GPS.
  --! @details    Send the message to the GPS one byte at a time.
  --!
  --! @param      reset         Reset the Parser.
  --! @param      clk           Multi-state per character clock.
  --
  ------------------------------------------------------------------------------

  send_message:  process (reset, clk)
  begin
    if reset = '1' then
      outready_fwl    <= '0' ;
      memreq          <= '0' ;
      memread_en      <= '0' ;
      msg_memaddr     <= (others => '0') ;
      outchar         <= (others => '0') ;
      outsend         <= '0' ;
      outdone         <= '0' ;
      cur_state       <= SEND_STATE_GET_MEM ;
      next_state      <= SEND_STATE_START ;

    elsif clk'event and clk = '1' then

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
          memreq              <= '0' ;

          if outready_fwl /= outready then
            outready_fwl      <= outready ;

            if outready = '1' then
              if calc_checksum = '1' then
                m_checksum_B  <= m_checksum_B + m_checksum_A +
                                 unsigned (nextout) ;
                m_checksum_A  <= m_checksum_A + unsigned (nextout) ;
              end if ;

              outchar         <= nextout ;
              outsend         <= '1' ;

              cur_state       <= SEND_STATE_GET_MEM ;
            else
              outsend         <= '0' ;
            end if ;
          end if ;

        when SEND_STATE_GET_MEM       =>
          if memrcv = '0' then
            memreq            <= '1' ;
            cur_state         <= SEND_STATE_WAIT_MEM ;
          else
            cur_state         <= SEND_STATE_GET_MEM ;
          end if ;

        when SEND_STATE_WAIT_MEM      =>
          if memrcv = '1' then
            cur_state         <= next_state ;
          else
            cur_state         <= SEND_STATE_WAIT_MEM ;
          end if ;

        --  Send the message start and sync bytes.

        when SEND_STATE_START         =>
          nextout             <= MSG_UBX_SYNC_1 ;
          next_state          <= SEND_STATE_SYNC ;

        when SEND_STATE_SYNC          =>
          nextout             <= MSG_UBX_SYNC_2 ;
          calc_checksum       <= '1' ;
          next_state          <= SEND_STATE_CLASS ;

        --  Send the message class and ID.

        when SEND_STATE_CLASS         =>
          m_checksum_A        <= (others => '0') ;
          m_checksum_B        <= (others => '0') ;
          nextout             <= msgclass ;
          next_state          <= SEND_STATE_ID ;

        when SEND_STATE_ID            =>
          nextout             <= msgid ;
          next_state          <= SEND_STATE_LEN_LOW ;

        --  Send the message length.

        when SEND_STATE_LEN_LOW       =>
          nextout             <= std_logic_vector (memlength (7 downto 0)) ;
          next_state          <= SEND_STATE_LEN_HIGH ;

        when SEND_STATE_LEN_HIGH      =>
          nextout             <= std_logic_vector (memlength (15 downto 8)) ;
          msg_memaddr         <= unsigned (memstart) ;
          msg_length          <= memlength ;
          memread_en          <= '1' ;
          next_state          <= SEND_STATE_PAYLOAD ;

        --  Find the message parsing information in ROM.

        when SEND_STATE_PAYLOAD       =>
          if msg_length = 0 then
            calc_checksum     <= '0' ;
            memread_en        <= '0' ;
            cur_state         <= SEND_STATE_CHECKSUM ;
          else
            nextout           <= meminput ;
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
          memreq              <= '0' ;
          outsend             <= '0' ;
          outdone             <= '1' ;
          cur_state           <= SEND_STATE_DONE ;

       end case ;
    end if ;
  end process send_message ;

end behavior ;
