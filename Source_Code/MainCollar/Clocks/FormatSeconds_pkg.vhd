----------------------------------------------------------------------------
--
--! @file       FormatSeconds_pkg.vhd
--! @brief      Date/Time Format Definitions.
--! @details    Definitions used for converting Epoch 70 seconds (seconds
--!             since Jan 1, 1970 midnight GMT) to date/times.
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

library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;

package FormatSeconds_pkg is

  --  Epoch70 Seconds.  Seconds since Midnight Jan 1, 1970 in GMT not
  --  including leap seconds.

  constant epoch70_secbits_c    : natural := 32 ;

  --  Date/Time Format.  Year since 2000 (0-31), month of year (1-12),
  --  day of month (1-31), hour of day (0-23), minute of hour (0-59),
  --  second of minute (0-60 supports leap seconds).

  constant dt_yearbits_c        : natural := 5 ;
  constant dt_monthbits_c       : natural := 4 ;
  constant dt_mdaybits_c        : natural := 5 ;
  constant dt_hourbits_c        : natural := 5 ;
  constant dt_minbits_c         : natural := 6 ;
  constant dt_secbits_c         : natural := 6 ;

  constant dt_maxbits_c         : natural := 6 ;

  constant dt_totalbits_c       : natural := dt_yearbits_c    +
                                             dt_monthbits_c   +
                                             dt_mdaybits_c    +
                                             dt_hourbits_c    +
                                             dt_minbits_c     +
                                             dt_secbits_c     ;

  --  Date/Time struture.

  type DateTime_t is record
    year          : unsigned (dt_yearbits_c-1  downto 0) ;
    month         : unsigned (dt_monthbits_c-1 downto 0) ;
    mday          : unsigned (dt_mdaybits_c-1  downto 0) ;
    hour          : unsigned (dt_hourbits_c-1  downto 0) ;
    minute        : unsigned (dt_minbits_c-1   downto 0) ;
    second        : unsigned (dt_secbits_c-1   downto 0) ;
  end record ;

  --  Concatinate the Date/Time fields into a bit vector.

  function TO_STD_LOGIC_VECTOR (a : in DateTime_t)
  return std_logic_vector ;

  --  Separate a bit vector into Date/Time fields.

  function TO_DATE_TIME (a : in std_logic_vector (dt_totalbits_c-1
                                                  downto 0))
  return DateTime_t ;

end package FormatSeconds_pkg ;

package body FormatSeconds_pkg is

  --  Concatinate the Date/Time fields into a bit vector.

  function TO_STD_LOGIC_VECTOR (a : in DateTime_t)
  return std_logic_vector is
    variable result_v : std_logic_vector (dt_totalbits_c-1 downto 0) ;
  begin
    result_v :=   std_logic_vector (a.year)
                & std_logic_vector (a.month)
                & std_logic_vector (a.mday)
                & std_logic_vector (a.hour)
                & std_logic_vector (a.minute)
                & std_logic_vector (a.second) ;
    return result_v ;
  end ;

  --  Separate a bit vector into Date/Time fields.

  function TO_DATE_TIME (a : in std_logic_vector (dt_totalbits_c-1
                                                  downto 0))
  return DateTime_t is
    variable result_v : DateTime_t ;
    variable strbit_v : natural ;
    variable endbit_v : natural ;
  begin
    strbit_v        := dt_totalbits_c ;
    endbit_v        := strbit_v - dt_yearbits_c ;
    result_v.year   := unsigned (a (strbit_v-1 downto endbit_v)) ;
    strbit_v        := endbit_v ;
    endbit_v        := endbit_v - dt_monthbits_c ;
    result_v.month  := unsigned (a (strbit_v-1 downto endbit_v)) ;
    strbit_v        := endbit_v ;
    endbit_v        := endbit_v - dt_mdaybits_c ;
    result_v.mday   := unsigned (a (strbit_v-1 downto endbit_v)) ;
    strbit_v        := endbit_v ;
    endbit_v        := endbit_v - dt_hourbits_c ;
    result_v.hour   := unsigned (a (strbit_v-1 downto endbit_v)) ;
    strbit_v        := endbit_v ;
    endbit_v        := endbit_v - dt_minbits_c ;
    result_v.minute := unsigned (a (strbit_v-1 downto endbit_v)) ;
    strbit_v        := endbit_v ;
    endbit_v        := endbit_v - dt_secbits_c ;
    result_v.second := unsigned (a (strbit_v-1 downto endbit_v)) ;
    return result_v ;
  end ;


end package body FormatSeconds_pkg ;
