----------------------------------------------------------------------------
--
--! @file       OnOffcheduler.vhd
--! @brief      Schedule the system's on and off times.
--! @details    Set the alarm to the time to turn the system on and turn
--!             the system off when the off time has been reached, and
--!             schedule the off time when in an operation window.
--! @author     Emery Newlon
--! @date       September 2016
--! @copyright  Copyright (C) 2016 Ross K. Snider and Emery L. Newlon
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

library GENERAL ;
use GENERAL.Utilities_pkg.all ;     --  General purpose definitons.
use GENERAL.GPS_Clock_pkg.all ;     --  GPS clock definitions.
use GENERAL.FormatSeconds_pkg.all ; --  Local time definitions.


----------------------------------------------------------------------------
--
--! @brief      System On/Off Scheduler.
--! @details    Set the alarm to the time to turn the system on and turn
--!             the system off when the off time has been reached, and
--!             schedule the off time when in an operation window.
--!
--! @param      sched_count_g     Number of scheduler IDs there are.
--! @param      turnoff_id_g      ID of the turnoff request.
--! @param      alarm_bytes_g     Number of bytes of alarm seconds.
--! @param      on_off_times_g    Array of on/off time ranges.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move through states in the
--!                               entity and its components.
--! @param      localtime_in      Local time in hrs/min/sec format.
--! @param      clockchg_in       The local time has jumped to a new value.
--! @param      startup_in        System startup for the Trx.
--! @param      startup_out       The Trx has been started.
--! @param      shutdown_in       System shutdown for the Trx.
--! @param      shutdown_out      The Trx has shut down.
--! @param      off_in            Signal to turn the system off.
--! @param      off_out           Turn the system off now.
--! @param      alarm_set_in      The alarm has been set.
--! @param      alarm_set_out     Set the alarm to the new alarm value.
--! @param      alarm_out         New alarm value in seconds from now.
--! @param      sched_req_out     Request access to the scheduler.
--! @param      sched_rcv_in      Access to the scheduler granted.
--! @param      sched_type_out    Scheduler request is add/change or delete.
--! @param      sched_id_out      Scheduler ID to use for this request.
--! @param      sched_delay_out   Seconds to wait before signalling request.
--! @param      sched_start_in    Status of scheduling the request.
--! @param      sched_start_out   Start scheduling the request.
--! @param      busy_out          The entity is busy processing.
--
----------------------------------------------------------------------------

entity OnOffScheduler is

  Generic (
    sched_count_g     : natural := 8 ;
    turnoff_id_g      : natural := 0 ;
    alarm_bytes_g     : natural := 3 ;
    on_off_times_g    : HM_range_vector_t := school_day_HMR_c
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    localtime_in      : in    std_logic_vector (dt_totalbits_c-1 downto 0) ;
    clockchg_in       : in    std_logic ;
    startup_in        : in    std_logic ;
    startup_out       : out   std_logic ;
    shutdown_in       : in    std_logic ;
    shutdown_out      : out   std_logic ;
    off_in            : in    std_logic ;
    off_out           : out   std_logic ;
    alarm_set_in      : in    std_logic ;
    alarm_set_out     : out   std_logic ;
    alarm_out         : out   std_logic_vector (alarm_bytes_g*8-1 downto 0) ;
    sched_req_out     : out   std_logic ;
    sched_rcv_in      : in    std_logic ;
    sched_type_out    : out   std_logic ;
    sched_id_out      : out   unsigned (const_bits (sched_count_g-1)-1
                                        downto 0) ;
    sched_delay_out   : out
          unsigned (const_bits (millisec_week_c / 1000 - 1)-1 downto 0) ;
    sched_start_in    : in    std_logic ;
    sched_start_out   : out   std_logic ;
    busy_out          : out   std_logic
  ) ;

end entity OnOffScheduler ;


