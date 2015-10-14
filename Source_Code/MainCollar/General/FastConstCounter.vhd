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
  --  both.  The number of bits added per period is reduced slightly to
  --  avoid round up.

  constant CountConstBits_c   : natural := const_bits (CounterConstant_g) ;
  constant CountLimitBits_c   : natural :=
              const_bits (CounterLimit_g + CounterConstant_g - 1) ;

  constant AddBitsPerPeriod_c : natural :=
              natural (trunc (real (AddBitsPerUsec_g) /
                              real (clk_freq_g) * 1.0e6 * 0.99)) ;


  signal result               : unsigned (CountLimitBits_c-1 downto 0) ;

  signal carry_next           : std_logic ;

begin

  --------------------------------------------------------------------------
  --  Don't subdivide the counting if not needed.
  --------------------------------------------------------------------------

  nonsubdiv : if (AddBitsPerPeriod_c >= CountLimitBits_c) generate

    begin

      counter: process (reset, clk)
        variable diff         : signed (CountLimitBits_c downto 0) ;
      begin
        --  Calculate the result of the first clock cycle.  Counting will
        --  not start until the second rising clock edge.

        if (reset = '1') then
          result              <= preset_in ;
          result_out          <= preset_in ;
          carry_out           <= '0' ;
          carry_next          <= '0' ;

        --  The carry signal is set one half clock cycle before rollover
        --  and cleared one half clock cycle after.  This allows synchronous
        --  carry chains.

        elsif (falling_edge (clk)) then
          carry_out           <= carry_next ;

        --  Output the result of the clock cycle and calculate the value
        --  to use for the next one.  Carry is set for the next clock
        --  cycle.

        elsif (rising_edge (clk)) then
          result_out          <= result ;

          diff                := signed (RESIZE (result, diff'length)) -
                                 CounterLimit_g + CounterConstant_g ;

          if (diff (diff'length-1) = '1') then
            result            <= result + CounterConstant_g ;
            carry_next        <= '0' ;
          else
            result            <= RESIZE (unsigned (diff), result'length) ;
            carry_next        <= '1' ;
          end if ;
        end if ;
      end process counter ;
  end generate nonsubdiv ;


  --------------------------------------------------------------------------
  --  Subdivide the counting if when it can't be completed in a single
  --  clock cycle.
  --------------------------------------------------------------------------

  subdiv : if (AddBitsPerPeriod_c < CountLimitBits_c) generate

      --  Adder bits.

      constant LowBitCnt_c    : natural := AddBitsPerPeriod_c ;
      constant HighBitCnt_c   : natural := CountLimitBits_c -
                                           AddBitsPerPeriod_c ;

      constant CounterLimit_full_c  : unsigned (CountLimitBits_c-1
                                                downto 0) :=
                  TO_UNSIGNED (CounterLimit_g, CountLimitBits_c) ;
      constant CounterLimit_low_c   : unsigned (LowBitCnt_c-1 downto 0) :=
                  RESIZE (CounterLimit_full_c, LowBitCnt_c) ;
      constant CounterLimit_high_c  : unsigned (HighBitCnt_c-1 downto 0) :=
                  RESIZE (SHIFT_RIGHT (CounterLimit_full_c, LowBitCnt_c),
                          HighBitCnt_c) ;

      signal low_bits         : unsigned (LowBitCnt_c-1 downto 0) ;
      signal high_bits        : unsigned (HighBitCnt_c-1 downto 0) ;
      signal pre_high_bits    : unsigned (HighBitCnt_c-1 downto 0) ;
      signal pre_high_reset   : unsigned (HighBitCnt_c-1 downto 0) ;

      signal preset_low       : unsigned (LowBitCnt_c-1 downto 0) ;
      signal preset_high      : unsigned (HighBitCnt_c-1 downto 0) ;

      signal restart          : std_logic ;
      signal counter_reset    : std_logic ;

      signal high_clk         : std_logic ;

    begin

      preset_low              <= RESIZE (preset_in, LowBitCnt_c) ;
      preset_high             <= RESIZE (SHIFT_RIGHT (preset_in,
                                                      LowBitCnt_c),
                                         HighBitCnt_c) ;

      result                  <= high_bits & low_bits ;

      ----------------------------------------------------------------------
      --  Add a constant amount to the low bits of the summation result.
      --  When the result reaches its maximum value below a specified limit
      --  roll the result over to zero.
      ----------------------------------------------------------------------

      low_counter: process (reset, clk, preset_in)
        variable low_bits_v       : unsigned (low_bits'length-1 downto 0) ;
        variable high_bits_v      : unsigned (high_bits'length-1 downto 0) ;
        variable diff_low_v       : signed (low_bits'length downto 0) ;
        variable diff_limit_v     : signed (low_bits'length downto 0) ;
        variable high_bits_new_v  : unsigned (high_bits'length-1 downto 0) ;
      begin
        --  Calculate the result of the first clock cycle.  Counting will
        --  not start until the second rising clock edge.

        if (reset = '1') then
          restart             <= '1' ;
          counter_reset       <= '0' ;
          carry_next          <= '0' ;
          carry_out           <= '0' ;
          high_clk            <= '0' ;
          result_out          <= preset_in ;

        --  The carry signal is set one half clock cycle before rollover
        --  and cleared one half clock cycle after.  This allows synchronous
        --  carry chains.

        elsif (falling_edge (clk)) then
          carry_out           <= carry_next ;

        --  Output the result of the clock cycle and calculate the value
        --  to use for the next one.  Rollover of both the lower bit
        --  counter and the counter as a whole is done here.

        elsif (rising_edge (clk)) then
          if (restart = '1') then
            restart           <= '0' ;
            low_bits_v        := preset_low ;
            high_bits_v       := preset_high ;
          else
            low_bits_v        := low_bits ;
            high_bits_v       := high_bits ;
          end if ;

          result_out          <= result ;

          counter_reset       <= '0' ;
          carry_next          <= '0' ;

          --  Determine if low bit counter roll over has occured.  This
          --  is indicated by a non negative value from the subtraction
          --  (sign bit is clear).

          diff_low_v          := signed (RESIZE (low_bits_v,
                                                 diff_low_v'length)) -
                                 ((2 ** low_bits_v'length) -
                                  CounterConstant_g) ;

          if (diff_low_v (diff_low_v'length-1) = '1') then
            low_bits          <= low_bits_v + CounterConstant_g ;
            high_bits_new_v   := high_bits_v ;
            high_clk          <= '0' ;

            diff_limit_v      := signed (RESIZE (low_bits_v,
                                                 diff_limit_v'length)) +
                                 (CounterConstant_g -
                                  signed (RESIZE (CounterLimit_low_c,
                                                  diff_limit_v'length))) ;
          else
            low_bits          <= RESIZE (unsigned (diff_low_v),
                                         low_bits'length) ;
            high_bits_new_v   := pre_high_bits ;
            high_bits         <= pre_high_bits ;
            high_clk          <= '1' ;

            diff_limit_v      := signed (RESIZE (low_bits_v,
                                                 diff_limit_v'length)) -
                                 ((2 ** low_bits_v'length) -
                                  CounterConstant_g +
                                  signed (RESIZE (CounterLimit_low_c,
                                                  diff_limit_v'length))) ;
          end if ;

          --  Determine if full counter roll over has occured.  This is
          --  indicated when the low bit counter has rolled over (sign
          --  bit clear) and the high bit counter has reached the maximum
          --  value.

          if (high_bits_new_v = CounterLimit_high_c and
              diff_limit_v (diff_limit_v'length-1) = '0') then

            low_bits          <= RESIZE (unsigned (diff_limit_v),
                                         low_bits'length) ;
            high_bits         <= (others => '0') ;
            counter_reset     <= '1' ;
            carry_next        <= '1' ;
          end if ;
        end if ;
      end process low_counter ;


      ----------------------------------------------------------------------
      --  High Counter Bits.
      ----------------------------------------------------------------------

      pre_high_reset        <=
                preset_high + 1
                    when (preset_high /= CounterLimit_high_c) else
                (others => '0') ;

      high_counter : process (clk)
      begin
        if (rising_edge (clk)) then

          if (restart = '1') then
            pre_high_bits   <= pre_high_reset ;

          elsif (counter_reset = '1') then
            pre_high_bits   <= TO_UNSIGNED (1, pre_high_bits'length) ;

          elsif (high_clk = '1') then
              pre_high_bits <= pre_high_bits + 1 ;
          end if ;
        end if ;
      end process high_counter ;

  end generate subdiv ;

end architecture rtl ;
