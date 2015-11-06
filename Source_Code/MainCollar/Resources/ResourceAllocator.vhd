----------------------------------------------------------------------------
--
--! @file       ResourceAllocator.vhd
--! @brief      Implements a resource allocator.
--! @details    Grants a resource to a single requester from a set of
--!             requesters.
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Resource Allocator
--! @details    Grant resource usage to a single requester from a set of
--!             requesters.
--!
--! @param      requester_cnt_g Number of requesters of the resource.
--! @param      number_len_g    Length of the receiver number returned.
--! @param      prioritized_g   The resource is allocated to the highest
--!                             priority requester (the lowest bit set) when
--!                             this parameter is set.  Otherwise,
--!                             round-robin allocation is used.
--! @param      cross_clock_domain_g  Set if the requesters come from
--!                                   different clock domains than the main
--!                                   clock (clk).
--! @param      reset           Reset the entity to an initial state.
--! @param      clk             Clock used to move through states in the
--!                             entity and its components.
--! @param      requesters_in   Bit vector of requesters for the resource.
--!                             The lowest bits have the highest priority.
--!                             When a requester is done with the resource
--!                             it releases it by setting its requester bit
--!                             to zero.
--! @param      receivers_out   Bit vector of requester that was granted the
--!                             resource.  Only one bit will be set at a
--!                             time.
--! @param      receiver_no_out Number of the receiver (starting at zero)
--!                             that has the resource.  It will default to
--!                             zero when no one has it.
--
----------------------------------------------------------------------------

entity ResourceAllocator is

  Generic (
    requester_cnt_g       : natural   :=  8 ;
    number_len_g          : natural   :=  3 ;
    prioritized_g         : std_logic := '1' ;
    cross_clock_domain_g  : std_logic := '0'
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    requesters_in         : in    std_logic_vector (requester_cnt_g-1
                                                      downto 0) ;
    receivers_out         : out   std_logic_vector (requester_cnt_g-1
                                                      downto 0) ;
    receiver_no_out       : out   unsigned (number_len_g-1 downto 0)
  ) ;

end entity ResourceAllocator ;


architecture rtl of ResourceAllocator is

  signal granted_to         : unsigned (requester_cnt_g-1 downto 0) ;
  signal low_priority_mask  : unsigned (requester_cnt_g-1 downto 0) ;

  signal requesters         : std_logic_vector (requester_cnt_g-1
                                                downto 0) ;
  signal requesters_s       : std_logic_vector (requester_cnt_g-1
                                                downto 0) ;

begin

  --------------------------------------------------------------------------
  --  Synchronize the requestors across clock domains if that is required.
  --------------------------------------------------------------------------

  no_sync :
    if (cross_clock_domain_g = '0') generate
      requesters          <= requesters_in ;
    end generate no_sync ;

  sync :
    if (cross_clock_domain_g = '1') generate
      sync_proc : process (reset, clk)
      begin
        if (reset = '1') then
          requesters      <= (others => '0') ;
          requesters_s    <= (others => '0') ;
        elsif (falling_edge (clk)) then
          requesters      <= requesters_s ;
        elsif (rising_edge (clk)) then
          requesters_s    <= requesters_in ;
        end if ;
      end process sync_proc ;
    end generate sync ;

  --------------------------------------------------------------------------
  --  Allocate the resource by setting the receiver's bit of the requester
  --  who was granted the resource.
  --------------------------------------------------------------------------

  allocate_resource : process (reset, clk)
    variable granted_low_v    : unsigned (requester_cnt_g-1 downto 0) ;
    variable granted_all_v    : unsigned (requester_cnt_g-1 downto 0) ;
    variable granted_bit_v    : unsigned (requester_cnt_g-1 downto 0) ;
  begin
    if (reset = '1') then
      granted_to          <= (others => '0') ;
      low_priority_mask   <= (others => '0') ;

    elsif (rising_edge (clk)) then

      --  When the requester that was granted the resource no longer wants
      --  it, allocate it to another requester.

      if ((granted_to and unsigned (requesters)) = 0) then

        --  When round-robin allocation is being done the lower priority
        --  requests are granted if there are any.  If there aren't, the
        --  higher priority requests are granted.  The lower priority
        --  requests are always those whose bits are above the bit of the
        --  last request granted.

        granted_low_v     := lsb_find (unsigned (requesters) and
                                       low_priority_mask) ;
        granted_all_v     := lsb_find (unsigned (requesters)) ;

        if (granted_low_v /= 0 and prioritized_g = '0') then
          granted_bit_v   := granted_low_v ;
        else
          granted_bit_v   := granted_all_v ;
        end if ;

        --  Set the receiver's bit and its bit number as well.

        receivers_out     <= std_logic_vector (granted_bit_v) ;
        receiver_no_out   <=
              bit_to_number (std_logic_vector (granted_bit_v),
                             receiver_no_out'length) ;

        --  Save the bit that was granted and create a mask of lower
        --  priority bits for the next allocation.

        granted_to        <= granted_bit_v ;
        low_priority_mask <= (not SHIFT_LEFT (granted_bit_v, 1)) + 1 ;

      end if ;
    end if ;
  end process allocate_resource ;

end architecture rtl ;
