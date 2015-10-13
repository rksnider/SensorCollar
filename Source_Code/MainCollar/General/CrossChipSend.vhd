----------------------------------------------------------------------------
--
--! @file       CrossChipSend.vhd
--! @brief      Signals a cross-chip signal array is ready to read.
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
--! @brief      Signals that a cross chip signal array can be read.
--! @details    A cross chip array path may take a significant amount of
--!             time to propagate with the different signals in it
--!             travelling at different rates.  This entity signals the data
--!             is ready to read after enough time has passed for all the
--!             data to have crossed the chip.  This is done by generating
--!             a data latch signal on a following edge of the fast clock
--!             after the data ready signal goes high.
--!             If the data ready signal is derived from the fast clock
--!             the data latch signal can follow the data ready signal at
--!             the next clock edge.  Otherwise an extra clock edge delay
--!             is needed.  This takes care of the situation in which the
--!             to clock domains (the data ready and the fast clock domains)
--!             are nearly in sync.  In this situation the time difference
--!             between the data ready and the fast clock's next edge may
--!             be very small, not large enough for all the array's signals
--!             to arrive at their destination before the data latch signal
--!             does.  Adding an extra clock edge delay insures that with
--!             separate clock domains for the data ready and fast clock
--!             the minimum delay between the data ready and data latch
--!             signals is one half a fast clock period while the maximum
--!             delay is one clock period.
--!             The data receiver at the far end may be running in a
--!             different clock domain from the fast clock's.  To prevent
--!             it from reading the signal array at the same moment as it
--!             is latched by the data latch signal, a data valid signal is
--!             also sent.  This signal is not true across the time the
--!             data latch signal goes high.  The data receiver should not
--!             read the latched data unless this signal is high to prevent
--!             it from reading the new value on some of the array's signals
--!             and the old value on others if the read takes place at the
--!             same time as the data latch goes high.
--!             To help with this situation the valid latch signal can be
--!             used.  This signal is high for one half a fast clock cycle
--!             one half a fast clock cycle after the data valid line goes
--!             high.  If used to latch the data latched by the data latch
--!             signal the result can be used during the next time the
--!             valid data line is low.  This results in a multiplexer that
--!             uses the data latched by the data latch signal when the
--!             valid line is high and the data latched by the valid latch
--!             signal when the valid line is low.
--!
--! @param      fast_latch_g    Fast latching can be done as the fast clock
--!                             and data ready are in the same clock domain.
--! @param      fast_clk        Fast clock that is used to generated the
--!                             latch signal.
--! @param      data_ready_in   Data is ready and in-transit accross the
--!                             chip.
--! @param      data_latch_out  Latch the data at the receiver on the rising
--!                             edge.
--! @param      data_valid_out  The data is valid an may be read.
--! @param      valid_latch_out The data can be lached when valid for use
--!                             during the next invalid data interval.
--
----------------------------------------------------------------------------

entity CrossChipSend is

  Generic (
    fast_latch_g          : std_logic := '1'
  ) ;
  Port (
    fast_clk              : in    std_logic ;
    data_ready_in         : in    std_logic ;
    data_latch_out        : out   std_logic ;
    data_valid_out        : out   std_logic ;
    valid_latch_out       : out   std_logic
  ) ;

end entity CrossChipSend ;

--! @details    The following timing diagrams show how the input and output
--!             signals relate in time.  All data reading and capturing
--!             takes place on rising edges.  The signal abreviations are:
--!
--!             DR is data ready.  It triggers the other signals except for
--!             the clocks.
--!             FC-SCD is the fast clock when in the same clock domain as
--!             the data ready.
--!             DL-SCD is the data latch when the fast clock and data ready
--!             are in the same clock domain.  It starts on the next clock
--!             edge after the data ready goes high.
--!             FC-DCD is the fast clock when in a different clock domain
--!             from the data ready.
--!             DL-DCD is the data latch when the fast clock and the data
--!             ready are in different clock domains.  In the case shown
--!             the time difference between the data ready and next clock
--!             edge is very short.  Thus the data latch must be two clock
--!             edges from the data ready going high to insure that there is
--!             enough time for all data lines to reach the destination
--!             before the data latch captures them there.
--!             DV is the data valid signal.  It must be false around the
--!             time the data latch goes high to insure that the data
--!             captured by the data latch is not read during that capture,
--!             which could lead to some bits being recently captured and
--!             some bits being from a previous capture.
--!             VL is the valid latch signal.  It will latch the newly
--!             captured data into another latch safely after that data
--!             has been completely captured.
--!             RC-DCD is the remote clock in a diffrent clock domain from
--!             all other clocks.  It can try to read data at the same time
--!             it is being captured by the latches.  To avoid this problem
--!             the data read is from the data latch if the data valid line
--!             is high.  Otherwise it is from valid latch which will be
--!             somewhat older.
--!
--!                   +----+----+
--! DR                |         |
--!     ----+----+----+         +----+----+----+
--!                   .
--!         +----+    +----+    +----+    +----+    +----+    +----+
--! FC-SCD  |    |    |    |    |    |    |    |    |    |    |    |
--!     ----+    +----+    +----+    +----+    +----+    +----+    +----
--!                   .
--!                   .    +----+
--! DL-SCD            .    |    |
--!     ----+----+----+----+    +----+----+----+
--!                   .
--!      +----+    +----+    +----+    +----+    +----+    +----+
--! FC-DCD    |    |  . |    |    |    |    |    |    |    |    |
--!           +----+  . +----+    +----+    +----+    +----+    +----
--!                   .
--!                   .      +----+
--! DL-DCD            .      |    |
--!     -+----+----+----+----+    +----+----+----+
--!                   .      .
--!     -+----+----+--+      .    +----+----+----+
--! DV                |      .    |
--!                   +-+----+----+
--!                          .
--!                          .         +----+
--! VL                       .         |    |
--!     -+----+----+----+----+----+----+    +----+
--!                          .
--!      +----+----+         +----+----+         +----+----+
--! RC-DCD         |         |         |         |         |
--!                +----+----+         +----+----+         +----+----
--!

