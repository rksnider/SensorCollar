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
--! @details    Generate a clock and gated versions by counting the cycles
--!             of a faster clock until a half cycle of the new clock is
--!             reached.  The new clock output is toggled then.  If the
--!             new clock runs at the same speed as the old clock then
--!             pass it through directly.
--!
--! @param      clk_freq_g          Frequency of the source clock in
--!                                 cycles per second.
--! @param      out_clk_freq_g      Frequency the result clock in cycles per
--!                                 second.
--! @param      net_clk_g           Type of network for the output clock.
--!                                   0 - None, 1 - Global,
--!                                   2 - Dual Regional,
--!                                   3 - Quadrant Regional
--! @param      net_inv_g           Type of network for inverted clock.
--! @param      net_gated_g         Type of network for gated clock.
--! @param      net_inv_gated_g     Type of network for gated inverted clk.
--! @param      reset               Reset all the processing information.
--! @param      clk                 Clock used to drive clock generation.
--! @param      clk_on_in           Turn on the gated result clock.
--! @param      clk_off_in          Turn off the gated result clock.
--! @param      clk_out             The result clock.
--! @param      clk_inv_out         The inverted result clock.
--! @param      gated_clk_out       The gated result clock.
--! @param      gated_clk_inv_out   The inverted gated result clock.
--
----------------------------------------------------------------------------

entity GenClock is

  Generic (
    clk_freq_g              : natural   := 10e6 ;
    out_clk_freq_g          : natural   := 1e6 ;
    net_clk_g               : natural   := 0 ;
    net_inv_g               : natural   := 0 ;
    net_gated_g             : natural   := 0 ;
    net_inv_gated_g         : natural   := 0
  ) ;
  Port (
    reset                   : in    std_logic ;
    clk                     : in    std_logic ;
    clk_on_in               : in    std_logic ;
    clk_off_in              : in    std_logic ;
    clk_out                 : out   std_logic ;
    clk_inv_out             : out   std_logic ;
    gated_clk_out           : out   std_logic ;
    gated_clk_inv_out       : out   std_logic
  ) ;

end entity GenClock ;

architecture rtl of GenClock is

  --  Clock information.  If this clock drives the reset line (externally)
  --  it will not ever receive a reset signal.  It should initialize itself
  --  as best it can without one.

  constant clk_cntmax_c     : natural := clk_freq_g / (out_clk_freq_g * 2) ;
  constant clk_cntsize_c    : natural := maximum (1, clk_cntmax_c) ;
  constant clk_cntbits_c    : natural := const_bits (clk_cntsize_c) ;

  signal clk_cnt            : unsigned (clk_cntbits_c-1 downto 0) :=
                                              (others => '0') ;

  signal gated_clk_en       : std_logic := '0' ;
  signal gated_inv_clk_en   : std_logic := '0' ;

  attribute keep            : boolean ;

  signal out_clk            : std_logic := '0' ;
  signal out_clk_inv        : std_logic := '0' ;
  signal out_gated_clk      : std_logic := '0' ;
  signal out_gated_clk_inv  : std_logic := '0' ;

  attribute keep of out_clk           : signal is true ;
  attribute keep of out_clk_inv       : signal is true ;
  attribute keep of out_gated_clk     : signal is true ;
  attribute keep of out_gated_clk_inv : signal is true ;

  --  Clock network components.

  COMPONENT GlobalClock IS
    PORT
    (
      ena    : IN STD_LOGIC  := '1';
      inclk    : IN STD_LOGIC ;
      outclk    : OUT STD_LOGIC
    );
  END COMPONENT GlobalClock;

  COMPONENT DualClock IS
    PORT
    (
      ena    : IN STD_LOGIC  := '1';
      inclk    : IN STD_LOGIC ;
      outclk    : OUT STD_LOGIC
    );
  END COMPONENT DualClock;

  COMPONENT QuadrantClock IS
    PORT
    (
      ena    : IN STD_LOGIC  := '1';
      inclk    : IN STD_LOGIC ;
      outclk    : OUT STD_LOGIC
    );
  END COMPONENT QuadrantClock;


