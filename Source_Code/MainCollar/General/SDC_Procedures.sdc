##
#   @file       SDC_Procedures.sdc
#   @brief      Find the clocks feeding a pin
#   @details    SDC procedure to find all clocks feeding a given pin.
#   @date       April 2015
#   @copyright  Copyright (C) 2015 Ross K. Snider and Emery L. Newlon

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

##
#   @brief    Push and pop instances onto and off of the instance stack.
#   @details  The instance stack contains the SDC instance specifications
#             of all instances that are part of the current instance.
#
#   @param    instance    Type and instance name of the new instance.
#

proc push_instance { instance } {
  global instance_stack

  if { 1 != [info exists instance_stack]} {
    set instance_stack          [list]
  }

  set instance_stack            [linsert $instance_stack 0 $instance]
}

proc pop_instance {} {
  global instance_stack

  set instance_stack            [lreplace $instance_stack 0 0]
}

proc get_instance {} {
  global instance_stack

  return [lindex $instance_stack 0]
}


##
#   @brief    Set the instance value for a key in the current instance.
#   @details  The given key is added to the current instance name to form
#             a key that is assigned the given value.
#
#   @param    key         The key in current instance to set the value of.
#   @param    value       The value to set for the key.
#

proc set_instvalue { key value } {
  global instance_stack
  global inst_mapping

  set cur_instance              [lindex $instance_stack 0]
  set full_key                  "$cur_instance|$key"
  set inst_mapping($full_key)   $value
}


##
#   @brief    Get the instance value for the key in the current instance.
#   @details  The given key is added to the current instance name to form
#             a key that is used to retrieve a value.
#
#   @param    key         The key in current instance to get the value of.
#

proc get_instvalue { key } {
  global instance_stack
  global inst_mapping

  set cur_instance              [lindex $instance_stack 0]
  set full_key                  "$cur_instance|$key"
  return $inst_mapping($full_key)
}


##
#   @brief    Copy the list of key values in the instance mapping.
#   @details  Key value pairs are 'input,output' key names.  The value of
#             the output key in the new instance (top of instance stack)
#             is copied from the input key in the previous instance on the
#             instance stack.
#
#   @param    keypairs  List of input,output key pairs.
#

proc copy_instvalues { keypairs } {
  global instance_stack
  global inst_mapping

  set new_instance              [lindex $instance_stack 0]
  set old_instance              [lindex $instance_stack 1]

  foreach pair $keypairs {
    set key_set                 [split $pair ","]
    set input_key               [lindex $key_set 0]
    set output_key              [lindex $key_set 1]

    set old_key                 "$old_instance|$input_key"
    set new_key                 "$new_instance|$output_key"

    set inst_mapping($new_key)  $inst_mapping($old_key)
  }
}


##
#   @brief    Set the instance value for a key.
#   @details  The given key is directly assigned the given value.
#
#   @param    key         The key to set the value of.
#   @param    value       The value to set for the key.
#

proc set_keyvalue { key value } {
  global inst_mapping

  set full_key                  "$key"
  set inst_mapping($full_key)   $value
}


##
#   @brief    Get the instance value for the key.
#   @details  The given key is used to retrieve a value.
#
#   @param    key         The key to get the value of.
#

proc get_keyvalue { key } {
  global inst_mapping

  set full_key                  "$key"
  return $inst_mapping($full_key)
}
