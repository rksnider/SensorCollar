function gps_message_ctl_out (msg_info, romseg_addr, offset_max, ...
                              msg_addrs, mem_bytes)
%GPS_MESSAGE_CTL_OUT  Output the gps message control info to a VHDL file.
% usage gps_message_ctl_out (msg_info, tree_addr, lookup_addr)
%      msg_info = Memory vector for [ROM RAM RAM_BLOCK RAM_TEMP MSG
%                                    FLD MSG_BUFF].
%   romseg_addr = Address start vector of ROM segments.
%    offset_max = Maximum offset value in any tree node.
%     msg_addrs = Addresses of the extraction fields in the ROM.
%     mem_bytes = Total number of bytes of memory in a memory allocation
%                 unit.
%

% --------------------------------------------------------------------------
%
%%  @file       gps_message_ctl_out.m
%   @brief      Write out the 'gps_message_ctl_pkg.vhd' file.
%   @details    Write out the 'gps_message_ctl_pkg.vhd' file with the
%               constants needed to access GPS memory and a few other
%               constants.
%   @author     Emery Newlon
%   @date       August 2014
%   @copyright  Copyright (C) 2014 Ross K. Snider and Emery L. Newlon

%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You should have received a copy of the GNU General Public License
%   along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%   Emery Newlon
%   Electrical and Computer Engineering
%   Montana State University
%   610 Cobleigh Hall
%   Bozeman, MT 59717
%   emery.newlon@msu.montana.edu
%
% --------------------------------------------------------------------------
%   Open the VHDL message control header file.

package_name    = 'gps_message_ctl' ;


vhd_file_name   = sprintf ('%s_pkg.vhd', package_name) ;
vhdfile         = fopen (vhd_file_name, 'w') ;

%   Write out the VHD file header.

fprintf (vhdfile, '--! GPS Message Control Definitions.\n') ;
fprintf (vhdfile, '--! Definitions for the GPS messages.\n\n') ;
fprintf (vhdfile, 'library IEEE ;\n') ;
fprintf (vhdfile, 'use IEEE.STD_LOGIC_1164.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.NUMERIC_STD.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.MATH_REAL.ALL ;\n\n') ;
fprintf (vhdfile, 'LIBRARY GENERAL ;\n') ;
fprintf (vhdfile, 'USE GENERAL.UTILITIES_PKG.ALL ;\n') ;
fprintf (vhdfile, 'USE GENERAL.GPS_CLOCK_PKG.ALL ;\n\n') ;

fprintf (vhdfile, 'package %s_pkg is\n\n', package_name) ;

%   Define message constants.

fprintf (vhdfile,                                                       ...
         '--  Two banks of RAM allow there to always (except at\n') ;
fprintf (vhdfile,                                                       ...
         '--  startup) be a valid set of message data.  If only\n') ;
fprintf (vhdfile,                                                       ...
         '--  one bank is used it is marked as valid or not.\n\n') ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_ram_banks_c', 2) ;

fprintf (vhdfile, '\n--  Memory block information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_count_c', msg_info (5)) ;
fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_count_bits_c') ;
fprintf (vhdfile,                                                       ...
         '      natural (trunc (log2 (real (msg_count_c)))) + 1 ;\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',               ...
         'msg_id_tbl_c', romseg_addr (3)) ;

fprintf (vhdfile, 'constant %-30s : natural := 0 ;\n',                  ...
         'msg_rom_base_c') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_ram_base_c', msg_info (1)) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_ram_blocks_c', msg_info (3)) ;
fprintf (vhdfile, 'constant %-30s : natural := %u * %s ;\n',            ...
         'msg_ram_temp_addr_c', msg_info (2), 'msg_ram_banks_c') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',               ...
         'msg_ram_temp_size_c', msg_info (4)) ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_ram_postime_addr_c') ;
fprintf (vhdfile, '      %s + %s * %s ;\n',                             ...
         'msg_ram_temp_addr_c', 'msg_ram_temp_size_c', 'msg_ram_banks_c') ;
fprintf (vhdfile, 'constant %-30s : natural := gps_time_bytes_c ;\n\n', ...
         'msg_ram_postime_size_c') ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_ram_marktime_addr_c') ;
