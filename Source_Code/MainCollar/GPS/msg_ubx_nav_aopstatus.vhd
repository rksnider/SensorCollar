--! msg_ubx_nav_aopstatus Message Definitions.
--! Definitons for the msg_ubx_nav_aopstatus message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl.ALL ;

package msg_ubx_nav_aopstatus is

constant MSG_UBX_NAV_AOPSTATUS_CLASS    : natural := 16#01# ;
constant MSG_UBX_NAV_AOPSTATUS_ID       : natural := 16#60# ;
constant MSG_UBX_NAV_AOPSTATUS_NUMBER   : natural := 1 ;

constant MSG_UBX_NAV_AOPSTATUS_ROMADDR  : natural := 18 ;
constant MSG_UBX_NAV_AOPSTATUS_RAMUSED  : natural := 10 ;
constant MSG_UBX_NAV_AOPSTATUS_FIELDCNT : natural := 8 ;
constant MSG_UBX_NAV_AOPSTATUS_FIELDBITS : natural :=
            natural (trunc (log2 (real (MSG_UBX_NAV_AOPSTATUS_FIELDCNT - 1)))) + 1 ;

--  Field Definitions.

constant MUNAOPstatus_iTOW_SIZE : natural := 4 ;
constant MUNAOPstatus_iTOW_FIELD : natural := 0 ;
constant MUNAOPstatus_iTOW_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_iTOW_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_iTOW_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_iTOW_FIELD + 17, MSG_FIELD_BITS) ;
constant MUNAOPstatus_iTOW_OFFSET : natural := 0 ;

constant MUNAOPstatus_config_SIZE : natural := 1 ;
constant MUNAOPstatus_config_FIELD : natural := 1 ;
constant MUNAOPstatus_config_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_config_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_config_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_config_FIELD + 17, MSG_FIELD_BITS) ;
constant MUNAOPstatus_config_OFFSET : natural := 4 ;

constant MUNAOPstatus_status_SIZE : natural := 1 ;
constant MUNAOPstatus_status_FIELD : natural := 2 ;
constant MUNAOPstatus_status_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_status_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_status_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_status_FIELD + 17, MSG_FIELD_BITS) ;
constant MUNAOPstatus_status_OFFSET : natural := 5 ;

constant MUNAOPstatus_res0_SIZE : natural := 1 ;
constant MUNAOPstatus_res0_FIELD : natural := 3 ;
constant MUNAOPstatus_res0_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res0_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_res0_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res0_FIELD + 17, MSG_FIELD_BITS) ;

constant MUNAOPstatus_res1_SIZE : natural := 1 ;
constant MUNAOPstatus_res1_FIELD : natural := 4 ;
constant MUNAOPstatus_res1_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res1_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_res1_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res1_FIELD + 17, MSG_FIELD_BITS) ;

constant MUNAOPstatus_avail_SIZE : natural := 4 ;
constant MUNAOPstatus_avail_FIELD : natural := 5 ;
constant MUNAOPstatus_avail_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_avail_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_avail_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_avail_FIELD + 17, MSG_FIELD_BITS) ;
constant MUNAOPstatus_avail_OFFSET : natural := 6 ;

constant MUNAOPstatus_res2_SIZE : natural := 4 ;
constant MUNAOPstatus_res2_FIELD : natural := 6 ;
constant MUNAOPstatus_res2_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res2_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_res2_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res2_FIELD + 17, MSG_FIELD_BITS) ;

constant MUNAOPstatus_res3_SIZE : natural := 4 ;
constant MUNAOPstatus_res3_FIELD : natural := 7 ;
constant MUNAOPstatus_res3_ID : unsigned (MSG_UBX_NAV_AOPSTATUS_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res3_FIELD, MSG_UBX_NAV_AOPSTATUS_FIELDBITS) ;
constant MUNAOPstatus_res3_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res3_FIELD + 17, MSG_FIELD_BITS) ;

end package msg_ubx_nav_aopstatus ;
