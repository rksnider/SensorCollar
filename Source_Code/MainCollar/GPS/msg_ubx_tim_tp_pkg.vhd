--! msg_ubx_tim_tp Message Definitions.
--! Definitons for the msg_ubx_tim_tp message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl_pkg.ALL ;

package msg_ubx_tim_tp_pkg is

constant msg_ubx_tim_tp_class_c         : natural := 16#0D# ;
constant msg_ubx_tim_tp_id_c            : natural := 16#01# ;
constant msg_ubx_tim_tp_number_c        : natural := 3 ;

constant msg_ubx_tim_tp_romaddr_c       : natural := 38 ;
constant msg_ubx_tim_tp_ramused_c       : natural := 15 ;
constant msg_ubx_tim_tp_fieldcnt_c      : natural := 6 ;
constant msg_ubx_tim_tp_fieldbits_c     : natural :=
            natural (trunc (log2 (real (msg_ubx_tim_tp_fieldcnt_c - 1)))) + 1 ;

--  Field Definitions.

constant MUTTp_towMS_size_c   : natural := 4 ;
constant MUTTp_towMS_field_c  : natural := 0 ;
constant MUTTp_towMS_id_c     : unsigned (msg_ubx_tim_tp_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_towMS_field_c, msg_ubx_tim_tp_fieldbits_c) ;
constant MUTTp_towMS_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_towMS_field_c + 35, msg_field_bits_c) ;
constant MUTTp_towMS_offset_c : natural := 0 ;

constant MUTTp_towSubMS_size_c : natural := 4 ;
constant MUTTp_towSubMS_field_c : natural := 1 ;
constant MUTTp_towSubMS_id_c  : unsigned (msg_ubx_tim_tp_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_towSubMS_field_c, msg_ubx_tim_tp_fieldbits_c) ;
constant MUTTp_towSubMS_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_towSubMS_field_c + 35, msg_field_bits_c) ;
constant MUTTp_towSubMS_offset_c : natural := 4 ;

constant MUTTp_qErr_size_c    : natural := 4 ;
constant MUTTp_qErr_field_c   : natural := 2 ;
constant MUTTp_qErr_id_c      : unsigned (msg_ubx_tim_tp_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_qErr_field_c, msg_ubx_tim_tp_fieldbits_c) ;
constant MUTTp_qErr_number_c  : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_qErr_field_c + 35, msg_field_bits_c) ;
constant MUTTp_qErr_offset_c  : natural := 8 ;

constant MUTTp_week_size_c    : natural := 2 ;
constant MUTTp_week_field_c   : natural := 3 ;
constant MUTTp_week_id_c      : unsigned (msg_ubx_tim_tp_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_week_field_c, msg_ubx_tim_tp_fieldbits_c) ;
constant MUTTp_week_number_c  : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_week_field_c + 35, msg_field_bits_c) ;
constant MUTTp_week_offset_c  : natural := 12 ;

constant MUTTp_flags_size_c   : natural := 1 ;
constant MUTTp_flags_field_c  : natural := 4 ;
constant MUTTp_flags_id_c     : unsigned (msg_ubx_tim_tp_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_flags_field_c, msg_ubx_tim_tp_fieldbits_c) ;
constant MUTTp_flags_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_flags_field_c + 35, msg_field_bits_c) ;
constant MUTTp_flags_offset_c : natural := 14 ;

constant MUTTp_res1_size_c    : natural := 1 ;
constant MUTTp_res1_field_c   : natural := 5 ;
constant MUTTp_res1_id_c      : unsigned (msg_ubx_tim_tp_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_res1_field_c, msg_ubx_tim_tp_fieldbits_c) ;
constant MUTTp_res1_number_c  : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTp_res1_field_c + 35, msg_field_bits_c) ;

end package msg_ubx_tim_tp_pkg ;
