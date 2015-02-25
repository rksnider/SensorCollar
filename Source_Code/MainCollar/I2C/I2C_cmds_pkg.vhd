----------------------------------------------------------------------------
--
--! @file       I2C_cmds_pkg.vhd
--! @brief      I2C command and associated data definitions.
--! @details    This module defines a general I2C command structure stored
--!             in memory.
--! @author     Emery Newlon
--! @date       January 2015
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

library IEEE ;                      --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;       --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;          --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;            --! Real number functions.

library GENERAL ;                   --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


package I2C_cmds_pkg is

  constant I2C_cmddef_len     : natural := 11 ;
  constant I2C_cmddef_str     : natural := 0 ;
  constant I2C_cmdwr_str      : natural := 256 ;
  constant I2C_cmdrd_str      : natural := 512 ;

  --  Command defintions and there associated read and write data locations.
  --  Command definitions passed to the I2C_IO entity are constants named
  --    "*_cmdname_cmd".
  --  When the constant "*_cmdname_wrlen" is zero there is nothing that
  --  can be written for the command.  When this is not zero the location
  --  that should be written to starts at "*_cmdname_wr" plus
  --  "I2C_cmdwr_str".
  --  When the constant "*_cmdname_rdlen" is zero there is nothing that was
  --  read for the command.  When this is not zero the location where data
  --  can be read from starts at "*_cmdname_rd" plus "I2C_cmdrd_str".

  --  Battery Monitor Commands.

  constant I2C_BM_GetStatus_cmdno : natural := 0 ;
  constant I2C_BM_GetStatus_cmd   : natural := I2C_BM_GetStatus_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_GetStatus_wr    : natural := 0 ;
  constant I2C_BM_GetStatus_wrlen : natural := 0 ;
  constant I2C_BM_GetStatus_rd    : natural := 0 ;
  constant I2c_BM_GetStatus_rdlen : natural := 2 ;

  constant I2C_BM_GetFlags_cmdno  : natural := I2C_BM_GetStatus_cmdno + 1 ;
  constant I2C_BM_GetFlags_cmd    : natural := I2C_BM_GetFlags_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_GetFlags_wr     : natural := 0 ;
  constant I2C_BM_GetFlags_wrlen  : natural := 0 ;
  constant I2C_BM_GetFlags_rd     : natural := I2C_BM_GetStatus_rd +
                                               I2C_BM_GetStatus_rdlen ;
  constant I2C_BM_GetFlags_rdlen  : natural := 2 ;

  constant I2C_BM_Voltage_cmdno   : natural := I2C_BM_GetFlags_cmdno + 1 ;
  constant I2C_BM_Voltage_cmd     : natural := I2C_BM_Voltage_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_Voltage_wr      : natural := 0 ;
  constant I2C_BM_Voltage_wrlen   : natural := 0 ;
  constant I2C_BM_Voltage_rd      : natural := I2C_BM_GetFlags_rd +
                                               I2C_BM_GetFlags_rdlen ;
  constant I2C_BM_Voltage_rdlen   : natural := 2 ;

  constant I2C_BM_AvgCur_cmdno    : natural := I2C_BM_Voltage_cmdno + 1 ;
  constant I2C_BM_AvgCur_cmd      : natural := I2C_BM_AvgCur_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_AvgCur_wr       : natural := 0 ;
  constant I2C_BM_AvgCur_wrlen    : natural := 0 ;
  constant I2C_BM_AvgCur_rd       : natural := I2C_BM_Voltage_rd +
                                               I2C_BM_Voltage_rdlen ;
  constant I2C_BM_AvgCur_rdlen    : natural := 2 ;

  constant I2C_BM_ReadSOC_cmdno   : natural := I2C_BM_AvgCur_cmdno + 1 ;
  constant I2C_BM_ReadSOC_cmd     : natural := I2C_BM_ReadSoc_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_ReadSOC_wr      : natural := 0 ;
  constant I2C_BM_ReadSOC_wrlen   : natural := 0 ;
  constant I2C_BM_ReadSOC_rd      : natural := I2C_BM_AvgCur_rd +
                                               I2C_BM_AvgCur_rdlen ;
  constant I2C_BM_ReadSOC_rdlen   : natural := 2 ;

  constant I2C_BM_TmToEmpty_cmdno : natural := I2C_BM_ReadSOC_cmdno + 1 ;
  constant I2C_BM_TmToEmpty_cmd   : natural := I2C_BM_TmToEmpty_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_TmToEmpty_wr    : natural := 0 ;
  constant I2C_BM_TmToEmpty_wrlen : natural := 0 ;
  constant I2C_BM_TmToEmpty_rd    : natural := I2C_BM_ReadSOC_rd +
                                               I2C_BM_ReadSOC_rdlen ;
  constant I2C_BM_TmToEmpty_rdlen : natural := 2 ;

  constant I2C_BM_BattTemp_cmdno  : natural := I2C_BM_TmToEmpty_cmdno + 1 ;
  constant I2C_BM_BattTemp_cmd    : natural := I2C_BM_BattTemp_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_BattTemp_wr     : natural := 0 ;
  constant I2C_BM_BattTemp_wrlen  : natural := 0 ;
  constant I2C_BM_BattTemp_rd     : natural := I2C_BM_TmToEmpty_rd +
                                               I2C_BM_TmToEmpty_rdlen ;
  constant I2C_BM_BattTemp_rdlen  : natural := 2 ;

  constant I2C_BM_BattMTemp_cmdno : natural := I2C_BM_BattTemp_cmdno + 1 ;
  constant I2C_BM_BattMTemp_cmd   : natural := I2C_BM_BattMTemp_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_BattMTemp_wr    : natural := 0 ;
  constant I2C_BM_BattMTemp_wrlen : natural := 0 ;
  constant I2C_BM_BattMTemp_rd    : natural := I2C_BM_BattTemp_rd +
                                               I2C_BM_BattTemp_rdlen ;
  constant I2C_BM_BattMTemp_rdlen : natural := 2 ;

  constant I2C_BM_ManInfo_cmdno   : natural := I2C_BM_BattMTemp_cmdno + 1 ;
  constant I2C_BM_ManInfo_cmd     : natural := I2C_BM_ManInfo_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_BM_ManInfo_wr      : natural := 0 ;
  constant I2C_BM_ManInfo_wrlen   : natural := 0 ;
  constant I2C_BM_ManInfo_rd      : natural := I2C_BM_BattMTemp_rd +
                                               I2C_BM_BattMTemp_rdlen ;
  constant I2C_BM_ManInfo_rdlen   : natural := 32 ;

  --  Real Time Clock Commands.

  constant I2C_RTC_Init_cmdno     : natural := I2C_BM_ManInfo_cmdno + 1 ;
  constant I2C_RTC_Init_cmd       : natural := I2C_RTC_Init_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_RTC_Init_wr        : natural := 0 ;
  constant I2C_RTC_Init_wrlen     : natural := 0 ;
  constant I2C_RTC_Init_rd        : natural := I2C_BM_ManInfo_rd +
                                               I2C_BM_ManInfo_rdlen ;
  constant I2C_RCT_Init_rdlen     : natural := 0 ;

  constant I2C_RTC_SetTime_cmdno  : natural := I2C_RTC_Init_cmdno + 1 ;
  constant I2C_RTC_SetTime_cmd    : natural := I2C_RTC_SetTime_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_RTC_SetTime_wr     : natural := 18 ;
  constant I2C_RTC_SetTime_wrlen  : natural := 4 ;
  constant I2C_RTC_SetTime_rd     : natural := I2C_RTC_Init_rd +
                                               I2C_RTC_Init_rdlen ;
  constant I2C_RTC_SetTime_rdlen  : natural := 0 ;

  constant I2C_RTC_SetAlarm_cmdno : natural := I2C_RTC_SetTime_cmdno + 1 ;
  constant I2C_RTC_SetAlarm_cmd   : natural := I2C_RTC_SetAlarm_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_RTC_SetAlarm_wr    : natural := 23 ;
  constant I2C_RTC_SetAlarm_wrlen : natural := 3 ;
  constant I2C_RTC_SetAlarm_rd    : natural := I2C_RTC_SetTime_rd +
                                               I2C_RTC_SetTime_rdlen ;
  constant I2C_RTC_SetAlarm_rdlen : natural := 0 ;

  constant I2C_RTC_GetTime_cmdno  : natural := I2C_RTC_SetAlarm_cmdno + 1 ;
  constant I2C_RTC_GetTime_cmd    : natural := I2C_RTC_SetAlart_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_RTC_GetTime_wr     : natural := 0 ;
  constant I2C_RTC_GetTime_wrlen  : natural := 0 ;
  constant I2C_RTC_GetTime_rd     : natural := I2C_RTC_SetAlarm_rd +
                                               I2C_RTC_SetAlarm_rdlen ;
  constant I2C_RTC_GetTime_rdlen  : natural := 4 ;

  constant I2C_RTC_GetAlarm_cmdno : natural := I2C_RTC_GetTime_cmdno + 1 ;
  constant I2C_RTC_GetAlarm_cmd   : natural := I2C_RTC_GetAlarm_cmdno *
                                               I2C_cmddef_len ;
  constant I2C_RTC_GetAlarm_wr    : natural := 0 ;
  constant I2C_RTC_GetAlarm_wrlen : natural := 0 ;
  constant I2C_RTC_GetAlarm_rd    : natural := I2C_RTC_GetTime_rd +
                                               I2C_RTC_GetTime_rdlen ;
  constant I2C_RTC_GetAlarm_rdlen : natural := 3 ;


end package I2C_cmds_pkg ;
