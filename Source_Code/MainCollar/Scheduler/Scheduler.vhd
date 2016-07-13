----------------------------------------------------------------------------
--
--! @file       Scheduler.vhd
--! @brief      Schedule wake-up events.
--! @details    Schedule wake-up signals for multiple, independent entities.
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

library GENERAL ;               --! General libraries
use GENERAL.GPS_CLOCK_PKG.ALL ;
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Schedule wake-up events.
--! @details    Schedule and send wake-up signals for multiple, independent
--!             entities.  Each requester can have only a single request
--!             pending at a time.
--!
--! @param      req_number_g          Number of requesters used.
--! @param      reset                 Reset the module to initial state.
--! @param      clk                   Clock used for logic.
--! @param      milli_clk             Millisecond clock to check events by.
--! @param      curtime_in            System time in GPS format.
--! @param      req_received_in       A request needs to be processed.
--!                                   This must be held high until the
--!                                   'req_received_out' goes high.  Then
--!                                   it must be held low until
--!                                   'req_received_out' goes low.
--! @param      req_received_out      A request is being processed.
--! @param      req_type_in           Add/modify if 1, delete if 0.
--! @param      req_id_in             Identity of the requester.  Also used
--!                                   as the bit number in the wake-up bits
--!                                   to signal the requester's event.
--! @param      req_time_in           System time millisecond to wake up at.
--!                                   Values less that current millisecond
--!                                   will be in the next week.  When set
--!                                   to all ones the 'req_secs_in' value
--!                                   will be used instead.  Limited to
--!                                   one week.
--! @param      req_secs_in           Delay in seconds to wake up at.  Only
--!                                   used if 'req_time_in' is all ones.
--!                                   Limited to one week.
--! @param      done_out              Wake-up bits.
--! @param      busy_out              The component is busy processing.
--
----------------------------------------------------------------------------

entity Scheduler is
  Generic (
    req_number_g          : natural := 8
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    milli_clk             : in    std_logic ;
    curtime_in            : in    std_logic_vector (gps_time_bits_c-1
                                                    downto 0) ;
    req_received_in       : in    std_logic ;
    req_received_out      : out   std_logic ;
    req_type_in           : in    std_logic ;
    req_id_in             : in
          std_logic_vector (const_bits (req_number_g-1)-1 downto 0) ;
    req_time_in           : in    std_logic_vector (gps_time_millibits_c-1
                                                    downto 0) ;
    req_secs_in           : in
          unsigned (const_bits (millisec_week_c / 1000 - 1)-1 downto 0) ;
    done_out              : out   std_logic_vector (req_number_g-1
                                                    downto 0) ;
    busy_out              : out   std_logic
  ) ;

end entity Scheduler ;


