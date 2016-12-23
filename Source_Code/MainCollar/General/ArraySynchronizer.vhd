----------------------------------------------------------------------------
--
--! @file       ArraySynchronizer.vhd
--! @brief      Synchronizes an array across clock domains.
--! @details    Creates a safe copy of an array in the given clock domain
--!             from that in a different clock domain.
--! @author     Emery Newlon
--! @date       October 2016
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Creates a safe copy of an array from another clock domain.
--! @details    Copies an array from another clock domain whenever that
--!             array changes.
--!
--! @param      data_bits_g     Number of bits in the array.
--! @param      clk             Local clock domain's clock.
--! @param      array_done_out  The array has been copied.
--! @param      array_in        The array to copy.
--! @param      array_out       Copy of the source array in the destination
--!                             clock domain.
--
----------------------------------------------------------------------------

entity ArraySynchronizer is

  Generic (
    data_bits_g             : natural := 8
  ) ;
  Port (
    clk                     : in    std_logic ;
    array_done_out          : out   std_logic ;
    array_in                : in    std_logic_vector (data_bits_g-1
                                                      downto 0) ;
    array_out               : out   std_logic_vector (data_bits_g-1
                                                      downto 0)
  ) ;

end entity ArraySynchronizer ;

architecture rtl of ArraySynchronizer is

  attribute keep            : boolean ;

  signal changed            : std_logic ;
  signal changed_set        : std_logic ;
  signal changed_clear      : std_logic := '1' ;
  signal array_changed      : std_logic := '0' ;
  signal array_changed_s    : std_logic := '0' ;
  signal array_ready_fwl    : std_logic := '0' ;
  signal array_done         : std_logic := '0' ;
  signal array_s            : std_logic_vector (data_bits_g-1 downto 0) :=
                                        (others => '0') ;
  attribute keep of array_s : signal is true ;

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

begin
  array_out                 <= array_s ;
  array_done_out            <= array_done ;

  --  A change in the source array has been detected.

  changed_set               <= '0' when (array_in = array_s) else '1' ;

  changed_detect : SR_FlipFlop
    Port Map (
      reset_in              => changed_clear,
      set_in                => changed_set,
      result_sd_out         => changed
    ) ;

  --------------------------------------------------------------------------
  --  Copy the array when the change has been detected for long enough.
  --------------------------------------------------------------------------

  copy : process (clk)
  begin
    if (falling_edge (clk)) then
      array_changed         <= array_changed_s ;
    elsif (rising_edge (clk)) then
      array_changed_s       <= changed ;

      if (array_changed = '1') then
        changed_clear       <= '1' ;
        array_changed_s     <= '0' ;

        array_s             <= array_in ;
        array_done          <= '1' ;
      else
        changed_clear       <= '0' ;
        array_done          <= '0' ;
      end if ;
    end if ;
  end process copy ;

end architecture rtl ;
