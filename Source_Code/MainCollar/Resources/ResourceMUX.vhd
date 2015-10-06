----------------------------------------------------------------------------
--
--! @file       ResourceMUX.vhd
--! @brief      Implements a resource multiplexer.
--! @details    Grants the resource and its I/O signals to a requester.
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
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;

library GENERAL ;               --! Local libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Resource allocator/multiplexer.
--! @details    Grants the resource and its I/O signals to a requester.
--!
--! @param      requester_cnt_g Number of requesters of the resource.
--! @param      resource_bits_g Number of bits the resource multiplexes.
--! @param      reset           Reset the entity to an initial state.
--! @param      clk             Clock used to move throuth states in the
--!                             entity and its components.
--! @param      requesters_in   Bit vector of requesters for the resource.
--!                             The lowest bits have the highest priority.
--! @param      resource_tbl_in Array of resource I/O signals of the
--!                             requesters.
--! @param      receivers_out   Bit vector of requester that was granted the
--!                             resource.  Only one bit will be set at a
--!                             time.
--! @param      resources_out   The I/O signal bits of the selected
--!                             requester.
--
----------------------------------------------------------------------------

entity ResourceMUX is

  Generic (
    requester_cnt_g       : natural   :=  8 ;
    resource_bits_g       : natural   :=  8
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    requesters_in         : in    std_logic_vector (requester_cnt_g-1
                                                        downto 0) ;
    resource_tbl_in       : in    std_logic_2D (requester_cnt_g-1
                                                        downto 0,
                                                resource_bits_g-1
                                                        downto 0) ;
    receivers_out         : out   std_logic_vector (requester_cnt_g-1
                                                        downto 0) ;
    resources_out         : out   std_logic_vector (resource_bits_g-1
                                                        downto 0)
  ) ;

end entity ResourceMUX ;


architecture rtl of ResourceMUX is

  --  Library of Parameterized Modules - Multiplexer Module.

  component LPM_MUX is
    Generic (
      LPM_WIDTH           : natural ;
      LPM_SIZE            : natural ;
      LPM_WIDTHS          : natural ;
      LPM_TYPE            : string
    ) ;
    Port (
      data                : in  std_logic_2d (LPM_SIZE-1 downto 0,
                                              LPM_WIDTH-1 downto 0) ;
      sel                 : in  std_logic_vector (LPM_WIDTHS-1 downto 0) ;
      result              : out std_logic_vector (LPM_WIDTH-1 downto 0)
    ) ;
  end component ;

  --  Resource allocator determines who will get the memory bus.

  component ResourceAllocator is

    Generic (
      requester_cnt_g       : natural   :=  8 ;
      number_len_g          : natural   :=  3 ;
      prioritized_g         : std_logic := '1'
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
  end component ;

  --  Internal signals.

  constant selector_bits_c  : natural := const_bits (requester_cnt_g - 1) ;

  signal selector           : unsigned (selector_bits_c-1 downto 0) ;

begin

  --  Multiplexer for the resource bits.

  resource_mux : LPM_MUX
    Generic Map (
      LPM_WIDTH           => resource_bits_g,
      LPM_SIZE            => requester_cnt_g,
      LPM_WIDTHS          => selector_bits_c,
      LPM_TYPE            => "LPM_MUX"
    )
    Port Map (
      data                => resource_tbl_in,
      sel                 => std_logic_vector (selector),
      result              => resources_out
    ) ;

  --  Allocate the bus signals to a requester.

  allocate : ResourceAllocator
    Generic Map (
      requester_cnt_g     => requester_cnt_g,
      number_len_g        => selector_bits_c,
      prioritized_g       => '0'
    )
    Port Map (
      reset               => reset,
      clk                 => clk,
      requesters_in       => requesters_in,
      receivers_out       => receivers_out,
      receiver_no_out     => selector
    ) ;


end rtl ;
