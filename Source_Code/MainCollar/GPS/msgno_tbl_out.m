function next_meminfo = msgno_tbl_out (miffile, start_meminfo, msg_ids)
%MSGNO_TBL_OUT  Output the message number to Class/ID table to a MIF file.
% usage next_meminfo = msgno_tbl_out (miffile, start_meminfo, msg_ids)
%  next_meminfo = Memory information vector when done.
%       miffile = MIF file handle to write the ROM information to.
% start_meminfo = Memory information vector at start.
%       msg_ids = Class/IDs of the message information in the ROM.
%

% --------------------------------------------------------------------------
%
%%  @file       msgno_tbl_out.m
%   @brief      Output the message number to Class/ID table to a MIF file.
%   @details    A Translation table that converts message numbers to Class
%               numbers and ID numbers used to identify UBX messages is
%               stored in a section of a MIF file.
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


%   Write out the entries for message number to UBX message Class/ID.

fprintf (miffile, '\n--  Message Number to UBX Class/ID Translation.\n\n') ;

for kk = 0 : 2 : length (msg_ids) - 1

  fprintf (miffile, '%-6u : %02X ;  --  Message Number %-5u\n',   ...
           start_meminfo (1) + kk, msg_ids (kk + 1), kk / 2) ;
  fprintf (miffile, '%-6u : %02X ;\n',                            ...
           start_meminfo (1) + kk + 1, msg_ids (kk + 2)) ;

end

next_meminfo      = start_meminfo ;
next_meminfo (1)  = next_meminfo (1) + length (msg_ids) ;
