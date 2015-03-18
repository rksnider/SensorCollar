------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Parses ASCII Text Fields.
--! @details    Parses a sequence of ASCII characters as a text and
--!             returns a code indicating the string match found.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library WORK ;                  --! Local packages.
use WORK.UTILITIES.ALL ;         --! General utilities.


------------------------------------------------------------------------------
--
--! @brief      ASCII Text Field Parser.
--! @details    Parse a sequence of ASCII characters as a text string and
--!             return a code indicating a match.
--!
--! @param      MEMADDR_BITS    Number of bits used to address the ROM.
--! @param      RESULT_BITS     Number of bits in the returned result.
--! @param      OFFSET_BITS     Number of bits for offset to the next node.
--! @param      reset           Reset the field prior to parsing a new field.
--! @param      clk             Clock to move between states.
--! @param      inchar          The character to find in the tree.
--! @param      inready         A new characater is ready for processing.
--! @param      memdata         Data returned from the ROM.
--! @param      memrcv          Receive access to the memory bus.
--! @param      memreq          Request access to the memory bus.
--! @param      memaddr         ROM address.
--! @param      memread_en      Enable ROM reads.
--! @param      valid           The results are currently still valid when set.
--! @param      result          The binary result of parsing the field so far.
--
------------------------------------------------------------------------------

entity ParseTextFieldTest is

    Generic (
      MEMADDR_BITS        : natural := 9 ;
      RESULT_BITS         : natural := 7 ;
      OFFSET_BITS         : natural := 8
    ) ;
    Port (
      reset               : in    std_logic ;
      clk                 : in    std_logic ;
      run                 : in    std_logic ;
      inchar              : in    std_logic_vector (7 downto 0) ;
      inready             : in    std_logic ;
      memdata             : in    std_logic_vector (7 downto 0) ;
      memrcv              : in    std_logic ;
      memreq              : out   std_logic ;
      memaddr             : out   unsigned (MEMADDR_BITS-1 downto 0) ;
      memread_en          : out   std_logic ;
      valid               : out   std_logic ;
      result              : out   unsigned (RESULT_BITS-1 downto 0)
    ) ;

end entity ParseTextFieldTest ;


--!   This entity searches a tree of nodes for matches for a string
--!   received one character at a time.  Each character matched has
--!   a list of characters that follow the matched character and a list of
--!   nodes for characters that can follow the one just matched.  The tree is
--!   searched initialy for the null character that percedes each
--!   string.
--!   Each tree node is made up of a series nodes consisting of four fields,
--!   a character to be matched, a list end marker (set for the last entry in
--!   a list), the end string result (when this character is the last one in
--!   the string the result is for), and an offset from the current node to
--!   the location of the list of nodes for characters following this one in
--!   strings.  A zero offset indicates there is no list, the string has ended.
--!   The first entry in the tree is the null element.  It is used when a
--!   match has reached the end of a string.
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


architecture behavior of ParseTextFieldTest is

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
  --  (1 bit), a result value (RESULT_BITS bits) that is the result value when
  --  the node is the last one for the string, and an offset (OFFSET_BITS bits)
  --  to the list of nodes for characters that follow this one in the strings
  --  with the same prefix up to this point.

  constant NODE_BITS      : natural := 8 + 1 + RESULT_BITS + OFFSET_BITS ;
  constant NODE_BYTES     : natural := (NODE_BITS - 1) / 8 + 1 ;
  constant NODE_BYTE_BITS : natural := const_bits (NODE_BYTES) ;

  --  Node signals.

  signal node         : std_logic_vector (NODE_BYTES * 8 - 1 downto 0) ;
  signal node_char    : std_logic_vector (7 downto 0) ;
  signal node_end     : std_logic ;
  signal node_result  : unsigned (RESULT_BITS-1 downto 0) ;
  signal node_offset  : unsigned (OFFSET_BITS-1 downto 0) ;
  signal node_addr    : unsigned (MEMADDR_BITS-1 downto 0) ;

  --  Internal Signals.

  signal byte_count   : unsigned (NODE_BYTE_BITS-1 downto 0) ;

  signal addr         : unsigned (MEMADDR_BITS-1 downto 0) ;
  signal inready_fwl  : std_logic ;
  
  signal clear        : std_logic ;

  --  Output signals that need to be read.
  
  signal mem_request  : std_logic ;

