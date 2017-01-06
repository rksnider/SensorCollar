----------------------------------------------------------------------------
--
--! @file       GPSscheduler.vhd
--! @brief      Turn the GPS on and off.
--! @details    Turn the GPS on and off at scheduled intervals.
--! @author     Emery Newlon
--! @date       July 2016
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


----------------------------------------------------------------------------
--
--! @brief      GPS Scheduler.
--! @details    Turn the GPS on and off at scheduled intervals.
--!
--! @param      sched_count_g     Number of scheduler IDs there are.
--! @param      turnon_id_g       ID of the turnon request.
--! @param      turnon_delay_g    Seconds to wait before turning on GPS.
--! @param      turnoff_id_g      ID of the turnoff request.
--! @param      turnoff_delay_g   Seconds to wait before turning GPS off.
--! @param      poll_interval_g   Seconds to wait between polls of the GPS.
--! @param      poll_fast_g       Fast poll interval for shutting down.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move through states in the
--!                               entity and its components.
--! @param      startup_in        System startup for the GPS.
--! @param      startup_out       The GPS has been started.
--! @param      shutdown_in       System shutdown for the GPS.
--! @param      shutdown_out      The GPS has shut down.
--! @param      turnon_in         Turn the GPS on.
--! @param      turnoff_in        Turn the GPS off.
--! @param      power_in          GPS power state.
--! @param      power_out         Set the GPS power state.
--! @param      init_in           State of GPS initialization.
--! @param      init_out          Start the GPS initialization.
--! @param      timemark_in       Current timemark bank being used.
--! @param      pollint_out       Polling interval to use.
--! @param      aop_updated_in    AOP status has been updated.
--! @param      aop_running_in    AOP is running.
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

