----------------------------------------------------------------------------
--
--! @file       TXscheduler.vhd
--! @brief      Turn the Data Transmitter on and off.
--! @details    Turn the Data Transmitter on and off at and send data
--!             packets scheduled intervals.
--! @author     Emery Newlon
--! @date       August 2016
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
--! @brief      Data Transmitter Scheduler.
--! @details    Turn the Data Transmitter on and off and send data packets
--!             at scheduled intervals.
--!
--! @param      sched_count_g     Number of scheduler IDs there are.
--! @param      send_id_g         ID of the send packet request.
--! @param      send_start_hr_g   Local hour to start sending packets.
--! @param      send_start_min_g  Local minute to start sending packets.
--! @param      send_end_hr_g     Local hour to stop sending packets.
--! @param      send_end_min_g    local minute to stop sending packets.
--! @param      send_int_hr_g     Hours of interval to send packets at.
--! @param      send_int_min_g    Minutes of interval to send packets at.
--! @param      send_copies_g     Number of packets to send every interval.
--! @param      send_delay_g      Clock cycles between sending copies.
--!                               One second should not be evenly divided by
--!                               this value in order to prevent multiple
--!                               units from transmitting at the same time.
--! @param      send_window_g     Number of seconds transmissions will be
--!                               started in.  This should be a prime number
--!                               as it is used to produce a hash coded trx
--!                               offset, in seconds, for each unit to start
--!                               transmitting in.
--! @param      recv_id_g         ID of the receive packets request.
--! @param      recv_start_hr_g   Local hour to start receiving packets.
--! @param      recv_start_min_g  Local minute to start receiving packets.
--! @param      recv_end_hr_g     Local hour to stop receiving packets.
--! @param      recv_end_min_g    Local minute to stop receiving packets.
--! @param      recv_int_hr_g     Hours of interval to receive packets at.
--! @param      recv_int_min_g    Minutes of interval to receive packets at.
--! @param      recv_delay_g      Clock cycles to wait for receive packets.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move through states in the
--!                               entity and its components.
--! @param      localtime_in      Local time in hrs/min/sec format.
--! @param      clockchg_in       The local time has jumped to a new value.
--! @param      system_id_in      The ID of the system differentiating it
--!                               from all other systems.
--! @param      startup_in        System startup for the Trx.
--! @param      startup_out       The Trx has been started.
--! @param      shutdown_in       System shutdown for the Trx.
--! @param      shutdown_out      The Trx has shut down.
--! @param      send_in           Send packets to the Trx.
--! @param      receive_in        Recieve packets from the Trx.
--! @param      power_in          Trx power state.
--! @param      power_out         Set the Trx power state.
--! @param      init_in           State of Trx initialization.
--! @param      init_out          Start the Trx initialization.
--! @param      trx_in            The packet send has completed.
--! @param      trx_out           Send a packet.
--! @param      rcv_in            A packet has been received.
--! @param      rcv_out           Receive a packet.
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

