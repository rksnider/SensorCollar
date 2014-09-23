----------------------------------------------------------------------------
--
--! @file       GenClock.vhd
--! @brief      Generate a clock and a gated version at a given frequency.
--! @details    Generates a clock by counting the cycles of a faster clock
--!             up to a half period.
--! @author     Emery Newlon
--! @date       September 2014
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
use GENERAL.UTILITIES_PKG.ALL ; --  Generally useful functions.


----------------------------------------------------------------------------
--
--! @brief      Generate a clock using a faster clock.
--! @details    Generate a clock and a gated version by counting the cycles
--!             of a faster clock until a half cycle of the new clock is
--!             reached.  The new clock output is toggled then.
--!
--! @param      clk_freq_g          Frequency of the source clock in
--!                                 cycles per second.
--! @param      out_clk_freq_g      Frequency the result clock in cycles per
--!                                 second.
--! @param      reset               Reset all the processing information.
--! @param      clk                 Clock used to drive clock generation.
--! @param      clk_on_in           Turn on the gated result clock.
--! @param      clk_off_in          Turn off the gated result clock.
--! @param      clk_out             The result clock.
--! @param      gated_clk_out       The gated result clock.
--
----------------------------------------------------------------------------

entity GenClock is

  Generic (
    clk_freq_g              : natural   := 10e6 ;
    out_clk_freq_g          : natural   := 1e6
  ) ;
  Port (
    reset                   : in    std_logic ;
    clk                     : in    std_logic ;
    clk_on_in               : in    std_logic ;
    clk_off_in              : in    std_logic ;
    clk_out                 : out   std_logic ;
    gated_clk_out           : out   std_logic
  ) ;

end entity GenClock ;

architecture rtl of GenClock is

  --  Clock information.

  constant clk_cntmax_c     : natural := clk_freq_g / (out_clk_freq_g * 2) ;
  constant clk_cntbits_c    : natural := const_bits (clk_cntmax_c) ;

  signal clk_cnt            : unsigned (clk_cntbits_c-1 downto 0) ;

  signal out_clk            : std_logic ;
  signal gated_clk_en       : std_logic ;


begin


  --------------------------------------------------------------------------
  --  Clock generation.
  --------------------------------------------------------------------------

  clk_gen : process (reset, clk)
  begin
    if (reset = '1') then
      clk_cnt             <= (others => '0') ;
      out_clk             <= '0' ;
      gated_clk_en        <= '0' ;

    --  Count out a half cycle of the output clock in driver clock cycles.

    elsif (rising_edge (clk)) then
      if (clk_cnt /= TO_UNSIGNED (clk_cntmax_c,
                                  clk_cnt'length)) then

        clk_cnt           <= clk_cnt + 1 ;
      else

        --  Enable or disable the gated clock only on a falling edge of the
        --  output clock.

        if (out_clk = '1') then

          if (clk_on_in = '1') then
            gated_clk_en  <= '1' ;
          elsif (clk_off_in = '1') then
            gated_clk_en  <= '0' ;
          end if ;
        end if ;

        --  Generate a new output clock edge and start counting a half
        --  cycle again.

        clk_cnt           <= (others => '0') ;
        out_clk           <= not out_clk ;
      end if ;
    end if ;

  end process clk_gen ;

  clk_out                 <= out_clk ;
  gated_clk_out           <= out_clk and gated_clk_en ;


end architecture rtl ;
