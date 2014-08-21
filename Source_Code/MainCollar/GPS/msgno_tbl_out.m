function next_meminfo = msgno_tbl_out (miffile, start_meminfo, msg_ids)
%MSGNO_TBL_OUT  Output the message number to Class/ID table to a MIF file.
% usage next_meminfo = msgno_tbl_out (miffile, start_meminfo, msg_ids)
%  next_meminfo = Memory information vector when done.
%       miffile = MIF file handle to write the ROM information to.
% start_meminfo = Memory information vector at start.
%       msg_ids = Class/IDs of the message information in the ROM.
%

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