begin

  --------------------------------------------------------------------------
  --  Select the clock networking to used for main output clock.
  --------------------------------------------------------------------------

  clk_Normal:
    if (net_clk_g = 0) generate
      clk_out               <= out_clk ;
    end generate clk_Normal;

  clk_GlobalClock:
    if (net_clk_g = 1) generate
      net_clock: GlobalClock
      PORT MAP
      (
        ena       => '1',
        inclk     => out_clk,
        outclk    => clk_out
      ) ;
    end generate clk_GlobalClock ;

  clk_DualClock:
    if (net_clk_g = 2) generate
      net_clock: DualClock
      PORT MAP
      (
        ena       => '1',
        inclk     => out_clk,
        outclk    => clk_out
      ) ;
    end generate clk_DualClock;

  clk_QuadrantClock:
    if (net_clk_g = 3) generate
      net_clock: QuadrantClock
      PORT MAP
      (
        ena       => '1',
        inclk     => out_clk,
        outclk    => clk_out
      ) ;
    end generate clk_QuadrantClock ;

  --------------------------------------------------------------------------
  --  Select the clock networking to used for inverted output clock.
  --------------------------------------------------------------------------

  clk_inv_Normal:
    if (net_inv_g = 0) generate
      clk_inv_out           <= out_clk_inv ;
    end generate clk_inv_Normal ;

  clk_inv_GlobalClock:
    if (net_inv_g = 1) generate
      net_clock: GlobalClock
      PORT MAP
      (
        ena       => '1',
        inclk     => out_clk_inv,
        outclk    => clk_inv_out
      ) ;
    end generate clk_inv_GlobalClock ;

  clk_inv_DualClock:
    if (net_inv_g = 2) generate
      net_clock: DualClock
      PORT MAP
      (
        ena       => '1',
        inclk     => out_clk_inv,
        outclk    => clk_inv_out
      ) ;
    end generate clk_inv_DualClock ;

  clk_inv_QuadrantClock:
    if (net_inv_g = 3) generate
      net_clock: QuadrantClock
      PORT MAP
      (
        ena       => '1',
        inclk     => out_clk_inv,
        outclk    => clk_inv_out
      ) ;
    end generate clk_inv_QuadrantClock ;

  --------------------------------------------------------------------------
  --  Select the clock networking to used for gated output clock.
  --------------------------------------------------------------------------

  gated_clk_Normal:
    if (net_gated_g = 0) generate
      gated_clk_out         <= out_gated_clk ;
    end generate gated_clk_Normal ;

  gated_clk_GlobalClock:
    if (net_gated_g = 1) generate
      net_clock: GlobalClock
      PORT MAP
      (
        ena       => gated_clk_en,
        inclk     => out_clk,
        outclk    => gated_clk_out
      ) ;
    end generate gated_clk_GlobalClock ;

  gated_clk_DualClock:
    if (net_gated_g = 2) generate
      net_clock: DualClock
      PORT MAP
      (
        ena       => gated_clk_en,
        inclk     => out_clk,
        outclk    => gated_clk_out
      ) ;
    end generate gated_clk_DualClock ;

  gated_clk_QuadrantClock :
    if (net_gated_g = 3) generate
      net_clock: QuadrantClock
      PORT MAP
      (
        ena       => gated_clk_en,
        inclk     => out_clk,
        outclk    => gated_clk_out
      ) ;
    end generate gated_clk_QuadrantClock ;

  --------------------------------------------------------------------------
  --  Select the clock networking to used for gated inverted output clock.
  --------------------------------------------------------------------------

  gated_clk_inv_Normal:
    if (net_inv_gated_g = 0) generate
      gated_clk_inv_out       <= out_gated_clk_inv ;
    end generate gated_clk_inv_Normal ;

  gated_clk_inv_GlobalClock:
    if (net_inv_gated_g = 1) generate
      net_clock: GlobalClock
      PORT MAP
      (
        ena       => gated_inv_clk_en,
        inclk     => out_clk_inv,
        outclk    => gated_clk_inv_out
      ) ;
    end generate gated_clk_inv_GlobalClock ;

  gated_clk_inv_DualClock:
    if (net_inv_gated_g = 2) generate
      net_clock: DualClock
      PORT MAP
      (
        ena       => gated_inv_clk_en,
        inclk     => out_clk_inv,
        outclk    => gated_clk_inv_out
      ) ;
    end generate gated_clk_inv_DualClock ;

  gated_clk_inv_QuadrantClock:
    if (net_inv_gated_g = 3) generate
      net_clock: QuadrantClock
      PORT MAP
      (
        ena       => gated_inv_clk_en,
        inclk     => out_clk_inv,
        outclk    => gated_clk_inv_out
      ) ;
    end generate gated_clk_inv_QuadrantClock ;

  --------------------------------------------------------------------------
  --  Clock enable setting.
  --------------------------------------------------------------------------

  clk_enable : process (reset, clk)
    variable new_clk        : std_logic ;
  begin
    if (reset = '1') then
      gated_clk_en          <= '0' ;

    --  Handle gated clocks when the input clock passes through directly.

    elsif (rising_edge (clk)) then
      if (clk_on_in = '1') then
        gated_inv_clk_en  <= '1' ;

      elsif (clk_off_in = '1') then
        gated_inv_clk_en  <= '0' ;

      end if ;

    elsif (falling_edge (clk)) then
      if (clk_on_in = '1') then
        gated_clk_en      <= '1' ;

      elsif (clk_off_in = '1') then
        gated_clk_en      <= '0' ;

      end if ;
    end if ;

  end process clk_enable ;


  --------------------------------------------------------------------------
  --  Clock generation, both gated clocks are normal.
  --------------------------------------------------------------------------

  net_both_gated_normal :
    if (net_gated_g = 0 and net_inv_gated_g = 0) generate

      direct_clock :
        if (clk_cntmax_c = 0) generate

          clk_gen : process (reset, clk, gated_clk_en, gated_inv_clk_en)
          begin
            if (reset = '1') then
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;
              out_gated_clk         <= '0' ;
              out_gated_clk_inv     <= '0' ;

            --  Handle clocks that pass through directly.

            else
              out_clk               <= clk ;
              out_clk_inv           <= not clk ;
              out_gated_clk         <= clk and gated_clk_en ;
              out_gated_clk_inv     <= (not clk) and gated_inv_clk_en ;
            end if ;
          end process clk_gen ;

        end generate direct_clock ;

      divided_clock :
        if (clk_cntmax_c /= 0) generate

          clk_gen : process (reset, clk)
            variable new_clk        : std_logic ;
          begin
            if (reset = '1') then
              clk_cnt               <= (others => '0') ;
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;
              out_gated_clk         <= '0' ;
              out_gated_clk_inv     <= '0' ;

            --  Count out a half cycle of the output clock in driver clock cycles.

            elsif (rising_edge (clk)) then
              if (clk_cnt /= TO_UNSIGNED (clk_cntmax_c - 1,
                                          clk_cnt'length)) then

                clk_cnt             <= clk_cnt + 1 ;
              else
                clk_cnt             <= (others => '0') ;

                --  Generate a new output clock edge and start counting a half
                --  cycle again.

                new_clk             := not out_clk ;
                out_clk             <= new_clk ;
                out_clk_inv         <= not new_clk ;
                out_gated_clk       <= new_clk and gated_clk_en ;
                out_gated_clk_inv   <= (not new_clk) and gated_inv_clk_en ;
              end if ;
            end if ;
          end process clk_gen ;

        end generate divided_clock ;
    end generate net_both_gated_normal ;

  --------------------------------------------------------------------------
  --  Clock generation, gated normal.
  --------------------------------------------------------------------------

  net_gated_normal :
    if (net_gated_g = 0 and net_inv_gated_g /= 0) generate

      direct_clock :
        if (clk_cntmax_c = 0) generate

          clk_gen : process (reset, clk, gated_clk_en)
          begin
            if (reset = '1') then
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;
              out_gated_clk         <= '0' ;

            --  Handle clocks that pass through directly.

            else
              out_clk               <= clk ;
              out_clk_inv           <= not clk ;
              out_gated_clk         <= clk and gated_clk_en ;
            end if ;
          end process clk_gen ;

        end generate direct_clock ;

      divided_clock :
        if (clk_cntmax_c /= 0) generate

          clk_gen : process (reset, clk)
            variable new_clk        : std_logic ;
          begin
            if (reset = '1') then
              clk_cnt               <= (others => '0') ;
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;
              out_gated_clk         <= '0' ;

            --  Count out a half cycle of the output clock in driver clock cycles.

            elsif (rising_edge (clk)) then
              if (clk_cnt /= TO_UNSIGNED (clk_cntmax_c - 1,
                                          clk_cnt'length)) then

                clk_cnt             <= clk_cnt + 1 ;
              else
                clk_cnt             <= (others => '0') ;

                --  Generate a new output clock edge and start counting a half
                --  cycle again.

                new_clk             := not out_clk ;
                out_clk             <= new_clk ;
                out_clk_inv         <= not new_clk ;
                out_gated_clk       <= new_clk and gated_clk_en ;
              end if ;
            end if ;
          end process clk_gen ;

        end generate divided_clock ;
    end generate net_gated_normal ;

  --------------------------------------------------------------------------
  --  Clock generation, gated inverted normal.
  --------------------------------------------------------------------------

  net_gated_inverted_normal :
    if (net_gated_g /= 0 and net_inv_gated_g = 0) generate

      direct_clock :
        if (clk_cntmax_c = 0) generate

          clk_gen : process (reset, clk, gated_inv_clk_en)
          begin
            if (reset = '1') then
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;
              out_gated_clk_inv     <= '0' ;

            --  Handle clocks that pass through directly.

            else
              out_clk               <= clk ;
              out_clk_inv           <= not clk ;
              out_gated_clk_inv     <= (not clk) and gated_inv_clk_en ;
            end if ;
          end process clk_gen ;

        end generate direct_clock ;

      divided_clock :
        if (clk_cntmax_c /= 0) generate

          clk_gen : process (reset, clk)
            variable new_clk        : std_logic ;
          begin
            if (reset = '1') then
              clk_cnt               <= (others => '0') ;
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;
              out_gated_clk_inv     <= '0' ;

            --  Count out a half cycle of the output clock in driver clock cycles.

            elsif (rising_edge (clk)) then
              if (clk_cnt /= TO_UNSIGNED (clk_cntmax_c - 1,
                                          clk_cnt'length)) then

                clk_cnt             <= clk_cnt + 1 ;
              else
                clk_cnt             <= (others => '0') ;

                --  Generate a new output clock edge and start counting a half
                --  cycle again.

                new_clk             := not out_clk ;
                out_clk             <= new_clk ;
                out_clk_inv         <= not new_clk ;
                out_gated_clk_inv   <= (not new_clk) and gated_inv_clk_en ;
              end if ;
            end if ;
          end process clk_gen ;

        end generate divided_clock ;
    end generate net_gated_inverted_normal ;

  --------------------------------------------------------------------------
  --  Clock generation, neither gated normal.
  --------------------------------------------------------------------------

  net_neither_normal :
    if (net_gated_g /= 0 and net_inv_gated_g /= 0) generate

      direct_clock :
        if (clk_cntmax_c = 0) generate

          clk_gen : process (reset, clk)
          begin
            if (reset = '1') then
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;

            --  Handle clocks that pass through directly.

            else
              out_clk               <= clk ;
              out_clk_inv           <= not clk ;
            end if ;
          end process clk_gen ;

        end generate direct_clock ;

      divided_clock :
        if (clk_cntmax_c /= 0) generate

          clk_gen : process (reset, clk)
            variable new_clk        : std_logic ;
          begin
            if (reset = '1') then
              clk_cnt               <= (others => '0') ;
              out_clk               <= '0' ;
              out_clk_inv           <= '0' ;

            --  Count out a half cycle of the output clock in driver clock cycles.

            elsif (rising_edge (clk)) then
              if (clk_cnt /= TO_UNSIGNED (clk_cntmax_c - 1,
                                          clk_cnt'length)) then

                clk_cnt             <= clk_cnt + 1 ;
              else
                clk_cnt             <= (others => '0') ;

                --  Generate a new output clock edge and start counting a half
                --  cycle again.

                new_clk             := not out_clk ;
                out_clk             <= new_clk ;
                out_clk_inv         <= not new_clk ;
              end if ;
            end if ;
          end process clk_gen ;

        end generate divided_clock ;
    end generate net_neither_normal ;

end architecture rtl ;
