----------------------------------------------------------------------------
--
--! @file       RealTimeClock.vhd
--! @brief      Handles the time to and from the Real Time Clock.
--! @details    The Real Time Clock time is the number of seconds since
--!             Midnight January 1, 1970 GMT.
--! @author     Emery Newlon
--! @date       August 2015
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


library IEEE ;                        --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;         --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;            --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;              --  Real number functions.

LIBRARY GENERAL ;                     --  Use General Purpose Libraries
USE GENERAL.UTILITIES_PKG.ALL ;       --  General Utilities.
USE GENERAL.GPS_CLOCK_PKG.ALL ;       --  Use GPS Clock information.
USE GENERAL.FORMATSECONDS_PKG.ALL ;   --  Use Second Formatting information.

LIBRARY WORK ;
USE WORK.COMPILE_START_TIME_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Maintains the Real Time Clock in seconds.
--! @details    Loads, stores, and maintains the Real Time Clock (RTC)
--!             value in seconds.  The local date and time are derived from
--!             this value.
--!
--! @param      reset             Reset the module.
--! @param      startup_time_in   Time since startup in GPS format.
--! @param      leap_seconds_in   Number of leap seconds since 2012.
--! @param      rtc_sec_in        Seconds to set the Real Time Clock to.
--! @param      rtc_set_in        Set the RTC on rising edge.
--! @param      rtc_sec_out       RTC current value in seconds.
--! @param      rtc_datetime_out  Local time in year-month-day
--!                               hour-minute-second.
--! @param      alarm_time_in     Time to set the RTC alarm to local time.
--! @param      alarm_set_in      Set the alarm on rising edge.
--
----------------------------------------------------------------------------

entity RealTimeClock is

  Port (
    reset             : in    std_logic ;
    startup_time_in   : in    std_logic_vector (gps_time_bits_c-1 downto 0) ;
    leap_seconds_in   : in    unsigned (7 downto 0) ;
    rtc_sec_in        : in    unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_set_in        : in    std_logic ;
    rtc_sec_out       : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_datetime_out  : out   std_logic_vector (dt_totalbits_c-1 downto 0) ;

    alarm_time_in     : in    std_logic_vector (dt_totalbits_c-1 downto 0) ;
    alarm_set_in      : in    std_logic
  ) ;

end entity RealTimeClock ;


architecture rtl of RealTimeclock is

  --  Initialize the seconds value to a valid time in the recent past.

  signal rtc_seconds          : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal alarm_seconds        : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal date_time            : std_logic_vector (dt_totalbits_c-1
                                                  downto 0) ;

  signal calc_datetime_start  : std_logic ;
  signal calc_datetime_done   : std_logic ;
  signal calc_alarm_start     : std_logic ;
  signal calc_alarm_done      : std_logic ;

  --  Epoch since 1970 seconds to/from local broken down time converter.

  component FormatSeconds is
    Generic (
      timezone_g        : integer   := -7 * 60 * 60 ;
      use_dst_g         : std_logic := '1' ;
      dst_start_mth_g   : natural   :=  3 ;
      dst_start_day_g   : natural   :=  8 ;
      dst_start_hr_g    : natural   :=  2 ;
      dst_start_min_g   : natural   :=  0 ;
      dst_end_mth_g     : natural   := 11 ;
      dst_end_day_g     : natural   :=  1 ;
      dst_end_hr_g      : natural   :=  2 ;
      dst_end_min_g     : natural   :=  0 ;
      dst_seconds_g     : natural   := 60 * 60
    ) ;
    Port (
      reset             : in    std_logic ;
      leap_seconds_in   : in    unsigned (7 downto 0) ;
      epoch70_in        : in    unsigned (epoch70_secbits_c-1 downto 0) ;
      datetime_out      : out   std_logic_vector (dt_totalbits_c-1 downto 0) ;
      to_datetime_clk   : in    std_logic ;
      to_dt_start_in    : in    std_logic ;
      to_dt_done_out    : out   std_logic ;
      datetime_in       : in    std_logic_vector (dt_totalbits_c-1 downto 0) ;
      epoch70_out       : out   unsigned (epoch70_secbits_c-1 downto 0) ;
      from_datetime_clk : in    std_logic ;
      from_dt_start_in  : in    std_logic ;
      from_dt_done_out  : out   std_logic
    ) ;
  end component FormatSeconds ;

  --  Capture short input signals.

  component SR_FlipFlop is
    Generic (
      source_cnt_g      : natural   :=  1
    ) ;
    Port (
      resets_in         : in    std_logic_vector (source_cnt_g-1 downto 0) ;
      sets_in           : in    std_logic_vector (source_cnt_g-1 downto 0) ;
      results_rd_out    : out   std_logic_vector (source_cnt_g-1 downto 0) ;
      results_sd_out    : out   std_logic_vector (source_cnt_g-1 downto 0)
    ) ;
  end component SR_FlipFlop ;

  --  Eight millisecond clock taken from a low bit of the startup time's
  --  millisecond field.

  constant milli_count_c    : natural := 125 ;

  signal rtc_milli_cnt      : unsigned (const_bits (milli_count_c-1)-1
                                        downto 0) ;
  signal milli_clk          : std_logic ;
  signal startup_time       : GPS_Time ;

