----------------------------------------------------------------------------
--
--! @file       FormatSeconds.vhd
--! @brief      Date/Time Format Conversions.
--! @details    Conversion processes used for converting Epoch 70 seconds
--!             (seconds since Jan 1, 1970 midnight GMT) to date/times.
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
USE GENERAL.FORMATSECONDS_PKG.ALL ;   --  Use Second Formatter information.

LIBRARY WORK ;
USE WORK.COMPILE_START_TIME_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Converts date/time values to and from Epoch 70 seconds.
--! @details    Convert Epoch 70 seconds (seconds since Jan 1 1970 midnight
--!             in GMT) to and from broken out year, month, month day,
--!             hour, minute, second values in a given timezone including
--!             daylight savings time.  Conversion to and from formatted
--!             date time can be done simultaniously using different clocks.
--!             The conversions will take less that 125 clock cycles.
--!             Epoch 70 seconds does not include leap seconds, time zone
--!             adjustments, or daylight savings time adjustements.
--!             Broken out time is local time.  It does contain leap second
--!             adjustments, time zone adjustments, and daylight savings
--!             time adjustments.
--!
--! @param      timezone_g        Number of seconds east of the prime
--!                               meridinan.  (MST = 7 hours)
--! @param      use_dst_g         Daylight Savings Time (DST) is used.
--! @param      dst_start_mth_g   Month DST starts in.  (March)
--! @param      dst_start_day_g   Earliest day DST can start on.  (Second
--!                               Sunday non-leap year)
--! @param      dst_start_hr_g    Hour into day DST starts at.  (2:00 AM)
--! @param      dst_start_min_g   Minutes into day DST starts.
--! @param      dst_end_mth_g     Month DST ends in.  (November)
--! @param      dst_end_day_g     Earliest day DST can end on.  (First
--!                               Sunday non-leap year)
--! @param      dst_end_hr_g      Hour into day DST ends at.  (2:00 AM)
--! @param      dst_end_min_g     Minutes into day DST ends.
--! @param      dst_seconds_g     Number of seconds to add when DST starts.
--! @param      reset             Reset the module.
--! @param      leap_seconds_in   Number of leap seconds since start of the
--!                               Epoch.
--! @param      epoch70_in        The seconds to convert to date/time
--!                               format not including leap seconds.
--! @param      datetime_out      The converted value as a bit vector.
--! @param      to_datetime_clk   Clock used to convert the value.
--! @param      to_dt_start_in    Rising edge starts the conversion.
--! @param      to_dt_done_out    Rising edge signals conversion done.
--! @param      datetime_in       Formatted date/time to convert to seconds.
--! @param      epoch70_out       Converted result not including leap
--!                               seconds.
--! @param      from_datetime_clk Clock used to convert the value.
--! @param      from_dt_start_in  Rising edge starts the conversion.
--! @param      from_dt_done_out  Rising edge signals conversion done.
--
----------------------------------------------------------------------------

entity FormatSeconds is
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

end entity FormatSeconds ;


