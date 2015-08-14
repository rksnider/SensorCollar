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
--!             this value.  The RTC alarm is set here as well.
--!
--! @param      gpsmem_addrbits_g   Number of address bits to read GPS mem.
--! @param      gpsmem_databits_g   Number of data bits returned by GPS mem.
--! @param      reset               Reset the module.
--! @param      startup_time_in     System startup time in GPS time format.
--! @param      gps_time_out        GPS time in GPS time format calculated
--!                                 from Timemark info stored in GPS mem.
--!                                 Note that this value can jump as new
--!                                 information is obtained from the GPS.
--! @param      rtc_sec_out         RTC current value in seconds.
--!                                 Note that this value can jump as new
--!                                 information is obtained from the GPS.
--! @param      rtc_datetime_out    Local time in year-month-day
--!                                 hour-minute-second from RTC current
--!                                 value.
--! @param      gpsmem_tmbank_in    Most recent valid Timemark bank in GPS
--!                                 memory.  Change to it triggers update
--!                                 of the GPS and RTC Time outputs.
--! @param      gpsmem_req_out      Request for access to GPS mem.
--! @param      gpsmem_rcv_in       Access granted to GPS mem.
--! @param      gpsmem_addr_out     Address to read from in GPS mem.
--! @param      gpsmem_datafrom_in  Data read from GPS mem.
--! @param      gpsmem_readen_out   Start a read from GPS mem.
--! @param      gpsmem_clk_out      Clock to use for GPS mem access.
--! @param      alarm_time_in       Time to set the RTC alarm in local time.
--! @param      alarm_set_in        Set the alarm on rising edge.
--
----------------------------------------------------------------------------

