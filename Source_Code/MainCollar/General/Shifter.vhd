----------------------------------------------------------------------------
--
--! @file       Shifter.vhd
--! @brief      Implements a Shifter.
--! @details    This shifter latches the shifted input buffer with input
--!             bits concatinated on the rising edge of the clock.  This
--!             value is output on the falling edge of the clock if shifting
--!             is enabled.
--! @author     Emery Newlon
--! @date       November 2016
--! @copyright  Copyright (C) 2016 Ross K. Snider and Emery L. Newlon
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

library GENERAL ;               --! Local libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Shifter
--! @details    This shifter latches the shifted buffer with input
--!             bits concatinated on the rising edge of the clock.  This
--!             value is output on the falling edge of the clock if shifting
--!             is enabled.  This allows shifting to be carried out when
--!             enabled on the rising clock edge.  The shifting buffer can
--!             be loaded initially as well.
--!
--! @param      bits_wide_g         Size of the buffer in bits.
--! @param      shift_bits_g        Number of bits to shift the buffer by.
--! @param      shift_right_g       Shift the buffer right when one, left
--!                                 when zero.
--! @param      clk                 Clock to latch the input buffer with.
--! @param      load_buffer_in      Buffer to load into the output on signal.
--! @param      load_in             Load the load buffer into the output.
--! @param      shift_enable_in     Enable shifting on the clock edges.
--! @param      buffer_out          The result of the shift.
--! @param      early_lastbits_out  Last bits in the buffer that will be
--!                                 shifted out on the next shift available
--!                                 on the falling clock edge.
--! @param      lastbits_out        Last bits in the buffer that will be
--!                                 shifted out on the next shift available
--!                                 on the rising clock edge.
--! @param      shift_inbits_in     The bits to shift into the output buffer.
--
----------------------------------------------------------------------------

entity Shifter is

  Generic (
    bits_wide_g           : natural   := 32 ;
    shift_bits_g          : natural   :=  8 ;
    shift_right_g         : std_logic := '1'
  ) ;
  Port (
    clk                   : in    std_logic ;
    load_buffer_in        : in    std_logic_vector (bits_wide_g-1
                                                    downto 0) ;
    load_in               : in    std_logic ;
    shift_enable_in       : in    std_logic ;
    buffer_out            : out   std_logic_vector (bits_wide_g-1
                                                    downto 0) ;
    early_lastbits_out    : out   std_logic_vector (shift_bits_g-1
                                                    downto 0) ;
    lastbits_out          : out   std_logic_vector (shift_bits_g-1
                                                    downto 0) ;
    shift_inbits_in       : in    std_logic_vector (shift_bits_g-1
                                                    downto 0)
  ) ;

end entity Shifter ;


architecture rtl of Shifter is

  signal shift_outbuff    : std_logic_vector (bits_wide_g-1 downto 0) :=
                                                    (others => '0') ;
  signal shift_inbuff     : std_logic_vector (bits_wide_g-shift_bits_g-1
                                              downto 0) :=
                                                    (others => '0') ;
  signal shift_lastbits   : std_logic_vector (shift_bits_g-1 downto 0) :=
                                                    (others => '0') ;
  signal early_lastbits   : std_logic_vector (shift_bits_g-1 downto 0) :=
                                                    (others => '0') ;

begin

  buffer_out              <= shift_outbuff ;
  early_lastbits_out      <= early_lastbits ;
  lastbits_out            <= shift_lastbits ;

  --------------------------------------------------------------------------
  --  Latch the shifted buffer on the falling edge and combine the result
  --  with the input bits.
  --------------------------------------------------------------------------

  right_shift : if (shift_right_g = '1') generate

    latch_proc : process (clk)
    begin
      if (rising_edge (clk)) then
        shift_inbuff      <= shift_outbuff (bits_wide_g-1 downto
                                            shift_bits_g) ;
        early_lastbits    <= shift_outbuff (shift_bits_g*2-1 downto
                                            shift_bits_g) ;
      elsif (falling_edge (clk)) then
        if (load_in = '1') then
          shift_outbuff   <= load_buffer_in ;
          shift_lastbits  <= load_buffer_in (shift_bits_g-1 downto 0) ;
        elsif (shift_enable_in = '1') then
          shift_outbuff   <= shift_inbits_in & shift_inbuff ;
          shift_lastbits  <= shift_inbuff (shift_bits_g-1 downto 0) ;
        end if ;
      end if ;
    end process latch_proc ;

  end generate right_shift ;

  left_shift : if (shift_right_g = '0') generate

    latch_proc : process (clk)
    begin
      if (rising_edge (clk)) then
        shift_inbuff      <= shift_outbuff (bits_wide_g-shift_bits_g-1
                                            downto 0) ;
        early_lastbits    <= shift_outbuff (bits_wide_g-shift_bits_g-1
                                            downto
                                            bits_wide_g-shift_bits_g*2) ;
      elsif (falling_edge (clk)) then
        if (load_in = '1') then
          shift_outbuff   <= load_buffer_in ;
          shift_lastbits  <= load_buffer_in (bits_wide_g-1 downto
                                             bits_wide_g-shift_bits_g) ;
        elsif (shift_enable_in = '1') then
          shift_outbuff   <= shift_inbuff & shift_inbits_in ;
          shift_lastbits  <= shift_inbuff (shift_inbuff'length-1 downto
                                           shift_inbuff'length-shift_bits_g) ;
        end if ;
      end if ;
    end process latch_proc ;

  end generate left_shift ;

end rtl ;
