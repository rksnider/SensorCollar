----------------------------------------------------------------------------
--
--! @file       RTC_Load.vhd
--! @brief      Load the RTC clock over the JTAG
--! @details    Provides signals for setting the RTC clock from the JTAG.
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
use GENERAL.FORMATSECONDS_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Load the RTC clock from JTAG or by signal.
--! @details    Provides an RTC clock value from JTAG or an external port.
--!
--! @param      clk                   Clock used to logic.
--! @param      new_rtc_in            RTC time from external source.
--! @param      new_rtc_set_in        Pulsed high to set RTC time.
--! @param      rtc_out               RTC time to set.
--! @param      rtc_set_out           Set the RTC time.
--
----------------------------------------------------------------------------

entity RTC_Load is

  Port (
    clk                   : in    std_logic ;
    new_rtc_in            : in    unsigned (epoch70_secbits_c-1 downto 0) ;
    new_rtc_set_in        : in    std_logic ;
    rtc_out               : out   unsigned (epoch70_secbits_c-1 downto 0) ;
    rtc_set_out           : out   std_logic
  ) ;

end entity RTC_Load ;


architecture rtl of RTC_Load is

  component RTC_Set is
    port (
      source_clk : in  std_logic                     := '0'; -- source_clk.clk
      source     : out std_logic_vector(32 downto 0)         --    sources.source
    );
  end component RTC_Set;

  signal probe_data       : std_logic_vector (rtc_out'length downto 0) ;

begin

  RTC_probe : RTC_Set
    port map (
      source_clk          => clk,
      source              => probe_data
    ) ;

  rtc_set_out   <= new_rtc_set_in or probe_data (probe_data'length-1) ;

  rtc_out       <= new_rtc_in
                      when (new_rtc_set_in = '1') else
                   unsigned (probe_data (rtc_out'length-1 downto 0))
                      when (probe_data (probe_data'length-1) = '1') else
                   (others => '0') ;

end rtl ;