entity GPSscheduler is

  Generic (
    sched_count_g     : natural := 8 ;
    turnon_id_g       : natural := 0 ;
    turnon_delay_g    : natural := 10 * 60 ;
    turnoff_id_g      : natural := 1 ;
    turnoff_delay_g   : natural := 4 * 60 ;
    poll_interval_g   : natural := 15 ;
    poll_fast_g       : natural := 3
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    startup_in        : in    std_logic ;
    startup_out       : out   std_logic ;
    shutdown_in       : in    std_logic ;
    shutdown_out      : out   std_logic ;
    turnon_in         : in    std_logic ;
    turnoff_in        : in    std_logic ;
    power_in          : in    std_logic ;
    power_out         : out   std_logic ;
    init_in           : in    std_logic ;
    init_out          : out   std_logic ;
    timemark_in       : in    std_logic ;
    pollint_out       : out   unsigned (13 downto 0) ;
    aop_updated_in    : in    std_logic ;
    aop_running_in    : in    std_logic ;
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

end entity GPSscheduler ;


architecture rtl of GPSscheduler is

  --  Initialization signal catcher.  The signal may be shorter than the
  --  clock period used for this entity.  An asynchronous SR flip flop will
  --  still be able to catch the signal.

  signal turnon             : std_logic ;
  signal turnon_s           : std_logic ;
  signal turnon_ff          : std_logic ;
  signal turnon_set         : std_logic ;
  signal turnon_clear       : std_logic ;
  signal turnon_started     : std_logic := '0' ;
  signal turnoff            : std_logic ;
  signal turnoff_s          : std_logic ;
  signal turnoff_ff         : std_logic ;
  signal turnoff_clear      : std_logic ;
  signal turnoff_started    : std_logic := '0' ;
  signal shutdown           : std_logic ;
  signal shutdown_s         : std_logic ;
  signal shutdown_ff        : std_logic ;
  signal shutdown_clear     : std_logic ;
  signal shutdown_started   : std_logic := '0' ;
  signal power              : std_logic ;
  signal power_s            : std_logic ;
  signal init               : std_logic ;
  signal init_s             : std_logic ;
  signal timemark           : std_logic ;
  signal timemark_s         : std_logic ;
  signal aop_updated        : std_logic ;
  signal aop_updated_s      : std_logic ;
  signal aop_running        : std_logic ;
  signal aop_running_s      : std_logic ;
  signal sched_rcv          : std_logic ;
  signal sched_rcv_s        : std_logic ;
  signal sched_start        : std_logic ;
  signal sched_start_s      : std_logic ;
  signal last_timemark      : std_logic ;
  signal last_aop_updated   : std_logic ;

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

  --  Poll Generation States.

  type SchedulerState is   (
    SCHED_STATE_WAIT,
    SCHED_STATE_POWERON,
    SCHED_STATE_POWEROFF,
    SCHED_STATE_AOP,
    SCHED_STATE_INIT,
    SCHED_STATE_TURNON,
    SCHED_STATE_CLEAROFF,
    SCHED_STATE_TURNOFF,
    SCHED_STATE_CLEARON,
    SCHED_STATE_DELAY,
    SCHED_STATE_DONE
  ) ;

  signal cur_state        : SchedulerState ;
  signal next_state       : SchedulerState ;

  --  Entity busy indicators.

  signal process_busy     : std_logic := '0' ;

begin

  --  Catch the startup, shutdown, turnon, turnoff, and scheduler receive
  --  signals.
  --  The signals may be shorter than the clock period used for this entity.
  --  An asynchronous SR flip flop will still be able to catch the signal.
  --  The result will be set if the initialize start signal is set or the
  --  timepulse signal has changed since the last initialization.

  turnon_set                <= startup_in or turnon_in ;
  turnon_clear              <= turnon_started   or reset ;
  turnoff_clear             <= turnoff_started  or reset ;
  shutdown_clear            <= shutdown_started or reset ;

  turnon_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => turnon_clear,
      set_in                => turnon_set,
      result_rd_out         => turnon_ff
    ) ;

  turnoff_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => turnoff_clear,
      set_in                => turnoff_in,
      result_rd_out         => turnoff_ff
    ) ;

  shutdown_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => shutdown_clear,
      set_in                => shutdown_in,
      result_rd_out         => shutdown_ff
    ) ;

  --  Entity busy.

  busy_out          <= turnon_ff or turnoff_ff or shutdown_ff or
                       process_busy or (last_timemark xor timemark_in) ;


  --------------------------------------------------------------------------
  --  Schedule and handle on/off events.
  --------------------------------------------------------------------------

  scheduler :  process (reset, clk)
  begin
    if (reset = '1') then
      startup_out           <= '0' ;
      turnon                <= '0' ;
      turnon_s              <= '0' ;
      turnon_started        <= '0' ;
      turnoff               <= '0' ;
      turnoff_s             <= '0' ;
      turnoff_started       <= '0' ;
      shutdown              <= '0' ;
      shutdown_s            <= '0' ;
      shutdown_started      <= '0' ;
      power                 <= '0' ;
      power_s               <= '0' ;
      init                  <= '0' ;
      init_s                <= '0' ;
      timemark              <= '0' ;
      timemark_s            <= '0' ;
      aop_updated           <= '0' ;
      aop_updated_s         <= '0' ;
      sched_rcv             <= '0' ;
      sched_rcv_s           <= '0' ;
      sched_start           <= '0' ;
      sched_start_s         <= '0' ;
      power_out             <= '0' ;
      shutdown_out          <= '0' ;
      init_out              <= '0' ;
      last_timemark         <= '0' ;
      last_aop_updated      <= '0' ;
      pollint_out           <= (others => '0') ;
      sched_req_out         <= '0' ;
      sched_type_out        <= '0' ;
      sched_id_out          <= (others => '0') ;
      sched_delay_out       <= (others => '0') ;
      sched_start_out       <= '0' ;
      process_busy          <= '1' ;
      cur_state             <= SCHED_STATE_WAIT ;

    elsif (falling_edge (clk)) then
      turnon                <= turnon_s ;
      turnoff               <= turnoff_s ;
      shutdown              <= shutdown_s ;
      power                 <= power_s ;
      init                  <= init_s ;
      timemark              <= timemark_s ;
      aop_updated           <= aop_updated_s ;
      aop_running           <= aop_running_s ;
      sched_rcv             <= sched_rcv_s ;
      sched_start           <= sched_start_s ;

    elsif (rising_edge (clk)) then
      turnon_s              <= turnon_ff ;
      turnoff_s             <= turnoff_ff ;
      shutdown_s            <= shutdown_ff ;
      power_s               <= power_in ;
      init_s                <= init_in ;
      timemark_s            <= timemark_in ;
      aop_updated_s         <= aop_updated_in ;
      aop_running_s         <= aop_running_in ;
      sched_rcv_s           <= sched_rcv_in ;
      sched_start_s         <= sched_start_in ;

      --  Initialization states.

      case (cur_state) is

        --  Wait until an action is required.

        when SCHED_STATE_WAIT       =>
          sched_req_out         <= '0' ;
          shutdown_started      <= '0' ;
          shutdown_out          <= '0' ;

          if (turnon = '1') then
            turnon_started      <= '1' ;
            turnon_s            <= '0' ;
            power_out           <= '1' ;
            process_busy        <= '1' ;
            cur_state           <= SCHED_STATE_POWERON ;

          elsif (turnoff = '1') then
            turnoff_started     <= '1' ;
            turnoff_s           <= '0' ;
            pollint_out         <= (others => '0') ;
            power_out           <= '0' ;
            process_busy        <= '1' ;
            cur_state           <= SCHED_STATE_POWEROFF ;

          elsif (shutdown = '1') then
            if (power = '0') then
              power_out         <= '0' ;
              shutdown_out      <= '1' ;
              shutdown_started  <= '1' ;
              shutdown_s        <= '0' ;
            else
              pollint_out       <= TO_UNSIGNED (poll_fast_g,
                                                pollint_out'length) ;
              last_aop_updated  <= aop_updated ;
              process_busy      <= '1' ;
              cur_state         <= SCHED_STATE_AOP ;
            end if ;

          --  Turn off the GPS after it has received a new timemark.

          elsif (last_timemark /= timemark) then
            if (power = '0') then
              last_timemark     <= '0' ;
            else
              pollint_out       <= TO_UNSIGNED (poll_fast_g,
                                                pollint_out'length) ;
              last_aop_updated  <= aop_updated ;
              process_busy      <= '1' ;
              cur_state         <= SCHED_STATE_AOP ;
            end if ;

          else
            process_busy      <= '0' ;
            cur_state         <= SCHED_STATE_WAIT ;
          end if ;

        --  Wait for the GPS to power up.

        when SCHED_STATE_POWERON    =>
          turnon_started      <= '0' ;

          if (power = '1') then
            init_out          <= '1' ;
            cur_state         <= SCHED_STATE_INIT ;
          end if ;

        --  Set the force off time after initialization done.

        when SCHED_STATE_INIT       =>
          init_out            <= '0' ;

          if (init = '1') then
            startup_out       <= '1' ;
            last_timemark     <= timemark ;
            pollint_out       <= TO_UNSIGNED (poll_interval_g,
                                              pollint_out'length) ;
            sched_req_out     <= '1' ;
            cur_state         <= SCHED_STATE_TURNOFF ;
          end if ;

        when SCHED_STATE_TURNOFF    =>
          startup_out         <= '0' ;

          if (sched_rcv = '1') then
            sched_type_out    <= '1' ;
            sched_id_out      <= TO_UNSIGNED (turnoff_id_g,
                                              sched_id_out'length) ;
            sched_delay_out   <= TO_UNSIGNED (turnoff_delay_g,
                                              sched_delay_out'length) ;
            sched_start_out   <= '1' ;
            next_state        <= SCHED_STATE_CLEARON ;
            cur_state         <= SCHED_STATE_DELAY ;
          end if ;

        when SCHED_STATE_CLEARON    =>
          sched_type_out      <= '0' ;
          sched_id_out        <= TO_UNSIGNED (turnon_id_g,
                                              sched_id_out'length) ;
          sched_delay_out     <= (others => '0') ;
          sched_start_out     <= '1' ;
          next_state          <= SCHED_STATE_WAIT ;
          cur_state           <= SCHED_STATE_DELAY ;

        --  Wait until the GPS has is off and schedule a new power on.

        when SCHED_STATE_POWEROFF   =>
          turnoff_started     <= '0' ;

          if (power = '0') then
            sched_req_out     <= '1' ;
            cur_state         <= SCHED_STATE_TURNON ;
          end if ;

        when SCHED_STATE_TURNON     =>
          if (sched_rcv = '1') then
            sched_type_out    <= '1' ;
            sched_id_out      <= TO_UNSIGNED (turnon_id_g,
                                              sched_id_out'length) ;
            sched_delay_out   <= TO_UNSIGNED (turnon_delay_g,
                                              sched_delay_out'length) ;
            sched_start_out   <= '1' ;
            next_state        <= SCHED_STATE_CLEAROFF ;
            cur_state         <= SCHED_STATE_DELAY ;
          end if ;

        when SCHED_STATE_CLEAROFF   =>
          sched_type_out      <= '0' ;
          sched_id_out        <= TO_UNSIGNED (turnoff_id_g,
                                              sched_id_out'length) ;
          sched_delay_out     <= (others => '0') ;
          sched_start_out     <= '1' ;
          next_state          <= SCHED_STATE_WAIT ;
          cur_state           <= SCHED_STATE_DELAY ;

        --  Wait for AOP status to go low.

        when SCHED_STATE_AOP        =>
          if (last_aop_updated /= aop_updated) then
            last_aop_updated      <= aop_updated ;

            if (aop_running = '0') then
              pollint_out         <= (others => '0') ;
              power_out           <= '0' ;

              if (shutdown = '1') then
                shutdown_started  <= '1' ;
                shutdown_s        <= '0' ;
                shutdown_out      <= '1' ;
                cur_state         <= SCHED_STATE_WAIT ;
              else
                cur_state         <= SCHED_STATE_POWEROFF ;
              end if ;
            end if ;
          end if ;

        --  Wait for the scheduling operation to complete.

        when SCHED_STATE_DELAY      =>
          if (sched_start = '1') then
            sched_start_out   <= '0' ;
            cur_state         <= SCHED_STATE_DONE ;
          end if ;

        when SCHED_STATE_DONE       =>
          if (sched_start = '0') then
            cur_state         <= next_state ;
          end if ;

      end case ;
    end if ;
  end process scheduler ;

end architecture rtl ;
