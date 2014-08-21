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
