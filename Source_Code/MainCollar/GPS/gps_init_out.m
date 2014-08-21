function next_meminfo = gps_init_out (mif_file, start_meminfo, eom, m_name, m_id, m_info)
%GPS_MESSAGE_OUT  Output the gps message init to a MIF file and symbols to VHDL.
% usage next_meminfo = gps_init_out (mif_file, start_meminfo, m_id, m_info)
%    next_meminfo = Next memory vector for
%                     [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSG_BUFF].
%        mif_file = File handle of the MIF file to add data to.
%   start_meminfo = Starting memory vector.  The same as next_meminfo.
%             eom = End of messages.  Set to 1 if this is the last message, else 0.
%          m_name = Name of the message.
%            m_id = Message class and identification number [class id].
%          m_info = Field definition cell array.  Each row defines a field and
%                   consists of the field name, the field length (in bytes), and
%                   the value to store in that field.
%

rom_addr        = start_meminfo (1) ;
msg_buff        = start_meminfo (7) ;

%   Build a matrix containing the bytes to add to the MIF file.

message_mat = {'  --  Length' 0 ; '' 1} ;
mat_index   = 1 ;
tot_len     = 0 ;

for ii = 1 : length (m_info)
  f_name    = sprintf ('  --  %s', m_info {ii, 1}) ;
  f_length  = m_info {ii, 2} ;
  f_value   = uint64 (m_info {ii, 3}) ;

  tot_len   = tot_len + f_length ;

  for jj = 0 : f_length - 1
    b_value = bitshift (bitand (f_value,                                      ...
                                bitshift (uint64 (255), 8 * jj)),             ...
                        -8 * jj) ;

    message_mat {mat_index, 1}  = f_name ;
    message_mat {mat_index, 2}  = b_value ;
    mat_index                   = mat_index + 1 ;
    f_name                      = '' ;
  end
end

if (tot_len > msg_buff)
  msg_buff  = tot_len ;
end

%   Write out the message information to the MIF.

fprintf (mif_file, '\n--  Init Message %s\n\n', m_name) ;

fprintf (mif_file, '%-6u : %02X ;  --  Class\n',  rom_addr + 0, m_id (1)) ;
fprintf (mif_file, '%-6u : %02X ;  --  ID\n',     rom_addr + 1, m_id (2)) ;
fprintf (mif_file, '%-6u : %02X ;  --  Payload Length\n', rom_addr + 2,       ...
         bitand (uint64 (tot_len), uint64 (255))) ;
fprintf (mif_file, '%-6u : %02X ;\n', rom_addr + 3,                           ...
         bitshift (bitand (uint64 (tot_len), uint64 (255 * 256)), -8)) ;

rom_addr        = rom_addr + 4 ;

%   Count zero and non-zero bytes and place a count byte first.
%   All non-zero bytes are counted first, then the number of zero bytes is
%   summed.  If only one zero byte is found before the next non-zero byte
%   it is included in the non-zero bytes.  Once a non-zero byte has been
%   found after a series of zero bytes the byte information (both non-zero
%   and zero) is written to the MIF file.

zero_count      = 0 ;
nz_count        = 0 ;

last_zero       = 1 ;
last_nz         = 1 ;

for mat_index   = 1 : length (message_mat)

  b_value       = mat_message {mat_index, 2} ;

  if (b_value == 0 && zero_count > 0)
    zero_count  = zero_count + 1 ;
  else if (b_value ~= 0 && nz_count > 0)
    nz_count    = nz_count + 1 ;
  else if (mat_index == length (message_mate))
    nz_count    = nz_count + 1 ;
  end

  %   Write out the zero count to the MIF file.

  if ((mat_index == length (message_mat) || b_value ~= 0) && zero_count > 0)

    fprintf (mif_file, '%-6u : %02X ;  --  Following zero bytes\n',       ...
             rom_addr, zero_count) ;
    rom_addr      = rom_addr + 1 ;

    %   Write out the field comments to the MIF file.

    for ii = last_zero : last_zero + zero_count - 1
      if (length (mat_message {ii, 1}) > 0)
        fprintf (mif_file, '             %s\n', mat_message {ii, 1}) ;
      end
    end

    zero_count  = 0 ;

    if (b_value ~= 0)
      nz_count  = 1 ;
      last_nz   = mat_index ;
    end
  end

  %   Write out the non-zero count and corresponding bytes to the MIF file.

  if ((mat_index == length (message_mat) || bvalue == 0) && nz_count > 0)

    fprintf (mif_file, '%-6u : %02X ;  --  Following litteral bytes\n',   ...
             rom_addr, 128 + nz_count) ;
    rom_addr      = rom_addr + 1 ;

    for ii = last_nz : last_nz + nz_count - 1
      fprintf (mif_file, '%-6u : %02X ;%s\n',                             ...
               rom_addr, mat_message {ii, 2}, mat_message {ii, 1}) ;
      rom_addr    = rom_addr + 1 ;
    end

    nz_count      = 0 ;

    if (bvalue == 0)
      zero_count  = 1 ;
      last_zero   = mat_index ;
    end
  end
end

%   Terminate the message with a 128 byte or all messages with a zero.

if (eom == 0)
  byte_value      = 128 ;
  comment         = '  --  End of message' ;
else
  byte_value      = 0 ;
  comment         = '  --  End of all messages' ;
end

fprintf (mif_file, '%-6u : %02x ;%s\n', rom_addr, byte_value, comment) ;
rom_addr          = rom_addr + 1 ;

%   Return the updated information.

next_meminfo      = start_meminfo ;
next_meminfo (1)  = rom_addr ;
next_meminfo (7)  = msg_buff ;
