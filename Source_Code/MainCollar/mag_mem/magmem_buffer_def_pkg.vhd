




library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Use real numbers for finding number of
                                --  bits needed.



package magmem_buffer_def_pkg is

  constant magmem_buffer_bytes        : natural := 1024;
  constant magmem_buffer_num          : natural := 2;
  constant magmem_data_width_a_bytes  : natural := 1;
  
  --Interval at which the magnetic memory buffer is saved
  --to physical magnetic memory. 
  constant mag_interval_ms_g          : natural := 128;
  

  
--Position in the magnetic memory 2 port ram buffer.


--SD Card Last Block Successfully Written
constant sd_card_start_location_length_bytes_c : natural := 4;
constant sd_card_start_location_c : natural := 0;


--Shut-Down successful. 
constant shutdown_success_length_bytes : natural := 1;
constant shutdown_success : natural := sd_card_start_location_c + sd_card_start_location_length_bytes_c ;



end package magmem_buffer_def_pkg ;

package body magmem_buffer_def_pkg is



end package body magmem_buffer_def_pkg ;