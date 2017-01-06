----------------------------------------------------------------------------
--
--! @file       TimeMark.vhd
--! @brief      Send a time mark pulse periodically.
--! @details    When the GPS is maintaining a good position (and time),
--!             periodically trigger a time mark event.
--! @author     Emery Newlon
--! @date       August 2014
--! @copyright  Copyright (C) 2014 Ross K. Snider and Emery L. Newlon
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

library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY GENERAL ;
use GENERAL.UTILITIES_PKG.ALL ;     --  General purpose information.
USE GENERAL.GPS_CLOCK_PKG.ALL ;     --  Use GPS Clock information.

LIBRARY WORK ;
USE WORK.GPS_MESSAGE_CTL_PKG.ALL ;  --  Use GPS Message information.
USE WORK.MSG_UBX_NAV_SOL_PKG.ALL ;  --  Navagation Solution message.
USE WORK.MSG_UBX_TIM_TP_PKG.ALL ;   --  Time pulse message.


----------------------------------------------------------------------------
--
--! @brief      Initiates a Time Mark event.
--! @details    When the GPS is maintaining good positional and time
--!             information, periodically initiate a time mark event.
--!
--! @param      curtime_freq_g        Frequency of the clock that counts
--!                                   the current time.
--! @param      time_mark_interval_g  Milliseconds between time mark events.
--! @param      time_mark_timeout_g   Milliseconds allowed to get time mark.
--! @param      time_mark_wait_g      Milliseconds to wait for next time
--!                                   mark if this one timed out.
--! @param      min_pos_accuracy_g    Minimum position accuracy in CM.
--! @param      max_pos_age_g         Maximum age of the last position
--!                                   found.
--! @param      memaddr_bits_g        Number of bits on the address bus.
--! @param      clk                   Clock used to drive the processes.
--! @param      reset                 Reset the processes to initial state.
--! @param      milli_clk             Millisecond clock.
--! @param      curtime_in            Current time in GPS format.
--! @param      curtime_latch_in      Latch curtime across clock domains.
--! @param      curtime_valid_in      Latched curtime is valid when set.
--! @param      curtime_vlatch_in     Latch curtime when valid not set.
--! @param      initilized_in         Set when the GPS has been initialized.
--! @param      posbank_in            Position information memory bank.
--! @param      tmbank_in             Time mark information memory bank.
--! @param      tempbank_in           Temporary information including time
--!                                   pulse messages.
--! @param      pulsebank_out         The current bank holding the pulse
--!                                   times.
--! @param      msgnumber_in          Message number of the message in the
--!                                   temporary bank.
--! @param      memreq_out            Access to the memory bus requested.
--! @param      memrcv_in             Request for the memory bus is granted.
--! @param      memaddr_out           Address of the byte of memory to read.
--! @param      memdata_in            Data byte of memory that is addressed.
--! @param      memdata_out           Data byte of memory to be written.
--! @param      memread_en_out        Enable the memory for reading.
--! @param      memwrite_en_out       Enable the memory for writing.
--! @param      continuous_start_out  Put the GPS into continuous fix mode.
--! @param      continuous_done_in    GPS in continuous fix mode.
--! @param      powersave_start_out   Put the GPS into powersave fix mode.
--! @param      powersave_done_in     GPS in powersave fix mode.
--! @param      pulse_in              Time pulse external signal.
--! @param      marker_out            Time marker external signal.
--! @param      marker_time_out       Time marker was lowered.
--! @param      req_position_out      Request a new position fix be
--!                                   obtained.
--! @param      req_timemark_out      Request a new time mark msg be
--!                                   obtained.
--! @param      busy_out              The process is busy processing a
--!                                   timemark request.
--
----------------------------------------------------------------------------

entity TimeMark is

  Generic (
    curtime_freq_g        : natural := 1e6 ;
    time_mark_interval_g  : natural := 5 * 60 * 1000 ;
    time_mark_timeout_g   : natural := 20 * 1000 ;
    time_mark_wait_g      : natural := 60 * 1000 ;
    mark_timeout_g        : natural := 10 * 1000 ;
    mark_retries_g        : natural := 5 ;
    min_pos_accuracy_g    : natural := 100 * 100 ;
    max_pos_age_g         : natural := 15 * 60 * 1000 ;
    memaddr_bits_g        : natural := 8
  ) ;
  Port (
    clk                   : in    std_logic ;
    reset                 : in    std_logic ;
    milli_clk             : in    std_logic ;
    curtime_in            : in    std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    curtime_latch_in      : in    std_logic ;
    curtime_valid_in      : in    std_logic ;
    curtime_vlatch_in     : in    std_logic ;


    initialized_in        : in    std_logic ;
    posbank_in            : in    std_logic ;
    tmbank_in             : in    std_logic ;
    tempbank_in           : in    std_logic ;
    pulsebank_out         : out   std_logic ;
    msgnumber_in          : in    std_logic_vector (msg_count_bits_c-1
                                                    downto 0) ;
    memreq_out            : out   std_logic ;
    memrcv_in             : in    std_logic ;
    memaddr_out           : out   std_logic_vector (memaddr_bits_g-1
                                                    downto 0) ;
    memdata_in            : in    std_logic_vector (7 downto 0) ;
    memdata_out           : out   std_logic_vector (7 downto 0) ;
    memread_en_out        : out   std_logic ;
    memwrite_en_out       : out   std_logic ;
    continuous_start_out  : out   std_logic ;
    continuous_done_in    : in    std_logic ;
    powersave_start_out   : out   std_logic ;
    powersave_done_in     : in    std_logic ;
    pulse_in              : in    std_logic ;
    marker_out            : out   std_logic ;
    marker_time_out       : out   std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    req_position_out      : out   std_logic ;
    req_timemark_out      : out   std_logic ;
    busy_out              : out   std_logic
  ) ;

