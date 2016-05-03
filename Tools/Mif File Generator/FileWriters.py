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

# Import the element tree library
import xml.etree.ElementTree as et

def RFXMLtoMIF (filename,fileoutput='output.mif',width=16,depth=256, \
                addr_radix='HEX', data_radix='HEX'):
    """
    This function creates a mif file out of an RF Studio generated file.  This 
    input file needs to be in XML format, which RF Studio does not provide.  
    The output of RF Studio needs to be processed before it used in this 
    function.
    
    Input -
           filename     - Name of the xml file to use
           fileoutput   - Name of the output file.  Default: output.mif
           width        - Data width  Default: 16
           depth        - Data depth  Default: 256
           addr_radix   - Address radix Default: hex (dec or hex supported)
           data_radix   - Data radix  Default: hex
    """
    
    # Create the element tree and find the root
    tree = et.parse(filename)
    root = tree.getroot()
    
    # Generate a mif file using the output name, write only.
    mif = open(fileoutput,'w')
    
    # Write the header of the mif file
    mif.write('DEPTH = ' + str(depth)+ ';\n')
    mif.write('WIDTH = ' + str(width)+ ';\n')
    mif.write('ADDRESS_RADIX = ' + str(addr_radix)+ ';\n')
    mif.write('DATA_RADIX = ' + str(data_radix)+ ';\n')
    mif.write('CONTENT'+ '\n')
    mif.write('BEGIN'+ '\n')
        
    # Create a line counter and a variable to hold all the lines
    cntr = 0
    lines = []
    line = ''
    
    # Iterate over the children of the root to pick out the address, description,
    # and value fields
    for c in root:
        # Check to see how the address radix should be formatted
        if addr_radix.upper() == 'DEC':
            line = str(cntr+1) + '\t:\t';
        elif addr_radix.upper() == 'HEX':
            line = hex(cntr+1)[2:].upper() + '\t:\t';
        for child in c:
            if child.tag == 'Address':
                line = line + child.text[2:]
            if child.tag == 'Value':
                line = line + child.text[2:] + '\t;\t'
            if child.tag == 'Description':
                line = line + '--' + child.text + '\n'
        lines.append(line)
        #mif.writelines(line)
        cntr+=1
    if addr_radix.upper() == 'HEX':
        mif.write('0\t:\t'+str(hex(cntr)[2:].upper()) + '\t;\t -- Number of registers to change\n')
    if addr_radix.upper() == 'DEC':
        mif.write('0\t:\t'+str(cntr) + '\t;\t -- Number of registers to change\n')
    mif.writelines(lines)
    mif.write('END;')
    mif.close()
    
def default_mif(fileoutput='output.mif',width=16,depth=256, 
                addr_radix='HEX', data_radix='HEX', default_val = 0000):
    """
    This function creates a mif file out of an RF Studio generated file.  This 
    input file needs to be in XML format, which RF Studio does not provide.  
    The output of RF Studio needs to be processed before it used in this 
    function.
    
    Input -
           fileoutput   - Name of the output file.  Default: output.mif
           width        - Data width  Default: 16
           depth        - Data depth  Default: 256
           addr_radix   - Address radix Default: hex (dec or hex supported)
           data_radix   - Data radix  Default: hex
           default_val  - Default value to put in registers  Default: '0000'
    """
    
    mif = open(fileoutput,'w')
    
    # Write the header of the mif file
    mif.write('DEPTH = ' + str(depth)+ ';\n')
    mif.write('WIDTH = ' + str(width)+ ';\n')
    mif.write('ADDRESS_RADIX = ' + str(addr_radix)+ ';\n')
    mif.write('DATA_RADIX = ' + str(data_radix)+ ';\n')
    mif.write('CONTENT'+ '\n')
    mif.write('BEGIN'+ '\n')
        
    # Create a line counter and a variable to hold all the lines
    lines = []
    line = '' 
    
    for i in range(0,depth):
        # Check to see how the address radix should be formatted
        if addr_radix.upper() == 'DEC':
            line = str(i) + '\t:\t' + str(default_val) + ';\n'
        elif addr_radix.upper() == 'HEX':
            line = hex(i)[2:].upper() + '\t:\t' + hex(default_val)[2:].upper() + ';\n'
        lines.append(line)

    mif.writelines(lines)
    mif.write('END;')
    mif.close()
    