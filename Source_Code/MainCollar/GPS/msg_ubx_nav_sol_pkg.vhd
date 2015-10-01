--! msg_ubx_nav_sol Message Definitions.
--! Definitons for the msg_ubx_nav_sol message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl_pkg.ALL ;

package msg_ubx_nav_sol_pkg is

constant msg_ubx_nav_sol_class_c        : natural := 16#01# ;
constant msg_ubx_nav_sol_id_c           : natural := 16#06# ;
constant msg_ubx_nav_sol_number_c       : natural := 0 ;

constant msg_ubx_nav_sol_romaddr_c      : natural := 0 ;
constant msg_ubx_nav_sol_ramaddr_c      : natural := 0 * msg_ram_banks_c ;
constant msg_ubx_nav_sol_ramused_c      : natural := 30 ;
constant msg_ubx_nav_sol_ramblock_c     : natural := 0 ;
constant msg_ubx_nav_sol_fieldcnt_c     : natural := 17 ;
constant msg_ubx_nav_sol_fieldbits_c    : natural :=
            natural (trunc (log2 (real (msg_ubx_nav_sol_fieldcnt_c - 1)))) + 1 ;

--  Field Definitions.

constant MUNSol_iTOW_size_c   : natural := 4 ;
constant MUNSol_iTOW_field_c  : natural := 0 ;
constant MUNSol_iTOW_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_iTOW_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_iTOW_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_iTOW_field_c + 0, msg_field_bits_c) ;
constant MUNSol_iTOW_offset_c : natural := 0 ;

constant MUNSol_fTOW_size_c   : natural := 4 ;
constant MUNSol_fTOW_field_c  : natural := 1 ;
constant MUNSol_fTOW_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_fTOW_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_fTOW_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_fTOW_field_c + 0, msg_field_bits_c) ;
constant MUNSol_fTOW_offset_c : natural := 4 ;

constant MUNSol_week_size_c   : natural := 2 ;
constant MUNSol_week_field_c  : natural := 2 ;
constant MUNSol_week_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_week_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_week_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_week_field_c + 0, msg_field_bits_c) ;
constant MUNSol_week_offset_c : natural := 8 ;

constant MUNSol_gpsFix_size_c : natural := 1 ;
constant MUNSol_gpsFix_field_c : natural := 3 ;
constant MUNSol_gpsFix_id_c   : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_gpsFix_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_gpsFix_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_gpsFix_field_c + 0, msg_field_bits_c) ;
constant MUNSol_gpsFix_offset_c : natural := 10 ;

constant MUNSol_flags_size_c  : natural := 1 ;
constant MUNSol_flags_field_c : natural := 4 ;
constant MUNSol_flags_id_c    : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_flags_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_flags_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_flags_field_c + 0, msg_field_bits_c) ;

constant MUNSol_ecefX_size_c  : natural := 4 ;
constant MUNSol_ecefX_field_c : natural := 5 ;
constant MUNSol_ecefX_id_c    : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefX_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_ecefX_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefX_field_c + 0, msg_field_bits_c) ;
constant MUNSol_ecefX_offset_c : natural := 11 ;

constant MUNSol_ecefY_size_c  : natural := 4 ;
constant MUNSol_ecefY_field_c : natural := 6 ;
constant MUNSol_ecefY_id_c    : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefY_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_ecefY_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefY_field_c + 0, msg_field_bits_c) ;
constant MUNSol_ecefY_offset_c : natural := 15 ;

constant MUNSol_ecefZ_size_c  : natural := 4 ;
constant MUNSol_ecefZ_field_c : natural := 7 ;
constant MUNSol_ecefZ_id_c    : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefZ_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_ecefZ_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefZ_field_c + 0, msg_field_bits_c) ;
constant MUNSol_ecefZ_offset_c : natural := 19 ;

constant MUNSol_pAcc_size_c   : natural := 4 ;
constant MUNSol_pAcc_field_c  : natural := 8 ;
constant MUNSol_pAcc_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pAcc_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_pAcc_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pAcc_field_c + 0, msg_field_bits_c) ;
constant MUNSol_pAcc_offset_c : natural := 23 ;

constant MUNSol_ecefVX_size_c : natural := 4 ;
constant MUNSol_ecefVX_field_c : natural := 9 ;
constant MUNSol_ecefVX_id_c   : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVX_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_ecefVX_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVX_field_c + 0, msg_field_bits_c) ;

constant MUNSol_ecefVY_size_c : natural := 4 ;
constant MUNSol_ecefVY_field_c : natural := 10 ;
constant MUNSol_ecefVY_id_c   : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVY_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_ecefVY_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVY_field_c + 0, msg_field_bits_c) ;

constant MUNSol_ecefVZ_size_c : natural := 4 ;
constant MUNSol_ecefVZ_field_c : natural := 11 ;
constant MUNSol_ecefVZ_id_c   : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVZ_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_ecefVZ_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVZ_field_c + 0, msg_field_bits_c) ;

constant MUNSol_sAcc_size_c   : natural := 4 ;
constant MUNSol_sAcc_field_c  : natural := 12 ;
constant MUNSol_sAcc_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_sAcc_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_sAcc_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_sAcc_field_c + 0, msg_field_bits_c) ;

constant MUNSol_pDOP_size_c   : natural := 2 ;
constant MUNSol_pDOP_field_c  : natural := 13 ;
constant MUNSol_pDOP_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pDOP_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_pDOP_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pDOP_field_c + 0, msg_field_bits_c) ;
constant MUNSol_pDOP_offset_c : natural := 27 ;

constant MUNSol_res1_size_c   : natural := 1 ;
constant MUNSol_res1_field_c  : natural := 14 ;
constant MUNSol_res1_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res1_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_res1_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res1_field_c + 0, msg_field_bits_c) ;

constant MUNSol_numSV_size_c  : natural := 1 ;
constant MUNSol_numSV_field_c : natural := 15 ;
constant MUNSol_numSV_id_c    : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_numSV_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_numSV_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_numSV_field_c + 0, msg_field_bits_c) ;
constant MUNSol_numSV_offset_c : natural := 29 ;

constant MUNSol_res2_size_c   : natural := 4 ;
constant MUNSol_res2_field_c  : natural := 16 ;
constant MUNSol_res2_id_c     : unsigned (msg_ubx_nav_sol_fieldbits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res2_field_c, msg_ubx_nav_sol_fieldbits_c) ;
constant MUNSol_res2_number_c : unsigned (msg_field_bits_c-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res2_field_c + 0, msg_field_bits_c) ;

end package msg_ubx_nav_sol_pkg ;
