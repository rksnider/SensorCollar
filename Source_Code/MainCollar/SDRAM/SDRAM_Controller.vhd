----------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      SD RAM controller.
--! @details    This file contains the entity that controls SD RAM.
--! @author     Emery Newlon
--! @version    $Revision$
--
----------------------------------------------------------------------------

library IEEE ;                        --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;         --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;            --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;              --  Real number functions.

library WORK ;
use WORK.UTILITIES_PKG.ALL ;          --  Generally useful functions and
                                      --  constants.

use WORK.SDRAM_Information_pkg.all ;  --  Parameters related to SDRAM
                                      --  implementations.


----------------------------------------------------------------------------
--
--! @brief      SD RAM Memory Controller.
--! @details    The controller moves data from static RAM onto the dynamic
--!             RAM chip and from it back a different bank of static RAM
--!             when the dynamic RAM fills up.  Input and output memory is
--!             circularly buffered.
--!
--! @param      SYSCLK_FREQ       Frequency of the system clock in cycles
--!                               per second.
--! @param      OUTMEM_BUFFROWS   Number of SDRAM rows in an output memory
--!                               buffer.
--! @param      OUTMEM_BUFFCOUNT  Number of buffers of output memory
--!                               available.
--! @param      INMEM_BUFFOUTS    Number of output memory buffers per input
--!                               memory buffer.
--! @param      INMEM_BUFFCOUNT   Number of input memory buffers available.
--! @param      SDRAM_SPACE       Capacity parameters for the dynamic RAM
--!                               chip used.
--! @param      SDRAM_TIMES       Timing parameters for the dynamic RAM chip
--!                               used.
--! @param      reset             Reset the entity when high.
--! @param      sysclk            Main system clock which everything is
--!                               based off of.
--! @param      direct_copy       Direct copying from the input memory to
--!                               the output memory is to be carried out.
--! @param      direct_copy_amt   Number of words to copy directly.
--! @param      inmem_buffready   A buffer is ready to be copied to SDRAM.
--! @param      inmem_datafrom    Data read from the input memory.
--! @param      inmem_address     Address of the data to read.
--! @param      inmem_read_en     Enables a read at the given address.
--! @param      inmem_clock       Clock used to drive the input memory.
--! @param      outmem_buffready  A buffer is empty and ready to be written.
--! @param      outmem_datato     Data to write to the output memory.
--! @param      outmem_address    Address to write the data to.
--! @param      outmem_write_en   Enable a write to the given address.
--! @param      outmem_clock      Clock used to drive the output memory.
--! @param      outmem_amt        Total number of bytes to be written.
--! @param      outmem_writing    Currently writing bytes to the memory.
--! @param      sdram_data        Data read from or written to dynamic mem.
--! @param      sdram_mask        Data in/out mask.
--! @param      sdram_address     Address to access in the dynamic memory.
--!                               This will be the row address for the
--!                               ACTIVE command and the column address for
--!                               the READ and WRITE commands.
--! @param      sdram_bank        Bank being accessed by the operation.
--! @param      sdram_command     Command to execute.  The bits from high to
--!                               low are CS#, RAS#, CAS#, and WE#.
--! @param      sdram_clock_en    Enable clock use by the dynamic memory.
--! @param      sdram_clock       Clock used to drive the dynamic memory.
--! @param      sdram_empty       Set when the dynamic memory has nothing in
--!                               it.
--! @param      sdram_forceout    Send all contents of dynamic memory to
--!                               output memory.
--
----------------------------------------------------------------------------

