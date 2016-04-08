# --------------------------------------------------------------------------
#
##  @file       set_vhdl_constants.tcl
#
#   @brief      Specify constants values via a VHDL package.
#   @details    A VHDL package is created with a list of constant
#               definitions in it for the constant names and values passed
#               into this script.  An extra set of library definitions can
#               be included in the file if a 'package'.hdr file exists
#               that contains these library specification lines.
#   @author     Emery Newlon
#   @date       August 2014
#   @copyright  Copyright (C) 2014 Ross K. Snider and Emery L. Newlon
#   @param[in]  packname    Name of the package to create.
#   @param[in]  constlist   List of constants to define.  Each list has:
#                           Name of the constant to define.
#                           The constant's type.
#                           Value of the constant to define.
#                           More constant definitions if desired.

#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   Emery Newlon
#   Electrical and Computer Engineering
#   Montana State University
#   610 Cobleigh Hall
#   Bozeman, MT 59717
#   emery.newlon@msu.montana.edu
#
# --------------------------------------------------------------------------

set arglist     $quartus(args)

set packname    [lindex $arglist 0]
set constlist   [lindex $arglist 1]

set chan [open "$packname.vhd" w]

#   Define the header.

puts -nonewline $chan "--------------------------------------"
puts            $chan "--------------------------------------"

puts $chan "--  Package to define constants in."

puts -nonewline $chan "--------------------------------------"
puts            $chan "--------------------------------------"

puts $chan ""
puts $chan "library IEEE ;"
puts $chan "use IEEE.STD_LOGIC_1164.ALL ;"
puts $chan "use IEEE.NUMERIC_STD.ALL ;"
puts $chan "use IEEE.MATH_REAL.ALL ;"

#   Include an extra header if there is one.

set hdrname "$packname.hdr"

if [file exists $hdrname] {
  set hdr  [open $hdrname r]

  puts $chan [read $hdr]

  close $hdr
}

#   Start the package.

puts $chan ""
puts $chan "package $packname is"
puts $chan ""

#   Define the constants.

foreach {constname typename constvalue} $constlist {

  puts $chan "  constant $constname : $typename := $constvalue ;"
}

#   End the package.

puts $chan ""
puts $chan "end package $packname ;"

close $chan
