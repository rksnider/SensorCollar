
library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Use real numbers for finding number of
                                --  bits needed.
package magmem_buffer_def_pkg is

constant magmem_buffer_bytes        : natural := 1024;
constant magmem_buffer_num          : natural := 2;
constant magmem_data_width_a_bytes  : natural := 1;

--Check magic value to see if magnetic memory is initialized.
constant magmem_init_value_c  : std_logic_vector(15 downto 0) := x"ABCD";

-- --Interval at which the magnetic memory buffer is saved
-- --to physical magnetic memory. 
-- constant mag_interval_ms_c          : natural := 128;



--Position in the magnetic memory 2 port ram buffer.

--Init Value Location
constant sd_card_init_value_length_bytes_c : natural := 2;
constant sd_card_init_value_location_c : natural := 0;


--SD Card Last Block Successfully Written
constant sd_card_start_location_length_bytes_c : natural := 4;
constant sd_card_start_location_c : natural := sd_card_init_value_location_c
                                              + sd_card_init_value_length_bytes_c;
                                              
--SD Card Last Logical Block Assembled Successfully
constant logical_block_length_bytes_c : natural := 4;
constant logical_block_location_c : natural := sd_card_init_value_location_c
                                              + sd_card_init_value_length_bytes_c;


--Shut-Down successful. 
constant shutdown_success_length_bytes_c : natural := 1;
constant shutdown_success_location_c : natural := logical_block_length_bytes_c 
                                  + logical_block_location_c ;


end package magmem_buffer_def_pkg ;

package body magmem_buffer_def_pkg is



end package body magmem_buffer_def_pkg ;