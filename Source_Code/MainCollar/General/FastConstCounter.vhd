----------------------------------------------------------------------------
--
--! @file       FastConstCounter.vhd
--! @brief      Counter does the low bits fast and the high bits slow.
--! @details    The counter bits are separated into a few low bits and the
--!             rest high bits.  A constant value is added to the low bits
--!             every cycle while the high bits are incremented only when
--!             the low bits roll over.  This allows the counter to function
--!             when the clock rate is too high for all bits to be
--!             added in a single clock cycle.
--! @author     Emery Newlon
--! @date       August 2015
--! @copyright  Copyright (C) 2015 Emery L. Newlon
--
----------------------------------------------------------------------------

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

library GENERAL ;
use GENERAL.UTILITIES_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @file       FastConstCounter.vhd
--! @brief      Counter does the low bits fast and the high bits slow.
--! @details    The counter bits are separated into a few low bits and the
--!             rest high bits.  A constant value is added to the low bits
--!             every cycle while the high bits are incremented only when
--!             the low bits roll over.  This allows the counter to function
--!             when the clock rate is too high for all bits to be
--!             added in a single clock cycle.
--!
--! @param      AddBitsPerUsec_g  Number of bits of addition that can be
--!                               done in one microsecond.
--! @param      CounterConstant_g The constant amount that is added to the
--!                               result each clock cycle.  It must be
--!                               small enough to fit in the fast bits of
--!                               the counter.
--! @param      CounterLimit_g    The upper limit the counter can't reach.
--! @param      clk_freq_g        The frequency of the clock in Hertz.
--! @param      reset             Reset the component to an initial state.
--!                               The result will hold at the preset value.
--! @param      clk               Clock to run the adder at.
--! @param      preset_in         The value to load the counter with on
--!                               reset.
--! @param      result_out        The adder's current result.
--! @param      carry_out         Carry from the adder when the adder
--!                               reaches the limit.  Set one half clock
--!                               before the value rolls over and cleared
--!                               one clock cycle afertward.
--
----------------------------------------------------------------------------

entity FastConstCounter is
  generic
  (
    AddBitsPerUsec_g    : natural := 1000 ;
    CounterConstant_g   : natural := 5 ;
    CounterLimit_g      : natural := 15 ;
    clk_freq_g          : natural := 10e6
  ) ;
  port
  (
    reset               : in    std_logic ;
    clk                 : in    std_logic ;
    preset_in           : in    unsigned (const_bits (CounterLimit_g-1)-1
                                          downto 0) ;
    result_out          : out   unsigned (const_bits (CounterLimit_g-1)-1
                                          downto 0) ;
    carry_out           : out   std_logic
  ) ;

end entity FastConstCounter ;

architecture rtl of FastConstCounter is

  --  Constants and signals used by non-subdivided adds and divided adds
  --  both.

  constant CountConstBits_c   : natural := const_bits (CounterConstant_g) ;
  constant CountMaxBits_c     : natural := const_bits (CounterLimit_g-1) ;

  constant AddBitsPerPeriod_c : natural :=
              natural (trunc (real (AddBitsPerUsec_g) /
                              real (clk_freq_g) * 1.0e6)) ;


  constant CounterMax_c       : natural :=
              natural (trunc (real (CounterLimit_g) /
                                    real (CounterConstant_g) - 1.0) *
                                    real (CounterConstant_g)) ;

  signal result               : unsigned (CountMaxBits_c-1 downto 0) ;