entity SDRAM_Controller is

  Generic (
    SYSCLK_FREQ           : natural     := 10e6 ;

    OUTMEM_BUFFROWS       : natural     := 1 ;
    OUTMEM_BUFFCOUNT      : natural     := 2 ;
    INMEM_BUFFOUTS        : natural     := 1 ;
    INMEM_BUFFCOUNT       : natural     := 2 ;
    SDRAM_SPACE           : SDRAM_Capacity  := SDRAM_32_Capacity ;
    SDRAM_TIMES           : SDRAM_Timing    := SDRAM_75_3_Timing
  ) ;
  Port (
    reset                 : in    std_logic ;
    sysclk                : in    std_logic ;

    direct_copy           : in    std_logic ;
    direct_copy_amt       : in
        unsigned (const_bits (INMEM_BUFFOUTS * OUTMEM_BUFFROWS *
                              SDRAM_SPACE.ROWBITS /
                              SDRAM_SPACE.DATABITS) - 1 downto 0) ;

    inmem_buffready       : in    std_logic ;
    inmem_datafrom        : in    std_logic_vector (SDRAM_SPACE.DATABITS-1
                                                      downto 0) ;
    inmem_address         : out
        std_logic_vector (const_bits (INMEM_BUFFCOUNT * INMEM_BUFFOUTS *
                                      OUTMEM_BUFFROWS *
                                      SDRAM_SPACE.ROWBITS /
                                      SDRAM_SPACE.DATABITS - 1) - 1
                                        downto 0) ;
    inmem_read_en         : out   std_logic ;
    inmem_clock           : out   std_logic ;

    outmem_buffready      : in    std_logic ;
    outmem_datato         : out   std_logic_vector (SDRAM_SPACE.DATABITS-1
                                                      downto 0) ;
    outmem_address        : out
        std_logic_vector (const_bits (OUTMEM_BUFFCOUNT * OUTMEM_BUFFROWS *
                                      SDRAM_SPACE.ROWBITS /
                                      SDRAM_SPACE.DATABITS - 1) - 1
                                        downto 0) ;
    outmem_write_en       : out   std_logic ;
    outmem_clock          : out   std_logic ;
    outmem_amt            : out
        unsigned (const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                              SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;
    outmem_writing        : out   std_logic ;

    sdram_data            : inout std_logic_vector (SDRAM_SPACE.DATABITS-1
                                                      downto 0) ;
    sdram_mask            : out   std_logic_vector (SDRAM_SPACE.DATABITS/8-1
                                                      downto 0) ;
    sdram_address         : out   unsigned (SDRAM_SPACE.ADDRBITS-1
                                                      downto 0) ;
    sdram_bank            : out
        unsigned (const_bits (SDRAM_SPACE.BANKS)-1 downto 0) ;
    sdram_command         : out   std_logic_vector (SDRAM_SPACE.CMDBITS-1
                                                      downto 0) ;
    sdram_clock_en        : out   std_logic ;
    sdram_clock           : out   std_logic ;
    sdram_empty           : out   std_logic ;
    sdram_forceout        : in    std_logic
  ) ;

end entity SDRAM_Controller ;


architecture rtl of SDRAM_Controller is

  --  Circular list information.  The wrap bits are used to determine
  --  how many times the circular lists have wrapped around.  This is
  --  useful in determining when start and end pointers matching means
  --  the list is empty.

  signal inmem_start_buff   : unsigned (const_bits (INMEM_BUFFCOUNT)-1
                                          downto 0) ;
  signal inmem_end_buff     : unsigned (const_bits (INMEM_BUFFCOUNT)-1
                                          downto 0) ;
  signal inmem_start_wrap   : std_logic ;
  signal inmem_end_wrap     : std_logic ;

  signal outmem_start_buff  : unsigned (const_bits (OUTMEM_BUFFCOUNT)-1
                                          downto 0) ;
  signal outmem_end_buff    : unsigned (const_bits (OUTMEM_BUFFCOUNT)-1
                                          downto 0) ;
  signal outmem_start_wrap  : std_logic ;
  signal outmem_end_wrap    : std_logic ;

  signal in_address         : unsigned (inmem_address'length-1 downto 0) ;
  signal out_address        : unsigned (outmem_address'length-1 downto 0) ;

  --  Clock control information.

  signal sdram_clock_run      : std_logic ;
  signal sdram_clock_active   : std_logic ;
  signal sdram_clock_output   : std_logic ;

  signal inmem_clock_run      : std_logic ;
  signal inmem_clock_active   : std_logic ;
  signal inmem_clock_output   : std_logic ;

  signal outmem_clock_run     : std_logic ;
  signal outmem_clock_active  : std_logic ;
  signal outmem_clock_output  : std_logic ;

  --  Direct copy from input memory to output memory control signals.

  signal copying              : std_logic ;
  signal copy_to_outmem       : std_logic ;
  signal copy_end             :
            unsigned (direct_copy_amt'length-1 downto 0) ;
  signal copied_amt           :
            unsigned (direct_copy_amt'length-1 downto 0) ;

  --  SDRAM access information.  The memory is considered full when the number
  --  of empty words drops to a specified number of rows worth of words.

  constant SDRAM_ROWWORDS       : natural := SDRAM_SPACE.ROWBITS /
                                             SDRAM_SPACE.DATABITS ;
  constant SDRAM_WORDCNT        : natural := SDRAM_SPACE.ROWCOUNT *
                                             SDRAM_SPACE.BANKS *
                                             SDRAM_ROWWORDS ;
  constant SDRAM_WORDADDR_BITS  : natural :=
            const_bits (SDRAM_WORDCNT - 1) ;

  constant SDRAM_EMPTY_MIN      : natural := SDRAM_ROWWORDS * 64 ;
  constant SDRAM_FULL_MAX       : natural := SDRAM_WORDCNT -
                                             SDRAM_EMPTY_MIN ;

  signal sdram_read_addr        :
            unsigned (SDRAM_WORDADDR_BITS-1 downto 0) ;
  signal sdram_write_addr       :
            unsigned (SDRAM_WORDADDR_BITS-1 downto 0) ;
  signal sdram_empty_addr       :
            unsigned (SDRAM_WORDADDR_BITS-1 downto 0) ;

  signal sdram_read             : std_logic ;
  signal sdram_write            : std_logic ;
  signal sdram_emptying         : std_logic ;
  signal sdram_passive          : std_logic ;

  constant BANK_ADDR_BOTTOM     : natural := const_bits (SDRAM_ROWWORDS-1) ;
  constant BANK_ADDR_TOP        : natural :=
              BANK_ADDR_BOTTOM + const_bits (SDRAM_SPACE.BANKS-1) - 1 ;
  constant ROW_ADDR_BOTTOM      : natural := BANK_ADDR_TOP + 1 ;
  constant ROW_ADDR_TOP         : natural :=
              ROW_ADDR_BOTTOM + SDRAM_SPACE.ADDRBITS - 1 ;

  --  Memory Action States.

  type MEMState is  (
    MEMST_WAIT,
    MEMST_INIT_START,
    MEMST_INIT_STABLE,
    MEMST_INIT_STARTUP,
    MEMST_INIT_REFRESH,
    MEMST_INIT_MODE,
    MEMST_INIT_EX_MODE,
    MEMST_INIT_DONE,
    MEMST_COPY_START,
    MEMST_READ_START,
    MEMST_READ_STARTUP,
    MEMST_MOVETO_OUTMEM,
    MEMST_READ_END,
    MEMST_WRITE_START,
    MEMST_WRITE_STARTUP,
    MEMST_MOVEFROM_INMEM,
    MEMST_WRITE_END,
    MEMST_REFRESH_START,
    MEMST_REFRESH,
    MEMST_PASSIFY,
    MEMST_RESTART
  ) ;

  signal current_state            : MEMState ;

  --  Commands.  Command bits from high to low are: CS#, RAS#, CAS#, WE#.

  constant SDRAM_CMD_INHIBIT        :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "1000" ;
  constant SDRAM_CMD_NOP            :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0111" ;
  constant SDRAM_CMD_ACTIVE         :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0011" ;
  constant SDRAM_CMD_READ           :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0101" ;
  constant SDRAM_CMD_WRITE          :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0100" ;
  constant SDRAM_CMD_BURST_TERM     :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0110" ;
  constant SDRAM_CMD_DEEP_PDOWN     :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0110" ;
  constant SDRAM_CMD_PRECHARGE      :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0010" ;
  constant SDRAM_CMD_AUTO_REFRESH   :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0001" ;
  constant SDRAM_CMD_SELF_REFRESH   :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0001" ;
  constant SDRAM_CMD_LOAD_MODE      :
              std_logic_vector (SDRAM_SPACE.CMDBITS-1 downto 0) := "0000" ;

  constant SDRAM_ADDR_PRECHARGE_ALL :
              unsigned (SDRAM_SPACE.ADDRBITS-1 downto 0) :=
                TO_UNSIGNED (2 ** 10, SDRAM_SPACE.ADDRBITS) ;
  constant SDRAM_ADDR_PRECHARGE_ONE :
              unsigned (SDRAM_SPACE.ADDRBITS-1 downto 0) :=
                (others => '0') ;

  --  Mode register definitions.

  constant SDRAM_MODE_BANKSEL     :
              unsigned (SDRAM_SPACE.BANKS-1 downto 0) :=
                TO_UNSIGNED (0, SDRAM_SPACE.BANKS) ;

  constant SDRAM_MODE_WB_PROG     : std_logic_vector (0 downto 0) := "0" ;
  constant SDRAM_MODE_WB_SINGLE   : std_logic_vector (0 downto 0) := "1" ;

  constant SDRAM_MODE_OM_NORMAL   : std_logic_vector (1 downto 0) := "00" ;

  constant SDRAM_MODE_BT_SEQ      : std_logic_vector (0 downto 0) := "0" ;
  constant SDRAM_MODE_BT_IL       : std_logic_vector (0 downto 0) := "1" ;

  constant SDRAM_MODE_BLEN_1      : std_logic_vector (2 downto 0) := "000" ;
  constant SDRAM_MODE_BLEN_2      : std_logic_vector (2 downto 0) := "001" ;
  constant SDRAM_MODE_BLEN_4      : std_logic_vector (2 downto 0) := "010" ;
  constant SDRAM_MODE_BLEN_8      : std_logic_vector (2 downto 0) := "011" ;
  constant SDRAM_MODE_BLEN_C      : std_logic_vector (2 downto 0) := "111" ;

  constant SDRAM_MODE_PREFIX      :
              std_logic_vector (SDRAM_SPACE.ADDRBITS-10-1 downto 0) :=
                                    (others => '0') ;

  constant SDRAM_MODE_CL_2        : natural := 2 ;
  constant SDRAM_MODE_CL_3        : natural := 3 ;

  constant SDRAM_CASLAT_CHOICES   : integer_vector :=
  (
    0,
    0,
    SDRAM_MODE_CL_2,
    SDRAM_MODE_CL_3,
    0,
    0,
    0,
    0
  ) ;

  constant SDRAM_MODE_CL          : std_logic_vector (2 downto 0) :=
              STD_LOGIC_VECTOR (
                  TO_UNSIGNED (SDRAM_CASLAT_CHOICES (SDRAM_TIMES.CL), 3)) ;

  constant SDRAM_MODE_INIT        :
              std_logic_vector (SDRAM_SPACE.ADDRBITS-1 downto 0) :=
                  SDRAM_MODE_PREFIX         &
                  SDRAM_MODE_WB_PROG        &
                  SDRAM_MODE_OM_NORMAL      &
                  SDRAM_MODE_CL             &
                  SDRAM_MODE_BT_SEQ         &
                  SDRAM_MODE_BLEN_C         ;

  --  Extended Mode register definitions.

  constant SDRAM_EMR_BANKSEL      :
              unsigned (SDRAM_SPACE.BANKS-1 downto 0) :=
                TO_UNSIGNED (2, SDRAM_SPACE.BANKS) ;

  constant SDRAM_EMR_DSTR_FULL    : std_logic_vector (2 downto 0) := "000" ;
  constant SDRAM_EMR_DSTR_HALF    : std_logic_vector (2 downto 0) := "001" ;
  constant SDRAM_EMR_DSTR_1QTR    : std_logic_vector (2 downto 0) := "010" ;
  constant SDRAM_EMR_DISR_3QTR    : std_logic_vector (2 downto 0) := "011" ;

  constant SDRAM_EMR_TCSR         : std_logic_vector (1 downto 0) := "00" ;

  constant SDRAM_EMR_SR_FULL      : std_logic_vector (2 downto 0) := "000" ;
  constant SDRAM_EMR_SR_HALF      : std_logic_vector (2 downto 0) := "001" ;
  constant SDRAM_EMR_SR_QUARTER   : std_logic_vector (2 downto 0) := "010" ;
  constant SDRAM_EMR_SR_EIGHTH    : std_logic_vector (2 downto 0) := "101" ;
  constant SDRAM_EMR_SR_SIXTNTH   : std_logic_vector (2 downto 0) := "110" ;

  constant SDRAM_EMR_PREFIX       :
              std_logic_vector (SDRAM_SPACE.ADDRBITS-8-1 downto 0) :=
                                  (others => '0') ;

  constant SDRAM_EMR_INIT         :
              std_logic_vector (SDRAM_SPACE.ADDRBITS-1 downto 0) :=
                  SDRAM_EMR_PREFIX          &
                  SDRAM_EMR_DSTR_1QTR       &
                  SDRAM_EMR_TCSR            &
                  SDRAM_EMR_SR_FULL         ;

  --  Timing control.

  constant MICRO_SEC_CYCLES       : natural :=
              natural (real (SYSCLK_FREQ) / 1.0e6) ;

  constant REFRESH_CLK_CYCLES     : natural :=
              natural (trunc (real (SYSCLK_FREQ) * SDRAM_TIMES.T_REF /
                              real (SDRAM_SPACE.ROWCOUNT))) ;

  signal refresh_clkcnt           :
            unsigned (const_bits (REFRESH_CLK_CYCLES-1)-1 downto 0) ;

  signal refreshes_needed         :
            unsigned (const_bits (SDRAM_SPACE.ROWCOUNT-1)-1 downto 0) ;
  signal refreshes_done           :
            unsigned (const_bits (SDRAM_SPACE.ROWCOUNT-1)-1 downto 0) ;

  --  Number of rows to process.

  constant SDRAM_INMEM_ROWS       : natural := INMEM_BUFFOUTS *
                                               OUTMEM_BUFFROWS ;
  constant SDRAM_OUTMEM_ROWS      : natural := OUTMEM_BUFFROWS ;


  constant ROW_COUNT_TABLE        : integer_vector :=
  (
    SDRAM_INMEM_ROWS,
    SDRAM_OUTMEM_ROWS
  ) ;

  constant ROW_COUNT_MAX          : natural :=
            max_integer (ROW_COUNT_TABLE) ;

  signal row_count                :
            unsigned (const_bits (ROW_COUNT_MAX)-1 downto 0) ;

 --  Long delay counts.

  constant INIT_CLOCK_STABLE_TIME : natural := 10 * MICRO_SEC_CYCLES ;
  constant INIT_STARTUP_TIME      : natural := 100 * MICRO_SEC_CYCLES ;
  constant INIT_REFRESH_COUNT     : natural := 2 * SDRAM_SPACE.ROWCOUNT ;

  constant LONG_DELAY_TABLE       : integer_vector :=
  (
    INIT_CLOCK_STABLE_TIME,
    INIT_STARTUP_TIME,
    INIT_REFRESH_COUNT
  ) ;

  constant LONG_DELAY_MAX         : natural :=
            max_integer (LONG_DELAY_TABLE) ;

  signal long_cnt                 :
            unsigned (const_bits (LONG_DELAY_MAX)-1 downto 0) ;

  --  Short delay counts.

  constant CLOCK_LATENCY_DELAY    : natural := SDRAM_TIMES.CL + 1 ;

  constant PRECHARGE_DELAY        : natural :=
              natural (trunc (SDRAM_TIMES.T_RP * real (SYSCLK_FREQ))) + 1 ;

  constant ACTIVE_DELAY           : natural :=
              natural (trunc (SDRAM_TIMES.T_RCD * real (SYSCLK_FREQ))) + 1 ;

  constant WRITE_DONE_DELAY       : natural :=
              natural (trunc (SDRAM_TIMES.T_WR * real (SYSCLK_FREQ))) + 1 ;

  constant AUTO_REFRESH_DELAY     : natural :=
              natural (trunc (SDRAM_TIMES.T_RFC * real (SYSCLK_FREQ))) + 3 ;
              -- Two extra cycles added to reduce current drain.

  constant LOAD_MODE_DELAY        : natural :=
              natural (trunc (real (SDRAM_TIMES.T_MRD) *
                              real (SYSCLK_FREQ))) + 1 ;

  constant SELF_REFRESH_DELAY     : natural :=
              natural (trunc (SDRAM_TIMES.T_RAS_L *
                              real (SYSCLK_FREQ))) + 1 ;

  constant CLOCK_RESTART_DELAY    : natural := 8 ;

  constant RESTART_DELAY          : natural :=
              natural (trunc (SDRAM_TIMES.T_XSR * real (SYSCLK_FREQ))) + 2 ;

  constant SHORT_DELAY_TABLE      : integer_vector :=
  (
    CLOCK_LATENCY_DELAY,
    PRECHARGE_DELAY,
    ACTIVE_DELAY,
    WRITE_DONE_DELAY,
    AUTO_REFRESH_DELAY,
    LOAD_MODE_DELAY,
    SELF_REFRESH_DELAY,
    CLOCK_RESTART_DELAY,
    RESTART_DELAY
  ) ;

  constant SHORT_DELAY_MAX        : natural :=
            max_integer (SHORT_DELAY_TABLE) ;

  signal delay_cnt                :
            unsigned (const_bits (SHORT_DELAY_MAX)-1 downto 0) ;

begin

  --  Output signals linked to local signals.

  inmem_address                   <= STD_LOGIC_VECTOR (in_address) ;
  outmem_address                  <= STD_LOGIC_VECTOR (out_address) ;

  --  SDRAM clock control.

  sdram_clock_output              <= not sysclk ;
  sdram_clock                     <= sdram_clock_output and
                                     sdram_clock_active ;

  sdram_clock_gate : process (reset, sdram_clock_output)
  begin
    if (reset = '1') then
      sdram_clock_active          <= '0' ;

    elsif (sdram_clock_output'event and sdram_clock_output = '0') then
      sdram_clock_active          <= sdram_clock_run ;
    end if ;
  end process sdram_clock_gate ;

  --  Input memory clock control.

  inmem_clock_output              <= not sysclk ;
  inmem_clock                     <= inmem_clock_output and
                                     inmem_clock_active ;

  inmem_clock_gate : process (reset, inmem_clock_output)
  begin
    if (reset = '1') then
      inmem_clock_active          <= '0' ;

    elsif (inmem_clock_output'event and inmem_clock_output = '0') then
      inmem_clock_active          <= inmem_clock_run ;
    end if ;
  end process inmem_clock_gate ;

  --  Output memory clock control.

  outmem_clock_output             <= not sysclk ;
  outmem_clock                    <= outmem_clock_output and
                                     outmem_clock_active ;

  outmem_clock_gate : process (reset, outmem_clock_output)
  begin
    if (reset = '1') then
      outmem_clock_active         <= '0' ;

    elsif (outmem_clock_output'event and outmem_clock_output = '0') then
      outmem_clock_active         <= outmem_clock_run ;
    end if ;
  end process outmem_clock_gate ;


  --------------------------------------------------------------------------
  --
  --! @brief      Determine how many auto refreshes need to have been done.
  --! @details    The number of refreshes needed continues to grow (wrapping
  --!             around) while the SDRAM is not in self-refresh mode.
  --!
  --! @param      reset               Reset the refresh needed counter.
  --! @param      sysclk              System clock.
  --
  --------------------------------------------------------------------------

  refresh_counter : process (reset, sysclk)
  begin
    if (reset = '1') then
      refreshes_needed            <= (others => '0') ;
      refresh_clkcnt              <= (others => '0') ;

    elsif (sysclk'event and sysclk = '1') then

      if (refresh_clkcnt /= REFRESH_CLK_CYCLES - 1) then
        refresh_clkcnt            <= refresh_clkcnt + 1 ;

      else
        refresh_clkcnt            <= (others => '0') ;

        if (sdram_emptying = '1' or refreshes_done /= refreshes_needed) then
          refreshes_needed        <= refreshes_needed + 1 ;
        end if ;
      end if ;
    end if ;
  end process refresh_counter ;


  --------------------------------------------------------------------------
  --
  --! @brief      Determine when new buffers are available.
  --! @details    Buffers are signalled as available with the buffer ready
  --!             signal.
  --!
  --! @param      reset         Reset emptying status.
  --! @param      buffready     In or out buffer ready signal.
  --
  --------------------------------------------------------------------------

  inmem_buff_check : process (reset, inmem_buffready)
  begin
    if (reset = '1') then
      inmem_end_buff              <= (others => '0') ;
      inmem_end_wrap              <= '0' ;

    elsif (inmem_buffready'event and inmem_buffready = '1') then
      if (inmem_end_buff /= INMEM_BUFFCOUNT - 1) then
        inmem_end_buff            <= inmem_end_buff + 1 ;
      else
        inmem_end_buff            <= (others => '0') ;
        inmem_end_wrap            <= not inmem_end_wrap ;
      end if ;
    end if ;
  end process inmem_buff_check ;

  outmem_buff_check : process (reset, outmem_buffready)
  begin
    if (reset = '1') then
      outmem_end_buff             <= (others => '0') ;
      outmem_end_wrap             <= '0' ;

    elsif (outmem_buffready'event and outmem_buffready = '1') then
      if (outmem_end_buff /= INMEM_BUFFCOUNT - 1) then
        outmem_end_buff           <= outmem_end_buff + 1 ;
      else
        outmem_end_buff            <= (others => '0') ;
        outmem_end_wrap            <= not outmem_end_wrap ;
      end if ;
    end if ;
  end process outmem_buff_check ;


  --------------------------------------------------------------------------
  --
  --! @brief      Determine when it is time to read memory.
  --! @details    When the SDRAM is almost full or a force output is
  --!             specified start emptying it.
  --!             When empting is in progress and a buffer is available,
  --!             start a read.
  --!
  --! @param      reset         Reset emptying status.
  --! @param      sysclk        Clock driving check times.
  --
  --------------------------------------------------------------------------

  mem_read_check : process (reset, sysclk)
  begin
    if (reset = '1') then
      sdram_emptying              <= '0' ;
      sdram_empty_addr            <= (others => '0') ;

    elsif (sysclk'event and sysclk = '1') then

      --  Start emptying the SDRAM when conditions are met.

      if (sdram_emptying = '0') then

        --  Start emptying when forced output is specified and the memory
        --  is not already empty.

        if (sdram_forceout = '1' and
            sdram_read_addr /= sdram_write_addr) then

          sdram_emptying          <= '1' ;
          sdram_empty_addr        <= sdram_write_addr ;

          if (sdram_write_addr > sdram_read_addr) then
            outmem_amt            <= sdram_write_addr - sdram_read_addr ;

          else
            outmem_amt            <= const_unsigned (SDRAM_WORDCNT) -
                                     (sdram_read_addr - sdram_write_addr) ;
          end if ;

        --  Start emptying when the memory is almost full.

        elsif (((sdram_write_addr > sdram_read_addr) and
                (sdram_write_addr - sdram_read_addr = SDRAM_FULL_MAX)) or
               (sdram_read_addr - sdram_write_addr  = SDRAM_EMPTY_MIN)) then

          sdram_emptying          <= '1' ;
          sdram_empty_addr        <= sdram_write_addr ;
          outmem_amt              <= TO_UNSIGNED (SDRAM_FULL_MAX,
                                                  outmem_amt'length) ;
        end if ;

      --  Stop emptying when the memory has reached its target empty point.
      --  (It may not be empty as more data may have been written to it
      --  after the empty operation had started.)

      elsif (sdram_read_addr = sdram_empty_addr) then

        sdram_emptying            <= '0' ;

      end if ;

      --  Memory is empty when the read pointer has caught up with the write
      --  pointer.

      if (sdram_read_addr = sdram_write_addr) then
        sdram_empty               <= '1' ;
      else
        sdram_empty               <= '0' ;
      end if ;

    end if ;
  end process mem_read_check ;

  --  Start a read when memory is being emptied and an output buffer is
  --  available to put the data in.

  sdram_read  <= '1' when ((sdram_emptying = '1') and
                           (outmem_start_buff /= outmem_end_buff or
                            outmem_start_wrap /= outmem_end_wrap))
                     else '0' ;

  --  Start a write when an input buffer is available to take data from.

  sdram_write <= '1' when ((inmem_start_buff /= inmem_end_buff or
                            inmem_start_wrap /= inmem_end_wrap))
                     else '0' ;


  --------------------------------------------------------------------------
  --
  --! @brief      Determine when it is time copy memory.
  --! @details    When direct copying is specified and there is more data to
  --!             copy set the copying flag, the new coping end count, and
  --!             the amount that will be copied this pass.
  --!
  --! @param      reset         Reset emptying status.
  --! @param      sysclk        Clock driving check times.
  --
  --------------------------------------------------------------------------

  mem_copy_check : process (reset, sysclk)
  begin
    if (reset = '1') then
      copying                     <= '0' ;
      copy_end                    <= (others => '0') ;

    elsif (sysclk'event and sysclk = '1') then
      if (direct_copy = '1') then
        if (direct_copy_amt /= copied_amt) then
          copying                 <= '1' ;
          copy_end                <= direct_copy_amt ;

          outmem_amt              <= direct_copy_amt - copied_amt ;

        elsif (copied_amt = copy_end) then
          copying                 <= '0' ;
        end if ;
      end if ;
    end if ;
  end process mem_copy_check ;

  --  Copy data when a place to put is available.

  copy_to_outmem <= '1' when (copying = '1' and
                              (outmem_start_buff /= outmem_end_buff or
                               outmem_start_wrap /= outmem_end_wrap))
                        else '0' ;


  --------------------------------------------------------------------------
  --
  --! @brief      Progress through states to achieve a goal.
  --! @details    Several state paths are implemented here.
  --!
  --! @param      reset         Reset the state machine.
  --! @param      sysclk        Clock driving state changes.
  --
  --------------------------------------------------------------------------

  mem_acc : process (reset, sysclk)
  begin
    if (reset = '1') then
      current_state         <= MEMST_INIT_START ;
      delay_cnt             <= (others => '0') ;
      long_cnt              <= (others => '0') ;
      row_count             <= (others => '0') ;
      refreshes_done        <= (others => '0') ;

      copied_amt            <= (others => '0') ;

      inmem_start_buff      <= (others => '0') ;
      inmem_start_wrap      <= '0' ;
      outmem_start_buff     <= (others => '0') ;
      outmem_start_wrap     <= '0' ;
      inmem_clock_run       <= '0' ;
      outmem_clock_run      <= '0' ;
      outmem_writing        <= '0' ;

      sdram_passive         <= '1' ;
      sdram_clock_run       <= '0' ;
      sdram_read_addr       <= (others => '0') ;
      sdram_write_addr      <= (others => '0') ;

      sdram_clock_en        <= '0' ;
      sdram_command         <= (others => '0') ;
      sdram_bank            <= (others => '0') ;
      sdram_address         <= (others => '0') ;
      sdram_data            <= (others => '0') ;
      sdram_mask            <= (others => '1') ;

    elsif (sysclk'event and sysclk = '1') then

      --  Clear the amount copied when direct copying is done.

      if (direct_copy = '0') then
        copied_amt          <= (others => '0') ;
      end if ;

      --  Clear the writing flag when we are done emptying the SDRAM.

      if (sdram_emptying = '0') then
        outmem_writing      <= '0' ;
      end if ;

      --  Handle any delays before going to the next state.

      if (delay_cnt /= 0) then
        delay_cnt           <= delay_cnt - 1 ;
        sdram_command       <= SDRAM_CMD_NOP ;

      else
        --  Memory Access State Machine.

        case current_state is

          --  Check for time to start a new state sequence.  The first
          --  entries are higher priority than later ones.  The clock must
          --  be reactivated before other commands can be started.

          when MEMST_WAIT           =>
            if ((copy_to_outmem  = '1' or
                 sdram_read      = '1' or
                 sdram_write     = '1' or
                 refreshes_done /= refreshes_needed) and
                sdram_clock_run = '0') then

              sdram_passive     <= '0' ;
              sdram_clock_run   <= '1' ;
              delay_cnt         <= TO_UNSIGNED (CLOCK_RESTART_DELAY,
                                                delay_cnt'length) ;
              current_state     <= MEMST_RESTART ;

            --  Copy data from the input memory to the output memory.

            elsif (copy_to_outmem = '1') then
              inmem_clock_run   <= '1' ;
              in_address        <= inmem_start_buff *
                                   const_unsigned (SDRAM_ROWWORDS) +
                                   copied_amt ;

              outmem_clock_run  <= '1' ;
              out_address       <= TO_UNSIGNED (OUTMEM_BUFFROWS *
                                                SDRAM_ROWWORDS,
                                                out_address'length) *
                                   outmem_start_buff - 1 +
                                   copied_amt ;

              current_state     <= MEMST_COPY_START ;

            --  Read a buffer from SDRAM and write it to output memory.

            elsif (sdram_read = '1') then
              outmem_clock_run  <= '1' ;
              out_address       <= TO_UNSIGNED (OUTMEM_BUFFROWS *
                                                SDRAM_ROWWORDS,
                                                out_address'length) *
                                   outmem_start_buff - 1 ;
              row_count         <= TO_UNSIGNED (OUTMEM_BUFFROWS - 1,
                                                row_count'length) ;
              current_state     <= MEMST_READ_START ;

            --  Write a buffer from input memory to the SDRAM.

            elsif (sdram_write = '1') then
              inmem_clock_run   <= '1' ;
              in_address        <= inmem_start_buff *
                                   const_unsigned (SDRAM_ROWWORDS) ;
              row_count         <= TO_UNSIGNED (INMEM_BUFFOUTS *
                                                OUTMEM_BUFFROWS - 1,
                                                row_count'length) ;
              current_state     <= MEMST_WRITE_START ;

            --  Execute an auto-refresh if refreshes need to be done.

            elsif (refreshes_done /= refreshes_needed) then
              current_state     <= MEMST_REFRESH ;

            --  Put the SDRAM into a passive mode.

            elsif (sdram_emptying = '0' and sdram_passive = '0') then
              current_state     <= MEMST_PASSIFY ;

            else
              sdram_clock_run   <= '0' ;
              current_state     <= MEMST_WAIT ;
            end if ;

          --  Initialize the dynamic memory.
          --  Start the clock and wait for stability.

          when MEMST_INIT_START     =>
            sdram_clock_en      <= '1' ;
            sdram_clock_run     <= '1' ;
            long_cnt            <= const_unsigned (INIT_CLOCK_STABLE_TIME) ;
            current_state       <= MEMST_INIT_STABLE ;

          --  Give the dynamic memory time to initialize itself.

          when MEMST_INIT_STABLE    =>
            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1 ;
            else
              sdram_command     <= SDRAM_CMD_INHIBIT ;
              long_cnt          <= const_unsigned (INIT_STARTUP_TIME) ;
              current_state     <= MEMST_INIT_STARTUP ;
            end if ;

          --  Precharge all banks of memory after startup time has passed.

          when MEMST_INIT_STARTUP   =>
            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1;
            else
              sdram_command     <= SDRAM_CMD_PRECHARGE ;
              sdram_address     <= SDRAM_ADDR_PRECHARGE_ALL ;
              delay_cnt         <= const_unsigned (PRECHARGE_DELAY) ;
              long_cnt          <= const_unsigned (INIT_REFRESH_COUNT - 1) ;
              current_state     <= MEMST_INIT_REFRESH ;
            end if ;

          --  Refresh all rows of memory twice.

          when MEMST_INIT_REFRESH   =>
            sdram_command       <= SDRAM_CMD_AUTO_REFRESH ;
            delay_cnt           <= const_unsigned (AUTO_REFRESH_DELAY) ;

            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1 ;
            else
              current_state     <= MEMST_INIT_MODE ;
            end if ;

          --  Initialize the mode register.

          when MEMST_INIT_MODE      =>
            sdram_command       <= SDRAM_CMD_LOAD_MODE ;
            sdram_bank          <= SDRAM_MODE_BANKSEL ;
            sdram_address       <= unsigned (SDRAM_MODE_INIT) ;

            delay_cnt           <= const_unsigned (LOAD_MODE_DELAY) ;
            current_state       <= MEMST_INIT_EX_MODE ;

          --  Initialize the extended mode register.

          when MEMST_INIT_EX_MODE   =>
            sdram_command       <= SDRAM_CMD_LOAD_MODE ;
            sdram_bank          <= SDRAM_EMR_BANKSEL ;
            sdram_address       <= unsigned (SDRAM_EMR_INIT) ;

            delay_cnt           <= const_unsigned (LOAD_MODE_DELAY) ;
            current_state       <= MEMST_INIT_DONE ;

          --  Put the memory into self-refresh mode and wait until some
          --  type of memory access needs to be done.

          when MEMST_INIT_DONE      =>
            sdram_command       <= SDRAM_CMD_SELF_REFRESH ;
            sdram_clock_en      <= '0' ;
            delay_cnt           <= const_unsigned (SELF_REFRESH_DELAY) ;
            current_state       <= MEMST_WAIT ;

          --  Start a row read operation moving data to output memory.
          --  The initial output address will be one less than the first
          --  address used so that the increment to next address can be
          --  used at every word output.

          when MEMST_READ_START     =>
            sdram_command       <= SDRAM_CMD_ACTIVE ;
            sdram_bank          <= sdram_read_addr (BANK_ADDR_TOP downto
                                                    BANK_ADDR_BOTTOM) ;
            sdram_address       <= sdram_read_addr (ROW_ADDR_TOP downto
                                                    ROW_ADDR_BOTTOM) ;
            sdram_read_addr     <= sdram_read_addr + SDRAM_ROWWORDS ;
            delay_cnt           <= const_unsigned (ACTIVE_DELAY) ;
            current_state       <= MEMST_READ_STARTUP ;

          --  Read all the words in a row and write them to the output.
          --  Close the row after finishing it.

          when MEMST_READ_STARTUP   =>
            sdram_command       <= SDRAM_CMD_READ ;
            sdram_address       <= (others => '0') ;
            sdram_data          <= (others => 'Z') ;
            sdram_mask          <= (others => '0') ;
            delay_cnt           <= const_unsigned (CLOCK_LATENCY_DELAY) ;
            long_cnt            <= const_unsigned (SDRAM_ROWWORDS - 1) ;
            current_state       <= MEMST_MOVETO_OUTMEM ;

          when MEMST_MOVETO_OUTMEM  =>
            outmem_datato       <= sdram_data ;
            outmem_write_en     <= '1' ;
            out_address         <= out_address + 1 ;

            if (long_cnt /= 0) then
              sdram_command     <= SDRAM_CMD_NOP ;
              long_cnt          <= long_cnt - 1 ;
            else
              sdram_command     <= SDRAM_CMD_PRECHARGE ;
              sdram_address     <= SDRAM_ADDR_PRECHARGE_ONE ;
              sdram_mask        <= (others => '1') ;
              current_state     <= MEMST_READ_END ;
            end if ;

          --  Drive the output lines again.  Stop writing to output memory.
          --  If the buffer has been filled set the last buffer filled
          --  indicator and say that output memory data is available.

          when MEMST_READ_END       =>
            sdram_data            <= (others => '0') ;
            outmem_write_en       <= '0' ;

            if (row_count /= 0) then
              row_count           <= row_count - 1 ;
              current_state       <= MEMST_READ_START ;
            else
              if (outmem_start_buff = OUTMEM_BUFFCOUNT - 1) then
                outmem_start_buff <= (others => '0') ;
                outmem_start_wrap <= not outmem_start_wrap ;
              else
                outmem_start_buff <= outmem_start_buff + 1 ;
              end if ;

              outmem_writing      <= '1' ;
              outmem_clock_run    <= '0' ;
              delay_cnt           <= const_unsigned (PRECHARGE_DELAY) ;
              current_state       <= MEMST_WAIT ;
            end if ;

          --  Start a row write operation moving data from input memory.

          when MEMST_WRITE_START    =>
            sdram_command       <= SDRAM_CMD_ACTIVE ;
            sdram_mask          <= (others => '0') ;
            sdram_bank          <= sdram_write_addr (BANK_ADDR_TOP downto
                                                     BANK_ADDR_BOTTOM) ;
            sdram_address       <= sdram_write_addr (ROW_ADDR_TOP downto
                                                     ROW_ADDR_BOTTOM) ;
            sdram_write_addr    <= sdram_write_addr + SDRAM_ROWWORDS ;
            inmem_read_en       <= '1' ;
            delay_cnt           <= const_unsigned (ACTIVE_DELAY) ;
            current_state       <= MEMST_WRITE_STARTUP ;

          --  Write all the words in a row and read them from the input.

          when MEMST_WRITE_STARTUP  =>
            sdram_command       <= SDRAM_CMD_WRITE ;
            sdram_address       <= (others => '0') ;
            sdram_data          <= inmem_datafrom ;
            in_address          <= in_address + 1 ;
            long_cnt            <= const_unsigned (SDRAM_ROWWORDS - 1) ;
            current_state       <= MEMST_MOVEFROM_INMEM ;

          when MEMST_MOVEFROM_INMEM =>
            sdram_command       <= SDRAM_CMD_NOP ;

            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1 ;
              sdram_data        <= inmem_datafrom ;
              in_address        <= in_address + 1 ;
            else
              sdram_mask        <= (others => '1') ;
              inmem_read_en     <= '0' ;
              delay_cnt         <= const_unsigned (WRITE_DONE_DELAY) ;
              current_state     <= MEMST_WRITE_END ;
           end if ;

          --  Close the row and mark the buffer as full if no more rows
          --  to be read.

          when MEMST_WRITE_END      =>

            sdram_command         <= SDRAM_CMD_PRECHARGE ;
            sdram_address         <= SDRAM_ADDR_PRECHARGE_ONE ;

            if (row_count /= 0) then
              row_count           <= row_count - 1 ;
              current_state       <= MEMST_WRITE_START ;
            else
              if (inmem_start_buff = INMEM_BUFFCOUNT - 1) then
                inmem_start_buff  <= (others => '0') ;
                inmem_start_wrap  <= not inmem_start_wrap ;
              else
                inmem_start_buff  <= inmem_start_buff + 1 ;
              end if ;

              delay_cnt           <= const_unsigned (PRECHARGE_DELAY) ;
              inmem_clock_run     <= '0' ;
              current_state       <= MEMST_WAIT ;
            end if ;

          --  Refresh one row.

          when MEMST_REFRESH        =>
            sdram_command       <= SDRAM_CMD_AUTO_REFRESH ;
            delay_cnt           <= const_unsigned (AUTO_REFRESH_DELAY) ;
            refreshes_done      <= refreshes_done + 1 ;
            current_state       <= MEMST_WAIT ;

          --  Put the memory into self-refresh mode.

          when MEMST_PASSIFY        =>
            sdram_passive       <= '1' ;
            sdram_command       <= SDRAM_CMD_SELF_REFRESH ;
            sdram_clock_en      <= '0' ;
            delay_cnt           <= const_unsigned (SELF_REFRESH_DELAY) ;
            current_state       <= MEMST_WAIT ;

          --  Restart the memory use from a passive state.

          when MEMST_RESTART        =>
              sdram_clock_en    <= '1' ;
              delay_cnt         <= const_unsigned (RESTART_DELAY) ;
              current_state     <= MEMST_WAIT ;

        end case ;
      end if ;
    end if ;
  end process mem_acc ;

end rtl ;
