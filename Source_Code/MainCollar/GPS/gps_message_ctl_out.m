function gps_message_ctl_out (msg_info, romseg_addr, offset_max, msg_addrs, mem_bytes)
%GPS_MESSAGE_CTL_OUT  Output the gps message control info to symbols in a VHDL file.
% usage gps_message_ctl_out (msg_info, tree_addr, lookup_addr)
%      msg_info = Memory vector for [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSG_BUFF].
%   romseg_addr = Address start vector of ROM segments.
%    offset_max = Maximum offset value in any tree node.
%     msg_addrs = Addresses of the extraction fields in the ROM.
%     mem_bytes = Total number of bytes of memory in a memory allocation unit.
%

%   Open the VHDL message control header file.

package_name    = 'gps_message_ctl' ;


vhd_file_name   = sprintf ('%s.vhd', package_name) ;
vhdfile         = fopen (vhd_file_name, 'w') ;

%   Write out the VHD file header.

fprintf (vhdfile, '--! GPS Message Control Definitions.\n') ;
fprintf (vhdfile, '--! Definitions for the GPS messages.\n\n') ;
fprintf (vhdfile, 'library IEEE ;\n') ;
fprintf (vhdfile, 'use IEEE.STD_LOGIC_1164.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.NUMERIC_STD.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.MATH_REAL.ALL ;\n\n') ;
fprintf (vhdfile, 'LIBRARY WORK ;\n') ;
fprintf (vhdfile, 'USE WORK.GPS_CLOCK.ALL ;\n\n') ;

fprintf (vhdfile, 'package %s is\n\n', package_name) ;

%   Define message constants.

fprintf (vhdfile, '--  Two banks of RAM allow there to always (except at\n') ;
fprintf (vhdfile, '--  startup) be a valid set of message data.  If only\n') ;
fprintf (vhdfile, '--  one bank is used it is marked as valid or not.\n\n') ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_RAM_BANKS', 2) ;

fprintf (vhdfile, '\n--  Memory block information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_COUNT', msg_info (5)) ;
fprintf (vhdfile, 'constant %-30s : natural :=\n',                          ...
         'MSG_COUNT_BITS') ;
fprintf (vhdfile, '      natural (trunc (log2 (real (MSG_COUNT)))) + 1 ;\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',                   ...
         'MSG_ID_TBL', romseg_addr (3)) ;

fprintf (vhdfile, 'constant %-30s : natural := 0 ;\n',                      ...
         'MSG_ROM_BASE') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_RAM_BASE', msg_info (1)) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_RAM_BLOCKS', msg_info (3)) ;
fprintf (vhdfile, 'constant %-30s : natural := %u * %s ;\n',                ...
         'MSG_RAM_TEMP_ADDR', msg_info (2), 'MSG_RAM_BANKS') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',                   ...
         'MSG_RAM_TEMP_SIZE', msg_info (4)) ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                          ...
         'MSG_RAM_POSTIME_ADDR') ;
fprintf (vhdfile, '      %s + %s * %s ;\n',                                 ...
         'MSG_RAM_TEMP_ADDR', 'MSG_RAM_TEMP_SIZE', 'MSG_RAM_BANKS') ;
fprintf (vhdfile, 'constant %-30s : natural := GPS_TIME_BYTES ;\n\n',       ...
         'MSG_RAM_POSTIME_SIZE') ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                          ...
         'MSG_RAM_MARKTIME_ADDR') ;
fprintf (vhdfile, '      %s + %s * %s ;\n',                                 ...
         'MSG_RAM_POSTIME_ADDR', 'MSG_RAM_POSTIME_SIZE', 'MSG_RAM_BANKS') ;
fprintf (vhdfile, 'constant %-30s : natural := GPS_TIME_BYTES ;\n\n',       ...
         'MSG_RAM_MARKTIME_SIZE') ;

fprintf (vhdfile, 'contant %-30s : natural :=\n',                           ...
         'MSG_RAM_MSGBUFF_ADDR') ;
fprintf (vhdfile, '      %s + %s ;\n',                                      ...
         'MSG_RAM_MARKTIME_ADDR', 'MSG_RAM_MARKTIME_SIZE') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',                   ...
         'MSG_RAM_MSGBUFF_SIZE', msg_info (7)) ;

fprintf (vhdfile, 'constant %-30s : natural :=\n',                          ...
         'MSG_RAM_END' ) ;
fprintf (vhdfile, '      MSG_RAM_MSGBUFF_ADDR + MSG_RAM_MSGBUFF_SIZE ;\n' ) ;

fprintf (vhdfile, '\n--  Field extraction information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_EXTRACT_TREE', romseg_addr (1)) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_TREE_OFFSET_BITS', fix (log2 (offset_max)) + 1) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_EXTRACT_LOOKUP', romseg_addr (2)) ;

bit_width  = fix (log2 (single (max (msg_addrs)))) + 1 ;
byte_width = fix ((bit_width - 1) / 8) + 1 ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_EXTRACT_LOOKUP_BYTES', byte_width) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_EXTRACT_OVERHEAD', 1) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_FIELD_COUNT', msg_info (6)) ;
fprintf (vhdfile, 'constant %-30s : natural :=\n',                          ...
         'MSG_FIELD_BITS') ;
fprintf (vhdfile, '      natural (trunc (log2 (real (%s - 1)))) + 1 ;\n',   ...
         'MSG_FIELD_COUNT') ;

fprintf (vhdfile, '\n--  Initialization information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                     ...
         'MSG_INIT_TABLE', romseg_addr (4)) ;

fprintf (vhdfile, '\n--  Field encoder information.\n\n') ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;    -- High bits.\n',    ...
         'MSG_SIZE_BITS', 7) ;
fprintf (vhdfile, 'constant %-30s : natural := %u ;    -- Low bit.\n',      ...
         'MSG_STORE_FLAG', 1) ;

fprintf (vhdfile, '\n--  Message prototols.\n\n') ;
fprintf (vhdfile,                                                           ...
         'constant %-30s : std_logic_vector (7 downto 0) := %s ;\n',        ...
         'MSG_UBX_SYNC_1', 'x"B5"') ;
fprintf (vhdfile,                                                           ...
         'constant %-30s : std_logic_vector (7 downto 0) := %s ;\n',        ...
         'MSG_UBX_SYNC_2', 'x"62"') ;

fprintf (vhdfile, '\n--  UBX protocol message classes.\n\n') ;
fprintf (vhdfile,                                                           ...
         'constant %-30s : std_logic_vector (7 downto 0) := %s ;\n',        ...
         'MSG_UBX_NAV', 'x"01"') ;
fprintf (vhdfile,                                                           ...
         'constant %-30s : std_logic_vector (7 downto 0) := %s ;\n',        ...
         'MSG_UBX_TIM', 'x"0D"') ;

fprintf (vhdfile, '\nend package %s ;\n', package_name) ;

fclose (vhdfile) ;
