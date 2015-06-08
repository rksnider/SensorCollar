function checksum_vector = calc_checksum (message)
%CALC_CHECKSUM  Calculate two checksum bytes for the UBX message.
% usage checksum_vector = calc_checksum (message)
%       checksum_vector = Vector of two byte checksum.
%               message = Message vector to calculate the checksum for.
%

ck_a      = 0 ;
ck_b      = 0 ;

for ii = 1 : length (message)
  ck_a    = bitand (ck_a + message (ii), 255) ;
  ck_b    = bitand (ck_b + ck_a, 255) ;
end

checksum_vector = [ck_a ck_b] ;
