% --------------------------------------------------------------------------
%
%%  @file       gps_message_ROM_out.m
%   @brief      Write out the GPS Message Parsing MIF file.
%   @details    The GPS Message Parsing MIF file contains informatin used
%               in parsing GPS Messages and transfering the data extracted
%               into memory.
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

miffile = fopen ('message_ROM.mif', 'w') ;

%   Write out the MIF file header.

fprintf (miffile, 'DEPTH = ') ;
depth_pos = ftell (miffile) ;
fprintf (miffile, '000000 ;\n') ;

fprintf (miffile, 'WIDTH = 8 ;\n') ;
fprintf (miffile, 'ADDRESS_RADIX = DEC ;\n') ;
fprintf (miffile, 'DATA_RADIX = HEX ;\n') ;
fprintf (miffile, 'CONTENT\n') ;
fprintf (miffile, 'BEGIN\n') ;

%   Memory allocatin size.

mem_bytes       = 1024 ;

%   Write out the ROM data.

mem_info        = zeros (1, 7) ;

mem_info        = gps_message_defs (miffile, mem_info, mem_bytes) ;

%   Terminate the MIF file but update the number of bytes in it first.

line = ['END ;'] ;
fprintf (miffile, '\n%s\n', line) ;

fseek (miffile, depth_pos, 'bof') ;
fprintf (miffile, '%6u', mem_info (1)) ;

fclose  (miffile) ;