entity TXscheduler is

  Generic (
    sched_count_g     : natural := 8 ;
    send_id_g         : natural := 0 ;
    send_start_hr_g   : natural := 4 ;
    send_start_min_g  : natural := 3 ;
    send_end_hr_g     : natural := 21 ;
    send_end_min_g    : natural := 30 ;
    send_int_hr_g     : natural := 0 ;
    send_int_min_g    : natural := 30 ;
    send_copies_g     : natural := 3 ;
    send_delay_g      : natural := 7 ;
    send_window_g     : natural := 29 ;
    recv_id_g         : natural := 1 ;
    recv_start_hr_g   : natural := 6 ;
    recv_start_min_g  : natural := 0 ;
    recv_end_hr_g     : natural := 20 ;
    recv_end_min_g    : natural := 0 ;
    recv_int_hr_g     : natural := 1 ;
    recv_int_min_g    : natural := 10 ;
    recv_delay_g      : natural := 100
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    localtime_in      : in    std_logic_vector (dt_totalbits_c-1 downto 0) ;
    clockchg_in       : in    std_logic ;
    system_id_in      : in    unsigned (31 downto 0) ;
    startup_in        : in    std_logic ;
    startup_out       : out   std_logic ;
    shutdown_in       : in    std_logic ;
    shutdown_out      : out   std_logic ;
    send_in           : in    std_logic ;
    receive_in        : in    std_logic ;
    power_in          : in    std_logic ;
    power_out         : out   std_logic ;
    init_in           : in    std_logic ;
    init_out          : out   std_logic ;
    trx_in            : in    std_logic ;
    trx_out           : out   std_logic ;
    rcv_in            : in    std_logic ;
    rcv_out           : out   std_logic ;
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

end entity TXscheduler ;


architecture rtl of TXscheduler is

  --  Signal catchers.  The signal may be shorter than the clock period
  --  used for this entity.  An asynchronous SR flip flop will still be
  --  able to catch the signal.

  signal clock_changed      : std_logic ;
  signal clock_changed_set  : std_logic ;
  signal clockchg_started   : std_logic ;
  signal send_packets       : std_logic ;
  signal send_started       : std_logic ;
  signal receive_packets    : std_logic ;
  signal receive_started    : std_logic ;
  signal receiving          : std_logic ;
  signal startup            : std_logic ;
  signal startup_started    : std_logic ;
  signal shutdown           : std_logic ;
  signal shutdown_started   : std_logic ;
  signal running            : std_logic ;

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

  signal send_timing        : std_logic ;
  signal last_send_year     : unsigned (dt_yearbits_c-1 downto 0) ;
  signal last_send_yday     : unsigned (dt_ydaybits_c-1 downto 0) ;
  signal next_send_hr       : unsigned (dt_hourbits_c*2-1 downto 0) ;
  signal next_send_min      : unsigned (dt_minbits_c-1 downto 0) ;

  signal recv_timing        : std_logic ;
  signal last_recv_year     : unsigned (dt_yearbits_c-1 downto 0) ;
  signal last_recv_yday     : unsigned (dt_ydaybits_c-1 downto 0) ;
  signal next_recv_hr       : unsigned (dt_hourbits_c*2-1 downto 0) ;
  signal next_recv_min      : unsigned (dt_minbits_c-1 downto 0) ;

  signal send_count         : unsigned (const_bits (send_copies_g)-1
                                        downto 0) ;
  signal delay              : unsigned (const_bits (recv_delay_g)-1
                                        downto 0) ;

  signal timing_changed     : std_logic ;
  signal clockchg_reset     : std_logic ;

  signal trx_offset         : unsigned (dt_secbits_c-1 downto 0) ;

  --  Poll Generation States.

  type SchedulerState is   (
    SCHED_STATE_WAIT,
    SCHED_STATE_TURNON,
    SCHED_STATE_INIT,
    SCHED_STATE_SEND,
    SCHED_STATE_SEND_DLY,
    SCHED_STATE_UPDSEND,
    SCHED_STATE_RECEIVE,
    SCHED_STATE_UPDRECV,
    SCHED_STATE_DELAY,
    SCHED_STATE_DONE
  ) ;

  signal cur_state        : SchedulerState ;

  --  Entity busy indicators.

  signal process_busy     : std_logic := '0' ;

begin

  --  Convert the local time from a vector into a record.

  local_time                <= TO_DATE_TIME (localtime_in) ;

  --  Catch the clock change, startup, shutdown, send, and receive signals.
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

  send_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => send_started,
      set_in                => send_in,
      result_rd_out         => send_packets
    ) ;

  receive_sig : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => receive_started,
      set_in                => receive_in,
      result_rd_out         => receive_packets
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

  --  Entity busy.

  busy_out          <= startup or shutdown or process_busy or
                       (running and (timing_changed or send_packets or
                                     receive_packets)) ;

  --  Timing has changed.

  timing_changed    <= clock_changed or clockchg_reset ;

  --  Transmition offset set from the system's ID.

  trx_offset        <= RESIZE (system_id_in rem send_window_g,
                               trx_offset'length) ;


  --------------------------------------------------------------------------
  --  Schedule and handle on/off events.
  --------------------------------------------------------------------------

  scheduler :  process (reset, clk)
  begin
    if (reset = '1') then
      clockchg_started      <= '1' ;
      clockchg_reset        <= '1' ;
      send_started          <= '1' ;
      receive_started       <= '1' ;
      receiving             <= '0' ;
      startup_started       <= '1' ;
      running               <= '0' ;
      shutdown_started      <= '1' ;
      power_out             <= '0' ;
      startup_out           <= '0' ;
      shutdown_out          <= '0' ;
      init_out              <= '0' ;
      trx_out               <= '0' ;
      rcv_out               <= '0' ;
      last_send_year        <= (others => '0') ;
      last_send_yday        <= (others => '0') ;
      next_send_hr          <= TO_UNSIGNED (send_start_hr_g,
                                            next_send_hr'length) ;
      next_send_min         <= TO_UNSIGNED (send_start_min_g,
                                            next_send_min'length) ;
      last_recv_year        <= (others => '0') ;
      last_recv_yday        <= (others => '0') ;
      next_recv_hr          <= TO_UNSIGNED (recv_start_hr_g,
                                            next_recv_hr'length) ;
      next_recv_min         <= TO_UNSIGNED (recv_start_min_g,
                                            next_recv_min'length) ;
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
          send_started          <= '0' ;
          receive_started       <= '0' ;
          startup_started       <= '0' ;
          shutdown_started      <= '0' ;
          clockchg_started      <= '0' ;
          shutdown_out          <= '0' ;

          --  Startup and shutdown requests do nothing.  No other actions
          --  are taken until the device is started.

          if (shutdown = '1') then
            power_out           <= '0' ;
            shutdown_out        <= '1' ;
            shutdown_started    <= '1' ;
            running             <= '0' ;
            process_busy        <= '1' ;

          elsif (startup = '1') then
            startup_out         <= '1' ;
            startup_started     <= '1' ;
            running             <= '1' ;
            process_busy        <= '1' ;

          elsif (running = '0') then
            process_busy        <= '0' ;

          --  Reset the scheduled send and receive events after clock
          --  changes and when comming out of reset.

          elsif (timing_changed = '1') then
            last_dst            <= local_time.indst ;
            send_timing         <= '1' ;
            recv_timing         <= '1' ;
            clockchg_started    <= '1' ;
            clockchg_reset      <= '0' ;
            process_busy        <= '1' ;

          elsif (send_timing = '1') then
            send_started        <= '1' ;
            send_timing         <= '0' ;
            next_send_hr        <= TO_UNSIGNED (send_start_hr_g,
                                                next_send_hr'length) ;
            next_send_min       <= TO_UNSIGNED (send_start_min_g,
                                                next_send_min'length) ;
            cur_year            <= local_time.year ;
            cur_yday            <= local_time.yday ;
            cur_hour            <= local_time.hour ;
            cur_minute          <= local_time.minute ;
            cur_second          <= local_time.second ;
            cur_state           <= SCHED_STATE_UPDSEND ;

          elsif (recv_timing = '1') then
            receive_started     <= '1' ;
            recv_timing         <= '0' ;
            next_recv_hr        <= TO_UNSIGNED (recv_start_hr_g,
                                                next_recv_hr'length) ;
            next_recv_min       <= TO_UNSIGNED (recv_start_min_g,
                                                next_recv_min'length) ;
            cur_year            <= local_time.year ;
            cur_yday            <= local_time.yday ;
            cur_hour            <= local_time.hour ;
            cur_minute          <= local_time.minute ;
            cur_second          <= local_time.second ;
            cur_state           <= SCHED_STATE_UPDRECV ;

          --  Send and receive packets after turning on and initializing
          --  the device.  The receive delay is reduce by a factor of 2
          --  because their are 2 clock cycles between decrements.

          elsif (send_packets = '1') then
            process_busy        <= '1' ;

            if (power_in = '0') then
              cur_state         <= SCHED_STATE_TURNON ;
            else
              send_started      <= '1' ;
              trx_out           <= '1' ;
              send_count        <= TO_UNSIGNED (send_copies_g,
                                                send_count'length) ;
              cur_state         <= SCHED_STATE_SEND ;
            end if ;

          elsif (receive_packets = '1') then
            process_busy        <= '1' ;

            if (power_in = '0') then
              cur_state         <= SCHED_STATE_TURNON ;
            else
              receive_started   <= '1' ;
              rcv_out           <= '1' ;
              delay             <= TO_UNSIGNED (recv_delay_g / 2 + 1,
                                                delay'length) ;
              cur_state         <= SCHED_STATE_RECEIVE ;
            end if ;

          elsif (receiving = '1') then
            cur_state           <= SCHED_STATE_RECEIVE ;

          --  Go back to sleep.

          else
            process_busy        <= '0' ;
            cur_state           <= SCHED_STATE_WAIT ;
          end if ;

        --  Turn on and initialize the device.

        when SCHED_STATE_TURNON     =>
          power_out                 <= '1' ;

          if (power_in = '1') then
            init_out                <= '1' ;
            cur_state               <= SCHED_STATE_INIT ;
          end if ;

        when SCHED_STATE_INIT       =>
          if (init_in = '1') then
            init_out                <= '0' ;
            cur_state               <= SCHED_STATE_WAIT ;
          end if ;

        --  Send a set of packets to the device.

        when SCHED_STATE_SEND       =>
          if (trx_in = '1') then
            trx_out                 <= '0' ;

            if (send_count /= 1) then
              send_count            <= send_count - 1 ;
              delay                 <= TO_UNSIGNED (send_delay_g,
                                                    delay'length) ;
              cur_state             <= SCHED_STATE_SEND_DLY ;
            else
              power_out             <= '0' ;
              cur_year              <= local_time.year ;
              cur_yday              <= local_time.yday ;
              cur_hour              <= local_time.hour ;
              cur_minute            <= local_time.minute ;
              cur_second            <= local_time.second ;
              cur_state             <= SCHED_STATE_UPDSEND ;
            end if ;
          end if ;

        when SCHED_STATE_SEND_DLY   =>
          if (delay /= 1) then
            delay                   <= delay - 1 ;
          elsif (trx_in = '0') then
            trx_out                 <= '1' ;
            cur_state               <= SCHED_STATE_SEND ;
          end if ;

        --  Update the send event wait for the new local time.

        when SCHED_STATE_UPDSEND    =>

          --  Progressively add the increment until the current time is
          --  passed.  When the end of the current day schedule is reached
          --  continue to the start of the next day's.

          if (cur_year /= last_send_year or cur_yday /= last_send_yday) then
            last_send_year          <= cur_year ;
            last_send_yday          <= cur_yday ;
            next_send_hr            <= TO_UNSIGNED (send_start_hr_g,
                                                    next_send_hr'length) ;
            next_send_min           <= TO_UNSIGNED (send_start_min_g,
                                                    next_send_min'length) ;

          elsif (cur_hour    >  next_send_hr or
                 (cur_hour   =  next_send_hr and
                  cur_minute >= next_send_min)) then

            if (next_send_min >= hour_minutes_c - send_int_min_g) then
              next_send_min         <= next_send_min -
                                       (hour_minutes_c - send_int_min_g) ;
              next_send_hr          <= next_send_hr  + send_int_hr_g + 1 ;

            else
              next_send_min         <= next_send_min + send_int_min_g ;
              next_send_hr          <= next_send_hr  + send_int_hr_g ;
            end if ;

          --  The current time has been passed.  Set the delay for the
          --  next event.  If the end of the day has been reached start
          --  it at the beginning of the next day.

          elsif (sched_rcv_in = '0') then
            sched_req_out           <= '1' ;

          else
            if (next_send_hr   > send_end_hr_g or
                (next_send_hr  = send_end_hr_g and
                 next_send_min > send_end_min_g)) then

              if (cur_minute > send_start_min_g) then
                sched_delay_out     <=
                  RESIZE ((send_start_hr_g + day_hours_c - 1 - cur_hour) *
                          const_unsigned (hour_seconds_c, 1) +
                          (send_start_min_g +
                           (hour_minutes_c - cur_minute)) *
                          const_unsigned (min_seconds_c, 1) - cur_second +
                          trx_offset,
                          sched_delay_out'length) ;
              else
                sched_delay_out     <=
                  RESIZE ((send_start_hr_g + day_hours_c - cur_hour) *
                          const_unsigned (hour_seconds_c, 1) +
                          (send_start_min_g - cur_minute) *
                          const_unsigned (min_seconds_c, 1) - cur_second +
                          trx_offset,
                          sched_delay_out'length) ;
              end if ;

            elsif (cur_minute > next_send_min) then
              sched_delay_out       <=
                  RESIZE ((next_send_hr - cur_hour - 1) *
                          const_unsigned (hour_seconds_c, 1) +
                          (next_send_min + (hour_minutes_c - cur_minute)) *
                          const_unsigned (min_seconds_c, 1) - cur_second +
                          trx_offset,
                          sched_delay_out'length) ;
            else
              sched_delay_out       <=
                  RESIZE ((next_send_hr - cur_hour) *
                          const_unsigned (hour_seconds_c, 1) +
                          (next_send_min - cur_minute) *
                          const_unsigned (min_seconds_c, 1) - cur_second +
                          trx_offset,
                          sched_delay_out'length) ;
            end if ;

            --  Schedule the event.

            sched_type_out          <= '1' ;
            sched_id_out            <= TO_UNSIGNED (send_id_g,
                                                    sched_id_out'length) ;
            sched_start_out         <= '1' ;
            cur_state               <= SCHED_STATE_DELAY ;
          end if ;

        --  Receive packets from the device.

        when SCHED_STATE_RECEIVE    =>
          if (rcv_in = '1') then
            rcv_out                 <= '0' ;
          else
            rcv_out                 <= '1' ;
          end if ;

          if (delay /= 1) then
            delay                   <= delay - 1 ;
            receiving               <= '1' ;
            cur_state               <= SCHED_STATE_WAIT ;
          else
            rcv_out                 <= '0' ;
            power_out               <= '0' ;
            receiving               <= '0' ;
            cur_year                <= local_time.year ;
            cur_yday                <= local_time.yday ;
            cur_hour                <= local_time.hour ;
            cur_minute              <= local_time.minute ;
            cur_second              <= local_time.second ;
            cur_state               <= SCHED_STATE_UPDRECV ;
          end if ;

        --  Update the receive event wait for the new local time.

        when SCHED_STATE_UPDRECV    =>

          --  Progressively add the increment until the current time is
          --  passed.

          if (cur_year /= last_recv_year or cur_yday /= last_recv_yday) then
            last_recv_year          <= cur_year ;
            last_recv_yday          <= cur_yday ;
            next_recv_hr            <= TO_UNSIGNED (recv_start_hr_g,
                                                    next_recv_hr'length) ;
            next_recv_min           <= TO_UNSIGNED (recv_start_min_g,
                                                    next_recv_min'length) ;

          elsif (cur_hour    >  next_recv_hr or
                 (cur_hour   =  next_recv_hr and
                  cur_minute >= next_recv_min)) then

            if (next_recv_min >= hour_minutes_c - recv_int_min_g) then
              next_recv_min         <= next_recv_min -
                                       (hour_minutes_c - recv_int_min_g) ;
              next_recv_hr          <= next_recv_hr  + recv_int_hr_g + 1 ;

            else
              next_recv_min         <= next_recv_min + recv_int_min_g ;
              next_recv_hr          <= next_recv_hr  + recv_int_hr_g ;
            end if ;

          --  The current time has been passed.  Set the delay for the
          --  next event.

          elsif (sched_rcv_in = '0') then
            sched_req_out           <= '1' ;

          else
            if (next_recv_hr   > recv_end_hr_g or
                (next_recv_hr  = recv_end_hr_g and
                 next_recv_min > recv_end_min_g)) then

              if (cur_minute > recv_start_min_g) then
                sched_delay_out       <=
                  RESIZE ((recv_start_hr_g + day_hours_c - 1 - cur_hour) *
                          const_unsigned (hour_seconds_c, 1) +
                          (recv_start_min_g +
                           (hour_minutes_c - cur_minute)) *
                          const_unsigned (min_seconds_c, 1) - cur_second,
                          sched_delay_out'length) ;
              else
                sched_delay_out       <=
                  RESIZE ((recv_start_hr_g + day_hours_c - cur_hour) *
                          const_unsigned (hour_seconds_c, 1) +
                          (recv_start_min_g - cur_minute) *
                          const_unsigned (min_seconds_c, 1) - cur_second,
                          sched_delay_out'length) ;
              end if ;

            elsif (cur_minute > next_recv_min) then
              sched_delay_out       <=
                  RESIZE ((next_recv_hr - cur_hour - 1) *
                          const_unsigned (hour_seconds_c, 1) +
                          (next_recv_min + (hour_minutes_c - cur_minute)) *
                          const_unsigned (min_seconds_c, 1) - cur_second,
                          sched_delay_out'length) ;
            else
              sched_delay_out       <=
                  RESIZE ((next_recv_hr - cur_hour) *
                          const_unsigned (hour_seconds_c, 1) +
                          (next_recv_min - cur_minute) *
                          const_unsigned (min_seconds_c, 1) - cur_second,
                          sched_delay_out'length) ;
            end if ;

            --  Schedule the event.

            sched_type_out          <= '1' ;
            sched_id_out            <= TO_UNSIGNED (recv_id_g,
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

      end case ;
    end if ;
  end process scheduler ;

end architecture rtl ;
