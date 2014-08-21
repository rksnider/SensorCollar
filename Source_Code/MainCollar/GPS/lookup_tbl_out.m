function next_meminfo = lookup_tbl_out (miffile, start_meminfo, msg_addrs)
%LOOKUP_TBL_OUT  Output the msg extraction lookup table to a MIF file.
% usage next_meminfo = lookup_tbl_out (miffile, start_meminfo, msg_addrs)
%  next_meminfo = Memory information vector [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSG_BUFF] when done.
%       miffile = MIF file handle to write the ROM information to.
% start_meminfo = Memory information vector [ROM RAM RAM_BLOCK RAM_TEMP MSG FLD MSB_BUFF] at start.
%     msg_addrs = Addresses of the extraction fields in the ROM.
%

%   Determine node size.

bit_width  = fix (log2 (single (max (msg_addrs)))) + 1 ;
byte_width = fix ((bit_width - 1) / 8) + 1 ;

%   Write out the entries for message extraction addresses.

fprintf (miffile, '\n--  Message Extraction Addresses per Message Number.\n\n') ;

for kk = 0 : length (msg_addrs) - 1
  comment = sprintf ('  --  Message Number %-5u', kk) ;

  for nn = 0 : byte_width - 1
    addr_byte = fix (mod (single (msg_addrs (kk + 1)) / (256 ^ nn), 256)) ;

    fprintf (miffile, '%-6u : %02X ;%s\n',                        ...
             (start_meminfo (1) + kk * byte_width + nn), addr_byte, comment) ;
    comment   = '' ;
  end
end

next_meminfo      = start_meminfo ;
next_meminfo (1)  = next_meminfo (1) + length (msg_addrs) * byte_width ;
