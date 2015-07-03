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
--! @param      sysclk_freq_g       Frequency of the system clock in cycles
--!                                 per second.
--! @param      outmem_buffrows_g   Number of SDRAM rows in an output memory
--!                                 buffer.
--! @param      outmem_buffcount_g  Number of buffers of output memory
--!                                 available.
--! @param      inmem_buffouts_g    Number of output memory buffers per
--!                                 input memory buffer.
--! @param      inmem_buffcount_g   Number of input memory buffers
--!                                 available.
--! @param      sdram_space_g       Capacity parameters for the dynamic RAM
--!                                 chip used.
--! @param      sdram_times_g       Timing parameters for the dynamic RAM
--!                                 chip used.
--! @param      reset               Reset the entity when high.
--! @param      sysclk              Main system clock which everything is
--!                                 based off of.
--! @param      ready_out           The module is ready to operate.  No
--!                                 input or output should be tried until
--!                                 this flag is set.
--! @param      inmem_buffready_in  A buffer is ready to be copied to SDRAM.
--! @param      inmem_datafrom_in   Data read from the input memory.
--! @param      inmem_address_out   Address of the data to read.
--! @param      inmem_read_en_out   Enables a read at the given address.
--! @param      inmem_clk_out       Clock used to drive the input memory.
--! @param      outmem_buffready_in A buffer is empty and ready to be
--!                                 written.
--! @param      outmem_datato_out   Data to write to the output memory.
--! @param      outmem_address_out  Address to write the data to.
--! @param      outmem_write_en_out Enable a write to the given address.
--! @param      outmem_clk_out      Clock used to drive the output memory.
--! @param      outmem_amt_out      Total number of bytes to be written.
--! @param      outmem_writing_out  Currently writing bytes to the memory.
--! @param      sdram_data_in       Data read from dynamic memory.
--! @param      sdram_data_out      Data written to dynamic memory.
--! @param      sdram_data_dir      Data read when 0 (high Z),
--!                                 written when 1.
--! @param      sdram_mask_out      Data in/out mask.
--! @param      sdram_address_out   Address to access in the dynamic memory.
--!                                 This will be the row address for the
--!                                 ACTIVE command and the column address
--!                                 for the READ and WRITE commands.
--! @param      sdram_bank_out      Bank being accessed by the operation.
--! @param      sdram_command_out   Command to execute.  The bits from high
--!                                 to low are CS#, RAS#, CAS#, and WE#.
--! @param      sdram_clk_en_out    Enable clock use by the dynamic memory.
--! @param      sdram_clk_out       Clock used to drive the dynamic memory.
--! @param      sdram_empty_out     Set when the dynamic memory has nothing
--!                                 in it.
--! @param      sdram_forceout_in   Send all contents of dynamic memory to
--!                                 output memory.
--
----------------------------------------------------------------------------

entity SDRAM_Controller is

  Generic (
    sysclk_freq_g         : natural     := 10e6 ;

    outmem_buffrows_g     : natural     := 1 ;
    outmem_buffcount_g    : natural     := 2 ;
    inmem_buffouts_g      : natural     := 1 ;
    inmem_buffcount_g     : natural     := 2 ;
    sdram_space_g         : SDRAM_Capacity_t  := SDRAM_32_Capacity_c ;
    sdram_times_g         : SDRAM_Timing_t    := SDRAM_75_3_Timing_c
  ) ;
  Port (
    reset                 : in    std_logic ;
    sysclk                : in    std_logic ;

    ready_out             : out   std_logic ;

    inmem_buffready_in    : in    std_logic ;
    inmem_datafrom_in     : in    std_logic_vector (sdram_space_g.DATABITS-1
                                                    downto 0) ;
    inmem_address_out     : out
        std_logic_vector (const_bits (inmem_buffcount_g * inmem_buffouts_g *
                                      outmem_buffrows_g *
                                      sdram_space_g.ROWBITS /
                                      sdram_space_g.DATABITS - 1) - 1
                                        downto 0) ;
    inmem_read_en_out     : out   std_logic ;
    inmem_clk_out         : out   std_logic ;

    outmem_buffready_in   : in    std_logic ;
    outmem_datato_out     : out   std_logic_vector (sdram_space_g.DATABITS-1
                                                    downto 0) ;
    outmem_address_out    : out
        std_logic_vector (const_bits (outmem_buffcount_g *
                                      outmem_buffrows_g *
                                      sdram_space_g.ROWBITS /
                                      sdram_space_g.DATABITS - 1) - 1
                                        downto 0) ;
    outmem_write_en_out   : out   std_logic ;
    outmem_clk_out        : out   std_logic ;
    outmem_amt_out        : out
        unsigned (const_bits (sdram_space_g.BANKS * sdram_space_g.ROWCOUNT *
                              sdram_space_g.ROWBITS / 8 - 1) - 1 downto 0) ;
    outmem_writing_out    : out   std_logic ;

    sdram_data_in         : in    std_logic_vector (sdram_space_g.DATABITS-1
                                                      downto 0) ;
    sdram_data_out        : out   std_logic_vector (sdram_space_g.DATABITS-1
                                                      downto 0) ;
    sdram_data_dir        : out   std_logic ;

    sdram_mask_out        : out
        std_logic_vector (sdram_space_g.DATABITS / 8 - 1 downto 0) ;
    sdram_address_out     : out   unsigned (sdram_space_g.ADDRBITS-1
                                                      downto 0) ;
    sdram_bank_out        : out
        unsigned (const_bits (sdram_space_g.BANKS - 1)-1 downto 0) ;
    sdram_command_out     : out   std_logic_vector (sdram_space_g.CMDBITS-1
                                                      downto 0) ;
    sdram_clk_en_out      : out   std_logic ;
    sdram_clk_out         : out   std_logic ;
    sdram_empty_out       : out   std_logic ;
    sdram_forceout_in     : in    std_logic
  ) ;

