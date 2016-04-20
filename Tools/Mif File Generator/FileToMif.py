# -*- coding: utf-8 -*-
"""
This file reads in an XML document created from excel based on the HTML output
from RF Studio

"""

# Import the filewriter python script
import FileWriters as fw

# Designate the path to the file
path = 'CC1120HTMLFiles/'

# Designate the filename
filename = 'CC1120_440p2_Config_XL.xml'

# Set the various values for the mif file
depth       = 256 
width       = 24 
addr_radix  = 'HEX' 
data_radix  = 'HEX' 
outputfile  = 'test.mif'

# Call the file writer and the appropriate function to create a mif file
# fw.RFXMLtoMIF(filename,outputfile,width,depth,addr_radix, data_radix)


# Set the various values for the mif file
depth       = 256 
width       = 8 
addr_radix  = 'HEX' 
data_radix  = 'HEX' 
outputfile  = 'default.mif'
default_val = 201

fw.default_mif(outputfile,width,depth,addr_radix, data_radix,default_val)