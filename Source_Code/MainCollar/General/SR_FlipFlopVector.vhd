---------------------------------------------------------------------------
--
--! @file       SR_FlipFlopVector.vhd
--! @brief      Implements a vector of SR flip-flops.
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
--! @param    source_cnt_g        Number of input lines.
--! @param    set_edge_detect_g   Set on the rising edge of the set input.
--!                               Otherwise set on high level.
--! @param    clear_edge_detect_g Clear on the rising edge of the clear
--!                               input.  Otherwise clear on high level.
--! @param    resets_in           Bit vector of reset lines.
--! @param    sets_in             Bit vector of set lines.
--! @param    results_rd_out      Bit vector of results with outputs clear
--!                               when both set and reset are high together.
--!                               (Reset Dominant)
--! @param    results_sd_out      Bit vector of results with outputs set
--!                               when both set and reset are high together.
--!                               (Set Dominant)
--
----------------------------------------------------------------------------

entity SR_FlipFlopVector is

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

end entity SR_FlipFlopVector ;


architecture rtl of SR_FlipFlopVector is

  signal results          : std_logic_vector (source_cnt_g-1 downto 0) :=
                                                    (others => '0') ;
  signal results_inv      : std_logic_vector (source_cnt_g-1 downto 0) :=
                                                    (others => '1') ;
  signal set_triggers     : std_logic_vector (source_cnt_g-1 downto 0) ;
  signal clr_triggers     : std_logic_vector (source_cnt_g-1 downto 0) ;

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
  --
  --  The possible state transitions the flip-flops can make are given by
  --  truth tables.  The stability column indicates the stability of the
  --  result of the input state.  A star indicates the state is stable.  A
  --  U indicates the state is unstable and will degenerate to a stable
  --  state.  An O indicates the state will oscellate between other states
  --  and not degrade to a stable state.  This latter condition is only a
  --  concern if an O state can be entered by the change of a single input
  --  from a stable state.
  --
  --  Output flip-flop.
  --      clr-t  set-t   results   inv   | results   inv   RD    SD  stable
  --        L      L        L       L    |   H        H    H     L     O
  --        L      L        L       H    |   L        H    L     L     *
  --        L      L        H       L    |   H        L    H     H     *
  --        L      L        H       H    |   L        L    L     H     O
  --        L      H        L       L    |   H        L    H     H     U
  --        L      H        L       H    |   H        L    H     H     U
  --        L      H        H       L    |   H        L    H     H     *
  --        L      H        H       H    |   L        L    L     H     U
  --        H      L        L       L    |   L        H    L     L     U
  --        H      L        L       H    |   L        H    L     L     *
  --        H      L        H       L    |   L        H    L     L     U
  --        H      L        H       H    |   L        L    L     H     U
  --        H      H        L       L    |   L        L    L     H     *
  --        H      H        L       H    |   L        L    L     H     U
  --        H      H        H       L    |   L        L    L     H     U
  --        H      H        H       H    |   L        L    L     H     U

  results                       <= not (clr_triggers or results_inv) ;
  results_inv                   <= not (set_triggers or results) ;

  results_rd_out                <= results ;
  results_sd_out                <= not results_inv ;

  --  Edge detection uses another SR flip-flop.
  --  This flip-flop is used to hold the last high value of the input until
  --  that input goes low again.  The last value is inverted and masked with
  --  the input value to keep the trigger low until the input has gone low.
  --  This results in a high pulse when the input goes high.  The input
  --  value for this flip-flop is taken from the main flip-flop to insure
  --  that there is enough time for the trigger signal to propagate through
  --  it before the pulse goes low.

  --  Set triggers.
  --        SD    set-in  set-res   inv   | set-res   inv   trig  stable
  --        L       L        L       L    |    L       H     L      U
  --        L       L        L       H    |    L       H     L      *
  --        L       L        H       L    |    L       L     L      U
  --        L       L        H       H    |    L       L     L      U
  --        L       H        L       L    |    H       H     H      O
  --        L       H        L       H    |    L       H     H      *
  --        L       H        H       L    |    H       L     L      *
  --        L       H        H       H    |    L       L     L      O
  --        H       L        L       L    |    L       L     L      *
  --        H       L        L       H    |    L       L     L      U
  --        H       L        H       L    |    L       L     L      U
  --        H       L        H       H    |    L       L     L      U
  --        H       H        L       L    |    H       L     L      U
  --        H       H        L       H    |    L       L     L      U
  --        H       H        H       L    |    H       L     L      *
  --        H       H        H       H    |    L       L     L      U

  set_level :
    if (set_edge_detect_g = '0') generate

      set_triggers              <= sets_in ;

    end generate set_level ;

  set_edge :
    if (set_edge_detect_g = '1') generate

        signal set_results      : std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
        signal set_results_inv  : std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
      begin
        set_results             <= not (not sets_in         or
                                            set_results_inv) ;
        set_results_inv         <= not (not results_inv     or
                                            set_results) ;

        set_triggers            <= sets_in and set_results_inv ;

    end generate set_edge ;

  --  Clear triggers.
  --        RD    clr-in  clr-res   inv   | clr-res   inv   trig  stable
  --        L       L        L       L    |    L       L     L      *
  --        L       L        L       H    |    L       L     L      U
  --        L       L        H       L    |    L       L     L      U
  --        L       L        H       H    |    L       L     L      U
  --        L       H        L       L    |    H       L     L      U
  --        L       H        L       H    |    L       L     L      U
  --        L       H        H       L    |    H       L     L      *
  --        L       H        H       H    |    L       L     L      U
  --        H       L        L       L    |    L       H     L      U
  --        H       L        L       H    |    L       H     L      *
  --        H       L        H       L    |    L       L     L      U
  --        H       L        H       H    |    L       L     L      U
  --        H       H        L       L    |    H       H     H      O
  --        H       H        L       H    |    L       H     H      *
  --        H       H        H       L    |    H       L     L      *
  --        H       H        H       H    |    L       L     L      O

  clear_level :
    if (clear_edge_detect_g = '0') generate

      clr_triggers              <= resets_in ;

    end generate clear_level ;

  clear_edge :
    if (clear_edge_detect_g = '1') generate

        signal clr_results      : std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
        signal clr_results_inv  : std_logic_vector (source_cnt_g-1
                                                    downto 0) ;
      begin
        clr_results             <= not (not resets_in       or
                                            clr_results_inv) ;
        clr_results_inv         <= not (not results         or
                                            clr_results) ;

        clr_triggers            <= resets_in and clr_results_inv ;

    end generate clear_edge ;

end architecture rtl ;
