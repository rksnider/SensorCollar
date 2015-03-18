%-----------------------------------------------------------------
% All UBX messages.
%-----------------------------------------------------------------

ids        = [1 0] ;
msgs       = ones (length (ids), 2) .* 5 ;   % ACK
msgs (:,2) = ids ;
ubxtbl     = [msgs] ;
ids        = [48 50 80 51 16 49 2 10] ;
msgs       = ones (length (ids), 2) .* 11 ;  % AID
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [19 9 6 18 41 14 2 57 1 36 35 23 34 59 50 0 8 52 4 ...
              17 22 61 29 49 7 27] ;
msgs       = ones (length (ids), 2) .* 6 ;   % CFG
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [2 16] ;
msgs       = ones (length (ids), 2) .* 16 ;  % ESF
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [4 0 2 3 1] ;
msgs       = ones (length (ids), 2) .* 4  ;  % INF
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [11 9 2 6 7 33 8 4] ;
msgs       = ones (length (ids), 2) .* 10 ;  % MON
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [96 34 49 4 64 1 2 50 6 3 48 32 33 17 18] ;
msgs       = ones (length (ids), 2) .* 1  ;  % NAV
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [48 49 65 16 17 32] ;
msgs       = ones (length (ids), 2) .* 2  ;  % RXM
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;
ids        = [4 3 1 6] ;
msgs       = ones (length (ids), 2) .* 13 ;  % TIM
msgs (:,2) = ids ;
ubxtbl     = [ubxtbl ; msgs] ;

strtbl  = cell (1, length (ubxtbl)) ;
for k = 1 : length (ubxtbl)
  strtbl (k) = {char(ubxtbl (k,:))} ;
end

ubxtree = text_tree (strtbl) ;

%   Memory table

meminit = zeros (1, length (ubxtree) * 3, 'uint8') ;

for k = 0 : length (ubxtree) - 1
  value           = ubxtree (k+1) ;
  meminit (k*3+1) = uint8 (bitand (value, 255)) ;
  meminit (k*3+2) = uint8 (bitshift (bitand (value, 255*256), -8)) ;
  meminit (k*3+3) = uint8 (bitshift (bitand (value, 255*256*256), -16)) ;
end

%   Encoding shift multipliers.

enc_list_char   = 2 ^ 0  ;
enc_list_end    = 2 ^ 8 ;
enc_list_number = 2 ^ 9 ;
enc_list_offset = 2 ^ (fix (log2 (length (strtbl))) + 1 + 9) ;

%   Output the results.

for k = 0 : length (ubxtree) - 1
  value   = double (ubxtree (k+1)) ;

  charval = mod (value, enc_list_end) ;
  val     = fix (value / enc_list_end) ;
  endval  = mod (val, 2) ;
  val     = fix (val / 2) ;

  nummod  = enc_list_offset / enc_list_number ;
  numval  = mod (val, nummod) ;
  val     = fix (val / nummod) ;

  fprintf (1, '%3d: %06X bytes %02X %02X %02X, char %02X, end %u, val %3d, off %3d\n',  ...
           k+1, value, meminit (k*3+1), meminit (k*3+2), meminit (k*3+3), charval,      ...
           endval, numval, val) ;
end
