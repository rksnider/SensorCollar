----------------------------------------------------------------------------
--
--! @file       ParseNumbericField.vhd
--! @brief      Parses Numeric ASCII Fields.
--! @details    Parses a sequence of ASCII characters as a numeric field and
--!             returns the binary results.
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library GENERAL ;               --! Utilities
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Numeric ASCII Field Parser.
--! @details    Parse a sequence of ASCII characters as a numeric field and
--!             return its binary value.
--!
--! @param      result_bits_g Number of bits in the fields binary result.
--! @param      max_digits_g  Maximum number of digits the field can
--!                           contain.
--! @param      reset         Reset the field prior to parsing a new field.
--! @param      clk           Clock used for multi-states per character.
--! @param      inchar_in     The character to parse and add to the field.
--! @param      inready_in    A new characater is ready for processing.
--! @param      multctl_in    Determines the multiplier to be applied to the
--!                           result before adding the next character's
--!                           value to it.  '0' times 10, '1' times 6.
--! @param      valid_out     The results are currently still valid when
--!                           set.
--! @param      result_out    The binary result of parsing the field so far.
--! @param      digits_out    The number of digits used to form the result.
--! @param      decimals_out  The number of decimal digits in the result.
--
----------------------------------------------------------------------------

entity ParseNumericField is

  Generic (
    result_bits_g   : natural := 32 ;
    max_digits_g    : natural := 10
  ) ;
  Port (
    reset           : in    std_logic ;
    clk             : in    std_logic ;
    inchar_in       : in    std_logic_vector (7 downto 0) ;
    inready_in      : in    std_logic ;
    multctl_in      : in    std_logic_vector (max_digits_g-1 downto 0) ;
    valid_out       : out   std_logic ;
    result_out      : out   unsigned (result_bits_g-1 downto 0) ;
    digits_out      : out   unsigned (const_bits (max_digits_g)-1
                                      downto 0) ;
    decimals_out    : out   unsigned (const_bits (max_digits_g)))
                                      downto 0)
  ) ;

end entity ParseNumericField ;


architecture rtl of ParseNumericField is

  --  Internal Signals.

  signal multipliers    : std_logic_vector (max_digits_g-1 downto 0) ;
  signal result_buff    : unsigned (result_bits_g-1 downto 0) ;
  signal digit_count    : unsigned (const_bits (max_digits_g)-1 downto 0) ;
  signal dec_count      : unsigned (const_bits (max_digits_g)-1 downto 0) ;
  signal decimalpnt     : std_logic ;

begin

  result_out      <= result_buff ;
  digits_out      <= digit_count ;
  decimals_out    <= dec_count ;


  --------------------------------------------------------------------------
  --  Process the characters.
  --------------------------------------------------------------------------

  parse_field:  process (reset, inready_in)
  begin
    --  Reset the state before parsing characters.

    if reset = '1' then
      result_buff <= (others => '0') ;
      digit_count <= (others => '0') ;
      dec_count   <= (others => '0') ;
      decimalpnt  <= '0' ;
      multipliers <= (others => '0') ;
      valid_out       <= '1' ;

    --  A new character is available.

    elsif (rising_edge (inready)) then

      --  Add a digit to the result.

      if (inchar_in (7 downto 4) = 3 and inchar_in (3 downto 0) <= 9) then

        --  The first digit is placed directly into the result and the
        --  multiplier field is set for following digits.

        if (digit_count = 0) then
          multipliers <= multctl_in ;
          result_buff <= TO_UNSIGNED (inchar_in (3 downto 0),
                                      result_bits_g) ;

        --  Multiply the previous result by proper amount and add in the
        --  new character's value.

        else
          if (multipliers (max_digits_g-1) = '1') then
            result_buff <= result_buff *  6 +
                           UNSIGNED (inchar_in (3 downto 0)) ;
          else
            result_buff <= result_buff * 10 +
                           UNSIGNED (inchar_in (3 downto 0)) ;
          end if ;

          --  Shift the multiplier control vector by one for the next digit.

          multipliers (max_digits_g-1 downto 1) <=
                           multipliers (max_digits_g-2 downto 0) ;
        end if ;

        digit_count <= digit_count + 1 ;

        --  Count the decimal digits if a decimal point has been
        --  encountered.

        if (decimalpnt = '1') then
          dec_count <= dec_count + 1 ;
        end if ;

      --  Start collecting decimal digits when a decimal point is found.

      elsif (decimalpnt = '0' and inchar_in = ".") then
        decimalpnt <= '1' ;

      --  The character is invalid making the field invalid.

      else
        valid_out <= '0' ;

      end if ;
    end if ;
  end process parse_field ;

end architecture rtl ;
