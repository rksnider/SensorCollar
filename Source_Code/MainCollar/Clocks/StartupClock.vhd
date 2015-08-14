----------------------------------------------------------------------------
--
--! @file       StartupClock.vhd
--! @brief      Handles the time since startup.
--! @details    The time since startup is kept by 3 clocks.  The number of
--!             weeks since startup, the millisecond in the current week,
--!             and the nanosecond in the current millisecond.
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


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;

LIBRARY GENERAL ;               --  Use General Purpose Libraries
USE GENERAL.UTILITIES_PKG.ALL ; --  General Utilities.
USE GENERAL.GPS_CLOCK_PKG.ALL ; --  Use GPS Clock information.


----------------------------------------------------------------------------
--
--! @brief      Produces time since startup.
--! @details    Produces the number of weeks, milliseconds in the current
--!             week, and nanosecond in the current millisecond all since
--!             the system clock started running.
--!
--! @param      CLK_FREQ              Frequency of the clock signal.
--! @param      clk                   Clock used to drive the counters.
--! @param      time_since_reset_out  Time in GPS format.
--! @param      time_bytes_out        Same time padded into a byte string.
--
----------------------------------------------------------------------------

entity StartupClock is

  Generic (
    clk_freq_g            : natural := 50e6
  ) ;
  Port (
    clk                   : in    std_logic ;
    time_since_reset_out  : out   std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    time_bytes_out        : out   std_logic_vector (gps_time_bytes_c*8-1
                                                    downto 0)
  ) ;

end entity StartupClock ;


architecture rtl of StartupClock is

  --  Reset time for conversion from GPS time to standard logic vector bits.

  signal time_since_reset   : GPS_Time ;

  signal time_bytes         : std_logic_vector (gps_time_bytes_c*8-1
                                                downto 0) :=
                                                    (others => '0') ;
  alias reset_time          : std_logic_vector (gps_time_bits_c-1
                                                downto 0) is
        time_bytes (gps_time_bits_c-1 downto 0) ;

  --  Number of clock ticks in a millisecond and nanoseconds in a
  --  clock tick.

  constant clk_in_nanosec_c         : natural :=
                  natural (round (1.0e9 / real (clk_freq_g))) ;
  constant clk_per_millisec_c       : natural :=
                  natural (round (real (clk_freq_g) / 1000.0)) ;
  constant clk_per_millisec_bits_c  : natural :=
                  const_bits (clk_per_millisec_c) ;


  --  Clock counter connectors.

  signal nanosec_cnt        : std_logic_vector (gps_time_nanobits_c-1
                                                downto 0) :=
                                                (others => '0') ;
  signal millisec_cnt       : std_logic_vector (gps_time_millibits_c-1
                                                downto 0) ;
  signal weekno_cnt         : std_logic_vector (gps_time_weekbits_c-1
                                                downto 0) ;
  signal carry_to_millisec  : std_logic ;
  signal carry_to_week      : std_logic ;

begin

  --  Conversion from GPS time format to standard logic vector output.

  reset_time              <= TO_STD_LOGIC_VECTOR (time_since_reset) ;
  time_since_reset_out    <= reset_time ;
  time_bytes_out          <= time_bytes ;

  --  Counter definitions.

  sysclock_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_MODULUS         => clk_per_millisec_c,
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => clk_per_millisec_bits_c
    )
    Port Map (
      clock               => clk,
      cout                => carry_to_millisec
    ) ;

  millisec_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_MODULUS         => millisec_week_c,
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => gps_time_millibits_c
    )
    Port Map (
      cin                 => carry_to_millisec,
      clock               => clk,
      cout                => carry_to_week,
      q                   => millisec_cnt
    ) ;

  week_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => gps_time_weekbits_c
    )
    Port Map (
      cin                 => carry_to_week,
      clock               => clk,
      q                   => weekno_cnt
    ) ;

  --  Latch the clocks all on the same clock edge to insure they are always
  --  consistant.

  latch_process : process (clk)
    variable nanocnt      : unsigned (gps_time_nanobits_c-1 downto 0) ;
  begin
    if (rising_edge (clk)) then
      if carry_to_millisec = '1' then
        nanocnt           := (others => '0') ;
      else
        nanocnt           := unsigned (nanosec_cnt) + clk_in_nanosec_c ;
      end if ;

      nanosec_cnt                       <= std_logic_vector (nanocnt) ;

      time_since_reset.millisecond_nanosecond
                                        <= std_logic_vector (nanosec_cnt) ;
      time_since_reset.week_millisecond <= millisec_cnt ;
      time_since_reset.week_number      <= weekno_cnt ;
    end if ;
  end process latch_process ;

end rtl ;
