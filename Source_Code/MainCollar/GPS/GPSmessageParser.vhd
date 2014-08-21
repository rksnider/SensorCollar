------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Parses messages from a NEO-6T GPS.
--! @details    Component parses messages from a GPS, converting them into
--!             binary and storing the results in Dual-Port memory.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

library WORK ;
use WORK.UTILITIES.ALL ;        --  General utility functions and definitons.

use WORK.GPS_CLOCK.ALL ;        --  Use the GPS Clock information.

use WORK.GPSmessageInfo.all ;   --  GPS message definitions.
use WORK.gps_message_ctl.all ;
use WORK.msg_ubx_nav_sol.all ;
use WORK.msg_ubx_tim_tm2.all ;


------------------------------------------------------------------------------
--
--! @brief      GPS Message Parser.
--! @details    Parse fields in GPS messages and store the results in Dual-
--!             Port memory.  While the message is being parsed the contents
--!             of the associated memory is marked as invalid.
--!
--! @param      MEMADDR_BITS  Bit width of the memory address.
--! @param      reset         Reset the entity to an initial state.
--! @param      clk           Clock used to move throuth states in the entity
--!                           and its components.
--! @param      curtime       The GPS Time to use for logging events at.
--! @param      inbyte        Byte received to add to message to parse.
--! @param      inready       The byte is ready to be parsed.
--! @param      meminput      Data byte read from memory that is addressed.
--! @param      memrcv        Receive access to memory.
--! @param      memreq        Request access to memory.
--! @param      memoutput     Data byte written to memory that is addressed.
--! @param      memaddr       Address of the byte of memory to read/write.
--! @param      memread_en    Enable the memory for reading.
--! @param      memwrite_en   Enable a write to the memory.
--! @param      ramclock      Clock to use to write to the output memory.
--!                           The memory clock is the inverse of the process
--!                           control clock to allow the process address,
--!                           data, and write enable signals time to settle
--!                           before being acted on.  This is possible because
--!                           the memory is much faster than the process
--!                           clock.  It can act on the negative edge of the
--!                           process clock and complete the action well
--!                           before the positive edge of the process clock.
--! @param      datavalid     The bank of memory with the newest valid data if
--!                           two banks are available, otherwise set when data
--!                           is valid.
--! @param      tempbank      The bank of memory the most recent temp message
--!                           is in.
--! @param      msgnumber     Message number of the most recent valid message.
--! @param      msgreceived   A new valid message has been received.
--
------------------------------------------------------------------------------

entity GPSmessageParser is

  Generic (
    MEMADDR_BITS          : natural := 8
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    curtime               : in    GPS_Time ;
    inbyte                : in    std_logic_vector (7 downto 0) ;
    inready               : in    std_logic ;
    meminput              : in    std_logic_vector (7 downto 0) ;
    memrcv                : in    std_logic ;
    memreq                : out   std_logic ;
    memoutput             : out   std_logic_vector (7 downto 0) ;
    memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
    memread_en            : out   std_logic ;
    memwrite_en           : out   std_logic ;
    datavalid             : out   std_logic_vector (MSG_RAM_BLOCKS-1 downto 0) ;
    tempbank              : out   std_logic ;
    msgnumber             : out   std_logic_vector (MSG_COUNT_BITS-1 downto 0) ;
    msgreceived           : out   std_logic
  ) ;

end entity GPSmessageParser ;


