----------------------------------------------------------------------------
--
--! @file       ParseTextField.vhd
--! @brief      Parses ASCII Text Fields.
--! @details    Parses a sequence of ASCII characters as a text and
--!             returns a code indicating the string match found.
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

library GENERAL ;                  --! Local packages.
use GENERAL.UTILITIES_PKG.ALL ;    --! General utilities.


----------------------------------------------------------------------------
--
--! @brief      ASCII Text Field Parser.
--! @details    Parse a sequence of ASCII characters as a text string and
--!             return a code indicating a match.
--!
--! @param      memaddr_bits_g  Number of bits used to address the ROM.
--! @param      result_bits_g   Number of bits in the returned result.
--! @param      offset_bits_g   Number of bits for offset to the next node.
--! @param      reset           Reset the field prior to parsing a new
--!                             field.
--! @param      clk             Clock to move between states.
--! @param      inchar_in       The character to find in the tree.
--! @param      inready_in      A new characater is ready for processing.
--! @param      memdata_in      Data returned from the ROM.
--! @param      memrcv_in       Receive access to the memory bus.
--! @param      memreq_out      Request access to the memory bus.
--! @param      memaddr_out     ROM address.
--! @param      memread_en_out  Enable ROM reads.
--! @param      valid_out       The results are currently still valid when
--!                             set.
--! @param      result_out      The binary result of parsing the field so
--!                             far.
--
----------------------------------------------------------------------------

entity ParseTextField is

    Generic (
      memaddr_bits_g  : natural := 8 ;
      result_bits_g   : natural := 8 ;
      offset_bits_g   : natural := 8
    ) ;
    Port (
      reset           : in    std_logic ;
      clk             : in    std_logic ;
      inchar_in       : in    std_logic_vector (7 downto 0) ;
      inready_in      : in    std_logic ;
      memdata_in      : in    std_logic_vector (7 downto 0) ;
      memrcv_in       : in    std_logic ;
      memreq_out      : out   std_logic ;
      memaddr_out     : out   unsigned (memaddr_bits_g-1 downto 0) ;
      memread_en_out  : out   std_logic ;
      valid_out       : out   std_logic ;
      result_out      : out   unsigned (result_bits_g-1 downto 0)
    ) ;

end entity ParseTextField ;


--!   This entity searches a tree of nodes for matches for a string
--!   received one character at a time.  Each character matched has
--!   a list of characters that follow the matched character and a list of
--!   nodes for characters that can follow the one just matched.  The tree
--!   is searched initialy for the null character that percedes each
--!   string.
--!   Each tree node is made up of a series nodes consisting of four fields,
--!   a character to be matched, a list end marker (set for the last entry
--!   in a list), the end string result (when this character is the last one
--!   in the string the result is for), and an offset from the current node
--!   to the location of the list of nodes for characters following this one
--!   in strings.  A zero offset indicates there is no list, the string has
--!   ended.  The first entry in the tree is the null element.  It is used
--!   when a match has reached the end of a string.
--!   The strings "sexy", "set", "test string", "testy", "test", "text",
--!   and "t" form the following tree where + indicates the list condinues
--!   and ! indicates the list has ended.  The result values for this tree
--!   are the numbers of the strings in the string list starting at zero
--!   for the string "sexy".  The nodes are:
--!         <character to match, result, offset>
--!     <0, 7, 0!> <s, 7, 2+> <t, 6, 5!> <e, 7, 1!>  <t, 1, 0+> <x, 7, 1!>
--!     <y, 0, 0!> <e, 7, 1!> <s, 7, 2+> <x, 7, 10!> <t, 4, 1!> <sp, 7, 2+>
--!     <y, 3, 0!> <s, 7, 1!> <t, 7, 1!> <r, 7, 1!>  <i, 7, 1!> <n, 7, 1!>
--!     <g, 2, 0> <t, 6, 0!>


