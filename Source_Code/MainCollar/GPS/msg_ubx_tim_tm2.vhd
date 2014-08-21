--! msg_ubx_tim_tm2 Message Definitions.
--! Definitons for the msg_ubx_tim_tm2 message and its fields.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library WORK ;
use WORK.gps_message_ctl.ALL ;

package msg_ubx_tim_tm2 is

constant MSG_UBX_TIM_TM2_CLASS          : natural := 16#0D# ;
constant MSG_UBX_TIM_TM2_ID             : natural := 16#03# ;
constant MSG_UBX_TIM_TM2_NUMBER         : natural := 2 ;

constant MSG_UBX_TIM_TM2_ROMADDR        : natural := 27 ;
constant MSG_UBX_TIM_TM2_RAMADDR        : natural := 30 * MSG_RAM_BANKS ;
constant MSG_UBX_TIM_TM2_RAMUSED        : natural := 15 ;
constant MSG_UBX_TIM_TM2_RAMBLOCK       : natural := 1 ;
constant MSG_UBX_TIM_TM2_FIELDCNT       : natural := 10 ;
constant MSG_UBX_TIM_TM2_FIELDBITS      : natural :=
            natural (trunc (log2 (real (MSG_UBX_TIM_TM2_FIELDCNT - 1)))) + 1 ;

--  Field Definitions.

constant MUTTm2_ch_SIZE       : natural := 1 ;
constant MUTTm2_ch_FIELD      : natural := 0 ;
constant MUTTm2_ch_ID         : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_ch_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_ch_NUMBER     : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_ch_FIELD + 25, MSG_FIELD_BITS) ;

constant MUTTm2_flags_SIZE    : natural := 1 ;
constant MUTTm2_flags_FIELD   : natural := 1 ;
constant MUTTm2_flags_ID      : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_flags_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_flags_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_flags_FIELD + 25, MSG_FIELD_BITS) ;
constant MUTTm2_flags_OFFSET  : natural := 0 ;

constant MUTTm2_count_SIZE    : natural := 2 ;
constant MUTTm2_count_FIELD   : natural := 2 ;
constant MUTTm2_count_ID      : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_count_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_count_NUMBER  : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_count_FIELD + 25, MSG_FIELD_BITS) ;

constant MUTTm2_wnR_SIZE      : natural := 2 ;
constant MUTTm2_wnR_FIELD     : natural := 3 ;
constant MUTTm2_wnR_ID        : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnR_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_wnR_NUMBER    : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnR_FIELD + 25, MSG_FIELD_BITS) ;

constant MUTTm2_wnF_SIZE      : natural := 2 ;
constant MUTTm2_wnF_FIELD     : natural := 4 ;
constant MUTTm2_wnF_ID        : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnF_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_wnF_NUMBER    : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_wnF_FIELD + 25, MSG_FIELD_BITS) ;
constant MUTTm2_wnF_OFFSET    : natural := 1 ;

constant MUTTm2_towMsR_SIZE   : natural := 4 ;
constant MUTTm2_towMsR_FIELD  : natural := 5 ;
constant MUTTm2_towMsR_ID     : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsR_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_towMsR_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsR_FIELD + 25, MSG_FIELD_BITS) ;

constant MUTTm2_towSubMsR_SIZE : natural := 4 ;
constant MUTTm2_towSubMsR_FIELD : natural := 6 ;
constant MUTTm2_towSubMsR_ID  : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsR_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_towSubMsR_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsR_FIELD + 25, MSG_FIELD_BITS) ;

constant MUTTm2_towMsF_SIZE   : natural := 4 ;
constant MUTTm2_towMsF_FIELD  : natural := 7 ;
constant MUTTm2_towMsF_ID     : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsF_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_towMsF_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towMsF_FIELD + 25, MSG_FIELD_BITS) ;
constant MUTTm2_towMsF_OFFSET : natural := 3 ;

constant MUTTm2_towSubMsF_SIZE : natural := 4 ;
constant MUTTm2_towSubMsF_FIELD : natural := 8 ;
constant MUTTm2_towSubMsF_ID  : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsF_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_towSubMsF_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_towSubMsF_FIELD + 25, MSG_FIELD_BITS) ;
constant MUTTm2_towSubMsF_OFFSET : natural := 7 ;

constant MUTTm2_accEst_SIZE   : natural := 4 ;
constant MUTTm2_accEst_FIELD  : natural := 9 ;
constant MUTTm2_accEst_ID     : unsigned (MSG_UBX_TIM_TM2_FIELDBITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_accEst_FIELD, MSG_UBX_TIM_TM2_FIELDBITS) ;
constant MUTTm2_accEst_NUMBER : unsigned (MSG_FIELD_BITS-1 downto 0) :=
      TO_UNSIGNED (MUTTm2_accEst_FIELD + 25, MSG_FIELD_BITS) ;
constant MUTTm2_accEst_OFFSET : natural := 11 ;

end package msg_ubx_tim_tm2 ;
