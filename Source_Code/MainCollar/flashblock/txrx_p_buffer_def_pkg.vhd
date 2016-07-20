-- @file       txrx_p_buffer_def_pkg.vhd
-- @brief      Wireless Packet Definition File
-- @details
-- @author     Chris Casebeer
-- @date       7_18_2016
-- @rev        2
-- @copyright
--
--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--  Chris Casebeer
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  christopher.casebee1@msu.montana.edu
--
--




--Wireless Packet Layout
--55 bytes total    (rev 2)
--55 locations written in modelsim. 


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --  Use real numbers for finding number of
                                --  bits needed.
                                
library WORK ;                      --! Local Libaries
use WORK.PC_StatusControl_pkg.All ;                                        
                                
package txrx_p_buffer_def_pkg is



constant txrx_single_buffer_size : natural := 128;
constant txrx_double_buffer_size : natural := txrx_single_buffer_size*2;


--Init Value Location
constant microsd_serial_length_bytes_c : natural := 4;
constant microsd_serial_location_c : natural := 0;

--The current time stored to the RTC.                                    
constant rtc_time_length_bytes_c : natural := 4;
constant rtc_time_location_c : natural := microsd_serial_location_c
                                              + microsd_serial_length_bytes_c;

                                                   
--The GPS time at which the wireless packet was assembled. 
constant packet_gen_time_length_bytes_c : natural := 9;
constant packet_gen_time_location_c : natural := rtc_time_location_c
                                              + rtc_time_length_bytes_c;
                                              

                                              
--Battery voltage (mAh) at the time packet was assembled. 
constant battery_voltage_length_bytes_c : natural := 2;
constant battery_voltage_location_c : natural := packet_gen_time_location_c
                                              + packet_gen_time_length_bytes_c;
                                              
--Battery capacity (mAh) at the time packet was assembled. 
constant battery_capacity_length_bytes_c : natural := 2;
constant battery_capacity_location_c : natural := battery_voltage_location_c
                                              + battery_voltage_length_bytes_c;
                                              
--Battery current drain (mA) at the time packet was assembled. 
constant battery_current_length_bytes_c : natural := 2;
constant battery_current_location_c : natural := battery_capacity_location_c
                                              + battery_capacity_length_bytes_c;
                                              
                                                                                            
--Last block written successfully to the microSD card. 
constant microsd_last_block_written_length_bytes_c : natural := 4;
constant microsd_last_block_written_location_c : natural := battery_current_location_c
                                              + battery_current_length_bytes_c;
                                              
--ECEF coordinates stored Little Endian. XYZ.
constant gps_pos_ecef_length_bytes_c : natural := 12;
constant gps_pos_ecef_location_c : natural := microsd_last_block_written_location_c
                                              + microsd_last_block_written_length_bytes_c;
                                                                            
                                                                                           
constant gps_accuracy_length_bytes_c : natural := 4;
constant gps_accuracy_location_c : natural := gps_pos_ecef_location_c
                                              + gps_pos_ecef_length_bytes_c;
                                              
--The time associated with the GPS position. 
constant gps_pos_time_length_bytes_c : natural := 9;
constant gps_pos_time_location_c : natural := gps_accuracy_location_c
                                              + gps_accuracy_length_bytes_c;
                                              
--The control register of the system. 
--This indicates all the devices which are currently turned on.
--Reference PC_StatusControl_pkg.vhd for field definitions. 
--3 bytes as of 7_18_2016
constant control_register_length_bytes_c : natural :=  (ControlSignalsCnt_c + 7) / 8;
constant control_register_location_c : natural := gps_pos_time_length_bytes_c
                                              + gps_pos_time_location_c;
                                              
                                              
                                              
constant packet_total_length : natural := control_register_length_bytes_c + control_register_location_c;
                                              


end package txrx_p_buffer_def_pkg ;
