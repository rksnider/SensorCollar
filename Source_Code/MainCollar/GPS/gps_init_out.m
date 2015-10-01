function next_meminfo = gps_init_out (mif_file, start_meminfo, eom, ...
                                      m_name, m_id, m_info)
%GPS_MESSAGE_OUT  Output the gps message init to MIF file.
% usage next_meminfo = gps_init_out (mif_file, start_meminfo, m_id, m_info)
%    next_meminfo = Next memory vector for
%                     [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSG_BUFF].
%        mif_file = File handle of the MIF file to add data to.
%   start_meminfo = Starting memory vector.  The same as next_meminfo.
%             eom = End of messages.  Set to 1 if this is the last message,
%                   else 0.
%          m_name = Name of the message.
%            m_id = Message class and identification number [class id].
%          m_info = Field definition cell array.  Each row defines a field
%                   and consists of the field name, the field length (in
%                   bytes), and the value to store in that field.
%

% --------------------------------------------------------------------------
%
%%  @file       gps_init_out.m
%   @brief      Output the GPS message initialization info to a MIF file.
%   @details    GPS message initialization packets are stored in a MIF
%               file.
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

rom_addr        = start_meminfo (1) ;
msg_buff        = start_meminfo (7) ;

%   Build a matrix containing the bytes to add to the MIF file.

message_mat = {'  --  Length' 0 ; '' 1} ;
mat_index   = 1 ;
tot_len     = 0 ;

sz = size (m_info) ;

for ii = 1 : sz (1)
  f_name    = sprintf ('  --  %s', m_info {ii, 1}) ;
  f_length  = m_info {ii, 2} ;
  f_value   = uint64 (m_info {ii, 3}) ;

  tot_len   = tot_len + f_length ;

  for jj = 0 : f_length - 1
    b_value = bitshift (bitand (f_value,                                ...
                                bitshift (uint64 (255), 8 * jj)),       ...
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
fprintf (mif_file, '%-6u : %02X ;  --  Payload Length\n', rom_addr + 2, ...
         bitand (uint64 (tot_len), uint64 (255))) ;
fprintf (mif_file, '%-6u : %02X ;\n', rom_addr + 3,                     ...
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

  b_value       = message_mat {mat_index, 2} ;

  if (b_value == 0 && zero_count > 0)
    zero_count  = zero_count + 1 ;
  elseif (b_value ~= 0 && nz_count > 0)
    nz_count    = nz_count + 1 ;
  elseif (mat_index == length (message_mat))
    nz_count    = nz_count + 1 ;
  end

  %   Write out the zero count to the MIF file.

  if ((mat_index == length (message_mat) || b_value ~= 0) && zero_count > 0)

    fprintf (mif_file, '%-6u : %02X ;  --  Following zero bytes\n',     ...
             rom_addr, zero_count) ;
    rom_addr      = rom_addr + 1 ;

    %   Write out the field comments to the MIF file.

    for ii = last_zero : last_zero + zero_count - 1
      if (length (message_mat {ii, 1}) > 0)
        fprintf (mif_file, '             %s\n', message_mat {ii, 1}) ;
      end
    end

    zero_count  = 0 ;
    last_nz     = mat_index ;
  end

  %   Write out the non-zero count and corresponding bytes to the MIF file.

  if ((mat_index == length (message_mat) || b_value == 0) && nz_count > 0)

    fprintf (mif_file, '%-6u : %02X ;  --  Following literal bytes\n',  ...
             rom_addr, 128 + nz_count) ;
    rom_addr      = rom_addr + 1 ;

    for ii = last_nz : last_nz + nz_count - 1
      fprintf (mif_file, '%-6u : %02X ;%s\n',                           ...
               rom_addr, message_mat {ii, 2}, message_mat {ii, 1}) ;
      rom_addr    = rom_addr + 1 ;
    end

    nz_count      = 0 ;
    last_zero     = mat_index ;
  end

  %   Update the counts.

  if (b_value == 0 && zero_count == 0)
    zero_count  = 1 ;
  elseif (b_value ~= 0 && nz_count == 0)
    nz_count    = 1 ;
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
