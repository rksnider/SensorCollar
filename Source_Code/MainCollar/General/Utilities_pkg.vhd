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

  --  New functions defined for 2008.
  function minimum (a, b : in integer)
  return integer ;

  function maximum (a, b : in integer)
  return integer ;

  --  Reverse the bits in a vector.
  function reverse_any_vector (a : in std_logic_vector)
  return std_logic_vector ;

  --  Find the least significant set bit in an unsigned.
  function lsb_find (a : in unsigned) return unsigned ;

  --  Convert a bit vector with a single bit set to a binary number.
  function bit_to_number (a : in std_logic_vector ; len : natural)
  return unsigned ;

  --  A zero filled 2D vector.
  signal zero2D         : std_logic_2D (0 downto 0, 0 downto 0) :=
                                (others => (others => '0')) ;

  --  Map the bits of a vector into an element of a 2D vector.
  --  The source is copied to the destination except for the row specified
  --  by the element number.  Any bits in the destination that are not
  --  in the source are set to zero.
  procedure set2D_element (constant elem_no : in    natural ;
                           signal   value   : in    std_logic_vector ;
                           signal   source  : in    std_logic_2D ;
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

  procedure attach2except (signal dest      : out std_logic_vector ;
                           signal src       : in  std_logic_vector ;
                           constant except  : in  integer_vector) ;
  --  Attaches all source bits to corresponding destination bits except for
  --  those indexed in the except array.  This allows the latter to be
  --  attached to different signals.


end package UTILITIES_PKG ;

package body UTILITIES_PKG is

  --  New functions defined for 2008.

  function minimum (a, b : in integer)
  return integer is
  begin
    if (a < b) then
      return a ;
    else
      return b ;
    end if ;
  end ;

  function maximum (a, b : in integer)
  return integer is
  begin
    if (a > b) then
      return a ;
    else
      return b ;
    end if ;
  end ;

  --  Code originated from Jonathan Bromley to reverse the bits in a vector.

  function reverse_any_vector (a : in std_logic_vector)
  return std_logic_vector is
    variable  result  : std_logic_vector (a'RANGE) ;
    alias     aa      : std_logic_vector (a'REVERSE_RANGE) is a ;
  begin
    for i in aa'RANGE loop
      result (i) := aa (i) ;
    end loop ;
    return result ;
  end ;

  --  Find the least significant set bit in an unsigned.

  function lsb_find (a : in unsigned) return unsigned is
    variable result   : unsigned (a'range) ;
  begin
    result := a and ((not a) + 1) ;
    return result ;
  end ;

  --  Convert a bit vector with a single bit set to a binary number.

  function bit_to_number (a : in std_logic_vector ; len : in natural)
  return unsigned is
    variable result     : unsigned (len-1 downto 0) ;
    variable incr       : natural ;
    variable set        : natural ;
    variable group_cnt  : natural ;
    variable pos        : natural ;
    variable set_len    : natural ;
  begin
    result  := (others => '0') ;

    --  Go through each bit in the result number and set them by or'ing
    --  the bits from the input together correctly.

    for i in result'RANGE loop
      incr    := 2 ** (i + 1) ;
      set     := incr / 2 ;

      --  Or groupings together.

      if (a'length >= incr) then
        group_cnt := a'length / incr - 1 ;
      else
        group_cnt := 0 ;
      end if ;

      for j in 0 to group_cnt loop
        pos   := j * incr + set ;

        --  Or each set of contiguous bits together with the result.

        if (pos + set > a'length) then
          set_len   := a'length ;
        else
          set_len   := pos + set ;
        end if ;

        if (set_len > pos) then
          for k in pos to set_len-1 loop
            result (i) := result (i) or a (k) ;
          end loop ;
        end if ;
      end loop ;
    end loop ;

   return result ;
  end ;


  --  Map the bits of a vector into an element of a 2D vector.
  --  The source is copied to the destination except for the row specified
  --  by the element number.  Any bits in the destination that are not
  --  in the source are set to zero.

  procedure set2D_element (constant elem_no : in    natural ;
                           signal   value   : in    std_logic_vector ;
                           signal   source  : in    std_logic_2D ;
                           signal   dest    : out   std_logic_2D) is
  begin
    for col in dest'range (2) loop
      if (col < value'low or col > value'high) then
        dest (elem_no, col)   <= '0' ;
      else
        dest (elem_no, col)   <=  value (col) ;
      end if ;
    end loop ;
    for row in dest'range (1) loop
      if (row /= elem_no) then
        if (row < source'low (1) or row > source'high (1)) then
          for col in dest'range (2) loop
            dest (row, col)   <= '0' ;
          end loop ;
        else
          for col in dest'range (2) loop
            if (col < source'low (2) or col > source'high (2)) then
              dest (row, col) <= '0' ;
            else
              dest (row, col) <= source (row, col) ;
            end if ;
          end loop ;
        end if ;
      end if ;
    end loop ;
  end set2D_element ;

  --  Determine the maximum value from a (constant) array of integers.
  --  This function essentially provides the 'max' function for the array.

  function max_integer (tbl : integer_vector) return integer is
    variable max_value : integer ;
  begin
    max_value := tbl (tbl'low) ;
    for index in tbl'range loop
      if (max_value < tbl (index)) then
        max_value := tbl (index) ;
      end if ;
    end loop ;
    return max_value ;
  end max_integer ;

  --  Determine the minimum value from a (constant) array of integers.
  --  This function essentially provides the 'min' function for the array.

  function min_integer (tbl : integer_vector) return integer is
    variable min_value : integer ;
  begin
    min_value := tbl (tbl'low) ;
    for index in tbl'range loop
      if (min_value > tbl (index)) then
        min_value := tbl (index) ;
      end if ;
    end loop ;
    return min_value ;
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
    constant zero     : unsigned (value'length-1 downto 0) :=
                            (others => '0') ;
  begin
    if (t = '1') then
      return value ;
    else
      return zero ;
    end if ;
  end if_set ;

  --  Determine the number of bits needed to hold a constant.  A small
  --  bias is added to the constant to deal with truncation problems.

  function const_bits (const : natural) return natural is
  begin
    if (const = 0) then
      return 1 ;
    else
      return natural (trunc (log2 (real (const) + 0.001))) + 1 ;
    end if ;
  end const_bits ;

  --  Convert numeric constants into unsigneds with just enough bits to hold
  --  their values plus extras if needed.  (Adding two unsigneds may need an
  --  extra bit to hold the results.)

  function const_unsigned (const : in natural ; extra : in natural := 0)
  return unsigned is
    constant bits     : natural := const_bits (const) + extra ;
  begin
    return TO_UNSIGNED (const, bits) ;
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


  --  Attaches all source bits to corresponding destination bits except for
  --  those indexed in the except array.  This allows the latter to be
  --  attached to different signals.

  procedure attach2except (signal dest      : out std_logic_vector ;
                           signal src       : in  std_logic_vector ;
                           constant except  : in  integer_vector) is
    variable exclude    : std_logic_vector (dest'range) :=
                                  (others => '0') ;
  begin
    for i in except'range loop
      if (except (i) <= exclude'high and except (i) >= exclude'low) then
        exclude (except (i))     := '1' ;
      end if ;
    end loop ;
    for i in exclude'range loop
      if (exclude (i) = '0' and i <= src'high and i >= src'low) then
        dest (i)        <= src (i) ;
      end if ;
    end loop ;
  end ;

end package body UTILITIES_PKG ;
