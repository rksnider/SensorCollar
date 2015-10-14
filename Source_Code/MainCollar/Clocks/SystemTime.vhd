----------------------------------------------------------------------------
--
--! @file       SystemTime.vhd
--! @brief      Maintains the main time clocks.
--! @details    Maintains time in the system from the RTC, the GPS, and
--!             others.
--! @author     Emery Newlon
--! @date       August 2015
--! @copyright  Copyright (C) 2015 Ross K. Snider and Emery L. Newlon
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


library IEEE ;                        --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;         --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;            --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;              --  Real number functions.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;

LIBRARY GENERAL ;                     --  Use General Purpose Libraries
USE GENERAL.UTILITIES_PKG.ALL ;       --  General Utilities.
USE GENERAL.GPS_CLOCK_PKG.ALL ;       --  Use GPS Clock information.
USE GENERAL.FORMATSECONDS_PKG.ALL ;   --  Use Second Formatting information.

LIBRARY WORK ;
USE WORK.COMPILE_START_TIME_PKG.ALL ;
USE WORK.GPS_MESSAGE_CTL_PKG.ALL ;  --  Use GPS Message information.
USE WORK.MSG_UBX_TIM_TM2_PKG.ALL ;  --  Navagation Solution message.


----------------------------------------------------------------------------
--
--! @brief      Maintains the main Time clocks.
--! @details    Maintains:
--!               Startup Time in GPS Time format,
--!               GPS Time in GPS Time format,
--!               Real Time Clock (RTC) in seconds since Jan 1, 1970.
--!               Local Time in Year, Month, Day of Month, Hour, Minute,
--!               and Second.  This is adjusted for time zone and daylight
--!               savings time.
--!             The GPS Time can be derived from the GPS or from the
--!             Real Time Clock.  The local date and time are derived from
--!             the Real Time Clock.  The RTC alarm can be determined here
--!             as well.
--!
--! @param      clk_freq_g          Frequency of the clock in Hertz.
--! @param      gpsmem_addrbits_g   Number of address bits to read GPS mem.
--! @param      gpsmem_databits_g   Number of data bits returned by GPS mem.
--! @param      timezone_g          Number of seconds east of the prime
--!                                 meridinan.  (MST = 7 hours)
--! @param      dst_start_mth_g     Month DST starts in.  (March)
--! @param      dst_start_day_g     Earliest day DST can start on.  (Second
--!                                 Sunday non-leap year)
--! @param      dst_start_hr_g      Hour into day DST starts at.  (2:00 AM)
--! @param      dst_start_min_g     Minutes into day DST starts.
--! @param      dst_end_mth_g       Month DST ends in.  (November)
--! @param      dst_end_day_g       Earliest day DST can end on.  (First
--!                                 Sunday non-leap year)
--! @param      dst_end_hr_g        Hour into day DST ends at.  (2:00 AM)
--! @param      dst_end_min_g       Minutes into day DST ends.
--! @param      dst_seconds_g       Number of seconds to add when DST
--!                                 starts.  Zero value means no DST used.
--! @param      reset               Reset the module.
--! @param      startup_time_out    Running time in GPS time format since
--!                                 the system started.  This value is
--!                                 continuously updated and does not jump.
--! @param      startup_bytes_out   Running time since system started in
--!                                 bytes.
--! @param      gps_time_out        Running GPS time in GPS time format
--!                                 calculated from Timemark info stored in
--!                                 GPS mem or Real Time Clock info read
--!                                 from the RTC.  Note that this value can
--!                                 jump as new information is obtained from
--!                                 the GPS.
--! @param      gps_bytes_out       The running GPS time in bytes.
--! @param      rtc_sec_in          RTC time in seconds to load into GPS
--!                                 time.
--! @param      rtc_sec_load_in     Load the new RTC seconds into the GPS
--!                                 time.
--! @param      rtc_sec_out         Running RTC time in seconds.
--!                                 Note that this value can jump as new
--!                                 information is obtained from the GPS.
--! @param      rtc_sec_set_out     RTC seconds have been set from a source.
--! @param      rtc_datetime_out    Running Local time in year-month-day
--!                                 hour-minute-second from RTC current
--!                                 value.
--! @param      time_latch_out      Latches time startup, gps, or rtc time
--!                                 after a long path across the chip.
--! @param      time_valid_out      Latched time is valid.
--! @param      valid_latch_out     Latches the last latched time when it is
--!                                 valid for use when next time is not yet
--!                                 valid.
--! @param      gpsmem_tmbank_in    Most recent valid Timemark bank in
--!                                 GPS memory.  Changes to it triggers
--!                                 update of the GPS Time and RTC Time
--!                                 outputs.
--! @param      gpsmem_req_out      Request for access to GPS mem.
--! @param      gpsmem_rcv_in       Access granted to GPS mem.
--! @param      gpsmem_addr_out     Address to read from in GPS mem.
--! @param      gpsmem_datafrom_in  Data read from GPS mem.
--! @param      gpsmem_readen_out   Start a read from GPS mem.
--! @param      alarm_time_in       Time to set the RTC alarm in local time.
--! @param      alarm_time_out      Time to set the RTC alarm in RTC
--!                                 seconds.  The difference between this
--!                                 and the rtc_sec_out is the amount to
--!                                 set the countdown alarm to.
--
----------------------------------------------------------------------------

