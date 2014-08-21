--! GPS Message Control Definitions.
--! Definitions for the GPS messages.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

LIBRARY WORK ;
USE WORK.GPS_CLOCK.ALL ;

package gps_message_ctl is

--  Two banks of RAM allow there to always (except at
--  startup) be a valid set of message data.  If only
--  one bank is used it is marked as valid or not.

constant MSG_RAM_BANKS                  : natural := 2 ;

--  Memory block information.

constant MSG_COUNT                      : natural := 3 ;
constant MSG_COUNT_BITS                 : natural :=
      natural (trunc (log2 (real (MSG_COUNT)))) + 1 ;

constant MSG_ID_TBL                     : natural := 53 ;

constant MSG_ROM_BASE                   : natural := 0 ;
constant MSG_RAM_BASE                   : natural := 59 ;
constant MSG_RAM_BLOCKS                 : natural := 2 ;
constant MSG_RAM_TEMP_ADDR              : natural := 45 * MSG_RAM_BANKS ;
constant MSG_RAM_TEMP_SIZE              : natural := 30 ;

constant MSG_RAM_POSTIME_ADDR           : natural :=
      MSG_RAM_TEMP_ADDR + MSG_RAM_TEMP_SIZE * MSG_RAM_BANKS ;
constant MSG_RAM_POSTIME_SIZE           : natural := GPS_TIME_BYTES ;

constant MSG_RAM_MARKTIME_ADDR          : natural :=
      MSG_RAM_POSTIME_ADDR + MSG_RAM_POSTIME_SIZE * MSG_RAM_BANKS ;
constant MSG_RAM_MARKTIME_SIZE          : natural := GPS_TIME_BYTES ;

constant MSG_RAM_END                    : natural :=
      MSG_RAM_MARKTIME_ADDR + MSG_RAM_MARKTIME_SIZE ;

--  Field extraction information.

constant MSG_EXTRACT_TREE               : natural := 38 ;
constant MSG_TREE_OFFSET_BITS           : natural := 2 ;
constant MSG_EXTRACT_LOOKUP             : natural := 50 ;
constant MSG_EXTRACT_LOOKUP_BYTES       : natural := 1 ;
constant MSG_EXTRACT_OVERHEAD           : natural := 1 ;
constant MSG_FIELD_COUNT                : natural := 35 ;
constant MSG_FIELD_BITS                 : natural :=
      natural (trunc (log2 (real (MSG_FIELD_COUNT - 1)))) + 1 ;

--  Field encoder information.

constant MSG_SIZE_BITS                  : natural := 7 ;    -- High bits.
constant MSG_STORE_FLAG                 : natural := 1 ;    -- Low bit.

--  Message prototols.

constant MSG_UBX_SYNC_1                 : std_logic_vector (7 downto 0) := x"B5" ;
constant MSG_UBX_SYNC_2                 : std_logic_vector (7 downto 0) := x"62" ;

--  UBX protocol message classes.

constant MSG_UBX_NAV                    : std_logic_vector (7 downto 0) := x"01" ;
constant MSG_UBX_TIM                    : std_logic_vector (7 downto 0) := x"0D" ;

end package gps_message_ctl ;