architecture rtl of FormatSeconds is

  --  Conversion signals and registers.

  signal to_seconds         : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal to_datetime        : DateTime_t ;
  signal to_dt_start_fwl    : std_logic ;
  signal to_dt_calc         : std_logic ;

  signal from_seconds       : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal from_datetime      : DateTime_t ;
  signal from_dt_start_fwl  : std_logic ;
  signal from_dt_calc       : std_logic ;

  --  Time period in seconds between years, months, days, hours and minutes.

  constant day_sec_c        : natural := 24 * 60 * 60 ;

  constant time_diff_tbl_c  : integer_vector :=
  (
    --  Years, leap year then 3 non-leap years.

    366 * day_sec_c,
    365 * day_sec_c,
    365 * day_sec_c,
    365 * day_sec_c,

    --  Days of months.  Two sets.  The first for non-leap years the second
    --  for leap years.

    31 * day_sec_c,
    28 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,

    31 * day_sec_c,
    29 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,
    30 * day_sec_c,
    31 * day_sec_c,

    --  Days of month.

    day_sec_c,

    --  Hours of day.

    60 * 60,

    --  Minutes of hour.  Minutes are divided into 15 4 minute sections then
    --  4 one minute sections to used few clock cycles to count them.

    60 * 4,
    60

  ) ;

  constant year_times_start_c     : natural := 0 ;
  constant month_times_start_c    : natural := year_times_start_c    +  4 ;
  constant leap_times_start_c     : natural := month_times_start_c   + 12 ;
  constant day_times_start_c      : natural := leap_times_start_c    + 12 ;
  constant hour_times_start_c     : natural := day_times_start_c     +  1 ;
  constant fourmin_times_start_c  : natural := hour_times_start_c    +  1 ;
  constant minute_times_start_c   : natural := fourmin_times_start_c +  1 ;
  constant second_times_start_c   : natural := minute_times_start_c  +  1 ;

  signal to_time_diff_index       :
            unsigned (const_bits (time_diff_tbl_c'length)-1 downto 0) ;
  signal from_time_diff_index     :
            unsigned (const_bits (time_diff_tbl_c'length)-1 downto 0) ;

  --  Base year is 2012.  It is a leap year.  This year is 42 years since
  --  the start of the epoch in 1970.

  constant start_2012_c           : integer := (42 * 365 + 10) * day_sec_c ;

  --  Daylight saving time data.  Months and days start at one which must be
  --  removed.

  constant normyear_month_days_tbl_c : integer_vector :=
  (
    0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334
  ) ;

  constant leapyear_month_days_tbl_c : integer_vector :=
  (
    0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335
  ) ;

  constant dst_start_day_2012_c : natural := dst_start_day_g + 3 ;
  constant dst_end_day_2012_c   : natural := dst_end_day_g   + 3 ;

  constant dst_start_2012_c     : natural :=
              leapyear_month_days_tbl_c (dst_start_mth_g) +
              dst_start_day_2012_c - 1 ;
  constant dst_end_2012_c       : natural :=
              leapyear_month_days_tbl_c (dst_end_mth_g) +
              dst_end_day_2012_c - 1 ;

  constant dst_start_low_c      : natural :=
              normyear_month_days_tbl_c (dst_start_mth_g) +
              dst_start_day_g - 1 ;
  constant dst_end_low_c        : natural :=
              normyear_month_days_tbl_c (dst_end_mth_g) +
              dst_end_day_g - 1 ;

  signal to_dst_start           : unsigned (const_bits (366 * day_sec_c)-1
                                            downto 0) ;
  signal to_dst_end             : unsigned (const_bits (366 * day_sec_c)-1
                                            downto 0) ;

  signal from_dst_start         : unsigned (const_bits (33)-1 downto 0) ;
  signal from_dst_end           : unsigned (const_bits (33)-1 downto 0) ;

  --  Count of time periods.

  signal to_counter             : unsigned (dt_maxbits_c-1 downto 0) ;
  signal from_counter           : unsigned (dt_maxbits_c-1 downto 0) ;

  signal to_leap_year           : std_logic ;
  signal from_leap_year         : std_logic ;

  --  Conversion state machines.

  type DateTimeStates_t is
  (
    dtst_year_0_e,
    dtst_year_1_e,
    dtst_year_2_e,
    dtst_year_3_e,
    dtst_month_e,
    dtst_monthcnt_e,
    dtst_mday_e,
    dtst_hour_e,
    dtst_fourmin_e,
    dtst_minute_e,
    dtst_second_e,
    dtst_done_e,
    dtst_samediff_e
  ) ;

  signal to_cur_state       : DateTimeStates_t ;
  signal to_next_state      : DateTimeStates_t ;
  signal from_cur_state     : DateTimeStates_t ;
  signal from_next_state    : DateTimeStates_t ;

begin

  --------------------------------------------------------------------------
  --  Convert the Epoch70 seconds to Date/Time format.
  --------------------------------------------------------------------------

  to_dt : process (reset, to_datetime_clk)
    variable time_sec_size_v  : unsigned (const_bits (366 * day_sec_c)-1
                                          downto 0) ;
    variable cur_state_v      : DateTimeStates_t ;
  begin
    if (reset = '1') then
      datetime_out            <= (others => '0') ;
      to_dt_done_out          <= '0' ;
      to_dt_calc              <= '0' ;

    elsif (rising_edge (to_datetime_clk)) then

      --  Start the conversion.

      if (to_dt_start_fwl /= to_dt_start_in) then
        to_dt_start_fwl   <= to_dt_start_in ;

        if (to_dt_start_in = '1') then
          to_dt_done_out      <= '0' ;
          to_dt_calc          <= '1' ;

          to_time_diff_index  <= (others => '0') ;

          --  Start counting from the beginning of 2012.

          to_seconds          <= epoch70_in + leap_seconds_in -
                                 const_unsigned (start_2012_c -
                                                 timezone_g) ;

          to_counter          <= TO_UNSIGNED (12, to_counter'length) ;
          to_dst_start        <= TO_UNSIGNED (dst_start_2012_c *
                                              day_sec_c        +
                                              dst_start_hr_g   * 60 * 60 +
                                              dst_start_min_g  * 60,
                                              to_dst_start'length) ;
          to_dst_end          <= TO_UNSIGNED (dst_end_2012_c * day_sec_c +
                                              dst_end_hr_g   * 60 * 60 +
                                              dst_end_min_g  * 60,
                                              to_dst_end'length) ;
          to_leap_year        <= '1' ;

          to_cur_state        <= dtst_year_0_e ;
          to_next_state       <= dtst_month_e ;
        end if ;

      --  Continue with the conversion.

      elsif (to_dt_calc = '1') then

        --  Comparisons and subtractions are done outside of the state
        --  machine in order that fewer are needed, saving resources.

        time_sec_size_v       :=
            TO_UNSIGNED (time_diff_tbl_c (TO_INTEGER (to_time_diff_index)),
                         time_sec_size_v'length) ;

        if (to_seconds < time_sec_size_v) then
          cur_state_v         := to_next_state ;
          to_cur_state        <= cur_state_v ;
        else
          cur_state_v         := to_cur_state ;

          to_seconds          <= to_seconds - time_sec_size_v ;
          to_time_diff_index  <= to_time_diff_index + 1 ;
          to_counter          <= to_counter + 1 ;

          --  Adjust the daylight savings time start and end times by one
          --  day for regular years ([365 modulo 7] = 1) and two days for
          --  leap years ([366 modulo 7] = 2).  The DST start and end times
          --  are changed for all time segments but only have meaning for
          --  (and are used with) years.

          if (to_leap_year = '1') then
            if (to_dst_start < (dst_start_low_c + 2) * day_sec_c) then
              to_dst_start    <= TO_UNSIGNED ((dst_start_low_c + 6) *
                                              day_sec_c,
                                              to_dst_start'length) ;
            else
              to_dst_start    <= to_dst_start - (2 * day_sec_c) ;
            end if ;

            if (to_dst_end < (dst_end_low_c + 2) * day_sec_c) then
              to_dst_end      <= TO_UNSIGNED ((dst_end_low_c + 6) *
                                              day_sec_c,
                                              to_dst_end'length) ;
            else
              to_dst_end      <= to_dst_end - (2 * day_sec_c) ;
            end if ;
          else
            if (to_dst_start < (dst_start_low_c + 1) * day_sec_c ) then
              to_dst_start    <= TO_UNSIGNED ((dst_start_low_c + 6) *
                                              day_sec_c,
                                              to_dst_start'length) ;
            else
              to_dst_start    <= to_dst_start - (1 * day_sec_c) ;
            end if ;

            if (to_dst_end < (dst_end_low_c + 1) * day_sec_c) then
              to_dst_end      <= TO_UNSIGNED ((dst_end_low_c + 6) *
                                              day_sec_c,
                                              to_dst_end'length) ;
            else
              to_dst_end      <= to_dst_end - (1 * day_sec_c) ;
            end if ;
          end if ;
        end if ;

        --  Break the time into year, month, month day, hour, minute, and
        --  seconds.

        case (cur_state_v) is

          --  Count years from one leap year to the next.

          when dtst_year_0_e        =>
            to_leap_year        <= '0' ;
            to_cur_state        <= dtst_year_1_e ;

          when dtst_year_1_e        =>
            to_cur_state        <= dtst_year_2_e ;

          when dtst_year_2_e        =>
            to_cur_state        <= dtst_year_3_e ;

          when dtst_year_3_e        =>
            to_time_diff_index  <= (others => '0') ;
            to_leap_year        <= '1' ;
            to_cur_state        <= dtst_year_0_e ;

          --  Count months.

          when dtst_month_e         =>
            to_datetime.year    <= RESIZE (to_counter, dt_yearbits_c) ;
            to_counter          <= TO_UNSIGNED (1, to_counter'length) ;

            --  Adjust for daylight savings time in the northern
            --  hemisphere (starts and ends in the same year) and southern
            --  hemisphere (starts in one year and ends in the next).

            if (use_dst_g = '1') then
              if ((dst_start_mth_g < dst_end_mth_g      and
                   (to_seconds    >= to_dst_start   and
                    to_seconds    <= to_dst_end))           or
                  (dst_start_mth_g > dst_end_mth_g      and
                   (to_seconds    >= to_dst_start   or
                    to_seconds    <= to_dst_end))) then

                to_seconds        <= to_seconds + dst_seconds_g ;
              end if ;
            end if ;

            --  Used days/month from normal or leap year table section.

            if (to_leap_year = '0') then
              to_time_diff_index <=
                        TO_UNSIGNED (month_times_start_c,
                                     to_time_diff_index'length) ;
            else
              to_time_diff_index <=
                        TO_UNSIGNED (leap_times_start_c,
                                     to_time_diff_index'length) ;
            end if ;

            to_next_state       <= dtst_mday_e ;
            to_cur_state        <= dtst_monthcnt_e ;

          when dtst_monthcnt_e      =>

          --  Count days in the current month.

          when dtst_mday_e          =>
            to_datetime.month   <= RESIZE (to_counter, dt_monthbits_c) ;
            to_counter          <= TO_UNSIGNED (1, to_counter'length) ;
            to_time_diff_index  <=
                TO_UNSIGNED (day_times_start_c,
                             to_time_diff_index'length) ;
            to_next_state       <= dtst_hour_e ;
            to_cur_state        <= dtst_samediff_e ;

          --  Count hours in the current day.

          when dtst_hour_e          =>
            to_datetime.mday    <= RESIZE (to_counter, dt_mdaybits_c) ;
            to_counter          <= TO_UNSIGNED (0, to_counter'length) ;
            to_time_diff_index  <=
                TO_UNSIGNED (hour_times_start_c,
                             to_time_diff_index'length) ;
            to_next_state       <= dtst_fourmin_e ;
            to_cur_state        <= dtst_samediff_e ;

          --  Count four minute sections in the current hour.

          when dtst_fourmin_e       =>
            to_datetime.hour    <= RESIZE (to_counter, dt_hourbits_c) ;
            to_counter          <= TO_UNSIGNED (0, to_counter'length) ;
            to_time_diff_index  <=
                TO_UNSIGNED (fourmin_times_start_c,
                             to_time_diff_index'length) ;
            to_next_state       <= dtst_minute_e ;
            to_cur_state        <= dtst_samediff_e ;

          --  Count minutes in the current hour.

          when dtst_minute_e        =>
            to_counter          <= RESIZE (to_counter * 4,
                                           to_counter'length) ;
            to_time_diff_index  <=
                TO_UNSIGNED (minute_times_start_c,
                             to_time_diff_index'length) ;
            to_next_state       <= dtst_second_e ;
            to_cur_state        <= dtst_samediff_e ;

          --  Store the remaining seconds.

          when dtst_second_e        =>
            to_datetime.minute  <= RESIZE (to_counter, dt_minbits_c) ;
            to_datetime.second  <= RESIZE (to_seconds, dt_secbits_c) ;
            to_cur_state        <= dtst_done_e ;
            to_next_state       <= dtst_done_e ;

          --  Transfer the formatted time out and end.

          when dtst_done_e          =>
            datetime_out        <= TO_STD_LOGIC_VECTOR (to_datetime) ;
            to_dt_calc          <= '0' ;
            to_dt_done_out      <= '1' ;

          --  Time difference does not change between days, hours, and
          --  minutes.

          when dtst_samediff_e      =>
            to_time_diff_index  <= to_time_diff_index ;

        end case ;
      end if ;
    end if ;
  end process to_dt ;


  --------------------------------------------------------------------------
  --  Convert the Date/Time format to Epoch70 seconds.
  --------------------------------------------------------------------------

  from_dt : process (reset, from_datetime_clk)
    variable datetime_v         : DateTime_t ;
    variable time_sec_size_v    : unsigned (const_bits (366 * day_sec_c)-1
                                             downto 0) ;
    variable dst_start_passed_v : boolean ;
    variable dst_end_passed_v   : boolean ;
    variable cur_state_v      : DateTimeStates_t ;
  begin
    if (reset = '1') then
      epoch70_out               <= (others => '0') ;
      from_dt_done_out          <= '0' ;
      from_dt_calc              <= '0' ;

    elsif (rising_edge (from_datetime_clk)) then

      --  Start the conversion.

      if (from_dt_start_fwl /= from_dt_start_in) then
        from_dt_start_fwl   <= from_dt_start_in ;

        if (from_dt_start_in = '1') then
          from_dt_done_out      <= '0' ;
          from_dt_calc          <= '1' ;

          from_time_diff_index  <= (others => '0') ;

          --  Start counting from the beginning of 2012.

          datetime_v            := TO_DATE_TIME (datetime_in) ;
          from_datetime         <= datetime_v ;

          from_seconds          <= const_unsigned (start_2012_c -
                                                   timezone_g) -
                                   RESIZE (leap_seconds_in,
                                           from_seconds'length) ;

          from_counter          <= RESIZE (datetime_v.year - 12,
                                           from_counter'length) ;
          from_dst_start        <= TO_UNSIGNED (dst_start_day_2012_c,
                                                from_dst_start'length) ;
          from_dst_end          <= TO_UNSIGNED (dst_end_day_2012_c,
                                                from_dst_end'length) ;
          from_leap_year        <= '1' ;

          from_cur_state        <= dtst_year_0_e ;
          from_next_state       <= dtst_month_e ;
        end if ;

      --  Continue with the conversion.

      elsif (from_dt_calc = '1') then

        --  Comparisons and subtractions are done outside of the state
        --  machine in order that fewer are needed, saving resources.

        time_sec_size_v       :=
            TO_UNSIGNED (time_diff_tbl_c (TO_INTEGER (from_time_diff_index)),
                         time_sec_size_v'length) ;

        if (from_counter = 0) then
          cur_state_v           := from_next_state ;
          from_cur_state        <= cur_state_v ;
        else
          cur_state_v           := from_cur_state ;

          from_seconds          <= from_seconds + time_sec_size_v ;
          from_time_diff_index  <= from_time_diff_index + 1 ;
          from_counter          <= from_counter - 1 ;

          --  Adjust the daylight savings time start and end times by one
          --  day for regular years ([365 modulo 7] = 1) and two days for
          --  leap years ([366 modulo 7] = 2).  The DST start and end times
          --  are changed for all time segments but only have meaning for
          --  (and are used with) years.

          if (from_leap_year = '1') then
            if (from_dst_start < dst_start_low_c + 2) then
              from_dst_start    <= TO_UNSIGNED (dst_start_low_c + 6,
                                                from_dst_start'length) ;
            else
              from_dst_start    <= from_dst_start - 2 ;
            end if ;

            if (from_dst_end < dst_end_low_c + 2) then
              from_dst_end      <= TO_UNSIGNED (dst_end_low_c + 6,
                                                from_dst_end'length) ;
            else
              from_dst_end      <= from_dst_end - 2 ;
            end if ;
          else
            if (from_dst_start < dst_start_low_c + 1) then
              from_dst_start    <= TO_UNSIGNED (dst_start_low_c + 6,
                                                from_dst_start'length) ;
            else
              from_dst_start    <= from_dst_start - 1 ;
            end if ;

            if (from_dst_end < dst_end_low_c + 1) then
              from_dst_end      <= TO_UNSIGNED (dst_end_low_c + 6,
                                                from_dst_end'length) ;
            else
              from_dst_end      <= from_dst_end - 1 ;
            end if ;
          end if ;
        end if ;

        --  Combine the time from year, month, month day, hour, minute,
        --  and seconds into seconds since Jan 1, 1970 Midnight GMT.

        case (cur_state_v) is

          --  Count years from one leap year to the next.

          when dtst_year_0_e        =>
            from_leap_year        <= '0' ;
            from_cur_state        <= dtst_year_1_e ;

          when dtst_year_1_e        =>
            from_cur_state        <= dtst_year_2_e ;

          when dtst_year_2_e        =>
            from_cur_state        <= dtst_year_3_e ;

          when dtst_year_3_e        =>
            from_time_diff_index  <= (others => '0') ;
            from_leap_year        <= '1' ;
            from_cur_state        <= dtst_year_0_e ;

          --  Count months.

          when dtst_month_e         =>
            from_counter          <= RESIZE (from_datetime.month - 1,
                                             from_counter'length) ;

            --  Adjust for daylight savings time in the northern
            --  hemisphere (starts and ends in the same year) and southern
            --  hemisphere (starts in one year and ends in the next).

            if (use_dst_g = '1') then
              dst_start_passed_v  :=
                    (from_datetime.month          > dst_start_mth_g   or
                     (from_datetime.month         = dst_start_mth_g and
                      (from_datetime.mday         > from_dst_start    or
                       (from_datetime.mday        = from_dst_start  and
                        (from_datetime.hour       > dst_start_hr_g    or
                         (from_datetime.hour      = dst_start_hr_g  and
                          from_datetime.minute   >= dst_start_min_g)))))) ;

              dst_end_passed_v    :=
                    (from_datetime.month          > dst_end_mth_g     or
                     (from_datetime.month         = dst_end_mth_g   and
                      (from_datetime.mday         > from_dst_end      or
                       (from_datetime.mday        = from_dst_end    and
                        (from_datetime.hour       > dst_end_hr_g      or
                         (from_datetime.hour      = dst_end_hr_g    and
                          from_datetime.minute   >= dst_end_min_g)))))) ;

              if ((dst_start_mth_g    < dst_end_mth_g             and
                   (dst_start_passed_v and not dst_end_passed_v))   or
                  (dst_start_mth_g    > dst_end_mth_g             and
                   (dst_start_passed_v or  not dst_end_passed_v))) then

                from_seconds        <= from_seconds - dst_seconds_g ;
              end if ;
            end if ;

            --  Used days/month from normal or leap year table section.

            if (from_leap_year = '0') then
              from_time_diff_index <=
                        TO_UNSIGNED (month_times_start_c,
                                     from_time_diff_index'length) ;
            else
              from_time_diff_index <=
                        TO_UNSIGNED (leap_times_start_c,
                                     from_time_diff_index'length) ;
            end if ;

            from_next_state       <= dtst_mday_e ;
            from_cur_state        <= dtst_monthcnt_e ;

          when dtst_monthcnt_e      =>

          --  Count days in the current month.

          when dtst_mday_e          =>
            from_counter          <= RESIZE (from_datetime.mday - 1,
                                             from_counter'length) ;
            from_time_diff_index  <=
                      TO_UNSIGNED (day_times_start_c,
                                   from_time_diff_index'length) ;
            from_next_state       <= dtst_hour_e ;
            from_cur_state        <= dtst_samediff_e ;

          --  Count hours in the current day.

          when dtst_hour_e          =>
            from_counter          <= RESIZE (from_datetime.hour,
                                             from_counter'length) ;
            from_time_diff_index  <=
                      TO_UNSIGNED (hour_times_start_c,
                                   from_time_diff_index'length) ;
            from_next_state       <= dtst_fourmin_e ;
            from_cur_state        <= dtst_samediff_e ;

          --  Count four minute sections in the current hour.

          when dtst_fourmin_e       =>
            from_counter          <=
                      SHIFT_RIGHT (from_datetime.minute, 2) ;
            from_time_diff_index  <=
                      TO_UNSIGNED (fourmin_times_start_c,
                                   from_time_diff_index'length) ;
            from_next_state       <= dtst_minute_e ;
            from_cur_state        <= dtst_samediff_e ;

          --  Count minutes in the current hour.

          when dtst_minute_e        =>
            from_counter          <= RESIZE (from_datetime.minute and
                                             TO_UNSIGNED (2 ** 2 - 1,
                                                          dt_minbits_c),
                                             from_counter'length);
            from_time_diff_index  <=
                      TO_UNSIGNED (minute_times_start_c,
                                   from_time_diff_index'length) ;
            from_next_state       <= dtst_second_e ;
            from_cur_state        <= dtst_samediff_e ;

          --  Add the remaining seconds and finnish.

          when dtst_second_e        =>
            epoch70_out           <= from_seconds + from_datetime.second ;
            from_dt_calc          <= '0' ;
            from_dt_done_out      <= '1' ;

          when dtst_done_e          =>

          --  Time difference does not change between days, hours, and
          --  minutes.

          when dtst_samediff_e      =>
            from_time_diff_index  <= from_time_diff_index ;

        end case ;
      end if ;
    end if ;
  end process from_dt ;

end rtl ;