entity SystemTime is

  Generic (
    clk_freq_g          : natural := 50e3 ;
    gpsmem_addrbits_g   : natural := 10 ;
    gpsmem_databits_g   : natural :=  8 ;
    timezone_g          : integer := -7 * 60 * 60 ;
    dst_start_mth_g     : natural :=  3 ;
    dst_start_day_g     : natural :=  8 ;
    dst_start_hr_g      : natural :=  2 ;
    dst_start_min_g     : natural :=  0 ;
    dst_end_mth_g       : natural := 11 ;
    dst_end_day_g       : natural :=  1 ;
    dst_end_hr_g        : natural :=  2 ;
    dst_end_min_g       : natural :=  0 ;
    dst_seconds_g       : natural := 60 * 60
  ) ;
  Port (
    reset               : in    std_logic ;
    clk                 : in    std_logic ;
    startup_time_out    : out   std_logic_vector (gps_time_bits_c-1
                                                  downto 0) ;
    startup_bytes_out   : out   std_logic_vector (gps_time_bytes_c*8-1
                                                  downto 0) ;
    gps_time_out        : out   std_logic_vector (gps_time_bits_c-1
                                                  downto 0) ;
    gps_bytes_out       : out   std_logic_vector (gps_time_bytes_c*8-1
                                                  downto 0) ;

    rtc_sec_in          : in    unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_sec_load_in     : in    std_logic ;
    rtc_sec_out         : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_sec_set_out     : out   std_logic ;
    rtc_datetime_out    : out   std_logic_vector (dt_totalbits_c-1
                                                  downto 0) ;

    time_latch_out      : out   std_logic ;
    time_valid_out      : out   std_logic ;
    valid_latch_out     : out   std_logic ;

    gpsmem_tmbank_in    : in    std_logic ;
    gpsmem_req_out      : out   std_logic ;
    gpsmem_rcv_in       : in    std_logic ;
    gpsmem_addr_out     : out   std_logic_vector (gpsmem_addrbits_g-1
                                                  downto 0) ;
    gpsmem_datafrom_in  : in    std_logic_vector (gpsmem_databits_g-1
                                                  downto 0) ;
    gpsmem_readen_out   : out   std_logic ;

    alarm_time_in       : in    std_logic_vector (dt_totalbits_c-1
                                                  downto 0) ;
    alarm_time_out      : out   unsigned  (epoch70_secbits_c-1 downto 0)
  ) ;

end entity SystemTime ;


