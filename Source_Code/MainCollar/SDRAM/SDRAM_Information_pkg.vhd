----------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Information about synchronous dynamic RAM.
--! @details    Data organized about synchronous dynamic RAM.
--! @author     Emery Newlon
--! @version    $Revision$
--
----------------------------------------------------------------------------

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.

package SDRAM_Information_pkg is

  --  Capacity data about specific synchronous dynamic RAM chips.

  type SDRAM_Capacity is record
    ROWBITS   : natural ;   --  Number of bits in a row.
    ROWCOUNT  : natural ;   --  Number of rows in a bank.
    BANKS     : natural ;   --  Number of banks in the chip.
    ADDRBITS  : natural ;   --  Number of address pins on the chip.
    DATABITS  : natural ;   --  Number of data bits on the chip.
    CMDBITS   : natural ;   --  Number of command bits on the chip.
  end record SDRAM_Capacity ;

  --  Timing data about specific synchronous dynamic RAM chips.  Timings are
  --  mostly minimum values unless MAX is specified in the comment.  When
  --  both minimum and maximum values are specified minimums will have the
  --  _L suffix added while maximums will have the _H suffix added.  Times
  --  are specified in seconds (1.0e-9 is a nanosecond) or as multiples of
  --  the clock cycle time (T_CK).

  type SDRAM_Timing is record
    CL        : natural ;   --  Column (CAS) Latency in clock cycles.  MAX
    T_AC      : real    ;   --  Access time from CLK (positive edge).
    T_AH      : real    ;   --  Address hold time.
    T_AS      : real    ;   --  Address setup time.
    T_CH      : real    ;   --  CLK high-level width.
    T_CL      : real    ;   --  CLK low-level width.
    T_CK      : real    ;   --  Clock cycle time.
    T_CKH     : real    ;   --  CKE hold time.
    T_CKS     : real    ;   --  CKE setup time.
    T_CMH     : real    ;   --  CS#, RAS#, CAS#, WE#, DQM hold time.
    T_CMS     : real    ;   --  CS#, RAS#, CAS#, WE#, DQM setup time.
    T_DH      : real    ;   --  Data-in hold time.
    T_DS      : real    ;   --  Data-in setup time.
    T_HZ      : real    ;   --  Data-out High-Z time.  MAX
    T_LZ      : real    ;   --  Data-out Low-Z time.
    T_OH      : real    ;   --  Data-out hold time (load).
    T_OHn     : real    ;   --  Data-out hold time (no load).
    T_RAS_L   : real    ;   --  ACTIVE-to-PRECHARGE command.
    T_RAS_H   : real    ;   --  ACTIVE-to-PRECHARGE command.  MAX
    T_RC      : real    ;   --  ACTIVE-to-ACTIVE command period.
    T_RCD     : real    ;   --  ACTIVE-to-READ or Write delay.
    T_REF     : real    ;   --  Refresh period (8192 rows).  MAX
    T_RFC     : real    ;   --  AUTO REFRESH period.
    T_RP      : real    ;   --  PRECHARGE command period.
    T_RRD     : natural ;   --  ACTIVE bank a to ACTIVE bank b command.
    T_T_L     : real    ;   --  Transition time.
    T_T_H     : real    ;   --  Transition time.  MAX
    T_WR      : real    ;   --  WRITE recovery time.
    T_XSR     : real    ;   --  Exit SELF REFRESH-to-ACTIVE command.
    T_BDL     : natural ;   --  Last data-in to burset STOP command.
    T_CCD     : natural ;   --  READ/WRITE command to READ/WRITE command.
    T_CDL     : natural ;   --  Last data-in to new READ/WRITE command.
    T_CKED    : natural ;   --  CKE to clock disable or power-down entry
                            --  mode.
    T_DAL     : natural ;   --  Data-in to ACTIVE command.
    T_DPL     : natural ;   --  Data-in to PRECHARGE command.
    T_DQD     : natural ;   --  DQM to input data delay.
    T_DQM     : natural ;   --  DQM to data mask during WRITEs.
    T_DQZ     : natural ;   --  DQM to data High-Z during READs.
    T_DWD     : natural ;   --  Write command to input data delay.
    T_MRD     : natural ;   --  LOAD MODE REGISTER command to ACTIVE or
                                  --  REFRESH command.
    T_PED     : natural ;   --  CKE to clock enable or power-down exit mode.
    T_RDL     : natural ;   --  Last data-in to PRECHARGE command.
    T_ROH     : natural ;   --  Data-out High-Z from PRECHARGE command.
  end record SDRAM_Timing ;

  --  LPSDR SDRAM 32 bit chip.

  constant SDRAM_32_Capacity  : SDRAM_Capacity :=
  (
    ROWBITS         => 16384,
    ROWCOUNT        => 8192,
    BANKS           => 4,
    ADDRBITS        => 14,
    DATABITS        => 32,
    CMDBITS         => 4
  ) ;

  --  LPSDR SDRAM 16 bit chip.

  constant SDRAM_16_Capacity  : SDRAM_Capacity :=
  (
    ROWBITS         => 16384,
    ROWCOUNT        => 8192,
    BANKS           => 4,
    ADDRBITS        => 14,
    DATABITS        => 16,
    CMDBITS         => 4
  ) ;

  --  LPSDR SDRAM 7.5ns CL = 2.

  constant SDRAM_75_2_Timing  : SDRAM_Timing :=
  (
    CL              => 2,
    T_AC            => 8.0e-9,
    T_AH            => 1.0e-9,
    T_AS            => 1.5e-9,
    T_CH            => 2.5e-9,
    T_CL            => 2.5e-9,
    T_CK            => 9.6e-9,
    T_CKH           => 1.0e-9,
    T_CKS           => 1.5e-9,
    T_CMH           => 1.0e-9,
    T_CMS           => 1.5e-9,
    T_DH            => 1.0e-9,
    T_DS            => 1.5e-9,
    T_HZ            => 8.0e-9,
    T_LZ            => 1.0e-9,
    T_OH            => 2.5e-9,
    T_OHn           => 1.8e-9,
    T_RAS_L         => 45.0e-9,
    T_RAS_H         => 120.0e-6,
    T_RC            => 67.5e-9,
    T_RCD           => 19.2e-9,
    T_REF           => 64.0e-3,
    T_RFC           => 72.0e-9,
    T_RP            => 19.2e-9,
    T_RRD           => 2,
    T_T_L           => 0.3e-9,
    T_T_H           => 1.2e-9,
    T_WR            => 15.0e-9,
    T_XSR           => 120.0e-9,
    T_BDL           => 1,
    T_CCD           => 1,
    T_CDL           => 1,
    T_CKED          => 1,
    T_DAL           => 5,
    T_DPL           => 0,
    T_DQD           => 2,
    T_DQM           => 0,
    T_DQZ           => 2,
    T_DWD           => 0,
    T_MRD           => 2,
    T_PED           => 1,
    T_RDL           => 2,
    T_ROH           => 2
  ) ;

  --  LPSDR SDRAM 7.5ns CL = 3.

  constant SDRAM_75_3_Timing  : SDRAM_Timing :=
  (
    CL              => 3,
    T_AC            => 5.4e-9,
    T_AH            => 1.0e-9,
    T_AS            => 1.5e-9,
    T_CH            => 2.5e-9,
    T_CL            => 2.5e-9,
    T_CK            => 7.5e-9,
    T_CKH           => 1.0e-9,
    T_CKS           => 1.5e-9,
    T_CMH           => 1.0e-9,
    T_CMS           => 1.5e-9,
    T_DH            => 1.0e-9,
    T_DS            => 1.5e-9,
    T_HZ            => 5.4e-9,
    T_LZ            => 1.0e-9,
    T_OH            => 2.5e-9,
    T_OHn           => 1.8e-9,
    T_RAS_L         => 45.0e-9,
    T_RAS_H         => 120.0e-6,
    T_RC            => 67.5e-9,
    T_RCD           => 19.2e-9,
    T_REF           => 64.0e-3,
    T_RFC           => 72.0e-9,
    T_RP            => 19.2e-9,
    T_RRD           => 2,
    T_T_L           => 0.3e-9,
    T_T_H           => 1.2e-9,
    T_WR            => 15.0e-9,
    T_XSR           => 120.0e-9,
    T_BDL           => 1,
    T_CCD           => 1,
    T_CDL           => 1,
    T_CKED          => 1,
    T_DAL           => 5,
    T_DPL           => 0,
    T_DQD           => 2,
    T_DQM           => 0,
    T_DQZ           => 2,
    T_DWD           => 0,
    T_MRD           => 2,
    T_PED           => 1,
    T_RDL           => 2,
    T_ROH           => 3
  ) ;

end package SDRAM_Information_pkg ;
