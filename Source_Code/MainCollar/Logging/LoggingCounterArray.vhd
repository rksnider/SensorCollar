----------------------------------------------------------------------------
--
--! @file       LoggingCounterArray.vhd
--! @brief      Logging Counter Array Updater.
--! @details    Logging Counters are incremented when their signal goes
--!             high.
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

library IEEE ;                  -- Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   -- Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      -- Use numeric standard.

library GENERAL ;
use GENERAL.UTILITIES_PKG.ALL ; --  Generally useful functions and
                                --  constants.

----------------------------------------------------------------------------
--
--! @brief      Logging Counter Array.
--! @details    A Logging Counter increments its count when its increment
--!             signal is high.  The counters are stored in dual port
--!             memory with one port controlled by the Logging Counter
--!             Array controller.
--!
--! @param      clk_freq_g        Frequency of the clock in cycles
--!                               per second.
--! @param      counter_size_g    Number of bits in each counter.
--! @param      address_size_g    Number of address bits for counters.
--! @param      counters_g        Number of counters in the array.
--! @param      rollover_g        Allow counters to roll over to zero when
--!                               their max value is reached when set.
--! @param      reset             Reset the component when high.
--! @param      clk               Clock that drives the component.
--! @param      mem_clk_out       Counter memory clock.
--! @param      mem_datafrom_in   Data read from the counter memory.
--! @param      mem_datato_out    Data written to the counter memory.
--! @param      mem_address_out   Address of the counter to access.
--! @param      mem_read_en_out   Counter memory read enable signal.
--! @param      mem_write_en_out  Counter memory write enable signal.
--! @param      counter_incr_in   Array of counter increment signals.
--! @param      counter_clear_in  When set all counter values are cleared.
--! @param      counter_lock_in   Lock the counters.  Don't update any when
--!                               this is set.  Prevents reading multi-byte
--!                               counters whose bytes have changed between
--!                               reading each byte.
--! @param      counters_changed_out  The counters have changed since last
--!                                   cleared.
--
----------------------------------------------------------------------------

entity LoggingCounterArray is

  Generic (
    clk_freq_g            : natural     := 10e6 ;
    counter_size_g        : natural     := 8 ;
    address_size_g        : natural     := 9 ;
    counters_g            : natural     := 1 ;
    rollover_g            : std_logic   := '0'
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;

    mem_clk_out           : out   std_logic ;
    mem_datafrom_in       : in    unsigned (counter_size_g-1 downto 0) ;
    mem_datato_out        : out   unsigned (counter_size_g-1 downto 0) ;
    mem_address_out       : out   unsigned (address_size_g-1 downto 0) ;
    mem_read_en_out       : out   std_logic ;
    mem_write_en_out      : out   std_logic ;

    counter_incr_in       : in    std_logic_vector (counters_g-1 downto 0) ;
    counter_clear_in      : in    std_logic ;
    counter_lock_in       : in    std_logic ;

    counters_changed_out  : out   std_logic
  ) ;

end entity LoggingCounterArray ;


architecture rtl of LoggingCounterArray is

  --  Determine the maximum value that a counter can have.

  constant mem_datamax_c  : unsigned (counter_size_g-1 downto 0) :=
            TO_UNSIGNED (2 ** counter_size_g - 1, counter_size_g) ;

  --  Counter increment edge dectetion, counters waiting to be
  --  incremented, and the counter currently being processed.

  signal counter_incr_last  : std_logic_vector (counters_g-1 downto 0) ;
  signal counters_waiting   : std_logic_vector (counters_g-1 downto 0) ;
  signal counter_selected   : std_logic_vector (counters_g-1 downto 0) ;

  --  Clear counter signals.

  signal clear_counters : std_logic ;
  signal clear_address  : unsigned (const_bits (counters_g)-1 downto 0) ;

begin

  --  Memory clock is the inverse of the input clock to allow the data
  --  read/writes to take place in one clock cycle.

  mem_clk_out       <= not clk ;


  --------------------------------------------------------------------------
  --  Increment a counter when an increment request is made.
  --  Clear all counters initially and when requested.
  --------------------------------------------------------------------------

  incr_counter : process (reset, clk)
    variable counter_bit_v    : std_logic_vector (counters_g-1 downto 0) ;
    variable counter_bitset_v : std_logic_vector (counters_g-1 downto 0) ;
    variable address_v        : unsigned (address_size_g-1 downto 0) ;
  begin
    if (reset = '1') then
      counter_selected        <= (others => '0') ;
      counters_waiting        <= (others => '0') ;
      counter_incr_last       <= (others => '0') ;
      clear_address           <= TO_UNSIGNED (counters_g,
                                              clear_address'length) ;
      mem_read_en_out         <= '0' ;
      mem_write_en_out        <= '0' ;
      mem_datato_out          <= (others => '0') ;
      mem_address_out         <= (others => '0') ;

      counters_changed_out    <= '0' ;

    elsif (rising_edge (clk)) then
      mem_read_en_out         <= '0' ;
      mem_write_en_out        <= '0' ;

      --  Determine which counters need to be incremented.  The rising edge
      --  of a counter's increment bit is used to determine that it should
      --  be added.  The counter currently being processed is removed from
      --  those waiting to be incremented.

      counter_bitset_v        := (counter_incr_in and
                                  not counter_incr_last) or
                                 (counters_waiting and
                                  not counter_selected) ;
      counters_waiting        <= counter_bitset_v ;
      counter_incr_last       <= counter_incr_in ;

      --  Clear all counters when the clear flag is set.

      if (counter_clear_in = '1') then
        clear_address         <= TO_UNSIGNED (counters_g,
                                              clear_address'length) ;
        counters_changed_out  <= '0' ;

      elsif (clear_address /= 0) then
        address_v             := RESIZE (clear_address - 1,
                                         address_size_g) ;
        mem_address_out       <= address_v ;
        mem_datato_out        <= (others => '0') ;
        mem_write_en_out      <= '1' ;
        clear_address         <= address_v ;
        counter_selected      <= (others => '0') ;

      else

        --  Select a new counter to increment.

        if (unsigned (counter_selected) = 0) then
          if (unsigned (counter_bitset_v) /= 0 and
              counter_lock_in = '0') then

            counter_bit_v     :=
                std_logic_vector (lsb_find (unsigned (counter_bitset_v))) ;
            counter_selected  <= counter_bit_v ;
            mem_address_out   <= bit_to_number (counter_bit_v,
                                                address_size_g) ;
            mem_read_en_out   <= '1' ;
          end if ;

        --  Increment the selected counter.

        else
          counter_selected    <= (others => '0') ;

          if (rollover_g = '1' or mem_datafrom_in /= mem_datamax_c) then
            mem_datato_out    <= mem_datafrom_in + 1 ;
            mem_write_en_out  <= '1' ;
            counters_changed  <= '1' ;
          end if ;
        end if ;
      end if ;
    end if ;
  end process incr_counter ;

end rtl ;