begin

  --------------------------------------------------------------------------
  --  Don't subdivide the counting if not needed.
  --------------------------------------------------------------------------

  nonsubdiv : if (AddBitsPerPeriod_c >= CountMaxBits_c) generate

    begin

      counter: process (reset, clk)
        variable diff         : signed (CountMaxBits_c downto 0) ;
      begin
        --  Calculate the result of the first clock cycle and set the
        --  carry apropriately.

        if (reset = '1') then
          result_out          <= preset_in ;

          diff                := signed (RESIZE (preset_in, diff'length)) -
                                 (CounterLimit_g - CounterConstant_g) ;

          if (diff (diff'length-1) = '1') then
            result            <= preset_in + CounterConstant_g ;
            carry_out         <= '0' ;
          else
            result            <= unsigned (diff (CountMaxBits_c-1
                                                 downto 0)) ;
            carry_out         <= '1' ;
          end if ;

        --  Output the result of the clock cycle and calculate the value
        --  to use for the next one.  Carry is set for the next clock
        --  cycle.

        elsif (rising_edge (clk)) then
          result_out          <= result ;

          diff                := signed (RESIZE (result, diff'length)) -
                                 (CounterLimit_g - CounterConstant_g) ;

          if (diff (diff'length-1) = '1') then
            result            <= result + CounterConstant_g ;
            carry_out         <= '0' ;
          else
            result            <= unsigned (diff (CountMaxBits_c-1
                                                 downto 0)) ;
            carry_out         <= '1' ;
          end if ;
        end if ;
      end process counter ;
  end generate nonsubdiv ;


  --------------------------------------------------------------------------
  --  Subdivide the counting if when it can't be completed in a single
  --  clock cycle.
  --------------------------------------------------------------------------

  subdiv : if (AddBitsPerPeriod_c < CountMaxBits_c) generate

      --  Adder bits.

      constant LowBitCnt_c    : natural := AddBitsPerPeriod_c ;
      constant HighBitCnt_c   : natural := CountMaxBits_c -
                                           AddBitsPerPeriod_c ;

      signal low_bits         : unsigned (LowBitCnt_c-1 downto 0) ;
      signal high_bits        : unsigned (HighBitCnt_c-1 downto 0) ;
      signal pre_high_bits    : unsigned (HighBitCnt_c-1 downto 0) ;

      signal preset_low       : unsigned (LowBitCnt_c-1 downto 0) ;
      signal preset_high      : unsigned (HighBitCnt_c-1 downto 0) ;

      signal counter_reset    : std_logic ;
      signal carry_next       : std_logic ;

      signal high_clk         : std_logic ;

    begin

      preset_low              <= preset_in (LowBitCnt_c-1 downto 0) ;
      preset_high             <= preset_in (CountMaxBits_c-1
                                            downto LowBitCnt_c) ;

      result                  <= high_bits & low_bits ;

      ----------------------------------------------------------------------
      --  Add a constant amount to the low bits of the summation result.
      --  When the result reaches its maximum value below a specified limit
      --  roll the result over to zero.
      ----------------------------------------------------------------------

      low_counter: process (reset, clk)
        variable diff         : signed (low_bits'length downto 0) ;
      begin
        --  Calculate the result of the first clock cycle and set the
        --  carry apropriately.

        if (reset = '1') then
          counter_reset       <= '0' ;
          carry_next          <= '0' ;

          if (preset_in = CounterMax_c) then
            low_bits          <= (others => '0') ;
            high_bits         <= (others => '0') ;
            high_clk          <= '0' ;
            result_out        <= (others => '0') ;
            carry_out         <= '1' ;
          else
            result_out        <= preset_in ;
            carry_out         <= '0' ;

            diff              := signed (RESIZE (preset_low, diff'length)) -
                                 ((2 ** low_bits'length) -
                                  CounterConstant_g) ;

            if (diff (diff'length-1) = '1') then
              low_bits        <= preset_low + CounterConstant_g ;
              high_clk        <= '0' ;
            else
              low_bits        <= unsigned (diff (low_bits'length-1
                                                 downto 0)) ;
              high_bits       <= TO_UNSIGNED (1, high_bits'length) ;
              high_clk        <= '1' ;
            end if ;
          end if ;

        --  Determine if the next rising edge will result in rollover.
        --  The carry signal is set one half clock cycle before rollover
        --  and cleared one half clock cycle after.  This allows synchronous
        --  carry chains.

        elsif (falling_edge (clk)) then
          high_clk            <= '0' ;

          if (result = CounterMax_c) then
            carry_next        <= '1' ;
            carry_out         <= '1' ;
          else
            carry_next        <= '0' ;
            carry_out         <= '0' ;
          end if ;

        --  Output the result of the clock cycle and calculate the value
        --  to use for the next one.

        elsif (rising_edge (clk)) then
          result_out          <= result ;

          if (carry_next = '1') then
            counter_reset     <= '1' ;
            low_bits          <= (others => '0') ;
            high_bits         <= (others => '0') ;
            high_clk          <= '1' ;
          else
            counter_reset     <= '0' ;

            diff              := signed (RESIZE (low_bits, diff'length)) -
                                 ((2 ** low_bits'length) -
                                  CounterConstant_g) ;

            if (diff (diff'length-1) = '1') then
              low_bits        <= low_bits + CounterConstant_g ;
              high_clk        <= '0' ;
            else
              low_bits        <= unsigned (diff (low_bits'length-1
                                                 downto 0)) ;
              high_bits       <= pre_high_bits ;
              high_clk        <= '1' ;
            end if ;
          end if ;
        end if ;
      end process low_counter ;


      ----------------------------------------------------------------------
      --  High Counter Bits.
      ----------------------------------------------------------------------

      high_counter : process (reset, high_clk)
      begin
        if (reset = '1') then
          if (preset_in = CounterMax_c) then
            pre_high_bits   <= TO_UNSIGNED (1, pre_high_bits'length) ;
          else
            pre_high_bits   <= preset_high + 1 ;
          end if ;

        elsif (rising_edge (high_clk)) then
          if (counter_reset = '1') then
            pre_high_bits   <= TO_UNSIGNED (1, pre_high_bits'length) ;

          else
            pre_high_bits   <= pre_high_bits + 1 ;
          end if ;
        end if ;
      end process high_counter ;

  end generate subdiv ;

end architecture rtl ;
