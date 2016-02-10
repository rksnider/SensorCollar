% --
% --
% --! @file       i2c_top_tb.m
% --! @brief      Matlab cosimulation for flashblock VHDL block
% --! @details    
% --! @author     Chris Casebeer
% --! @date       12_16_2015
% --! @copyright  
% --
% --  This program is free software: you can redistribute it and/or modify
% --  it under the terms of the GNU General Public License as published by
% --  the Free Software Foundation, either version 3 of the License, or
% --  (at your option) any later version.
% --
% --  This program is distributed in the hope that it will be useful,
% --  but WITHOUT ANY WARRANTY; without even the implied warranty of
% --  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% --  GNU General Public License for more details.
% --
% --  You should have received a copy of the GNU General Public License
% --  along with this program.  If not, see <http://www.gnu.org/licenses/>.
% --
% --  Chris Casebeer
% --  Electrical and Computer Engineering
% --  Montana State University
% --  610 Cobleigh Hall
% --  Bozeman, MT 59717
% --  christopher.casebee1@msu.montana.edu
% --
% --


%This testbench assume inverted memory clocks. 
%Setting a wr_en or rd_en and address will yield valid data for the very
%rising edge of the master clock.
%This is due to an inverted clock sent to the memories of interest. 


function [] = i2c_top_tb


% HdlCosimulation System Object creation


sim_hdl = hdlcosim_i2c_top_level;


%Testbench parameters

%WARNING
%This test bench assumes sampling 4 times per period!
%AND it samples slightly after edges.
%This is done by setting the presimulation time set to slightly after
%the first full period. 
%This is to accomodate the inverted memory clock systems. 
%It also hopefully makes the test bench more fluid and easier to 
%understand (most especially for me)
tb_clock_rate_ns = 20;
tb_sample_rate_ns = 5;
tb_samples_per_period = tb_clock_rate_ns/tb_sample_rate_ns;
tb_num_samples = 30*tb_samples_per_period*128;


release(sim_hdl);


%Change to emery's newly updated cell array call by name system.
%Todo: Build the following through use of a script which interfaces
%with modelsim via TCL scripting. 
%Changing order of the entity port mapping in any way will break this
%testbench. 
%fi(v,s,w,f)
%All the input ports of the testbench are unsigned no fraction inputs. 
s = 0;
f = 0;
 
in_count                = 0 ;
out_count               = 0 ;


in_sig                  = zeros (1, 4) ;
out_sig                 = zeros (1, 1) ;

% sda_out
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
sda_out                  = out_count ;    
    
% scl_out			        : out std_logic
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
scl_out                 = out_count ; 

% scl_dir             : in std_logic;
 
in_count                = in_count + 1 ;
v = 0; 
w = 1;
in_sig (in_count, :)    = [v s w f] ;
scl_dir                 = in_count ;   
      
% sda_dir             : in std_logic;
      
in_count                = in_count + 1 ;
v = 0; 
w = 1;
in_sig (in_count, :)    = [v s w f] ;
sda_dir              = in_count ;

% sda_in 			        : in std_logic;  

in_count                = in_count + 1 ;
v = 1; 
w = 1;
in_sig (in_count, :)    = [v s w f] ;
sda_in              = in_count ;


% scl_in 			        : in std_logic
    
in_count                = in_count + 1 ;
v = 0; 
w = 1;
in_sig (in_count, :)    = [v s w f] ;
scl_in                   = in_count ;

in_vect = cell(1,in_count);
out_vect = cell(1,out_count);


i2c_scl_period_ns = 1/(400e3) * 10^9;

bit_count = 0;
scl_new = 1;
sda_new = 1;
scl_old = [ones(1,floor(i2c_scl_period_ns/tb_sample_rate_ns) )];
sda_old = [ones(1,floor(i2c_scl_period_ns/tb_sample_rate_ns) )];

i2c_slave_received = cell{1};
i2c_slave_send = fi(0,0,8,0);