begin

  clear         <= reset or not run ;

  memreq        <= mem_request ;
  memaddr       <= addr ;

  --  Node field extraction.

  node_char     <= node (7 downto 0) ;
  node_end      <= node (8) ;
  node_result   <= unsigned (node (RESULT_BITS+9-1 downto 9)) ;
  node_offset   <= unsigned (node (OFFSET_BITS+RESULT_BITS+9-1 downto
                                   RESULT_BITS+9)) ;


  ------------------------------------------------------------------------------
  --
  --! @brief      Process field characters as they become available.
  --! @details    Process the characters.
  --!
  --! @param      reset       Reset the parsing process.
  --! @param      inready     A new character is ready to process.
  --
  ------------------------------------------------------------------------------

  parse_field:  process (clear, clk)
  begin
    --  Reset the state before parsing characters.

    if clear = '1' then
      valid       <= '1' ;
      result      <= (others => '1') ;
      addr        <= (others => '0') ;
      node_addr   <= TO_UNSIGNED (NODE_BYTES, addr'length) ;
      mem_request <= '0' ;
      memread_en  <= '0' ;
      inready_fwl <= '0' ;
      cur_state   <= PARSE_STATE_WAIT ;

    elsif clk'event and clk = '1' then

      --  Check for matches in the string table.

      case cur_state is

        --  Wait until a new character has arrived.

        when PARSE_STATE_WAIT       =>
          memread_en      <= '0' ;
          mem_request     <= '0' ;

          if inready_fwl /= inready then
            inready_fwl   <= inready ;

            --  A new character is available.

            if inready = '1' then
              cur_state   <= PARSE_STATE_WAIT_MEM ;
            end if ;
          end if ;

        when PARSE_STATE_WAIT_MEM   =>
          if memrcv = '1' and mem_request = '1' then
            cur_state     <= PARSE_STATE_LOADNODE ;
          else
            if memrcv = '0' and mem_request = '0' then
              mem_request <= '1' ;
            end if ;
            
            cur_state     <= PARSE_STATE_WAIT_MEM ;
          end if ;

        --  Load a node from memory.

        when PARSE_STATE_LOADNODE   =>
          byte_count      <= TO_UNSIGNED (NODE_BYTES, byte_count'length) ;
          addr            <= node_addr ;
          memread_en      <= '1' ;
          cur_state       <= PARSE_STATE_LOADBYTE ;

        when PARSE_STATE_LOADBYTE   =>
          if byte_count = 0 then
            cur_state     <= PARSE_STATE_CHKCHAR ;
          else
            byte_count    <= byte_count - 1 ;
            node          <= memdata & node (NODE_BYTES*8-1 downto 8) ;
            addr          <= addr + 1 ;
          end if ;

        --  Find the input character in a list of characters.

        when PARSE_STATE_CHKCHAR    =>

          if node_char = inchar then
            result        <= node_result ;

            --  Advance to the match list for this char if there is one.

            if node_offset = 0 then
              node_addr   <= (others => '0') ;
            else
              node_addr   <= node_addr +
                             RESIZE (node_offset * const_unsigned (NODE_BYTES),
                                     node_addr'length) ;
            end if ;

            cur_state     <= PARSE_STATE_WAIT ;

          --  Advance to the next list entry if not at end of list.

          else
            if node_end = '1' then
              cur_state   <= PARSE_STATE_ABORT ;
            else
              node_addr   <= node_addr + NODE_BYTES ;
              cur_state   <= PARSE_STATE_LOADNODE ;
            end if ;
          end if ;

        --  Done with this string.

        when  PARSE_STATE_ABORT     =>
          result          <= (others => '1') ;
          valid           <= '0' ;
          memread_en      <= '0' ;
          mem_request     <= '0' ;

      end case ;
    end if ;
  end process parse_field ;

end behavior ;
