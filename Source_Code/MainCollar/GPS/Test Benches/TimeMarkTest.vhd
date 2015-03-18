------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Send a time mark pulse periodically.
--! @details    When the GPS is maintaining a good position (and time),
--!             periodically trigger a time mark event.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY WORK ;                  --  Use local libraries.
use WORK.UTILITIES.ALL ;        --  General purpose information.
USE WORK.GPS_CLOCK.ALL ;        --  Use GPS Clock information.

USE WORK.GPS_MESSAGE_CTL.ALL ;  --  Use GPS Message information.
USE WORK.MSG_UBX_NAV_SOL.ALL ;  --  Navagation Solution message.


------------------------------------------------------------------------------
--
--! @brief      Initiates a Time Mark event.
--! @details    When the GPS is maintaining good positional and time
--!             information, periodically initiate a time mark event.
--!
--! @param      TIME_MARK_INTERVAL    Milliseconds between time mark events.
--! @param      MIN_POS_ACCURACY      Minimum position accuracy in CM.
--! @param      MAX_POS_AGE           Maximum age the last position found at.
--! @param      MEMADDR_BITS          Number of bits on the address bus.
--! @param      clk                   Clock used to drive the processes.
--! @param      reset                 Reset the processes to initial state.
--! @param      curtime               Current time in GPS format.
--! @param      posbank               Position information memory bank.
--! @param      tmbank                Time mark information memory bank.
--! @param      memdata               Data byte of memory that is addressed.
--! @param      memrcv                Request for the memory bus is granted.
--! @param      memreq                Access to the memory bus requested.
--! @param      memaddr               Address of the byte of memory to read.
--! @param      memread_en            Enable the memory for reading.
--! @param      memwrite_en           Enable the memory for writing.
--! @param      memoutput             Byte to write to memory.
--! @param      marker                Time marker external signal.
--! @param      req_position          Request a new position fix be obtained.
--! @param      req_timemark          Request a new time mark msg be obtained.
--
------------------------------------------------------------------------------

entity TimeMarkTest is

  Generic (
    TIME_MARK_INTERVAL    : natural := 16 ;
    MIN_POS_ACCURACY      : natural := 100 * 100 ;
    MAX_POS_AGE           : natural := 64 ;
    MEMADDR_BITS          : natural := 9
  ) ;
  Port (
    clk                   : in    std_logic ;
    reset                 : in    std_logic ;
    curtimebits           : in    std_logic_vector (GPS_TIME_BITS-1 downto 0) ;
    posbank               : in    std_logic ;
    tmbank                : in    std_logic ;
    memdata               : in    std_logic_vector (7 downto 0) ;
    memrcv                : in    std_logic ;
    memreq                : out   std_logic ;
    memaddr               : out   std_logic_vector (MEMADDR_BITS-1 downto 0) ;
    memread_en            : out   std_logic ;
    memwrite_en           : out   std_logic ;
    memoutput             : out   std_logic_vector (7 downto 0) ;
    marker                : out   std_logic ;
    req_position          : out   std_logic ;
    req_timemark          : out   std_logic
  ) ;

end entity TimeMarkTest ;


