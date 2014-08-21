function naddr = text_tree_out (miffile, saddr, text_tree, string_count)
%TEXT_TREE_OUT  Output the text tree nodes to a MIF file.
% usage naddr = text_tree_out (miffile, out_file, saddr, text_tree, string_count)
%         naddr = Next address in the MIF file after this function has run.
%       miffile = MIF file handle to write the ROM information to.
%         saddr = Address in the MIF file to start writing data at.
%     text_tree = Vector of uint32 text tree node values.
%  string_count = Number of strings forming the tree.
%

%   Determine node size.

bit_width  = fix (log2 (single (max (text_tree)))) + 1 ;
byte_width = fix ((bit_width - 1) / 8) + 1 ;

strno_mult = 2 ^ (fix (log2 (string_count)) + 1) ;

%   Write out the entries for tree nodes.

next_last     = { '+' '!' } ;

fprintf (miffile, '\n--  Text Tree Nodes.\n\n') ;

for kk = 0 : length (text_tree) - 1
  node_value  = single (text_tree (kk + 1)) ;
  node_char   = fix (mod (node_value, 256)) ;

  if (node_char < 32 || node_char > 126)
    node_str  = sprintf ('$%02X', node_char) ;
  else
    node_str  = char (node_char) ;
  end

  node_end    = next_last {fix (mod (node_value / 256, 2)) + 1} ;
  node_strno  = fix (mod (node_value / 512, strno_mult)) ;
  node_offset = fix (node_value / (strno_mult * 512)) ;

  if (node_strno < string_count)
    node_string = sprintf (', string %u', node_strno) ;
  else
    node_string = '' ;
  end

  comment = sprintf ('  --  "%s" %s %u offset%s',        ...
                     node_str, node_end, node_offset, node_string) ;

  for nn = 0 : byte_width - 1
    node_byte = fix (mod (single (text_tree (kk + 1)) / (256 ^ nn), 256)) ;

    fprintf (miffile, '%-6u : %02X ;%s\n',                        ...
             (saddr + kk * byte_width + nn), node_byte, comment) ;
    comment   = '' ;
  end
end

naddr = saddr + length (text_tree) * byte_width ;
