---------------------------------------------------------------------------
--
--! @file       SR_FlipFlopVector.vhd
--! @brief      Implements a simple SR flip-flop.
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
--! @brief    SR Flip-Flop Vector
--! @details  Set/Reset flip-flop with outputs for both when reset dominates
--!           and set dominates when both inputs are high at the same time.
--! @param    set_edge_detect_g   Set on the rising edge of the set input.
--!                               Otherwise set on high level.
--! @param    clear_edge_detect_g Clear on the rising edge of the clear
--!                               input.  Otherwise clear on high level.
--! @param    reset_in            Reset (clear) the flip flop when high or
--!                               on its rising edge.
--! @param    set_in              Set the flip flop when high or on its
--!                               rising edge.
--! @param    result_rd_out       Flip-flop's result.  Will be clear when
--!                               both set and reset are high together.
--!                               (Reset Dominant)
--! @param    result_sd_out       Flip-flop's result.  Will be set when both
--!                               set and reset are high together.
--!                               (Set Dominant)
--
----------------------------------------------------------------------------

entity SR_FlipFlop is

  Generic (
    set_edge_detect_g     : std_logic := '0' ;
    clear_edge_detect_g   : std_logic := '0'
  ) ;
  Port (
    reset_in              : in    std_logic ;
    set_in                : in    std_logic ;
    result_rd_out         : out   std_logic ;
    result_sd_out         : out   std_logic
  ) ;

end entity SR_FlipFlop ;


architecture rtl of SR_FlipFlop is

  signal resets             : std_logic_vector (0 downto 0) ;
  signal sets               : std_logic_vector (0 downto 0) ;
  signal results_rd         : std_logic_vector (0 downto 0) ;
  signal results_sd         : std_logic_vector (0 downto 0) ;

  component SR_FlipFlopVector is
    Generic (
      source_cnt_g          : natural   := 1 ;
      set_edge_detect_g     : std_logic := '0' ;
      clear_edge_detect_g   : std_logic := '0'
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
  end component SR_FlipFlopVector ;

begin

  resets (0)                <= reset_in ;
  sets   (0)                <= set_in ;
  result_rd_out             <= results_rd (0) ;
  result_sd_out             <= results_sd (0) ;

  ff_vector : SR_FlipFlopVector
    Generic Map (
      source_cnt_g          => 1,
      set_edge_detect_g     => set_edge_detect_g,
      clear_edge_detect_g   => clear_edge_detect_g
    )
    Port Map (
      resets_in             => resets,
      sets_in               => sets,
      results_rd_out        => results_rd,
      results_sd_out        => results_sd
    ) ;

end architecture rtl ;
