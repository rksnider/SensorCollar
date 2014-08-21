------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Get the AssistNow Autonomous status information.
--! @details    Process AssistNow Autonomous status messages and determine
--!             if AssistNow Autonomous is running.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY WORK ;                  --  Use local libraries.
USE WORK.UTILITIES.ALL ;        --  Use general purpose definitions.

USE WORK.GPS_MESSAGE_CTL.ALL ;        --  Use GPS Message information.
USE WORK.MSG_UBX_NAV_AOPSTATUS.ALL ;  --  Navagation Solution message.


------------------------------------------------------------------------------
--
--! @brief      Process AssistNow Autonomous status messages.
--! @details    When an AssistNow Autonomous status message arrives, determine
--!             if AssistNow Autonomous is currently running on the GPS.
--!
--! @param      MEMADDR_BITS          Number of bits on the address bus.
--! @param      QUIET_COUNT           Number of messages where AssistNow
--!                                   Autonomous not running to indicate that
--!                                   it is truely not running.
--! @param      clk                   Clock used to drive the processes.
--! @param      reset                 Reset the processes to initial state.
--! @param      msgnumber             Number of the message just received.
--! @param      msgreceived           A message has just been received.
--! @param      tempbank              Temporary data memory bank.  Used for
--!                                   all messages just received.
--! @param      memdata               Data byte of memory that is addressed.
--! @param      memrcv                Request for the memory bus is granted.
--! @param      memreq                Access to the memory bus requested.
--! @param      memaddr               Address of the byte of memory to read.
--! @param      memread_en            Enable the memory for reading.
--
------------------------------------------------------------------------------

entity AOPstatus is

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

end entity AOPstatus ;


architecture behavior of AOPstatus is

   --  AOP Status Processing States.

  type AOP_State is   (
    AOP_STATE_WAIT,
    AOP_STATE_RCVMEM,
    AOP_STATE_ENABLED,
    AOP_STATE_ACTIVE,
    AOP_STATE_COUNT
  ) ;

  signal cur_state        : AOP_State ;

  --  Follower of the message received signal used to detect when the latter
  --  changes.

  signal msgreceived_fwl    : std_logic ;

  --  Count of the number of messages where AssistNow Autonomous was not
  --  running.

  constant QUIET_COUNT_BITS : natural := const_bits (QUIET_COUNT) ;

  signal quiet_counter      : unsigned (QUIET_COUNT_BITS-1 downto 0) ;

  --  Output signals that must be read.

  signal mem_address        : unsigned (MEMADDR_BITS-1 downto 0) ;


begin

  --  Output signals that must be read.

  memaddr                   <= std_logic_vector (mem_address) ;

  --  Handle recevied AssistNow Autonomous status messages.

  marker_pending : process (reset, clk)
  begin
    if reset = '1' then
      memreq                <= '0' ;
      mem_address           <= (others => '0') ;
      memread_en            <= '0' ;
      msgreceived_fwl       <= '0' ;
      running               <= '0' ;
      quiet_counter         <= (others => '0') ;
      cur_state             <= AOP_STATE_WAIT ;

    elsif clk'event and clk = '1' then

      case cur_state is

        --  Wait until a new AOPstatus message has arrived.

        when AOP_STATE_WAIT           =>
          cur_state            <= AOP_STATE_WAIT ;
          memreq               <= '0' ;
          memread_en           <= '0' ;

          if msgreceived_fwl /= msgreceived then
            msgreceived_fwl  <= msgreceived ;

            if msgreceived = '1' then
              if unsigned (msgnumber) = MSG_UBX_NAV_AOPSTATUS_NUMBER then
                memreq       <= '1' ;
                cur_state    <= AOP_STATE_RCVMEM ;
              end if ;
            end if ;
          end if ;

        --  Wait until the memory request has been granted before continuing.

        when AOP_STATE_RCVMEM         =>
          if memrcv = '1' then
            mem_address     <= TO_UNSIGNED (MSG_RAM_BASE +
                                            MSG_RAM_TEMP_ADDR +
                                            if_set (tempbank,
                                                    MSG_RAM_TEMP_SIZE) +
                                            MUNAOPstatus_config_OFFSET,
                                            mem_address'length) ;
            memread_en      <= '1' ;
            cur_state       <= AOP_STATE_ENABLED ;
          else
            cur_state       <= AOP_STATE_RCVMEM ;
          end if ;

        --  Determine if AssistNow Autonomous is running.

        when AOP_STATE_ENABLED        =>
          if unsigned (memdata) = 0 then
            cur_state       <= AOP_STATE_COUNT ;
          else
            mem_address     <= TO_UNSIGNED (MSG_RAM_BASE +
                                            MSG_RAM_TEMP_ADDR +
                                            if_set (tempbank,
                                                    MSG_RAM_TEMP_SIZE) +
                                            MUNAOPstatus_status_OFFSET,
                                            mem_address'length) ;
            memread_en      <= '1' ;
            cur_state       <= AOP_STATE_ACTIVE ;
          end if ;

        when AOP_STATE_ACTIVE         =>
          if unsigned (memdata) = 0 then
            cur_state       <= AOP_STATE_COUNT ;
          else
            quiet_counter   <= (others => '0') ;
            running         <= '1' ;
            cur_state       <= AOP_STATE_WAIT ;
          end if ;

        --  Increment the quiet counter until its limit is reached.

        when AOP_STATE_COUNT          =>
          if quiet_counter = QUIET_COUNT then
            running         <= '0' ;
          else
            quiet_counter   <= quiet_counter + 1 ;
          end if ;

          cur_state         <= AOP_STATE_WAIT ;

      end case ;
    end if ;
  end process ;


end behavior ;