architecture behavior of TimeMarkTest is

  --  Time Mark Generation States.

  type TimeMarkState is   (
    MARK_STATE_BYTE_LOAD,
    MARK_STATE_BYTE_SAVE,
    MARK_STATE_REQMEM,
    MARK_STATE_RCVMEM,
    MARK_STATE_CHECK,
    MARK_STATE_CHK_CONVERT,
    MARK_STATE_CHK_CURRENT,
    MARK_STATE_POS_WAIT,
    MARK_STATE_ACCURACY,
    MARK_STATE_CHK_ACCURACY,
    MARK_STATE_SUCCESS,
    MARK_STATE_END,
    MARK_STATE_LOGMARK,
    MARK_STATE_DONE
  ) ;

  signal cur_state        : TimeMarkState ;
  signal return_state     : TimeMarkState ;

  --  Output signals that must be read.

  signal mem_address        : unsigned (MEMADDR_BITS-1 downto 0) ;

  --  Time mark scheduling information.

  signal time_mark_clock    : std_logic ;
  signal time_mark_target   : unsigned (GPS_TIME_MILLIBITS-1 downto 0) ;

  signal send_time_mark     : std_logic ;
  signal time_mark_pending  : std_logic ;

  signal last_millibit      : std_logic ;

  --  Time conversion values.

  signal logtime            : GPS_Time ;

  --  Poll completed information.

  signal last_posbank       : std_logic ;
  signal last_tmbank        : std_logic ;

  --  Scratch area used for loading/storing bit vectors to/from
  --  memory.  Each signal using it is defined via an alias.

  constant BYTE_LENGTH_TBL : integer_vector :=
      (GPS_TIME_BYTES, MUNSol_pAcc_SIZE) ;

  constant BYTE_BUFFER_BYTES    : natural := max_integer (BYTE_LENGTH_TBL) ;

  signal byte_buffer            : std_logic_vector (BYTE_BUFFER_BYTES*8-1
                                                    downto 0) ;

  signal byte_count             :
      unsigned (const_bits (BYTE_BUFFER_BYTES)-1 downto 0) ;

  alias  logtime_bits           : std_logic_vector (GPS_TIME_BITS-1 downto 0) is
                                  byte_buffer      (BYTE_BUFFER_BYTES*8 -
                                                    GPS_TIME_BYTES*8 +
                                                    GPS_TIME_BITS-1 downto
                                                    BYTE_BUFFER_BYTES*8 -
                                                    GPS_TIME_BYTES*8) ;

  alias  marker_time_bits       : std_logic_vector (GPS_TIME_BITS-1 downto 0) is
                                  byte_buffer      (GPS_TIME_BITS-1 downto 0) ;

  alias  posacc                 : std_logic_vector (MUNSol_pAcc_SIZE*8-1
                                                    downto 0) is
                                  byte_buffer (BYTE_BUFFER_BYTES*8-1 downto
                                               BYTE_BUFFER_BYTES*8 -
                                               MUNSol_pAcc_SIZE*8) ;

  signal curtime                : GPS_Time ;

