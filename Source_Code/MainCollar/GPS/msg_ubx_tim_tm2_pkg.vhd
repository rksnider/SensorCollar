--! msg_ubx_tim_tm2 Message Definitions.
--! Definitons for the msg_ubx_tim_tm2 message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl_pkg.ALL ;

package msg_ubx_tim_tm2_pkg is

constant msg_ubx_tim_tm2_class_c        : natural := 16#0D# ;
constant msg_ubx_tim_tm2_id_c           : natural := 16#03# ;
constant msg_ubx_tim_tm2_number_c       : natural := 2 ;

constant msg_ubx_tim_tm2_romaddr_c      : natural := 27 ;
constant msg_ubx_tim_tm2_ramaddr_c      : natural := 30 * msg_ram_banks_c ;
constant msg_ubx_tim_tm2_ramused_c      : natural := 15 ;
constant msg_ubx_tim_tm2_ramblock_c     : natural := 1 ;
constant msg_ubx_tim_tm2_fieldcnt_c     : natural := 10 ;
constant msg_ubx_tim_tm2_fieldbits_c    : natural :=
            natural (trunc (log2 (real (msg_ubx_tim_tm2_fieldcnt_c - 1)))) + 1 ;

--  Field Definitions.

constant MUTTm2_ch_size_c     : natural := 1 ;
constant MUTTm2_ch_field_c    : natural := 0 ;
constant MUTTm2_ch_id_c       : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_ch_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_ch_number_c   : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_ch_field_c + 25, msg_field_bits_c) ;

constant MUTTm2_flags_size_c  : natural := 1 ;
constant MUTTm2_flags_field_c : natural := 1 ;
constant MUTTm2_flags_id_c    : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_flags_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_flags_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_flags_field_c + 25, msg_field_bits_c) ;
constant MUTTm2_flags_offset_c : natural := 0 ;

constant MUTTm2_count_size_c  : natural := 2 ;
constant MUTTm2_count_field_c : natural := 2 ;
constant MUTTm2_count_id_c    : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_count_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_count_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_count_field_c + 25, msg_field_bits_c) ;

constant MUTTm2_wnR_size_c    : natural := 2 ;
constant MUTTm2_wnR_field_c   : natural := 3 ;
constant MUTTm2_wnR_id_c      : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnR_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_wnR_number_c  : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnR_field_c + 25, msg_field_bits_c) ;

constant MUTTm2_wnF_size_c    : natural := 2 ;
constant MUTTm2_wnF_field_c   : natural := 4 ;
constant MUTTm2_wnF_id_c      : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnF_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_wnF_number_c  : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnF_field_c + 25, msg_field_bits_c) ;
constant MUTTm2_wnF_offset_c  : natural := 1 ;

constant MUTTm2_towMsR_size_c : natural := 4 ;
constant MUTTm2_towMsR_field_c : natural := 5 ;
constant MUTTm2_towMsR_id_c   : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsR_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_towMsR_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsR_field_c + 25, msg_field_bits_c) ;

constant MUTTm2_towSubMsR_size_c : natural := 4 ;
constant MUTTm2_towSubMsR_field_c : natural := 6 ;
constant MUTTm2_towSubMsR_id_c : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsR_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_towSubMsR_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsR_field_c + 25, msg_field_bits_c) ;

constant MUTTm2_towMsF_size_c : natural := 4 ;
constant MUTTm2_towMsF_field_c : natural := 7 ;
constant MUTTm2_towMsF_id_c   : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsF_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_towMsF_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsF_field_c + 25, msg_field_bits_c) ;
constant MUTTm2_towMsF_offset_c : natural := 3 ;

constant MUTTm2_towSubMsF_size_c : natural := 4 ;
constant MUTTm2_towSubMsF_field_c : natural := 8 ;
constant MUTTm2_towSubMsF_id_c : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsF_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_towSubMsF_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsF_field_c + 25, msg_field_bits_c) ;
constant MUTTm2_towSubMsF_offset_c : natural := 7 ;

constant MUTTm2_accEst_size_c : natural := 4 ;
constant MUTTm2_accEst_field_c : natural := 9 ;
constant MUTTm2_accEst_id_c   : unsigned (msg_ubx_tim_tm2_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_accEst_field_c, msg_ubx_tim_tm2_fieldbits_c) ;
constant MUTTm2_accEst_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_accEst_field_c + 25, msg_field_bits_c) ;
constant MUTTm2_accEst_offset_c : natural := 11 ;

end package msg_ubx_tim_tm2_pkg ;
