----------------------------------------------------------------------------
--
--! @file       Collar_Control_pkg.vhd
--! @brief      Acoustic Recording Collar Top Level component control.
--! @details    Settings in this file control what compenents are used by
--!             the collar.
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.

package Collar_Control_pkg is

  constant Collar_Control_useStrClk_c       : std_logic := '0' ;
  constant Collar_Control_useI2C_c          : std_logic := '0' ;
  constant Collar_Control_usePC_c           : std_logic := '1' ;
  constant Collar_Control_useSDRAM_c        : std_logic := '0' ;
  constant Collar_Control_useSD_c           : std_logic := '0' ;
  constant Collar_Control_useSDH_c          : std_logic := '0' ;
  constant Collar_Control_useGPS_c          : std_logic := '0' ;
  constant Collar_Control_useGPSRAM_c       : std_logic := '0' ;
  constant Collar_Control_useInertial_c     : std_logic := '0' ;
  constant Collar_Control_useMagMem_c       : std_logic := '0' ;
  constant Collar_Control_useMagMemBuffer_c : std_logic := '0' ;
  constant Collar_Control_usePDMmic_c       : std_logic := '0' ;
  constant Collar_Control_useRadio_c        : std_logic := '0' ;

end package Collar_Control_pkg ;
