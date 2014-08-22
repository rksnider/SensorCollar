function next_meminfo = gps_message_out (mif_file, start_meminfo, perm, ...
                                         m_name, m_id, m_prefix, m_info)
%GPS_MESSAGE_OUT  Output the gps message info to a MIF and a VHDL file.
% usage next_meminfo = gps_message_out (mif_file, start_meminfo, perm,
%                                       m_name, m_id, m_prefix, m_info)
%    next_meminfo = Next memory vector for [ROM RAM RAM_BLOCK RAM_TEMP MSG
%                                           FLD MSG_BUFF].
%        mif_file = File handle of the MIF file to add data to.
%   start_meminfo = Starting memory vector for [ROM RAM RAM_BLOCK RAM_TEMP
%                                               MSG FLD MSG_BUFF].
%            perm = The message data is store permanently if set otherwise
%                   it is temp.
%          m_name = Base name of the VHDL symbols file to write to (.vhd
%                   added to it.)  Also used as the name of message symbol.
%            m_id = Message class and identification number [class id].
%        m_prefix = Prefix string added to the start of each field constant.
%          m_info = Field definition cell array.  Each row defines a field
%                   and consists of the field name, the field length (in
%                   bytes, and the storage indicator (0 means not stored in
%                   memory).
%

% --------------------------------------------------------------------------
%
%%  @file       gps_message_out.m
%   @brief      Output GPS message information to a MIF and a VHDL file.
%   @details    The MIF file contains parsing information while the VHDL
%               file contains information about fields in the memory
%               result.
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


%   Open the VHDL header file.

vhd_file_name   = sprintf ('%s_pkg.vhd', m_name) ;
vhdfile         = fopen (vhd_file_name, 'w') ;

message_name    = m_name ;      --  upper (m_name) ;
msg_overhead    = 1 ;

ram_temp_name   = 'msg_ram_temp_c' ;

rom_addr        = start_meminfo (1) ;
ram_temp        = start_meminfo (4) ;
msg_number      = start_meminfo (5) ;
fld_number      = start_meminfo (6) ;
msg_buff        = start_meminfo (7) ;

if (perm == 1)
  ram_addr      = start_meminfo (2) ;
  ram_block     = start_meminfo (3) ;
else
  ram_addr      = -1 ;
  ram_block     = -1 ;
end

%   Write out the message information to the MIF.

fprintf (mif_file, '\n--  Message %s\n\n', message_name) ;

fprintf (mif_file, '%-6u : %02X ;  --  Message %u, %u fields\n',        ...
         rom_addr + 0, length (m_info), msg_number, length (m_info)) ;

rom_addr        = rom_addr + msg_overhead ;

discard_store   = {'discard' 'store'} ;

ram_used        = 0 ;

for k = 1 : length (m_info)
  if (m_info {k, 3} == 1)
    ram_used    = ram_used + m_info {k, 2} ;
  end

  fprintf (mif_file, '%-6u : %02X ;  --  %-10s %3d bytes %s\n' ,        ...
           rom_addr, m_info {k, 2} * 2 + m_info {k, 3}, m_info {k, 1},  ...
           m_info {k, 2}, discard_store {m_info {k, 3} + 1}) ;

  rom_addr      = rom_addr + 1 ;
end

%   Write out the VHD file header.

fprintf (vhdfile, '--! %s Message Definitions.\n', m_name) ;
fprintf (vhdfile,                                                       ...
         '--! Definitons for the %s message and its fields.\n\n', m_name) ;
fprintf (vhdfile, 'library IEEE ;\n') ;
fprintf (vhdfile, 'use IEEE.STD_LOGIC_1164.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.NUMERIC_STD.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.MATH_REAL.ALL ;\n\n') ;
fprintf (vhdfile, 'library WORK ;\n') ;
fprintf (vhdfile, 'use WORK.gps_message_ctl_pkg.ALL ;\n\n') ;

fprintf (vhdfile, 'package %s_pkg is\n\n', m_name) ;

%   Define message constants.

message_class_name  = sprintf ('%s_class_c',        message_name) ;
message_id_name     = sprintf ('%s_id_c',           message_name) ;
message_number_name = sprintf ('%s_number_c',       message_name) ;
rom_addr_name       = sprintf ('%s_romaddr_c',      message_name) ;
ram_addr_name       = sprintf ('%s_ramaddr_c',      message_name) ;
ram_used_name       = sprintf ('%s_ramused_c',      message_name) ;
ram_block_name      = sprintf ('%s_ramblock_c',     message_name) ;
fieldcnt_name       = sprintf ('%s_fieldcnt_c',     message_name) ;
fieldbits_name      = sprintf ('%s_fieldbits_c',    message_name) ;

fprintf (vhdfile, 'constant %-30s : natural := 16#%02X# ;\n',           ...
         message_class_name, m_id (1)) ;

fprintf (vhdfile, 'constant %-30s : natural := 16#%02X# ;\n',           ...
         message_id_name, m_id (2)) ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',               ...
         message_number_name, msg_number) ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         rom_addr_name, start_meminfo (1)) ;