end entity SDRAM_Controller ;


architecture rtl of SDRAM_Controller is

  --  Input/Output signal derived constants.

  constant word_shift_c         : natural :=
              const_bits (sdram_space_g.DATABITS / 8) - 1 ;
  constant row_shift_c          : natural :=
              const_bits (sdram_space_g.ROWBITS / 8) - 1 ;

  constant outmem_buffbytes_c   : natural := outmem_buffrows_g *
                                             sdram_space_g.ROWBITS / 8 ;
  constant outmem_buffwords_c   : natural :=
              outmem_buffbytes_c / (2 ** word_shift_c) ;
  constant outmem_buffbits_c    : natural :=
              const_bits (outmem_buffbytes_c - 1) ;

  constant inmem_buffbytes_c    : natural := inmem_buffouts_g *
                                             outmem_buffbytes_c ;
  constant inmem_buffwords_c    : natural := inmem_buffouts_g *
                                             outmem_buffwords_c ;

  --  Circular list information.  The wrap bits are used to determine
  --  how many times the circular lists have wrapped around.  This is
  --  useful in determining when start and end pointers matching means
  --  the list is empty.

  signal inmem_start_buff   : unsigned (const_bits (inmem_buffcount_g)-1
                                          downto 0) ;
  signal inmem_end_buff     : unsigned (const_bits (inmem_buffcount_g)-1
                                          downto 0) ;
  signal inmem_start_wrap   : std_logic ;
  signal inmem_end_wrap     : std_logic ;

  signal outmem_start_buff  : unsigned (const_bits (outmem_buffcount_g)-1
                                          downto 0) ;
  signal outmem_end_buff    : unsigned (const_bits (outmem_buffcount_g)-1
                                          downto 0) ;
  signal outmem_start_wrap  : std_logic ;
  signal outmem_end_wrap    : std_logic ;

  signal in_address         : unsigned (inmem_address_out'length-1
                                          downto 0) ;
  signal out_address        : unsigned (outmem_address_out'length-1
                                          downto 0) ;

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

  --  SDRAM access information.  The memory is considered full when the
  --  number of empty words drops to a specified number of rows worth of
  --  words.

  constant sdram_rowwords_c       : natural := sdram_space_g.ROWBITS /
                                               sdram_space_g.DATABITS ;
  constant sdram_rowcount_c       : natural := sdram_space_g.ROWCOUNT *
                                               sdram_space_g.BANKS ;
  constant sdram_wordcnt_c        : natural := sdram_rowcount_c *
                                               sdram_rowwords_c ;
  constant sdram_rowaddr_bits_c   : natural :=
            const_bits (sdram_rowcount_c - 1) ;

  constant sdram_empty_min_c      : natural := 64 ;
  constant sdram_full_max_c       : natural := sdram_rowcount_c -
                                               sdram_empty_min_c ;

  signal sdram_read_addr          :
            unsigned (sdram_rowaddr_bits_c-1 downto 0) ;
  signal sdram_write_addr         :
            unsigned (sdram_rowaddr_bits_c-1 downto 0) ;
  signal sdram_empty_addr         :
            unsigned (sdram_rowaddr_bits_c-1 downto 0) ;

  signal sdram_read               : std_logic ;
  signal sdram_write              : std_logic ;
  signal sdram_emptying           : std_logic ;
  signal sdram_passive            : std_logic ;

  constant bank_addr_bottom_c     : natural := 0 ;
  constant bank_addr_top_c        : natural :=
              bank_addr_bottom_c + const_bits (sdram_space_g.BANKS-1) - 1 ;
  constant row_addr_bottom_c      : natural := bank_addr_top_c + 1 ;
  constant row_addr_top_c         : natural :=
              row_addr_bottom_c + sdram_space_g.ADDRBITS - 1 ;

  --  Memory Action States.

  type MEMState_t is  (
    memst_wait_e,
    memst_init_start_e,
    memst_init_stable_e,
    memst_init_startup_e,
    memst_init_refresh_e,
    memst_init_mode_e,
    memst_init_wait_e,
    memst_init_ex_mode_e,
    memst_init_ex_wait_e,
    memst_init_done_e,
    memst_read_start_e,
    memst_read_startup_e,
    memst_moveto_outmem_e,
    memst_read_end_e,
    memst_write_start_e,
    memst_write_startup_e,
    memst_movefrom_inmem_e,
    memst_write_end_e,
    memst_refresh_e,
    memst_passify_e,
    memst_restart_e
  ) ;

  signal current_state            : MEMState_t ;

  --  Commands.  Command bits from high to low are: CS#, RAS#, CAS#, WE#.

  constant sdram_cmd_inhibit_c        :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "1000" ;
  constant sdram_cmd_nop_c            :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0111" ;
  constant sdram_cmd_active_c         :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0011" ;
  constant sdram_cmd_read_c           :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0101" ;
  constant sdram_cmd_write_c          :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0100" ;
  constant sdram_cmd_burst_term_c     :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0110" ;
  constant sdram_cmd_deep_pdown_c     :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0110" ;
  constant sdram_cmd_precharge_c      :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0010" ;
  constant sdram_cmd_auto_refresh_c   :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0001" ;
  constant sdram_cmd_self_refresh_c   :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0001" ;
  constant sdram_cmd_load_mode_c      :
           std_logic_vector (sdram_space_g.CMDBITS-1 downto 0) := "0000" ;

  constant sdram_addr_precharge_all_c :
           unsigned (sdram_space_g.ADDRBITS-1 downto 0) :=
                TO_UNSIGNED (2 ** 10, sdram_space_g.ADDRBITS) ;
  constant sdram_addr_precharge_one_c :
           unsigned (sdram_space_g.ADDRBITS-1 downto 0) :=
                (others => '0') ;

  --  Mode register definitions.

  constant sdram_bankbits_c       : natural :=
              const_bits (sdram_space_g.BANKS - 1) ;

  constant sdram_mode_banksel_c   :
              unsigned (sdram_bankbits_c-1 downto 0) :=
                TO_UNSIGNED (0, sdram_bankbits_c) ;

  constant sdram_mode_wb_prog_c   : std_logic_vector (0 downto 0) := "0" ;
  constant sdram_mode_wb_single_c : std_logic_vector (0 downto 0) := "1" ;

  constant sdram_mode_om_normal_c : std_logic_vector (1 downto 0) := "00" ;

  constant sdram_mode_bt_seq_c    : std_logic_vector (0 downto 0) := "0" ;
  constant sdram_mode_bt_il_c     : std_logic_vector (0 downto 0) := "1" ;

  constant sdram_mode_blen_1_c    : std_logic_vector (2 downto 0) := "000" ;
  constant sdram_mode_blen_2_c    : std_logic_vector (2 downto 0) := "001" ;
  constant sdram_mode_blen_4_c    : std_logic_vector (2 downto 0) := "010" ;
  constant sdram_mode_blen_8_c    : std_logic_vector (2 downto 0) := "011" ;
  constant sdram_mode_blen_c_c    : std_logic_vector (2 downto 0) := "111" ;

  constant sdram_mode_prefix_c    :
              std_logic_vector (sdram_space_g.ADDRBITS-10-1 downto 0) :=
                                    (others => '0') ;

  constant sdram_mode_cl_2_c      : natural := 2 ;
  constant sdram_mode_cl_3_c      : natural := 3 ;

  constant sdram_caslat_choices_c : integer_vector :=
  (
    0,
    0,
    sdram_mode_cl_2_c,
    sdram_mode_cl_3_c,
    0,
    0,
    0,
    0
  ) ;

  constant sdram_mode_cl_c        : std_logic_vector (2 downto 0) :=
              STD_LOGIC_VECTOR (
                  TO_UNSIGNED (sdram_caslat_choices_c (sdram_times_g.CL),
                               3)) ;

  constant sdram_mode_init_c      :
              std_logic_vector (sdram_space_g.ADDRBITS-1 downto 0) :=
                  sdram_mode_prefix_c         &
                  sdram_mode_wb_prog_c        &
                  sdram_mode_om_normal_c      &
                  sdram_mode_cl_c             &
                  sdram_mode_bt_seq_c         &
                  sdram_mode_blen_c_c         ;

  --  Extended Mode register definitions.

  constant sdram_emr_banksel_c    :
              unsigned (sdram_bankbits_c-1 downto 0) :=
                TO_UNSIGNED (2, sdram_bankbits_c) ;

  constant sdram_emr_dstr_full_c  : std_logic_vector (2 downto 0) := "000" ;
  constant sdram_emr_dstr_half_c  : std_logic_vector (2 downto 0) := "001" ;
  constant sdram_emr_dstr_1qtr_c  : std_logic_vector (2 downto 0) := "010" ;
  constant sdram_emr_disr_3qtr_c  : std_logic_vector (2 downto 0) := "011" ;

  constant sdram_emr_tcsr_c       : std_logic_vector (1 downto 0) := "00" ;

  constant sdram_emr_sr_full_c    : std_logic_vector (2 downto 0) := "000" ;
  constant sdram_emr_sr_half_c    : std_logic_vector (2 downto 0) := "001" ;
  constant sdram_emr_sr_quarter_c : std_logic_vector (2 downto 0) := "010" ;
  constant sdram_emr_sr_eighth_c  : std_logic_vector (2 downto 0) := "101" ;
  constant sdram_emr_sr_sixtnth_c : std_logic_vector (2 downto 0) := "110" ;

  constant sdram_emr_prefix_c     :
              std_logic_vector (sdram_space_g.ADDRBITS-8-1 downto 0) :=
                                  (others => '0') ;

  constant sdram_emr_init_c       :
              std_logic_vector (sdram_space_g.ADDRBITS-1 downto 0) :=
                  sdram_emr_prefix_c          &
                  sdram_emr_dstr_1qtr_c       &
                  sdram_emr_tcsr_c            &
                  sdram_emr_sr_full_c         ;

  --  Timing control.

  constant micro_sec_cycles_c     : natural :=
              natural (real (sysclk_freq_g) / 1.0e6) ;

  constant refresh_clk_cycles_c   : natural :=
              natural (trunc (real (sysclk_freq_g) * sdram_times_g.T_REF /
                              real (sdram_space_g.ROWCOUNT))) ;

  signal refresh_clkcnt           :
            unsigned (const_bits (refresh_clk_cycles_c-1)-1 downto 0) ;

  signal refreshes_needed         :
            unsigned (const_bits (sdram_space_g.ROWCOUNT-1)-1 downto 0) ;
  signal refreshes_done           :
            unsigned (const_bits (sdram_space_g.ROWCOUNT-1)-1 downto 0) ;

  --  Number of rows to process.

  constant sdram_inmem_rows_c     : natural := inmem_buffouts_g *
                                               outmem_buffrows_g ;
  constant sdram_outmem_rows_c    : natural := outmem_buffrows_g ;


  constant row_count_table_c      : integer_vector :=
  (
    sdram_inmem_rows_c,
    sdram_outmem_rows_c
  ) ;

  constant row_count_max_c        : natural :=
            max_integer (row_count_table_c) ;

  signal row_count                :
            unsigned (const_bits (row_count_max_c)-1 downto 0) ;

 --  Long delay counts.

  constant init_clock_stable_time_c   : natural :=
              10 * micro_sec_cycles_c ;
  constant init_startup_time_c        : natural :=
              100 * micro_sec_cycles_c ;
  constant init_refresh_count_c       : natural :=
              2 * sdram_space_g.ROWCOUNT ;

  constant long_delay_table_c     : integer_vector :=
  (
    init_clock_stable_time_c,
    init_startup_time_c,
    init_refresh_count_c
  ) ;

  constant long_delay_max_c       : natural :=
            max_integer (long_delay_table_c) ;

  signal long_cnt                 :
            unsigned (const_bits (long_delay_max_c)-1 downto 0) ;

  --  Short delay counts.  To handle truncation problems a small bias is
  --  added to each non-integer number.

  constant clock_latency_delay_c  : natural := sdram_times_g.CL - 1 ;

  constant precharge_delay_c      : natural :=
              natural (trunc (sdram_times_g.T_RP *
                              real (sysclk_freq_g) + 0.001)) + 1 ;

  constant active_delay_c         : natural :=
              natural (trunc (sdram_times_g.T_RCD *
                              real (sysclk_freq_g) + 0.001)) + 1 ;

  constant write_done_delay_c     : natural :=
              natural (trunc (sdram_times_g.T_WR *
                              real (sysclk_freq_g) + 0.001)) + 1 ;

  constant auto_refresh_delay_c   : natural :=
              natural (trunc (sdram_times_g.T_RFC *
                              real (sysclk_freq_g) + 0.001)) + 3 ;
              -- Two extra cycles added to reduce current drain.

  -- Constant is calculated using min T_CK as multiplier.
  -- constant load_mode_delay_c      : natural :=
              -- natural (trunc (real (sdram_times_g.T_MRD) *
                                    -- sdram_times_g.T_CK *
                              -- real (sysclk_freq_g) + 0.001)) + 1 ;

  -- Constant is calculated using T_CK as number of clock cycles of whatever
  -- length.
  constant load_mode_delay_c      : natural := sdram_times_g.T_MRD ;

  constant self_refresh_delay_c   : natural :=
              natural (trunc (sdram_times_g.T_RAS_L *
                              real (sysclk_freq_g) + 0.001)) + 1 ;

  constant clock_restart_delay_c  : natural := 8 ;

  constant restart_delay_c        : natural :=
              minimum (natural (trunc (sdram_times_g.T_XSR *
                                       real (sysclk_freq_g) + 0.001)) + 1,
                       2) ;

  constant short_delay_table_c    : integer_vector :=
  (
    clock_latency_delay_c,
    precharge_delay_c,
    active_delay_c,
    write_done_delay_c,
    auto_refresh_delay_c,
    load_mode_delay_c,
    self_refresh_delay_c,
    clock_restart_delay_c,
    restart_delay_c
  ) ;

  constant short_delay_max_c      : natural :=
            max_integer (short_delay_table_c) ;

  signal delay_cnt                :
            unsigned (const_bits (short_delay_max_c)-1 downto 0) ;