i2c_slave_receive = fi(0,0,8,0);

%AA
i2c_test_byte = fi(170,0,8,0);

i2c_start = 0;
i2c_stop = 0;
i2c_repeated_start = 0;

%%%%
%Begin the main testbench
%%%%
for i = 1:tb_num_samples



%Maintain information about the modelsim clock.
%This is done via a modulo operator, knowing the defined
%sample rate in relation to the clock rate. 
%Knowledge of how the simulation is setup is also important. 
  if (mod(i-1,tb_samples_per_period) == 0)
    rising_edge = 1;
    falling_edge = 0;
  else
    falling_edge = 1;
    rising_edge = 0;
  end
  
  

  

  
  %Send the ack in if master is not reading.
  if (i2c_reading == 0)
      if (bit_count == 9)
          in_sig(sda_dir) = 1;
          in_sig(sda_in,1) = 0;
        else 
          in_sig(sda_dir) = 0;
          in_sig(sda_in,1) = 1;
      end
  end
  
  %If the clock line has been raised and stays that way.
  %Reset the bit count. 
  %Remember this testbench assumes 4x sampling per period. 
  if ( all(double(scl_old) == 1))
   bit_count = 0;
   i2c_slave_byte_count = 1;
  end
  
  %A start condition has occured.
  if (sda_new == 0 && scl_old(end) == 1 && scl_new == 0)
    if (start == 1)
        repeated_start = 1;
        bit_count = 0;
        
    else
        start = 1;
    end
  end
  
  %A stop condition has occured.
    if (scl_new == 1 && sda_old(end) == 0 && sda_new == 1)
        stop = 1;
        start = 0;
        repeated_start = 0;
    end
      

    %New rising edge on scl.
    %The i2c_master vhdl component we use samples on falling edge of 
    %scl.
  if ( scl_old(end) == 0 && scl_new == 1)
    if (bit_count == 9)
      bit_count = 1;
      i2c_slave_received{i2c_slave_byte_count} = i2c_slave_receive;
      i2c_slave_byte_count = i2c_slave_byte_count + 1;
    else
      if (i2c_reading == 0)
        %Sample the bit. 
        i2c_slave_receive.bin(bit_count) = out_vect{sda_out};
        bit_count = bit_count + 1;
      else
      	in_sig(sda_dir) = 1;
        in_sig(sda_in,1) = i2c_test_byte.bin(bit_count);
        bit_count = bit_count + 1;
      end
      
    end
  end
  
  %Determine if the first byte send over I2C by the master
  %has the read bit set. If so, we need to send a byte back to the host. 
  %If the first byte already received.
  %This I2C system is specific to the battery monitor setup.
  %I am not going to do specific command response. 
  %I will only be sending back test pattern if the I2C host
  %requests data. 
  %Create BEEF pattern
  if (i2c_slave_byte_count == 2)
    if(double(i2c_slave_receive{1}.bin(8)) == 1)
        i2c_reading = 1;
    else
        i2c_reading = 0;
    end
  end
  
  %Need to check for repeated start and stop conditions.
%   Start happens when SDA is high and SCL goes low. 
%   Stop happens when SCL is high and SDA then goes high.
%   Repeated start happens when no stop condition and another start occurs.

  in_sig(scl_dir) = 0;

 
            
    %Only cell arrays can hold the fi's. 
    for j=1:in_count
      in_vect{j} = fi(in_sig(j,1),in_sig(j,2),in_sig(j,3),in_sig(j,4));
    end
                         

            
            
  %Step the hdl verifier cosimulation object with inputs. Receive outputs
  %back from modelsim. 
  [out_vect{:}] =  step (sim_hdl,in_vect{:}) ;
                      
  
  %Keep track of older sda and scl to find starts and stops. 
  scl_old = [scl_old(2:end) scl_new];
  scl_new = out_vect{scl_out};
  
  sda_old = [sda_old(2:end) sda_new];
  sda_new = out_vect{sda_out};
  


end



