--! msg_ubx_nav_aopstatus Message Definitions.
--! Definitons for the msg_ubx_nav_aopstatus message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl_pkg.ALL ;

package msg_ubx_nav_aopstatus_pkg is

constant msg_ubx_nav_aopstatus_class_c    : natural := 16#01# ;
constant msg_ubx_nav_aopstatus_id_c       : natural := 16#60# ;
constant msg_ubx_nav_aopstatus_number_c   : natural := 1 ;

constant msg_ubx_nav_aopstatus_romaddr_c  : natural := 18 ;
constant msg_ubx_nav_aopstatus_ramused_c  : natural := 10 ;
constant msg_ubx_nav_aopstatus_fieldcnt_c : natural := 8 ;
constant msg_ubx_nav_aopstatus_fieldbits_c : natural :=
            natural (trunc (log2 (real (msg_ubx_nav_aopstatus_fieldcnt_c - 1)))) + 1 ;

--  Field Definitions.

constant MUNAOPstatus_iTOW_size_c : natural := 4 ;
constant MUNAOPstatus_iTOW_field_c : natural := 0 ;
constant MUNAOPstatus_iTOW_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_iTOW_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_iTOW_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_iTOW_field_c + 17, msg_field_bits_c) ;
constant MUNAOPstatus_iTOW_offset_c : natural := 0 ;

constant MUNAOPstatus_config_size_c : natural := 1 ;
constant MUNAOPstatus_config_field_c : natural := 1 ;
constant MUNAOPstatus_config_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_config_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_config_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_config_field_c + 17, msg_field_bits_c) ;
constant MUNAOPstatus_config_offset_c : natural := 4 ;

constant MUNAOPstatus_status_size_c : natural := 1 ;
constant MUNAOPstatus_status_field_c : natural := 2 ;
constant MUNAOPstatus_status_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_status_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_status_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_status_field_c + 17, msg_field_bits_c) ;
constant MUNAOPstatus_status_offset_c : natural := 5 ;

constant MUNAOPstatus_res0_size_c : natural := 1 ;
constant MUNAOPstatus_res0_field_c : natural := 3 ;
constant MUNAOPstatus_res0_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res0_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_res0_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res0_field_c + 17, msg_field_bits_c) ;

constant MUNAOPstatus_res1_size_c : natural := 1 ;
constant MUNAOPstatus_res1_field_c : natural := 4 ;
constant MUNAOPstatus_res1_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res1_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_res1_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res1_field_c + 17, msg_field_bits_c) ;

constant MUNAOPstatus_avail_size_c : natural := 4 ;
constant MUNAOPstatus_avail_field_c : natural := 5 ;
constant MUNAOPstatus_avail_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_avail_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_avail_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_avail_field_c + 17, msg_field_bits_c) ;
constant MUNAOPstatus_avail_offset_c : natural := 6 ;

constant MUNAOPstatus_res2_size_c : natural := 4 ;
constant MUNAOPstatus_res2_field_c : natural := 6 ;
constant MUNAOPstatus_res2_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res2_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_res2_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res2_field_c + 17, msg_field_bits_c) ;

constant MUNAOPstatus_res3_size_c : natural := 4 ;
constant MUNAOPstatus_res3_field_c : natural := 7 ;
constant MUNAOPstatus_res3_id_c : unsigned (msg_ubx_nav_aopstatus_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res3_field_c, msg_ubx_nav_aopstatus_fieldbits_c) ;
constant MUNAOPstatus_res3_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNAOPstatus_res3_field_c + 17, msg_field_bits_c) ;

end package msg_ubx_nav_aopstatus_pkg ;
