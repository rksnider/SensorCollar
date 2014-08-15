Quartus II
==========
This is where files are kept that support Quartus II projects.

The 'at_compile_start.tcl' script is run at compile time.  It uses the
'set_vhdl_constants.tcl' script store constant values into a VHDL
package containing timestamps for when the compile started and the
commit time of the source code used to compile the project.  This package
file is named 'compile_start_time_pkg.vhd' and must be added to the
project's files to be compiled properly.  The file 'commit_timestamp.log'
must exist in the project's directory for this script to work correctly.
It extracts an integer from this file and defines the commit time constant
with that value.

The 'set_tcl_compile_scripts.qsf' file contains global settings that must
be made in a project to cause the compile time scripts to be run.
Instructions for making these settings is included in that file.