if (ram_addr >= 0)
  fprintf (vhdfile, 'constant %-30s : natural := %u * %s ;\n',          ...
           ram_addr_name, ram_addr, 'msg_ram_banks_c') ;
end

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         ram_used_name, ram_used) ;

if (ram_block >= 0)
  fprintf (vhdfile, 'constant %-30s : natural := %d ;\n',               ...
           ram_block_name, ram_block) ;
end

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',                 ...
         fieldcnt_name, length (m_info)) ;

fprintf (vhdfile, 'constant %-30s : natural :=\n', fieldbits_name) ;
fprintf (vhdfile,                                                       ...
         '            natural (trunc (log2 (real (%s - 1)))) + 1 ;\n',  ...
         fieldcnt_name) ;

fprintf (vhdfile, '\n--  Field Definitions.\n') ;

%   Define field constants.

offset          = 0 ;

for k = 1 : length (m_info)
  field_name    = m_info {k, 1} ;

  field_size    = sprintf ('%s_%s_size_c',    m_prefix, field_name) ;
  field_offset  = sprintf ('%s_%s_offset_c',  m_prefix, field_name) ;
  field_field   = sprintf ('%s_%s_field_c',   m_prefix, field_name) ;
  field_id      = sprintf ('%s_%s_id_c'   ,   m_prefix, field_name) ;
  field_numb    = sprintf ('%s_%s_number_c',  m_prefix, field_name) ;

  fprintf (vhdfile, '\n') ;
  fprintf (vhdfile, 'constant %-20s : natural := %d ;\n',               ...
           field_size, m_info {k, 2}) ;
  fprintf (vhdfile, 'constant %-20s : natural := %d ;\n',               ...
           field_field, k - 1) ;
  fprintf (vhdfile, 'constant %-20s : unsigned (%s-1 downto 0) :=\n',   ...
           field_id, fieldbits_name) ;
  fprintf (vhdfile, '      TO_UNSIGNED (%s, %s) ;\n',                   ...
           field_field, fieldbits_name) ;
  fprintf (vhdfile, 'constant %-20s : unsigned (%s-1 downto 0) :=\n',   ...
           field_numb, 'msg_field_bits_c') ;
  fprintf (vhdfile, '      TO_UNSIGNED (%s + %u, %s) ;\n',              ...
           field_field, fld_number, 'msg_field_bits_c') ;

  if (m_info {k, 3} == 1)
    fprintf (vhdfile, 'constant %-20s : natural := %d ;\n',             ...
             field_offset, offset) ;
    offset      = offset + m_info {k, 2} ;
  end
end

fprintf (vhdfile, '\nend package %s_pkg ;\n', m_name) ;

fclose  (vhdfile) ;

if (perm == 1)
  ram_addr      = ram_addr + ram_used ;
  ram_block     = ram_block + 1 ;
else
  ram_addr      = start_meminfo (2) ;
  ram_block     = start_meminfo (3) ;
end

if (ram_used > ram_temp)
  ram_temp      = ram_used ;
end

msg_number      = msg_number + 1 ;
fld_number      = fld_number + length (m_info) ;

next_meminfo    = [rom_addr ram_addr ram_block ram_temp msg_number      ...
                   fld_number msg_buff] ;
