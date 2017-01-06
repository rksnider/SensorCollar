----------------------------------------------------------------------------
--
--! @file       SunriseSunset.vhd
--! @brief      Determine the time of the next sunrise and sunset.
--! @details    Sunrise and sunset are determined from encoded noon offset
--!             and sunrise offset information precalculated and stored in
--!             ROM.
--! @author     Emery Newlon
--! @date       September 2015
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

LIBRARY GENERAL ;                     --  Use General Purpose Libraries
USE GENERAL.UTILITIES_PKG.ALL ;       --  Use Utilities.
USE GENERAL.FORMATSECONDS_PKG.ALL ;   --  Use Second Formatting information.

LIBRARY WORK ;                        --  Use Local Libraries
USE WORK.COLLAR_PARAMETERS_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Determine sunrise and sunset times.
--! @details    Uses the longitude, timezone, and current time information
--!             to determine the next sunrise and sunset.
--!             NOTE:   This is an asynchronous entity.  It can take several
--!                     seconds for the results to be updated when a day
--!                     change takes place (midnight).  The results will be
--!                     inacturate on a DST change day before the DST change
--!                     takes place on that day.
--!
--! @param      location_code_g       Code indicating location this
--!                                   module is for.
--! @param      longitude_g           Longitude of current location.
--! @param      timezone_g            Seconds from GMT that this location's
--!                                   timezone is at in standard time.
--! @param      dst_offset_g          Number of seconds added to time when
--!                                   in Daylight Savings Time.
--! @param      reset                 Reset the module.
--! @param      clk                   Clock used for memory access.
--! @param      rtc_sec_in            Running time in RTC seconds.
--! @param      rtc_datetime_in       Running Local time in year-month-day
--!                                   hour-minute-second from RTC current
--!                                   value.
--! @param      alarm_time_out        Time to determine local noon of the
--!                                   current day in local time.
--! @param      alarm_time_in         Time of local noon in RTC seconds.
--! @param      dawn_today_out        Today's dawn time in RTC seconds.
--! @param      sunrise_today_out     Today's sunrise time in RTC seconds.
--! @param      sunset_today_out      Today's sunset time in RTC seconds.
--! @param      dusk_today_out        Today's dusk time in RTC seconds.
--! @param      dawn_tomorrow_out     Tomorrow's dawn time in RTC seconds.
--! @param      sunrise_tomorrow_out  Tomorrow's sunrise time in RTC
--!                                   seconds.
--! @param      sunset_tomorrow_out   Tomorrow's sunset time in RTC seconds.
--! @param      dusk_tomorrow_out     Tomorrow's dusk time in RTC seconds.
--
----------------------------------------------------------------------------

entity SunriseSunset is

  Generic (
    location_code_g       : natural :=  0 ;
    longitude_g           : real    := -111.0525791 ;
    timezone_g            : integer := -7 * 60 * 60 ;
    dst_offset_g          : integer := 60 * 60
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    rtc_sec_in            : in    unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_datetime_in       : in    std_logic_vector (dt_totalbits_c-1
                                                    downto 0) ;
    alarm_time_out        : out   std_logic_vector (dt_totalbits_c-1
                                                    downto 0) ;
    alarm_time_in         : in    unsigned (epoch70_secbits_c-1 downto 0) ;
    dawn_today_out        : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    sunrise_today_out     : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    sunset_today_out      : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    dusk_today_out        : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    dawn_tomorrow_out     : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    sunrise_tomorrow_out  : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    sunset_tomorrow_out   : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    dusk_tomorrow_out     : out   unsigned (epoch70_secbits_c-1 downto 0)
  ) ;

end entity SunriseSunset ;