architecture rtl of SystemTime is

  --  Times maintained by this module.
  --    The time since startup (Startup Time) in GPS Time Format.
  --    The GPS Time in GPS Time Format.
  --    Alarm Time in seconds (epoch70).
  --    Local Time.  Formatted RTC time converted to local time zone,
  --    daylight savings time, and leap seconds.

  signal startup_time         : GPS_Time ;
  signal gps_timerec          : GPS_Time ;
  signal alarm_time           : unsigned (epoch70_secbits_c-1 downto 0) ;
  signal date_time            : std_logic_vector (dt_totalbits_c-1
                                                  downto 0) ;

  --  Cross chip communication protects against corruption of signals
  --  travelling long distances and across clock domains.  This operation
  --  takes to fast clock cycles to complete and so must be slowed down from
  --  clock generation by a factor of two.

  signal systime_ready        : std_logic := '0' ;

  component CrossChipSend is
    Generic (
      fast_latch_g          : std_logic := '1'
    ) ;
    Port (
      fast_clk              : in    std_logic ;
      data_ready_in         : in    std_logic ;
      data_latch_out        : out   std_logic ;
      data_valid_out        : out   std_logic ;
      valid_latch_out       : out   std_logic
    ) ;
  end component CrossChipSend ;

  --  Map GPS times to standard logic vector of bits and one of bytes.

  signal startup_time_bts   : std_logic_vector (gps_time_bytes_c*8-1
                                                downto 0) :=
                                                    (others => '0') ;
  alias  startup_time_slv   : std_logic_vector (gps_time_bits_c-1
                                                downto 0) is
        startup_time_bts (gps_time_bits_c-1 downto 0) ;

  signal gps_timerec_bts    : std_logic_vector (gps_time_bytes_c*8-1
                                                downto 0) :=
                                                    (others => '0') ;
  alias  gps_timerec_slv    : std_logic_vector (gps_time_bits_c-1
                                                downto 0) is
        gps_timerec_bts (gps_time_bits_c-1 downto 0) ;

  --  Bits of addition that can be carried out in specified times.
  --  These numbers are underestimated in order for connection times to and
  --  from an adder be part of it.

  constant addbits_per_usec_c       : natural := 500 ;
  constant addbits_per_clock_c      : natural :=
              natural (trunc (real (addbits_per_usec_c) * 1.0e6 /
                              real (clk_freq_g))) ;

  --------------------------------------------------------------------------
  --  Startup and GPS time connecting constants and signals.
  --------------------------------------------------------------------------

  constant clk_in_nanosec_c         : natural :=
                  natural (round (1.0e9 / real (clk_freq_g))) ;
  constant clk_per_millisec_c       : natural :=
                  natural (round (real (clk_freq_g) / 1000.0)) ;
  constant clk_per_millisec_bits_c  : natural :=
                  const_bits (clk_per_millisec_c) ;

  signal startup_nanosec_cnt        :
                  unsigned (gps_time_nanobits_c-1 downto 0) ;
  signal startup_millisec_cnt       :
                  std_logic_vector (gps_time_millibits_c-1 downto 0) ;
  signal startup_weekno_cnt         :
                  std_logic_vector (gps_time_weekbits_c-1 downto 0) ;
  signal startup_carry_to_millisec  : std_logic ;
  signal startup_carry_to_week      : std_logic ;


  constant gps_nanosec_limit_c      : natural := 1e6 ;
  constant week_seconds_c           : natural := 7 * 24 * 60 * 60 ;
  constant gps_millisec_limit_c     : natural := week_seconds_c * 1000 ;
  constant gps_epoch70_offset_c     : natural := (365 * 10 + 2 + 5) *
                                                 24 * 60 * 60 ;

  signal gps_nanosec_cnt            :
                  unsigned (gps_time_nanobits_c-1 downto 0) ;
  signal gps_millisec_cnt           :
                  std_logic_vector (gps_time_millibits_c-1 downto 0) ;
  signal gps_weekno_cnt             :
                  std_logic_vector (gps_time_weekbits_c-1 downto 0) ;
  signal gps_carry_to_millisec      : std_logic ;
  signal gps_carry_to_week          : std_logic ;

  signal gps_timerec_load           : std_logic ;
  signal gps_seconds_load           : std_logic ;
  signal rtc_seconds_load           : std_logic ;
  signal gps_timerec_restart        : std_logic ;

  signal gps_seconds                : unsigned (epoch70_secbits_c-1
                                                downto 0) ;
  signal rtc_seconds                : unsigned (epoch70_secbits_c-1
                                                downto 0) :=
                                          (others => '0') ;
  signal next_second                : unsigned (epoch70_secbits_c-1
                                                downto 0) ;

  --------------------------------------------------------------------------
  --  Signals for formatting the local time.
  --------------------------------------------------------------------------

  signal calc_datetime_start  : std_logic ;
  signal calc_datetime_done   : std_logic ;

  --------------------------------------------------------------------------
  --  Calculate differences between Real Time Clock and Timemark time
  --  and Startup Time to keep continuing RTC Seconds and GPS Time.
  --  The GPS Time and RTC Time will be initialized to the compile time to
  --  start at a recent, valid time.
  --------------------------------------------------------------------------

  constant gps_secbits_c      : natural := epoch70_secbits_c +
                                           const_bits (1000) ;

  constant gps_compile_time_c : natural := compile_timestamp_c -
                                           gps_epoch70_offset_c ;

  signal load_time            : GPS_Time :=
  (
    week_number               =>
                std_logic_vector (TO_UNSIGNED (gps_compile_time_c /
                                               week_seconds_c,
                                               gps_time_weekbits_c)),
    week_millisecond          =>
                std_logic_vector (TO_UNSIGNED ((gps_compile_time_c rem
                                                week_seconds_c) * 1000,
                                               gps_time_millibits_c)),
    millisecond_nanosecond    =>
                std_logic_vector (TO_UNSIGNED (65533,
                                               gps_time_nanobits_c))
  ) ;

  signal sample_time          : GPS_Time :=
  (
    week_number               => (others => '0'),
    week_millisecond          => (others => '0'),
    millisecond_nanosecond    => (others => '0')
  ) ;
  signal target_time          : GPS_Time :=
  (
    week_number               => (others => '0'),
    week_millisecond          => (others => '0'),
    millisecond_nanosecond    => (others => '0')
  ) ;

  signal result_time          : GPS_Time ;

  signal rtc_loaded           : unsigned (gps_secbits_c-1 downto 0) :=
                TO_UNSIGNED (compile_timestamp_c, gps_secbits_c) ;

  signal rtc_secs             : unsigned (gps_secbits_c-1 downto 0) ;

  signal gps_nanodiff_sub     : signed   (gps_time_nanobits_c+1 downto 0) ;
  signal gps_nanodiff_pos     : unsigned (gps_time_nanobits_c   downto 0) ;
  signal gps_nanodiff_borrow  : unsigned (0 downto 0) ;
  signal gps_nanodiff         : unsigned (gps_time_nanobits_c   downto 0) ;

  signal gps_millidiff_sub    : signed   (gps_time_millibits_c+1 downto 0) ;
  signal gps_millidiff_pos    : unsigned (gps_time_millibits_c   downto 0) ;
  signal gps_millidiff_borrow : unsigned (0 downto 0) ;
  signal gps_millidiff        : unsigned (gps_time_millibits_c   downto 0) ;

  signal gps_weekdiff         : unsigned (gps_time_weekbits_c-1  downto 0) ;

  signal diff_nanosec         : unsigned (gps_time_nanobits_c   downto 0) ;
  signal diff_nano_limit      : signed   (gps_time_nanobits_c+1 downto 0) ;
  signal diff_nano_over       : unsigned (gps_time_nanobits_c   downto 0) ;
  signal diff_nano_carry      : unsigned (0 downto 0) ;

  signal diff_millisec        : unsigned (gps_time_millibits_c   downto 0) ;
  signal diff_milli_limit     : signed   (gps_time_millibits_c+1 downto 0) ;
  signal diff_milli_over      : unsigned (gps_time_millibits_c   downto 0) ;
  signal diff_milli_carry     : unsigned (0 downto 0) ;

  --  Detemine the clock cycle delay count based on the number of serial
  --  bit adds needed divided by the number that can be done in a clock
  --  cycle.

  constant rtc_load_delay_c   : natural := (rtc_secs'length           * 2) /
                                           addbits_per_clock_c + 1 ;

  constant diffcalc_clocks_c  : natural := (gps_nanodiff_sub'length   * 2 +
                                            gps_millidiff_sub'length  * 2 +
                                            gps_time_weekbits_c       * 1) /
                                           addbits_per_clock_c + 1 ;

  constant diff_delay_c       : natural := (gps_nanodiff'length       * 2 +
                                            diff_nano_limit'length    * 1 +
                                            gps_millidiff'length      * 1 +
                                            diff_milli_limit'length   * 1 +
                                            gps_weekdiff'length       * 1) /
                                           addbits_per_clock_c + 1 ;

  constant clock_set_delay_c  : natural := 3 ;


  --------------------------------------------------------------------------
  --  Conversion state machine constants and signals.
  --------------------------------------------------------------------------

  type gps_state_cnv_t is
  (
    gps_st_wait_e,
    gps_st_tmload_e,
    gps_st_tmweek_e,
    gps_st_tmmilli_e,
    gps_st_tmnano_e,
    gps_st_tmmarked_e,
    gps_st_rtcload_e,
    gps_st_rtcdiv_e,
    gps_st_rtcdiff_e,
    gps_st_gpsdiff_e,
    gps_st_diff_wait_e,
    gps_st_diff_calc_e,
    gps_st_sec_calc_e,
    gps_st_sec_save_e,
    gps_st_divide_e,
    gps_st_divloop_e
  ) ;

  signal cur_state                  : gps_state_cnv_t ;
  signal return_state               : gps_state_cnv_t ;

  constant count_tbl_c              : integer_vector :=
  (
    MUTTm2_wnF_size_c - 1,
    MUTTm2_towMsF_size_c - 1,
    MUTTm2_towSubMsF_size_c - 1,
    gps_time_bytes_c - 1,
    diffcalc_clocks_c - 1,
    rtc_load_delay_c - 1,
    rtc_secs'length - 1,
    diffcalc_clocks_c - 1,
    diff_delay_c - 1,
    gps_time_millibits_c - 1,
    clock_set_delay_c
  ) ;

  constant count_max_c              : natural := max_integer (count_tbl_c) ;

  signal count                      : unsigned (const_bits (count_max_c)-1
                                                downto 0) ;

  constant numerator_tbl_c          : integer_vector :=
  (
    gps_secbits_c,
    gps_time_millibits_c
  ) ;

  constant denominator_tbl_c        : integer_vector :=
  (
    const_bits (millisec_week_c),
    const_bits (1000)
  ) ;

  constant numerator_bits_c         : natural :=
                                          max_integer (numerator_tbl_c) ;
  constant denominator_bits_c       : natural :=
                                          max_integer (denominator_tbl_c) ;

  signal div_numerator              : unsigned (numerator_bits_c-1
                                                downto 0) ;
  signal div_denominator            : unsigned (denominator_bits_c-1
                                                downto 0) ;
  signal div_result                 : unsigned (numerator_bits_c-1
                                                downto 0) ;
  signal div_remainder              : unsigned (denominator_bits_c
                                                downto 0) ;

  --  Delay can be one less than needed as there is one clock cycle delay
  --  between re-execution of the state.

  constant div_delay_c              : natural := (denominator_bits_c + 1 ) /
                                                 addbits_per_clock_c ;

  constant delay_tbl_c              : integer_vector :=
  (
    div_delay_c,
    div_delay_c
  ) ;

  constant delay_max_c              : natural := max_integer (delay_tbl_c) ;

  signal delay_count                : unsigned (const_bits (delay_max_c)-1
                                                downto 0) ;

  --------------------------------------------------------------------------
  --  Constants and signals for starting time loading.
  --------------------------------------------------------------------------

  signal gpsmem_address             : unsigned (gpsmem_addr_out'length-1
                                                downto 0) ;
  signal tmbank_fwl                 : std_logic ;
  signal rtc_sec_load_fwl           : std_logic ;

  signal tmweek                     :
            std_logic_vector (MUTTm2_wnF_size_c*8-1 downto 0) ;
  signal tmmilli                    :
            std_logic_vector (MUTTm2_towMsF_size_c*8-1 downto 0) ;
  signal tmnano                     :
            std_logic_vector (MUTTm2_towSubMsF_size_c*8-1 downto 0) ;
  signal tmmarked                   :
            std_logic_vector (gps_time_bytes_c*8-1 downto 0) ;

  --------------------------------------------------------------------------
  --  Fast counter to handle nanoseconds.
  --------------------------------------------------------------------------

  component FastConstCounter is
    generic
    (
      AddBitsPerUsec_g    : natural := 1000 ;
      CounterConstant_g   : natural := 5 ;
      CounterLimit_g      : natural := 15 ;
      clk_freq_g          : natural := 10e6
    ) ;
    port
    (
      reset               : in    std_logic ;
      clk                 : in    std_logic ;
      preset_in           : in    unsigned (const_bits (CounterLimit_g-1)-1
                                            downto 0) ;
      result_out          : out   unsigned (const_bits (CounterLimit_g-1)-1
                                            downto 0) ;
      carry_out           : out   std_logic
    ) ;
  end component FastConstCounter ;

  --  Epoch since 1970 seconds to/from local broken down time converter.

  component FormatSeconds is
    Generic (
      timezone_g        : integer   := -7 * 60 * 60 ;
      dst_start_mth_g   : natural   :=  3 ;
      dst_start_day_g   : natural   :=  8 ;
      dst_start_hr_g    : natural   :=  2 ;
      dst_start_min_g   : natural   :=  0 ;
      dst_end_mth_g     : natural   := 11 ;
      dst_end_day_g     : natural   :=  1 ;
      dst_end_hr_g      : natural   :=  2 ;
      dst_end_min_g     : natural   :=  0 ;
      dst_seconds_g     : natural   := 60 * 60
    ) ;
    Port (
      reset             : in    std_logic ;
      leap_seconds_in   : in    unsigned (7 downto 0) ;
      epoch70_in        : in    unsigned (epoch70_secbits_c-1 downto 0) ;
      datetime_out      : out   std_logic_vector (dt_totalbits_c-1 downto 0) ;
      to_datetime_clk   : in    std_logic ;
      to_dt_start_in    : in    std_logic ;
      to_dt_done_out    : out   std_logic ;
      datetime_in       : in    std_logic_vector (dt_totalbits_c-1 downto 0) ;
      epoch70_out       : out   unsigned (epoch70_secbits_c-1 downto 0) ;
      from_datetime_clk : in    std_logic ;
      from_dt_start_in  : in    std_logic ;
      from_dt_done_out  : out   std_logic
    ) ;
  end component FormatSeconds ;

  --  Eight millisecond clock taken from a low bit of the startup time's
  --  millisecond field.

  constant milli_count_c    : natural := 125 ;

  signal rtc_milli_cnt      : unsigned (const_bits (milli_count_c-1)-1
                                        downto 0) ;
  signal milli_clk          : std_logic ;

  attribute keep                : boolean ;
  attribute keep of milli_clk   : signal is true ;

begin

  --------------------------------------------------------------------------
  --  Cross Chip Latching Signalling
  --------------------------------------------------------------------------

  ccs : CrossChipSend
    Generic Map (
      fast_latch_g          => '1'
    )
    Port Map (
      fast_clk              => clk,
      data_ready_in         => systime_ready,
      data_latch_out        => time_latch_out,
      data_valid_out        => time_valid_out,
      valid_latch_out       => valid_latch_out
    ) ;

  --------------------------------------------------------------------------
  --  Startup Time
  --------------------------------------------------------------------------

  startup_time_slv          <= TO_STD_LOGIC_VECTOR (startup_time) ;
  startup_time_out          <= startup_time_slv ;
  startup_bytes_out         <= startup_time_bts ;

  nanosec_counter : FastConstCounter
    Generic Map
    (
      AddBitsPerUsec_g    => addbits_per_usec_c,
      CounterConstant_g   => clk_in_nanosec_c,
      CounterLimit_g      => gps_nanosec_limit_c,
      clk_freq_g          => clk_freq_g
    )
    Port Map
    (
      reset               => reset,
      clk                 => clk,
      preset_in           => (others => '0'),
      result_out          => startup_nanosec_cnt,
      carry_out           => startup_carry_to_millisec
    ) ;

  millisec_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_MODULUS         => gps_millisec_limit_c,
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => gps_time_millibits_c
    )
    Port Map (
      aclr                => reset,
      cin                 => startup_carry_to_millisec,
      clock               => clk,
      cout                => startup_carry_to_week,
      q                   => startup_millisec_cnt
    ) ;

  week_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => gps_time_weekbits_c
    )
    Port Map (
      aclr                => reset,
      cin                 => startup_carry_to_week,
      clock               => clk,
      q                   => startup_weekno_cnt
    ) ;

  --------------------------------------------------------------------------
  --  GPS Time
  --------------------------------------------------------------------------

  gps_timerec_slv           <= TO_STD_LOGIC_VECTOR (gps_timerec) ;
  gps_time_out              <= gps_timerec_slv ;
  gps_bytes_out             <= gps_timerec_bts ;

  gps_timerec_restart       <= reset or gps_timerec_load ;

  gps_nanosec_counter : FastConstCounter
    Generic Map
    (
      AddBitsPerUsec_g    => addbits_per_usec_c,
      CounterConstant_g   => clk_in_nanosec_c,
      CounterLimit_g      => gps_nanosec_limit_c,
      clk_freq_g          => clk_freq_g
    )
    Port Map
    (
      reset               => gps_timerec_restart,
      clk                 => clk,
      preset_in           => unsigned (result_time.millisecond_nanosecond),
      result_out          => gps_nanosec_cnt,
      carry_out           => gps_carry_to_millisec
    ) ;

  gps_millisec_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_MODULUS         => gps_millisec_limit_c,
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => gps_time_millibits_c
    )
    Port Map (
      cin                 => gps_carry_to_millisec,
      clock               => clk,
      data                => result_time.week_millisecond,
      sload               => gps_timerec_restart,
      cout                => gps_carry_to_week,
      q                   => gps_millisec_cnt
    ) ;

  gps_week_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => gps_time_weekbits_c
    )
    Port Map (
      cin                 => gps_carry_to_week,
      clock               => clk,
      data                => result_time.week_number,
      sload               => gps_timerec_restart,
      q                   => gps_weekno_cnt
    ) ;

  --------------------------------------------------------------------------
  --  Convert the last received RTC seconds into the difference between
  --  GPS Time and Startup Time.  Multiplying by 1000 is reduced to 3 adds
  --  by multiplying by 1024 (1 bit set) then subtracting the result of
  --  multiplying by 24 (2 bits set).
  --  The difference between RTC time start and GPS time start is
  --  subtracted.
  --  Division by the number of milliseconds per week is used to convert
  --  this value into a week number and milliseconds into that week.
  --------------------------------------------------------------------------

  rtc_secs              <= RESIZE (rtc_loaded * const_unsigned (1024) -
                                   rtc_loaded * const_unsigned (24),
                                   rtc_secs'length) -
                           RESIZE (const_unsigned (gps_epoch70_offset_c) *
                                   const_unsigned (1000),
                                   rtc_secs'length) ;


  --------------------------------------------------------------------------
  --  Calculate the difference between the Marked Time and Startup Time.
  --  The Marked Time may be from the Real Time Clock or the GPS.  The
  --  difference values have one more bit than needed to store the values
  --  normally.  This allows calculations using them to exceed the space
  --  normally available.  A carry to the next value then must be done.
  --------------------------------------------------------------------------

  gps_nanodiff_sub      <=
      signed (RESIZE (unsigned (target_time.millisecond_nanosecond),
                                gps_nanodiff_sub'length)) -
      signed (RESIZE (unsigned (sample_time.millisecond_nanosecond),
                                gps_nanodiff_sub'length)) ;
  gps_nanodiff_pos      <=
      unsigned (gps_nanodiff_sub (gps_nanodiff_pos'length-1 downto 0)) ;
  gps_nanodiff_borrow   <=
      unsigned (gps_nanodiff_sub (gps_nanodiff_sub'length-1 downto
                                  gps_nanodiff_sub'length-1)) ;

  gps_nanodiff  <= RESIZE (unsigned (gps_nanodiff_sub +
                                     gps_nanosec_limit_c),
                           gps_nanodiff'length)
                      when (gps_nanodiff_borrow /= 0) else
                   gps_nanodiff_pos ;

  gps_millidiff_sub      <=
      signed (RESIZE (unsigned (target_time.week_millisecond),
                                gps_millidiff_sub'length)) -
      signed (RESIZE (unsigned (sample_time.week_millisecond),
                                gps_millidiff_sub'length)) -
      signed (RESIZE (gps_nanodiff_borrow, 2)) ;
  gps_millidiff_pos      <=
      unsigned (gps_millidiff_sub (gps_millidiff_pos'length-1 downto 0)) ;
  gps_millidiff_borrow   <=
      unsigned (gps_millidiff_sub (gps_millidiff_sub'length-1 downto
                                   gps_millidiff_sub'length-1)) ;

  gps_millidiff <= RESIZE (unsigned (gps_millidiff_sub +
                                     gps_millisec_limit_c),
                           gps_millidiff'length)
                      when (gps_millidiff_borrow /= 0) else
                   gps_millidiff_pos ;

  gps_weekdiff  <= unsigned (target_time.week_number) -
                   unsigned (sample_time.week_number) -
                   gps_millidiff_borrow ;

  --------------------------------------------------------------------------
  --  Use the GPS difference values added to the Startup Time snapshot
  --  to calculate initial value loaded into the GPS time.
  --  Carry and the amount left over after carry are calculated with a
  --  single subtraction whose value can be reused saving a subtraction.
  --    A sign bit is added to the target value to be checked for carry and
  --    the limit is subtracted from it.  If this sign bit is not set,
  --    overflow occured resulting in carry.  The target value used is then
  --    the amount of the overflow instead of the initial target value.
  --    The carry result is added to the next significant value.
  --------------------------------------------------------------------------

  diff_nanosec          <= unsigned (load_time.millisecond_nanosecond) +
                           gps_nanodiff + diff_delay_c * clk_in_nanosec_c ;

  diff_nano_limit       <= signed (RESIZE (diff_nanosec,
                                           diff_nano_limit'length)) -
                           gps_nanosec_limit_c ;
  diff_nano_over        <= unsigned (diff_nano_limit (diff_nano_over'length-1
                                                      downto 0)) ;
  diff_nano_carry       <=
      not unsigned (diff_nano_limit (diff_nano_limit'length-1 downto
                                     diff_nano_limit'length-1)) ;

  result_time.millisecond_nanosecond  <=
      std_logic_vector (RESIZE (diff_nano_over, gps_time_nanobits_c))
          when (diff_nano_carry /= 0) else
      std_logic_vector (RESIZE (diff_nanosec, gps_time_nanobits_c)) ;

  --  Handle milliseconds.

  diff_millisec         <= unsigned (load_time.week_millisecond) +
                           gps_millidiff + diff_nano_carry ;

  diff_milli_limit      <= signed (RESIZE (diff_millisec,
                                           diff_milli_limit'length)) -
                           gps_millisec_limit_c ;
  diff_milli_over       <=
      unsigned (diff_milli_limit (diff_milli_over'length-1 downto 0)) ;
  diff_milli_carry      <=
      not unsigned (diff_milli_limit (diff_milli_limit'length-1 downto
                                      diff_milli_limit'length-1)) ;

  result_time.week_millisecond        <=
      std_logic_vector (RESIZE (diff_milli_over, gps_time_millibits_c))
            when (diff_milli_carry /= 0) else
      std_logic_vector (RESIZE (diff_millisec, gps_time_millibits_c)) ;

  --  Handle weeks.

  result_time.week_number             <=
            std_logic_vector (gps_weekdiff +
                              unsigned (load_time.week_number) +
                              diff_milli_carry) ;

  --  Derive 8ms second counting clock from the GPS time.

  milli_clk             <= gps_timerec.week_millisecond (2) ;

  --  Date/Time converter.

  next_second           <= rtc_seconds + 1 ;

  dt_cnv : FormatSeconds
    Generic Map (
      timezone_g        => timezone_g,
      dst_start_mth_g   => dst_start_mth_g,
      dst_start_day_g   => dst_start_day_g,
      dst_start_hr_g    => dst_start_hr_g,
      dst_start_min_g   => dst_start_min_g,
      dst_end_mth_g     => dst_end_mth_g,
      dst_end_day_g     => dst_end_day_g,
      dst_end_hr_g      => dst_end_hr_g,
      dst_end_min_g     => dst_end_min_g,
      dst_seconds_g     => dst_seconds_g
    )
    Port Map (
      reset             => reset,
      leap_seconds_in   => TO_UNSIGNED (26, 8),   -- as of July 2015
      epoch70_in        => next_second,
      datetime_out      => date_time,
      to_datetime_clk   => milli_clk,
      to_dt_start_in    => calc_datetime_start,
      to_dt_done_out    => calc_datetime_done,
      datetime_in       => alarm_time_in,
      epoch70_out       => alarm_time,
      from_datetime_clk => milli_clk,
      from_dt_start_in  => calc_datetime_start
    ) ;

  --------------------------------------------------------------------------
  --  Latch the clocks all on the same clock edge to insure they are always
  --  consistant.
  --------------------------------------------------------------------------

  latch_process : process (clk)
  begin
    if (rising_edge (clk)) then

      --  Startup Time

      startup_time.millisecond_nanosecond   <=
                                 std_logic_vector (startup_nanosec_cnt) ;
      startup_time.week_millisecond         <= startup_millisec_cnt ;
      startup_time.week_number              <= startup_weekno_cnt ;

      --  GPS Time.

      gps_timerec.millisecond_nanosecond   <=
                                 std_logic_vector (gps_nanosec_cnt) ;
      gps_timerec.week_millisecond         <= gps_millisec_cnt ;
      gps_timerec.week_number              <= gps_weekno_cnt ;

      --  Latch Cross Chip signals every other clock cycle.

      systime_ready                       <= not systime_ready ;

    end if ;
  end process latch_process ;

  --------------------------------------------------------------------------
  --  Count seconds for the RTC clock.
  --------------------------------------------------------------------------

  rtc_seconds_load            <= reset or gps_seconds_load ;

  rtc_sec_out                 <= rtc_seconds ;
  rtc_sec_set_out             <= gps_seconds_load ;


  upd_sec : process (rtc_seconds_load, gps_seconds, milli_clk)
  begin
    if (rtc_seconds_load = '1') then
      rtc_seconds             <= gps_seconds ;
      rtc_milli_cnt           <= (others => '0') ;
      calc_datetime_start     <= '0' ;
      alarm_time_out          <= (others => '0') ;

    elsif (rising_edge (milli_clk)) then

      if (rtc_milli_cnt /= milli_count_c) then
        rtc_milli_cnt         <= rtc_milli_cnt + 1 ;
        calc_datetime_start   <= '0' ;
      else
        rtc_milli_cnt         <= (others => '0') ;
        rtc_seconds           <= rtc_seconds + 1 ;

        rtc_datetime_out      <= date_time ;
        calc_datetime_start   <= '1' ;
        alarm_time_out        <= alarm_time ;
      end if ;
    end if ;
  end process upd_sec ;

  --------------------------------------------------------------------------
  --  Add the difference between Startup Time and GPS time to the Startup
  --  Time to determine the GPS time.
  --------------------------------------------------------------------------

  gpsmem_addr_out           <= std_logic_vector (gpsmem_address) ;

  gps_tm : process (reset, clk)
    variable remainder      : unsigned (div_remainder'length-1 downto 0) ;
    variable difference     : signed   (div_remainder'length   downto 0) ;
  begin
    if (reset = '1') then
      tmbank_fwl            <= '0' ;
      rtc_sec_load_fwl      <= '0' ;
      gpsmem_req_out        <= '0' ;
      gpsmem_readen_out     <= '0' ;
      gpsmem_address        <= (others => '0') ;
      gps_timerec_load      <= '0' ;
      gps_seconds           <= TO_UNSIGNED (compile_timestamp_c,
                                            gps_seconds'length) ;
      gps_seconds_load      <= '1' ;
      cur_state             <= gps_st_wait_e ;

    elsif (rising_edge (clk)) then

      case (cur_state) is

        --  Wait until a new GPS time must be calculated because new
        --  timing information is available.

        when gps_st_wait_e            =>
          gps_seconds_load        <= '0' ;

          if (tmbank_fwl /= gpsmem_tmbank_in) then
            tmbank_fwl <= gpsmem_tmbank_in ;

            gpsmem_req_out        <= '1' ;
            cur_state             <= gps_st_tmload_e ;

          elsif (rtc_sec_load_fwl /= rtc_sec_load_in) then
            rtc_sec_load_fwl      <= rtc_sec_load_in ;

            if (rtc_sec_load_in = '1') then
              cur_state           <= gps_st_rtcload_e ;
            end if ;
          end if ;

        --  Load the GPS timebank time from GPS memory.

        when gps_st_tmload_e          =>
          if (gpsmem_rcv_in = '1') then
             gpsmem_address        <=
                  TO_UNSIGNED (msg_ram_base_c +
                               msg_ubx_tim_tm2_ramaddr_c +
                               if_set (gpsmem_tmbank_in,
                                       msg_ubx_tim_tm2_ramused_c) +
                               MUTTm2_wnF_offset_c,
                               gpsmem_address'length) ;
            gpsmem_readen_out     <= '1' ;
            count                 <= TO_UNSIGNED (MUTTm2_wnF_size_c - 1,
                                                  count'length) ;
            cur_state             <= gps_st_tmweek_e ;
          end if ;

        when gps_st_tmweek_e          =>
          tmweek                  <= gpsmem_datafrom_in &
                                     tmweek (tmweek'length-1 downto 8) ;

          if (count /= 0) then
            count                 <= count - 1 ;
            gpsmem_address        <= gpsmem_address + 1 ;
          else
            gpsmem_address        <=
                  TO_UNSIGNED (msg_ram_base_c +
                               msg_ubx_tim_tm2_ramaddr_c +
                               if_set (gpsmem_tmbank_in,
                                       msg_ubx_tim_tm2_ramused_c) +
                               MUTTm2_towMsF_offset_c,
                               gpsmem_address'length) ;
            count                 <= TO_UNSIGNED (MUTTm2_towMsF_size_c - 1,
                                                  count'length) ;
            cur_state             <= gps_st_tmmilli_e ;
          end if ;

        when gps_st_tmmilli_e         =>
          tmmilli                 <= gpsmem_datafrom_in &
                                     tmmilli (tmmilli'length-1 downto 8) ;

          if (count /= 0) then
            count                 <= count - 1 ;
            gpsmem_address        <= gpsmem_address + 1 ;
          else
            gpsmem_address        <=
                  TO_UNSIGNED (msg_ram_base_c +
                               msg_ubx_tim_tm2_ramaddr_c +
                               if_set (gpsmem_tmbank_in,
                                       msg_ubx_tim_tm2_ramused_c) +
                               MUTTm2_towSubMsF_offset_c,
                               gpsmem_address'length) ;
            count                 <= TO_UNSIGNED (MUTTm2_towSubMsF_size_c -
                                                  1, count'length) ;
            cur_state             <= gps_st_tmnano_e ;
          end if ;

        when gps_st_tmnano_e          =>
          tmnano                  <= gpsmem_datafrom_in &
                                     tmnano (tmnano'length-1 downto 8) ;

          if (count /= 0) then
            count                 <= count - 1 ;
            gpsmem_address        <= gpsmem_address + 1 ;
          else
            gpsmem_address        <=
                  TO_UNSIGNED (msg_ram_base_c +
                               msg_ram_marktime_addr_c +
                               if_set (gpsmem_tmbank_in,
                                       msg_ram_marktime_size_c),
                               gpsmem_address'length) ;
            count                 <= TO_UNSIGNED (gps_time_bytes_c - 1,
                                                  count'length) ;
            cur_state             <= gps_st_tmmarked_e ;
          end if ;

        when gps_st_tmmarked_e        =>
          tmmarked                <= gpsmem_datafrom_in &
                                     tmmarked (tmmarked'length-1 downto 8) ;

          if (count /= 0) then
            count                 <= count - 1 ;
            gpsmem_address        <= gpsmem_address + 1 ;
          else
            gpsmem_readen_out     <= '0' ;
            gpsmem_req_out        <= '0' ;
            cur_state             <= gps_st_gpsdiff_e ;
          end if ;

        when gps_st_gpsdiff_e         =>
          target_time.week_number               <=
                    tmweek (gps_time_weekbits_c-1   downto 0) ;
          target_time.week_millisecond          <=
                    tmmilli (gps_time_millibits_c-1 downto 0) ;
          target_time.millisecond_nanosecond    <=
                    tmnano (gps_time_nanobits_c-1   downto 0) ;
          sample_time                           <=
                    TO_GPS_TIME (tmmarked (gps_time_bits_c-1 downto 0)) ;
          count                                 <=
                    TO_UNSIGNED (diffcalc_clocks_c - 1, count'length) ;
          cur_state                             <= gps_st_diff_wait_e ;

         -- Calculate the difference between RTC time and Startup Time.

        when gps_st_rtcload_e         =>
          rtc_loaded                <= RESIZE (rtc_sec_in,
                                               rtc_loaded'length) ;
          count                     <= TO_UNSIGNED (rtc_load_delay_c - 1,
                                                    count'length) ;
          cur_state                 <= gps_st_rtcdiv_e ;

        when gps_st_rtcdiv_e          =>
          if (count /= 0) then
            count                   <= count - 1 ;
          else
            div_numerator           <= SHIFT_LEFT_LL (rtc_secs,
                                                      div_numerator'length -
                                                      rtc_secs'length) ;
            div_denominator         <= TO_UNSIGNED (millisec_week_c,
                                                    div_denominator'length) ;
            count                   <= TO_UNSIGNED (rtc_secs'length - 1,
                                                    count'length) ;

            return_state            <= gps_st_rtcdiff_e ;
            cur_state               <= gps_st_divide_e ;
          end if ;

        when gps_st_rtcdiff_e         =>
          target_time.week_number             <=
                  std_logic_vector (RESIZE (div_result,
                                            gps_time_weekbits_c)) ;
          target_time.week_millisecond        <=
                  std_logic_vector (RESIZE (div_remainder,
                                            gps_time_millibits_c)) ;
          target_time.millisecond_nanosecond  <= (others => '0') ;
          sample_time                         <= startup_time ;
          count                               <=
                  TO_UNSIGNED (diffcalc_clocks_c - 1, count'length) ;
          cur_state                           <= gps_st_diff_wait_e ;

        --  Wait until the difference values have been calculated then
        --  apply them to the startup time.
        --  These steps are too slow to be done in one clock cycle, thus
        --  they must be done outside the process.

        when gps_st_diff_wait_e     =>
          if (count /= 0) then
            count                 <= count - 1 ;
          else
            load_time             <= startup_time ;
            count                 <= TO_UNSIGNED (diff_delay_c - 1,
                                                  count'length) ;
            cur_state             <= gps_st_diff_calc_e ;
          end if ;

        when gps_st_diff_calc_e     =>
          if (count /= 0) then
            count                 <= count - 1 ;
          else
            gps_timerec_load      <= '1' ;
            count                 <= TO_UNSIGNED (clock_set_delay_c - 1,
                                                  count'length) ;
            cur_state             <= gps_st_sec_calc_e ;
          end if ;

        --  Calculate the GPS seconds from the GPS Time.  It is in
        --  Epoch70 format and is calculated by dividing the GPS
        --  milliseconds by 1000 and adding the week start to it.

        when gps_st_sec_calc_e      =>
          gps_timerec_load        <= '0' ;

          if (count /= 0) then
            count                 <= count - 1 ;
          else
            div_numerator         <=
                SHIFT_LEFT_LL (unsigned (gps_timerec.week_millisecond),
                               div_numerator'length - gps_time_millibits_c) ;
            div_denominator       <= TO_UNSIGNED (1000,
                                                  div_denominator'length) ;
            count                 <= TO_UNSIGNED (gps_time_millibits_c - 1,
                                                  count'length) ;
            return_state          <= gps_st_sec_save_e ;
            cur_state             <= gps_st_divide_e ;
          end if ;

        when gps_st_sec_save_e      =>
          gps_seconds             <=
                RESIZE (div_result + unsigned (gps_timerec.week_number) *
                        const_unsigned (week_seconds_c) +
                        const_unsigned (gps_epoch70_offset_c),
                        gps_seconds'length) ;
          gps_seconds_load        <= '1' ;
          cur_state               <= gps_st_wait_e ;

        --  Bitwise divide.
        --  The numerator must be left justified to allow the most
        --  significant bit to be extracted each pass.
        --  First bit of the remainder calculation is done ahead of time.

        when gps_st_divide_e        =>
          div_remainder           <=
              RESIZE (div_numerator (div_numerator'length-1 downto
                                     div_numerator'length-1),
                      div_remainder'length) ;
          div_numerator           <= SHIFT_LEFT (div_numerator, 1) ;
          div_result              <= (others => '0') ;
          delay_count             <= TO_UNSIGNED (div_delay_c,
                                                  delay_count'length) ;
          cur_state               <= gps_st_divloop_e ;

        when gps_st_divloop_e       =>

          --  Delay for enough clock cycles for the subtraction to complete.

          if (delay_count /= 0) then
            delay_count           <= delay_count - 1 ;
          else
            delay_count           <= TO_UNSIGNED (div_delay_c,
                                                  delay_count'length) ;

            --  The difference variable is used in order to save a
            --  subtraction as a comparison and subtraction are both
            --  needed.

            difference            := signed (RESIZE (div_remainder,
                                                     difference'length)) -
                                     signed (RESIZE (div_denominator,
                                                     difference'length)) ;

            if (difference (difference'length-1) = '0') then
              remainder           := RESIZE (unsigned (difference),
                                             remainder'length) ;
              div_result          <= SHIFT_LEFT (div_result, 1) or
                                     TO_UNSIGNED (1, div_result'length) ;
            else
              remainder           := div_remainder ;
              div_result          <= SHIFT_LEFT (div_result, 1) ;
            end if ;

            --  Return the result to the calling state.

            if (count = 0) then
              div_remainder       <= remainder ;
              cur_state           <= return_state ;
            else

              --  Start the next pass.

              count               <= count - 1 ;

              div_remainder       <=
                    RESIZE (remainder * 2 +
                            div_numerator (div_numerator'length-1 downto
                                           div_numerator'length-1),
                            div_remainder'length) ;

              div_numerator       <= SHIFT_LEFT (div_numerator, 1) ;

            end if ;
          end if ;
      end case ;
    end if ;
  end process gps_tm ;

end rtl ;
