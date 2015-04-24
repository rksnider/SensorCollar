function [mem,gpsmem,cntmem] = LSM9DS1_top_tb

%------------------------------------------------------------
% Note: it appears that the cosimWizard needs to be re-run if
% this is moved to a different machine (VHDL needs to be
% recompile in ModelSim).
%------------------------------------------------------------

% HdlCosimulation System Object creation


sim_hdl = hdlcosim_lsm9ds1_top;


release(sim_hdl);


clock_edges = 4*512;


%Send MISO bytes to the master.
spi_slave_byte_cnt = 1;
miso_bit_cnt = 1;
spi_slave_bytes = repmat([0:1:512],1,3);

in3_fi = fi(spi_slave_bytes(spi_slave_byte_cnt),0,8,0);
in3_signal_value = str2num(in3_fi.bin(miso_bit_cnt));

in4_fi = fi(spi_slave_bytes(spi_slave_byte_cnt),0,8,0);
in4_signal_value = str2num(in4_fi.bin(miso_bit_cnt));



in1_signal_value = 0;
in2_signal_value = 0;



in3_signal_value = 0;
in4_signal_value = 0;
in5_signal_value = 0;
in6_signal_value = 0;
in7_signal_value = 0;
in8_signal_value = 0;

%gyro_data_rdy
output_vector1 = 0;
%accel_data_rdy
output_vector2 = 0;
%mag_data_rdy
output_vector3 = 0;
%temp_data_rdy
output_vector4 = 0;

%gyro_data_x
output_vector5 = 0;
%gyro_data_y
output_vector6 = 0;
%gyro_data_z
output_vector7 = 0;

%accel_data_x
output_vector8 = 0; 
%accel_data_y
output_vector9 = 0;
%accel_data_z
output_vector10 = 0;


%mag_data_x
output_vector11 = 0; 
%mag_data_y
output_vector12 = 0; 
%mag_data_z
output_vector13 = 0; 

%temp_data
output_vector14 = 0;

%sclk
output_vector15 = 0; 
%mosi
output_vector16 = 0;
%cs_XL_G
output_vector17 = 0;
%cs_M
output_vector18 = 0;

%gyro_fpga_time
output_vector19 = 0;
%accel_fpga_time
output_vector20 = 0;
%mag_fpga_time
output_vector21 = 0;
%temp_fpga_time
output_vector22 = 0;



%Step occurs at the sampling rate. 
%I is thus the number of samples! not the number of clock edges.
%To change signals in relation in relation to the clk using i, 
%this must be remembered. 
for i = 1:clock_edges
    
%startup
in1_signal_width        = 1;
in1_signal_signed       = 0;
in1_signal_fraction     = 0;
   
input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                        in1_signal_width, in1_signal_fraction) ;
              
%current_fpga_time              
in2_signal_width        = 9*8;
in2_signal_signed       = 0;
in2_signal_fraction     = 0;
   
input_vector2     = fi (in2_signal_value, in2_signal_signed,          ...
                        in2_signal_width, in2_signal_fraction) ;


%miso_XL_G
in3_signal_width        = 1 ; 
in3_signal_signed       = 0 ;
in3_signal_fraction     = 0 ;
input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                        in3_signal_width, in3_signal_fraction) ;
                    
%miso_M                  
in4_signal_width        = 1 ; 
in4_signal_signed       = 0 ;
in4_signal_fraction     = 0 ;
input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                        in4_signal_width, in4_signal_fraction) ;
                    
%INT_M                               
in5_signal_width        = 1 ; 
in5_signal_signed       = 0 ;
in5_signal_fraction     = 0 ;
input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                        in5_signal_width, in5_signal_fraction) ;
                    
%DRDY_M                                 
in6_signal_width        = 1 ; 
in6_signal_signed       = 0 ;
in6_signal_fraction     = 0 ;
input_vector6     = fi (in6_signal_value, in6_signal_signed,          ...
                        in6_signal_width, in6_signal_fraction) ;
                    
%INT1_A_G
in7_signal_width        = 1 ; 
in7_signal_signed       = 0 ;
in7_signal_fraction     = 0 ;
input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                        in7_signal_width, in7_signal_fraction) ;
                    
%INT2_A_G                    
in8_signal_width        = 1 ; 
in8_signal_signed       = 0 ;
in8_signal_fraction     = 0 ;
input_vector8     = fi (in8_signal_value, in8_signal_signed,          ...
                        in8_signal_width, in8_signal_fraction) ;

                    

