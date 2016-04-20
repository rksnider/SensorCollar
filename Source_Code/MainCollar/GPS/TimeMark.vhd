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


----------------------------------------------------------------------------
--
--! @brief      Initiates a Time Mark event.
--! @details    When the GPS is maintaining good positional and time
--!             information, periodically initiate a time mark event.
--!
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
--! @param      curtime_in            Current time in GPS format.
--! @param      curtime_latch_in      Latch curtime across clock domains.
--! @param      curtime_valid_in      Latched curtime is valid when set.
--! @param      curtime_vlatch_in     Latch curtime when valid not set.
--! @param      initilized_in         Set when the GPS has been initialized.
--! @param      posbank_in            Position information memory bank.
--! @param      tmbank_in             Time mark information memory bank.
--! @param      memreq_out            Access to the memory bus requested.
--! @param      memrcv_in             Request for the memory bus is granted.
--! @param      memaddr_out           Address of the byte of memory to read.
--! @param      memdata_in            Data byte of memory that is addressed.
--! @param      memread_en_out        Enable the memory for reading.
--! @param      continuous_start_out  Put the GPS into continuous fix mode.
--! @param      continuous_done_in    GPS in continuous fix mode.
--! @param      powersave_start_out   Put the GPS into powersave fix mode.
--! @param      powersave_done_in     GPS in powersave fix mode.
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
    curtime_in            : in    std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    curtime_latch_in      : in    std_logic ;
    curtime_valid_in      : in    std_logic ;
    curtime_vlatch_in     : in    std_logic ;


    initialized_in        : in    std_logic ;
    posbank_in            : in    std_logic ;
    tmbank_in             : in    std_logic ;
    memreq_out            : out   std_logic ;
    memrcv_in             : in    std_logic ;
    memaddr_out           : out   std_logic_vector (memaddr_bits_g-1
                                                    downto 0) ;
    memdata_in            : in    std_logic_vector (7 downto 0) ;
    memread_en_out        : out   std_logic ;
    continuous_start_out  : out   std_logic ;
    continuous_done_in    : in    std_logic ;
    powersave_start_out   : out   std_logic ;
    powersave_done_in     : in    std_logic ;
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

  --  Time Mark Generation States.

  type TimeMarkState is   (
    MARK_STATE_BYTE_LOAD,
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
    MARK_STATE_SCHEDULE,
    MARK_STATE_DONE
  ) ;

  signal cur_state        : TimeMarkState ;
  signal return_state     : TimeMarkState ;

  --  Output signals that must be read.

  signal mem_address        : unsigned (memaddr_bits_g-1 downto 0) ;

  --  GPS time must be converted from standard logic vector to GPS time
  --  record structure.

  signal curtime_slv        : std_logic_vector (gps_time_bits_c-1 downto 0) ;
  signal curtime            : GPS_Time ;
  signal intime             : GPS_Time ;

  --  Time mark scheduling information.

  signal time_mark_clock    : std_logic ;
  signal time_mark_target   : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal delay              : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal target_time        : unsigned (gps_time_millibits_c-1 downto 0) ;
  signal retry              : unsigned (const_bits (mark_retries_g) - 1
                                        downto 0) ;

  signal send_time_mark     : std_logic ;
  signal time_mark_pending  : std_logic ;

  signal last_millibit      : std_logic ;

  --  Time conversion values.

  signal logtime            : GPS_Time ;

  --  Poll completed information.

  signal last_posbank       : std_logic ;
  signal last_tmbank        : std_logic ;

  --  Scratch area used for loading/storing bit vectors to/from
  --  memory.  Each signal using it is defined via an alias.

  constant byte_length_tbl_c : integer_vector :=
      (gps_time_bytes_c, MUNSol_pAcc_size_c) ;

  constant byte_buffer_bytes_c    : natural :=
      max_integer (byte_length_tbl_c) ;

  signal byte_buffer            : std_logic_vector (byte_buffer_bytes_c*8-1
                                                    downto 0) ;

  signal byte_count             :
      unsigned (const_bits (byte_buffer_bytes_c)-1 downto 0) ;

  alias  logtime_bits           :
      std_logic_vector (gps_time_bits_c-1 downto 0) is
      byte_buffer      (byte_buffer_bytes_c*8 - gps_time_bytes_c*8 +
                        gps_time_bits_c-1
                        downto
                        byte_buffer_bytes_c*8 - gps_time_bytes_c*8) ;

  alias  posacc                 :
      std_logic_vector (MUNSol_pAcc_size_c*8-1 downto 0) is
      byte_buffer      (byte_buffer_bytes_c*8-1
                        downto
                        byte_buffer_bytes_c*8 - MUNSol_pAcc_size_c*8) ;


