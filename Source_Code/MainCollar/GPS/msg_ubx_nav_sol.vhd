--! msg_ubx_nav_sol Message Definitions.
--! Definitons for the msg_ubx_nav_sol message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl.ALL ;

package msg_ubx_nav_sol is

constant MSG_UBX_NAV_SOL_CLASS          : natural := 16#01# ;
constant MSG_UBX_NAV_SOL_ID             : natural := 16#06# ;
constant MSG_UBX_NAV_SOL_NUMBER         : natural := 0 ;

constant MSG_UBX_NAV_SOL_ROMADDR        : natural := 0 ;
constant MSG_UBX_NAV_SOL_RAMADDR        : natural := 0 * MSG_RAM_BANKS ;
constant MSG_UBX_NAV_SOL_RAMUSED        : natural := 30 ;
constant MSG_UBX_NAV_SOL_RAMBLOCK       : natural := 0 ;
constant MSG_UBX_NAV_SOL_FIELDCNT       : natural := 17 ;
constant MSG_UBX_NAV_SOL_FIELDBITS      : natural :=
            natural (trunc (log2 (real (MSG_UBX_NAV_SOL_FIELDCNT - 1)))) + 1 ;

--  Field Definitions.

constant MUNSol_iTOW_SIZE     : natural := 4 ;
constant MUNSol_iTOW_FIELD    : natural := 0 ;
constant MUNSol_iTOW_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_iTOW_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_iTOW_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_iTOW_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_iTOW_OFFSET   : natural := 0 ;

constant MUNSol_fTOW_SIZE     : natural := 4 ;
constant MUNSol_fTOW_FIELD    : natural := 1 ;
constant MUNSol_fTOW_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_fTOW_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_fTOW_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_fTOW_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_fTOW_OFFSET   : natural := 4 ;

constant MUNSol_week_SIZE     : natural := 2 ;
constant MUNSol_week_FIELD    : natural := 2 ;
constant MUNSol_week_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_week_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_week_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_week_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_week_OFFSET   : natural := 8 ;

constant MUNSol_gpsFix_SIZE   : natural := 1 ;
constant MUNSol_gpsFix_FIELD  : natural := 3 ;
constant MUNSol_gpsFix_ID     : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_gpsFix_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_gpsFix_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_gpsFix_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_gpsFix_OFFSET : natural := 10 ;

constant MUNSol_flags_SIZE    : natural := 1 ;
constant MUNSol_flags_FIELD   : natural := 4 ;
constant MUNSol_flags_ID      : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_flags_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_flags_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_flags_FIELD + 0, MSG_FIELD_BITS) ;

constant MUNSol_ecefX_SIZE    : natural := 4 ;
constant MUNSol_ecefX_FIELD   : natural := 5 ;
constant MUNSol_ecefX_ID      : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefX_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_ecefX_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefX_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_ecefX_OFFSET  : natural := 11 ;

constant MUNSol_ecefY_SIZE    : natural := 4 ;
constant MUNSol_ecefY_FIELD   : natural := 6 ;
constant MUNSol_ecefY_ID      : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefY_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_ecefY_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefY_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_ecefY_OFFSET  : natural := 15 ;

constant MUNSol_ecefZ_SIZE    : natural := 4 ;
constant MUNSol_ecefZ_FIELD   : natural := 7 ;
constant MUNSol_ecefZ_ID      : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefZ_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_ecefZ_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefZ_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_ecefZ_OFFSET  : natural := 19 ;

constant MUNSol_pAcc_SIZE     : natural := 4 ;
constant MUNSol_pAcc_FIELD    : natural := 8 ;
constant MUNSol_pAcc_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pAcc_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_pAcc_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pAcc_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_pAcc_OFFSET   : natural := 23 ;

constant MUNSol_ecefVX_SIZE   : natural := 4 ;
constant MUNSol_ecefVX_FIELD  : natural := 9 ;
constant MUNSol_ecefVX_ID     : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVX_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_ecefVX_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVX_FIELD + 0, MSG_FIELD_BITS) ;

constant MUNSol_ecefVY_SIZE   : natural := 4 ;
constant MUNSol_ecefVY_FIELD  : natural := 10 ;
constant MUNSol_ecefVY_ID     : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVY_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_ecefVY_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVY_FIELD + 0, MSG_FIELD_BITS) ;

constant MUNSol_ecefVZ_SIZE   : natural := 4 ;
constant MUNSol_ecefVZ_FIELD  : natural := 11 ;
constant MUNSol_ecefVZ_ID     : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVZ_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_ecefVZ_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_ecefVZ_FIELD + 0, MSG_FIELD_BITS) ;

constant MUNSol_sAcc_SIZE     : natural := 4 ;
constant MUNSol_sAcc_FIELD    : natural := 12 ;
constant MUNSol_sAcc_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_sAcc_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_sAcc_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_sAcc_FIELD + 0, MSG_FIELD_BITS) ;

constant MUNSol_pDOP_SIZE     : natural := 2 ;
constant MUNSol_pDOP_FIELD    : natural := 13 ;
constant MUNSol_pDOP_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pDOP_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_pDOP_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_pDOP_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_pDOP_OFFSET   : natural := 27 ;

constant MUNSol_res1_SIZE     : natural := 1 ;
constant MUNSol_res1_FIELD    : natural := 14 ;
constant MUNSol_res1_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res1_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_res1_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res1_FIELD + 0, MSG_FIELD_BITS) ;

constant MUNSol_numSV_SIZE    : natural := 1 ;
constant MUNSol_numSV_FIELD   : natural := 15 ;
constant MUNSol_numSV_ID      : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_numSV_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_numSV_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_numSV_FIELD + 0, MSG_FIELD_BITS) ;
constant MUNSol_numSV_OFFSET  : natural := 29 ;

constant MUNSol_res2_SIZE     : natural := 4 ;
constant MUNSol_res2_FIELD    : natural := 16 ;
constant MUNSol_res2_ID       : unsigned (MSG_UBX_NAV_SOL_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res2_FIELD, MSG_UBX_NAV_SOL_FIELDBITS) ;
constant MUNSol_res2_NUMBER   : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUNSol_res2_FIELD + 0, MSG_FIELD_BITS) ;

end package msg_ubx_nav_sol ;
