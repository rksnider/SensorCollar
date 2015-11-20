----------------------------------------------------------------------------
--
--! @file       GPSclocks.vhd
--! @brief      Clocks and gated clocks needed by GPS entities.
--! @details    Generate all clocks and gated clocks needed by GPS entities
--!             from the master clock.
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;

use GENERAL.GPS_CLOCK_PKG.ALL ;

library WORK ;                  --! Local Library
use WORK.COLLAR_CONTROL_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      GPS Clock Generation.
--! @details    Generate all clocks needed by the GPS entities including
--!             gated clocks.
--!
--! @param      clk_freq_g          Frequency of the source clock in
--!                                 cycles per second.
--! @param      gps_clk_freq_g      Frequency the GPS UART receiver clock is
--!                                 to use.
--! @param      parse_clk_freq_g    Frequency the Message Parsing and
--!                                 memory clocks are to use.
--! @param      tx_clk_freq_q       Frequency the UART transmitter clock is
--!                                 to use.
--! @param      reset               Reset all the processing information.
--! @param      clk                 Clock used to drive clock generation.
--! @param      gps_clk_out         The GPS UART receiver clock.
--! @param      tx_clk_on_in        Turn on the gated UART transmitter
--!                                 clock.
--! @param      tx_clk_off_in       Turn off the gated UART transmitter
--!                                 clock.
--! @param      tx_clk_out          Gated UART transmitter clock.
--! @param      parse_clk_out       The Message Parser and Memory access
--!                                 clock.
--! @param      mem_clk_en_in       Enable the gated memory allocation and
--!                                 memory access clocks.  The memory access
--!                                 clock is the inverted parse clock.
--! @param      mem_clk_out         Gated, inverted memory access clock.
--! @param      memalloc_clk_out    Gated memory allocation clock.
--
----------------------------------------------------------------------------

entity GPSclocks is

  Generic (
    clk_freq_g              : natural   := 10e6 ;
    gps_clk_freq_g          : natural   := 16 * 9600 ;
    parse_clk_freq_g        : natural   := 16 * (9600 / 10) ;
    tx_clk_freq_g           : natural   := 9600
  ) ;
  Port (
    reset                   : in    std_logic ;
    clk                     : in    std_logic ;
    gps_clk_en_in           : in    std_logic ;
    gps_clk_out             : out   std_logic ;
    tx_clk_on_in            : in    std_logic ;
    tx_clk_off_in           : in    std_logic ;
    tx_clk_out              : out   std_logic ;
    parse_clk_en_in         : in    std_logic ;
    parse_clk_out           : out   std_logic ;
    mem_clk_en_in           : in    std_logic ;
    mem_clk_out             : out   std_logic ;
    memalloc_clk_out        : out   std_logic
  ) ;

end entity GPSclocks ;

architecture structural of GPSclocks is

  component GenClock is
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
  end component GenClock ;

  --  GPS clock used to generate other clocks needed by GPS entities.

  signal gps_clk                : std_logic ;

  --  Other clocks.

  signal parse_clk              : std_logic ;


begin

  --  Main GPS Clock generator.

  gpsclk_gen : GenClock
    Generic Map (
      clk_freq_g              => clk_freq_g,
      out_clk_freq_g          => gps_clk_freq_g,
      net_gated_g             => 3
    )
    Port Map (
      reset                   => reset,
      clk                     => clk,
      clk_on_in               => gps_clk_en_in,
      clk_off_in              => not gps_clk_en_in,
      gated_clk_out           => gps_clk
    ) ;

  gps_clk_out                 <= gps_clk ;

  --  UART Transmission Clock generation.

  txclk_gen : GenClock
    Generic Map (
      clk_freq_g              => gps_clk_freq_g,
      out_clk_freq_g          => tx_clk_freq_g
    )
    Port Map (
      reset                   => reset,
      clk                     => gps_clk,
      clk_on_in               => tx_clk_on_in,
      clk_off_in              => tx_clk_off_in,
      gated_clk_out           => tx_clk_out
    ) ;

  --  Parsing Clock generation.  This uses a clock network to avoid data
  --  overtaking the clock in the various modules that use it.

  parseclk_gen : GenClock
    Generic Map (
      clk_freq_g              => gps_clk_freq_g,
      out_clk_freq_g          => parse_clk_freq_g,
      net_gated_g             => 1
    )
    Port Map (
      reset                   => reset,
      clk                     => gps_clk,
      clk_on_in               => parse_clk_en_in,
      clk_off_in              => not parse_clk_en_in,
      gated_clk_out           => parse_clk
    ) ;

  parse_clk_out               <= parse_clk ;

  memclk_gen : GenClock
    Generic Map (
      clk_freq_g              => parse_clk_freq_g,
      out_clk_freq_g          => parse_clk_freq_g
    )
    Port Map (
      reset                   => reset,
      clk                     => parse_clk,
      clk_on_in               => mem_clk_en_in,
      clk_off_in              => not mem_clk_en_in,
      gated_clk_out           => memalloc_clk_out,
      gated_clk_inv_out       => mem_clk_out
    ) ;

end architecture structural ;
