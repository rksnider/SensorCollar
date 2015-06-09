function byte_vector = byte_store (value, byte_count)
%BYTE_STORE   Store the given value in a vector of bytes.
% usage   byte_vector = byte_store (value, byte_count)
%         byte_vector = Vector of bytes containing the value.
%               value = Value to convert to a vector of byte values.
%          byte_count = The number of bytes to produce for the result.
%

vector    = zeros (1, byte_count) ;

signed    = (value < 0) ;

left      = fi (value, signed, byte_count * 8, 0) ;
low_byte  = fi (255, signed, byte_count * 8 , 0) ;

for ii = 1 : byte_count
  vector (ii) = double (bitand (left, low_byte)) ;
  left        = bitshift (left, -8) ;
end

byte_vector = vector ;