architecture rtl of Scheduler is

  signal req_received_fwl : std_logic ;
  signal req_busy         : std_logic ;
  signal req_id           : std_logic_vector (req_id_in'length-1 downto 0) ;
  signal req_time         : std_logic_vector (gps_time_millibits_c
                                              downto 0) ;
  signal req_count        : unsigned (const_bits (req_number_g)-1
                                      downto 0) := (others => '0') ;
  signal count            : unsigned (req_count'length-1 downto 0) ;

  signal wake_bits        : std_logic_vector (done_out'length-1 downto 0) ;

  signal curtime          : GPS_Time ;
  signal last_week_bit    : std_logic ;
  signal millisecond      : std_logic_vector (gps_time_millibits_c-1
                                              downto 0) ;
  signal next_target      : std_logic_vector (gps_time_millibits_c-1
                                              downto 0) ;

  --  Memory access.

  signal not_clk          : std_logic ;

  signal src_read_en      : std_logic ;
  signal src_address      : unsigned (req_count'length-1 downto 0) ;
  signal src_reqid        : std_logic_vector (req_id'length-1 downto 0) ;
  signal src_time         : std_logic_vector (req_time'length-1 downto 0) ;

  signal dst_write_en     : std_logic ;
  signal dst_address      : unsigned (req_count'length-1 downto 0) ;
  signal dst_reqid        : std_logic_vector (req_id'length-1 downto 0) ;
  signal dst_time         : std_logic_vector (req_time'length-1 downto 0) ;

  component SchedulerTbl is
    port
    (
      clock               : in    std_logic  := '1' ;
      data                : in    std_logic_vector (39 downto 0) ;
      rdaddress           : in    std_logic_vector (7 downto 0) ;
      rden                : in    std_logic  := '1' ;
      wraddress           : in    std_logic_vector (7 downto 0) ;
      wren                : in    std_logic  := '0' ;
      q                   : out   std_logic_vector (39 downto 0)
    ) ;
  end component SchedulerTbl ;

  signal rd_address       : std_logic_vector (7 downto 0) ;
  signal rd_data          : std_logic_vector (39 downto 0) ;
  signal wr_address       : std_logic_vector (7 downto 0) ;
  signal wr_data          : std_logic_vector (39 downto 0) ;

  --  Process clock control flags.

  signal proc_start       : std_logic ;
  signal proc_busy        : std_logic ;

  --  Process state control.

  type SchedulerState is   (
    SCH_STATE_WAIT,
    SCH_STATE_NEWWEEK,
    SCH_STATE_WAKEUP,
    SCH_STATE_WAKEDONE,
    SCH_STATE_ADD,
    SCH_STATE_REMOVE,
    SCH_STATE_MOVE,
    SCH_STATE_INSERT
  ) ;

  signal cur_state        : SchedulerState ;


begin

  not_clk                 <= not clk ;

  curtime                 <= TO_GPS_TIME (curtime_in) ;

  busy_out                <= proc_busy or proc_start or req_received_in ;

  req_received_out        <= req_busy ;

  --  Memory table mapping.

  tbl : SchedulerTbl
    port map
    (
      clock               => not_clk,
      data                => wr_data,
      rdaddress           => rd_address,
      rden                => src_read_en,
      wraddress           => wr_address,
      wren                => dst_write_en,
      q                   => rd_data
    ) ;

  wr_address              <=
      std_logic_vector (RESIZE (dst_address, wr_address'length)) ;
  wr_data                 <=
      std_logic_vector (RESIZE (unsigned (dst_reqid & dst_time),
                        wr_data'length)) ;

  rd_address              <=
      std_logic_vector (RESIZE (src_address, rd_address'length)) ;
  src_time                <= rd_data (src_time'length-1 downto 0) ;
  src_reqid               <= rd_data (src_time'length+src_reqid'length-1
                                      downto src_time'length) ;


  --------------------------------------------------------------------------
  --  Wake up the main process when a week change or millisecond match
  --  has occured.
  --------------------------------------------------------------------------

  milli_wait : process (milli_clk)
  begin
    if (rising_edge (milli_clk)) then
      millisecond         <= curtime.week_millisecond ;

      if (curtime.week_number (0) /= last_week_bit or
          (req_count /= 0 and
           curtime.week_millisecond = next_target)) then
        proc_start        <= '1' ;
      else
        proc_start        <= '0' ;
      end if ;
    end if ;
  end process milli_wait ;


  --------------------------------------------------------------------------
  --  Scheduler process.
  --  Add and remove events and signal event wake-ups.  Also handle week
  --  rollovers.
  --------------------------------------------------------------------------

  sched : process (reset, clk)
  variable sec_time           :
      unsigned (const_bits (millisec_week_c * 2)-1 downto 0) ;
  begin
    if (reset = '1') then
      proc_busy               <= '0' ;
      last_week_bit           <= '0' ;
      req_received_fwl        <= '0' ;
      req_busy                <= '0' ;
      src_read_en             <= '0' ;
      dst_write_en            <= '0' ;
      next_target             <= (others => '0') ;
      req_count               <= (others => '0') ;
      cur_state               <= SCH_STATE_WAIT ;

    elsif (rising_edge (clk)) then

      case cur_state is

        --  Wait until there is something to process.

        when SCH_STATE_WAIT       =>
          dst_write_en        <= '0' ;
          done_out            <= (others => '0') ;

          --  Check for week rollover.

          if (curtime.week_number (0) /= last_week_bit) then
            last_week_bit     <= curtime.week_number (0) ;
            proc_busy         <= '1' ;

            if (req_count /= 0) then
              src_read_en     <= '1' ;
              src_address     <= (others => '0') ;
              dst_address     <= (others => '1') ;
              cur_state       <= SCH_STATE_NEWWEEK ;
            end if ;

          --  Check for next event target reached.

          elsif (req_count /= 0 and millisecond = next_target) then
            src_read_en       <= '1' ;
            src_address       <= (others => '0') ;
            count             <= (others => '0') ;
            wake_bits         <= (others => '0') ;
            proc_busy         <= '1' ;
            cur_state         <= SCH_STATE_WAKEUP ;

          --  Check for change in requests.

          elsif (req_received_fwl /= req_received_in) then
            req_received_fwl  <= req_received_in ;

            if (req_received_in = '1') then
              req_id          <= req_id_in ;

              --  Determine the request time from the seconds to delay.
              --  Wrap the time around if the result is greater than a
              --  week.

              if (unsigned (not req_time_in) = 0) then
                sec_time      := RESIZE (req_secs_in * 1000,
                                         sec_time'length) +
                                 unsigned (millisecond) ;

                if (sec_time >= millisec_week_c) then
                  req_time    <=
                    '1' & std_logic_vector (RESIZE (sec_time -
                                                    millisec_week_c,
                                                    req_time_in'length)) ;
                else
                  req_time    <=
                    '0' & std_logic_vector (RESIZE (sec_time,
                                                    req_time_in'length)) ;
                end if ;

              --  Use the request time directly.  Extend the time to the
              --  next week if it has already passed in this week.

              else
                if (unsigned (req_time_in) < unsigned (millisecond)) then
                  req_time    <= '1' & req_time_in ;
                else
                  req_time    <= '0' & req_time_in ;
                end if ;
              end if ;

              req_busy        <= '1' ;
              proc_busy       <= '1' ;

              --  Delete any current event for the request if there is one
              --  then add the new event if one is specified.

              if (req_count = 0) then
                if (req_type_in = '0') then
                  cur_state       <= SCH_STATE_WAIT ;
                else
                  src_address     <= (others => '0') ;
                  cur_state       <= SCH_STATE_ADD ;
                end if ;
              else
                count             <= (others => '0') ;
                src_address       <= (others => '0') ;
                src_read_en       <= '1' ;
                cur_state         <= SCH_STATE_REMOVE ;
              end if ;
            end if ;

          elsif (req_received_in = '0') then
            req_busy          <= '0' ;
            proc_busy         <= '0' ;
          end if ;

        --  Handle week rollover by clearing all next week flags.

        when SCH_STATE_NEWWEEK    =>
          dst_reqid                               <= src_reqid ;
          dst_time (dst_time'length-2 downto 0)   <=
              src_time (dst_time'length-2 downto 0) ;
          dst_time (dst_time'length-1)            <= '0' ;
          dst_write_en                            <= '1' ;
          dst_address                             <= dst_address + 1 ;

          if (src_address = req_count - 1) then
            src_read_en       <= '0' ;
            cur_state         <= SCH_STATE_WAIT ;
          else
            src_address       <= src_address + 1 ;
          end if ;

        --  Next event target has been reached.

        when SCH_STATE_WAKEUP     =>
          if (src_address /= req_count and
              src_time (src_time'length-2 downto 0) = next_target) then
            wake_bits (TO_INTEGER (unsigned (src_reqid)))   <= '1' ;
            count             <= count + 1 ;
            src_address       <= src_address + 1 ;
          else
            next_target       <= src_time (src_time'length-2 downto 0) ;
            dst_address       <= (others => '1') ;
            cur_state         <= SCH_STATE_WAKEDONE ;
          end if ;

        when SCH_STATE_WAKEDONE   =>
          if (src_address /= req_count) then
            dst_reqid         <= src_reqid ;
            dst_time          <= src_time ;
            dst_address       <= dst_address + 1 ;
            dst_write_en      <= '1' ;
            src_address       <= src_address + 1 ;
          else
            src_read_en       <= '0' ;
            dst_write_en      <= '0' ;
            req_count         <= req_count - count ;
            done_out          <= wake_bits ;
            cur_state         <= SCH_STATE_WAIT ;
          end if ;

        --  Remove all entries that match the request ID.

        when SCH_STATE_REMOVE     =>
          if (src_address = req_count) then
            req_count         <= req_count - count ;
            dst_write_en      <= '0' ;

            if (req_type_in = '0') then
              src_read_en     <= '0' ;
              cur_state       <= SCH_STATE_WAIT ;
            else
              src_address     <= (others => '0') ;
              cur_state       <= SCH_STATE_ADD ;
            end if ;
          else
            dst_write_en      <= '1' ;
            dst_reqid         <= src_reqid ;
            dst_time          <= src_time ;
            dst_address       <= src_address - count ;
            src_address       <= src_address + 1 ;

            if (src_reqid = req_id_in) then
              count           <= count + 1 ;
            end if ;
          end if ;

        --  Use an insertion sort to add the request to the list.

        when SCH_STATE_ADD        =>
          if (src_address = req_count) then
            count             <= src_address ;
            dst_address       <= req_count + 1 ;
            src_read_en       <= '0' ;
            cur_state         <= SCH_STATE_INSERT ;

          elsif (src_time > req_time) then
            count             <= src_address ;
            dst_address       <= req_count + 1 ;
            src_address       <= req_count - 1 ;
            cur_state         <= SCH_STATE_MOVE ;
          else
            src_address       <= src_address + 1 ;
          end if ;

        when SCH_STATE_MOVE       =>
          dst_write_en        <= '1' ;
          dst_reqid           <= src_reqid ;
          dst_time            <= src_time ;
          dst_address         <= dst_address - 1 ;

          if (src_address = count) then
            src_read_en       <= '0' ;
            cur_state         <= SCH_STATE_INSERT ;
          else
            src_address       <= src_address - 1 ;
          end if ;

        when SCH_STATE_INSERT     =>
          dst_write_en        <= '1' ;
          dst_reqid           <= req_id ;
          dst_time            <= req_time ;
          dst_address         <= dst_address - 1 ;
          req_count           <= req_count + 1 ;

          if (count = 0) then
            next_target       <= req_time (next_target'length-1 downto 0) ;
          end if ;

          cur_state           <= SCH_STATE_WAIT ;

      end case ;
    end if ;
  end process sched ;


end architecture rtl ;
