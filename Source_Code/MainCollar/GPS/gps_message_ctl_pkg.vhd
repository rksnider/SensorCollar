--! GPS Message Control Definitions.
--! Definitions for the GPS messages.

library IEEE ;
use IEEE.STD_LOGIC_1164.ALL ;
use IEEE.NUMERIC_STD.ALL ;
use IEEE.MATH_REAL.ALL ;

LIBRARY GENERAL ;
USE GENERAL.GPS_CLOCK.ALL ;

package gps_message_ctl_pkg is

--  Two banks of RAM allow there to always (except at
--  startup) be a valid set of message data.  If only
--  one bank is used it is marked as valid or not.

constant msg_ram_banks_c                : natural := 2 ;

--  Memory block information.

constant msg_count_c                    : natural := 3 ;
constant msg_count_bits_c               : natural :=
      natural (trunc (log2 (real (msg_count_c)))) + 1 ;

constant msg_id_tbl_c                   : natural := 53 ;

constant msg_rom_base_c                 : natural := 0 ;
constant msg_ram_base_c                 : natural := 59 ;
constant msg_ram_blocks_c               : natural := 2 ;
constant msg_ram_temp_addr_c            : natural := 45 * msg_ram_banks_c ;
constant msg_ram_temp_size_c            : natural := 30 ;

constant msg_ram_postime_addr_c         : natural :=
      msg_ram_temp_addr_c + msg_ram_temp_size_c * msg_ram_banks_c ;
constant msg_ram_postime_size_c         : natural := gps_time_bytes_c ;

constant msg_ram_marktime_addr_c        : natural :=
      msg_ram_postime_addr_c + msg_ram_postime_size_c * msg_ram_banks_c ;
constant msg_ram_marktime_size_c        : natural := gps_time_bytes_c ;

constant msg_ram_end_c                  : natural :=
      msg_ram_marktime_addr_c + msg_ram_marktime_size_c ;

--  Field extraction information.

constant msg_extract_tree_c             : natural := 38 ;
constant msg_tree_offset_bits_c         : natural := 2 ;
constant msg_extract_lookup_c           : natural := 50 ;
constant msg_extract_lookup_bytes_c     : natural := 1 ;
constant msg_extract_overhead_c         : natural := 1 ;
constant msg_field_count_c              : natural := 35 ;
constant msg_field_bits_c               : natural :=
      natural (trunc (log2 (real (msg_field_count_c - 1)))) + 1 ;

--  Field encoder information.

constant msg_size_bits_c                : natural := 7 ;    -- High bits.
constant msg_store_flag_c               : natural := 1 ;    -- Low bit.

--  Message prototols.

constant msg_ubx_sync_1_c               : std_logic_vector (7 downto 0) :=
                                            x"B5" ;
constant msg_ubx_sync_2_c               : std_logic_vector (7 downto 0) :=
                                            x"62" ;

--  UBX protocol message classes.

constant msg_ubx_nav_c                  : std_logic_vector (7 downto 0) :=
                                            x"01" ;
constant msg_ubx_tim_c                  : std_logic_vector (7 downto 0) :=
                                            x"0D" ;

end package gps_message_ctl_pkg ;
