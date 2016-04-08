# --------------------------------------------------------------------------
##  @file       at_compile_start.tcl
#   @brief      Script to be run at the start of a VHDL compile
#   @details    This script runs other scripts that prepare for a VHDL
#               compile right before it is done.
#   @author     Emery Newlon
#   @date       August 2014
#   @copyright  Copyright (C) 2014 Ross K. Snider and Emery L. Newlon

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

#   Put the commit time and the current time into a package.

set chan      [open commit_timestamp.log r]
set commit    [gets $chan]
close $chan

set now       [clock seconds]

exec quartus_sh -t set_vhdl_constants.tcl compile_start_time_pkg \
                [list compile_timestamp_c natural $now \
                      commit_timestamp_c  natural $commit]

#   Put the values shared by the source and SDC files into a package.

source sdc_values.tcl

exec quartus_sh -t set_vhdl_constants.tcl shared_sdc_values_pkg \
                $sdc_value_list
               