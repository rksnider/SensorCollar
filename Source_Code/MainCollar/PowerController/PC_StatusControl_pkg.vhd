----------------------------------------------------------------------------
--
--! @file       PC_StatusControl_pkg.vhd
--! @brief      Status and Control register signal placement.
--! @details    Constants used to place signals into the Status and Control
--!             registers that are communicated between the FPGA and
--!             Power Controller.
--! @author     Emery Newlon
--! @date       October 2014
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


package PC_StatusControl_pkg is

  --  Power Controller Status Register Definitions.
  --  The status register must be at least nine bits long in order to
  --  insure that the Flash Address register is initialized completely while
  --  the status register is being sent.

  type StatusSignals is (
    Stat_BatteryGood_e,
    Stat_SolarCtlOn_e,
    Stat_SolarCtlMax_e,
    Stat_BattMonLow_e,
    Stat_ForceStartup_e,
    Stat_PwrGood2p5_e,
    Stat_PwrGood3p3_e,
    Stat_Spacer1_e,
    Stat_Spacer2_e
  ) ;

  constant StatusSignalsCnt_c     : natural :=
      StatusSignals'pos(StatusSignals'high) + 1 ;

  --  Power Controller Control Register Definitions.

  type ControlSignals is (
    Ctl_MainPowerSwitch_e,
    Ctl_RechargeSwitch_e,
    Ctl_SolarCtlShutdown_e,
    Ctl_LevelShifter3p3_e,
    Ctl_LevelShifter1p8_e,
    Ctl_InertialOn1p8_e,
    Ctl_InertialOn2p5_e,
    Ctl_MicLeftOn_e,
    Ctl_MicRightOn_e,
    Ctl_SDRAM_On_e,
    Ctl_SDCardOn_e,
    Ctl_MagMemOn_e,
    Ctl_GPS_On_e,
    Ctl_DataTX_On_e,
    Ctl_FPGA_Shutdown_e
  ) ;

  constant ControlSignalsCnt_c    : natural :=
      ControlSignals'pos(ControlSignals'high) + 1 ;

end package PC_StatusControl_pkg ;
