----------------------------------------------------------------------------
--
--! @file       CrossChipReceive.vhd
--! @brief      Reads a signal array from accross the chip.
--! @details    Provides support for cross chip signals that may arrive
--!             over a significant difference in time.
--! @author     Emery Newlon
--! @date       October 2015
--! @copyright  Copyright (C) 2015 Ross K. Snider and Emery L. Newlon
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Reads an array of signals from accross chip.
--! @details    A cross chip array path may take a significant amount of
--!             time to propagate with the different signals in it
--!             travelling at different rates.  This entity reads the
--!             signals in the array when it receives signals indicating
--!             they are ready.  The array of signals is ready to read after
--!             enough time has passed for all the data to have crossed the
--!             chip.  This is signaled by a latch signal that latches the
--!             data locally.  Another signal indicates the data is valid
--!             and can be used.  This insures that the latch signal and
--!             the local clock signal do not happen simultaniously.  The
--!             data valid signal is never true at the time the latch signal
--!             goes high.
--!             The valid latch signal can be used to latch the data latched
--!             by the previous data latch signal during a time that the
--!             data is valid.  This data can be used when the valid line
--!             is low.
--!
--! @param      data_bits_g     Number of bits in the signal array.
--! @param      clk             Local clock domain's clock.
--! @param      data_latch_in   Latches the data at the receiver on its
--!                             rising edge.
--! @param      data_valid_in   The data is valid an may be read.
--! @param      valid_latch_in  Latches the last latched data during the
--!                             time it is valid for use during the time
--!                             the received data is not valid.
--! @param      data_in         The data that is to be read.
--! @param      data_out        The data that has been read.  It is latched
--!                             on the falling edge of the clock in order to
--!                             provide the most recent data for processes
--!                             that are rising edge triggered.
--! @param      data_ready_out  New data has been received and is ready to
--!                             be read.
--
----------------------------------------------------------------------------

entity CrossChipReceive is

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

end entity CrossChipReceive ;

architecture rtl of CrossChipReceive is

  --  Data bus latched signals both asynchronous and synchronous as well as
  --  the synchronous data valid line used to choose which to return.

  signal data_local_new     : std_logic_vector (data_bits_g-1 downto 0) ;
  signal data_local_old     : std_logic_vector (data_bits_g-1 downto 0) ;
  signal data_local_new_s   : std_logic_vector (data_bits_g-1 downto 0) ;
  signal data_local_old_s   : std_logic_vector (data_bits_g-1 downto 0) ;
  signal data_valid_s       : std_logic ;

  --  New data detected flip flop and associated signals.

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

  signal new_data_clear     : std_logic := '0' ;
  signal new_data_ready     : std_logic ;
  signal data_ready_s       : std_logic := '0' ;

begin

  --------------------------------------------------------------------------
  --  Latch the data at this end of its path.
  --  Latch the last valid data obtained as well.
  --------------------------------------------------------------------------

  latch_data : process (data_latch_in)
  begin
    if (rising_edge (data_latch_in)) then
      data_local_new      <= data_in ;
    end if ;
  end process latch_data ;

  latch_valid : process (valid_latch_in)
  begin
    if (rising_edge (valid_latch_in)) then
      data_local_old      <= data_local_new ;
    end if ;
  end process latch_valid ;

  --------------------------------------------------------------------------
  --  Synchronise the captured data to the local clock domain.
  --------------------------------------------------------------------------

  data_out                <= data_local_new_s
                                when (data_valid_s = '1') else
                             data_local_old_s ;

  data_ready_out          <= data_ready_s ;

  sync_data : process (clk)
  begin
    if (falling_edge (clk)) then
      data_local_new_s    <= data_local_new ;
      data_local_old_s    <= data_local_old ;
      data_valid_s        <= data_valid_in ;

      if (new_data_ready = '1') then
        data_ready_s      <= '1' ;
        new_data_clear    <= '1' ;
      else
        data_ready_s      <= '0' ;
        new_data_clear    <= '0' ;
      end if ;
    end if ;
  end process sync_data ;

  --------------------------------------------------------------------------
  --  Edge triggered detection of new data available when the data valid
  --  line goes high.
  --------------------------------------------------------------------------

  received : SR_FlipFlop
    Generic Map (
      set_edge_detect_g     => '1'
    )
    Port Map (
      reset_in              => new_data_clear,
      set_in                => data_valid_in,
      result_sd_out         => new_data_ready
    ) ;

end architecture rtl ;