entity RealTimeClock is

  Generic (
    gpsmem_addrbits_g   : natural := 10 ;
    gpsmem_databits_g   : natural :=  8
  ) ;
  Port (
    reset               : in    std_logic ;
    startup_time_in     : in    std_logic_vector (gps_time_bits_c-1
                                                  downto 0) ;
    gps_time_out        : out   std_logic_vector (gps_time_bits_c-1
                                                  downto 0) ;

    rtc_sec_out         : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_datetime_out    : out   std_logic_vector (dt_totalbits_c-1
                                                  downto 0) ;

    gpsmem_tmbank_in    : in    std_logic ;
    gpsmem_req_out      : out   std_logic ;
    gpsmem_rcv_in       : in    std_logic ;
    gpsmem_addr_out     : out   std_logic_vector (gpsmem_addrbits_g-1
                                                downto 0) ;
    gpsmem_datafrom_in  : in    std_logic_vector (gpsmem_databits_g-1
                                                  downto 0) ;
    gpsmem_readen_out   : out   std_logic ;
    gpsmem_clk_out      : out   std_logic ;

    alarm_time_in       : in    std_logic_vector (dt_totalbits_c-1
                                                  downto 0) ;
    alarm_set_in        : in    std_logic
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

  --  Calculate differences between Real Time Clock and Timemark time
  --  and Startup Time to keep continuing RTC Seconds and GPS Time.

  constant gps_secbits_c      : natural := gps_time_weekbits_c +
                                           gps_time_millibits_c ;

  signal load_time            : GPS_Time ;

  signal rtc_loaded           : unsigned (gps_secbits_c-1 downto 0) ;
  alias rtc_loaded_high       : unsigned (gps_secbits_c-epoch70_secbits_c-1
                                          downto 0) is
                                  rtc_loaded (gps_secbits_c-1 downto
                                              epoch70_secbits_c) ;
  alias rtc_loaded_low        : unsigned (epoch70_secbits_c-1 downto 0) is
                                  rtc_loaded (epoch70_secbits_c-1
                                              downto 0) ;


  signal rtc_secs             : unsigned (gps_secbits_c-1 downto 0) ;
  alias rtc_secs_week         : unsigned (gps_time_weekbits_c-1
                                          downto 0) is
                                    rtc_secs (gps_secbits_c-1 downto
                                              gps_time_millibits_c) ;
  alias rtc_secs_milli        : unsigned (gps_time_millibits_c-1
                                          downto 0) is
                                    rtc_secs (gps_time_millibits_c-1
                                              downto 0) ;

  signal rtc_secs_carry       : std_logic ;
  signal rtc_week             : unsigned (gps_time_weekbits_c-1 downto 0) ;
  signal rtc_milli            : unsigned (gps_time_millibits_c downto 0) ;

  signal rtc_borrow           : std_logic ;
  signal rtc_gps_weekdiff     : unsigned (gps_time_weekbits_c-1 downto 0) ;
  signal rtc_gps_millidiff    : unsigned (gps_time_millibits_c-1 downto 0) ;

  signal gps_carry            : std_logic ;
  signal gps_weekdiff         : unsigned (gps_time_weekbits_c-1 downto 0) ;
  signal gps_millidiff        : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal gps_nanodiff         : unsigned (gps_time_nanobits_c-1 downto 0) ;

  signal gps_timerec          : GPS_Time ;

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

  signal fast_clk           : std_logic ;

  attribute keep                : boolean ;
  attribute keep of milli_clk   : signal is true ;
  attribute keep of fast_clk    : signal is true ;

begin

  startup_time              <= TO_GPS_TIME (startup_time_in) ;

  --  Future use values for extracting time information from GPS memory
  --  and using it to set the RTC clock from.  The GPS time is the startup
  --  time with addition of the difference between startup and GPS times
  --  determined from the GPS Timemark information.  Leap seconds are
  --  also obtained from the GPS.
  --  NOTE: GPS Memory access must run at a much higher rate than most other
  --        operations as the memory is shared with other modules and must
  --        be locked for as short a time as possible.

  gpsmem_req_out            <= '0' ;
  gpsmem_addr_out           <= (others => '0') ;
  gpsmem_readen_out         <= '0' ;
  gpsmem_clk_out            <= '0' ;

  --  Convert the last received RTC seconds into the difference between
  --  GPS Time and Startup Time.  Multiplying by 1000 is reduced to 3 adds
  --  by multiplying by 1024 (1 bit set) then subtracting the result of
  --  multiplying by 24 (2 bits set).

  rtc_loaded_low        <= TO_UNSIGNED (compile_timestamp_c,
                                        rtc_seconds'length) ;
  rtc_loaded_high       <= (others => '0') ;
  rtc_secs              <= rtc_loaded * 1024 - rtc_loaded * 24 ;

  rtc_secs_carry        <= '1'  when (rtc_secs_milli >= millisec_week_c) else
                           '0' ;

  rtc_week              <= rtc_secs_week  when (rtc_secs_carry = '0') else
                           rtc_secs_week + 1 ;
  rtc_milli             <= rtc_secs_milli when (rtc_secs_carry = '0') else
                           rtc_secs_milli - millisec_week_c ;

  --  Calculate the difference between the RTC Time and Startup Time at
  --  RTC load.

  rtc_borrow            <= '1'
                           when (unsigned (load_time.week_millisecond) >
                                 rtc_milli) else
                           '0' ;

  rtc_gps_weekdiff      <= rtc_week - unsigned (load_time.week_number)
                                when (rtc_borrow = '0') else
                           rtc_week - unsigned (load_time.week_number) - 1 ;
  rtc_gps_millidiff     <= rtc_milli - unsigned (load_time.week_millisecond)
                                when (rtc_borrow = '0') else
                           rtc_milli + millisec_week_c -
                           unsigned (load_time.week_millisecond) ;

  --  Use the most recently loaded time (RTC or GPS) to determine the
  --  difference to generated GPS time.

  gps_weekdiff          <= rtc_gps_weekdiff ;
  gps_millidiff         <= RESIZE (rtc_gps_millidiff, gps_millidiff'length) ;
  gps_nanodiff          <= (others => '0') ;

  --  Derive second counting clock from the GPS time.

  milli_clk             <= gps_timerec.week_millisecond (2) ;

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
      leap_seconds_in   => TO_UNSIGNED (26, 8),   -- as of July 2015
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

  --------------------------------------------------------------------------
  --  Add the difference between Startup Time and GPS time to the Startup
  --  Time to determine the GPS time.
  --------------------------------------------------------------------------

  gps_time_out              <= TO_STD_LOGIC_VECTOR (gps_timerec) ;

  fast_clk                  <= startup_time_in (8) ;

  gps_tm : process (fast_clk)
    variable nanosec_v      : unsigned (gps_time_nanobits_c downto 0) ;
    variable millisec_v     : unsigned (gps_time_millibits_c downto 0) ;
    variable week_carry_v   : std_logic ;
  begin
    nanosec_v                             :=
        RESIZE (unsigned (startup_time.millisecond_nanosecond) +
                gps_nanodiff, nanosec_v'length) ;
    millisec_v                            :=
        RESIZE (unsigned (startup_time.week_millisecond) +
                gps_millidiff, millisec_v'length) ;

    if (nanosec_v >= 1000000) then
      gps_timerec.millisecond_nanosecond  <=
            std_logic_vector (RESIZE (nanosec_v - 1000000,
                                      gps_time_nanobits_c)) ;

      if (millisec_v >= millisec_week_c - 1) then
        week_carry_v                      := '1' ;
        gps_timerec.week_millisecond      <=
            std_logic_vector (RESIZE (millisec_v - (millisec_week_c - 1),
                                      gps_time_millibits_c)) ;
      else
        week_carry_v                      := '0' ;
        gps_timerec.week_millisecond      <=
            std_logic_vector (RESIZE (millisec_v + 1,
                                      gps_time_millibits_c)) ;
      end if ;

    else
      gps_timerec.millisecond_nanosecond  <=
            std_logic_vector (RESIZE (nanosec_v, gps_time_nanobits_c)) ;

      if (millisec_v >= millisec_week_c) then
        week_carry_v                      := '1' ;
        gps_timerec.week_millisecond      <=
            std_logic_vector (RESIZE (millisec_v - millisec_week_c,
                                      gps_time_millibits_c)) ;
      else
        week_carry_v                      := '0' ;
        gps_timerec.week_millisecond      <=
            std_logic_vector (RESIZE (millisec_v, gps_time_millibits_c)) ;
      end if ;
    end if ;

    if (week_carry_v = '1') then
      gps_timerec.week_number             <=
            std_logic_vector (gps_weekdiff +
                              unsigned (startup_time.week_number) + 1) ;
    else
      gps_timerec.week_number             <=
            std_logic_vector (gps_weekdiff +
                              unsigned (startup_time.week_number)) ;
    end if ;
  end process gps_tm ;


end rtl ;
