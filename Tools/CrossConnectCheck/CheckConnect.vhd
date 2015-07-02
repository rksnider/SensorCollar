----------------------------------------------------------------------------
--
--! @file       CheckConnect.vhd
--! @brief      Check a set of in/out pins for cross connections.
--! @details    Check a vector of in/out pins for cross connections.
--! @author     Emery Newlon
--! @date       June 2015
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

library IEEE ;                      --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;       --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;          --! Use numeric standard.

library GENERAL ;                   --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      CheckConnect.
--! @details    Check Output and Bidirection pins for cross connections.
--!             The bus hold circuitry is first driven with the same level
--!             for all lines.  Then the lines are put in high-impedence
--!             mode and checked to see if they changed value.  If they
--!             did there is some type of cross connection.
--!
--! @param      bits_g      Number of bits to be checked.
--! @param      clk         Clock driving the logic.
--! @param      check_io    I/O lines to check.
--!
--
----------------------------------------------------------------------------

entity CheckConnect is

  Generic (
    bits_g                    : natural := 10
  ) ;
  Port (
    clk                       : in    std_logic ;
    check_io                  : inout std_logic_vector (bits_g-1 downto 0)
  ) ;

  end entity CheckConnect ;

architecture rtl of CheckConnect is

  component GenClock is
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
  end component GenClock ;

  signal slow_clk           : std_logic ;

  --  Memory Action States.

  type CheckState_t is  (
    chkst_low_start_e,
    chkst_low_wait_e,
    chkst_low_save_e,
    chkst_low_verify_e,
    chkst_high_start_e,
    chkst_high_wait_e,
    chkst_high_save_e,
    chkst_high_verify_e,
    chkst_bit_start_e,
    chkst_bit_drive_e,
    chkst_bit_highz_e,
    chkst_bit_readz_e,
    chkst_bit_setlow_e,
    chkst_bit_low_save_e,
    chkst_bit_low_verify_e,
    chkst_bit_sethi_e,
    chkst_bit_hi_save_e,
    chkst_bit_hi_verify_e,
    chkst_next_e
  ) ;

  signal check_state        : CheckState_t ;

  --  Reset information.  The power up signal defaults to zero.

  constant pu_count_c       : natural := 3 ;

  signal reset              : std_logic ;
  signal power_up           : std_logic := '0' ;
  signal pu_counter         : unsigned (const_bits (pu_count_c)-1
                                        downto 0) := (others => '0') ;

  --  Check control signals.

  constant check_bits_c       : natural := const_bits (bits_g-1) + 1 ;

  signal counter              : unsigned (check_bits_c-1 downto 0) ;
  signal bitno                : unsigned (check_bits_c-2 downto 0) ;

  signal check_input          : std_logic_vector (bits_g-1 downto 0) ;
  signal check_output         : std_logic_vector (bits_g-1 downto 0) ;
  signal check_target         : std_logic_vector (bits_g-1 downto 0) ;
  signal check_match          : std_logic_vector (bits_g-1 downto 0) ;

  signal check_clock          : std_logic ;
  signal check_failed         : std_logic ;

  --  Preserve signals for use by signal tap.

  attribute noprune                   : boolean ;
  attribute noprune of check_target   : signal is true ;
  attribute noprune of check_match    : signal is true ;
  attribute noprune of check_clock    : signal is true ;
  attribute noprune of check_failed   : signal is true ;

