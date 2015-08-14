----------------------------------------------------------------------------
--
--! @file       SR_FlipFlop.vhd
--! @brief      Implements an SR flip-flop.
--! @details    Produces SR flip-flop output with both reset and set
--!             dominant when both are set at the same time.
--! @author     Emery Newlon
--! @date       July 2015
--! @copyright  Copyright (C) 2015 Ross K. Snider and Emery L. Newlon
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
--! @brief      SR Flip-Flop
--! @details    Simple Set/Reset flip-flop with outputs for both when
--!             reset dominates and set dominates when both inputs are high
--!             at the same time.
--! @param      source_cnt_g    Number of input lines.
--! @param      resets_in       Bit vector of reset lines.
--! @param      sets_in         Bit vector of set lines.
--! @param      results_rd_out  Bit vector of results with outputs clear
--!                             when both set and reset are high together.
--!                             (Reset Dominant)
--! @param      results_sd_out  Bit vector of results with outputs set
--!                             when both set and reset are high together.
--!                             (Set Dominant)
--
----------------------------------------------------------------------------

entity SR_FlipFlop is

  Generic (
    source_cnt_g          : natural   :=  1
  ) ;
  Port (
    resets_in             : in    std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
    sets_in               : in    std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
    results_rd_out        : out   std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
    results_sd_out        : out   std_logic_vector (source_cnt_g-1
                                                    downto 0)
  ) ;

end entity SR_FlipFlop ;


architecture rtl of SR_FlipFlop is

  signal results          : std_logic_vector (source_cnt_g-1 downto 0) :=
                                                    (others => '0') ;
  signal results_inv      : std_logic_vector (source_cnt_g-1 downto 0) :=
                                                    (others => '1') ;

begin

  --  Logic interconnect for a SR flip-flop.  The results will be the same
  --  on both output lines except when both inputs are high at the same
  --  time.  Then the reset dominating line will be clear and the set
  --  dominating line will be set.
  --
  --                ______
  --     resets ----\     \   results
  --                 )     )O---+----------------- results reset dominating
  --             +--/_____/     |
  --             |              |
  --             |_______  _____|
  --                     \/
  --              _______/\_____
  --             |  ______      |
  --             +--\     \     |          |\
  --                 )     )O---+----------| }O--- results set dominating
  --     sets   ----/_____/   results_inv  |/
  --

  results                 <= not (resets_in or results_inv) ;
  results_inv             <= not (sets_in   or results) ;

  results_rd_out          <= results ;
  results_sd_out          <= not results_inv ;

end architecture rtl ;
