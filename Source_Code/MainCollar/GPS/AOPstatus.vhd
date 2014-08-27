----------------------------------------------------------------------------
--
--! @file       AOPstatus.vhd
--! @brief      Get the AssistNow Autonomous status information.
--! @details    Process AssistNow Autonomous status messages and determine
--!             if AssistNow Autonomous is running.
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

LIBRARY GENERAL ;               --  General libraries.
USE GENERAL.UTILITIES_PKG.ALL ; --  Use general purpose definitions.

LIBRARY WORK ;                            --  Local packages.
USE WORK.GPS_MESSAGE_CTL_PKG.ALL ;        --  Use GPS Message information.
USE WORK.MSG_UBX_NAV_AOPSTATUS_PKG.ALL ;  --  Navagation Solution message.


----------------------------------------------------------------------------
--
--! @brief      Process AssistNow Autonomous status messages.
--! @details    When an AssistNow Autonomous status message arrives,
--!             determine if AssistNow Autonomous is currently running on
--!             the GPS.
--!
--! @param      memaddr_bits_g        Number of bits on the address bus.
--! @param      quiet_count_g         Number of messages where AssistNow
--!                                   Autonomous not running to indicate
--!                                   that it is truely not running.
--! @param      clk                   Clock used to drive the processes.
--! @param      reset                 Reset the processes to initial state.
--! @param      msgnumber_in          Number of the message just received.
--! @param      msgreceived_in        A message has just been received.
--! @param      tempbank_in           Temporary data memory bank.  Used for
--!                                   all messages just received.
--! @param      memreq_out            Access to the memory bus requested.
--! @param      memrcv_in             Request for the memory bus is granted.
--! @param      memaddr_out           Address of the byte of memory to read.
--! @param      memdata_in            Data byte of memory that is addressed.
--! @param      memread_en_out        Enable the memory for reading.
--! @param      running_out           Set when AssistNow is running.
--
----------------------------------------------------------------------------

entity AOPstatus is

  Generic (
    memaddr_bits_g        : natural := 8 ;
    quiet_count_g         : natural := 8
  ) ;
  Port (
    clk                   : in    std_logic ;
    reset                 : in    std_logic ;
    msgnumber_in          : in    std_logic_vector (MSG_COUNT_BITS-1
                                                      downto 0) ;
    msgreceived_in        : in    std_logic ;
    tempbank_in           : in    std_logic ;
    memreq_out            : out   std_logic ;
    memrcv_in             : in    std_logic ;
    memaddr_out           : out   std_logic_vector (memaddr_bits_g-1
                                                      downto 0) ;
    memdata_in            : in    std_logic_vector (7 downto 0) ;
    memread_en_out        : out   std_logic ;
    running_out           : out   std_logic
  ) ;

end entity AOPstatus ;


architecture rtl of AOPstatus is

   --  AOP Status Processing States.

  type AOP_State is   (
    AOP_STATE_WAIT,
    AOP_STATE_RCVMEM,
    AOP_STATE_ENABLED,
    AOP_STATE_ACTIVE,
    AOP_STATE_COUNT
  ) ;

  signal cur_state            : AOP_State ;

  --  Follower of the message received signal used to detect when the latter
  --  changes.

  signal msgreceived_fwl      : std_logic ;

  --  Count of the number of messages where AssistNow Autonomous was not
  --  running.

  constant quiet_count_bits_c : natural := const_bits (quiet_count_g) ;

  signal quiet_counter        : unsigned (quiet_count_bits_c-1 downto 0) ;

  --  Output signals that must be read.

  signal mem_address          : unsigned (memaddr_bits_g-1 downto 0) ;


begin

  --  Output signals that must be read.

  memaddr_out               <= std_logic_vector (mem_address) ;

  --  Handle recevied AssistNow Autonomous status messages.

  marker_pending : process (reset, clk)
  begin
    if (reset = '1') then
      memreq_out            <= '0' ;
      mem_address           <= (others => '0') ;
      memread_en_out        <= '0' ;
      msgreceived_fwl       <= '0' ;
      running_out           <= '0' ;
      quiet_counter         <= (others => '0') ;
      cur_state             <= AOP_STATE_WAIT ;

    elsif (rising_edge (clk)) then

      case cur_state is

        --  Wait until a new AOPstatus message has arrived.

        when AOP_STATE_WAIT           =>
          cur_state          <= AOP_STATE_WAIT ;
          memreq_out         <= '0' ;
          memread_en_out     <= '0' ;

          if (msgreceived_fwl /= msgreceived_in) then
            msgreceived_fwl  <= msgreceived_in ;

            if (msgreceived_in = '1') then
              if (unsigned (msgnumber_in) =
                  msg_ubx_nav_aopstatus_number_c) then

                memreq_out   <= '1' ;
                cur_state    <= AOP_STATE_RCVMEM ;
              end if ;
            end if ;
          end if ;

        --  Wait until the memory request has been granted before
        --  continuing.

        when AOP_STATE_RCVMEM         =>
          if (memrcv_in = '1') then
            mem_address     <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ram_temp_addr_c +
                                            if_set (tempbank_in,
                                                    msg_ram_temp_size_c) +
                                            MUNAOPstatus_config_offset_c,
                                            mem_address'length) ;
            memread_en_out  <= '1' ;
            cur_state       <= AOP_STATE_ENABLED ;
          else
            cur_state       <= AOP_STATE_RCVMEM ;
          end if ;

        --  Determine if AssistNow Autonomous is running.

        when AOP_STATE_ENABLED        =>
          if (unsigned (memdata_in) = 0) then
            cur_state       <= AOP_STATE_COUNT ;
          else
            mem_address     <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ram_temp_addr_c +
                                            if_set (tempbank_in,
                                                    msg_ram_temp_size_c) +
                                            MUNAOPstatus_status_offset_c,
                                            mem_address'length) ;
            memread_en_out  <= '1' ;
            cur_state       <= AOP_STATE_ACTIVE ;
          end if ;

        when AOP_STATE_ACTIVE         =>
          if (unsigned (memdata_in) = 0) then
            cur_state       <= AOP_STATE_COUNT ;
          else
            quiet_counter   <= (others => '0') ;
            running_out     <= '1' ;
            cur_state       <= AOP_STATE_WAIT ;
          end if ;

        --  Increment the quiet counter until its limit is reached.

        when AOP_STATE_COUNT          =>
          if (quiet_counter = quiet_count_g) then
            running_out         <= '0' ;
          else
            quiet_counter   <= quiet_counter + 1 ;
          end if ;

          cur_state         <= AOP_STATE_WAIT ;

      end case ;
    end if ;
  end process marker_pending ;


end architecture rtl ;
