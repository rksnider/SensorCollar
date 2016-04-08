----------------------------------------------------------------------------
--  Package to define constants in.
----------------------------------------------------------------------------

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

package shared_sdc_values_pkg is

  constant source_clk_freq_c : natural := 50e6 ;
  constant spi_clk_freq_c : natural := 3571428 ;
  constant slow_sdcard_clk_freq_c : natural := 400e3 ;
  constant gps_baud_rate_c : natural := 9600 ;

end package shared_sdc_values_pkg ;
