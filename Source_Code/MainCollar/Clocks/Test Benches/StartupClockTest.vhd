------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Handles the time since startup.
--! @details    The time since startup is kept by 3 clocks.  The number of
--!             weeks since startup, the millisecond in the current week, and
--!             the nanosecond in the current millisecond.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Real number functions.

LIBRARY lpm ;                   --  Use Library of Parameterized Modules.
USE lpm.lpm_components.all ;

LIBRARY WORK ;                  --  Use local libraries.
USE WORK.UTILITIES.ALL ;        --  General Utilities.
USE WORK.GPS_CLOCK.ALL ;        --  Use GPS Clock information.


------------------------------------------------------------------------------
--
--! @brief      Produces time since startup.
--! @details    Produces the number of weeks, milliseconds in the current
--!             week, and nanosecond in the current millisecond all since
--!             the system clock started running.
--!
--! @param      CLK_FREQ              Frequency of the clock signal.
--! @param      clk                   Clock used to drive the counters.
--! @param      time_since_reset      Time in GPS format.
--
------------------------------------------------------------------------------

entity StartupClock is

  Generic (
    CLK_FREQ              : natural := 5e3
  ) ;
  Port (
    clk                   : in    std_logic ;
    time_nanosecs         : out   std_logic_vector (20-1 downto 0) ;
    time_millisecs        : out   std_logic_vector (30-1 downto 0) ;
    time_weeks            : out   std_logic_vector (16-1 downto 0)
  ) ;

end entity StartupClock ;


architecture behavior of StartupClock is

  --  Number of clock ticks in a millisecond and nanoseconds in a
  --  clock tick.

  constant CLK_IN_NANOSEC         : natural :=
                  natural (round (1.0e9 / real (CLK_FREQ))) ;
  constant CLK_PER_MILLISEC       : natural :=
                  natural (round (real (CLK_FREQ) / 1000.0)) ;
  constant CLK_PER_MILLISEC_BITS  : natural := const_bits (CLK_PER_MILLISEC) ;


  --  Clock counter connectors.

  signal nanosec_cnt              : std_logic_vector (GPS_TIME_NANOBITS-1
                                                      downto 0) := (others => '0') ;
  signal millisec_cnt             : std_logic_vector (GPS_TIME_MILLIBITS-1
                                                      downto 0) ;
  signal weekno_cnt               : std_logic_vector (GPS_TIME_WEEKBITS-1
                                                      downto 0) ;
  signal carry_to_millisec        : std_logic ;
  signal carry_to_week            : std_logic ;
  signal start                    : std_logic := '1' ;

begin

  sysclock_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_MODULUS         => CLK_PER_MILLISEC,
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => CLK_PER_MILLISEC_BITS
    )
    Port Map (
      clock               => clk,
      cout                => carry_to_millisec
    ) ;

  millisec_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_MODULUS         => MILLISEC_WEEK,
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => GPS_TIME_MILLIBITS
    )
    Port Map (
      cin                 => carry_to_millisec,
      clock               => clk,
      cout                => carry_to_week,
      data                => std_logic_vector (
                                TO_UNSIGNED (MILLISEC_WEEK - 10, GPS_TIME_MILLIBITS)),
      aload               => start,
      q                   => millisec_cnt
    ) ;

  week_counter : lpm_counter
    Generic Map (
      LPM_DIRECTION       => "UP",
      LPM_PORT_UPDOWN     => "PORT_UNUSED",
      LPM_TYPE            => "LPM_COUNTER",
      LPM_WIDTH           => GPS_TIME_WEEKBITS
    )
    Port Map (
      cin                 => carry_to_week,
      clock               => clk,
      data                => std_logic_vector (TO_UNSIGNED (5, GPS_TIME_WEEKBITS)),
      aload               => start,
      q                   => weekno_cnt
    ) ;

  --  Latch the clocks all on the same clock edge to insure they are always
  --  consistant.

  latch_process : process (clk)
    variable nanocnt      : unsigned (GPS_TIME_NANOBITS-1 downto 0) ;
  begin
    if clk'event and clk = '1' then
      if carry_to_millisec = '1' then
        nanocnt           := (others => '0') ;
      else
        nanocnt           := unsigned (nanosec_cnt) + CLK_IN_NANOSEC ;
      end if ;

      start               <= '0' ;
      nanosec_cnt         <= std_logic_vector (nanocnt) ;

      time_nanosecs       <= std_logic_vector (nanosec_cnt) ;
      time_millisecs      <= millisec_cnt ;
      time_weeks          <= weekno_cnt ;
    end if ;
  end process ;


end behavior ;
