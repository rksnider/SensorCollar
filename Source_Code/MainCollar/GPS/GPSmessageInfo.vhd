------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      GPS message information not available from other packages.
--! @details    Information about GPS messages.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl.ALL ;

package GPSmessageInfo is

--  NAV Sol message information.

constant NAV_SOL_gpsFix_None      : unsigned (7 downto 0) := x"00" ;
constant NAV_SOL_gpsFix_DR        : unsigned (7 downto 0) := x"01" ;
constant NAV_SOL_gpsFix_2D        : unsigned (7 downto 0) := x"02" ;
constant NAV_SOL_gpsFix_3D        : unsigned (7 downto 0) := x"03" ;
constant NAV_SOL_gpsFix_GPSandDR  : unsigned (7 downto 0) := x"04" ;
constant NAV_SOL_gpsFix_TimeOnly  : unsigned (7 downto 0) := x"05" ;

constant NAV_SOL_flags_GPSfixOK   : unsigned (7 downto 0) := x"01" ;
constant NAV_SOL_flags_DiffSoln   : unsigned (7 downto 0) := x"02" ;
constant NAV_SOL_flags_WKNSET     : unsigned (7 downto 0) := x"04" ;
constant NAV_SOL_flags_TOWSET     : unsigned (7 downto 0) := x"08" ;

--  TIM TM2 message information.

constant TIM_TM2_flags_mode       : unsigned (7 downto 0) := x"01" ;
constant TIM_TM2_flags_run        : unsigned (7 downto 0) := x"02" ;
constant TIM_TM2_flags_newFall    : unsigned (7 downto 0) := x"04" ;
constant TIM_TM2_flags_timeBase   : unsigned (7 downto 0) := x"18" ;
constant TIM_TM2_flags_utc        : unsigned (7 downto 0) := x"20" ;
constant TIM_TM2_flags_time       : unsigned (7 downto 0) := x"40" ;
constant TIM_TM2_flags_newRise    : unsigned (7 downto 0) := x"80" ;

constant TIM_TM2_flags_TB_RCV     : unsigned (7 downto 0) := x"00" ;
constant TIM_TM2_flags_TB_GPS     : unsigned (7 downto 0) := x"08" ;
constant TIM_TM2_flags_TB_UTC     : unsigned (7 downto 0) := x"10" ;

constant TIM_TM2_flags_Check      : unsigned (7 downto 0) :=
            TIM_TM2_flags_timeBase or TIM_TM2_flags_utc or TIM_TM2_flags_time ;

constant TIM_TM2_flags_OK         : unsigned (7 downto 0) :=
            TIM_TM2_flags_TB_UTC or TIM_TM2_flags_utc or TIM_TM2_flags_time ;


end package GPSmessageInfo ;