architecture behavior of GPSmessageParser is

  --  Text tree parsing component.

  component ParseTextField is

    Generic (
      MEMADDR_BITS        : natural := 8 ;
      RESULT_BITS         : natural := 8 ;
      OFFSET_BITS         : natural := 8
    ) ;
    Port (
      reset               : in    std_logic ;
      clk                 : in    std_logic ;
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

  --  MBX message checking information.

  constant NAV_SOL_gpsFix2D   : unsigned (7 downto 0) := x"02" ;
  constant NAV_SOL_gpsFix3D   : unsigned (7 downto 0) := x"03" ;
  constant NAV_SOL_flagsOK    : unsigned (7 downto 0) := "00001101" ;

  constant TIM_TM2_flagsOK    : unsigned (7 downto 0) := "01110000" ;

  --  Character processing signals.

  signal inready_fwl            : std_logic ;

  signal text_reset             : std_logic ;

  signal text_valid             : std_logic ;

  signal text_result            : unsigned (MSG_COUNT_BITS-1 downto 0) ;

  --  Memory addressed from one of several sources.

  constant MEMADDR_SELECT_MSG   : unsigned (0 downto 0) := "0" ;
  constant MEMADDR_SELECT_TEXT  : unsigned (0 downto 0) := "1" ;

  signal memaddr_select         : unsigned (0 downto 0) ;

  signal text_memaddr           : unsigned (MEMADDR_BITS-1 downto 0) ;
  signal msg_memaddr            : unsigned (MEMADDR_BITS-1 downto 0) ;
  signal fld_memaddr            : unsigned (MEMADDR_BITS-1 downto 0) ;

  signal text_memread_en        : std_logic ;
  signal msg_memread_en         : std_logic ;

  signal text_memreq            : std_logic ;
  signal msg_memreq             : std_logic ;

  --  Valid message banks.

  signal db_nav_sol             : std_logic ;
  signal db_tim_tm2             : std_logic ;
  signal db_temp                : std_logic ;

  --  Checksum processing

  signal calc_checksum          : std_logic ;
  signal m_checksum_A           : unsigned (7 downto 0) ;
  signal m_checksum_B           : unsigned (7 downto 0) ;

  --  Message information.

  signal m_number               : unsigned (MSG_COUNT_BITS-1 downto 0) ;
  signal m_length               : unsigned (15 downto 0) ;
  signal m_ramoffset            : unsigned (MSG_SIZE_BITS-1 downto 0) ;
  signal m_field_number         : unsigned (MSG_FIELD_BITS-1 downto 0) ;
  signal m_field_end            : unsigned (MSG_FIELD_BITS-1 downto 0) ;
  signal m_field_length         : unsigned (MSG_SIZE_BITS-1 downto 0) ;
  signal m_field_save           : std_logic ;

  --  RAM memory information.

  signal temp_ramaddr           : unsigned (MEMADDR_BITS-1 downto 0) ;
  signal save_ramaddr           : unsigned (MEMADDR_BITS-1 downto 0) ;

  --  Scratch area used for loading/storing bit vectors to/from
  --  memory.  Each signal using it is defined via an alias.

  constant BYTE_LENGTH_TBL : integer_vector :=
      (MSG_EXTRACT_LOOKUP_BYTES, GPS_TIME_BYTES) ;

  constant BYTE_BUFFER_SIZE     : natural := max_integer (BYTE_LENGTH_TBL) ;

  signal byte_buffer            : std_logic_vector (BYTE_BUFFER_SIZE*8-1
                                                    downto 0) ;

  signal byte_count             : unsigned (const_bits (BYTE_BUFFER_SIZE)-1
                                            downto 0) ;

  alias  m_extract              : std_logic_vector (MSG_EXTRACT_LOOKUP_BYTES*8-1
                                                    downto 0) is
                                  byte_buffer (BYTE_BUFFER_SIZE*8-1 downto
                                               BYTE_BUFFER_SIZE*8 -
                                               MSG_EXTRACT_LOOKUP_BYTES*8) ;

  alias  log_time               : std_logic_vector (GPS_TIME_BITS-1 downto 0) is
                                  byte_buffer      (GPS_TIME_BITS-1 downto 0) ;


begin

  --  Request memory when someone wants it and release it when everyone
  --  is done with it.

  memreq        <= text_memreq or msg_memreq ;

  --  Select who can set the memory address.

  with memaddr_select select
    memaddr     <=  std_logic_vector (text_memaddr +
                                      MSG_EXTRACT_TREE +
                                      MSG_ROM_BASE)   when MEMADDR_SELECT_TEXT,
                    std_logic_vector (msg_memaddr)    when others ;

  memread_en    <= msg_memread_en or text_memread_en ;

  --  Data banks for these messages are kept internally and exported
  --  continuously.

  datavalid (MSG_UBX_NAV_SOL_RAMBLOCK)    <= db_nav_sol ;
  datavalid (MSG_UBX_TIM_TM2_RAMBLOCK)    <= db_tim_tm2 ;

  tempbank                                <= db_temp ;

  --  Text tree parsing instance.

  textfield : component ParseTextField

    Generic Map (
      MEMADDR_BITS        => MEMADDR_BITS,
      RESULT_BITS         => MSG_COUNT_BITS,
      OFFSET_BITS         => MSG_TREE_OFFSET_BITS
    )
    Port Map (
      reset               => text_reset,
      clk                 => clk,
      inchar              => inbyte,
      inready             => inready,
      memdata             => meminput,
      memrcv              => memrcv,
      memreq              => text_memreq,
      memaddr             => text_memaddr,
      memread_en          => text_memread_en,
      valid               => text_valid,
      result              => text_result
    ) ;


  ------------------------------------------------------------------------------
  --
  --! @brief      Parse the fields in a line.
  --! @details    Parse the individual fields in a line and save the results
  --!             to memory.
  --!
  --! @param      reset         Reset the Parser.
  --! @param      clk           Multi-state per character clock.
  --
  ------------------------------------------------------------------------------

  parse_fields:  process (reset, clk)
  begin
    if reset = '1' then
      text_reset      <= '1' ;
      inready_fwl     <= '0' ;
      db_nav_sol      <= '0' ;
      db_tim_tm2      <= '0' ;
      db_temp         <= '0' ;
      msg_memreq      <= '0' ;
      msg_memaddr     <= (others => '0') ;
      msg_memread_en  <= '0' ;
      memwrite_en     <= '0' ;
      memaddr_select  <= MEMADDR_SELECT_MSG ;
      cur_state       <= PARSE_STATE_WAIT_BYTE ;
      next_state      <= PARSE_STATE_WAIT ;
      msgnumber       <= (others => '0') ;
      msgreceived     <= '0' ;

    elsif clk'event and clk = '1' then

      --  Always allow the write enable to be high for just one clock cycle.

      memwrite_en <= '0' ;

      --  Always wait for a new character unless changed within a state.
      --  In most cases a new byte is needed before a state can proceed.
      --  Thus the state machine waits in the WAIT_BYTE state until a new
      --  byte has arrived then proceeds to the next specified state.
      --  In some states multiple clock cycles are needed to process the
      --  information received.  In those cases waiting for a new byte is
      --  skipped.  The state machine proceeds at the clock rate instead.
      --  THIS CHANGE DOES NOT TAKE PLACE UNTIL THE END OF THE PROCESS!
      --  IT CAN BE OVERRIDDEN IF SET AGAIN BEFORE THE END OF THE PROCESS!

      cur_state               <= PARSE_STATE_WAIT_BYTE ;

      --  Parsing state machine.

      case cur_state is

        --  Subroutine like state to load a value from memory into a bit
        --  vector.

        when PARSE_STATE_LOAD_BYTE    =>
          if byte_count > 0 then
            byte_buffer (byte_buffer'length-8-1 downto 0)   <=
                  byte_buffer (byte_buffer'length-1 downto 8) ;
            byte_buffer (byte_buffer'length-1 downto
                         byte_buffer'length-8)              <= meminput ;

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
          if byte_count > 0 then
            memoutput                 <= byte_buffer (7 downto 0) ;
            byte_buffer (byte_buffer'length-8-1 downto 0)   <=
                    byte_buffer (byte_buffer'length-1 downto 8) ;

            byte_count                <= byte_count - 1 ;
            msg_memaddr               <= msg_memaddr + 1 ;
            memwrite_en               <= '1' ;
            cur_state                 <= PARSE_STATE_SAVE_BYTE ;
          else
            cur_state                 <= return_state ;
          end if ;

       --  Wait until a new byte has been received.  Add its value to the
       --  checksum if currently calculating the checksum.

        when PARSE_STATE_WAIT_BYTE  =>
          msg_memreq          <= '0' ;
          msg_memread_en      <= '0' ;

          if inready_fwl  /= inready then
            inready_fwl       <= inready ;

            if inready = '1' then
              if calc_checksum = '1' then
                m_checksum_B  <= m_checksum_B + m_checksum_A +
                                 unsigned (inbyte) ;
                m_checksum_A  <= m_checksum_A + unsigned (inbyte) ;
              end if ;

              msg_memreq      <= '1' ;
              cur_state       <= PARSE_STATE_WAIT_MEM ;
            end if ;
          end if ;

        when PARSE_STATE_WAIT_MEM   =>
          if memrcv = '1' then
            cur_state         <= next_state ;
          else
            cur_state         <= PARSE_STATE_WAIT_MEM ;
          end if ;

        --  Wait until a new message is detected.

        when PARSE_STATE_WAIT       =>
          text_reset          <= '1' ;
          msg_memread_en      <= '0' ;

          if inbyte = MSG_UBX_SYNC_1 then
            next_state        <= PARSE_STATE_SYNC ;
          else
            next_state        <= PARSE_STATE_WAIT ;
          end if ;

        when PARSE_STATE_SYNC       =>
          if inbyte = MSG_UBX_SYNC_2 then
            msgreceived       <= '0' ;

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
           memaddr_select     <= MEMADDR_SELECT_TEXT ;
           cur_state          <= PARSE_STATE_FIND_MSG ;

        when PARSE_STATE_FIND_MSG   =>

          --  When no valid message found read the length and abort with
          --  unknown message.

          if text_valid = '0' then
            m_number          <= TO_UNSIGNED (MSG_COUNT, m_number'length) ;
            text_reset        <= '1' ;
            memaddr_select    <= MEMADDR_SELECT_MSG ;
            next_state        <= PARSE_STATE_MSG_LEN ;

          --  Keep searching until a message is found.

          elsif text_result = MSG_COUNT then
            cur_state         <= PARSE_STATE_FIND_MSG ;

          --  Found a message.  Turn off the text parser an find the
          --  message's length.

          else
            m_number          <= text_result ;
            text_reset        <= '1' ;
            memaddr_select    <= MEMADDR_SELECT_MSG ;
            next_state        <= PARSE_STATE_MSG_LEN ;

            --  Set the base RAM addresses to store in.

            temp_ramaddr      <= TO_UNSIGNED (MSG_RAM_BASE +
                                              MSG_RAM_TEMP_ADDR +
                                              if_set (not db_temp,
                                                      MSG_RAM_TEMP_SIZE),
                                              temp_ramaddr'length) ;

            if text_result = TO_UNSIGNED (MSG_UBX_NAV_SOL_NUMBER,
                                          text_result'length) then

              save_ramaddr    <= TO_UNSIGNED (MSG_RAM_BASE +
                                              MSG_UBX_NAV_SOL_RAMADDR +
                                              if_set (not db_nav_sol,
                                                      MSG_UBX_NAV_SOL_RAMUSED),
                                              save_ramaddr'length) ;

            elsif text_result = TO_UNSIGNED (MSG_UBX_TIM_TM2_NUMBER,
                                            text_result'length) then

              save_ramaddr    <= TO_UNSIGNED (MSG_RAM_BASE +
                                              MSG_UBX_TIM_TM2_RAMADDR +
                                              if_set (not db_tim_tm2,
                                                      MSG_UBX_TIM_TM2_RAMUSED),
                                              save_ramaddr'length) ;

            else
              save_ramaddr    <= (others => '1') ;
            end if ;
          end if ;

        --  Extract the message length.

        when PARSE_STATE_MSG_LEN      =>
          m_length (7 downto 0)     <= unsigned (inbyte) ;
          next_state                <= PARSE_STATE_MSG_HIGH ;

        when PARSE_STATE_MSG_HIGH     =>
          m_length (15 downto 8)    <= unsigned (inbyte) ;

          --  Abort the message if we don't know what it is.

          if m_number = MSG_COUNT then
            cur_state               <= PARSE_STATE_ABORT ;
          else

            --  Read the message parsing start addr from the lookup table.

            msg_memread_en          <= '1' ;
            msg_memaddr             <=
                RESIZE (CONST_UNSIGNED (MSG_ROM_BASE +
                                        MSG_EXTRACT_LOOKUP, 1) +
                        CONST_UNSIGNED (MSG_EXTRACT_LOOKUP_BYTES) * m_number,
                        msg_memaddr'length ) ;
            byte_count              <= TO_UNSIGNED (MSG_EXTRACT_LOOKUP_BYTES,
                                                    byte_count'length) ;
            cur_state               <= PARSE_STATE_LOAD_BYTE ;
            return_state            <= PARSE_STATE_EXTRACT ;
          end if ;

        --  Find the message parsing information in ROM.  The extraction addr
        --  is converted to a field number by subtracting the number of
        --  overhead bytes from the address.  Each message has N bytes of
        --  overhead.

        when PARSE_STATE_EXTRACT      =>
          m_field_number            <=
              RESIZE (unsigned (m_extract) -
                      (m_number * CONST_UNSIGNED (MSG_EXTRACT_OVERHEAD)),
                      m_field_number'length) ;
          msg_memaddr               <=
              RESIZE (unsigned (m_extract) + CONST_UNSIGNED (MSG_ROM_BASE, 1),
                      msg_memaddr'length) ;
          cur_state                 <= PARSE_STATE_FIELD_CNT ;

        --  The msg_memaddr field is used for other purposes after this state
        --  so the fld_memaddr field is used to hold the address of the next
        --  field parse information until it is needed.

        when PARSE_STATE_FIELD_CNT    =>
          m_field_end               <= RESIZE (m_field_number +
                                               unsigned (meminput),
                                               m_field_end'length) ;
          m_ramoffset               <= (others => '0') ;
          fld_memaddr               <= msg_memaddr + 2 ;
          msg_memaddr               <= msg_memaddr + 1 ;
          cur_state                 <= PARSE_STATE_NEXT_FLD ;

        --  Process the next field.

        when PARSE_STATE_NEXT_FLD     =>
          msg_memread_en            <= '0' ;

          if m_field_number = m_field_end then
            if m_length /= 0 then
              cur_state             <= PARSE_STATE_ABORT ;
            else
              calc_checksum         <= '0' ;
              next_state            <= PARSE_STATE_CHECKSUM ;
            end if ;
          else
            m_field_length          <= unsigned (meminput (MSG_SIZE_BITS downto 1)) ;
            m_field_save            <= meminput (0) ;

            if m_length < unsigned (meminput (MSG_SIZE_BITS downto 1)) then
              cur_state             <= PARSE_STATE_ABORT ;
            else
              next_state            <= PARSE_STATE_FLD_PERM ;
            end if ;
          end if ;

        --  Store the field byte in permanent RAM if so specified.

        when PARSE_STATE_FLD_PERM     =>
          if m_field_save = '0' then
            cur_state               <= PARSE_STATE_FLD_DONE ;
          else
            if (not save_ramaddr) /= 0 then
              memoutput             <= inbyte ;
              msg_memaddr           <= save_ramaddr + m_ramoffset ;
              memwrite_en           <= '1' ;
            end if ;

            cur_state               <= PARSE_STATE_FLD_TEMP ;
          end if ;

        --  Store the field byte in temperary RAM even if already stored
        --  in permanent RAM.

        when PARSE_STATE_FLD_TEMP     =>
          memoutput                 <= inbyte ;
          msg_memaddr               <= temp_ramaddr + m_ramoffset ;
          memwrite_en               <= '1' ;
          m_ramoffset               <= m_ramoffset + 1 ;
          cur_state                 <= PARSE_STATE_FLD_DONE ;

        --  Continue copying bytes until all field bytes have been processed.

        when PARSE_STATE_FLD_DONE     =>
          m_length                  <= m_length - 1 ;
          m_field_length            <= m_field_length - 1 ;

          if m_field_length = 1 then
            cur_state               <= PARSE_STATE_FLD_CHECK ;
          else
            next_state              <= PARSE_STATE_FLD_PERM ;
          end if ;

        --  Check any special field values to make sure the message is valid.

        when PARSE_STATE_FLD_CHECK    =>
          m_field_number            <= m_field_number + 1 ;
          msg_memaddr               <= fld_memaddr ;
          fld_memaddr               <= fld_memaddr + 1 ;
          msg_memread_en            <= '1' ;
          cur_state                 <= PARSE_STATE_NEXT_FLD ;

          --  NAV-SOL field checks.

          if m_field_number = MUNSol_gpsFix_NUMBER then
            if unsigned (inbyte) /= NAV_SOL_gpsFix_2D and
               unsigned (inbyte) /= NAV_SOL_gpsFix_3D then
              cur_state             <= PARSE_STATE_ABORT ;
            end if ;

          elsif m_field_number = MUNSol_flags_NUMBER then
            if (unsigned (inbyte) and NAV_SOL_flags_GPSfixOK) /=
                                      NAV_SOL_flags_GPSfixOK then
              cur_state             <= PARSE_STATE_ABORT ;
            end if ;

          --  TIM-TM2 field checks.

          elsif m_field_number = MUTTm2_flags_NUMBER then
            if (unsigned (inbyte) and TIM_TM2_flags_Check) /=
                                      TIM_TM2_flags_OK then
              cur_state             <= PARSE_STATE_ABORT ;
            end if ;

          end if ;

        --  The message has been completely received.  Now verify that
        --  the checksum is correct.

        when PARSE_STATE_CHECKSUM     =>
          if m_checksum_A /= unsigned (inbyte) then
            --  One byte left in the message.

            m_length                <= TO_UNSIGNED (1, m_length'length) ;
            cur_state               <= PARSE_STATE_ABORT ;
          else
            next_state              <= PARSE_STATE_CHECKSUM_B ;
          end if ;

        when PARSE_STATE_CHECKSUM_B   =>
          if m_checksum_B /= unsigned (inbyte) then
            --  Zero bytes left in the message.

            m_length                <= (others => '0') ;
            cur_state               <= PARSE_STATE_ABORT ;

          --  Message successful!

          elsif m_number = MSG_UBX_NAV_SOL_NUMBER then

            --  Log the time the position message was received at.

            log_time                <= TO_STD_LOGIC_VECTOR (curtime) ;
            byte_count              <= TO_UNSIGNED (GPS_TIME_BYTES,
                                                    byte_count'length) ;
            msg_memaddr             <= TO_UNSIGNED (MSG_RAM_POSTIME_ADDR +
                                                    MSG_RAM_BASE +
                                                    if_set (not db_nav_sol,
                                                            GPS_TIME_BYTES) - 1,
                                                    msg_memaddr'length) ;

            cur_state               <= PARSE_STATE_SAVE_BYTE ;
            return_state            <= PARSE_STATE_SUCCESS ;

          elsif m_number = MSG_UBX_TIM_TM2_NUMBER then

            --  Log the time the timemark message was received at.

            log_time                <= TO_STD_LOGIC_VECTOR (curtime) ;
            byte_count              <= TO_UNSIGNED (GPS_TIME_BYTES,
                                                    byte_count'length) ;
            msg_memaddr             <= TO_UNSIGNED (MSG_RAM_MARKTIME_ADDR +
                                                    MSG_RAM_BASE +
                                                    if_set (not db_tim_tm2,
                                                            GPS_TIME_BYTES) - 1,
                                                    msg_memaddr'length) ;

            cur_state               <= PARSE_STATE_SAVE_BYTE ;
            return_state            <= PARSE_STATE_SUCCESS ;

          else
            cur_state               <= PARSE_STATE_SUCCESS ;
          end if;

        --  Return the success indicators.

        when PARSE_STATE_SUCCESS      =>
          msgnumber                 <= std_logic_vector (m_number) ;
          msgreceived               <= '1' ;
          next_state                <= PARSE_STATE_WAIT ;

          --  Indicate the bank with the most recent valid message.

          db_temp                   <= not db_temp ;

          if m_number = TO_UNSIGNED (MSG_UBX_NAV_SOL_NUMBER,
                                     m_number'length) then
            db_nav_sol              <= not db_nav_sol ;
          elsif m_number = TO_UNSIGNED (MSG_UBX_TIM_TM2_NUMBER,
                                        m_number'length) then
            db_tim_tm2              <= not db_tim_tm2 ;
          end if ;

        --  Abort the parsing operation.  Skip the rest of the bytes in the
        --  message and the checksum bytes too.

        when PARSE_STATE_ABORT        =>
          msg_memread_en            <= '0' ;
          cur_state                 <= PARSE_STATE_WAIT_BYTE ;
          next_state                <= PARSE_STATE_ABORT_LOOP ;

        when PARSE_STATE_ABORT_LOOP   =>
          if m_length > 1 then
            m_length                <= m_length - 1 ;
            next_state              <= PARSE_STATE_ABORT_LOOP ;
          elsif calc_checksum = '1' then
            calc_checksum           <= '0' ;
            m_length                <= TO_UNSIGNED (2, m_length'length) ;
            next_state              <= PARSE_STATE_ABORT_LOOP ;
          else
            next_state              <= PARSE_STATE_WAIT ;
          end if ;

      end case ;
    end if ;
  end process parse_fields ;

end behavior ;