fprintf (vhdfile, '      %s + %s * %s ;\n',                             ...
         'msg_ram_postime_addr_c', 'msg_ram_postime_size_c',            ...
         'msg_ram_banks_c') ;
fprintf (vhdfile, 'constant %-30s : natural := gps_time_bytes_c ;\n\n', ...
         'msg_ram_marktime_size_c') ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_ram_pulsetime_addr_c') ;
fprintf (vhdfile, '      %s + %s * %s ;\n',                             ...
         'msg_ram_marktime_addr_c', 'msg_ram_marktime_size_c',          ...
         'msg_ram_banks_c') ;
fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_ram_pulsetime_size_c') ;
fprintf (vhdfile, '      2 * gps_time_bytes_c ;\n\n') ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_ram_msgbuff_addr_c') ;
fprintf (vhdfile, '      %s + %s * %s ;\n',                             ...
         'msg_ram_pulsetime_addr_c', 'msg_ram_pulsetime_size_c',        ...
         'msg_ram_banks_c') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',               ...
         'msg_ram_msgbuff_size_c', msg_info (7)) ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_ram_end_c' ) ;
fprintf (vhdfile,                                                       ...
         '      msg_ram_msgbuff_addr_c + msg_ram_msgbuff_size_c ;\n' ) ;

fprintf (vhdfile, '\n--  Field extraction information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_extract_tree_c', romseg_addr (1)) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_tree_offset_bits_c', fix (log2 (offset_max)) + 1) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_extract_lookup_c', romseg_addr (2)) ;

bit_width  = fix (log2 (single (max (msg_addrs)))) + 1 ;
byte_width = fix ((bit_width - 1) / 8) + 1 ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_extract_lookup_bytes_c', byte_width) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_extract_overhead_c', 1) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         'msg_field_count_c', msg_info (6)) ;
fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_field_bits_c') ;
fprintf (vhdfile,                                                       ...
         '      natural (trunc (log2 (real (%s - 1)))) + 1 ;\n',        ...
         'msg_field_count_c') ;

fprintf (vhdfile, '\n--  Initialization information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : integer_vector :=\n(\n',            ...
         'msg_init_table_c') ;

for ii = 4 : length (romseg_addr)
  fprintf (vhdfile, '    %u', romseg_addr (ii)) ;

  if (ii < length (romseg_addr))
    fprintf (vhdfile, ',\n') ;
  else
    fprintf (vhdfile, '\n') ;
  end
end

fprintf (vhdfile, ') ;\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural :=\n',                      ...
         'msg_init_bits_c') ;
fprintf (vhdfile,                                                       ...
         '      natural (trunc (log2 (real (%s''length - 1)))) + 1 ;\n',  ...
         'msg_init_table_c') ;

fprintf (vhdfile, '\n--  Field encoder information.\n\n') ;
fprintf (vhdfile,                                                       ...
         'constant %-30s : natural := %u ;    -- High bits.\n',         ...
         'msg_size_bits_c', 7) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;    -- Low bit.\n',  ...
         'msg_store_flag_c', 1) ;

fprintf (vhdfile, '\n--  Message prototols.\n\n') ;
fprintf (vhdfile,                                                       ...
         'constant %-30s : std_logic_vector (7 downto 0) :=\n',         ...
         'msg_ubx_sync_1_c') ;
fprintf (vhdfile, '                                    x"B5" ;\n') ;
fprintf (vhdfile,                                                       ...
         'constant %-30s : std_logic_vector (7 downto 0) :=\n',         ...
         'msg_ubx_sync_2_c') ;
fprintf (vhdfile, '                                    x"62" ;\n') ;

fprintf (vhdfile, '\n--  UBX protocol message classes.\n\n') ;
fprintf (vhdfile,                                                       ...
         'constant %-30s : std_logic_vector (7 downto 0) :=\n',         ...
         'msg_ubx_nav_c') ;
fprintf (vhdfile, '                                    x"01" ;\n') ;
fprintf (vhdfile,                                                       ...
         'constant %-30s : std_logic_vector (7 downto 0) :=\n',         ...
         'msg_ubx_tim_c') ;
fprintf (vhdfile, '                                    x"0D" ;\n') ;

fprintf (vhdfile, '\nend package %s_pkg ;\n', package_name) ;

fclose (vhdfile) ;
