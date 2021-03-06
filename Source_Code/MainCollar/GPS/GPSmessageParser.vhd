----------------------------------------------------------------------------
--
--! @file       GPSMessageParser.vhd
--! @brief      Parses messages from a NEO-6T GPS.
--! @details    Component parses messages from a GPS, converting them into
--!             binary and storing the results in Dual-Port memory.
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

library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

library GENERAL ;
use GENERAL.UTILITIES_PKG.ALL ;     --  General utility definitons.
use GENERAL.GPS_CLOCK_PKG.ALL ;     --  Use the GPS Clock information.

library WORK ;
use WORK.GPSmessageInfo_pkg.all ;   --  GPS message definitions.
use WORK.gps_message_ctl_pkg.all ;
use WORK.msg_ubx_nav_sol_pkg.all ;
use WORK.msg_ubx_tim_tm2_pkg.all ;


----------------------------------------------------------------------------
--
--! @brief      GPS Message Parser.
--! @details    Parse fields in GPS messages and store the results in Dual-
--!             Port memory.  While the message is being parsed the contents
--!             of the associated memory is marked as invalid.
--!
--! @param      memaddr_bits_g    Bit width of the memory address.
--! @param      reset             Reset the entity to an initial state.
--! @param      clk               Clock used to move throuth states in the
--!                               entity and its components.
--! @param      curtime_in        The System Time for logging events at.
--! @param      curtime_latch_in  Latch curtime across clock domains.
--! @param      curtime_valid_in  Latched curtime is valid when set.
--! @param      curtime_vlatch_in Latch curtime when valid not set.
--! @param      markertime_in     The time the last Time Marker generated.
--! @param      inbyte_in         Byte received to add to message to parse.
--! @param      inready_in        The byte is ready to be parsed.
--! @param      inreceived_out    The byte has been received for parsing.
--! @param      memreq_out        Request access to memory.
--! @param      memrcv_in         Receive access to memory.
--! @param      memaddr_out       Address of the byte of memory to
--!                               read/write.
--! @param      meminput_in       Data byte read from memory that is
--!                               addressed.
--! @param      memoutput_out     Data byte written to memory that is
--!                               addressed.
--! @param      memread_en_out    Enable the memory for reading.
--! @param      memwrite_en_out   Enable a write to the memory.
--! @param      datavalid_out     The bank of memory with the newest valid
--!                               data if two banks are available, otherwise
--!                               set when data is valid.
--! @param      tempbank_out      The bank of memory the most recent temp
--!                               message is in.
--! @param      msgnumber_out     Message number of the most recent valid
--!                               message.
--! @param      msgreceived_out   A new valid message has been received.
--! @param      busy_out          The component is busy processing data.
--
----------------------------------------------------------------------------

entity GPSmessageParser is

  Generic (
    memaddr_bits_g  : natural := 10
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    curtime_in        : in    std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
    curtime_latch_in  : in    std_logic ;
    curtime_valid_in  : in    std_logic ;
    curtime_vlatch_in : in    std_logic ;
    markertime_in     : in    std_logic_vector (gps_time_bits_c-1
                                                downto 0) ;
    inbyte_in         : in    std_logic_vector (7 downto 0) ;
    inready_in        : in    std_logic ;
    inreceived_out    : out   std_logic ;
    memreq_out        : out   std_logic ;
    memrcv_in         : in    std_logic ;
    memaddr_out       : out   std_logic_vector (memaddr_bits_g-1 downto 0) ;
    meminput_in       : in    std_logic_vector (7 downto 0) ;
    memoutput_out     : out   std_logic_vector (7 downto 0) ;
    memread_en_out    : out   std_logic ;
    memwrite_en_out   : out   std_logic ;
    datavalid_out     : out   std_logic_vector (msg_ram_blocks_c-1
                                                downto 0) ;
    tempbank_out      : out   std_logic ;
    msgnumber_out     : out   std_logic_vector (msg_count_bits_c-1
                                                downto 0) ;
    msgreceived_out   : out   std_logic ;
    busy_out          : out   std_logic
  ) ;

end entity GPSmessageParser ;