architecture rtl of SunriseSunset is

  constant longitude_offset_c   : integer :=
      integer (real (timezone_g) -
               (longitude_g / 360.0) * 24.0 * 60.0 * 60.0) ;

  constant dawn_bits_c    : natural := 10 ;
  constant sunrise_bits_c : natural := 13 ;
  constant noon_bits_c    : natural :=  7 ;

  constant noon_end_c     : natural := 0 ;
  constant noon_str_c     : natural := noon_end_c + noon_bits_c - 1 ;
  constant sunrise_end_c  : natural := noon_str_c + 1 ;
  constant sunrise_str_c  : natural := sunrise_end_c + sunrise_bits_c - 1 ;
  constant dawn_end_c     : natural := sunrise_str_c + 1 ;
  constant dawn_str_c     : natural := dawn_end_c + dawn_bits_c - 1 ;

  constant day_bits_c     : natural := dawn_str_c + 1 ;

  COMPONENT sun_8Sx36W IS
    PORT
    (
      address_a           : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      address_b           : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      clock               : IN STD_LOGIC  := '1';
      q_a                 : OUT STD_LOGIC_VECTOR (day_bits_c-1 DOWNTO 0);
      q_b                 : OUT STD_LOGIC_VECTOR (day_bits_c-1 DOWNTO 0)
    );
  END COMPONENT sun_8Sx36W ;

  COMPONENT sun_46Nx111W IS
    PORT
    (
      address_a           : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      address_b           : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      clock               : IN STD_LOGIC  := '1';
      q_a                 : OUT STD_LOGIC_VECTOR (day_bits_c-1 DOWNTO 0);
      q_b                 : OUT STD_LOGIC_VECTOR (day_bits_c-1 DOWNTO 0)
    );
  END COMPONENT sun_46Nx111W ;

  signal datetime         : DateTime_t ;
  signal alarmtime        : DateTime_t ;

  --  Offsets for day of year for today and tomorrow.  The calculated noon,
  --  sunrise/sunset, and dawn/dusk offsets derived from these values.

  signal today              : std_logic_vector (day_bits_c-1 downto 0) ;
  signal dawn_today         : unsigned (dawn_bits_c-1    downto 0) ;
  signal sunrise_today      : unsigned (sunrise_bits_c-1 downto 0) ;
  signal noon_today         : unsigned (noon_bits_c-1    downto 0) ;

  signal today_noon         : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal sun_today          : unsigned (sunrise_today'length +
                                        const_bits (15) - 1 downto 0) ;
  signal twilight_today     : unsigned (sunrise_today'length +
                                        const_bits (15) downto 0) ;

  signal tomorrow           : std_logic_vector (day_bits_c-1 downto 0) ;
  signal dawn_tomorrow      : unsigned (dawn_bits_c-1    downto 0) ;
  signal sunrise_tomorrow   : unsigned (sunrise_bits_c-1 downto 0) ;
  signal noon_tomorrow      : unsigned (noon_bits_c-1    downto 0) ;

  signal tomorrow_noon      : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal sun_tomorrow       : unsigned (sunrise_tomorrow'length +
                                        const_bits (15) - 1 downto 0) ;
  signal twilight_tomorrow  : unsigned (sunrise_tomorrow'length +
                                        const_bits (15) downto 0) ;

