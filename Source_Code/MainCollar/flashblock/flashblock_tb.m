% --
% --
% --! @file       flashblock_tb.m
% --! @brief      Matlab cosimulation for flashblock VHDL block
% --! @details    
% --! @author     Chris Casebeer
% --! @date       1_21_2015
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


function [mem,gpsmem,cntmem] = flashblock_tb


% HdlCosimulation System Object creation


sim_hdl = hdlcosim_flashblock;


%Testbench parameters
tb_clock_rate_ns = 278;
tb_sample_rate_ns = 139;
tb_samples_per_period = tb_clock_rate_ns/tb_sample_rate_ns;
tb_num_samples = 64*2*64;



    
release(sim_hdl);


%Set flashblock generic to correspond to number of counters.  
cntmem = [ 5 6 7 0 0 1  0 2 3 5 15 10 13];



% --Position in the magnetic memory 2 port ram buffer.

% --Init Value Location
% constant sd_card_init_value_length_bytes_c : natural := 2;
% constant sd_card_init_value_location_c : natural := 0;


% --SD Card Last Block Successfully Written
% constant sd_card_start_location_length_bytes_c : natural := 4;
% constant sd_card_start_location_c : natural := sd_card_init_value_location_c
                                              % + sd_card_init_value_length_bytes_c;
                                              
% --SD Card Last Logical Block Assembled Successfully
% constant logical_block_length_bytes_c : natural := 4;
% constant logical_block_location_c : natural := sd_card_init_value_location_c
                                              % + sd_card_init_value_length_bytes_c;


% --Shut-Down successful. 
% constant shutdown_success_length_bytes_c : natural := 1;
% constant shutdown_success_location_c : natural := logical_block_length_bytes_c 
                                  % + logical_block_location_c ;

magmem = [0 0 8 0 0 0 8 0 0 0 1];
        

% Please see GPS code for this structure. 
gpsmem = zeros(1,512);

gps_time_bytes_c = 9;

msg_ram_banks = 2;

msg_rom_base            = 0 ;
msg_ram_base            = 59 ;
msg_ram_blocks          = 2 ;
msg_ram_temp_addr       = 45 * msg_ram_banks;
msg_ram_temp_size       = 30 ;

msg_ram_postime_addr    = msg_ram_temp_addr + msg_ram_temp_size * msg_ram_banks ;
msg_ram_postime_size    = gps_time_bytes_c ;

msg_ram_marktime_addr   = msg_ram_postime_addr + msg_ram_postime_size * msg_ram_banks ;
msg_ram_marktime_size   = gps_time_bytes_c ;

msg_ubx_nav_sol_ramaddr = 0 * msg_ram_banks;
msg_ubx_nav_sol_ramused = 30 ;

msg_ubx_tim_tm2_ramaddr = 30 * msg_ram_banks;
msg_ubx_tim_tm2_ramused = 15 ;

%Input buffer to sd_ram controller.
mem = zeros(1,4096);

%Fill the GPS memory with initial values. So I can read them into
%flashblock. Consult GPS dev package files for locations. 

for i = 1:msg_ram_postime_size
    for j = 1:msg_ram_banks
    gpsmem(msg_ram_base + msg_ram_postime_addr + (j - 1)*msg_ram_postime_size + i - 1) = i;
    
    end
end;    


for i = 1:msg_ram_marktime_size
    for j = 1:msg_ram_banks
    gpsmem(msg_ram_base + msg_ram_marktime_addr + (j - 1)*msg_ram_marktime_size + i - 1) = i ; 
    
    end
end;    


for i = 1:msg_ubx_nav_sol_ramused
     for j = 1:msg_ram_banks
    gpsmem(msg_ram_base + msg_ubx_nav_sol_ramaddr + (j - 1)*msg_ubx_nav_sol_ramused +  i - 1) = i; 
    
     end
end

for i = 1:msg_ubx_tim_tm2_ramused
     for j = 1:msg_ram_banks
    gpsmem(msg_ram_base + msg_ubx_tim_tm2_ramaddr + (j - 1)*msg_ubx_tim_tm2_ramused +  i - 1) = i; 
    
     end
end
       
        
        
