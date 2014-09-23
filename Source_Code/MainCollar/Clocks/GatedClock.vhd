----------------------------------------------------------------------------
--
--! @file       GatedClock.vhd
--! @brief      Gate a clock turning it on and off as desired.
--! @details    Turn a clock on and off as desired.
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
--! @brief      Turn a clock on and off as desired.
--! @details    Gate a clock on and off in response to control inputs.
--!
--! @param      reset               Reset all the processing information.
--! @param      clk                 Clock used to drive clock generation.
--! @param      clk_on_in           Turn on the gated result clock.
--! @param      clk_off_in          Turn off the gated result clock.
--! @param      clk_out             The gated result clock.
--
----------------------------------------------------------------------------

entity GatedClock is

  Port (
    reset                   : in    std_logic ;
    clk                     : in    std_logic ;
    clk_on_in               : in    std_logic ;
    clk_off_in              : in    std_logic ;
    clk_out                 : out   std_logic
  ) ;

end entity GatedClock ;

architecture rtl of GatedClock is

  signal gated_clk_en       : std_logic ;


begin


  --------------------------------------------------------------------------
  --  Turn the clock on and off.
  --------------------------------------------------------------------------

  clk_gate : process (reset, clk)
  begin
    if (reset = '1') then
      gated_clk_en        <= '0' ;

    elsif (falling_edge (clk)) then
      if (clk_on_in = '1') then
        gated_clk_en      <= '1' ;

      elsif (clk_off_in = '1') then
        gated_clk_en      <= '0' ;
      end if ;
    end if ;
  end process clk_gate ;

  clk_out                 <= clk and gated_clk_en ;


end architecture rtl ;
