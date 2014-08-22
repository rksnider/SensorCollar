function next_meminfo = lookup_tbl_out (miffile, start_meminfo, msg_addrs)
%LOOKUP_TBL_OUT  Output the msg extraction lookup table to a MIF file.
% usage next_meminfo = lookup_tbl_out (miffile, start_meminfo, msg_addrs)
%  next_meminfo = Memory information vector [ROM RAM RAM_BLOCK RAM_TEMP MSG
%                                            FLD MSG_BUFF] when done.
%       miffile = MIF file handle to write the ROM information to.
% start_meminfo = Memory information vector [ROM RAM RAM_BLOCK RAM_TEMP MSG
%                                            FLD MSB_BUFF] at start.
%     msg_addrs = Addresses of the extraction fields in the ROM.
%

% --------------------------------------------------------------------------
%
%%  @file       lookup_tbl_out.m
%   @brief      Output the contents of a string lookup table to a MIF file.
%   @details    A lookup table is in the form of lists of nodes, each for
%               a character and with a list of nodes that might follow
%               that character.
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


%   Determine node size.

bit_width  = fix (log2 (single (max (msg_addrs)))) + 1 ;
byte_width = fix ((bit_width - 1) / 8) + 1 ;

%   Write out the entries for message extraction addresses.

fprintf (miffile,                                                       ...
         '\n--  Message Extraction Addresses per Message Number.\n\n') ;

for kk = 0 : length (msg_addrs) - 1
  comment = sprintf ('  --  Message Number %-5u', kk) ;

  for nn = 0 : byte_width - 1
    addr_byte = fix (mod (single (msg_addrs (kk + 1)) / (256 ^ nn), 256)) ;

    fprintf (miffile, '%-6u : %02X ;%s\n',                              ...
             (start_meminfo (1) + kk * byte_width + nn), addr_byte,     ...
             comment) ;
    comment   = '' ;
  end
end

next_meminfo      = start_meminfo ;
next_meminfo (1)  = next_meminfo (1) + length (msg_addrs) * byte_width ;
