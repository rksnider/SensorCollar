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
use GENERAL.Utilities_pkg.all ;     --  General purpose definitions.
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
--! @param      on_off_count_g    Number of on/off time ranges used.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move through states in the
--!                               entity and its components.
--! @param      rtctime_in        Current time in Epoch 70 time in seconds.
--! @param      timingchg_in      Changes when the local time has jumped to
--!                               a new value or the on/off times have
--!                               changed.  This is a toggle not a level
--!                               based signal.
--! @param      startup_in        System startup for the Trx.
--! @param      startup_out       The Trx has been started.
--! @param      shutdown_in       System shutdown for the Trx.
--! @param      shutdown_out      The Trx has shut down.
--! @param      off_in            Signal to turn the system off.
--! @param      off_out           Turn the system off now.
--! @param      on_off_times_in   Array of on/off time ranges.
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
    on_off_count_g    : natural := 4
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    rtctime_in        : in    unsigned (Epoch70_secbits_c-1 downto 0) ;
    timingchg_in      : in    std_logic ;
    startup_in        : in    std_logic ;
    startup_out       : out   std_logic ;
    shutdown_in       : in    std_logic ;
    shutdown_out      : out   std_logic ;
    off_in            : in    std_logic ;
    off_out           : out   std_logic ;
    on_off_times_in   : in    std_logic_vector (E70_rangebits_c *
                                                on_off_count_g-1 downto 0) ;
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

  signal timingchg          : std_logic ;
  signal timingchg_started  : std_logic ;
  signal timingchg_ff       : std_logic ;
  signal timingchg_s        : std_logic ;
  signal startup            : std_logic ;
  signal startup_started    : std_logic ;
  signal startup_ff         : std_logic ;
  signal startup_s          : std_logic ;
  signal shutdown           : std_logic ;
  signal shutdown_started   : std_logic ;
  signal shutdown_ff        : std_logic ;
  signal shutdown_s         : std_logic ;
  signal running            : std_logic ;
  signal turnoff            : std_logic ;
  signal turnoff_started    : std_logic ;
  signal turnoff_ff         : std_logic ;
  signal turnoff_s          : std_logic ;
  signal sched_rcv          : std_logic ;
  signal sched_rcv_s        : std_logic ;
  signal sched_start        : std_logic ;
  signal sched_start_s      : std_logic ;
  signal sched_start_ff     : std_logic ;
  signal sched_start_clear  : std_logic ;
  signal alarm_set_started  : std_logic ;
  signal alarm_set_clear    : std_logic ;
  signal alarm_set_finished : std_logic ;
  signal alarm_set_done     : std_logic ;
  signal alarm_set_ff       : std_logic ;
  signal alarm_set_s        : std_logic ;

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

  signal timingchg_fwl      : std_logic ;
  signal timingchg_set      : std_logic ;

  signal update_timing      : std_logic ;
  signal timing_changed     : std_logic ;

  signal cur_time           : unsigned (rtctime_in'length-1 downto 0) ;

  signal on_off_times       : E70_range_vector_t (0 to on_off_count_g-1) ;
  signal cur_range          : Epoch70Range_t ;
  signal next_range         :
            unsigned (const_bits (on_off_count_g)-1 downto 0) ;

  signal turnon_time        : unsigned (alarm_out'length-1 downto 0) ;

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

  --  Convert the on/off times from a vector into a range array.

  on_off_times              <= TO_E70_RANGE (on_off_times_in) ;

  --  Catch the clock change, startup, shutdown, and turnoff signals.
  --  The signals may be shorter than the clock period used for this entity.
  --  An asynchronous SR flip flop will still be able to catch the signal.

  timingchg_set             <= timingchg_in xor timingchg_fwl ;

  clock_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => timingchg_started,
      set_in                => timingchg_set,
      result_rd_out         => timingchg_ff
    ) ;

  turnoff_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => turnoff_started,
      set_in                => off_in,
      result_rd_out         => turnoff_ff
    ) ;

  startup_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => startup_started,
      set_in                => startup_in,
      result_rd_out         => startup_ff
    ) ;

  shutdown_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => shutdown_started,
      set_in                => shutdown_in,
      result_rd_out         => shutdown_ff
    ) ;

  sched_stat_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => sched_start_clear,
      set_in                => sched_start_in,
      result_rd_out         => sched_start_ff
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
      result_rd_out         => alarm_set_ff
    ) ;

  --  Entity busy.

  busy_out          <= startup or shutdown or process_busy or
                       (running and (timing_changed or turnoff)) ;

  --  Timing has changed.

  timing_changed    <= timingchg or update_timing ;


  --------------------------------------------------------------------------
  --  Schedule and handle events.
  --------------------------------------------------------------------------

  scheduler :  process (reset, clk)
  begin
    if (reset = '1') then
      timingchg_fwl         <= '0' ;
      timingchg_started     <= '1' ;
      timingchg_s           <= '0' ;
      timingchg             <= '0' ;
      update_timing         <= '1' ;
      turnoff_started       <= '1' ;
      turnoff_s             <= '0' ;
      turnoff               <= '0' ;
      alarm_set_started     <= '0' ;
      alarm_set_s           <= '0' ;
      startup_started       <= '1' ;
      startup_s             <= '0' ;
      startup               <= '0' ;
      running               <= '0' ;
      shutdown_started      <= '1' ;
      shutdown_s            <= '0' ;
      shutdown              <= '0' ;
      sched_rcv_s           <= '0' ;
      sched_rcv             <= '0' ;
      sched_start_s         <= '0' ;
      sched_start           <= '0' ;
      sched_start_clear     <= '1' ;
      off_out               <= '0' ;
      startup_out           <= '0' ;
      shutdown_out          <= '0' ;
      next_range            <= TO_UNSIGNED (1, next_range'length) ;
      sched_req_out         <= '0' ;
      sched_type_out        <= '0' ;
      sched_id_out          <= (others => '0') ;
      sched_delay_out       <= (others => '0') ;
      sched_start_out       <= '0' ;
      process_busy          <= '1' ;
      cur_state             <= SCHED_STATE_WAIT ;

    elsif (falling_edge (clk)) then
      turnoff               <= turnoff_s ;
      startup               <= startup_s ;
      shutdown              <= shutdown_s ;
      timingchg             <= timingchg_s ;
      alarm_set_done        <= alarm_set_s ;
      sched_rcv             <= sched_rcv_s ;
      sched_start           <= sched_start_s ;

    elsif (rising_edge (clk)) then
      turnoff_s             <= turnoff_ff ;
      startup_s             <= startup_ff ;
      shutdown_s            <= shutdown_ff ;
      timingchg_s           <= timingchg_ff ;
      alarm_set_s           <= alarm_set_ff ;
      sched_rcv_s           <= sched_rcv_in ;
      sched_start_s         <= sched_start_ff ;

      --  Initialization states.

      case (cur_state) is

        --  Wait until an action is required.

        when SCHED_STATE_WAIT       =>
          turnoff_started       <= '0' ;
          startup_started       <= '0' ;
          shutdown_started      <= '0' ;
          timingchg_started     <= '0' ;
          sched_start_clear     <= '0' ;
          shutdown_out          <= '0' ;

          --  Shutdown requests do nothing.  Startup causes a timing change
          --  action to be take.  No other actions are taken until the
          --  device is started.

          if (shutdown = '1') then
            shutdown_out        <= '1' ;
            startup_out         <= '0' ;
            off_out             <= '0' ;
            shutdown_started    <= '1' ;
            shutdown_s          <= '0' ;
            running             <= '0' ;
            process_busy        <= '1' ;

          elsif (startup = '1') then
            startup_out         <= '1' ;
            startup_started     <= '1' ;
            startup_s           <= '0' ;
            running             <= '1' ;
            update_timing       <= '1' ;
            process_busy        <= '1' ;

          elsif (running = '0') then
            process_busy        <= '0' ;

          --  Reset the scheduled events after clock changes and when
          --  comming out of reset.  The range values can change dynamically
          --  requiring a recheck every time an event occurs.

          elsif (timing_changed = '1') then
            timingchg_fwl       <= update_timing xor not timingchg_fwl ;
            timingchg_started   <= '1' ;
            timingchg_s         <= '0' ;
            update_timing       <= '0' ;
            turnoff_started     <= '1' ;
            turnoff_s           <= '0' ;
            cur_range           <= on_off_times (0) ;
            next_range          <= TO_UNSIGNED (1, next_range'length) ;
            cur_time            <= rtctime_in ;
            turnon_time         <= (others => '1') ;
            cur_state           <= SCHED_STATE_UPDTURNOFF ;
            process_busy        <= '1' ;

          --  Turn off the system.

          elsif (turnoff = '1') then
            turnoff_started     <= '1' ;
            turnoff_s           <= '0' ;
            cur_range           <= on_off_times (0) ;
            next_range          <= TO_UNSIGNED (1, next_range'length) ;
            turnon_time         <= (others => '1') ;
            cur_time            <= rtctime_in ;
            cur_state           <= SCHED_STATE_UPDTURNOFF ;
            process_busy        <= '1' ;

          --  Go back to sleep.

          else
            process_busy        <= '0' ;
            cur_state           <= SCHED_STATE_WAIT ;
          end if ;

        --  Update the send event wait for the new local time.

        when SCHED_STATE_UPDTURNOFF =>

          --  Progressively check range entries until a range containing the
          --  current time is reached.  When the last range is passed, wait
          --  for the ranges to be updated.

          if (cur_time >= cur_range.end_time) then

            if (next_range = on_off_count_g) then
              if ((not turnon_time) = 0) then
                cur_state           <= SCHED_STATE_WAIT ;
              else
                cur_state           <= SCHED_STATE_TURNOFF ;
              end if ;
            else
              cur_range             <=
                    on_off_times (TO_INTEGER (next_range)) ;
              next_range            <= next_range + 1 ;
            end if ;

          --  Not yet in the next range.  Shutdown the system until then.

          elsif (cur_time < cur_range.str_time) then
            if (cur_range.str_time - cur_time < turnon_time) then
              turnon_time           <= RESIZE (cur_range.str_time -
                                               cur_time,
                                               turnon_time'length) ;
            end if ;

            if (next_range = on_off_count_g) then
              cur_state             <= SCHED_STATE_TURNOFF ;
            else
              cur_range             <=
                    on_off_times (TO_INTEGER (next_range)) ;
              next_range            <= next_range + 1 ;
            end if ;

          --  In the current range.  Schedule turn off when this range ends.

          elsif (sched_rcv = '0') then
            sched_req_out           <= '1' ;

          --  Schedule the event.

          else
            sched_delay_out         <= RESIZE (cur_range.end_time - cur_time,
                                               sched_delay_out'length) ;

            sched_type_out          <= '1' ;
            sched_id_out            <= TO_UNSIGNED (turnoff_id_g,
                                                    sched_id_out'length) ;
            sched_start_out         <= '1' ;
            cur_state               <= SCHED_STATE_DELAY ;
          end if ;

        --  Wait for the scheduling operation to complete.

        when SCHED_STATE_DELAY      =>
          if (sched_start = '1') then
            sched_start_clear <= '1' ;
            sched_start_s     <= '0' ;
            sched_start_out   <= '0' ;
            cur_state         <= SCHED_STATE_DONE ;
          end if ;

        when SCHED_STATE_DONE       =>
          if (sched_rcv = '0') then
            cur_state         <= SCHED_STATE_WAIT ;
          elsif (sched_start = '0') then
            sched_start_clear <= '0' ;
            sched_req_out     <= '0' ;
          end if ;

        --  Turn off the system.  If the last range has passed wait until
        --  the ranges have been updated before taking any action.

        when SCHED_STATE_TURNOFF    =>
          alarm_out           <= std_logic_vector (turnon_time) ;
          alarm_set_started   <= '1' ;
          cur_state           <= SCHED_STATE_ALARM ;

        when SCHED_STATE_ALARM    =>
          if (alarm_set_done = '1') then
            alarm_set_started <= '0' ;
            alarm_set_s       <= '0' ;
            off_out           <= '1' ;
            cur_state         <= SCHED_STATE_WAIT ;
          end if ;

      end case ;
    end if ;
  end process scheduler ;

end architecture rtl ;