%In the attempt to ever get a cleaner matlab cosimulation 
%testbench, import the generics of interest which define the 
%associated ports. 
%Taken from flashblock.vhd OR a VHDL pkg file it relies on. 
    fpga_time_length_bytes_g  = 9;          
    time_bytes_g              = 9 ;        
    event_bytes_g             = 2 ;       

    rtc_time_bytes_g          = 4;
    num_mics_active_g         = 1;
    
    counter_data_size_g       = 8 ;
    counter_address_size_g    = 9 ;
    counters_g                = 10 ;

    gps_buffer_bytes_g            = 512;
    imu_axis_word_length_bytes_g  = 2;
    sdram_input_buffer_bytes_g    = 4096;
    audio_word_bytes_g            = 2;
    
    
gps_time_bytes_c = 9;





sdram_force_cnt = 64*2*256;

% %Essentially a trigger for data when there are 512 - trig/2 -4 bytes left. 
% % trig = 12;


% in1_signal_value = 100;
% in2_signal_value = 0;

% %DEEFFEEBDEEFFEEBBA

% in3_signal_value = hex2dec('DEEFFEEBDEEFFEEBBA');
% in4_signal_value = 0;
% in5_signal_value = 0;
% in6_signal_value = 0;
% in7_signal_value = 0;
% in8_signal_value = 0;
% in9_signal_value = 0;
% in10_signal_value = 1;
% in11_signal_value = 2;
% in12_signal_value = 3;
% in13_signal_value = 4;
% in14_signal_value = 5;
% in15_signal_value = 6;
% in16_signal_value = 7;
% in17_signal_value = 8;
% in18_signal_value = 4;
% in19_signal_value = 0;
% in20_signal_value = 0;
% in21_signal_value = 0;
% in22_signal_value = 0;
% in23_signal_value = 0;
% in24_signal_value = 0;
% in25_signal_value = 0;
% in26_signal_value = 0;
% in27_signal_value = 0;
% in28_signal_value = 0;
% in29_signal_value = 0;
% in30_signal_value = 0;
% in31_signal_value = 0;


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


%clk_enable            : in    std_logic;

in_count                = in_count + 1 ;
v = 1; 
w = 1;
in_sig (in_count, :)    = [v s w f] ;
clk_enable      = in_count ;


% log_status            : in    std_logic ;
    
in_count                = in_count + 1 ;
v = 0; 
w = 1;
in_sig (in_count, :)    = [v s w f] ;
log_status      = in_count ;


% current_fpga_time     : in std_logic_vector 
                              % (gps_time_bytes_c*8-1 downto 0);
                              
in_count                = in_count + 1 ;
v = 0; 
w = 9*8;
in_sig (in_count, :)    = [v s w f] ;
current_fpga_time      = in_count ;                             
                              
                              
% log_events            : in    std_logic;
    
in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
log_events      = in_count ;


% gyro_data_rdy   : in    std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
gyro_data_rdy      = in_count ;

% accel_data_rdy  : in    std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
accel_data_rdy      = in_count ;


% mag_data_rdy    : in    std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
mag_data_rdy      = in_count ;


% temp_data_rdy   : in    std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
temp_data_rdy      = in_count ;
    
    
    
%   gyro_data_x     :in     std_logic_vector(
                            %imu_axis_word_length_bytes_g*8 - 1 downto 0);    
    
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
gyro_data_x      = in_count ;
    