begin

  --  Find local noon of the current day.

  datetime              <= TO_DATE_TIME (rtc_datetime_in) ;
  alarmtime.year        <= datetime.year ;
  alarmtime.lyear       <= '0' ;
  alarmtime.month       <= datetime.month ;
  alarmtime.mday        <= datetime.mday ;
  alarmtime.yday        <= (others => '0') ;
  alarmtime.indst       <= '0' ;
  alarmtime.hour        <= TO_UNSIGNED (12, dt_hourbits_c) ;
  alarmtime.minute      <= (others => '0') ;
  alarmtime.second      <= (others => '0') ;
  alarm_time_out        <= TO_STD_LOGIC_VECTOR (alarmtime) ;

  --  Determine the sunrise and noon offsets for the the current and
  --  next day.  Very slow as the clock is 0.5 Hz.
  --  The MIF file to use depends on the location.

  at_8Sx36W:
    if (location_code_g = CP_Loc_8Sx36W_c) generate
      sun: sun_8Sx36W
        PORT MAP
        (
          address_a   => std_logic_vector (datetime.yday),
          address_b   => std_logic_vector (datetime.yday + 1),
          clock       => clk,
          q_a         => today,
          q_b         => tomorrow
        ) ;
    end generate at_8Sx36W ;

  at_46Nx111W:
    if (location_code_g = CP_Loc_46N111W_c) generate
      sun: sun_46Nx111W
        PORT MAP
        (
          address_a   => std_logic_vector (datetime.yday),
          address_b   => std_logic_vector (datetime.yday + 1),
          clock       => clk,
          q_a         => today,
          q_b         => tomorrow
        ) ;
    end generate at_46Nx111W ;

  dawn_today        <= unsigned (today    (dawn_str_c    downto
                                           dawn_end_c)) ;
  sunrise_today     <= unsigned (today    (sunrise_str_c downto
                                           sunrise_end_c)) ;
  noon_today        <= unsigned (today    (noon_str_c    downto
                                           noon_end_c)) ;
  dawn_tomorrow     <= unsigned (tomorrow (dawn_str_c    downto
                                           dawn_end_c)) ;
  sunrise_tomorrow  <= unsigned (tomorrow (sunrise_str_c downto
                                           sunrise_end_c)) ;
  noon_tomorrow     <= unsigned (tomorrow (noon_str_c    downto
                                           noon_end_c)) ;

  --  Determine local noon today.  This is timezone noon today, plus the
  --  noon offset for this day of the year, plus the noon offset for
  --  the longitude.  The noon offset is in quarters of a minute and must
  --  be converted into seconds.  The local noon tomorrow is calculated
  --  in the same way using the next day's noon offset and adding one
  --  days worth of seconds.  (Noon offsets are biased by 18 minutes to
  --  prevent them from being negative numbers.)

  today_noon            <= alarm_time_in +
                           noon_today * const_unsigned (15) - 18 * 60 +
                           longitude_offset_c ;

  tomorrow_noon         <= alarm_time_in +
                           noon_tomorrow * const_unsigned (15) - 18 * 60 +
                           longitude_offset_c + 24 * 60 * 60 ;

  --  Determine the offset, from noon, for sunrise, sunset, dawn, and dusk.
  --  The offsets are in quarters of a minute and must be converted to
  --  seconds.

  twilight_today        <= RESIZE ((dawn_today + sunrise_today) *
                                   const_unsigned (15),
                                   twilight_today'length) ;
  sun_today             <= RESIZE (sunrise_today    * const_unsigned (15),
                                   sun_today'length) ;
  twilight_tomorrow     <= RESIZE ((dawn_tomorrow + sunrise_tomorrow) *
                                   const_unsigned (15),
                                   twilight_tomorrow'length) ;
  sun_tomorrow          <= RESIZE (sunrise_tomorrow * const_unsigned (15),
                                   sun_tomorrow'length) ;

  --  Produce the sunrise, sunset, dawn, and dusk times in Standard Time,
  --  subtracting off the Daylight Savings Time offset if needed.

  dawn_today_out        <= today_noon - twilight_today - dst_offset_g
                              when (datetime.indst = '1') else
                           today_noon - twilight_today ;
  sunrise_today_out     <= today_noon - sun_today - dst_offset_g
                              when (datetime.indst = '1') else
                           today_noon - sun_today ;
  sunset_today_out      <= today_noon + sun_today - dst_offset_g
                              when (datetime.indst = '1') else
                           today_noon + sun_today ;
  dusk_today_out        <= today_noon + twilight_today - dst_offset_g
                              when (datetime.indst = '1') else
                           today_noon + twilight_today ;

  dawn_tomorrow_out     <= tomorrow_noon - twilight_tomorrow - dst_offset_g
                              when (datetime.indst = '1') else
                           tomorrow_noon - twilight_tomorrow ;
  sunrise_tomorrow_out  <= tomorrow_noon - sun_tomorrow - dst_offset_g
                              when (datetime.indst = '1') else
                           tomorrow_noon - sun_tomorrow ;
  sunset_tomorrow_out   <= tomorrow_noon + sun_tomorrow - dst_offset_g
                              when (datetime.indst = '1') else
                           tomorrow_noon + sun_tomorrow ;
  dusk_tomorrow_out     <= tomorrow_noon + twilight_tomorrow - dst_offset_g
                              when (datetime.indst = '1') else
                           tomorrow_noon + twilight_tomorrow ;

end rtl ;
