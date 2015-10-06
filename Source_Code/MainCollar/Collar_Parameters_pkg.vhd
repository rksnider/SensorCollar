----------------------------------------------------------------------------
--
--! @file       Collar_Parameters_pkg.vhd
--! @brief      Acoustic Recording Collar Top Level component parameters.
--! @details    Settings in this file provide information used by the
--!             collar and its instanciated components.
--! @author     Emery Newlon
--! @date       October 2015
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.MATH_REAL.ALL ;        --! Real numbers in constants.

package Collar_Parameters_pkg is

  --------------------------------------------------------------------------
  --  Location Information.
  --------------------------------------------------------------------------

  constant CP_Loc_Code_c    : natural := 0 ;  -- Bozeman, MT  USA

  constant CP_Loc_46N111W_c : natural := 0 ;  -- Bozeman, MT  USA
  constant CP_Loc_8Sx36W_c  : natural := 1 ;  -- Cabaceiras, Paraiba Brazil

  type CP_LocationInfo_t is record
    latitude                : real ;          -- In decimal degrees.
    longitude               : real ;          -- In decimal degrees.
    timezone                : integer ;       -- In seconds ahead of UTC.
    dst_change              : natural ;       -- Change amount in seconds.
    dst_start_month         : natural ;       -- Month DST starts.  (Jan=1)
    dst_start_mday          : natural ;       -- Earliest Month Day of DST.
    dst_start_hour          : natural ;       -- Starting time in day.
    dst_start_minute        : natural ;
    dst_start_second        : natural ;
    dst_end_month           : natural ;       -- Daylight Savings Time end.
    dst_end_mday            : natural ;
    dst_end_hour            : natural ;
    dst_end_minute          : natural ;
    dst_end_second          : natural ;
  end record ;

  --  Bozeman Montana USA Location Information.

  constant CP_Loc46Nx111W_info_c  : CP_LocationInfo_t :=
  (
    latitude                =>   45.6669502,
    longitude               => -111.0525791,
    timezone                =>   -7 * 60 * 60,
    dst_change              =>    1 * 60 * 60,
    dst_start_month         =>    1,
    dst_start_mday          =>    8,
    dst_start_hour          =>    2,
    dst_start_minute        =>    0,
    dst_start_second        =>    0,
    dst_end_month           =>   11,
    dst_end_mday            =>    1,
    dst_end_hour            =>    2,
    dst_end_minute          =>    0,
    dst_end_second          =>    0
  ) ;

  --  Cabaceiras Paraiba Brazil Location Information.

  constant CP_Loc8Sx36W_info_c    : CP_locationInfo_t :=
  (
    latitude                =>   -7.530341,
    longitude               =>  -36.296667,
    timezone                =>   -3 * 60 * 60,
    dst_change              =>    0 * 60 * 60,
    dst_start_month         =>   10,
    dst_start_mday          =>   15,
    dst_start_hour          =>    0,
    dst_start_minute        =>    0,
    dst_start_second        =>    0,
    dst_end_month           =>    2,
    dst_end_mday            =>   15,
    dst_end_hour            =>    0,
    dst_end_minute          =>    0,
    dst_end_second          =>    0
  ) ;

  --  All location information data indexed by their location codes.
  --  The place the information is put into the array MUST be indexed by
  --  the corresponding location code.

  type CP_LocationInfoArray_t is array (natural range <>) of
                                    CP_LocationInfo_t ;

  constant CP_LocationTbl_c       : CP_LocationInfoArray_t :=
  (
    CP_Loc46Nx111W_info_c,
    CP_Loc8Sx36W_info_c
  ) ;

  constant CP_CurrentLocation_c   : CP_LocationInfo_t :=
                CP_LocationTbl_c (CP_Loc_Code_c) ;

end package Collar_Parameters_pkg ;