begin

  startup_time              <= TO_GPS_TIME (startup_time_in) ;

  milli_clk                 <= startup_time.week_millisecond (2) ;

  --  Date/Time converter.

  dt_cnv : FormatSeconds
    Generic Map (
      timezone_g        => -7 * 60 * 60,  -- Mountain Standard Time
      use_dst_g         => '1',
      dst_start_mth_g   => 3,       -- Second Sunday in March, 2:00 AM.
      dst_start_day_g   => 8,
      dst_start_hr_g    => 2,
      dst_start_min_g   => 0,
      dst_end_mth_g     => 11,      -- First Sunday in Novermber, 2:00 AM.
      dst_end_day_g     => 1,
      dst_end_hr_g      => 2,
      dst_end_min_g     => 0,
      dst_seconds_g     => 60 * 60  --  One hour forward.
    )
    Port Map (
      reset             => reset,
      leap_seconds_in   => leap_seconds_in,
      epoch70_in        => rtc_seconds + 1,
      datetime_out      => date_time,
      to_datetime_clk   => milli_clk,
      to_dt_start_in    => calc_datetime_start,
      to_dt_done_out    => calc_datetime_done,
      datetime_in       => alarm_time_in,
      epoch70_out       => alarm_seconds,
      from_datetime_clk => milli_clk,
      from_dt_start_in  => calc_alarm_start,
      from_dt_done_out  => calc_alarm_done
    ) ;

  --  Capture alarm set.

  alrm_set : SR_FlipFlop
    Generic Map (
      source_cnt_g          => 1
    )
    Port Map (
      resets_in      (0)    => calc_alarm_done,
      sets_in        (0)    => alarm_set_in,
      results_sd_out (0)    => calc_alarm_start
    ) ;

  --------------------------------------------------------------------------
  --  Count seconds for the RTC clock.
  --------------------------------------------------------------------------

  upd_sec : process (reset, milli_clk)
  begin
    if (reset = '1') then
      rtc_seconds             <= TO_UNSIGNED (compile_timestamp_c,
                                              rtc_seconds'length) ;
      rtc_milli_cnt           <= (others => '0') ;
      calc_datetime_start     <= '0' ;

    elsif (rising_edge (milli_clk)) then

      if (rtc_milli_cnt /= milli_count_c) then
        rtc_milli_cnt         <= rtc_milli_cnt + 1 ;
        calc_datetime_start   <= '0' ;
      else
        rtc_milli_cnt         <= (others => '0') ;
        rtc_seconds           <= rtc_seconds + 1 ;

        rtc_datetime_out      <= date_time ;
        calc_datetime_start   <= '1' ;
      end if ;
    end if ;
  end process upd_sec ;


end rtl ;
