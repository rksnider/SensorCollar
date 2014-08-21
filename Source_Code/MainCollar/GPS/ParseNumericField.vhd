------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Parses Numeric ASCII Fields.
--! @details    Parses a sequence of ASCII characters as a numeric field and
--!             returns the binary results.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library WORK ;                  --! Utilities
use WORK.UTILITIES.ALL ;


------------------------------------------------------------------------------
--
--! @brief      Numeric ASCII Field Parser.
--! @details    Parse a sequence of ASCII characters as a numeric field and
--!             return its binary value.
--!
--! @param      RESULT_BITS     Number of bits in the fields binary result.
--! @param      MAX_DIGITS      Maximum number of digits the field can contain.
--! @param      reset           Reset the field prior to parsing a new field.
--! @param      clk             Clock used for multi-states per character.
--! @param      inchar          The character to parse and add to the field.
--! @param      inready         A new characater is ready for processing.
--! @param      multctl         Determines the multiplier to be applied to the
--!                             result before adding the next character's value
--!                             to it.  '0' times 10, '1' times 6.
--! @param      valid           The results are currently still valid when set.
--! @param      result          The binary result of parsing the field so far.
--! @param      digits          The number of digits used to form the result.
--! @param      decimals        The number of decimal digits in the result.
--
------------------------------------------------------------------------------

entity ParseNumericField is

  Generic (
    RESULT_BITS         : natural := 32 ;
    MAX_DIGITS          : natural := 10
  ) ;
  Port (
    reset               : in    std_logic ;
    clk                 : in    std_logic ;
    inchar              : in    std_logic_vector (7 downto 0) ;
    inready             : in    std_logic ;
    multctl             : in    std_logic_vector (MAX_DIGITS-1 downto 0) ;
    valid               : out   std_logic ;
    result              : out   unsigned (RESULT_BITS-1 downto 0) ;
    digits              : out   unsigned (const_bits (MAX_DIGITS)-1
                                          downto 0) ;
    decimals            : out   unsigned (const_bits (MAX_DIGITS)))
                                          downto 0)
  ) ;

end entity ParseNumericField ;


architecture behavior of ParseNumericField is

  --  Internal Signals.

  signal multipliers    : std_logic_vector (MAX_DIGITS-1 downto 0) ;
  signal result_buff    : unsigned (RESULT_BITS-1 downto 0) ;
  signal digit_count    : unsigned (const_bits (MAX_DIGITS)-1 downto 0) ;
  signal dec_count      : unsigned (const_bits (MAX_DIGITS)-1 downto 0) ;
  signal decimalpnt     : std_logic ;

begin

  result      <= result_buff ;
  digits      <= digit_count ;
  decimals    <= dec_count ;


  ------------------------------------------------------------------------------
  --
  --! @brief      Process field characters as they become available.
  --! @details    Process the characters.
  --!
  --! @param      reset       Reset the parsing process.
  --! @param      inready     A new character is ready to process.
  --
  ------------------------------------------------------------------------------

  parse_field:  process (reset, inready)
  begin
    --  Reset the state before parsing characters.

    if reset = '1' then
      result_buff <= (others => '0') ;
      digit_count <= (others => '0') ;
      dec_count   <= (others => '0') ;
      decimalpnt  <= '0' ;
      multipliers <= (others => '0') ;
      valid       <= '1' ;

    --  A new character is available.

    elsif inready'event and inready = '1' then

      --  Add a digit to the result.

      if inchar (7 downto 4) = 3 and inchar (3 downto 0) <= 9 then

        --  The first digit is placed directly into the result and the
        --  multiplier field is set for following digits.

        if digit_count = 0 then
          multipliers <= multctl ;
          result_buff <= TO_UNSIGNED (inchar (3 downto 0), RESULT_BITS) ;

        --  Multiply the previous result by proper amount and add in the
        --  new character's value.

        else
          if multipliers (MAX_DIGITS-1) = '1' then
            result_buff <= result_buff *  6 + UNSIGNED (inchar (3 downto 0)) ;
          else
            result_buff <= result_buff * 10 + UNSIGNED (inchar (3 downto 0)) ;
          end if ;

          --  Shift the multiplier control vector by one for the next digit.

          multipliers (MAX_DIGITS-1 downto 1) <=
                            multipliers (MAX_DIGITS-2 downto 0) ;
        end if ;

        digit_count <= digit_count + 1 ;

        --  Count the decimal digits if a decimal point has been encountered.

        if decimalpnt = '1' then
          dec_count <= dec_count + 1 ;
        end if ;

      --  Start collecting decimal digits when a decimal point is found.

      else if decimalpnt = '0' and inchar = "." then
        decimalpnt <= '1' ;

      --  The character is invalid making the field invalid.

      else
        valid <= '0' ;

      end if ;
    end if ;
  end process parse_field ;

end behavior ;
