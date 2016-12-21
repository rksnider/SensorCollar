# -*- coding: utf-8 -*-
"""
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Tyler B. Davis
Electrical and Computer Engineering
Montana State University
610 Cobleigh Hall
Bozeman, MT 59717
tyler.davis5@msu.montana.edu

"""

def read_mif(fname,min_bytes_out = 2):
    """
    This function reads a mif file, then returns a list of the correct radix and 
    the address/data values to write to the device.  It is assumed that the address
    and data constitute at least two bytes unless otherwise specified.
    
    Input: 
        name            - Name of the .mif file to read
        min_bytes_out   - Minimum number of bytes in the output
        
    Output:
        rlist - a list of the number of addresses to change, and the
                address/data values.  The address and data values are 
                returned as lists of bytes in string format.
    """
    
    # Open the file to be read in
    File = open (fname, 'r')
    
    # Create a list to hold the radix and bytes
    rlist = []
    
    # Define the various key characters in the mif files
    comment_char = '--'                 
    format_char = '='                   
    data_begin_char = ':'               
    data_end_char = ';'
    
    # Create a variable to store the data format from the .mif file
    data_format = ''
    
    # Loop through all the lines in the file
    for line in File.readlines():
        
        # For each line, find the locations (if they exists) of the various
        # key characters 
        pos = line.find(format_char)
        cpos = line.find(comment_char)
        dbpos = line.find(data_begin_char)
        depos = line.find(data_end_char)
        
        # If the formatting character is present and not in a comment, then 
        # we are in the header of the file where the format is specified
        if pos != -1 and (cpos == -1 or cpos > pos):
            
            # if the data radix format is found, set the variable
            if line[:pos].strip().upper() == 'DATA_RADIX':
                data_format = line[pos+1:depos].strip()
         
        # If there is no formatting character or it does appear in a comment, 
        # then we are in the payload section of the mif file.  If the payload 
        # line contains the data line delimiters, then it contains data
        elif dbpos != -1 and depos != -1:
            
            # If decimal
            if data_format == 'DEC':
                
                # Read the data from the line and backfill 0's 
                hex_val = hex(int(line[dbpos+1:depos].strip(),10))[2:].zfill(min_bytes_out*2)
                
                # Create a list of bytes from the hex value
                byte_list = ['0x' + hex_val[i:i+2].upper() for i in range(0,len(hex_val), 2)]
             
                # Append the byte list to the list of return values
                rlist.append(byte_list)
            
            # If hexidecimal
            elif data_format == 'HEX':
                
                # Read the data from the line and backfill 0's 
                hex_val = hex(int(line[dbpos+1:depos].strip(),16))[2:].zfill(min_bytes_out*2)
        
                # Create a list of bytes from the hex value
                byte_list = ['0x' + hex_val[i:i+2].upper() for i in range(0,len(hex_val), 2)]
                             
                # Append the byte list to the list of return values
                rlist.append(byte_list)
    
    # Close the file
    File.close()
    
    # Return the list of bytes
    return rlist