architecture rtl of GPSmessageParser is

  --  System time from across clock domains.

  signal curtime            : std_logic_vector (curtime_in'length-1
                                                downto 0) ;

  component CrossChipReceive is
    Generic (
      data_bits_g           : natural := 8
    ) ;
    Port (
      clk                   : in    std_logic ;
      data_latch_in         : in    std_logic ;
      data_valid_in         : in    std_logic ;
      valid_latch_in        : in    std_logic ;
      data_in               : in    std_logic_vector (data_bits_g-1
                                                      downto 0) ;
      data_out              : out   std_logic_vector (data_bits_g-1
                                                      downto 0) ;
      data_ready_out        : out   std_logic
    ) ;
  end component CrossChipReceive ;

  --  Text tree parsing component.

  component ParseTextField is

    Generic (
      memaddr_bits_g      : natural := 8 ;
      result_bits_g       : natural := 8 ;
      offset_bits_g       : natural := 8
    ) ;
    Port (
      reset               : in    std_logic ;
      clk                 : in    std_logic ;
      inchar_in           : in    std_logic_vector (7 downto 0) ;
      inready_in          : in    std_logic ;
      memreq_out          : out   std_logic ;
      memrcv_in           : in    std_logic ;
      memaddr_out         : out   unsigned (memaddr_bits_g-1 downto 0) ;
      memdata_in          : in    std_logic_vector (7 downto 0) ;
      memread_en_out      : out   std_logic ;
      valid_out           : out   std_logic ;
      result_out          : out   unsigned (result_bits_g-1 downto 0)
    ) ;

  end component ParseTextField ;

  --  Message Parsing States.

  type ParseState is   (
    PARSE_STATE_LOAD_BYTE,
    PARSE_STATE_SAVE_BYTE,
    PARSE_STATE_WAIT_BYTE,
    PARSE_STATE_WAIT_MEM,
    PARSE_STATE_WAIT,
    PARSE_STATE_SYNC,
    PARSE_STATE_INIT_STR,
    PARSE_STATE_FIND_MSG,
    PARSE_STATE_MSG_LEN,
    PARSE_STATE_MSG_HIGH,
    PARSE_STATE_EXTRACT,
    PARSE_STATE_FIELD_CNT,
    PARSE_STATE_NEXT_FLD,
    PARSE_STATE_FLD_PERM,
    PARSE_STATE_FLD_TEMP,
    PARSE_STATE_FLD_DONE,
    PARSE_STATE_FLD_CHECK,
    PARSE_STATE_CHECKSUM,
    PARSE_STATE_CHECKSUM_B,
    PARSE_STATE_SUCCESS,
    PARSE_STATE_ABORT,
    PARSE_STATE_ABORT_LOOP
  ) ;

  signal cur_state        : ParseState ;
  signal next_state       : ParseState ;
  signal return_state     : ParseState ;

  --  Character processing signals.

  signal inbyte_s         : std_logic_vector (inbyte_in'length-1 downto 0) ;
  signal inready_s        : std_logic ;
  signal inready          : std_logic ;

  signal inready_fwl      : std_logic ;

  signal text_reset       : std_logic ;

  signal text_valid       : std_logic ;

  signal text_result      : unsigned (msg_count_bits_c-1 downto 0) ;

  constant timeout_c      : natural := 100 ;
  signal byte_timeout     : unsigned (const_bits (timeout_c)-1 downto 0) ;

  --  Memory addressed from one of several sources.

  constant memaddr_select_msg_c   : unsigned (0 downto 0) := "0" ;
  constant memaddr_select_text_c  : unsigned (0 downto 0) := "1" ;

  signal memaddr_select           : unsigned (0 downto 0) ;

  signal text_memaddr             : unsigned (memaddr_bits_g-1 downto 0) ;
  signal msg_memaddr              : unsigned (memaddr_bits_g-1 downto 0) ;
  signal fld_memaddr              : unsigned (memaddr_bits_g-1 downto 0) ;

  signal text_memread_en          : std_logic ;
  signal msg_memread_en           : std_logic ;

  signal text_memreq              : std_logic ;
  signal msg_memreq               : std_logic ;

  --  Valid message banks.

  signal db_nav_sol               : std_logic ;
  signal db_tim_tm2               : std_logic ;
  signal db_temp                  : std_logic ;

  --  Checksum processing

  signal calc_checksum          : std_logic ;
  signal m_checksum_A           : unsigned (7 downto 0) ;
  signal m_checksum_B           : unsigned (7 downto 0) ;

  --  Message information.

  signal m_number               : unsigned (msg_count_bits_c-1 downto 0) ;
  signal m_length               : unsigned (15 downto 0) ;
  signal m_ramoffset            : unsigned (msg_size_bits_c-1 downto 0) ;
  signal m_field_number         : unsigned (msg_field_bits_c-1 downto 0) ;
  signal m_field_end            : unsigned (msg_field_bits_c-1 downto 0) ;
  signal m_field_length         : unsigned (msg_size_bits_c-1 downto 0) ;
  signal m_field_save           : std_logic ;

  --  RAM memory information.

  signal temp_ramaddr           : unsigned (memaddr_bits_g-1 downto 0) ;
  signal save_ramaddr           : unsigned (memaddr_bits_g-1 downto 0) ;

  --  Scratch area used for loading/storing bit vectors to/from
  --  memory.  Each signal using it is defined via an alias.

  constant byte_length_tbl_c : integer_vector :=
      (msg_extract_lookup_bytes_c, gps_time_bytes_c) ;

  constant byte_buffer_size_c : natural := max_integer (byte_length_tbl_c) ;

  signal in_buffer            : std_logic_vector (byte_buffer_size_c*8-1
                                                  downto 0) ;
  signal out_buffer           : std_logic_vector (byte_buffer_size_c*8-1
                                                  downto 0) :=
                                            (others => '0') ;

  signal byte_count           : unsigned (const_bits (byte_buffer_size_c)-1
                                          downto 0) ;

  signal buffer_load          : std_logic ;
  signal buffer_shift         : std_logic ;
  signal in_bits              : std_logic_vector (7 downto 0) ;
  signal last_bits            : std_logic_vector (in_bits'length-1
                                                  downto 0) ;

  alias  m_extract            :
            std_logic_vector (msg_extract_lookup_bytes_c*8-1 downto 0) is
                              in_buffer (byte_buffer_size_c*8-1 downto
                                         byte_buffer_size_c*8 -
                                         msg_extract_lookup_bytes_c*8) ;

  alias  log_time             :
            std_logic_vector (gps_time_bits_c-1 downto 0) is
                              out_buffer (gps_time_bits_c-1 downto 0) ;

  component Shifter is
    Generic (
      bits_wide_g           : natural   := 32 ;
      shift_bits_g          : natural   :=  8 ;
      shift_right_g         : std_logic := '1'
    ) ;
    Port (
      clk                   : in    std_logic ;
      load_buffer_in        : in    std_logic_vector (bits_wide_g-1
                                                      downto 0) ;
      load_in               : in    std_logic ;
      shift_enable_in       : in    std_logic ;
      buffer_out            : out   std_logic_vector (bits_wide_g-1
                                                      downto 0) ;
      early_lastbits_out    : out   std_logic_vector (shift_bits_g-1
                                                      downto 0) ;
      lastbits_out          : out   std_logic_vector (shift_bits_g-1
                                                      downto 0) ;
      shift_inbits_in       : in    std_logic_vector (shift_bits_g-1
                                                      downto 0)
    ) ;
  end component Shifter ;

begin

  --  The byte received state is saved in the follower signal.

  inreceived_out  <= inready_fwl ;

  --  System time from across clock domains.

  get_curtime : component CrossChipReceive
    Generic Map (
      data_bits_g             => curtime_in'length
    )
    Port Map (
      clk                     => clk,
      data_latch_in           => curtime_latch_in,
      data_valid_in           => curtime_valid_in,
      valid_latch_in          => curtime_vlatch_in,
      data_in                 => curtime_in,
      data_out                => curtime
    ) ;

  --  Byte buffer shifter.

  byte_shift : component Shifter
    Generic Map (
      bits_wide_g           => in_buffer'length,
      shift_bits_g          => in_bits'length,
      shift_right_g         => '1'
    )
    Port Map (
      clk                   => clk,
      load_buffer_in        => out_buffer,
      load_in               => buffer_load,
      shift_enable_in       => buffer_shift,
      buffer_out            => in_buffer,
      lastbits_out          => last_bits,
      shift_inbits_in       => in_bits
    ) ;

  --  Request memory when someone wants it and release it when everyone
  --  is done with it.

  memreq_out      <= text_memreq or msg_memreq ;

  --  Select who can set the memory address.

  with memaddr_select select
    memaddr_out   <= std_logic_vector (text_memaddr +
                                       msg_extract_tree_c +
                                       msg_rom_base_c)
                                              when memaddr_select_text_c,
                     std_logic_vector (msg_memaddr)
                                              when others ;

  memread_en_out  <= msg_memread_en or text_memread_en ;

  --  Data banks for these messages are kept internally and exported
  --  continuously.

  datavalid_out (msg_ubx_nav_sol_ramblock_c)  <= db_nav_sol ;
  datavalid_out (msg_ubx_tim_tm2_ramblock_c)  <= db_tim_tm2 ;

  tempbank_out                                <= db_temp ;

  --  Text tree parsing instance.

  textfield : component ParseTextField

    Generic Map (
      memaddr_bits_g      => memaddr_bits_g,
      result_bits_g       => msg_count_bits_c,
      offset_bits_g       => msg_tree_offset_bits_c
    )
    Port Map (
      reset               => text_reset,
      clk                 => clk,
      inchar_in           => inbyte_s,
      inready_in          => inready,
      memreq_out          => text_memreq,
      memrcv_in           => memrcv_in,
      memaddr_out         => text_memaddr,
      memdata_in          => meminput_in,
      memread_en_out      => text_memread_en,
      valid_out           => text_valid,
      result_out          => text_result
    ) ;


  --------------------------------------------------------------------------
  --  Parse the individual fields in a line and save the results to memory.
  --------------------------------------------------------------------------

  parse_fields:  process (reset, clk)
  begin
    if (reset = '1') then
      text_reset      <= '1' ;
      inready_s       <= '0' ;
      inready         <= '0' ;
      inready_fwl     <= '0' ;
      inbyte_s        <= (others => '0') ;
      byte_timeout    <= (others => '0') ;
      db_nav_sol      <= '0' ;
      db_tim_tm2      <= '0' ;
      db_temp         <= '0' ;
      msg_memreq      <= '0' ;
      msg_memaddr     <= (others => '0') ;
      msg_memread_en  <= '0' ;
      memwrite_en_out <= '0' ;
      memaddr_select  <= memaddr_select_msg_c ;
      buffer_load     <= '0' ;
      buffer_shift    <= '0' ;
      cur_state       <= PARSE_STATE_WAIT_BYTE ;
      next_state      <= PARSE_STATE_WAIT ;
      msgnumber_out   <= (others => '0') ;
      msgreceived_out <= '0' ;
      busy_out        <= '0' ;

    elsif (falling_edge (clk)) then

      --  Capture the received byte from a different clock domain.

      inready         <= inready_s ;
      inbyte_s        <= inbyte_in ;

    elsif (rising_edge (clk)) then

      inready_s       <= inready_in ;

      --  Always allow the write enable and shift control signals to be high
      --  for just one clock cycle.

      memwrite_en_out <= '0' ;
      buffer_load     <= '0' ;
      buffer_shift    <= '0' ;

      --  Always wait for a new character unless changed within a state.
      --  In most cases a new byte is needed before a state can proceed.
      --  Thus the state machine waits in the WAIT_BYTE state until a new
      --  byte has arrived then proceeds to the next specified state.
      --  In some states multiple clock cycles are needed to process the
      --  information received.  In those cases waiting for a new byte is
      --  skipped.  The state machine proceeds at the clock rate instead.
      --  THIS CHANGE DOES NOT TAKE PLACE UNTIL THE END OF THE PROCESS!
      --  IT CAN BE OVERRIDDEN IF SET AGAIN BEFORE THE END OF THE PROCESS!

      cur_state       <= PARSE_STATE_WAIT_BYTE ;

      --  Parsing state machine.

      case cur_state is

        --  Subroutine like state to load a value from memory into a bit
        --  vector.

        when PARSE_STATE_LOAD_BYTE    =>
          if (byte_count > 0) then
            in_bits                   <= meminput_in ;
            buffer_shift              <= '1' ;

            byte_count                <= byte_count - 1 ;
            msg_memaddr               <= msg_memaddr + 1 ;
            cur_state                 <= PARSE_STATE_LOAD_BYTE ;
          else
            cur_state                 <= return_state ;
          end if ;

        --  Subroutine like state to save a value into memory from a bit
        --  vector.  Address must start one byte before the first byte to
        --  be written.

        when PARSE_STATE_SAVE_BYTE    =>
          if (byte_count > 0) then
            memoutput_out             <= last_bits ;
            in_bits                   <= (others => '0') ;
            buffer_shift              <= '1' ;

            byte_count                <= byte_count - 1 ;
            msg_memaddr               <= msg_memaddr + 1 ;
            memwrite_en_out           <= '1' ;
            cur_state                 <= PARSE_STATE_SAVE_BYTE ;
          else
            cur_state                 <= return_state ;
          end if ;

        --  Wait until a new byte has been received.  Add its value to the
        --  checksum if currently calculating the checksum.
        --  The process is busy if it is processing states other than
        --  waiting for the first sync byte.

        when PARSE_STATE_WAIT_BYTE  =>
          msg_memreq          <= '0' ;
          msg_memread_en      <= '0' ;

          if (next_state = PARSE_STATE_WAIT) then
            busy_out          <= '0' ;
          else
            busy_out          <= '1' ;
          end if ;

          if (inready_fwl /= inready) then
            inready_fwl   <= inready ;

            if (inready = '1') then
              if (calc_checksum = '1') then
                m_checksum_B  <= m_checksum_B + m_checksum_A +
                                 unsigned (inbyte_s) ;
                m_checksum_A  <= m_checksum_A + unsigned (inbyte_s) ;
              end if ;

              byte_timeout    <= (others => '0') ;
              msg_memreq      <= '1' ;
              busy_out        <= '1' ;
              cur_state       <= PARSE_STATE_WAIT_MEM ;
            end if ;

          --  Check for message timed out.

          elsif (byte_timeout /= timeout_c) then
            byte_timeout      <= byte_timeout + 1 ;
          else
            next_state        <= PARSE_STATE_WAIT ;
          end if ;

        when PARSE_STATE_WAIT_MEM   =>
          if (memrcv_in = '1') then
            cur_state         <= next_state ;
          else
            cur_state         <= PARSE_STATE_WAIT_MEM ;
          end if ;

        --  Wait until a new message is detected.

        when PARSE_STATE_WAIT       =>
          text_reset          <= '1' ;
          msg_memread_en      <= '0' ;

          if (inbyte_s = msg_ubx_sync_1_c) then
            next_state        <= PARSE_STATE_SYNC ;
          else
            next_state        <= PARSE_STATE_WAIT ;
          end if ;

        when PARSE_STATE_SYNC       =>
          if (inbyte_s = msg_ubx_sync_2_c) then
            msgreceived_out       <= '0' ;

            m_checksum_A      <= (others => '0') ;
            m_checksum_B      <= (others => '0') ;
            calc_checksum     <= '1' ;

            cur_state         <= PARSE_STATE_INIT_STR ;
          else
            next_state        <= PARSE_STATE_WAIT ;
          end if ;

        --  Parse the initial GPS message string.

        when PARSE_STATE_INIT_STR   =>
           text_reset         <= '0' ;
           msg_memreq         <= '0' ;
           memaddr_select     <= memaddr_select_text_c ;
           cur_state          <= PARSE_STATE_FIND_MSG ;

        when PARSE_STATE_FIND_MSG   =>

          --  When no valid message found read the length and abort with
          --  unknown message.

          if (text_valid = '0') then
            m_number          <= TO_UNSIGNED (msg_count_c,
                                              m_number'length) ;
            text_reset        <= '1' ;
            memaddr_select    <= memaddr_select_msg_c ;
            next_state        <= PARSE_STATE_MSG_LEN ;

          --  Keep searching until a message is found.

          elsif (text_result = msg_count_c or
                 text_result = not TO_UNSIGNED (0, text_result'length)) then
            if (inready_fwl /= inready) then
              inready_fwl     <= inready ;

              if (inready = '1') then
                m_checksum_B  <= m_checksum_B + m_checksum_A +
                                 unsigned (inbyte_s) ;
                m_checksum_A  <= m_checksum_A + unsigned (inbyte_s) ;

                byte_timeout  <= (others => '0') ;
              end if ;

            cur_state         <= PARSE_STATE_FIND_MSG ;

            --  Check for message timed out.

            elsif (byte_timeout /= timeout_c) then
              byte_timeout    <= byte_timeout + 1 ;
              cur_state       <= PARSE_STATE_FIND_MSG ;
            else
              text_reset      <= '1' ;
              next_state      <= PARSE_STATE_WAIT ;
            end if ;

          --  Found a message.  Turn off the text parser an find the
          --  message's length.

          else
            m_number          <= text_result ;
            text_reset        <= '1' ;
            memaddr_select    <= memaddr_select_msg_c ;
            next_state        <= PARSE_STATE_MSG_LEN ;

            --  Set the base RAM addresses to store in.

            temp_ramaddr      <= TO_UNSIGNED (msg_ram_base_c +
                                              msg_ram_temp_addr_c +
                                              if_set (not db_temp,
                                                      msg_ram_temp_size_c),
                                              temp_ramaddr'length) ;

            if (text_result = TO_UNSIGNED (msg_ubx_nav_sol_number_c,
                                           text_result'length)) then

              save_ramaddr    <= TO_UNSIGNED (msg_ram_base_c +
                                              msg_ubx_nav_sol_ramaddr_c +
                                              if_set (not db_nav_sol,
                                                msg_ubx_nav_sol_ramused_c),
                                              save_ramaddr'length) ;

            elsif (text_result = TO_UNSIGNED (msg_ubx_tim_tm2_number_c,
                                              text_result'length)) then

              save_ramaddr    <= TO_UNSIGNED (msg_ram_base_c +
                                              msg_ubx_tim_tm2_ramaddr_c +
                                              if_set (not db_tim_tm2,
                                                msg_ubx_tim_tm2_ramused_c),
                                              save_ramaddr'length) ;

            else
              save_ramaddr    <= (others => '1') ;
            end if ;
          end if ;

        --  Extract the message length.

        when PARSE_STATE_MSG_LEN      =>
          m_length (7 downto 0)     <= unsigned (inbyte_s) ;
          next_state                <= PARSE_STATE_MSG_HIGH ;

        when PARSE_STATE_MSG_HIGH     =>
          m_length (15 downto 8)    <= unsigned (inbyte_s) ;

          --  Abort the message if we don't know what it is.

          if (m_number = msg_count_c) then
            cur_state               <= PARSE_STATE_ABORT ;
          else

            --  Read the message parsing start addr from the lookup table.

            msg_memread_en          <= '1' ;
            msg_memaddr             <=
                RESIZE (CONST_UNSIGNED (msg_rom_base_c +
                                        msg_extract_lookup_c, 1) +
                        CONST_UNSIGNED (msg_extract_lookup_bytes_c) *
                        m_number,
                        msg_memaddr'length ) ;
            byte_count              <=
                TO_UNSIGNED (msg_extract_lookup_bytes_c,
                             byte_count'length) ;
            cur_state               <= PARSE_STATE_LOAD_BYTE ;
            return_state            <= PARSE_STATE_EXTRACT ;
          end if ;

        --  Find the message parsing information in ROM.  The extraction
        --  addr is converted to a field number by subtracting the number of
        --  overhead bytes from the address.  Each message has N bytes of
        --  overhead.

        when PARSE_STATE_EXTRACT      =>
          m_field_number            <=
              RESIZE (unsigned (m_extract) -
                      (m_number * CONST_UNSIGNED (msg_extract_overhead_c)),
                      m_field_number'length) ;
          msg_memaddr               <=
              RESIZE (unsigned (m_extract) +
                      CONST_UNSIGNED (msg_rom_base_c, 1),
                      msg_memaddr'length) ;
          cur_state                 <= PARSE_STATE_FIELD_CNT ;

        --  The msg_memaddr field is used for other purposes after this
        --  state so the fld_memaddr field is used to hold the address of
        --  the next field parse information until it is needed.

        when PARSE_STATE_FIELD_CNT    =>
          m_field_end               <= RESIZE (m_field_number +
                                               unsigned (meminput_in),
                                               m_field_end'length) ;
          m_ramoffset               <= (others => '0') ;
          fld_memaddr               <= msg_memaddr + 2 ;
          msg_memaddr               <= msg_memaddr + 1 ;
          cur_state                 <= PARSE_STATE_NEXT_FLD ;

        --  Process the next field.

        when PARSE_STATE_NEXT_FLD     =>
          msg_memread_en            <= '0' ;

          if (m_field_number = m_field_end) then
            if (m_length /= 0) then
              cur_state             <= PARSE_STATE_ABORT ;
            else
              calc_checksum         <= '0' ;
              next_state            <= PARSE_STATE_CHECKSUM ;
            end if ;

          elsif (m_length = 0) then
            cur_state               <= PARSE_STATE_ABORT_LOOP ;

          else
            m_field_length          <=
                unsigned (meminput_in (msg_size_bits_c downto 1)) ;
            m_field_save            <= meminput_in (0) ;

            if (m_length <
                unsigned (meminput_in (msg_size_bits_c downto 1))) then
              cur_state             <= PARSE_STATE_ABORT ;
            else
              next_state            <= PARSE_STATE_FLD_PERM ;
            end if ;
          end if ;

        --  Store the field byte in permanent RAM if so specified.

        when PARSE_STATE_FLD_PERM     =>
          if (m_field_save = '0') then
            cur_state               <= PARSE_STATE_FLD_DONE ;
          else
            if ((not save_ramaddr) /= 0) then
              memoutput_out         <= inbyte_s ;
              msg_memaddr           <= save_ramaddr + m_ramoffset ;
              memwrite_en_out       <= '1' ;
            end if ;

            cur_state               <= PARSE_STATE_FLD_TEMP ;
          end if ;

        --  Store the field byte in temperary RAM even if already stored
        --  in permanent RAM.

        when PARSE_STATE_FLD_TEMP     =>
          memoutput_out             <= inbyte_s ;
          msg_memaddr               <= temp_ramaddr + m_ramoffset ;
          memwrite_en_out           <= '1' ;
          m_ramoffset               <= m_ramoffset + 1 ;
          cur_state                 <= PARSE_STATE_FLD_DONE ;

        --  Continue copying bytes until all field bytes have been
        --  processed.

        when PARSE_STATE_FLD_DONE     =>
          m_length                  <= m_length - 1 ;
          m_field_length            <= m_field_length - 1 ;

          if (m_field_length = 1) then
            cur_state               <= PARSE_STATE_FLD_CHECK ;
          else
            next_state              <= PARSE_STATE_FLD_PERM ;
          end if ;

        --  Check any special field values to make sure the message is
        --  valid.

        when PARSE_STATE_FLD_CHECK    =>
          m_field_number            <= m_field_number + 1 ;
          msg_memaddr               <= fld_memaddr ;
          fld_memaddr               <= fld_memaddr + 1 ;
          msg_memread_en            <= '1' ;
          cur_state                 <= PARSE_STATE_NEXT_FLD ;

          --  NAV-SOL field checks.

          if (m_field_number = MUNSol_gpsFix_number_c) then
            if (unsigned (inbyte_s) /= NAV_SOL_gpsFix_2D_c and
                unsigned (inbyte_s) /= NAV_SOL_gpsFix_3D_c) then
              cur_state             <= PARSE_STATE_ABORT ;
            end if ;

          elsif (m_field_number = MUNSol_flags_number_c) then
            if ((unsigned (inbyte_s) and NAV_SOL_flags_OK_c) /=
                                      NAV_SOL_flags_OK_c) then
              cur_state             <= PARSE_STATE_ABORT ;
            end if ;

          --  TIM-TM2 field checks.

          elsif (m_field_number = MUTTm2_flags_number_c) then
            if ((unsigned (inbyte_s) and TIM_TM2_flags_Check_c) /=
                                      TIM_TM2_flags_OK_c) then
              cur_state             <= PARSE_STATE_ABORT ;
            end if ;

          end if ;

        --  The message has been completely received.  Now verify that
        --  the checksum is correct.

        when PARSE_STATE_CHECKSUM     =>
          if (m_checksum_A /= unsigned (inbyte_s)) then
            --  One byte left in the message.

            m_length                <= TO_UNSIGNED (1, m_length'length) ;
            cur_state               <= PARSE_STATE_ABORT ;
          else
            next_state              <= PARSE_STATE_CHECKSUM_B ;
          end if ;

        when PARSE_STATE_CHECKSUM_B   =>
          if (m_checksum_B /= unsigned (inbyte_s)) then
            --  Zero bytes left in the message.

            m_length                <= (others => '0') ;
            next_state              <= PARSE_STATE_WAIT ;

          --  Message successful!

          elsif (m_number = msg_ubx_nav_sol_number_c) then

            --  Log the time the position message was received at.

            log_time                <= curtime ;
            byte_count              <= TO_UNSIGNED (gps_time_bytes_c,
                                                    byte_count'length) ;
            msg_memaddr             <= TO_UNSIGNED (msg_ram_postime_addr_c +
                                                    msg_ram_base_c +
                                                    if_set (not db_nav_sol,
                                                      gps_time_bytes_c) - 1,
                                                    msg_memaddr'length) ;

            buffer_load             <= '1' ;
            cur_state               <= PARSE_STATE_SAVE_BYTE ;
            return_state            <= PARSE_STATE_SUCCESS ;

          elsif (m_number = msg_ubx_tim_tm2_number_c) then

            --  Log the time the timemark message was generated at.

            log_time                <= markertime_in ;
            byte_count              <= TO_UNSIGNED (gps_time_bytes_c,
                                                    byte_count'length) ;
            msg_memaddr             <=
                TO_UNSIGNED (msg_ram_marktime_addr_c + msg_ram_base_c +
                             if_set (not db_tim_tm2, gps_time_bytes_c) - 1,
                             msg_memaddr'length) ;

            buffer_load             <= '1' ;
            cur_state               <= PARSE_STATE_SAVE_BYTE ;
            return_state            <= PARSE_STATE_SUCCESS ;

          else
            cur_state               <= PARSE_STATE_SUCCESS ;
          end if;

        --  Return the success indicators.

        when PARSE_STATE_SUCCESS      =>
          msgnumber_out             <= std_logic_vector (m_number) ;
          msgreceived_out           <= '1' ;
          next_state                <= PARSE_STATE_WAIT ;

          --  Indicate the bank with the most recent valid message.

          db_temp                   <= not db_temp ;

          if (m_number = TO_UNSIGNED (msg_ubx_nav_sol_number_c,
                                      m_number'length)) then
            db_nav_sol              <= not db_nav_sol ;
          elsif (m_number = TO_UNSIGNED (msg_ubx_tim_tm2_number_c,
                                         m_number'length)) then
            db_tim_tm2              <= not db_tim_tm2 ;
          end if ;

        --  Abort the parsing operation.  Skip the rest of the bytes in the
        --  message and the checksum bytes too.

        when PARSE_STATE_ABORT        =>
          msg_memread_en            <= '0' ;
          cur_state                 <= PARSE_STATE_WAIT_BYTE ;
          next_state                <= PARSE_STATE_ABORT_LOOP ;

        when PARSE_STATE_ABORT_LOOP   =>
          if (m_length > 1) then
            m_length                <= m_length - 1 ;
            next_state              <= PARSE_STATE_ABORT_LOOP ;
          elsif (calc_checksum = '1') then
            calc_checksum           <= '0' ;
            m_length                <= TO_UNSIGNED (2, m_length'length) ;
            next_state              <= PARSE_STATE_ABORT_LOOP ;
          else
            next_state              <= PARSE_STATE_WAIT ;
          end if ;

      end case ;
    end if ;
  end process parse_fields ;

end architecture rtl ;
