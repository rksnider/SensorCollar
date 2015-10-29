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
--! @param      clock_bitcnt_g  Number of clock bits at the end of the
--!                             input and output vectors.
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
    resource_bits_g       : natural   :=  8 ;
    clock_bitcnt_g        : natural   :=  0
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

  --  2D Multiplexing function.

  function MUX_2D (signal input_tbl     : std_logic_2d ;
                   signal select_index  : unsigned)
  return std_logic_vector is
    constant mux_count_c    : natural := input_tbl'length(1) ;
    constant out_len_c      : natural := input_tbl'length(2) ;
    variable result_v       : std_logic_vector (out_len_c-1 downto 0) ;
  begin
    for bitno in out_len_c-1 downto 0 loop
      result_v (bitno) := input_tbl (0, bitno) ;
    end loop ;

    for i in mux_count_c-1 downto 1 loop
      if (select_index = i) then
        for bitno in out_len_c-1 downto 0 loop
          result_v (bitno) := input_tbl (i, bitno) ;
        end loop ;
      end if ;
    end loop ;

    return result_v ;
  end function MUX_2D ;

  --  Clock extraction function.

  function clock_extract (signal   input_tbl    : std_logic_2d ;
                          constant clock_count  : natural)
  return std_logic_2d is
    constant clock_bits_c   : natural := maximum (1, clock_count) ;
    constant row_cnt_c      : natural := input_tbl'length(1) ;
    constant col_cnt_c      : natural := input_tbl'length(2) ;
    variable result_v       : std_logic_2d (clock_bits_c-1 downto 0,
                                            row_cnt_c-1 downto 0) ;
  begin
    for row in row_cnt_c-1 downto 0 loop
      for clock in clock_bits_c-1 downto 0 loop
        result_v (clock, row)     := input_tbl (row, col_cnt_c -
                                                     clock_bits_c + clock) ;
      end loop ;
    end loop ;

    return result_v ;
  end function clock_extract ;

  --  Clock reintegration function.

  function clock_insert (signal   input_tbl     : std_logic_2d ;
                         signal   clock_bits    : std_logic_2d ;
                         constant clock_count   : natural)
  return std_logic_2d is
    constant row_cnt_c      : natural := input_tbl'length(1) ;
    constant col_cnt_c      : natural := input_tbl'length(2) ;
    variable result_v       : std_logic_2d (row_cnt_c-1  downto 0,
                                            col_cnt_c-1 downto 0) ;
  begin
    for row in row_cnt_c-1 downto 0 loop
      for col in col_cnt_c-1 downto 0 loop
        if (col >= col_cnt_c - clock_count) then
          result_v (row, col) := clock_bits (col + clock_count -
                                             col_cnt_c, row) ;
        else
          result_v (row, col) := input_tbl (row, col) ;
        end if ;
      end loop ;
    end loop ;

    return result_v ;
  end function clock_insert ;

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
  constant clock_bits_c     : natural := maximum (1, clock_bitcnt_g) ;

  signal selector           : unsigned (selector_bits_c-1 downto 0) ;

  signal input              : std_logic_2D (requester_cnt_g-1 downto 0,
                                            resource_bits_g-1 downto 0) ;
  signal clocks             : std_logic_2D (clock_bits_c-1    downto 0,
                                            requester_cnt_g-1 downto 0) ;

  attribute keep            : boolean ;

  attribute keep of clocks  : signal is true ;

begin

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

  --  Extract the clock bits and reintegrate them in the results.
  --  Separation allows clocks to be assigned to them.

  clocks    <= clock_extract (resource_tbl_in, clock_bitcnt_g) ;

  input     <= clock_insert  (resource_tbl_in, clocks, clock_bitcnt_g)
                    when (clock_bitcnt_g > 0) else
               resource_tbl_in ;

  --  Multiplexer for the resource bits.

  resources_out <= MUX_2D (input, selector) ;


end rtl ;