begin

  curtime           <= TO_GPS_TIME (curtimebits) ;

  --  Pass the memory address out of the entity.

  memaddr           <= std_logic_vector (mem_address) ;

  --  Produce a millisecond clock from the current time.

  time_mark_clock   <= curtime.millisecond_nanosecond (GPS_TIME_NANOBITS-1) ;

  --  Wait until the next time for a marker has arrived.

  marker_alarm : process (reset, time_mark_clock)
  begin
    if reset = '1' then
      send_time_mark        <= '0' ;

    elsif time_mark_clock'event and time_mark_clock = '1' then

      if time_mark_pending = '1' then
        send_time_mark      <= '0' ;

      elsif send_time_mark = '0' then
        if time_mark_target = unsigned (curtime.week_millisecond) then
          send_time_mark    <= '1' ;
        end if ;
      end if ;
    end if ;
  end process ;


  --  Handle pending time mark requests.

  marker_pending : process (reset, clk)
  begin
    if reset = '1' then
      time_mark_pending                   <= '1' ;
      memreq                              <= '0' ;
      mem_address                         <= (others => '0') ;
      memread_en                          <= '0' ;
      memwrite_en                         <= '0' ;
      time_mark_target                    <= (others => '0') ;
      marker                              <= '0' ;
      last_posbank                        <= posbank ;
      last_tmbank                         <= tmbank ;
      req_position                        <= '0' ;
      req_timemark                        <= '0' ;
      cur_state                           <= MARK_STATE_POS_WAIT ;

    elsif clk'event and clk = '1' then

      --  Write enable is set for only one clock cycle.

      memwrite_en           <= '0' ;

      --  Request a time mark poll until new information has arrived.

      if tmbank /= last_tmbank then
        req_timemark        <= '0' ;
      end if ;

      --  Start a new time mark generation sequence.

      if send_time_mark = '1' then
        time_mark_pending   <= '1' ;
        cur_state           <= MARK_STATE_REQMEM ;

      elsif send_time_mark = '0' and time_mark_pending = '1' then

        case cur_state is

          --  Wait until the memory request has been granted before continuing.

          when MARK_STATE_REQMEM        =>
            memreq          <= '1' ;
            cur_state       <= MARK_STATE_RCVMEM ;

          when MARK_STATE_RCVMEM        =>
            if memrcv = '1' then
              cur_state     <= MARK_STATE_CHECK ;
            else
              cur_state     <= MARK_STATE_RCVMEM ;
            end if ;

          --  Subroutine like state to load a value from memory into a bit
          --  vector.

          when MARK_STATE_BYTE_LOAD     =>
            if byte_count > 0 then
              byte_count    <= byte_count - 1 ;

              byte_buffer   <= memdata &
                               byte_buffer (BYTE_BUFFER_BYTES*8-1 downto 8) ;
              mem_address   <= mem_address + 1 ;
              cur_state     <= MARK_STATE_BYTE_LOAD ;
            else
              cur_state     <= return_state ;
            end if ;

          --  Subroutine like state to save a value into memory from a bit
          --  vector.  Address must start one byte before the first byte to
          --  be written.

          when MARK_STATE_BYTE_SAVE     =>
            if byte_count > 0 then
              memoutput                 <= byte_buffer (7 downto 0) ;
              byte_buffer (byte_buffer'length-8-1 downto 0)   <=
                      byte_buffer (byte_buffer'length-1 downto 8) ;

              byte_count                <= byte_count - 1 ;
              mem_address               <= mem_address + 1 ;
              memwrite_en               <= '1' ;
              cur_state                 <= MARK_STATE_BYTE_SAVE ;
            else
              cur_state                 <= return_state ;
            end if ;

        --  Check how current the GPS position is.  It must always be less
        --  than one week.

          when MARK_STATE_CHECK         =>
            byte_count      <= TO_UNSIGNED (GPS_TIME_BYTES,
                                            byte_count'length) ;
            mem_address     <= TO_UNSIGNED (MSG_RAM_BASE +
                                            MSG_RAM_POSTIME_ADDR +
                                            if_set (posbank,
                                                    MSG_RAM_POSTIME_SIZE),
                                            mem_address'length) ;
            memread_en      <= '1' ;
            cur_state       <= MARK_STATE_BYTE_LOAD ;
            return_state    <= MARK_STATE_CHK_CONVERT ;

          when MARK_STATE_CHK_CONVERT   =>
            memread_en      <= '0' ;
            logtime         <= TO_GPS_TIME (logtime_bits) ;
            cur_state       <= MARK_STATE_CHK_CURRENT ;

          when MARK_STATE_CHK_CURRENT   =>
            if (unsigned (curtime.week_number) -
                unsigned (logtime.week_number) > 1) or
               ((curtime.week_number = logtime.week_number) and
                (unsigned (curtime.week_millisecond) -
                 unsigned (logtime.week_millisecond) > MAX_POS_AGE)) or
               ((curtime.week_number /= logtime.week_number) and
                ((unsigned (curtime.week_millisecond) >
                  unsigned (logtime.week_millisecond)) or
                 (unsigned (logtime.week_millisecond) -
                  unsigned (curtime.week_millisecond) <
                      MILLISEC_WEEK - MAX_POS_AGE))) then

              last_posbank  <= posbank ;
              cur_state     <= MARK_STATE_POS_WAIT ;
            else
              cur_state     <= MARK_STATE_ACCURACY ;
            end if ;

          --  Determine if the accuracy of the position is good enough.

          when MARK_STATE_ACCURACY      =>
            byte_count      <= TO_UNSIGNED (MUNSol_pAcc_SIZE,
                                            byte_count'length) ;
            mem_address     <= TO_UNSIGNED (MSG_RAM_BASE +
                                            MSG_UBX_NAV_SOL_RAMADDR +
                                            if_set (posbank,
                                                    MSG_UBX_NAV_SOL_RAMUSED) +
                                            MUNSol_pAcc_OFFSET,
                                            mem_address'length) ;
            memread_en      <= '1' ;
            cur_state       <= MARK_STATE_BYTE_LOAD ;
            return_state    <= MARK_STATE_CHK_ACCURACY ;

          when MARK_STATE_CHK_ACCURACY  =>
            memread_en      <= '0' ;

            if unsigned (posacc) > MIN_POS_ACCURACY then
              last_posbank  <= posbank ;
              cur_state     <= MARK_STATE_POS_WAIT ;
            else
              req_position  <= '0' ;
              last_millibit <= curtime.week_millisecond (0) ;
              cur_state     <= MARK_STATE_SUCCESS ;
            end if ;

          --  Generate a time mark.  Wait for 1 millisecond between setting
          --  the time mark line high then back low.
          --  Exit the state machine and schedule a new time mark.

          when MARK_STATE_SUCCESS       =>
            memreq                <= '0' ;

            if last_millibit /= curtime.week_millisecond (0) then
              marker              <= '1' ;
              cur_state           <= MARK_STATE_END ;
            else
              cur_state           <= MARK_STATE_SUCCESS ;
            end if ;

          when MARK_STATE_END           =>
            if last_millibit = curtime.week_millisecond (0) then
              marker              <= '0' ;
              marker_time_bits    <= TO_STD_LOGIC_VECTOR (curtime) ;

              if unsigned (curtime.week_millisecond) >=
                 MILLISEC_WEEK - TIME_MARK_INTERVAL then

                time_mark_target  <= unsigned (curtime.week_millisecond) -
                                     (MILLISEC_WEEK - TIME_MARK_INTERVAL) ;
              else
                time_mark_target  <= unsigned (curtime.week_millisecond) +
                                     TIME_MARK_INTERVAL ;
              end if ;

              memreq              <= '1' ;
              cur_state           <= MARK_STATE_LOGMARK ;
            else
              cur_state           <= MARK_STATE_END ;
            end if ;

          --  Log the time the timemark was made to memory.

          when MARK_STATE_LOGMARK       =>
            if memrcv = '1' then
              mem_address         <= TO_UNSIGNED (MSG_RAM_BASE +
                                                  MSG_RAM_MARKTIME_ADDR - 1,
                                                  mem_address'length) ;
              byte_count          <= TO_UNSIGNED (GPS_TIME_BYTES,
                                                  byte_count'length) ;
              cur_state           <= MARK_STATE_BYTE_SAVE ;
              return_state        <= MARK_STATE_DONE ;
            else
              cur_state           <= MARK_STATE_LOGMARK ;
            end if ;

          when MARK_STATE_DONE          =>
            memreq                <= '0' ;
            time_mark_pending     <= '0' ;

            last_tmbank           <= tmbank ;
            req_timemark          <= '1' ;

          --  Wait until a new position has been received and then check
          --  it out.  When the bank the position data is stored in changes,
          --  new information has been stored in that bank.

          when MARK_STATE_POS_WAIT      =>
            memreq                <= '0' ;
            req_position          <= '1' ;

            if posbank /= last_posbank then
              req_position        <= '0' ;
              cur_state           <= MARK_STATE_REQMEM ;
            else
              cur_state           <= MARK_STATE_POS_WAIT ;
            end if ;

        end case ;
      end if ;
    end if ;
  end process ;


end behavior ;
