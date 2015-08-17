----------------------------------------------------------------------------
--
--! @file       GPSmessageInfo_pkg.vhd
--! @brief      GPS message information not available from other packages.
--! @details    Information about GPS messages.
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


library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl_pkg.ALL ;

package GPSmessageInfo_pkg is

--  NAV Sol message information.

constant NAV_SOL_gpsFix_None_c      : unsigned (7 downto 0) := x"00" ;
constant NAV_SOL_gpsFix_DR_c        : unsigned (7 downto 0) := x"01" ;
constant NAV_SOL_gpsFix_2D_c        : unsigned (7 downto 0) := x"02" ;
constant NAV_SOL_gpsFix_3D_c        : unsigned (7 downto 0) := x"03" ;
constant NAV_SOL_gpsFix_GPSandDR_c  : unsigned (7 downto 0) := x"04" ;
constant NAV_SOL_gpsFix_TimeOnly_c  : unsigned (7 downto 0) := x"05" ;

constant NAV_SOL_flags_GPSfixOK_c   : unsigned (7 downto 0) := x"01" ;
constant NAV_SOL_flags_DiffSoln_c   : unsigned (7 downto 0) := x"02" ;
constant NAV_SOL_flags_WKNSET_c     : unsigned (7 downto 0) := x"04" ;
constant NAV_SOL_flags_TOWSET_c     : unsigned (7 downto 0) := x"08" ;

constant NAV_SOL_flags_OK_c         : unsigned (7 downto 0) :=
               NAV_SOL_flags_GPSfixOK_c
            or NAV_SOL_flags_WKNSET_c
            or NAV_SOL_flags_TOWSET_c ;

--  TIM TM2 message information.

constant TIM_TM2_flags_mode_c       : unsigned (7 downto 0) := x"01" ;
constant TIM_TM2_flags_run_c        : unsigned (7 downto 0) := x"02" ;
constant TIM_TM2_flags_newFall_c    : unsigned (7 downto 0) := x"04" ;
constant TIM_TM2_flags_timeBase_c   : unsigned (7 downto 0) := x"18" ;
constant TIM_TM2_flags_utc_c        : unsigned (7 downto 0) := x"20" ;
constant TIM_TM2_flags_time_c       : unsigned (7 downto 0) := x"40" ;
constant TIM_TM2_flags_newRise_c    : unsigned (7 downto 0) := x"80" ;

constant TIM_TM2_flags_TB_RCV_c     : unsigned (7 downto 0) := x"00" ;
constant TIM_TM2_flags_TB_GPS_c     : unsigned (7 downto 0) := x"08" ;
constant TIM_TM2_flags_TB_UTC_c     : unsigned (7 downto 0) := x"10" ;

constant TIM_TM2_flags_Check_c      : unsigned (7 downto 0) :=
               TIM_TM2_flags_timeBase_c
            or TIM_TM2_flags_utc_c
            or TIM_TM2_flags_time_c ;

constant TIM_TM2_flags_OK_c         : unsigned (7 downto 0) :=
               TIM_TM2_flags_TB_GPS_c
            or TIM_TM2_flags_utc_c
            or TIM_TM2_flags_time_c ;


end package GPSmessageInfo_pkg ;