architecture rtl of ParseTextField is

  --  Text Parsing States.

  type ParseState is (
    PARSE_STATE_WAIT,
    PARSE_STATE_WAIT_MEM,
    PARSE_STATE_LOADNODE,
    PARSE_STATE_LOADBYTE,
    PARSE_STATE_CHKCHAR,
    PARSE_STATE_ABORT
  ) ;

  signal cur_state        : ParseState ;

  --  Each tree node consists of a character (8 bits), a list terminator flag
  --  (1 bit), a result value (result_bits_g bits) that is the result value when
  --  the node is the last one for the string, and an offset (offset_bits_g bits)
  --  to the list of nodes for characters that follow this one in the strings
  --  with the same prefix up to this point.

  constant node_bits_c      : natural := 8 + 1 + result_bits_g +
                                         offset_bits_g ;
  constant node_bytes_c     : natural := (node_bits_c - 1) / 8 + 1 ;
  constant node_byte_bits_c : natural := const_bits (node_bytes_c) ;

  --  Node signals.

  signal node         : std_logic_vector (node_bytes_c * 8 - 1 downto 0) ;
  signal node_char    : std_logic_vector (7 downto 0) ;
  signal node_end     : std_logic ;
  signal node_result  : unsigned (result_bits_g-1 downto 0) ;
  signal node_offset  : unsigned (offset_bits_g-1 downto 0) ;
  signal node_addr    : unsigned (memaddr_bits_g-1 downto 0) ;

  --  Internal Signals.

  signal byte_count   : unsigned (node_byte_bits_c-1 downto 0) ;

  signal addr         : unsigned (memaddr_bits_g-1 downto 0) ;
  signal inready_fwl  : std_logic ;

  --  Output signals that need to be read.

  signal mem_request  : std_logic ;

begin

  memreq_out        <= mem_request ;
  memaddr_out       <= addr ;

  --  Node field extraction.

  node_char     <= node (7 downto 0) ;
  node_end      <= node (8) ;
  node_result   <= unsigned (node (result_bits_g+9-1 downto 9)) ;
  node_offset   <= unsigned (node (offset_bits_g+result_bits_g+9-1 downto
                                   result_bits_g+9)) ;


  --------------------------------------------------------------------------
  --  Process the characters.
  --------------------------------------------------------------------------

  parse_field:  process (reset, clk)
  begin
    --  Reset the state before parsing characters.

    if (reset = '1') then
      valid_out       <= '1' ;
      result_out      <= (others => '1') ;
      addr            <= (others => '0') ;
      node_addr       <= TO_UNSIGNED (node_bytes_c, addr'length) ;
      mem_request     <= '0' ;
      memread_en_out  <= '0' ;
      inready_fwl     <= '0' ;
      cur_state       <= PARSE_STATE_WAIT ;

    elsif (rising_edge (clk)) then

      --  Check for matches in the string table.

      case cur_state is

        --  Wait until a new character has arrived.

        when PARSE_STATE_WAIT       =>
          memread_en_out  <= '0' ;
          mem_request     <= '0' ;

          if (inready_fwl /= inready_in) then
            inready_fwl   <= inready_in ;

            --  A new character is available.

            if (inready_in = '1') then
              cur_state   <= PARSE_STATE_WAIT_MEM ;
            end if ;
          end if ;

        when PARSE_STATE_WAIT_MEM   =>
          if (memrcv_in = '1' and mem_request = '1') then
            cur_state     <= PARSE_STATE_LOADNODE ;
          else
            if (memrcv_in = '0' and mem_request = '0') then
              mem_request <= '1' ;
            end if ;

            cur_state     <= PARSE_STATE_WAIT_MEM ;
          end if ;

        --  Load a node from memory.

        when PARSE_STATE_LOADNODE   =>
          byte_count      <= TO_UNSIGNED (node_bytes_c, byte_count'length) ;
          addr            <= node_addr ;
          memread_en_out  <= '1' ;
          cur_state       <= PARSE_STATE_LOADBYTE ;

        when PARSE_STATE_LOADBYTE   =>
          if (byte_count = 0) then
            cur_state     <= PARSE_STATE_CHKCHAR ;
          else
            byte_count    <= byte_count - 1 ;
            node          <= memdata_in & node (node_bytes_c*8-1 downto 8) ;
            addr          <= addr + 1 ;
          end if ;

        --  Find the input character in a list of characters.

        when PARSE_STATE_CHKCHAR    =>

          if (node_char = inchar_in) then
            result_out        <= node_result ;

            --  Advance to the match list for this char if there is one.

            if (node_offset = 0) then
              node_addr   <= (others => '0') ;
            else
              node_addr   <= node_addr +
                             RESIZE (node_offset *
                                     const_unsigned (node_bytes_c),
                                     node_addr'length) ;
            end if ;

            cur_state     <= PARSE_STATE_WAIT ;

          --  Advance to the next list entry if not at end of list.

          else
            if (node_end = '1') then
              cur_state   <= PARSE_STATE_ABORT ;
            else
              node_addr   <= node_addr + node_bytes_c ;
              cur_state   <= PARSE_STATE_LOADNODE ;
            end if ;
          end if ;

        --  Done with this string.

        when  PARSE_STATE_ABORT     =>
          result_out      <= (others => '1') ;
          valid_out       <= '0' ;
          memread_en_out  <= '0' ;
          mem_request     <= '0' ;

      end case ;
    end if ;
  end process parse_field ;

end architecture rtl ;