begin

  --  Generate a 1MHz clock.

  slow_clock : GenClock
    Generic Map (
      clk_freq_g              => 50e6,
      out_clk_freq_g          =>  5e6
    )
    Port Map (
      reset                   => reset,
      clk                     => clk,
      clk_on_in               => '1',
      clk_off_in              => '0',
      clk_out                 => slow_clk
    ) ;

  --------------------------------------------------------------------------
  --  Reset occurs on power up or button press of the reset button.
  --------------------------------------------------------------------------

  reset                     <= not power_up ;

  reset_poweron : process (clk)
  begin
    if (rising_edge (clk)) then
      if (pu_counter = pu_count_c) then
        power_up              <= '1' ;
      else
        pu_counter            <= pu_counter + 1 ;
      end if ;
    end if ;
  end process reset_poweron ;

  --------------------------------------------------------------------------
  --  Check all output lines for cross connections.
  --------------------------------------------------------------------------

  cross_check : process (reset, slow_clk)
  begin
    if (reset = '1') then
      check_state           <= chkst_low_start_e ;
      check_clock           <= '0' ;
      check_failed          <= '0' ;
      check_io              <= (others => '1') ;

    elsif (rising_edge (slow_clk)) then

      check_failed          <= '0' ;
      check_clock           <= '0' ;

      case check_state is

        --  Determine if any of the lines are always high.  Putting lines
        --  into high impedence state causes some of them to bounce to the
        --  opposite value of what they held previously.

        when chkst_low_start_e    =>
          check_target                      <= (others => '0') ;
          check_io                          <= (others => '0') ;
          check_state                       <= chkst_low_wait_e ;

        when chkst_low_wait_e     =>
          check_io                          <= (others => 'Z') ;
          check_state                       <= chkst_low_save_e ;

        when chkst_low_save_e     =>
          check_input                       <= check_io ;
          check_match                       <= check_target ;
          check_state                       <= chkst_low_verify_e ;

        when chkst_low_verify_e   =>
          if (check_input /= check_target) then
            check_failed                    <= '1' ;
          end if ;

          check_clock                       <= '1' ;
          check_state                       <= chkst_high_start_e ;

        --  Determine if any of the lines are always low.

        when chkst_high_start_e   =>
          check_target                      <= (others => '1') ;
          check_io                          <= (others => '1') ;
          check_state                       <= chkst_high_wait_e ;

        when chkst_high_wait_e    =>
          check_io                          <= (others => 'Z') ;
          check_state                       <= chkst_high_save_e ;

        when chkst_high_save_e    =>
          check_input                       <= not check_io ;
          check_match                       <= check_target ;
          check_state                       <= chkst_high_verify_e ;

        when chkst_high_verify_e  =>
          if (check_input /= check_target) then
            check_failed                    <= '1' ;
          end if ;

          check_clock                       <= '1' ;
          check_state                       <= chkst_bit_start_e ;

        --  Determine if any bit is cross connected to other bits.
        --  All bits will be set to 0 or 1 locking in this value to the
        --  bus hold circuitry.  Then all lines are put into high Z.  Next
        --  one bit is set to zero then one.  If it is the only bit that
        --  changes level then there is no cross connection for it.

        when chkst_bit_start_e      =>
          counter                           <= (others => '0') ;
          check_state                       <= chkst_bit_drive_e ;

        when chkst_bit_drive_e      =>
          bitno                             <= counter (check_bits_c-1
                                                        downto 1) ;
          check_io                          <= (others => counter (0)) ;
          check_state                       <= chkst_bit_highz_e ;

        when chkst_bit_highz_e       =>
          check_io                          <= (others => 'Z') ;
          check_state                       <= chkst_bit_readz_e ;

        when chkst_bit_readz_e      =>
          check_target                      <= check_io ;
          check_state                       <= chkst_bit_setlow_e ;

        when chkst_bit_setlow_e     =>
          check_target (TO_INTEGER (bitno)) <= '0' ;
          check_io     (TO_INTEGER (bitno)) <= '0' ;
          check_state                       <= chkst_bit_low_save_e ;

        when chkst_bit_low_save_e   =>
          check_input                       <= check_io ;
          check_match                       <= check_target ;
          check_state                       <= chkst_bit_low_verify_e ;

        when chkst_bit_low_verify_e =>
          if (check_input /= check_target) then
            check_failed                    <= '1' ;
          end if ;

          check_clock                       <= '1' ;
          check_state                       <= chkst_bit_sethi_e ;

        when chkst_bit_sethi_e      =>
          check_target (TO_INTEGER (bitno)) <= '1' ;
          check_io     (TO_INTEGER (bitno)) <= '1' ;
          check_state                       <= chkst_bit_hi_save_e ;

        when chkst_bit_hi_save_e    =>
          check_input                       <= check_io ;
          check_match                       <= check_target ;
          check_state                       <= chkst_bit_hi_verify_e ;

        when chkst_bit_hi_verify_e  =>
          if (check_input /= check_target) then
            check_failed                    <= '1' ;
          end if ;

          check_clock                       <= '1' ;
          check_state                       <= chkst_next_e ;

        when chkst_next_e           =>
          if (counter /= bits_g * 2 - 1) then
            counter                         <= counter + 1 ;
            check_state                     <= chkst_bit_drive_e ;
          else
            check_state                     <= chkst_low_start_e ;
          end if ;
      end case ;
    end if ;
  end process cross_check ;


end architecture rtl ;
