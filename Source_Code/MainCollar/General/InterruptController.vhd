----------------------------------------------------------------------------
--
--! @file       InterruptController.vhd
--! @brief      Implements an interrupt controller.
--! @details    Signals and holds an interrupt line when any of its source
--!             inputs goes high.
--! @author     Emery Newlon
--! @date       July 2015
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
--! @brief      Interrupt Controller
--! @details    Signals and holds an interrupt line when any of its inputs
--!             goes high.  The interrupt line is maintained high until
--!             clears are signalled for all sources that cause it to be
--!             set.  This controller is not clock dependent.  It can be
--!             used to activate a gated clock for modules that handle the
--!             interrupts it generates.
--!
--! @param      source_cnt_g        Number of interrupt sources.
--! @param      number_len_g        Length of the source number returned.
--! @param      prioritized_g       Interrupt sources are prioritized by
--!                                 order in the source vector.  The lowest
--!                                 bits have the highest priority.
--!                                 Otherwise round-robin ordering is used.
--! @param      edge_trigger_g      Trigger on rising edge of the input
--!                                 when set.  Otherwise trigger on high
--!                                 state of the input.  The latter is used
--!                                 if the device generating the source
--!                                 is cleared by the interrupt handler
--!                                 directly.
--! @param      reset               Reset the entity to an initial state.
--! @param      sources_in          Bit vector of interrupt sources.
--!                                 Sources become active when they go high.
--!                                 They do not have to maintain this high
--!                                 state to be considered active.  The
--!                                 lowest bits have the highest priority.
--! @param      sources_out         All source bits that are currently ready
--!                                 to generate the interrupt.
--! @param      active_out          Bit vector of sources with only one bit
--!                                 set in it, that of the source currently
--!                                 being processed.
--! @param      active_no_out       Number of the source (starting at zero)
--!                                 that is being processed.  It will be
--!                                 zero when no source is being processed.
--! @param      clear_in            Sources that have been processed and are
--!                                 no longer active.
--! @param      interrupt_out       An interrupt is active.
--
----------------------------------------------------------------------------

entity InterruptController is

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

end entity InterruptController ;


architecture rtl of InterruptController is

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

  signal input_triggers     : std_logic_vector (source_cnt_g-1 downto 0) ;
  signal sources_in_last    : std_logic_vector (source_cnt_g-1 downto 0) :=
                                      (others => '0') ;

  signal sources_active     : std_logic_vector (source_cnt_g-1 downto 0) ;

  signal active_source      : unsigned (source_cnt_g-1 downto 0) ;
  signal low_priority_mask  : unsigned (source_cnt_g-1 downto 0) ;

  signal update_clk         : std_logic ;

  --  Force signals to be kept through optimization.

  attribute keep            : boolean ;

  attribute keep of update_clk      : signal is true ;

begin

  --  Set the interrupt state when one or more sources are active.  Choose
  --  one to be processed (if the interrupt handler wants to process them
  --  one at a time.)

  interrupt_out           <= '1' when (unsigned (sources_active) /= 0)
                                 else '0' ;

  active_out              <= std_logic_vector (active_source) ;
  active_no_out           <= bit_to_number (std_logic_vector (active_source),
                                            active_no_out'length) ;

  --  Determine which interrupt sources are active.  Once a high level of
  --  a source has been detected the source will remain active until cleared
  --  by the interrupt handler.

  active : SR_FlipFlop
    Generic Map (
      source_cnt_g        => source_cnt_g
    )
    Port Map (
      resets_in           => clears_in,
      sets_in             => input_triggers,
      results_sd_out      => sources_active
    ) ;

  sources_out             <= sources_active ;

  --  Determine source edges since they last reset.

  edge : SR_FlipFlop
    Generic Map (
      source_cnt_g        => source_cnt_g
    )
    Port Map (
      resets_in           => not sources_in,
      sets_in             => sources_active,
      results_sd_out      => sources_in_last
    ) ;

  input_triggers          <= sources_in when (edge_trigger_g = '0') else
                             (sources_in and not sources_in_last) ;

  --  Wait until the active interrupt source has been cleared before
  --  choosing another one.

  update_clk              <= '1' when ((unsigned (clears_in)       = 0) and
                                       (unsigned (sources_active) /= 0))
                                 else '0' ;

  update_active : process (reset, update_clk)
    variable active_low_v : unsigned (sources_active'length-1 downto 0) ;
    variable active_all_v : unsigned (sources_active'length-1 downto 0) ;
    variable active_bit_v : unsigned (sources_active'length-1 downto 0) ;
  begin
    if (reset = '1') then
      active_source       <= (others => '0') ;
      low_priority_mask   <= (others => '0') ;

    elsif (rising_edge (update_clk)) then
      active_low_v        := lsb_find (unsigned (sources_active) and
                                       low_priority_mask) ;
      active_all_v        := lsb_find (unsigned (sources_active)) ;

      if (active_low_v /= 0 and prioritized_g = '0') then
        active_bit_v      := active_low_v ;
      else
        active_bit_v      := active_all_v ;
      end if ;

      active_source       <= active_bit_v ;
      low_priority_mask   <= (not SHIFT_LEFT (active_bit_v, 1)) + 1 ;
    end if ;
  end process update_active ;

end architecture rtl ;
