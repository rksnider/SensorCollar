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
    set full_instance           "$instance"
  } else {
    set cur_instance            [lindex $instance_stack 0]
    set full_instance           "$cur_instance|$instance"
  }

  set instance_stack            [linsert $instance_stack 0 $full_instance]
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

  if {[llength [array names inst_mapping $full_key]] > 0} {
    return $inst_mapping($full_key)
  } else {
    return { }
  }
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

  if {[llength [array names inst_mapping $full_key]] > 0} {
    return $inst_mapping($full_key)
  } else {
    return { }
  }
}


##
#   @brief    Set the entity port to I/O port mappings
#   @details  The list of entity port to I/O port mappings is converted into
#             an array.
#

proc set_ioports { port_list } {
  global ioport_mapping

  array set ioport_mapping      $port_list
}


##
#   @brief    Translate collar entity port names into I/O port names
#   @details  A list of collar entity port names is translated into
#             the corresponding I/O port names.  A star appended to a port
#             name will be appended to the I/O port name result.
#

proc get_ioports { entity_ports } {
  global ioport_mapping

  set results                   [list]

  foreach port_name $entity_ports {
    regexp {([^*]+)(\*)?} "$port_name" match_name base_name star_match
    set ioport_name             $ioport_mapping($base_name)
    lappend results "$ioport_name$star_match"
  }

  return $results
}


##
#   @brief    Put all clocks in a list into the clock set table.
#   @details  The list of clocks becomes the value of each clock in the list.
#
#   @param    clocks      List of all clocks that are part of a set.
#

proc make_clockset { clocks } {
  global clockset

  foreach clk $clocks {
    set clockset($clk)          $clocks
  }
}


##
#   @brief    Get a list of all clocks that are part of a clock's set.
#   @details  Return the list of clocks that are part of the given clock's
#             set.  This includes the given clock.
#
#   @param    clk       Clock to return the clock set list for.
#

proc get_clockset { clk } {
  global clockset

  if {[array exists clockset] > 0} {
    if {[llength [array names clockset $clk]] > 0} {
      return $clockset($clk)
    }
  }
  return { [list $clk] }
}