end entity TimeMark ;


architecture rtl of TimeMark is

  --  Capture the most recent current time possible from across clock
  --  domains.

  component CrossChipReceive is
    Generic (
      data_bits_g             : natural := 8
    ) ;
    Port (
      clk                     : in    std_logic ;
      data_latch_in           : in    std_logic ;
      data_valid_in           : in    std_logic ;
      valid_latch_in          : in    std_logic ;
      data_in                 : in    std_logic_vector (data_bits_g-1
                                                        downto 0) ;
      data_out                : out   std_logic_vector (data_bits_g-1
                                                        downto 0) ;
      data_ready_out          : out   std_logic
    ) ;
  end component CrossChipReceive ;

  --  Cross clock domain signalling.

  component SR_FlipFlop is
    Generic (
      set_edge_detect_g     : std_logic := '0' ;
      clear_edge_detect_g   : std_logic := '0'
    ) ;
    Port (
      reset_in              : in    std_logic ;
      set_in                : in    std_logic ;
      result_rd_out         : out   std_logic ;
      result_sd_out         : out   std_logic
    ) ;
  end component SR_FlipFlop ;

  --  Bit shifting.

  component Shifter is
    Generic (
      bits_wide_g           : natural   := 32 ;
      shift_bits_g          : natural   :=  8 ;
      shift_right_g         : std_logic := '1'
    ) ;
    Port (
      clk                   : in    std_logic ;
      load_buffer_in        : in    std_logic_vector (bits_wide_g-1
                                                      downto 0) ;
      load_in               : in    std_logic ;
      shift_enable_in       : in    std_logic ;
      buffer_out            : out   std_logic_vector (bits_wide_g-1
                                                      downto 0) ;
      early_lastbits_out    : out   std_logic_vector (shift_bits_g-1
                                                      downto 0) ;
      lastbits_out          : out   std_logic_vector (shift_bits_g-1
                                                      downto 0) ;
      shift_inbits_in       : in    std_logic_vector (shift_bits_g-1
                                                      downto 0)
    ) ;
  end component Shifter ;

  --  Time Mark Generation States.

  type TimeMarkState is   (
    MARK_STATE_BYTE_LOAD,
    MARK_STATE_BYTE_SAVE,
    MARK_STATE_FUTURE,
    MARK_STATE_INIT_CHECK,
    MARK_STATE_CONTINUOUS,
    MARK_STATE_READY,
    MARK_STATE_RUNNING,
    MARK_STATE_REQMEM,
    MARK_STATE_RCVMEM,
    MARK_STATE_CHECK,
    MARK_STATE_CHK_CONVERT,
    MARK_STATE_CHK_CURRENT,
    MARK_STATE_POS_WAIT,
    MARK_STATE_ACCURACY,
    MARK_STATE_CHK_ACCURACY,
    MARK_STATE_SUCCESS,
    MARK_STATE_MARK,
    MARK_STATE_END,
    MARK_STATE_CHKMSG,
    MARK_STATE_GETWEEK,
    MARK_STATE_GETMS,
    MARK_STATE_GETQERR,
    MARK_STATE_CALCTP,
    MARK_STATE_SAVE_PULSE,
    MARK_STATE_SAVE_TPMSG,
    MARK_STATE_CAPTURED,
    MARK_STATE_SCHEDULE,
    MARK_STATE_DONE
  ) ;

  signal cur_state          : TimeMarkState ;
  signal return_state       : TimeMarkState ;

  --  Output signals that must be read.

  signal mem_address        : unsigned (memaddr_bits_g-1 downto 0) ;
  signal pulsebank          : std_logic ;

  --  GPS time must be converted from standard logic vector to GPS time
  --  record structure.

  signal curtime_slv        : std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
  signal curtime            : GPS_Time ;
  signal caught_time        : GPS_Time ;

  --  Time mark scheduling information.

  constant time_mark_bits_c : natural :=
              const_bits (maximum (time_mark_wait_g, time_mark_interval_g)) ;

  signal time_mark_delay    : unsigned (time_mark_bits_c-1 downto 0) ;
  signal delay              : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal target_time        : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal retry              : unsigned (const_bits (mark_retries_g) - 1
                                        downto 0) ;

  signal clear_timing       : std_logic ;
  signal wait_time_set      : std_logic ;
  signal mark_wait          : std_logic ;
  signal mark_wait_s        : std_logic ;
  signal mark_wait_ff       : std_logic ;
  signal wait_interval_set  : std_logic ;
  signal mark_interval      : std_logic ;
  signal mark_interval_s    : std_logic ;
  signal mark_interval_ff   : std_logic ;
  signal time_mark_pending  : std_logic ;
  signal send_time_mark_set : std_logic ;
  signal send_time_mark     : std_logic ;
  signal send_time_mark_s   : std_logic ;
  signal send_time_mark_ff  : std_logic ;

  signal last_millibit      : std_logic ;

  --  Time conversion values.

  signal logtime            : GPS_Time ;

  --  Poll completed information and syncrhonizers.

  signal initialized        : std_logic ;
  signal initialized_s      : std_logic ;

  signal msgnumber_s        : std_logic_vector (msgnumber_in'length-1
                                                downto 0) ;

  signal tempbank           : std_logic ;
  signal tempbank_s         : std_logic ;
  signal last_tempbank      : std_logic ;

  signal tmbank             : std_logic ;
  signal tmbank_s           : std_logic ;
  signal last_tmbank        : std_logic ;

  signal posbank            : std_logic ;
  signal posbank_s          : std_logic ;
  signal last_posbank       : std_logic ;

  signal memrcv             : std_logic ;
  signal memrcv_s           : std_logic ;

  signal continuous_done    : std_logic ;
  signal continuous_done_s  : std_logic ;
  signal powersave_done     : std_logic ;
  signal powersave_done_s   : std_logic ;

  --  Time pulse capturing.

  signal ct_pulse           : std_logic ;
  signal ct_pulse_s         : std_logic ;
  signal ct_pulse_fwl       : std_logic ;
  signal ce_pulse           : std_logic ;
  signal ce_pulse_s         : std_logic ;

  signal pulse_timed        : std_logic ;
  signal pulse_timed_s      : std_logic ;
  signal pulse_timed_ff     : std_logic ;
  signal pulse_latched      : std_logic ;
  signal early_time_s       : std_logic ;
  signal time_clear         : std_logic ;
  signal time_caught        : std_logic ;

  signal pulse_time_s       : std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
  signal pulse_time_raw     : GPS_Time ;
  signal pulse_time_adj     : GPS_Time ;
  signal pulse_time_nano    : unsigned (gps_time_nanobits_c-1 downto 0) ;
  signal pulse_time_milli   : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal pulse_time_week    : unsigned (gps_time_weekbits_c-1 downto 0) ;
  signal pulse_nano_sub     :
            unsigned (const_bits (3 * (1e9 / curtime_freq_g))-1 downto 0) ;
  signal pulse_nano_borrow  : unsigned (0 downto 0) ;
  signal pulse_milli_borrow : unsigned (0 downto 0) ;

  --  Scratch areas used for loading/storing bit vectors to/from
  --  memory.  Each signal using it is defined via an alias.

  signal shift_to               : std_logic ;
  signal shift_from             : std_logic ;
  signal buffer_load            : std_logic ;
  signal memdata_to             : std_logic_vector (memdata_in'length-1
                                                    downto 0) ;
  signal memdata_from           : std_logic_vector (memdata_out'length-1
                                                    downto 0) ;

  constant in_length_tbl_c      : integer_vector :=
      (gps_time_bytes_c, MUNSol_pAcc_size_c) ;

  constant in_buffer_bytes_c    : natural :=
      max_integer (in_length_tbl_c) ;

  signal in_buffer              : std_logic_vector (in_buffer_bytes_c*8-1
                                                    downto 0) ;

  constant out_length_tbl_c     : integer_vector :=
      (gps_time_bytes_c, gps_time_bytes_c) ;

  constant out_buffer_bytes_c   : natural :=
      max_integer (out_length_tbl_c) ;

  signal out_buffer             : std_logic_vector (out_buffer_bytes_c*8-1
                                                    downto 0) :=
                                        (others => '0') ;

  signal byte_count             :
      unsigned (const_bits (maximum (in_buffer_bytes_c,
                                     out_buffer_bytes_c))-1 downto 0) ;

  alias  logtime_bits           :
      std_logic_vector (gps_time_bits_c-1 downto 0) is
      in_buffer        (in_buffer_bytes_c*8 - gps_time_bytes_c*8 +
                        gps_time_bits_c-1
                        downto
                        in_buffer_bytes_c*8 - gps_time_bytes_c*8) ;

  alias  posacc                 :
      std_logic_vector (MUNSol_pAcc_size_c*8-1 downto 0) is
      in_buffer        (in_buffer_bytes_c*8-1
                        downto
                        in_buffer_bytes_c*8 - MUNSol_pAcc_size_c*8) ;

  alias  buff_week              :
      std_logic_vector (MUTTp_week_size_c*8-1 downto 0) is
      in_buffer        (in_buffer_bytes_c*8-1
                        downto
                        in_buffer_bytes_c*8 - MUTTp_week_size_c*8) ;

  alias  buff_milli             :
      std_logic_vector (MUTTp_towMS_size_c*8-1 downto 0) is
      in_buffer        (in_buffer_bytes_c*8-1
                        downto
                        in_buffer_bytes_c*8 - MUTTp_towMS_size_c*8) ;

  alias  buff_qerr              :
      std_logic_vector (MUTTp_towMS_size_c*8-1 downto 0) is
      in_buffer        (in_buffer_bytes_c*8-1
                        downto
                        in_buffer_bytes_c*8 - MUTTp_qErr_size_c*8) ;

  signal tp_week                : unsigned (gps_time_weekbits_c-1
                                            downto 0) ;
  signal tp_milli               : unsigned (gps_time_millibits_c-1
                                            downto 0) ;
  signal tp_qerr_ns             : signed (buff_qerr'length-1 downto 0) ;

  alias  pulsetime              :
      std_logic_vector (gps_time_bits_c-1 downto 0) is
      out_buffer       (gps_time_bits_c-1 downto 0) ;

begin

  --  Pass the memory address out of the entity.

  memaddr_out       <= std_logic_vector (mem_address) ;

  --  Past the pulse time bank out of the entity.

  pulsebank_out     <= pulsebank ;

  --  Set the busy indicator.

  busy_out          <= send_time_mark or time_mark_pending ;

  --  Convert the Timepulse quantization error to nanoseconds.

  tp_qerr_ns        <= (signed (buff_qerr) + 500) / 1000 ;

  --  Bit shifting to and from memory.

  shift_into : component Shifter
    Generic Map (
      bits_wide_g           => in_buffer'length,
      shift_bits_g          => memdata_in'length,
      shift_right_g         => '1'
    )
    Port Map (
      clk                   => clk,
      load_buffer_in        => (others => '0'),
      load_in               => '0',
      shift_enable_in       => shift_to,
      buffer_out            => in_buffer,
      shift_inbits_in       => memdata_to
    ) ;

  shift_outof : component Shifter
    Generic Map (
      bits_wide_g           => out_buffer'length,
      shift_bits_g          => memdata_out'length,
      shift_right_g         => '1'
    )
    Port Map (
      clk                   => clk,
      load_buffer_in        => out_buffer,
      load_in               => buffer_load,
      shift_enable_in       => shift_from,
      lastbits_out          => memdata_from,
      shift_inbits_in       => (others => '0')
    ) ;

  --  Capture the most recent current time possible from across clock
  --  domains.

  curtime_receive : CrossChipReceive
    Generic Map (
      data_bits_g             => curtime_in'length
    )
    Port Map (
      clk                     => not clk,
      data_latch_in           => curtime_latch_in,
      data_valid_in           => curtime_valid_in,
      valid_latch_in          => curtime_vlatch_in,
      data_in                 => curtime_in,
      data_out                => curtime_slv
    ) ;

  --  Convert GPS Times from standard logic vector to GPS_Time record.

  curtime           <= TO_GPS_TIME (curtime_slv) ;

  --  Trigger scheduler to a delay.

  wait_time : SR_FlipFlop
    Port Map (
      reset_in              => clear_timing,
      set_in                => wait_time_set,
      result_rd_out         => mark_wait_ff
    ) ;

  wait_interval : SR_FlipFlop
    Port Map (
      reset_in              => clear_timing,
      set_in                => wait_interval_set,
      result_rd_out         => mark_interval_ff
    ) ;

  --  Trigger a new timemark.

  mark_pending : SR_FlipFlop
    Port Map (
      reset_in              => time_mark_pending,
      set_in                => send_time_mark_set,
      result_sd_out         => send_time_mark_ff
    ) ;


  --  A time pulse time has been captured.

  time_capture : SR_FlipFlop
    Port Map (
      reset_in              => time_clear,
      set_in                => pulse_latched,
      result_sd_out         => pulse_timed_ff
    ) ;

  --  The captured pulse time is two or three current time clock periods
  --  late due to being run through a synchronizer.  The curtime_latch_in
  --  clock runs at half the frequency of the current time clock and the
  --  pulse may occur while that clock is high resulting in an extra half
  --  clock cycle delay.  The early time signal captures this latter case.

  pulse_time_raw            <= TO_GPS_TIME (pulse_time_s) ;
  pulse_nano_sub            <=
          TO_UNSIGNED (2 * (1e9 / curtime_freq_g), pulse_nano_sub'length)
              when (early_time_s = '0') else
          TO_UNSIGNED (3 * (1e9 / curtime_freq_g), pulse_nano_sub'length) ;

  pulse_time_nano           <=
          unsigned (pulse_time_raw.millisecond_nanosecond) ;
  pulse_time_milli          <=
          unsigned (pulse_time_raw.week_millisecond) ;
  pulse_time_week           <=
          unsigned (pulse_time_raw.week_number) ;

  pulse_nano_borrow         <=
          TO_UNSIGNED (1, pulse_nano_borrow'length)
              when (pulse_time_nano < pulse_nano_sub) else
          TO_UNSIGNED (0, pulse_nano_borrow'length) ;

  pulse_milli_borrow        <=
          TO_UNSIGNED (1, pulse_milli_borrow'length)
              when (pulse_time_milli = 0 and pulse_nano_borrow = 1) else
          TO_UNSIGNED (0, pulse_milli_borrow'length) ;

  pulse_time_adj.millisecond_nanosecond
                            <=
          std_logic_vector (pulse_time_nano - pulse_nano_sub)
              when (pulse_nano_borrow = 0) else
          std_logic_vector (pulse_time_nano + 1000000 - pulse_nano_sub) ;
  pulse_time_adj.week_millisecond
                            <=
          std_logic_vector (pulse_time_milli - pulse_nano_borrow)
              when (pulse_milli_borrow = 0) else
          std_logic_vector (pulse_time_milli + millisec_week_c -
                            pulse_milli_borrow) ;
  pulse_time_adj.week_number
                            <=
          std_logic_vector (pulse_time_week - pulse_milli_borrow) ;


  --------------------------------------------------------------------------
  --  Catch the most recent time after a time pulse is detected.
  --------------------------------------------------------------------------

  pulse_captured : process (reset, curtime_latch_in)
  begin
    if (reset = '1') then
      ct_pulse              <= '0' ;
      ct_pulse_s            <= '0' ;
      ct_pulse_fwl          <= '0' ;
      pulse_time_s          <= (others => '0') ;
      pulse_latched         <= '0' ;

    elsif (falling_edge (curtime_latch_in)) then
      ct_pulse              <= ct_pulse_s ;
      ce_pulse_s            <= pulse_in ;

    elsif (rising_edge (curtime_latch_in)) then
      ct_pulse_s            <= pulse_in ;
      ce_pulse              <= ce_pulse_s ;

      pulse_latched         <= '0' ;

      if (ct_pulse_fwl /= ct_pulse) then
        ct_pulse_fwl        <= ct_pulse ;

        if (ct_pulse = '1') then
          pulse_time_s      <= curtime_in ;
          early_time_s      <= ce_pulse ;
          pulse_latched     <= '1' ;
        end if ;
      end if ;
    end if ;
  end process pulse_captured ;


  --------------------------------------------------------------------------
  --  Wait until the next time for a marker has arrived.
  --------------------------------------------------------------------------

  marker_alarm : process (reset, milli_clk)
  begin
    if (reset = '1') then
      mark_wait             <= '0' ;
      mark_wait_s           <= '0' ;
      mark_interval         <= '0' ;
      mark_interval_s       <= '0' ;
      clear_timing          <= '0' ;
      send_time_mark_set    <= '0' ;
      time_mark_delay       <= (others => '0') ;

    elsif (falling_edge (milli_clk)) then
      mark_wait             <= mark_wait_s ;
      mark_interval         <= mark_interval_s ;

    elsif (rising_edge (milli_clk)) then
      mark_wait_s           <= mark_wait_ff ;
      mark_interval_s       <= mark_interval_ff ;

      clear_timing          <= '0' ;
      send_time_mark_set    <= '0' ;

      --  Flip flops signal a new interval is to begin.

      if (mark_wait = '1') then
        clear_timing        <= '1' ;
        time_mark_delay     <= TO_UNSIGNED (time_mark_wait_g,
                                            time_mark_delay'length) ;
      elsif (mark_interval = '1') then
        clear_timing        <= '1' ;
        time_mark_delay     <= TO_UNSIGNED (time_mark_interval_g,
                                            time_mark_delay'length) ;

      --  The interval is underway.

      elsif (time_mark_delay /= 0) then
        if (time_mark_delay  /= 1) then
          time_mark_delay   <= time_mark_delay - 1 ;

        else
          --  Order time mark generation when the time has arrived for one.

          send_time_mark_set  <= '1' ;
          time_mark_delay     <= (others => '0') ;
        end if ;
      end if ;
    end if ;
  end process marker_alarm ;


  --------------------------------------------------------------------------
  --  Handle pending time mark requests.
  --------------------------------------------------------------------------

  marker_pending : process (reset, clk)
  begin
    if (reset = '1') then
      wait_time_set             <= '0' ;
      wait_interval_set         <= '0' ;
      time_mark_pending         <= '1' ;
      time_clear                <= '1' ;
      pulse_timed               <= '0' ;
      pulse_timed_s             <= '0' ;
      send_time_mark            <= '0' ;
      send_time_mark_s          <= '0' ;
      initialized               <= '0' ;
      initialized_s             <= '0' ;
      msgnumber_s               <= (others => '0') ;
      pulsebank                 <= '0' ;
      tempbank                  <= '0' ;
      tempbank_s                <= '0' ;
      last_tempbank             <= '0' ;
      tmbank                    <= '0' ;
      tmbank_s                  <= '0' ;
      last_tmbank               <= '0' ;
      posbank                   <= '0' ;
      posbank_s                 <= '0' ;
      last_posbank              <= '0' ;
      shift_to                  <= '0' ;
      shift_from                <= '0' ;
      buffer_load               <= '0' ;
      memreq_out                <= '0' ;
      memrcv                    <= '0' ;
      memrcv_s                  <= '0' ;
      mem_address               <= (others => '0') ;
      memread_en_out            <= '0' ;
      continuous_start_out      <= '0' ;
      continuous_done           <= '0' ;
      continuous_done_s         <= '0' ;
      powersave_start_out       <= '0' ;
      powersave_done            <= '0' ;
      powersave_done_s          <= '0' ;
      marker_out                <= '0' ;
      marker_time_out           <= (others => '0') ;
      req_position_out          <= '0' ;
      req_timemark_out          <= '0' ;
      cur_state                 <= MARK_STATE_INIT_CHECK ;

    elsif (falling_edge (clk)) then
      pulse_timed               <= pulse_timed_s ;
      send_time_mark            <= send_time_mark_s ;
      initialized               <= initialized_s ;
      msgnumber_s               <= msgnumber_in ;
      tempbank                  <= tempbank_s ;
      tmbank                    <= tmbank_s ;
      posbank                   <= posbank_s ;
      memrcv                    <= memrcv_s ;
      continuous_done           <= continuous_done_s ;
      powersave_done            <= powersave_done_s ;

    elsif (rising_edge (clk)) then
      pulse_timed_s             <= pulse_timed_ff ;
      send_time_mark_s          <= send_time_mark_ff ;
      initialized_s             <= initialized_in ;
      tempbank_s                <= tempbank_in ;
      tmbank_s                  <= tmbank_in ;
      posbank_s                 <= posbank_in ;
      memrcv_s                  <= memrcv_in ;
      continuous_done_s         <= continuous_done_in ;
      powersave_done_s          <= powersave_done_in ;

      shift_to                  <= '0' ;
      shift_from                <= '0' ;
      buffer_load               <= '0' ;
      memwrite_en_out           <= '0' ;

      --  Start a new time mark generation sequence.

      if (send_time_mark = '1') then
        time_clear              <= '0' ;
        time_mark_pending       <= '1' ;
        send_time_mark_s        <= '0' ;
        cur_state               <= MARK_STATE_INIT_CHECK ;

      elsif (send_time_mark = '0' and time_mark_pending = '1') then

        case cur_state is

          --  Subroutine like state to load a value from memory into a bit
          --  vector.

          when MARK_STATE_BYTE_LOAD     =>
            shift_to            <= '1' ;
            memdata_to          <= memdata_in ;

            if (byte_count /= 1) then
              byte_count        <= byte_count - 1 ;
              mem_address       <= mem_address + 1 ;
            else
              memread_en_out    <= '0' ;
              cur_state         <= return_state ;
            end if ;

          when MARK_STATE_BYTE_SAVE     =>
            shift_from          <= '1' ;
            memdata_out         <= memdata_from ;
            mem_address         <= mem_address + 1 ;
            memwrite_en_out     <= '1' ;

            if (byte_count /= 1) then
              byte_count        <= byte_count - 1 ;
            else
              cur_state         <= return_state ;
            end if ;

          --  Subroutine like state to determine a time in the future.

          when MARK_STATE_FUTURE        =>
            if (unsigned (curtime.week_millisecond) >=
                millisec_week_c - delay) then

              target_time       <= unsigned (curtime.week_millisecond) -
                                   (millisec_week_c - delay) ;
            else
              target_time       <= unsigned (curtime.week_millisecond) +
                                   delay ;
            end if ;

            cur_state           <= return_state ;

          --  Wait until the initialization system is available and
          --  the GPS has been initialized.

          when MARK_STATE_INIT_CHECK    =>
            if (initialized = '0') then
              cur_state             <= MARK_STATE_INIT_CHECK ;
            else
              cur_state             <= MARK_STATE_CONTINUOUS ;
            end if ;

          --  Put the GPS into continuous mode.

          when MARK_STATE_CONTINUOUS    =>
            continuous_start_out    <= '1' ;

            if (continuous_done = '1') then
              cur_state             <= MARK_STATE_CONTINUOUS ;
            else
              cur_state             <= MARK_STATE_READY ;
            end if ;

          when MARK_STATE_READY         =>
            if (continuous_done = '0') then
              continuous_start_out  <= '0' ;
              cur_state             <= MARK_STATE_READY ;
            else
              last_posbank          <= posbank ;
              delay                 <= TO_UNSIGNED (time_mark_timeout_g,
                                                    delay'length) ;
              return_state          <= MARK_STATE_RUNNING ;
              cur_state             <= MARK_STATE_FUTURE ;
            end if ;

          when MARK_STATE_RUNNING       =>
            if (target_time = unsigned (curtime.week_millisecond)) then
              wait_time_set         <= '1' ;
              cur_state             <= MARK_STATE_SCHEDULE ;
            elsif (last_posbank = posbank) then
              cur_state             <= MARK_STATE_RUNNING ;
            else
              cur_state             <= MARK_STATE_REQMEM ;
            end if ;

          --  Wait until the memory request has been granted before
          --  continuing.

          when MARK_STATE_REQMEM        =>
            memreq_out              <= '1' ;
            cur_state               <= MARK_STATE_RCVMEM ;

          when MARK_STATE_RCVMEM        =>
            if (target_time = unsigned (curtime.week_millisecond)) then
              memreq_out            <= '0' ;
              wait_time_set         <= '1' ;
              cur_state             <= MARK_STATE_SCHEDULE ;
            elsif (memrcv = '1') then
              cur_state             <= MARK_STATE_CHECK ;
            else
              cur_state             <= MARK_STATE_RCVMEM ;
            end if ;

        --  Check how current the GPS position is.  It must always be less
        --  than one week and have been logged since the system started.

          when MARK_STATE_CHECK         =>
            byte_count      <= TO_UNSIGNED (gps_time_bytes_c,
                                            byte_count'length) ;
            mem_address     <= TO_UNSIGNED (msg_ram_base_c +
                                            msg_ram_postime_addr_c +
                                            if_set (posbank,
                                                    msg_ram_postime_size_c),
                                            mem_address'length) ;
            memread_en_out  <= '1' ;
            cur_state       <= MARK_STATE_BYTE_LOAD ;
            return_state    <= MARK_STATE_CHK_CONVERT ;

          when MARK_STATE_CHK_CONVERT   =>
            memread_en_out  <= '0' ;
            logtime         <= TO_GPS_TIME (logtime_bits) ;
            cur_state       <= MARK_STATE_CHK_CURRENT ;

          when MARK_STATE_CHK_CURRENT   =>
            if ((unsigned (logtime.week_number)             = 0 and
                 unsigned (logtime.week_millisecond)        = 0 and
                 unsigned (logtime.millisecond_nanosecond)  = 0)        or
                (unsigned (curtime.week_number) -
                 unsigned (logtime.week_number) > 1) or
                ((curtime.week_number = logtime.week_number) and
                 (unsigned (curtime.week_millisecond) -
                  unsigned (logtime.week_millisecond) > max_pos_age_g)) or
                ((curtime.week_number /= logtime.week_number) and
                 ((unsigned (curtime.week_millisecond) >
                   unsigned (logtime.week_millisecond)) or
                  (unsigned (logtime.week_millisecond) -
                   unsigned (curtime.week_millisecond) <
                      millisec_week_c - max_pos_age_g)))) then

              last_posbank  <= posbank ;
              cur_state     <= MARK_STATE_POS_WAIT ;
            else
              cur_state     <= MARK_STATE_ACCURACY ;
            end if ;

          --  Determine if the accuracy of the position is good enough.

          when MARK_STATE_ACCURACY      =>
            byte_count          <= TO_UNSIGNED (MUNSol_pAcc_size_c,
                                                byte_count'length) ;
            mem_address         <=
                TO_UNSIGNED (msg_ram_base_c +
                             msg_ubx_nav_sol_ramaddr_c +
                             if_set (posbank,
                                     msg_ubx_nav_sol_ramused_c) +
                             MUNSol_pAcc_offset_c,
                             mem_address'length) ;
            memread_en_out      <= '1' ;
            cur_state           <= MARK_STATE_BYTE_LOAD ;
            return_state        <= MARK_STATE_CHK_ACCURACY ;

          when MARK_STATE_CHK_ACCURACY  =>
            memread_en_out      <= '0' ;

            if (unsigned (posacc) > min_pos_accuracy_g) then
              last_posbank      <= posbank ;
              cur_state         <= MARK_STATE_POS_WAIT ;
            else
              req_position_out  <= '0' ;
              retry             <= TO_UNSIGNED (mark_retries_g - 1,
                                                retry'length) ;
              last_millibit     <= curtime.week_millisecond (3) ;
              cur_state         <= MARK_STATE_SUCCESS ;
            end if ;

          --  Generate a time mark.  Wait for 8 millisecond between setting
          --  the time mark line high then back low.  The operation timeout
          --  must be reset as the last one might have passed during this
          --  time mark interval.  Clear the time pulse flip flop and
          --  release it only once time pulse messages are able to be
          --  processed.  If no time pulse messages occur before the next
          --  time pulse that operation will have failed.

          when MARK_STATE_SUCCESS       =>
            memreq_out          <= '0' ;
            time_clear          <= '1' ;
            pulse_timed_s       <= '0' ;

            if (last_millibit /= curtime.week_millisecond (3)) then
              marker_out        <= '1' ;
              cur_state         <= MARK_STATE_MARK ;
            else
              cur_state         <= MARK_STATE_SUCCESS ;
            end if ;

          when MARK_STATE_MARK          =>
            if (last_millibit = curtime.week_millisecond (3)) then
              marker_out        <= '0' ;
              marker_time_out   <= TO_STD_LOGIC_VECTOR (curtime) ;
              last_tmbank       <= tmbank ;
              req_timemark_out  <= '1' ;

              time_clear        <= '0' ;
              time_caught       <= '0' ;
              last_tempbank     <= tempbank ;

              delay             <= TO_UNSIGNED (mark_timeout_g,
                                                delay'length) ;
              return_state      <= MARK_STATE_END ;
              cur_state         <= MARK_STATE_FUTURE ;
            else
              cur_state         <= MARK_STATE_MARK ;
            end if ;

          when MARK_STATE_END           =>
            if (target_time = unsigned (curtime.week_millisecond)) then
              if (retry /= 0) then
                retry           <= retry - 1 ;
                last_millibit   <= curtime.week_millisecond (3) ;
                cur_state       <= MARK_STATE_SUCCESS ;
              else
                wait_time_set   <= '1' ;
                cur_state       <= MARK_STATE_SCHEDULE ;
              end if ;

            elsif (last_tmbank /= tmbank) then
              wait_interval_set <= '1' ;
              cur_state         <= MARK_STATE_SCHEDULE ;

            elsif (pulse_timed = '1') then
              if (time_caught = '0') then
                cur_state       <= MARK_STATE_SUCCESS ;
              else
                memreq_out      <= '1' ;
                cur_state       <= MARK_STATE_SAVE_PULSE ;
              end if ;

            elsif (last_tempbank /= tempbank) then
              last_tempbank     <= tempbank ;
              cur_state         <= MARK_STATE_CHKMSG ;

            else
              cur_state         <= MARK_STATE_END ;
            end if ;

          --  Prossess timepulse messages.

          when MARK_STATE_CHKMSG        =>
            if (unsigned (msgnumber_s) /= msg_ubx_tim_tp_number_c) then
              cur_state         <= MARK_STATE_END ;
            else
              memreq_out        <= '1' ;
              cur_state         <= MARK_STATE_GETWEEK ;
            end if ;

          when MARK_STATE_GETWEEK       =>
            if (memrcv = '1') then
              byte_count        <= TO_UNSIGNED (MUTTp_week_size_c,
                                                byte_count'length) ;
              mem_address       <=
                TO_UNSIGNED (msg_ram_base_c +
                             msg_ram_temp_addr_c +
                             if_set (tempbank,
                                     msg_ram_temp_size_c) +
                             MUTTp_week_offset_c,
                             mem_address'length) ;
              memread_en_out    <= '1' ;
              cur_state         <= MARK_STATE_BYTE_LOAD ;
              return_state      <= MARK_STATE_GETMS ;
            end if ;

          when MARK_STATE_GETMS         =>
            tp_week             <= unsigned (buff_week) ;

            byte_count          <= TO_UNSIGNED (MUTTp_towMS_size_c,
                                                byte_count'length) ;
            mem_address         <=
              TO_UNSIGNED (msg_ram_base_c +
                           msg_ram_temp_addr_c +
                           if_set (tempbank,
                                   msg_ram_temp_size_c) +
                           MUTTp_towMS_offset_c,
                           mem_address'length) ;
            memread_en_out      <= '1' ;
            cur_state           <= MARK_STATE_BYTE_LOAD ;
            return_state        <= MARK_STATE_GETQERR ;

          when MARK_STATE_GETQERR       =>
            tp_milli            <= RESIZE (unsigned (buff_milli),
                                           tp_milli'length) ;

            byte_count          <= TO_UNSIGNED (MUTTp_qErr_size_c,
                                                byte_count'length) ;
            mem_address         <=
              TO_UNSIGNED (msg_ram_base_c +
                           msg_ram_temp_addr_c +
                           if_set (tempbank,
                                   msg_ram_temp_size_c) +
                           MUTTp_qErr_offset_c,
                           mem_address'length) ;
            memread_en_out      <= '1' ;
            cur_state           <= MARK_STATE_BYTE_LOAD ;
            return_state        <= MARK_STATE_CALCTP ;

          when MARK_STATE_CALCTP        =>
            if (tp_qerr_ns < 0) then
              if (tp_qerr_ns < -2e6) then
                caught_time.millisecond_nanosecond
                                <= std_logic_vector (
                                      RESIZE (unsigned (3e6 + tp_qerr_ns),
                                              gps_time_nanobits_c)) ;

                if (tp_milli /= 0) then
                  caught_time.week_number
                                <= std_logic_vector (tp_week) ;
                  caught_time.week_millisecond
                                <= std_logic_vector (tp_milli - 3) ;
                else
                  caught_time.week_number
                                <= std_logic_vector (tp_week - 1) ;
                  caught_time.week_millisecond
                                <= std_logic_vector (
                                      TO_UNSIGNED (millisec_week_c - 3,
                                                   gps_time_millibits_c)) ;
                end if ;
              elsif (tp_qerr_ns < -1e6) then
                caught_time.millisecond_nanosecond
                                <= std_logic_vector (
                                      RESIZE (unsigned (2e6 + tp_qerr_ns),
                                              gps_time_nanobits_c)) ;

                if (tp_milli /= 0) then
                  caught_time.week_number
                                <= std_logic_vector (tp_week) ;
                  caught_time.week_millisecond
                                <= std_logic_vector (tp_milli - 2) ;
                else
                  caught_time.week_number
                                <= std_logic_vector (tp_week - 1) ;
                  caught_time.week_millisecond
                                <= std_logic_vector (
                                      TO_UNSIGNED (millisec_week_c - 2,
                                                   gps_time_millibits_c)) ;
                end if ;
              else
                caught_time.millisecond_nanosecond
                                <= std_logic_vector (
                                      RESIZE (unsigned (1e6 + tp_qerr_ns),
                                              gps_time_nanobits_c)) ;

                if (tp_milli /= 0) then
                  caught_time.week_number
                                <= std_logic_vector (tp_week) ;
                  caught_time.week_millisecond
                                <= std_logic_vector (tp_milli - 1) ;
                else
                  caught_time.week_number
                                <= std_logic_vector (tp_week - 1) ;
                  caught_time.week_millisecond
                                <= std_logic_vector (
                                      TO_UNSIGNED (millisec_week_c - 1,
                                                   gps_time_millibits_c)) ;
                end if ;
              end if ;
            else
              caught_time.week_number
                                <= std_logic_vector (tp_week) ;

              if (tp_qerr_ns >= 2e6) then
                caught_time.millisecond_nanosecond
                                <= std_logic_vector (
                                      RESIZE (unsigned (tp_qerr_ns - 2e6),
                                              gps_time_nanobits_c)) ;
                caught_time.week_millisecond
                                <= std_logic_vector (tp_milli + 2) ;
              elsif (tp_qerr_ns >= 1e6) then
                caught_time.millisecond_nanosecond
                                <= std_logic_vector (
                                      RESIZE (unsigned (tp_qerr_ns - 1e6),
                                              gps_time_nanobits_c)) ;
                caught_time.week_millisecond
                                <= std_logic_vector (tp_milli + 1) ;
              else
                caught_time.millisecond_nanosecond
                                <= std_logic_vector (
                                      RESIZE (unsigned (tp_qerr_ns),
                                              gps_time_nanobits_c)) ;
                caught_time.week_millisecond
                                <= std_logic_vector (tp_milli) ;
              end if ;
            end if ;

            time_caught         <= '1' ;
            memreq_out          <= '0' ;
            cur_state           <= MARK_STATE_END ;

          --  Store the time pulse times.

          when MARK_STATE_SAVE_PULSE    =>
            if (memrcv = '1') then
              pulsetime       <= TO_STD_LOGIC_VECTOR (pulse_time_adj) ;
              buffer_load     <= '1' ;
              byte_count      <= TO_UNSIGNED (gps_time_bytes_c,
                                              byte_count'length) ;
              mem_address     <=
                  TO_UNSIGNED (msg_ram_base_c +
                               msg_ram_pulsetime_addr_c +
                               if_set (not pulsebank,
                                       msg_ram_pulsetime_size_c) - 1,
                               mem_address'length) ;
              cur_state       <= MARK_STATE_BYTE_SAVE ;
              return_state    <= MARK_STATE_SAVE_TPMSG ;
            end if ;

          when MARK_STATE_SAVE_TPMSG    =>
            pulsetime           <= TO_STD_LOGIC_VECTOR (caught_time) ;
            buffer_load         <= '1' ;
            byte_count          <= TO_UNSIGNED (gps_time_bytes_c,
                                                byte_count'length) ;
            mem_address         <=
                TO_UNSIGNED (msg_ram_base_c +
                             msg_ram_pulsetime_addr_c +
                             if_set (not pulsebank,
                                     msg_ram_pulsetime_size_c) +
                             gps_time_bytes_c - 1,
                             mem_address'length) ;
            cur_state           <= MARK_STATE_BYTE_SAVE ;
            return_state        <= MARK_STATE_CAPTURED ;

          when MARK_STATE_CAPTURED       =>
            pulsebank           <= not pulsebank ;
            memreq_out          <= '0' ;
            wait_interval_set   <= '1' ;
            cur_state           <= MARK_STATE_SCHEDULE ;

          --  Exit the state machine after a new time mark has been
          --  scheduled.

          when MARK_STATE_SCHEDULE      =>
            req_timemark_out        <= '0' ;
            wait_time_set           <= '0' ;
            wait_interval_set       <= '0' ;
            powersave_start_out     <= '1' ;
            cur_state               <= MARK_STATE_DONE ;

          when MARK_STATE_DONE          =>

            if (powersave_done = '0') then
              powersave_start_out   <= '0' ;
              time_mark_pending     <= '0' ;
            end if ;

            cur_state               <= MARK_STATE_DONE ;

          --  Wait until a new position has been received and then check
          --  it out.  When the bank the position data is stored in changes,
          --  new information has been stored in that bank.

          when MARK_STATE_POS_WAIT      =>
            memreq_out            <= '0' ;
            req_position_out      <= '1' ;

            if (target_time = unsigned (curtime.week_millisecond)) then
              req_position_out    <= '0' ;
              wait_time_set       <= '1' ;
              cur_state           <= MARK_STATE_SCHEDULE ;
            elsif (posbank /= last_posbank) then
              req_position_out    <= '0' ;
              cur_state           <= MARK_STATE_REQMEM ;
            else
              cur_state           <= MARK_STATE_POS_WAIT ;
            end if ;

        end case ;
      end if ;
    end if ;
  end process marker_pending ;


end architecture rtl ;
