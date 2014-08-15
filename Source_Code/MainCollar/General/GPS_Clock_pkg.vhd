----------------------------------------------------------------------------
--
--! @file       GPS_Clock_pkg.vhd
--! @brief      GPS Time Definitions.
--! @details    Definitions used for GPS Clock times.
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

package GPS_Clock_pkg is

  --  Number of milliseconds in a week.

  constant millisec_week_c      : natural := 7 * 24 * 60 * 60 * 1000 ;

  --  GPS Clock Format.

  constant gps_time_weekbits_c  : natural := 16 ;
  constant gps_time_millibits_c : natural := 30 ;
  constant gps_time_nanobits_c  : natural := 20 ;

  constant gps_time_bits_c      : natural := gps_time_weekbits_c +
                                             gps_time_millibits_c +
                                             gps_time_nanobits_c ;

  constant gps_time_bytes_c     : natural :=
                natural ((gps_time_bits_c - 1) / 8) + 1 ;

  --  The week number is the number of the current week this time is for.
  --  The week millisecond is the number of milliseconds into the current
  --  week.
  --  The millisecond nanosecond is the number of nanoseconds into the
  --  current millisecond.

  type GPS_Time is record
     week_number            : std_logic_vector (gps_time_weekbits_c-1
                                                    downto 0) ;
     week_millisecond       : std_logic_vector (gps_time_millibits_c-1
                                                    downto 0) ;
     millisecond_nanosecond : std_logic_vector (gps_time_nanobits_c-1
                                                    downto 0) ;
  end record ;

  --  Concatinate the GPS Time fields into a bit vector.

  function TO_STD_LOGIC_VECTOR (a : in GPS_Time) return std_logic_vector ;

  --  Separate a bit vector into GPS Time fields.

  function TO_GPS_TIME (a : in std_logic_vector (gps_time_bits_c-1
                                                    downto 0))
  return GPS_Time ;

end package GPS_Clock_pkg ;

package body GPS_Clock_pkg is

  --  Concatinate the GPS Time fields into a bit vector.

  function TO_STD_LOGIC_VECTOR (a : in GPS_Time) return std_logic_vector is
    variable result_v : std_logic_vector (gps_time_bits_c-1 downto 0) ;
  begin
    result_v :=   a.week_number
                & a.week_millisecond
                & a.millisecond_nanosecond ;
    return result_v ;
  end ;

  --  Separate a bit vector into GPS Time fields.

  function TO_GPS_TIME (a : in std_logic_vector (gps_time_bits_c-1
                                                    downto 0))
  return GPS_Time is
    variable result_v : GPS_Time ;
  begin
    result_v.week_number            :=
        a (gps_time_bits_c-1 downto gps_time_bits_c-gps_time_weekbits_c) ;
    result_v.week_millisecond       :=
        a (gps_time_bits_c-gps_time_weekbits_c-1 downto
              gps_time_nanobits_c) ;
    result_v.millisecond_nanosecond :=
        a (gps_time_nanobits_c-1 downto 0) ;
    return result_v ;
  end ;


end package body GPS_Clock_pkg ;
