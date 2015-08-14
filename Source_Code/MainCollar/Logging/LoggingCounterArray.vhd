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
--! @param      clk               Clock that drives the component.  This
--!                               can be a gated clock that is active when
--!                               the component is busy.
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
--! @param      busy_out          The component is busy processing data.
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

    mem_datafrom_in       : in    unsigned (counter_size_g-1 downto 0) ;
    mem_datato_out        : out   unsigned (counter_size_g-1 downto 0) ;
    mem_address_out       : out   unsigned (address_size_g-1 downto 0) ;
    mem_read_en_out       : out   std_logic ;
    mem_write_en_out      : out   std_logic ;

    counter_incr_in       : in    std_logic_vector (counters_g-1 downto 0) ;
    counter_clear_in      : in    std_logic ;
    counter_lock_in       : in    std_logic ;

    counters_changed_out  : out   std_logic ;
    busy_out              : out   std_logic
  ) ;

end entity LoggingCounterArray ;


architecture rtl of LoggingCounterArray is

  --  Handle incoming counter increment requests.

  component InterruptController is
    Generic (
      source_cnt_g          : natural   :=  1 ;
      number_len_g          : natural   :=  1 ;
      prioritized_g         : std_logic := '1' ;
      edge_trigger_g        : std_logic := '1'
    ) ;
    Port (
      reset                 : in    std_logic ;
      sources_in            : in    std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      sources_out           : out   std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      active_out            : out   std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      active_no_out         : out   unsigned (number_len_g-1 downto 0) ;
      clears_in             : in    std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      interrupt_out         : out   std_logic
    ) ;
  end component InterruptController ;

  --  Handle clear counter requests.

  component SR_FlipFlop is
    Generic (
      source_cnt_g          : natural   :=  1
    ) ;
    Port (
      resets_in             : in    std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      sets_in               : in    std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      results_rd_out        : out   std_logic_vector (source_cnt_g-1
                                                      downto 0) ;
      results_sd_out        : out   std_logic_vector (source_cnt_g-1
                                                      downto 0)
    ) ;
  end component SR_FlipFlop ;

  --  Determine the maximum value that a counter can have.

  constant mem_datamax_c  : unsigned (counter_size_g-1 downto 0) :=
            TO_UNSIGNED (2 ** counter_size_g - 1, counter_size_g) ;

  --  Counter currently being processed, counter clear signals, and
  --  the memory control flags.

  signal read_enable      : std_logic ;
  signal write_enable     : std_logic ;

  signal counter_selected : std_logic_vector (counters_g-1 downto 0) ;
  signal counter_number   : unsigned (address_size_g-1 downto 0) ;

  signal clear_counters   : std_logic_vector (counters_g-1 downto 0) ;
  signal clear_address    : unsigned (const_bits (counters_g)-1 downto 0) ;

  --  Busy signalling.

  signal counter_clear    : std_logic ;

  signal clear_busy       : std_logic ;
  signal incr_busy        : std_logic ;

begin

  mem_read_en_out         <= read_enable ;
  mem_write_en_out        <= write_enable ;

  busy_out                <= incr_busy          or
                             clear_busy         or
                             counter_clear      or
                             write_enable ;

  --  Capture increment requests while the logger may be sleeping.

  intctl : InterruptController
    Generic Map (
      source_cnt_g        => counters_g,
      number_len_g        => address_size_g,
      prioritized_g       => '0',
      edge_trigger_g      => '1'
    )
    Port Map (
      reset               => reset,
      sources_in          => counter_incr_in,
      active_out          => counter_selected,
      active_no_out       => counter_number,
      clears_in           => clear_counters,
      interrupt_out       => incr_busy
    ) ;

  --  Capture clear requests while logger may be sleeping.

  clrcnt : SR_FlipFlop
    Generic Map (
      source_cnt_g        => 1
    )
    Port Map (
      resets_in      (0)  => clear_busy,
      sets_in        (0)  => counter_clear_in,
      results_sd_out (0)  => counter_clear
    ) ;

  --------------------------------------------------------------------------
  --  Increment a counter when an increment request is made.
  --  Clear all counters initially and when requested.
  --------------------------------------------------------------------------

  incr_counter : process (reset, clk)
    variable counter_bit_v    : std_logic_vector (counters_g-1 downto 0) ;
    variable address_v        : unsigned (address_size_g-1 downto 0) ;
  begin
    if (reset = '1') then
      clear_busy                  <= '0' ;
      clear_address               <= TO_UNSIGNED (counters_g,
                                                  clear_address'length) ;
      clear_counters              <= (others => '0') ;
      read_enable                 <= '0' ;
      write_enable                <= '0' ;
      mem_datato_out              <= (others => '0') ;
      mem_address_out             <= (others => '0') ;

      counters_changed_out        <= '0' ;

    elsif (rising_edge (clk)) then

      --  Clear all counters when the clear flag is set.

      if (counter_clear = '1') then
        clear_busy                <= '1' ;
        read_enable               <= '0' ;
        clear_address             <= TO_UNSIGNED (counters_g,
                                                  clear_address'length) ;
        clear_counters            <= (others => '1') ;
        counters_changed_out      <= '0' ;

      elsif (clear_address /= 0) then
        address_v                 := RESIZE (clear_address - 1,
                                             address_size_g) ;
        mem_address_out           <= address_v ;
        mem_datato_out            <= (others => '0') ;
        write_enable              <= '1' ;
        clear_address             <= RESIZE (address_v,
                                             clear_address'length) ;

      else
        clear_busy                <= '0' ;
        clear_counters            <= (others => '0') ;

        --  Terminate increment steps.

        if (write_enable = '1') then
          write_enable            <= '0' ;
          counters_changed_out    <= '0' ;

        --  Increment the selected counter.

        elsif (read_enable = '1') then
          read_enable             <= '0' ;

          clear_counters          <= counter_selected ;

          if (rollover_g = '1' or mem_datafrom_in /= mem_datamax_c) then
            mem_datato_out        <= mem_datafrom_in + 1 ;
            write_enable          <= '1' ;
            counters_changed_out  <= '1' ;
          end if ;

        --  Select a new counter to increment.

        elsif (unsigned (counter_selected) /= 0 and
               counter_lock_in = '0') then

          mem_address_out         <= counter_number ;
          read_enable             <= '1' ;
        end if ;
      end if ;
    end if ;
  end process incr_counter ;

end rtl ;
