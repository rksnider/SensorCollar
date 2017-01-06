----------------------------------------------------------------------------
--
--! @file       OnOffchedulerWrapper.vhd
--! @brief      Schedule the system's on and off times test.
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


entity OnOffSchedulerWrapper is

  Generic (
    sched_count_g     : natural := 8 ;
    alarm_bytes_g     : natural := 3
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
    on_off_times01_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times02_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times03_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times04_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times05_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times06_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times07_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times08_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times09_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times10_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times11_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times12_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times13_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times14_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times15_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times16_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times17_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times18_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times19_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
    on_off_times20_in : in    std_logic_vector (E70_rangebits_c-1 downto 0) ;
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

end entity OnOffSchedulerWrapper ;


architecture structural of OnOffSchedulerWrapper is

  constant on_off_count_c       : integer := 20 ;

  component OnOffScheduler is

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
  end component OnOffScheduler ;

  signal on_off_times   : std_logic_vector (on_off_times01_in'length *
                                            on_off_count_c-1 downto 0) ;

begin

  on_off_times          <= on_off_times20_in &
                           on_off_times19_in &
                           on_off_times18_in &
                           on_off_times17_in &
                           on_off_times16_in &
                           on_off_times15_in &
                           on_off_times14_in &
                           on_off_times13_in &
                           on_off_times12_in &
                           on_off_times11_in &
                           on_off_times10_in &
                           on_off_times09_in &
                           on_off_times08_in &
                           on_off_times07_in &
                           on_off_times06_in &
                           on_off_times05_in &
                           on_off_times04_in &
                           on_off_times03_in &
                           on_off_times02_in &
                           on_off_times01_in ;

  --  Pass the port information on.

  inst : OnOffScheduler
    Generic Map (
      on_off_count_g    => on_off_count_c
    )
    Port Map (
      reset             => reset,
      clk               => clk,
      rtctime_in        => rtctime_in,
      timingchg_in      => timingchg_in,
      startup_in        => startup_in,
      startup_out       => startup_out,
      shutdown_in       => shutdown_in,
      shutdown_out      => shutdown_out,
      off_in            => off_in,
      off_out           => off_out,
      on_off_times_in   => on_off_times,
      alarm_set_in      => alarm_set_in,
      alarm_set_out     => alarm_set_out,
      alarm_out         => alarm_out,
      sched_req_out     => sched_req_out,
      sched_rcv_in      => sched_rcv_in,
      sched_type_out    => sched_type_out,
      sched_id_out      => sched_id_out,
      sched_delay_out   => sched_delay_out,
      sched_start_in    => sched_start_in,
      sched_start_out   => sched_start_out,
      busy_out          => busy_out
    ) ;


end architecture structural ;
