function next_meminfo = gps_message_out (mif_file, start_meminfo, perm, m_name, m_id, m_prefix, m_info)
%GPS_MESSAGE_OUT  Output the gps message info to a MIF file and symbols to VHDL.
% usage next_meminfo = gps_message_out (mif_file, start_meminfo, perm, m_name, m_id, m_prefix, m_info)
%    next_meminfo = Next memory vector for [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSG_BUFF].
%        mif_file = File handle of the MIF file to add data to.
%   start_meminfo = Starting memory vector for [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSG_BUFF].
%            perm = The message data is store permanently if set otherwise it is temp.
%          m_name = Base name of the VHDL symbols file to write to (.vhd
%                   added to it.)  Also used as the name of message symbol.
%            m_id = Message class and identification number [class id].
%        m_prefix = Prefix string added to the start of each field constant.
%          m_info = Field definition cell array.  Each row defines a field and
%                   consists of the field name, the field length (in bytes, and
%                   the storage indicator (0 means not stored in memory).
%

%   Open the VHDL header file.

vhd_file_name   = sprintf ('%s.vhd', m_name) ;
vhdfile         = fopen (vhd_file_name, 'w') ;

message_name    = upper (m_name) ;
msg_overhead    = 1 ;

ram_temp_name   = 'MSG_RAM_TEMP' ;

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

fprintf (mif_file, '%-6u : %02X ;  --  Message %u, %u fields\n',              ...
         rom_addr + 0, length (m_info), msg_number, length (m_info)) ;

rom_addr        = rom_addr + msg_overhead ;

discard_store   = {'discard' 'store'} ;

ram_used        = 0 ;

for k = 1 : length (m_info)
  if (m_info {k, 3} == 1)
    ram_used    = ram_used + m_info {k, 2} ;
  end

  fprintf (mif_file, '%-6u : %02X ;  --  %-10s %3d bytes %s\n' ,          ...
           rom_addr, m_info {k, 2} * 2 + m_info {k, 3}, m_info {k, 1},    ...
           m_info {k, 2}, discard_store {m_info {k, 3} + 1}) ;

  rom_addr      = rom_addr + 1 ;
end

%   Write out the VHD file header.

fprintf (vhdfile, '--! %s Message Definitions.\n', m_name) ;
fprintf (vhdfile, '--! Definitons for the %s message and its fields.\n\n', ...
         m_name) ;
fprintf (vhdfile, 'library IEEE ;\n') ;
fprintf (vhdfile, 'use IEEE.STD_LOGIC_1164.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.NUMERIC_STD.ALL ;\n') ;
fprintf (vhdfile, 'use IEEE.MATH_REAL.ALL ;\n\n') ;
fprintf (vhdfile, 'library WORK ;\n') ;
fprintf (vhdfile, 'use WORK.gps_message_ctl.ALL ;\n\n') ;

fprintf (vhdfile, 'package %s is\n\n', m_name) ;

%   Define message constants.

message_class_name  = sprintf ('%s_CLASS',        message_name) ;
message_id_name     = sprintf ('%s_ID',           message_name) ;
message_number_name = sprintf ('%s_NUMBER',       message_name) ;
rom_addr_name       = sprintf ('%s_ROMADDR',      message_name) ;
ram_addr_name       = sprintf ('%s_RAMADDR',      message_name) ;
ram_used_name       = sprintf ('%s_RAMUSED',      message_name) ;
ram_block_name      = sprintf ('%s_RAMBLOCK',     message_name) ;
fieldcnt_name       = sprintf ('%s_FIELDCNT',     message_name) ;
fieldbits_name      = sprintf ('%s_FIELDBITS',    message_name) ;

fprintf (vhdfile, 'constant %-30s : natural := 16#%02X# ;\n',   ...
         message_class_name, m_id (1)) ;

fprintf (vhdfile, 'constant %-30s : natural := 16#%02X# ;\n',   ...
         message_id_name, m_id (2)) ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n\n',       ...
         message_number_name, msg_number) ;

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',         ...
         rom_addr_name, start_meminfo (1)) ;

if (ram_addr >= 0)
  fprintf (vhdfile, 'constant %-30s : natural := %u * %s ;\n',  ...
           ram_addr_name, ram_addr, 'MSG_RAM_BANKS') ;
end

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',         ...
         ram_used_name, ram_used) ;

if (ram_block >= 0)
  fprintf (vhdfile, 'constant %-30s : natural := %d ;\n',       ...
           ram_block_name, ram_block) ;
end

fprintf (vhdfile, 'constant %-30s : natural := %u ;\n',         ...
         fieldcnt_name, length (m_info)) ;

fprintf (vhdfile, 'constant %-30s : natural :=\n', fieldbits_name) ;
fprintf (vhdfile, '            natural (trunc (log2 (real (%s - 1)))) + 1 ;\n', ...
         fieldcnt_name) ;

fprintf (vhdfile, '\n--  Field Definitions.\n') ;

%   Define field constants.

offset          = 0 ;

for k = 1 : length (m_info)
  field_name    = m_info {k, 1} ;

  field_size    = sprintf ('%s_%s_SIZE',    m_prefix, field_name) ;
  field_offset  = sprintf ('%s_%s_OFFSET',  m_prefix, field_name) ;
  field_field   = sprintf ('%s_%s_FIELD',   m_prefix, field_name) ;
  field_id      = sprintf ('%s_%s_ID'   ,   m_prefix, field_name) ;
  field_numb    = sprintf ('%s_%s_NUMBER',  m_prefix, field_name) ;

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
           field_numb, 'MSG_FIELD_BITS') ;
  fprintf (vhdfile, '      TO_UNSIGNED (%s + %u, %s) ;\n',              ...
           field_field, fld_number, 'MSG_FIELD_BITS') ;

  if (m_info {k, 3} == 1)
    fprintf (vhdfile, 'constant %-20s : natural := %d ;\n',             ...
             field_offset, offset) ;
    offset      = offset + m_info {k, 2} ;
  end
end

fprintf (vhdfile, '\nend package %s ;\n', m_name) ;

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

next_meminfo    = [rom_addr ram_addr ram_block ram_temp msg_number fld_number msg_buff] ;