begin

  --  Pass the memory address out of the entity.

  memaddr_out       <= std_logic_vector (mem_address) ;

  --  Set the busy indicator.

  busy_out          <= send_time_mark or time_mark_pending ;

  --  Capture the most recent current time possible from across clock
  --  domains.  The driving clock is inverted so that it will capture the
  --  time on the rising edge (rather than falling edge normally done) to
  --  produce the most recent possible clock when it is captured as the
  --  captured time is not used for a full clock cycle.  Otherwise the
  --  captured time would be half a local (slow) clock cycle before the
  --  time mark line was pulled low.

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

  intime            <= TO_GPS_TIME (curtime_in) ;
  curtime           <= TO_GPS_TIME (curtime_slv) ;

  --  Produce a millisecond clock from the current time.

  time_mark_clock   <=
      intime.millisecond_nanosecond (gps_time_nanobits_c-1) ;


  --------------------------------------------------------------------------
  --  Wait until the next time for a marker has arrived.
  --------------------------------------------------------------------------

  marker_alarm : process (reset, time_mark_clock)
  begin
    if (reset = '1') then
      req_timemark_out      <= '0' ;
      send_time_mark        <= '0' ;

    elsif (rising_edge (time_mark_clock)) then

      --  Order time mark generation when the time has arrived for one
      --  until that operation has started.

      if (time_mark_target = unsigned (intime.week_millisecond)) then
        send_time_mark      <= '1' ;

      elsif (time_mark_pending = '1') then
        send_time_mark      <= '0' ;

      end if ;
    end if ;
  end process marker_alarm ;


  --------------------------------------------------------------------------
  --  Handle pending time mark requests.
  --------------------------------------------------------------------------

  marker_pending : process (reset, clk)
  begin
    if (reset = '1') then
      time_mark_pending         <= '1' ;
      memreq_out                <= '0' ;
      mem_address               <= (others => '0') ;
      memread_en_out            <= '0' ;
      time_mark_target          <= (others => '0') ;
      continuous_start_out      <= '0' ;
      powersave_start_out       <= '0' ;
      marker_out                <= '0' ;
      marker_time_out           <= (others => '0') ;
      last_posbank              <= '0' ;
      last_tmbank               <= '0' ;
      req_position_out          <= '0' ;
      cur_state                 <= MARK_STATE_INIT_CHECK ;

    elsif (rising_edge (clk)) then

      --  Start a new time mark generation sequence.

      if (send_time_mark = '1') then
        time_mark_pending       <= '1' ;
        cur_state               <= MARK_STATE_INIT_CHECK ;

      elsif (send_time_mark = '0' and time_mark_pending = '1') then

        case cur_state is

          --  Subroutine like state to load a value from memory into a bit
          --  vector.

          when MARK_STATE_BYTE_LOAD     =>
            if (byte_count /= 0) then
              byte_count        <= byte_count - 1 ;

              byte_buffer       <= memdata_in &
                                   byte_buffer (byte_buffer_bytes_c*8-1
                                                downto 8) ;
              mem_address       <= mem_address + 1 ;
              cur_state         <= MARK_STATE_BYTE_LOAD ;
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
            if (initialized_in = '0') then
              cur_state             <= MARK_STATE_INIT_CHECK ;
            else
              cur_state             <= MARK_STATE_CONTINUOUS ;
            end if ;

          --  Put the GPS into continuous mode.

          when MARK_STATE_CONTINUOUS    =>
            continuous_start_out    <= '1' ;

            if (continuous_done_in = '1') then
              cur_state             <= MARK_STATE_CONTINUOUS ;
            else
              cur_state             <= MARK_STATE_READY ;
            end if ;

          when MARK_STATE_READY         =>
            if (continuous_done_in = '0') then
              continuous_start_out  <= '0' ;
              cur_state             <= MARK_STATE_READY ;
            else
              last_posbank          <= posbank_in ;
              delay                 <= TO_UNSIGNED (time_mark_timeout_g,
                                                    delay'length) ;
              return_state          <= MARK_STATE_RUNNING ;
              cur_state             <= MARK_STATE_FUTURE ;
            end if ;

          when MARK_STATE_RUNNING       =>
            if (target_time = unsigned (curtime.week_millisecond)) then
              delay                 <= TO_UNSIGNED (time_mark_wait_g,
                                                    delay'length) ;
              cur_state             <= MARK_STATE_SCHEDULE ;
            elsif (last_posbank = posbank_in) then
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
              delay                 <= TO_UNSIGNED (time_mark_wait_g,
                                                    delay'length) ;
              cur_state             <= MARK_STATE_SCHEDULE ;
            elsif (memrcv_in = '1') then
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
                                            if_set (posbank_in,
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

              last_posbank  <= posbank_in ;
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
                             if_set (posbank_in,
                                     msg_ubx_nav_sol_ramused_c) +
                             MUNSol_pAcc_offset_c,
                             mem_address'length) ;
            memread_en_out      <= '1' ;
            cur_state           <= MARK_STATE_BYTE_LOAD ;
            return_state        <= MARK_STATE_CHK_ACCURACY ;

          when MARK_STATE_CHK_ACCURACY  =>
            memread_en_out      <= '0' ;

            if (unsigned (posacc) > min_pos_accuracy_g) then
              last_posbank      <= posbank_in ;
              cur_state         <= MARK_STATE_POS_WAIT ;
            else
              req_position_out  <= '0' ;
              retry             <= TO_UNSIGNED (mark_retries_g - 1,
                                                retry'length) ;
              last_millibit     <= curtime.week_millisecond (8) ;
              cur_state         <= MARK_STATE_SUCCESS ;
            end if ;

          --  Generate a time mark.  Wait for 8 millisecond between setting
          --  the time mark line high then back low.  The operation timeout
          --  must be reset as the last one might have passed during this
          --  time mark interval.

          when MARK_STATE_SUCCESS       =>
            memreq_out          <= '0' ;

            if (last_millibit /= curtime.week_millisecond (8)) then
              marker_out        <= '1' ;
              cur_state         <= MARK_STATE_MARK ;
            else
              cur_state         <= MARK_STATE_SUCCESS ;
            end if ;

          when MARK_STATE_MARK          =>
            if (last_millibit = curtime.week_millisecond (8)) then
              marker_out        <= '0' ;
              marker_time_out   <= TO_STD_LOGIC_VECTOR (curtime) ;
              last_tmbank       <= tmbank_in ;
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
                last_millibit   <= curtime.week_millisecond (8) ;
                cur_state       <= MARK_STATE_SUCCESS ;
              else
                delay           <= TO_UNSIGNED (time_mark_wait_g,
                                                delay'length) ;
                cur_state       <= MARK_STATE_SCHEDULE ;
              end if ;
            elsif (last_tmbank /= tmbank_in) then
              delay             <= TO_UNSIGNED (time_mark_interval_g,
                                                delay'length) ;
              cur_state         <= MARK_STATE_SCHEDULE ;
            else
              cur_state         <= MARK_STATE_END ;
            end if ;

          --  Exit the state machine and schedule a new time mark.

          when MARK_STATE_SCHEDULE      =>
            powersave_start_out <= '1' ;
            return_state        <= MARK_STATE_DONE ;
            cur_state           <= MARK_STATE_FUTURE ;

          when MARK_STATE_DONE          =>
            if (powersave_done_in = '0') then
              powersave_start_out   <= '0' ;
              time_mark_target      <= target_time ;
              time_mark_pending     <= '0' ;
            end if ;

            cur_state           <= MARK_STATE_DONE ;

          --  Wait until a new position has been received and then check
          --  it out.  When the bank the position data is stored in changes,
          --  new information has been stored in that bank.

          when MARK_STATE_POS_WAIT      =>
            memreq_out            <= '0' ;
            req_position_out      <= '1' ;

            if (target_time = unsigned (curtime.week_millisecond)) then
              req_position_out    <= '0' ;
              delay               <= TO_UNSIGNED (time_mark_wait_g,
                                                  delay'length) ;
              cur_state           <= MARK_STATE_SCHEDULE ;
            elsif (posbank_in /= last_posbank) then
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