% gyro_data_y     :in     std_logic_vector(
                            % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
gyro_data_y      = in_count ;


% gyro_data_z     :in     std_logic_vector(
                            % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
gyro_data_z      = in_count ;

% accel_data_x    :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
accel_data_x      = in_count ;


% accel_data_y    :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
accel_data_y      = in_count ;


% accel_data_z    :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
accel_data_z      = in_count ;
    
% mag_data_x      :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
mag_data_x      = in_count ;

% mag_data_y      :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
mag_data_y      = in_count ;

% mag_data_z      :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
mag_data_z      = in_count ;

% temp_data       :in     std_logic_vector(
                        % imu_axis_word_length_bytes_g*8 - 1 downto 0);
                            
in_count                = in_count + 1 ;
v = 0;
w = imu_axis_word_length_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
temp_data      = in_count ;
    
% audio_data_rdy          : in std_logic;
    
in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
audio_data_rdy      = in_count ;
    
% audio_data              : in std_logic_vector(
                              % audio_word_bytes_g*8  - 1 downto 0);
                              
in_count                = in_count + 1 ;
v = 0;
w = audio_word_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
audio_data      = in_count ;           
  
% flashblock_inbuf_data       : out    std_logic_vector(7 downto 0);

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_inbuf_data        = out_count ;    
    
    
% flashblock_inbuf_wr_en      : out    std_logic;
    
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_inbuf_wr_en        = out_count ;
    
    
% flashblock_inbuf_clk        : out    std_logic;
    
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_inbuf_clk        = out_count ;
    
    

% flashblock_inbuf_addr       : out   std_logic_vector(
                                        % natural(trunc(log2(real(
                                        % sdram_input_buffer_bytes_g-1)))) 
                                        % downto 0);
                                        
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_inbuf_addr        = out_count ;
                                        
                                        
    
% flashblock_gpsbuf_addr      : out   std_logic_vector(
                                    % natural(trunc(log2(real(
                                    % gps_buffer_bytes_g-1)))) 
                                    % downto 0);  
 
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_gpsbuf_addr        = out_count ; 
                                    
% flashblock_gpsbuf_rd_en     : out   std_logic;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_gpsbuf_rd_en        = out_count ;


% flashblock_gpsbuf_clk       : out   std_logic;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_gpsbuf_clk        = out_count ;


% gpsbuf_flashblock_data      : in    std_logic_vector(7 downto 0);

in_count                = in_count + 1 ;
v = 0;
w = 8;
in_sig (in_count, :)    = [v s w f] ;
gpsbuf_flashblock_data      = in_count ;

% gps_req_out       : out   std_logic;

out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
gps_req_out        = out_count ;


% gps_rec_in        : in    std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
gps_rec_in      = in_count ;

% posbank     :in std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
posbank      = in_count ;


% tmbank      :in std_logic;

in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
tmbank      = in_count ;
  
% gyro_fpga_time  :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    
in_count                = in_count + 1 ;
v = 0;
w = gps_time_bytes_c*8;
in_sig (in_count, :)    = [v s w f] ;
gyro_fpga_time      = in_count ;
    
% accel_fpga_time :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    
in_count                = in_count + 1 ;
v = 0;
w = gps_time_bytes_c*8;
in_sig (in_count, :)    = [v s w f] ;
accel_fpga_time      = in_count ;
    
% mag_fpga_time :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    
in_count                = in_count + 1 ;
v = 0;
w = gps_time_bytes_c*8;
in_sig (in_count, :)    = [v s w f] ;
mag_fpga_time      = in_count ;
    
% temp_fpga_time :in std_logic_vector (gps_time_bytes_c*8-1 downto 0);
    
in_count                = in_count + 1 ;
v = 0;
w = gps_time_bytes_c*8;
in_sig (in_count, :)    = [v s w f] ;
temp_fpga_time      = in_count ;

% rtc_time  : in std_logic_vector (rtc_time_bytes_g*8-1 downto 0);
    
in_count                = in_count + 1 ;
v = 0;
w = rtc_time_bytes_g*8;
in_sig (in_count, :)    = [v s w f] ;
rtc_time      = in_count ;
    
    
% flashblock_counter_rd_wr_addr  : out   std_logic_vector(
                                        % counter_address_size_g-1 downto 0); 
                                        
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_counter_rd_wr_addr        = out_count ;

                                   
% flashblock_counter_rd_en    : out   std_logic;
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_counter_rd_en        = out_count ; 
% flashblock_counter_wr_en    : out   std_logic;
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_counter_wr_en        = out_count ; 
% flashblock_counter_clk      : out   std_logic;
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_counter_clk        = out_count ; 
% flashblock_counter_lock     : out   std_logic;   
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_counter_lock        = out_count ;     
% flashblock_counter_data     : out   std_logic_vector(
                                        % counter_data_size_g-1 downto 0);
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_counter_data        = out_count ; 

% counter_flashblock_data     : in    std_logic_vector(
                                  % counter_data_size_g-1 downto 0);
                                  
in_count                = in_count + 1 ;
v = 0;
w = counter_data_size_g;
in_sig (in_count, :)    = [v s w f] ;
counter_flashblock_data      = in_count ;
                                        
                                        
                                        
    
% flashblock_sdram_2k_accumulated : out  std_logic;
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
flashblock_sdram_2k_accumulated        = out_count ; 

% mem_req_a_out           : out std_logic; 
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
mem_req_a_out        = out_count ;     
% mem_rec_a_in            : in std_logic;  
in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
mem_rec_a_in      = in_count ;

% fb_magram_clk_a_out     : out std_logic;
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
fb_magram_clk_a_out        = out_count ; 
% fb_magram_wr_en_a_out   : out std_logic;  
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
fb_magram_wr_en_a_out        = out_count ; 
% fb_magram_rd_en_a_out   : out std_logic;  
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
fb_magram_rd_en_a_out        = out_count ; 
% fb_magram_address_a_out : out std_logic_vector(natural(trunc(log2(real(
                            % (magmem_buffer_bytes/magmem_buffer_num)-1)))) downto 0);
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
fb_magram_address_a_out        = out_count ; 
% fb_magram_data_a_out    : out std_logic_vector(7 downto 0);
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
fb_magram_data_a_out        = out_count ; 
% magram_fb_q_a_in        : in std_logic_vector(7 downto 0);
in_count                = in_count + 1 ;
v = 0;
w = 8;
in_sig (in_count, :)    = [v s w f] ;
magram_fb_q_a_in      = in_count ;

% force_wr_en : out  std_logic; 
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
force_wr_en        = out_count ;     
% sdram_empty : in  std_logic;
in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
sdram_empty      = in_count ;
    
% crit_event  : in  std_logic;
in_count                = in_count + 1 ;
v = 0;
w = 1;
in_sig (in_count, :)    = [v s w f] ;
crit_event      = in_count ;

% blocks_past_crit : out std_logic_vector(7 downto 0)
out_count               = out_count + 1 ;
out_sig (out_count)     = 1 ;
blocks_past_crit        = out_count ; 





%Previous testbench method. 

% in1_signal_width        = 32 ;
% in1_signal_signed       = 0 ;
% in1_signal_fraction     = 0 ;
   
% input_vector1     = fi (in1_signal_value, in1_signal_signed,          ...
                        % in1_signal_width, in1_signal_fraction) ;
                    
% in2_signal_width        = 1 ;
% in2_signal_signed       = 0 ;
% in2_signal_fraction     = 0 ;
   
% input_vector2     = fi (in2_signal_value, in2_signal_signed,          ...
                        % in2_signal_width, in2_signal_fraction) ;


% in3_signal_width        = 9*8 ; 
% in3_signal_signed       = 0 ;
% in3_signal_fraction     = 0 ;
% input_vector3     = fi (in3_signal_value, in3_signal_signed,          ...
                        % in3_signal_width, in3_signal_fraction) ;
                    
                    
% in4_signal_width        = 1 ; 
% in4_signal_signed       = 0 ;
% in4_signal_fraction     = 0 ;
% input_vector4     = fi (in4_signal_value, in4_signal_signed,          ...
                        % in4_signal_width, in4_signal_fraction) ;
                    
                                        
% in5_signal_width        = 1 ; 
% in5_signal_signed       = 0 ;
% in5_signal_fraction     = 0 ;
% input_vector5     = fi (in5_signal_value, in5_signal_signed,          ...
                        % in5_signal_width, in5_signal_fraction) ;
                    
                                        
% in6_signal_width        = 1 ; 
% in6_signal_signed       = 0 ;
% in6_signal_fraction     = 0 ;
% input_vector6     = fi (in6_signal_value, in6_signal_signed,          ...
                        % in6_signal_width, in6_signal_fraction) ;
                    
                                        
% in7_signal_width        = 1 ; 
% in7_signal_signed       = 0 ;
% in7_signal_fraction     = 0 ;
% input_vector7     = fi (in7_signal_value, in7_signal_signed,          ...
                        % in7_signal_width, in7_signal_fraction) ;
                    
                    
% in8_signal_width        = 1 ; 
% in8_signal_signed       = 0 ;
% in8_signal_fraction     = 0 ;
% input_vector8     = fi (in8_signal_value, in8_signal_signed,          ...
                        % in8_signal_width, in8_signal_fraction) ;

% in9_signal_width        = 16 ; 
% in9_signal_signed       = 0 ;
% in9_signal_fraction     = 0 ;
% input_vector9     = fi (in9_signal_value, in9_signal_signed,          ...
                        % in9_signal_width, in9_signal_fraction) ;
                    
% in10_signal_width        = 16 ; 
% in10_signal_signed       = 0 ;
% in10_signal_fraction     = 0 ;
% input_vector10     = fi (in10_signal_value, in10_signal_signed,          ...
                        % in10_signal_width, in10_signal_fraction) ;
                    
% in11_signal_width        = 16 ; 
% in11_signal_signed       = 0 ;
% in11_signal_fraction     = 0 ;
% input_vector11     = fi (in11_signal_value, in11_signal_signed,          ...
                        % in11_signal_width, in11_signal_fraction) ;
                    
% in12_signal_width        = 16 ; 
% in12_signal_signed       = 0 ;
% in12_signal_fraction     = 0 ;
% input_vector12     = fi (in12_signal_value, in12_signal_signed,          ...
                        % in12_signal_width, in12_signal_fraction) ;
                    
% in13_signal_width        = 16 ; 
% in13_signal_signed       = 0 ;
% in13_signal_fraction     = 0 ;
% input_vector13     = fi (in13_signal_value, in13_signal_signed,          ...
                        % in13_signal_width, in13_signal_fraction) ;
                    
% in14_signal_width        = 16 ; 
% in14_signal_signed       = 0 ;
% in14_signal_fraction     = 0 ;
% input_vector14     = fi (in14_signal_value, in14_signal_signed,          ...
                        % in14_signal_width, in14_signal_fraction) ;
                    
% in15_signal_width        = 16 ; 
% in15_signal_signed       = 0 ;
% in15_signal_fraction     = 0 ;
% input_vector15     = fi (in15_signal_value, in15_signal_signed,          ...
                        % in15_signal_width, in15_signal_fraction) ;
                    
% in16_signal_width        = 2*8 ; 
% in16_signal_signed       = 0 ;
% in16_signal_fraction     = 0 ;
% input_vector16     = fi (in16_signal_value, in16_signal_signed,          ...
                        % in16_signal_width, in16_signal_fraction) ;
                    
% in17_signal_width        = 16 ; 
% in17_signal_signed       = 0 ;
% in17_signal_fraction     = 0 ;
% input_vector17     = fi (in17_signal_value, in17_signal_signed,          ...
                        % in17_signal_width, in17_signal_fraction) ;
                    
% in18_signal_width        = 2*8 ; 
% in18_signal_signed       = 0 ;
% in18_signal_fraction     = 0 ;
% input_vector18     = fi (in18_signal_value, in18_signal_signed,          ...
                        % in18_signal_width, in18_signal_fraction) ;
                    
% in19_signal_width        = 1 ; 
% in19_signal_signed       = 0 ;
% in19_signal_fraction     = 0 ;
% input_vector19     = fi (in19_signal_value, in19_signal_signed,          ...
                        % in19_signal_width, in19_signal_fraction) ;

% in20_signal_width        = 2*8 ; 
% in20_signal_signed       = 0 ;
% in20_signal_fraction     = 0 ;
% input_vector20     = fi (in20_signal_value, in20_signal_signed,          ...
                        % in20_signal_width, in20_signal_fraction) ;

                    
% in21_signal_width        = 8 ; 
% in21_signal_signed       = 0 ;
% in21_signal_fraction     = 0 ;
% input_vector21     = fi (in21_signal_value, in21_signal_signed,          ...
                        % in21_signal_width, in21_signal_fraction) ;
                    
% in22_signal_width        = 1 ; 
% in22_signal_signed       = 0 ;
% in22_signal_fraction     = 0 ;
% input_vector22     = fi (in22_signal_value, in22_signal_signed,          ...
                        % in22_signal_width, in22_signal_fraction) ;
                    
% in23_signal_width        = 1 ; 
% in23_signal_signed       = 0 ;
% in23_signal_fraction     = 0 ;
% input_vector23     = fi (in23_signal_value, in23_signal_signed,          ...
                        % in23_signal_width, in23_signal_fraction) ;
                    
% in24_signal_width        = 9*8 ; 
% in24_signal_signed       = 0 ;
% in24_signal_fraction     = 0 ;
% input_vector24     = fi (in24_signal_value, in24_signal_signed,          ...
                        % in24_signal_width, in24_signal_fraction) ;
                    
% in25_signal_width        = 9*8 ; 
% in25_signal_signed       = 0 ;
% in25_signal_fraction     = 0 ;
% input_vector25     = fi (in25_signal_value, in25_signal_signed,          ...
                        % in25_signal_width, in25_signal_fraction) ;
                    
% in26_signal_width        = 9*8 ; 
% in26_signal_signed       = 0 ;
% in26_signal_fraction     = 0 ;
% input_vector26     = fi (in26_signal_value, in26_signal_signed,          ...
                        % in26_signal_width, in26_signal_fraction) ;
                    
% in27_signal_width        = 9*8 ; 
% in27_signal_signed       = 0 ;
% in27_signal_fraction     = 0 ;
% input_vector27     = fi (in27_signal_value, in27_signal_signed,          ...
                        % in27_signal_width, in27_signal_fraction) ;
                    
% in28_signal_width        = 4*8 ; 
% in28_signal_signed       = 0 ;
% in28_signal_fraction     = 0 ;
% input_vector28     = fi (in28_signal_value, in28_signal_signed,          ...
                        % in28_signal_width, in28_signal_fraction) ;
                    
% in29_signal_width        = 8 ; 
% in29_signal_signed       = 0 ;
% in29_signal_fraction     = 0 ;
% input_vector29     = fi (in29_signal_value, in29_signal_signed,          ...
                        % in29_signal_width, in29_signal_fraction) ;
                    
% in30_signal_width        = 1 ; 
% in30_signal_signed       = 0 ;
% in30_signal_fraction     = 0 ;
% input_vector30     = fi (in30_signal_value, in30_signal_signed,          ...
                        % in30_signal_width, in30_signal_fraction) ;
                    
% in31_signal_width        = 1 ; 
% in31_signal_signed       = 0 ;
% in31_signal_fraction     = 0 ;
% input_vector31     = fi (in31_signal_value, in31_signal_signed,          ...
                        % in31_signal_width, in31_signal_fraction) ;

in_vect = cell(1,in_count);
out_vect = cell(1,out_count);

%%%%
%Begin the main testbench
%%%%
for i = 1:tb_num_samples



%Maintrain information about the modelsim clock.
%This is done via a modulo operator, knowing the defined
%sample rate in relation to the clock rate. 
  if (mod(i,tb_samples_per_period) == 0)
    rising_edge = 1;
    falling_edge = 0;
  else
    falling_edge = 1;
    rising_edge = 0;
  end





  
%I manually enter in hex values here as they are very large. matlab's
%type used by hex2dec won't hold them.
% % Sensor Times
in_vect{gyro_fpga_time}.hex = 'DEEFFEEBDEEFFEEBAB';
in_vect{accel_fpga_time}.hex = 'DEEFFEEBDEEFFEEBAB';
in_vect{mag_fpga_time}.hex = 'DEEFFEEBDEEFFEEBAB';

% % RTC 
in_vect{rtc_time}.hex = 'DEADBEEF';

   

  %Audio Rdy and Data
  %I am sampling at twice my clock frequency. 
%       56250kHz is 3.6Mhz / 64. But the matlab cosim object is set up to
%       sample twice every (T)(Period), so multiply i by two.

    if (mod(i,64*2) == 0)

        in_sig(audio_data_rdy,1) = 1;
        in_sig(audio_data,1) = in_sig(audio_data,1) + 1;
    else
      if (rising_edge)
        in_sig(audio_data_rdy,1) = 0;
      end
    end 
        
        
  %Accel and Gyro cap out at ~980Hz.
  %Gyro Ready and Data
  if (mod(i,4096*2) == 0)
    in_sig(gyro_data_rdy,1) = 1;
    in_sig(gyro_data_x,1) = in_sig(gyro_data_x,1) + 1;
    in_sig(gyro_data_y,1) = in_sig(gyro_data_y,1) + 1;
    in_sig(gyro_data_z,1) = in_sig(gyro_data_z,1) + 1;
  else
    if (rising_edge)
      in_sig(gyro_data_rdy,1) = 0;
    end
  end 
        
  %Accel Ready and Data
  if (mod(i,4096*2) == 0)
    in_sig(accel_data_rdy,1) = 1;
    in_sig(accel_data_x,1) = in_sig(accel_data_x,1) + 1;
    in_sig(accel_data_y,1) = in_sig(accel_data_y,1) + 1;
    in_sig(accel_data_z,1) = in_sig(accel_data_z,1) + 1;
  else
    if (rising_edge)
      in_sig(accel_data_rdy,1) = 0;
    end
  end 
        
  %Mag caps out at 80Hz.
  %Mag Ready and Data
  if (i == 80)
    in_sig(mag_data_rdy,1) = 1;
    in_sig(mag_data_x,1) = in_sig(mag_data_x,1) + 1;
    in_sig(mag_data_y,1) = in_sig(mag_data_y,1) + 1;
    in_sig(mag_data_z,1) = in_sig(mag_data_z,1) + 1;
  else
    if(rising_edge)
      in_sig(mag_data_rdy,1) = 0;
    end
  end 
        
%         %Temp caps out at 50Hz.
        %Temp Ready and Data
%        if (i == trig*64*2)
        % if(i == 5000)
% %         if (mod(i,2^16) == 0)
            % in8_signal_value = 1;
            % in18_signal_value = in18_signal_value + 1;
        % else
            % in8_signal_value = 0;
        % end 
        
        %Toggle the navbank, indicating GPS has written a new nav_sol ram bank.
        if (i == 450)
          if (rising_edge)
             in_sig(tmbank,1) = not(in_sig(tmbank,1));
          end
        end 
        
        % Toggle the tmbank, indicating GPS has written a new tm2 ram bank.
        if (i == 600)
          if (rising_edge)
             in_sig(posbank,1) = not(in_sig(posbank,1));
          end
        end 
        

        %Toggle a log_status event.
%     if (i == trig*64*2)
        % if (i == 10000)
            % in2_signal_value = 1;
        % else
            % in2_signal_value = 0;
        % end 
        
        
        
        
         %Toggle a log_events
%        if (i == trig*64*2)
        % if (i == 10000)
            % in4_signal_value = 1;
        % else
            % in4_signal_value = 0;
        % end 
        
        
                
         %Toggle a crit_event
%        if (i == trig*64*2)
        % if (i == 6000)
            % in31_signal_value = 1;
        % else
            % in31_signal_value = 0;
        % end 
            
            
         
% Testing for rising_edge is only valid before the step function. 
% Otherwise we would lag 1/2 clock cycle. 

  if (out_vect{gps_req_out} == 1)
    if (rising_edge)
      in_sig(gps_rec_in,1) = 1;
    end
  elseif (out_vect{gps_req_out} == 0)
    if (rising_edge)
      in_sig(gps_rec_in,1) = 0;
    end
  end   
  
  
  if (out_vect{mem_req_a_out} == 1)
    if (rising_edge)
      in_sig(mem_rec_a_in,1) = 1;
    end
  elseif (out_vect{mem_req_a_out} == 0)
    if (rising_edge)
      in_sig(mem_rec_a_in,1) = 0;
    end
  end   


  %Simulate sdram being forced from physical ram
  if (out_vect{force_wr_en} == 1)
    sdram_force_cnt = sdram_force_cnt - 1;
    if (sdram_force_cnt == 0)
    %Trigger sdram_empty.
      if (rising_edge)
        in_sig(sdram_empty,1) = 1;
       end
    end 
  end  

            
            
            
    %Only cell arrays can hold the fi's. 
    for j=1:in_count
      in_vect{j} = fi(in_sig(j,1),in_sig(j,2),in_sig(j,3),in_sig(j,4));
    end
                         

            
            
  %Step the hdl verifier cosimulation object with inputs. Receive outputs
  %back from modelsim. 
  [out_vect{:}] =  step (sim_hdl,in_vect{:}) ;
                      

  %Write the output of flashblock into input buffer
  %of sdram.
  if (out_vect{flashblock_inbuf_wr_en} == 1)
    if (out_vect{flashblock_inbuf_clk} == 1)
      mem(out_vect{flashblock_inbuf_addr} + 1) = out_vect{flashblock_inbuf_data};
    end
  end


  %Read from GPS Buffer.
  %Contains both Nav_Sol and TIM_TM2 data. 
  if (out_vect{flashblock_gpsbuf_rd_en} == 1)
    if (out_vect{flashblock_gpsbuf_clk} == 1)
      in_vect(gpsbuf_flashblock_data,1) = gpsmem(out_vect{flashblock_gpsbuf_addr});
    end 
  end

  %Counter rd_en
  %Must be eternally careful of 0 index vs matlab 1 index.
  if (out_vect{flashblock_counter_rd_en} == 1)
    out_vect{counter_flashblock_data} = cntmem(out_vect{flashblock_counter_rd_wr_addr}+1);
  end

  %Counter wr_en
  if (out_vect{flashblock_counter_wr_en} == 1)
    cntmem(out_vect{flashblock_counter_rd_wr_addr}+1) = out_vect{flashblock_counter_data};
  end
  
  
  %mag_ram_simulation
  if (out_vect{fb_magram_rd_en_a_out} == 1)
    if (out_vect{fb_magram_clk_a_out} == 1)
      in_vect(magram_fb_q_a_in,1) = magmem(out_vect{fb_magram_address_a_out});
    end
  end



end