architecture rtl of OnOffScheduler is

  --  Signal catchers.  The signal may be shorter than the clock period
  --  used for this entity.  An asynchronous SR flip flop will still be
  --  able to catch the signal.

  signal clock_changed      : std_logic ;
  signal clock_changed_set  : std_logic ;
  signal clockchg_started   : std_logic ;
  signal startup            : std_logic ;
  signal startup_started    : std_logic ;
  signal shutdown           : std_logic ;
  signal shutdown_started   : std_logic ;
  signal running            : std_logic ;
  signal turnoff            : std_logic ;
  signal turnoff_started    : std_logic ;
  signal alarm_set_started  : std_logic ;
  signal alarm_set_clear    : std_logic ;
  signal alarm_set_finished : std_logic ;
  signal alarm_set_done     : std_logic ;

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

  --  Timing signals.

  constant day_hours_c      : natural := 24 ;
  constant day_minutes_c    : natural := 24 * 60 ;
  constant day_seconds_c    : natural := 24 * 60 * 60 ;
  constant hour_minutes_c   : natural := 60 ;
  constant hour_seconds_c   : natural := 60 * 60 ;
  constant min_seconds_c    : natural := 60 ;

  signal local_time         : DateTime_t ;
  signal cur_year           : unsigned (dt_yearbits_c-1 downto 0) ;
  signal cur_yday           : unsigned (dt_ydaybits_c-1 downto 0) ;
  signal cur_hour           : unsigned (dt_hourbits_c-1 downto 0) ;
  signal cur_minute         : unsigned (dt_minbits_c-1 downto 0) ;
  signal cur_second         : unsigned (dt_secbits_c-1 downto 0) ;
  signal last_dst           : std_logic := '0' ;

  signal last_year          : unsigned (dt_yearbits_c-1 downto 0) ;
  signal last_yday          : unsigned (dt_ydaybits_c-1 downto 0) ;

  signal update_timing      : std_logic ;
  signal timing_changed     : std_logic ;

  signal cur_range          : HourMinuteRange_t ;
  signal next_range         :
            unsigned (const_bits (on_off_times_g'length)-1 downto 0) ;

  --  Scheduling States.

  type SchedulerState is   (
    SCHED_STATE_WAIT,
    SCHED_STATE_UPDTURNOFF,
    SCHED_STATE_TURNOFF,
    SCHED_STATE_ALARM,
    SCHED_STATE_DELAY,
    SCHED_STATE_DONE
  ) ;

  signal cur_state        : SchedulerState ;

  --  Entity busy indicators.

  signal process_busy     : std_logic := '0' ;

begin

  --  Convert the local time from a vector into a record.

  local_time                <= TO_DATE_TIME (localtime_in) ;

  --  Catch the clock change, startup, shutdown, and turnoff signals.
  --  The signals may be shorter than the clock period used for this entity.
  --  An asynchronous SR flip flop will still be able to catch the signal.

  clock_changed_set         <= clockchg_in or
                               (last_dst   xor local_time.indst) ;

  clock_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => clockchg_started,
      set_in                => clock_changed_set,
      result_rd_out         => clock_changed
    ) ;

  turnoff_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => turnoff_started,
      set_in                => off_in,
      result_rd_out         => turnoff
    ) ;

  startup_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => startup_started,
      set_in                => startup_in,
      result_rd_out         => startup
    ) ;

  shutdown_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => shutdown_started,
      set_in                => shutdown_in,
      result_rd_out         => shutdown
    ) ;

  --  RTC Alarm setting flip-flops.  The RTC Alarm set may run at a much
  --  faster clock speed than this entity.  The set alarm and alarm set done
  --  lines need to be able to handle this speed.  To insure this they are
  --  driven by the alarm setting clock via SR flip-flops.

  alarm_set_clear           <= alarm_set_in or reset ;
  alarm_set_finished        <= not alarm_set_started ;

  alarm_set : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => alarm_set_clear,
      set_in                => alarm_set_started,
      result_rd_out         => alarm_set_out
    ) ;

  alarm_done : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => alarm_set_finished,
      set_in                => alarm_set_in,
      result_rd_out         => alarm_set_done
    ) ;

  --  Entity busy.

  busy_out          <= startup or shutdown or process_busy or
                       (running and (timing_changed or turnoff)) ;

  --  Timing has changed.

  timing_changed    <= clock_changed or update_timing ;


  --------------------------------------------------------------------------
  --  Schedule and handle events.
  --------------------------------------------------------------------------

  scheduler :  process (reset, clk)
  begin
    if (reset = '1') then
      clockchg_started      <= '1' ;
      update_timing         <= '1' ;
      turnoff_started       <= '1' ;
      alarm_set_started     <= '0' ;
      startup_started       <= '1' ;
      running               <= '0' ;
      shutdown_started      <= '1' ;
      off_out               <= '0' ;
      startup_out           <= '0' ;
      shutdown_out          <= '0' ;
      last_year             <= (others => '0') ;
      last_yday             <= (others => '0') ;
      cur_range             <= on_off_times_g (0) ;
      next_range            <= TO_UNSIGNED (1, next_range'length) ;
      sched_req_out         <= '0' ;
      sched_type_out        <= '0' ;
      sched_id_out          <= (others => '0') ;
      sched_delay_out       <= (others => '0') ;
      sched_start_out       <= '0' ;
      process_busy          <= '1' ;
      cur_state             <= SCHED_STATE_WAIT ;

    elsif (rising_edge (clk)) then

      --  Initialization states.

      case (cur_state) is

        --  Wait until an action is required.

        when SCHED_STATE_WAIT       =>
          turnoff_started       <= '0' ;
          startup_started       <= '0' ;
          shutdown_started      <= '0' ;
          clockchg_started      <= '0' ;
          shutdown_out          <= '0' ;

          --  Shutdown requests do nothing.  Startup causes a timing change
          --  action to be take.  No other actions are taken until the
          --  device is started.

          if (shutdown = '1') then
            shutdown_out        <= '1' ;
            startup_out         <= '0' ;
            off_out             <= '0' ;
            shutdown_started    <= '1' ;
            running             <= '0' ;
            process_busy        <= '1' ;

          elsif (startup = '1') then
            startup_out         <= '1' ;
            startup_started     <= '1' ;
            running             <= '1' ;
            update_timing       <= '1' ;
            process_busy        <= '1' ;

          elsif (running = '0') then
            process_busy        <= '0' ;

          --  Reset the scheduled events after clock changes and when
          --  comming out of reset.

          elsif (timing_changed = '1') then
            clockchg_started    <= '1' ;
            update_timing       <= '0' ;
            turnoff_started     <= '1' ;
            cur_range           <= on_off_times_g (0) ;
            next_range          <= TO_UNSIGNED (1, next_range'length) ;
            last_dst            <= local_time.indst ;
            cur_year            <= local_time.year ;
            cur_yday            <= local_time.yday ;
            cur_hour            <= local_time.hour ;
            cur_minute          <= local_time.minute ;
            cur_second          <= local_time.second ;
            cur_state           <= SCHED_STATE_UPDTURNOFF ;
            process_busy        <= '1' ;

          --  Turn off the system.

          elsif (turnoff = '1') then
            cur_hour            <= local_time.hour ;
            cur_minute          <= local_time.minute ;
            cur_second          <= local_time.second ;
            process_busy        <= '1' ;
            turnoff_started     <= '1' ;
            cur_state           <= SCHED_STATE_TURNOFF ;

          --  Go back to sleep.

          else
            process_busy        <= '0' ;
            cur_state           <= SCHED_STATE_WAIT ;
          end if ;

        --  Update the send event wait for the new local time.

        when SCHED_STATE_UPDTURNOFF =>

          --  Progressively check range entries until current time
          --  is reached.  When the end of the current day is reached
          --  turn off the system.

          if (cur_year /= last_year or cur_yday /= last_yday) then
            last_year               <= cur_year ;
            last_yday               <= cur_yday ;
            cur_range               <= on_off_times_g (0) ;
            next_range              <= TO_UNSIGNED (1, next_range'length) ;

          elsif (cur_hour    >  cur_range.end_hour   or
                 (cur_hour   =  cur_range.end_hour  and
                  cur_minute >= cur_range.end_minute)) then

            if (next_range = on_off_times_g'length) then
              cur_state             <= SCHED_STATE_TURNOFF ;
            else
              cur_range             <=
                    on_off_times_g (TO_INTEGER (next_range)) ;
              next_range            <= next_range + 1 ;
            end if ;

          --  Not yet in the next range.  Shutdown the system until then.

          elsif (cur_hour      < cur_range.str_hour    or
                 (cur_hour     = cur_range.str_hour   and
                  cur_minute   < cur_range.str_minute)) then
            cur_state               <= SCHED_STATE_TURNOFF ;

          --  In the current range.  Schedule turn off when this range ends.

          elsif (sched_rcv_in = '0') then
            sched_req_out           <= '1' ;

          else
            if (cur_minute > cur_range.end_minute) then
              sched_delay_out     <=
                RESIZE ((cur_range.end_hour - 1 - cur_hour) *
                        const_unsigned (hour_seconds_c, 1) +
                        (cur_range.end_minute +
                         (hour_minutes_c - cur_minute)) *
                        const_unsigned (min_seconds_c, 1) - cur_second,
                        sched_delay_out'length) ;
            else
              sched_delay_out     <=
                RESIZE ((cur_range.end_hour - cur_hour) *
                        const_unsigned (hour_seconds_c, 1) +
                        (cur_range.end_minute - cur_minute) *
                        const_unsigned (min_seconds_c, 1) - cur_second,
                        sched_delay_out'length) ;
            end if ;

            if (next_range /= on_off_times_g'length) then
              cur_range             <=
                    on_off_times_g (TO_INTEGER (next_range)) ;
              next_range            <= next_range + 1 ;
            end if ;

            --  Schedule the event.

            sched_type_out          <= '1' ;
            sched_id_out            <= TO_UNSIGNED (turnoff_id_g,
                                                    sched_id_out'length) ;
            sched_start_out         <= '1' ;
            cur_state               <= SCHED_STATE_DELAY ;
          end if ;

        --  Wait for the scheduling operation to complete.

        when SCHED_STATE_DELAY      =>
          if (sched_start_in = '1') then
            sched_start_out   <= '0' ;
            cur_state         <= SCHED_STATE_DONE ;
          end if ;

        when SCHED_STATE_DONE       =>
          if (sched_rcv_in = '0') then
            cur_state         <= SCHED_STATE_WAIT ;
          elsif (sched_start_in = '0') then
            sched_req_out     <= '0' ;
          end if ;

        --  Turn off the system.  Until the next start time even if it is
        --  the next day.

        when SCHED_STATE_TURNOFF    =>
          if (cur_hour    >  cur_range.end_hour or
              (cur_hour   =  cur_range.end_hour and
               cur_minute >= cur_range.end_minute)) then

            alarm_out         <= std_logic_vector (
                RESIZE ((on_off_times_g (0).str_hour +
                         (day_hours_c - 1 - cur_hour)) *
                        const_unsigned (hour_seconds_c, 1) +
                        (on_off_times_g (0).str_minute +
                         (hour_minutes_c - 1 - cur_minute)) *
                        const_unsigned (min_seconds_c, 1) +
                        (min_seconds_c - cur_second),
                        alarm_out'length)) ;

          elsif (cur_minute > cur_range.str_minute) then
            alarm_out         <= std_logic_vector (
                RESIZE ((cur_range.str_hour - 1 - cur_hour) *
                        const_unsigned (hour_seconds_c, 1) +
                        (cur_range.str_minute +
                         (hour_minutes_c - cur_minute)) *
                        const_unsigned (min_seconds_c, 1) - cur_second,
                        alarm_out'length)) ;

          else
            alarm_out         <= std_logic_vector (
                RESIZE ((cur_range.str_hour - cur_hour) *
                        const_unsigned (hour_seconds_c, 1) +
                        (cur_range.str_minute - cur_minute) *
                        const_unsigned (min_seconds_c, 1) - cur_second,
                        alarm_out'length)) ;
          end if ;

          alarm_set_started   <= '1' ;
          cur_state           <= SCHED_STATE_ALARM ;

        when SCHED_STATE_ALARM    =>
          if (alarm_set_done = '1') then
            alarm_set_started <= '0' ;
            off_out           <= '1' ;
            cur_state         <= SCHED_STATE_WAIT ;
          end if ;

      end case ;
    end if ;
  end process scheduler ;

end architecture rtl ;
