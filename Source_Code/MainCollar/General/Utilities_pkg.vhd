----------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      General Utility Functions and Definitions.
--! @details    Generally useful functions and definitons.
--! @author     Emery Newlon
--! @version    $Revision$
--
----------------------------------------------------------------------------

library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Use real numbers for finding number of
                                --  bits needed.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;


package UTILITIES_PKG is

  --  New type defined for 2008.
  type integer_vector is array (natural range <>) of integer ;

  --  Reverse the bits in a vector.
  function reverse_any_vector (a : in std_logic_vector)
  return std_logic_vector ;

  --  Find the least significant set bit in an unsigned.
  function lsb_find (a : in unsigned) return unsigned ;

  --  Convert a bit vector with a single bit set to a binary number.
  function bit_to_number (a : in std_logic_vector ; len : natural)
  return unsigned ;

  --  Map the bits of a vector into an element of a 2D vector.
  procedure set2D_element (constant elem_no : in    natural ;
                           signal   value   : in    std_logic_vector ;
                           signal   dest    : out   std_logic_2D) ;

  --  Determine the maximum value from a (constant) array of integers.
  --  This function essentially provides the 'max' function for the array.
  function max_integer (tbl : integer_vector) return integer ;

  --  Determine the minimum value from a (constant) array of integers.
  --  This function essentially provides the 'min' function for the array.
  function min_integer (tbl : integer_vector) return integer ;

  --  Return the destination value if the test bit is set, zero otherwise.
  function if_set (t : in std_logic ; value : in integer) return integer ;

  function if_set (t : in std_logic ; value : in unsigned) return unsigned ;

  --  Determine the number of bits needed to hold a constant.
  function const_bits (const : natural) return natural ;

  --  Convert numeric constants into unsigneds with just enough bits to hold
  --  their values plus extras if needed.  (Adding two unsigneds may need an
  --  extra bit to hold the results.)
  function const_unsigned (const : natural ; extra : natural := 0)
  return unsigned ;

  function SHIFT_LEFT_LL (ARG: UNSIGNED; COUNT: NATURAL) return UNSIGNED;
  --  Result subtype: UNSIGNED(ARG'LENGTH+COUNT-1 downto 0)
  --  Result: Performs a lossless shift-left on an UNSIGNED vector COUNT.
  --          times.
  --          No elements are lost.

  function SHIFT_RIGHT_LL (ARG: UNSIGNED; COUNT: NATURAL) return UNSIGNED;
  --  Result subtype: UNSIGNED(ARG'LENGTH-COUNT-1 downto 0)
  --  Result: Performs a truncated shift-right on an UNSIGNED vector COUNT
  --          times.
  --          The vacated positions removed.
  --          The COUNT rightmost elements are lost.

  function SHIFT_LEFT_LL (ARG: SIGNED; COUNT: NATURAL) return SIGNED;
  --  Result subtype: SIGNED(ARG'LENGTH+COUNT-1 downto 0)
  --  Result: Performs a lossless shift-left on a SIGNED vector COUNT times.
  --          No elements are lost.

  function SHIFT_RIGHT_LL (ARG: SIGNED; COUNT: NATURAL) return SIGNED;
  --  Result subtype: SIGNED(ARG'LENGTH-COUNT-1 downto 0)
  --  Result: Performs a truncated shift-right on a SIGNED vector COUNT
  --          times.
  --          The vacated positions are removed.
  --          The COUNT rightmost elements are lost.

end package UTILITIES_PKG ;

package body UTILITIES_PKG is

  --  Code originated from Jonathan Bromley to reverse the bits in a vector.

  function reverse_any_vector (a : in std_logic_vector)
  return std_logic_vector is
    variable  result_v  : std_logic_vector (a'RANGE) ;
    alias     aa        : std_logic_vector (a'REVERSE_RANGE) is a ;
  begin
    for i in aa'RANGE loop
      result_v (i) := aa (i) ;
    end loop ;
    return result_v ;
  end ;

  --  Find the least significant set bit in an unsigned.

  function lsb_find (a : in unsigned) return unsigned is
    variable result_v   : unsigned (a'range) ;
  begin
    result_v := a and ((not a) + 1) ;
    return result_v ;
  end ;

  --  Convert a bit vector with a single bit set to a binary number.

  function bit_to_number (a : in std_logic_vector ; len : in natural)
  return unsigned is
    variable result_v     : unsigned (len-1 downto 0) ;
    variable incr_v       : natural ;
    variable set_v        : natural ;
    variable group_cnt_v  : natural ;
    variable pos_v        : natural ;
    variable set_len_v    : natural ;
  begin
    result_v  := (others => '0') ;

    --  Go through each bit in the result number and set them by or'ing
    --  the bits from the input together correctly.

    for i in result_v'RANGE loop
      incr_v    := 2 ** (i + 1) ;
      set_v     := incr_v / 2 ;

      --  Or groupings together.

      if (a'length >= incr_v) then
        group_cnt_v := a'length / incr_v - 1 ;
      else
        group_cnt_v := 0 ;
      end if ;

      for j in 0 to group_cnt_v loop
        pos_v   := j * incr_v + set_v ;

        --  Or each set of contiguous bits together with the result.

        if (pos_v + set_v > a'length) then
          set_len_v   := a'length ;
        else
          set_len_v   := pos_v + set_v ;
        end if ;

        if (set_len_v > pos_v) then
          for k in pos_v to set_len_v-1 loop
            result_v (i) := result_v (i) or a (k) ;
          end loop ;
        end if ;
      end loop ;
    end loop ;

   return result_v ;
  end ;


  --  Map the bits of a vector into an element of a 2D vector.

  procedure set2D_element (constant elem_no : in    natural ;
                           signal   value   : in    std_logic_vector ;
                           signal   dest    : out   std_logic_2D) is
  begin
    for i in value'range loop
      dest (elem_no, i) <= value (i) ;
    end loop ;
  end set2D_element ;

  --  Determine the maximum value from a (constant) array of integers.
  --  This function essentially provides the 'max' function for the array.

  function max_integer (tbl : integer_vector) return integer is
    variable max_value_v : integer ;
  begin
    max_value_v := tbl (tbl'low) ;
    for index in tbl'range loop
      if (max_value_v < tbl (index)) then
        max_value_v := tbl (index) ;
      end if ;
    end loop ;
    return max_value_v ;
  end max_integer ;

  --  Determine the minimum value from a (constant) array of integers.
  --  This function essentially provides the 'min' function for the array.

  function min_integer (tbl : integer_vector) return integer is
    variable min_value_v : integer ;
  begin
    min_value_v := tbl (tbl'low) ;
    for index in tbl'range loop
      if (min_value_v > tbl (index)) then
        min_value_v := tbl (index) ;
      end if ;
    end loop ;
    return min_value_v ;
  end min_integer ;

  --  Return the destination value if the test bit is set, zero otherwise.

  function if_set (t : in std_logic ; value : in integer) return integer is
  begin
    if (t = '1') then
      return value ;
    else
      return 0 ;
    end if ;
  end if_set ;

  function if_set (t : in std_logic ; value : in unsigned)
  return unsigned is
    constant zero_c     : unsigned (value'length-1 downto 0) :=
                            (others => '0') ;
  begin
    if (t = '1') then
      return value ;
    else
      return zero_c ;
    end if ;
  end if_set ;

  --  Determine the number of bits needed to hold a constant.

  function const_bits (const : natural) return natural is
  begin
    if (const = 0) then
      return 1 ;
    else
      return natural (trunc (log2 (real (const)))) + 1 ;
    end if ;
  end const_bits ;

  --  Convert numeric constants into unsigneds with just enough bits to hold
  --  their values plus extras if needed.  (Adding two unsigneds may need an
  --  extra bit to hold the results.)

  function const_unsigned (const : in natural ; extra : in natural := 0)
  return unsigned is
    constant bits_c     : natural := const_bits (const) + extra ;
  begin
    return TO_UNSIGNED (const, bits_c) ;
  end const_unsigned ;

  --  Result subtype: UNSIGNED(ARG'LENGTH+COUNT-1 downto 0)
  --  Result: Performs a lossless shift-left on an UNSIGNED vector COUNT
  --          times.
  --          No elements are lost.

  function SHIFT_LEFT_LL (ARG: UNSIGNED; COUNT: NATURAL) return UNSIGNED is
  begin
    return SHIFT_LEFT (RESIZE (ARG, ARG'length + COUNT), COUNT) ;
  end SHIFT_LEFT_LL ;

  --  Result subtype: UNSIGNED(ARG'LENGTH-COUNT-1 downto 0)
  --  Result: Performs a truncated shift-right on an UNSIGNED vector COUNT
  --          times.
  --          The vacated positions removed.
  --          The COUNT rightmost elements are lost.

  function SHIFT_RIGHT_LL (ARG: UNSIGNED; COUNT: NATURAL) return UNSIGNED is
  begin
    return RESIZE (SHIFT_RIGHT (ARG, COUNT), ARG'length - COUNT) ;
  end SHIFT_RIGHT_LL ;

  --  Result subtype: SIGNED(ARG'LENGTH+COUNT-1 downto 0)
  --  Result: Performs a lossless shift-left on a SIGNED vector COUNT times.
  --          No elements are lost.

  function SHIFT_LEFT_LL (ARG: SIGNED; COUNT: NATURAL) return SIGNED is
  begin
    return SHIFT_LEFT (RESIZE (ARG, ARG'length + COUNT), COUNT) ;
  end SHIFT_LEFT_LL ;

  --  Result subtype: SIGNED(ARG'LENGTH-COUNT-1 downto 0)
  --  Result: Performs a truncated shift-right on a SIGNED vector COUNT
  --          times.
  --          The vacated positions are removed.
  --          The COUNT rightmost elements are lost.

  function SHIFT_RIGHT_LL (ARG: SIGNED; COUNT: NATURAL) return SIGNED is
  begin
    return RESIZE (SHIFT_RIGHT (ARG, COUNT), ARG'length - COUNT) ;
  end SHIFT_RIGHT_LL ;


end package body UTILITIES_PKG ;
