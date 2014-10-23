----------------------------------------------------------------------------
--
--! @file       PC_UFM.vhd
--! @brief      Power Controller UFM reader.
--! @details    This entity reads the Power Controller's User Accessable
--!             Flash memory sequencially.
--! @author     Emery Newlon
--! @date       October 2014
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Power Controller UFM reader.
--! @details    This entity reads the Power Controller's User Accessable
--!             Flash memory sequencially.
--!
--! @param      reset         Reset the component to its initial state.
--! @param      clk           Driving clock for the component.
--! @param      enable_in     Enable the component to start operating.
--! @param      read_in       Start reading the Flash data.  When this
--!                           is zero it will load the address register
--!                           with zero.
--! @param      data_out      When reading is enabled each clock cycle will
--!                           clock out the next bit in Flash.
--
----------------------------------------------------------------------------

entity PC_UFM is

  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    enable_in             : in    std_logic ;
    read_in               : in    std_logic ;
    data_out              : out   std_logic
  ) ;

end entity PC_UFM ;


architecture rtl of PC_UFM is

  --  Flash control signals.

  signal flash_clk  : std_logic ;
  signal addr_clk   : std_logic ;
  signal addr_shift : std_logic ;
  signal data_clk   : std_logic ;
  signal data_shift : std_logic ;
  signal data_cnt   : unsigned (3 downto 0) ;

  --  UTM megafunction component.  Only read operations will be done.  Thus,
  --  many signals are ignored.

  COMPONENT Flash IS
    PORT
    (
      arclk    : IN STD_LOGIC ;
      ardin    : IN STD_LOGIC ;
      arshft    : IN STD_LOGIC ;
      drclk    : IN STD_LOGIC ;
      drdin    : IN STD_LOGIC ;
      drshft    : IN STD_LOGIC ;
      erase    : IN STD_LOGIC ;
      oscena    : IN STD_LOGIC ;
      program    : IN STD_LOGIC ;
      busy    : OUT STD_LOGIC ;
      drdout    : OUT STD_LOGIC ;
      osc    : OUT STD_LOGIC ;
      rtpbusy    : OUT STD_LOGIC
    );
  END Flash;


begin


  --  UTM megafunction instance.  Only read operations will be done.  Thus,
  --  many signals are ignored.

  UFM : Flash
    Port Map
    (
      arclk         => addr_clk,
      ardin         => '0',
      arshft        => addr_shift,
      drclk         => data_clk,
      drshft        => data_shift,
      drdout        => data_out
    ) ;

  --  The flash clock is only active when the component is enabled.
  --  Zero is clocked into the address register until the read operation
  --  is started.  During the read the address register is incremented
  --  every 16 clocks to load a new word into the shift register.  The
  --  data register is loaded every 16 clocks.  The data is clocked out
  --  every clock cycle during read operations.

  flash_clk     <= clk        when (enable_in = '1')  else '0' ;

  addr_clk      <= flash_clk  when (read_in = '0')    else data_cnt (3) ;
  addr_shift    <= not read_in ;

  data_shift    <= '0'        when (data_cnt = 0)     else '1' ;
  data_clk      <= flash_clk  when (read_in = '1')    else '0' ;


  --------------------------------------------------------------------------
  --  The data counter is used to divide the clock by 16 for reloading
  --  the data register.
  --------------------------------------------------------------------------

  data_counter : process (reset, flash_clk)
  begin
    if (reset = '1') then
      data_cnt        <= (others => '0') ;

    elsif (rising_edge (flash_clk)) then
      if (read_in = '0') then
        data_cnt      <= (others => '0') ;
      else
        data_cnt      <= data_cnt + 1 ;
      end if ;
    end if ;
  end process data_counter ;

end architecture rtl ;