architecture rtl of CrossChipSend is

  signal data_latch           : std_logic ;
  signal data_valid           : std_logic ;
  signal valid_latch          : std_logic ;

  signal data_ready_fwl       : std_logic ;
  signal data_ready_fwl_high  : std_logic := '0' ;
  signal data_ready_fwl_low   : std_logic := '0' ;
  signal clock_high           : std_logic := '0' ;
  signal clock_low            : std_logic := '0' ;

  signal data_valid_fwl       : std_logic ;
  signal data_valid_fwl_high  : std_logic := '0' ;
  signal data_valid_fwl_low   : std_logic := '0' ;
  signal valid_high           : std_logic := '0' ;
  signal valid_low            : std_logic := '0' ;

begin

  data_latch_out          <= data_latch ;
  data_valid_out          <= data_valid ;
  valid_latch_out         <= valid_latch ;

  --  When using fast latching the data data ready signal is sent on the
  --  first fast clock edge.  Otherwise it is set on the second clock edge.

  data_latch              <= (clock_high or clock_low)
                                  when (fast_latch_g = '1') else
                             (clock_high and clock_low) ;

  --  Data is valid at all times except the interval between when data
  --  ready goes high and data latch goes low.

  data_valid              <= not (data_ready_in and not data_ready_fwl)
                             and not data_latch ;

  --  The data valid latch signal is high for one half clock cycle at
  --  one half clock cycle after data valid goes high.

  valid_latch             <= valid_high or valid_low ;

  --------------------------------------------------------------------------
  --  Data ready triggers the data latch.
  --------------------------------------------------------------------------

  data_ready_fwl          <= data_ready_fwl_high and data_ready_fwl_low ;
  data_valid_fwl          <= data_valid_fwl_high and data_valid_fwl_low ;

  data_latch_trigger : process (fast_clk)
  begin
    if (rising_edge (fast_clk)) then

      --  Set the clock high line high when data ready is first detected.

      if (data_ready_fwl /= data_ready_in) then
        if (data_ready_in = '1' and clock_high = '0' and
            (fast_latch_g = '0' or  clock_low  = '0')) then

          clock_high            <= '1' ;
        else
          clock_high            <= '0' ;
        end if ;
      else
        clock_high              <= '0' ;
      end if ;

      data_ready_fwl_high       <= data_ready_in ;

      --  Set the valid high line when data valid is first determined.

      if (data_valid_fwl /= data_valid) then
        if (data_valid = '1' and valid_high = '0' and valid_low = '0') then
          valid_high            <= '1' ;
        else
          valid_high            <= '0' ;
        end if ;
      else
        valid_high              <= '0' ;
      end if ;

      data_valid_fwl_high       <= data_valid_fwl ;

    --  Falling edge actions.

    elsif (falling_edge (fast_clk)) then

      --  Set the clock low line high when data ready is first detected.

      if (data_ready_fwl /= data_ready_in) then

        if (data_ready_in = '1' and clock_low  = '0' and
            (fast_latch_g = '0' or  clock_high = '0')) then

          clock_low           <= '1' ;
        else
          clock_low           <= '0' ;
        end if ;
      else
        clock_low             <= '0' ;
      end if ;

      data_ready_fwl_low      <= data_ready_in ;

      --  Set the valid low line when data valid is first determined.

      if (data_valid_fwl /= data_valid) then
        if (data_valid = '1' and valid_high = '0' and valid_low = '0') then
          valid_low             <= '1' ;
        else
          valid_low             <= '0' ;
        end if ;
      else
        valid_low               <= '0' ;
      end if ;

      data_valid_fwl_low        <= data_valid_fwl ;

    end if ;
  end process data_latch_trigger ;

end architecture rtl ;