begin

  --  Output signals linked to local signals.

  inmem_address_out               <= STD_LOGIC_VECTOR (in_address) ;
  outmem_address_out              <= STD_LOGIC_VECTOR (out_address) ;

  --  SDRAM clock control.

  sdram_clock_output              <= not sysclk ;
  sdram_clk_out                   <= sdram_clock_output and
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
  inmem_clk_out                   <= inmem_clock_output and
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
  outmem_clk_out                  <= outmem_clock_output and
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

      if (sdram_passive = '1') then
        refresh_clkcnt            <= (others => '0') ;

      elsif (refresh_clkcnt /= refresh_clk_cycles_c - 1) then
        refresh_clkcnt            <= refresh_clkcnt + 1 ;

      else
        refresh_clkcnt            <= (others => '0') ;

        refreshes_needed          <= refreshes_needed + 1 ;
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

  inmem_buff_check : process (reset, inmem_buffready_in)
  begin
    if (reset = '1') then
      inmem_end_buff              <= (others => '0') ;
      inmem_end_wrap              <= '0' ;

    elsif (inmem_buffready_in'event and inmem_buffready_in = '1') then
      if (inmem_end_buff /= inmem_buffcount_g - 1) then
        inmem_end_buff            <= inmem_end_buff + 1 ;
      else
        inmem_end_buff            <= (others => '0') ;
        inmem_end_wrap            <= not inmem_end_wrap ;
      end if ;
    end if ;
  end process inmem_buff_check ;

  outmem_buff_check : process (reset, outmem_buffready_in)
  begin
    if (reset = '1') then
      outmem_end_buff             <= (others => '0') ;
      outmem_end_wrap             <= '0' ;

    elsif (outmem_buffready_in'event and outmem_buffready_in = '1') then
      if (outmem_end_buff /= inmem_buffcount_g - 1) then
        outmem_end_buff           <= outmem_end_buff + 1 ;
      else
        outmem_end_buff           <= (others => '0') ;
        outmem_end_wrap           <= not outmem_end_wrap ;
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
      outmem_amt_out              <= (others => '0') ;

    elsif (sysclk'event and sysclk = '1') then

      --  Start emptying the SDRAM when conditions are met.

      if (sdram_emptying = '0') then

        --  Start emptying when forced output is specified and the memory
        --  is not already empty but the output buffers are empty.

        if (sdram_forceout_in  = '1' and
            sdram_read_addr   /= sdram_write_addr and
            outmem_start_buff  = outmem_end_buff and
            outmem_start_wrap  = outmem_end_wrap) then

          sdram_emptying          <= '1' ;
          sdram_empty_addr        <= sdram_write_addr ;

          if (sdram_write_addr > sdram_read_addr) then
            outmem_amt_out        <=
                    SHIFT_LEFT (RESIZE (sdram_write_addr -
                                        sdram_read_addr,
                                        outmem_amt_out'length),
                                row_shift_c) ;

          else
            outmem_amt_out        <=
                    SHIFT_LEFT (RESIZE (const_unsigned (sdram_rowcount_c) -
                                        (sdram_read_addr -
                                         sdram_write_addr),
                                        outmem_amt_out'length),
                                row_shift_c) ;
          end if ;

        --  Start emptying when the memory is almost full.

        elsif (((sdram_write_addr > sdram_read_addr) and
                (sdram_write_addr - sdram_read_addr =
                 sdram_full_max_c)) or
               (sdram_read_addr - sdram_write_addr  =
                sdram_empty_min_c)) then

          sdram_emptying          <= '1' ;
          sdram_empty_addr        <= sdram_write_addr ;
          outmem_amt_out          <=
                  SHIFT_LEFT (TO_UNSIGNED (sdram_full_max_c,
                                           outmem_amt_out'length),
                              row_shift_c) ;
        end if ;

      --  Stop emptying when the memory has reached its target empty point.
      --  (It may not be empty as more data may have been written to sdram
      --  after the empty operation had started.)

      elsif (sdram_read_addr = sdram_empty_addr) then

        sdram_emptying            <= '0' ;

      end if ;

      --  Memory is empty when the read pointer has caught up with the write
      --  pointer and nothing is ready to be read from or written to it.

      if (sdram_read_addr = sdram_write_addr and sdram_write = '0' and
          (outmem_start_buff = outmem_end_buff and
           outmem_start_wrap = outmem_end_wrap)) then
        sdram_empty_out           <= '1' ;
      else
        sdram_empty_out           <= '0' ;
      end if ;

    end if ;
  end process mem_read_check ;

  --  Circular buffers are implemented using mirroring.
  --  Each buffer has a pointer and a wrap bit that is toggled every time
  --  a pointer wraps around.  Buffer status is determined as follows.
  --    Empty:      (start_buff  = end_buff) and (start_wrap  = end_wrap)
  --    Full:       (start_buff  = end_buff) and (start_wrap /= end_wrap)
  --    Not Empty:  (start_buff /= end_buff) or  (start_wrap /= end_wrap)
  --    Not Full:   (start_buff /= end_buff) or  (start_wrap  = end_wrap)

  --  Start a read when memory is being emptied and an output buffer is
  --  available to put the data in.

  sdram_read  <= '1' when ((sdram_emptying = '1') and
                           (outmem_start_buff /= outmem_end_buff or
                            outmem_start_wrap  = outmem_end_wrap))
                     else '0' ;

  --  Start a write when an input buffer is available to take data from.

  sdram_write <= '1' when ((inmem_start_buff /= inmem_end_buff or
                            inmem_start_wrap /= inmem_end_wrap))
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
      current_state         <= memst_init_start_e ;
      delay_cnt             <= (others => '0') ;
      long_cnt              <= (others => '0') ;
      row_count             <= (others => '0') ;
      refreshes_done        <= (others => '0') ;

      ready_out             <= '0' ;

      inmem_start_buff      <= (others => '0') ;
      inmem_start_wrap      <= '0' ;    -- No buffers initially available.
      inmem_read_en_out     <= '0' ;
      inmem_clock_run       <= '0' ;
      in_address            <= (others => '0') ;

      outmem_start_buff     <= (others => '0') ;
      outmem_start_wrap     <= '0' ;    -- All buffers initially available.
      outmem_datato_out     <= (others => '0') ;
      outmem_write_en_out   <= '0' ;
      outmem_clock_run      <= '0' ;
      outmem_writing_out    <= '0' ;
      out_address           <= (others => '0') ;

      sdram_passive         <= '1' ;
      sdram_clock_run       <= '0' ;
      sdram_read_addr       <= (others => '0') ;
      sdram_write_addr      <= (others => '0') ;

      sdram_clk_en_out      <= '0' ;
      sdram_command_out     <= (others => '0') ;
      sdram_bank_out        <= (others => '0') ;
      sdram_address_out     <= (others => '0') ;
      sdram_data_out        <= (others => '0') ;
      sdram_data_dir        <= '1' ;
      sdram_mask_out        <= (others => '1') ;

    elsif (sysclk'event and sysclk = '1') then

      --  Clear the writing flag when we are done emptying the SDRAM.

      if (sdram_emptying = '0') then
        outmem_writing_out  <= '0' ;
      end if ;

      --  Handle any delays before going to the next state.

      if (delay_cnt /= 0) then
        delay_cnt           <= delay_cnt - 1 ;
        sdram_command_out   <= sdram_cmd_nop_c ;

      else
        --  Memory Access State Machine.

        case current_state is

          --  Check for time to start a new state sequence.  The first
          --  entries are higher priority than later ones.  The clock must
          --  be reactivated before other commands can be started.
          --  Refreshes must be started as well.  One is added immediately
          --  when this is done.

          when memst_wait_e           =>
            if ((sdram_read      = '1' or
                 sdram_write     = '1' or
                 refreshes_done /= refreshes_needed) and
                sdram_clock_run = '0') then

              if (sdram_passive = '1') then
                sdram_passive   <= '0' ;
                refreshes_done  <= refreshes_done - 1 ;
              end if ;

              sdram_clock_run   <= '1' ;
              delay_cnt         <= TO_UNSIGNED (clock_restart_delay_c,
                                                delay_cnt'length) ;
              current_state     <= memst_restart_e ;

            --  Read a buffer from SDRAM and write it to output memory.

            elsif (sdram_read = '1') then
              outmem_clock_run  <= '1' ;
              out_address       <=
                    RESIZE (const_unsigned (outmem_buffwords_c) *
                            outmem_start_buff - 1,
                            out_address'length) ;
              row_count         <= TO_UNSIGNED (outmem_buffrows_g - 1,
                                                row_count'length) ;
              current_state     <= memst_read_start_e ;

            --  Write a buffer from input memory to the SDRAM.

            elsif (sdram_write = '1') then
              inmem_clock_run   <= '1' ;
              in_address        <=
                    RESIZE (const_unsigned (inmem_buffwords_c) *
                            inmem_start_buff,
                            in_address'length) ;
              row_count         <= TO_UNSIGNED (inmem_buffouts_g *
                                                outmem_buffrows_g - 1,
                                                row_count'length) ;
              current_state     <= memst_write_start_e ;

            --  Execute an auto-refresh if refreshes need to be done.

            elsif (refreshes_done /= refreshes_needed) then
              current_state     <= memst_refresh_e ;

            --  Put the SDRAM into a passive mode.

            elsif (sdram_emptying = '0' and sdram_passive = '0') then
              current_state     <= memst_passify_e ;

            else
              sdram_clock_run   <= '0' ;
              current_state     <= memst_wait_e ;
            end if ;

          --  Initialize the dynamic memory.
          --  Start the clock and wait for stability.

          when memst_init_start_e     =>
            sdram_clk_en_out    <= '1' ;
            sdram_clock_run     <= '1' ;
            sdram_command_out   <= sdram_cmd_inhibit_c ;
            long_cnt            <= TO_UNSIGNED (init_clock_stable_time_c,
                                                long_cnt'length) ;
            current_state       <= memst_init_stable_e ;

          --  Give the dynamic memory time to initialize itself.

          when memst_init_stable_e    =>
            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1 ;
            else
              sdram_command_out <= sdram_cmd_nop_c ;
              long_cnt          <= TO_UNSIGNED (init_startup_time_c,
                                                long_cnt'length) ;
              current_state     <= memst_init_startup_e ;
            end if ;

          --  Precharge all banks of memory after startup time has passed.

          when memst_init_startup_e   =>
            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1;
            else
              sdram_command_out <= sdram_cmd_precharge_c ;
              sdram_address_out <= sdram_addr_precharge_all_c ;
              delay_cnt         <= TO_UNSIGNED (precharge_delay_c,
                                                delay_cnt'length) ;
              long_cnt          <= TO_UNSIGNED (init_refresh_count_c - 1,
                                                long_cnt'length) ;
              current_state     <= memst_init_refresh_e ;
            end if ;

          --  Refresh all rows of memory twice.

          when memst_init_refresh_e   =>
            sdram_command_out   <= sdram_cmd_auto_refresh_c ;
            delay_cnt           <= TO_UNSIGNED (auto_refresh_delay_c,
                                                delay_cnt'length) ;

            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1 ;
            else
              current_state     <= memst_init_mode_e ;
            end if ;

          --  Initialize the mode register.

          when memst_init_mode_e      =>
            sdram_command_out   <= sdram_cmd_load_mode_c ;
            sdram_bank_out      <= sdram_mode_banksel_c ;
            sdram_address_out   <= unsigned (sdram_mode_init_c) ;
            current_state       <= memst_init_wait_e ;

          when memst_init_wait_e      =>
            sdram_command_out   <= sdram_cmd_nop_c ;
            sdram_bank_out      <= (others => '0') ;
            sdram_address_out   <= (others => '0') ;
            delay_cnt           <= TO_UNSIGNED (load_mode_delay_c,
                                                delay_cnt'length) ;
            current_state       <= memst_init_ex_mode_e ;

          --  Initialize the extended mode register.

          when memst_init_ex_mode_e   =>
            sdram_command_out   <= sdram_cmd_load_mode_c ;
            sdram_bank_out      <= sdram_emr_banksel_c ;
            sdram_address_out   <= unsigned (sdram_emr_init_c) ;
            current_state       <= memst_init_ex_wait_e ;

          when memst_init_ex_wait_e   =>
            sdram_command_out   <= sdram_cmd_nop_c ;
            sdram_bank_out      <= (others => '0') ;
            sdram_address_out   <= (others => '0') ;
            delay_cnt           <= TO_UNSIGNED (load_mode_delay_c,
                                                delay_cnt'length) ;
            current_state       <= memst_init_done_e ;

          --  Put the memory into self-refresh mode and wait until some
          --  type of memory access needs to be done.

          when memst_init_done_e      =>
            sdram_command_out   <= sdram_cmd_self_refresh_c ;
            sdram_clk_en_out    <= '0' ;
            sdram_passive       <= '1' ;
            delay_cnt           <= TO_UNSIGNED (self_refresh_delay_c,
                                                delay_cnt'length) ;
            ready_out           <= '1' ;
            current_state       <= memst_wait_e ;

          --  Start a row read operation moving data to output memory.
          --  The initial output address will be one less than the first
          --  address used so that the increment to next address can be
          --  used at every word output.

          when memst_read_start_e     =>
            sdram_command_out   <= sdram_cmd_active_c ;
            sdram_bank_out      <= sdram_read_addr (bank_addr_top_c downto
                                                    bank_addr_bottom_c) ;
            sdram_address_out   <= sdram_read_addr (row_addr_top_c downto
                                                    row_addr_bottom_c) ;
            delay_cnt           <= TO_UNSIGNED (active_delay_c,
                                                delay_cnt'length) ;
            current_state       <= memst_read_startup_e ;

          --  Read all the words in a row and write them to the output.
          --  Close the row after finishing it.

          when memst_read_startup_e   =>
            sdram_command_out   <= sdram_cmd_read_c ;
            sdram_address_out   <= (others => '0') ;
            sdram_data_out      <= (others => '0') ;
            sdram_data_dir      <= '0' ;
            sdram_mask_out      <= (others => '0') ;
            delay_cnt           <= TO_UNSIGNED (clock_latency_delay_c,
                                                delay_cnt'length) ;
            long_cnt            <= TO_UNSIGNED (sdram_rowwords_c - 1,
                                                long_cnt'length) ;
            current_state       <= memst_moveto_outmem_e ;

          when memst_moveto_outmem_e  =>
            outmem_datato_out   <= sdram_data_in ;
            outmem_write_en_out <= '1' ;
            out_address         <= out_address + 1 ;

            if (long_cnt = clock_latency_delay_c) then
              sdram_command_out <= sdram_cmd_precharge_c ;
              sdram_address_out <= sdram_addr_precharge_one_c ;
              long_cnt          <= long_cnt - 1 ;
            elsif (long_cnt /= 0) then
              sdram_command_out <= sdram_cmd_nop_c ;
              long_cnt          <= long_cnt - 1 ;
            else
              sdram_command_out <= sdram_cmd_nop_c ;
              sdram_mask_out    <= (others => '1') ;
              current_state     <= memst_read_end_e ;
            end if ;

          --  Drive the output lines again.  Stop writing to output memory.
          --  If the buffer has been filled set the last buffer filled
          --  indicator and say that output memory data is available.
          --  A delay is added before re-entering the wait state to insure
          --  that control signals have had a chance to stabalize
          --  (sdram_emptying in particular).

          when memst_read_end_e       =>
            sdram_data_out        <= (others => '0') ;
            sdram_data_dir        <= '1' ;
            outmem_write_en_out   <= '0' ;
            sdram_read_addr       <= sdram_read_addr + 1 ;

            if (precharge_delay_c > clock_latency_delay_c) then
              delay_cnt           <= TO_UNSIGNED (precharge_delay_c -
                                                  clock_latency_delay_c,
                                                  delay_cnt'length) ;
            end if ;

            if (row_count /= 0) then
              row_count           <= row_count - 1 ;
              current_state       <= memst_read_start_e ;
            else
              if (outmem_start_buff = outmem_buffcount_g - 1) then
                outmem_start_buff <= (others => '0') ;
                outmem_start_wrap <= not outmem_start_wrap ;
              else
                outmem_start_buff <= outmem_start_buff + 1 ;
              end if ;

              outmem_writing_out  <= '1' ;
              outmem_clock_run    <= '0' ;
              delay_cnt           <= TO_UNSIGNED (2,
                                                  delay_cnt'length) ;
              current_state       <= memst_wait_e ;
            end if ;

          --  Start a row write operation moving data from input memory.

          when memst_write_start_e    =>
            sdram_command_out   <= sdram_cmd_active_c ;
            sdram_mask_out      <= (others => '0') ;
            sdram_bank_out      <= sdram_write_addr (bank_addr_top_c downto
                                                     bank_addr_bottom_c) ;
            sdram_address_out   <= sdram_write_addr (row_addr_top_c downto
                                                     row_addr_bottom_c) ;
            inmem_read_en_out   <= '1' ;
            delay_cnt           <= TO_UNSIGNED (active_delay_c,
                                                delay_cnt'length) ;
            current_state       <= memst_write_startup_e ;

          --  Write all the words in a row and read them from the input.

          when memst_write_startup_e  =>
            sdram_command_out   <= sdram_cmd_write_c ;
            sdram_address_out   <= (others => '0') ;
            sdram_data_out      <= inmem_datafrom_in ;
            sdram_data_dir      <= '1' ;
            in_address          <= in_address + 1 ;
            long_cnt            <= TO_UNSIGNED (sdram_rowwords_c - 1,
                                                long_cnt'length) ;
            current_state       <= memst_movefrom_inmem_e ;

          when memst_movefrom_inmem_e =>
            sdram_command_out   <= sdram_cmd_nop_c ;

            if (long_cnt /= 0) then
              long_cnt          <= long_cnt - 1 ;
              sdram_data_out    <= inmem_datafrom_in ;
              sdram_data_dir    <= '1' ;
              in_address        <= in_address + 1 ;
            else
              sdram_mask_out    <= (others => '1') ;
              inmem_read_en_out <= '0' ;
              delay_cnt         <= TO_UNSIGNED (write_done_delay_c,
                                                delay_cnt'length) ;
              current_state     <= memst_write_end_e ;
           end if ;

          --  Close the row and mark the buffer as full if no more rows
          --  to be read.

          when memst_write_end_e      =>

            sdram_command_out     <= sdram_cmd_precharge_c ;
            sdram_address_out     <= sdram_addr_precharge_one_c ;
            sdram_write_addr      <= sdram_write_addr + 1 ;

            if (row_count /= 0) then
              row_count           <= row_count - 1 ;
              current_state       <= memst_write_start_e ;
            else
              if (inmem_start_buff = inmem_buffcount_g - 1) then
                inmem_start_buff  <= (others => '0') ;
                inmem_start_wrap  <= not inmem_start_wrap ;
              else
                inmem_start_buff  <= inmem_start_buff + 1 ;
              end if ;

              delay_cnt           <= TO_UNSIGNED (precharge_delay_c,
                                                  delay_cnt'length) ;
              inmem_clock_run     <= '0' ;
              current_state       <= memst_wait_e ;
            end if ;

          --  Refresh one row.

          when memst_refresh_e        =>
            sdram_command_out   <= sdram_cmd_auto_refresh_c ;
            delay_cnt           <= TO_UNSIGNED (auto_refresh_delay_c,
                                                delay_cnt'length) ;
            refreshes_done      <= refreshes_done + 1 ;
            current_state       <= memst_wait_e ;

          --  Put the memory into self-refresh mode.

          when memst_passify_e        =>
            sdram_passive       <= '1' ;
            sdram_command_out   <= sdram_cmd_self_refresh_c ;
            sdram_clk_en_out    <= '0' ;
            delay_cnt           <= TO_UNSIGNED (self_refresh_delay_c,
                                                delay_cnt'length) ;
            current_state       <= memst_wait_e ;

          --  Restart the memory use from a passive state.

          when memst_restart_e        =>
              sdram_clk_en_out  <= '1' ;
              delay_cnt         <= TO_UNSIGNED (restart_delay_c,
                                                delay_cnt'length) ;
              current_state     <= memst_wait_e ;

        end case ;
      end if ;
    end if ;
  end process mem_acc ;

end rtl ;