%Begin actual testbench

        %Audio Rdy and Data
        %*2?
        %I am sampling at twice my clock frequency. 
%       56250kHz is 3.6Mhz / 64. But the matlab cosim object is set up to
%       sample twice every (T)(Period), so multiply i by two.
        
        
        
        %Send a startup enable. 
        if (i == 100)
            in1_signal_value = 1;
        else
            in1_signal_value = 0;
        end 
        
        % %Accel and Gyro cap out at ~980Hz.
        % %Gyro Ready and Data
%     if (mod(i,4096*2) == 0)
                  if (mod(i,200*2) == 0)
       % if (i == 200)
            in7_signal_value = 1;
        else
            in7_signal_value = 0;
        end 
        
        %Accel Ready and Data
%         if (i == trig*64*2)
 %    if (mod(i,4096*2) == 0)
                  if (mod(i,200*2) == 0)
        %if (i == 200)
            in8_signal_value = 1;
        else
            in8_signal_value = 0;
        end 
        
        %Mag caps out at 80Hz.
        %Mag Ready and Data
%         if (i == trig*64*2)
%        if (i == 250)
%          if (mod(i,4096*2) == 0)
         if (mod(i,200*2) == 0)
            in6_signal_value = 1;
        else
            in6_signal_value = 0;
        end 
        
        
% %         %Temp caps out at 50Hz.
        % %Temp Ready and Data
% %        if (i == trig*64*2)
        % if(i == 5000)
% %         if (mod(i,2^16) == 0)
            % in8_signal_value = 1;
            % in18_signal_value = in18_signal_value + 1;
        % else
            % in8_signal_value = 0;
        % end 
        

      [output_vector1, output_vector2, output_vector3, output_vector4,    ...
                       output_vector5, output_vector6, output_vector7,      ...
                       output_vector8, output_vector9, ...
                       output_vector10, output_vector11, ...
                       output_vector12, output_vector13, ...
                       output_vector14, output_vector15, ...
                        output_vector16, output_vector17, ...
                         output_vector18, output_vector19, ...
                          output_vector20,output_vector21,output_vector22] =  ...
          step (sim_hdl, input_vector1, input_vector2, input_vector3,     ...
                         input_vector4, input_vector5, input_vector6,       ...
                    	input_vector7,input_vector8) ;
                    
      %Send MISO bits to both the MISO_XL and MISO_M ports depending on
      %which CS_N is selected. 
      
      %Below we send back MISO bytes from both the XL_G and the M.            
      %This method of MISO input works well.
      %The sample of sclk==1 allows line to be updated on the falling edge
      %of sclk, or the next iteration of this loop, being that the loop
      %runs twice per clock period. 
         if (output_vector17 == 0)
                 %Change MISO line on falling edge of sclk. 
                 if (output_vector15 == 1)
                    if (miso_bit_cnt == 8)
                        miso_bit_cnt = 1;
                        spi_slave_byte_cnt = spi_slave_byte_cnt + 1;
                    else
                         miso_bit_cnt = miso_bit_cnt + 1;
                    end
                 end
             in3_fi = fi(spi_slave_bytes(spi_slave_byte_cnt),0,8,0);
             in3_signal_value = str2num(in3_fi.bin(miso_bit_cnt));

%          else
%          miso_bit_cnt = 1;
%          end
         
         
      %This method of MISO input works well.
      %The sample of sclk==1 allows line to be updated on the falling edge
      %of sclk, or the next iteration of this loop, being that the loop
      %runs twice per clock period. 
         elseif (output_vector18 == 0)
                 %Change MISO line on falling edge of sclk. 
                 if (output_vector15 == 1)
                    if (miso_bit_cnt == 8)
                        miso_bit_cnt = 1;
                        spi_slave_byte_cnt = spi_slave_byte_cnt + 1;
                    else
                         miso_bit_cnt = miso_bit_cnt + 1;
                    end
                 end
             in4_fi = fi(spi_slave_bytes(spi_slave_byte_cnt),0,8,0);
             in4_signal_value = str2num(in4_fi.bin(miso_bit_cnt));

         else
         miso_bit_cnt = 1;
         end
       
end

% mem_comp{trig} = mem;

% end
  


