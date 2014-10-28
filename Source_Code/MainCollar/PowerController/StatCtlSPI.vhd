----------------------------------------------------------------------------
--
--! @file       StatCtlSPI.vhd
--! @brief      Power Controller Status/Control Registers SPI interface.
--! @details    The FPGA reads the Power Controller Status and User Flash
--!             Memory while writing the Power Controller Control Register
--!             via an SPI interface.
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
--! @brief      Power Controller Status/Control Registers SPI interface.
--! @details    The FPGA reads the Power Controller Status and User Flash
--!             Memory while writing the Power Controller Control Register
--!             via an SPI interface.  The SPI interface uses CPOL = 1,
--!             CPHA = 1 as it is a standard where everything is driven by
--!             the master clock.  (In CPOL = 0 data must be put on the
--!             bus at chip select, before the clock is driven.)
--!             This entity is fed with an interted clock and an inverted
--!             nCS in order to comply with the standard that all clocks
--!             are rising edge (mostly) and all logic is active high.
--!
--! @param      status_bits_g   The number of bits in the Power Controller's
--!                             status register.
--! @param      control_bits_g  The number of bits in the Power Controller's
--!                             control register.
--! @param      reset           Reset the component to its initial state.
--! @param      clk             Driving clock for the component.
--! @param      status_in       The Power Controller's status register.
--! @param      status_chg_in   Set when the status register has changed
--!                             since it was last tranferred by SPI.
--! @param      control_out     The Power Controller's control register.
--! @param      enable_in       Enable the component to start operating.  It
--!                             is the inverse of the Chip Select nCS for
--!                             the SPI bus.
--! @param      data_in         MOSI line from the SPI bus.  The Control
--!                             register contents are shifted in over this
--!                             line.  The LAST bits shifted in will be
--!                             loaded into the control register.  Any
--!                             earlier bits will be discarded.
--! @param      data_out        MISO line from the SPI bus.  The Status
--!                             register contents are shifted out over this
--!                             line, followed by the contents of the User
--!                             Flash Memory if the enable line stays high
--!                             long enough for this.
--
----------------------------------------------------------------------------

entity StatCtlSPI is

  Generic (
    status_bits_g           : natural := 1 ;
    control_bits_g          : natural := 1
  ) ;
  Port (
    reset                   : in    std_logic ;
    clk                     : in    std_logic ;
    status_in               : in    std_logic_vector (status_bits_g-1
                                                      downto 0) ;
    status_chg_out          : out   std_logic ;
    control_out             : out   std_logic_vector (control_bits_g-1
                                                      downto 0) ;
    enable_in               : in    std_logic ;
    data_in                 : in    std_logic ;
    data_out                : out   std_logic
  ) ;

end entity StatCtlSPI ;


architecture rtl of StatCtlSPI is

  --  Initialize the SPI shifting process on reset and enable.

  signal spi_init           : std_logic ;

  --  Status register when last shifted out the SPI and the status
  --  register being shifted out the SPI.  Flash is shifted out after
  --  the status register is.

  signal status_saved       : std_logic_vector (status_bits_g-1 downto 0) :=
                                  (others => '0') ;
  signal status_shift       : std_logic_vector (status_bits_g-1 downto 0) ;

  signal status_shift_cnt   : unsigned (const_bits (status_bits_g-1) - 1
                                        downto 0) ;
  signal flash_read         : std_logic ;
  signal flash_bit          : std_logic ;

  --  Control register is shifted in.

  signal control_shift      : std_logic_vector (control_bits_g-1 downto 0) ;
  signal control_shift_cnt  : unsigned (const_bits (control_bits_g-1) - 1
                                        downto 0) ;

  --  Power Controller's User Flash Memory access component.

  component PC_UFM is
    Port (
      reset                 : in    std_logic ;
      clk                   : in    std_logic ;
      enable_in             : in    std_logic ;
      read_in               : in    std_logic ;
      data_out              : out   std_logic
    ) ;
  end component PC_UFM ;

begin

  --  The status changed condition occurs when the status register no longer
  --  matches its value when it was last transferred over the SPI.

  status_chg_out          <= '0' when (status_in = status_saved) else '1' ;

  --  Power Controller's User Flash Memory access component.

  flash : PC_UFM
    Port Map (
      reset               => reset,
      clk                 => clk,
      enable_in           => enable_in,
      read_in             => flash_read,
      data_out            => flash_bit
    ) ;

  --  Initialize the SPI shift process on a reset and not enable.

  spi_init                <= reset or not enable_in ;

  --------------------------------------------------------------------------
  --  Shift the data into and out of the SPI when it is enabled.
  --------------------------------------------------------------------------

  SPI_shift : process (spi_init, clk)
    variable control_temp   : std_logic_vector (control_bits_g-1 downto 0) ;
  begin
    if (spi_init = '1') then
      control_shift         <= (others => '0') ;
      control_shift_cnt     <= (others => '0') ;
      status_shift_cnt      <= (others => '0') ;
      flash_read            <= '0' ;

    elsif (rising_edge (clk)) then

      --  Shift the status register out until it is done, then shift out
      --  Flash data.

      elsif (status_shift_cnt /= status_bits_g) then
        if (status_shift_cnt = 0) then

          --  Initialize the shift out operations.

          status_saved      <= status_in ;
          data_out          <= status_in (status_bits_g-1) ;

          status_shift (0)  <= '0' ;
          status_shift (status_bits_g-1 downto 1) <=
                        status_in (status_bits_g-2 downto 0) ;
        else
          --  Output from the shift register.

          data_out          <= status_shift (status_bits_g-1) ;

          status_shift (status_bits_g-1 downto 1) <=
                        status_shift (status_bits_g-2 downto 0) ;
        end if ;

        status_shift_cnt    <= status_shift_cnt + 1 ;

        --  Output from the flash memory.
      else
        flash_read          <= '1' ;
        data_out            <= flash_bit ;
      end if ;

    else

      --  Shift the control register in and save it when it is full.

      if (control_shift_cnt /= control_bits_g) then
        control_shift_cnt   <= control_shift_cnt + 1 ;

        control_temp (control_bits_g-1 downto 1)    :=
                      control_shift (control_bits_g-2 downto 0) ;
        control_temp (0)    := data_in ;

        if (control_shift_cnt = control_bits_g - 1) then
          control_out       <= control_temp ;
        else
          control_shift     <= control_temp ;
        end if ;
      end if ;
    end if ;
  end process SPI_shift ;


end architecture rtl ;
