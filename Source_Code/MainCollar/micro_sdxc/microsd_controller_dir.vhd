
--
-- Filename:     	    microsd_controller_dir.vhd
-- Description:  	    Source code for microsd serial data logger
-- Author:			      Christopher Casebeer
-- Lab:               Dr. Snider
-- Department:        Electrical and Computer Engineering
-- Institution:       Montana State University
-- Support:           This work was supported under NSF award No. DBI-1254309
-- Creation Date:	    June 2014	
--		

--
-- Version 1.0
--
---
--
-- Modification Hisory (give date, author, description)
--
-- None
--
-- Please send bug reports and enhancement requests to 
-- Dr. Snider at rksnider@ece.montana.edu
--
--
--
--This software is released under
--            
--The MIT License (MIT)
--
--Copyright (C) 2014  Christopher C. Casebeer and Ross K. Snider
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in
--all copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--THE SOFTWARE.
--
--    Christopher Casebeer
--    Electrical and Computer Engineering
--    Montana State University
--    541 Cobleigh Hall
--    Bozeman, MT 59717
--    christopher.casebee1@msu.montana.edu
--
--    Ross K. Snider
--    Associate Professor
--    Electrical and Computer Engineering
--    Montana State University
--    538 Cobleigh Hall
--    Bozeman, MT 59717
--    rksnider@ece.montana.edu
--
--    Information on the MIT license can be found at http://opensource.org/licenses/MIT
--
--


--The DOxygen system of commenting has been used for efficient documentation.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ; 

--Library used for dual port ram.
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;




--! @brief      microsd_controller is the top component of the serial logging design.
--! @details    
--!
--! @param      clk_freq_g            Frequency of the input clk. Used to generate
--!                                 new clocks and timeout values.
--! @param      buf_size_g          Number of bytes in the buffer. Must be specified as N * 512 bytes. 
--!
--! @param      buf_size_g          Size of microsd_controller internal buffer, bytes.
--! @param      block_size_g        Size of a sd card block. Minimal addressable data size.
--!  
--! @param      hs_sdr25_mode_g       When operating clk @ 25Mhz or below, set '0'. @ above 25Mhz  set to '1'.
--!
--! @param      clk_divide_g          The sd card init clock should be close to 400k. 
--!                                 Specify this number to divide the 
--!                                 provided data clock to an ~400k init clock.  
--! @param      signalling_18_en_g  Set this bit to either attempt to change initialization to 
--!                                 switch into 1.8V signalling mode. This requires a differet ACMD41 in init
--!                                 as well as control of a level shifter in use with the lines of the sdcard. 
--!
--! @param      rst_n               Reset will cause the card to reinitialize immediately back 
--!                                 to the waiting for data state.
--!
--! @param      clk                 Data Transmission Clock. Clock can be from 400kHz 
--!                                 to 50MHz depending on timing of target device.
--! @param      clock_enable        Disable the component. The component will finish 
--!                                 its current write if writing, and then gate its clock.

--! @param      data_input          Data presented a byte at a time.   
--!                                 This is written into the component's buffer. 
--!                               
--! @param      data_we             Data is clocked into the internal buffer on the rising edge.
--!                                 Host should control this clock appropriately. 
--!                              
--! @param      data_full           Buffer is full. Stop sending data.
--!
--! @param      data_sd_start_address       The beginning block address on the card 
--!                                         the sent data should be written.
--!                              
--! @param      data_nblocks        The number of blocks the host intends 
--!                                 to send to component and write to SD card.
--!                              
--!
--! @param      data_current_block_written      This is the sd block address which 
--!                                             was last written successfully. It passed CRC response check.
--! @param      sd_block_written_flag           This flag is pulsed on successful block write.   
--!                                             data_current_block_written is valid.       
--!
--! @param      sd_clk              sd_clk wired to IO bank.          
--! @param      sd_cmd              sd_cmd wired to IO bank.      
--! @param      sd_dat              sd_dat wired to IO bank.  
--! 
--! @param      v_3_3_on_off        Wired to 3.3 switch on/off control. 
--!                                 Output of switch goes to level translator 
--!                                 sd card side bank control.
--! @param      v_1_8_on_off        Wired to 1.8 switch on/off control. 
--!                                 Output of switch goes to level translator 
--!                                 sd card side bank control.
--! @param      init_start          Start the init process.
--! @param      user_led_n_out      Data FSM encoding used for LEDs. 
--
----------------------------------------------------------------------------





entity microsd_controller_dir is
 generic(
    
    clk_freq_g                :natural    := 50E6;
    buf_size_g                :natural    := 2048;     
    block_size_g              :natural    := 512;    
		hs_sdr25_mode_g						:std_logic  := '1';                  
    clk_divide_g              :natural    := 128;
    signalling_18_en_g				:std_logic  := '0'  
    );

  port(

    rst_n           :in      std_logic;                                     
    clk             :in      std_logic;                                     
    clock_enable    :in      std_logic;                                     
    


    data_input      :in      std_logic_vector(7 downto 0);                  
    data_we         :in      std_logic;
    data_full       :out     std_logic;                                     


    
    data_sd_start_address     :in      std_logic_vector(31 downto 0);                 
    data_nblocks              :in      std_logic_vector(31 downto 0);                 
                       

                      
    data_current_block_written      :out     std_logic_vector(31 downto 0);                 
    sd_block_written_flag           :out     std_logic; 
    buffer_level                    :out     std_logic_vector (natural(trunc(log2(
                                    real(buf_size_g/block_size_g)))) downto 0); 


    sd_clk                          :out     std_logic;                                                                      
       
    sd_cmd_in                       : in      std_logic ;
    sd_cmd_out                      : out     std_logic ;
    sd_cmd_dir                      : out     std_logic ;
    sd_dat_in                       : in      std_logic_vector (3 downto 0) ;
    sd_dat_out                      : out     std_logic_vector (3 downto 0) ;
    sd_dat_dir                      : out     std_logic_vector (3 downto 0) ;                 


        
    v_3_3_on_off                    :out     std_logic;                                     
    v_1_8_on_off                    :out     std_logic;                                     
    
    init_start                      :in     std_logic;                                  
    user_led_n_out                  :out    std_logic_vector(3 downto 0);
    ext_trigger                     :out    std_logic

);
end microsd_controller_dir;


--A chunk of data of N blocks (a block is 512 bytes) is signalled to to 
--be written through use of data_nblocks.
--The card expects the N blocks to flow through its internal buffer. The 
--component should be presented with 
--data only on the rising edge of mem_clk and not when data_full is '1';
--The number of blocks to be written to the card will be written starting 
--at sd card block 
--address data_sd_start_address.
--data_nblocks represents the number of blocks (512 bytes each) which
--will be sent to the component's buffers and written to the sd card starting at 
--data_sd_start_address. The component will reset its buffers after it has 
--written data_nblocks blocks. 
--The component signals with the sd_block_written_flag pulse
--that the last block written at data_current_block_written 
--address was successful. The bidirectional lines are tri-states internally. 
--sd_cmd and sd_dat thus must be inout to top entity and tied to bidirectional pins.
--By default the card will transmit data at 3.3V signalling level. 
--To achieve a 1.8V signalling level a 
--level translator must be present between the FPGA GPIO and the sd card.
--The outputs of the switches 
--are tied together and routed to the voltage reference port of the level translator. 
--The component will handle the switching of the sd card side supply voltage pin 
--of the level translator. An internal signal of the design can also be 
--changed easily to run  the card in 
--3.3V mode if so desired.

architecture Behavioral of microsd_controller_dir is


component microsd_controller_inner 
	generic(
    
    clk_divide_g                      :natural;
    clk_freq_g                        :natural;
    signalling_18_en_g                :std_logic
    );
	port(

    clk							    :in	    std_logic; 							
    rst_n							  :in 	  std_logic;							
    sd_init_start			  :in	    std_logic;							
  
    sd_control				  :in	    std_logic_vector(7 downto 0);       
    sd_status						:out	  std_logic_vector(7 downto 0);      
  
    block_read_sd_addr		    :in	    std_logic_vector(31 downto 0);
    
    block_byte_data				    :out	std_logic_vector(7 downto 0);		
    block_byte_wren				    :out	std_logic;							
    block_byte_addr				    :out	std_logic_vector(8 downto 0) ;      

    block_write_sd_addr		    :in	  std_logic_vector(31 downto 0);      
    block_write_data			    :in 	std_logic_vector(7 downto 0);		
    num_blocks_to_write		    :in 	integer range 0 to 2**16 - 1;	 
  
    ram_read_address				:out 	std_logic_vector(8 downto 0); 	    
  
    erase_start					    :in 	std_logic_vector(31 downto 0);	    
    erase_end						    :in 	std_logic_vector(31 downto 0);	   

    dat0							:out	std_logic;                          
    dat1							:out	std_logic;                           
    dat2							:out	std_logic;
    dat3							:out	std_logic;                           
    cmd						    :out	std_logic;
    sclk							:out	std_logic;                           
     
    prev_block_write_sd_addr 	      :out	std_logic_vector(31 downto 0);   
    prev_block_write_sd_addr_pulse  :out	std_logic;						 

    cmd_write_en				:out std_logic;     
    D0_write_en				  :out std_logic;
    D1_write_en				  :out std_logic;
    D2_write_en				  :out std_logic;
    D3_write_en				  :out std_logic;

    cmd_signal_in			  :in	std_logic;      
    D0_signal_in				:in	std_logic;
    D1_signal_in				:in	std_logic;
    D2_signal_in				:in	std_logic;
    D3_signal_in				:in	std_logic;
    
    vc_18_on            :out    std_logic;
    vc_33_on            :out    std_logic;    

  
    hs_sdr25_mode_en			:in std_logic;      
    state_leds				    :out std_logic_vector(3 downto 0);  

    restart               :out std_logic;    

    init_done					:out std_logic;     

    ext_trigger				:out std_logic      
	
);
end component;
	

--Debug ram. I read data off the sd card and store it here. 
--Debuggable as its single clock single port. 
-- component ram_1_port IS
	-- PORT
	-- (
		-- address		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		-- clock		: IN STD_LOGIC  := '1';
		-- data		    : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		-- wren		    : IN STD_LOGIC ;
		-- q		    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	-- );
-- END component;



component microsd_buffer is
  generic(

    buf_size_g                      :   natural;
    block_size_g                    :   natural      
);
  port(
    rst_n                             :in      std_logic;
    clk                            		:in      std_logic;  
    mem_address						            :in 	   std_logic_vector(8 downto 0);
    data_out                          :out     std_logic_vector(7 downto 0);  
    data_input                        :in      std_logic_vector(7 downto 0);                  
   -- data_clk                          :in      std_logic;
    data_we                           :in      std_logic;
    data_full                         :out     std_logic;                 
    sd_write_rdy                      :out     std_logic;                                     
    sd_write_done						          :in		  std_logic;										
    buffer_reinit_done		            :out    std_logic;
    data_nblocks                      :in     std_logic_vector(31 downto 0);                 
    sd_block_written			            :in     std_logic;
    buffer_level                      :out    std_logic_vector (natural(
                                      trunc(log2(real(
                                      buf_size_g/block_size_g)))) 
                                      downto 0); 
    init_start						            :in 	  std_logic
);
end component;

--Signals to be sent to card.
signal  dat0_top_signal						:	std_logic;  				
signal  dat1_top_signal						:	std_logic;
signal  dat2_top_signal						:	std_logic;
signal  dat3_top_signal						:	std_logic;
signal  sclk_top_signal						:	std_logic;		
signal  cmd_top_signal						:	std_logic;
--Tri-State Read Signals
signal  cmd_top_signal_in					:	std_logic;     	    
signal  D0_top_signal_in			    :	std_logic;	
signal  D1_top_signal_in			    :	std_logic;	
signal  D2_top_signal_in			    :	std_logic;	
signal  D3_top_signal_in			    :	std_logic;	




signal clk_signal : std_logic;
attribute keep: boolean;
attribute keep of clk_signal: signal is true;

--sd_data will leave its APP_WAIT state to execute differt commands.
signal  sd_control_signal					:	std_logic_vector(7 downto 0); 
--Byte enconding of the current state of sd_data. Not complete or unique.       
signal  sd_status_signal					:	std_logic_vector(7 downto 0);       

---Where on sd card a block will be read.
signal  block_read_sd_addr_signal		    :	std_logic_vector(31 downto 0);      
--Read data from SD card memory
signal	block_byte_data_top			        :	std_logic_vector(7 downto 0);
--Signals that a data byte has been read. Ram wr_en.		
signal 	block_byte_wren_top			        :	std_logic;
--Address to write read data to in ram.							
signal  block_byte_addr_top			        :	std_logic_vector(8 downto 0);  

     
--The address for the current CMD25
signal  block_write_sd_addr_signal	    	:	std_logic_vector(31 downto 0);
--Data sent to card      
signal  block_write_data_signal		      	: std_logic_vector(7 downto 0);
--Number of blocks to be sent in any multiblock write.       
signal  num_blocks_to_write_signal		    :	integer range 0 to 2**16 - 1;       
--Start address for an erase.  
signal  erase_start_signal					:	std_logic_vector(31 downto 0);
--End   address for an erase. 	      
signal  erase_end_signal				    : std_logic_vector(31 downto 0); 
     
--Once off control signal for data_buffer_to_sd_data_handler process
signal  stop_write 							  :	std_logic;                          
--Used to simply push sd_data current state to Leds.
signal  state_leds_top						:	std_logic_vector(3 downto 0);   
    
--Enables for the tri-state output
signal  cmd_write_en_signal 		    :	std_logic;  
signal  D0_write_en_signal					:	std_logic;
signal  D1_write_en_signal					:	std_logic;
signal  D2_write_en_signal					:	std_logic;
signal  D3_write_en_signal					:	std_logic;


 --Where sd_data is going to fetch its data from to write to card
signal  ram_read_address_top			    :	std_logic_vector(8 downto 0);  


--Counter to keep track of how many blocks have been written to card
--using multiple cmd25s.  
signal  num_of_blocks_written 	    :   natural;    

--sd_init has finished init.
signal  init_done_top					    :   std_logic;  

                   
--Bit used to enable CMD6 hs_sdr25 mode transition 
--before first CMD25 in the data core. 
signal 	hs_sdr25_mode_en				    :   std_logic;      

--ext_trigger bit which can be used for an oscope.
signal	ext_trigger_top			            :   std_logic;       
 
   
--Bit signifying that buffer is either full OR data_nblocks number of 
--blocks has streamed and the card must first flush the buffer to the card.
signal 	buf_ful_top                         :   std_logic := '0';
--Bit signifying that buffer has at least 1 writeable block in it.       
signal 	sd_write_rdy_top                    :   std_logic := '0'; 
      
--clk_en gating signal.
signal 	shut_off 			                :   std_logic;  
--Main system clock. Renamed signal to allow shutoff with gating.
signal	clk_internal		              :   std_logic;  

--A CMD25 stream has finished.
signal 	sd_write_done_internal        :   std_logic;  
--data_buffer has finished reinit.
signal 	buffer_reinit_done_internal	  :   std_logic;  
--sd_block_written_flag. Last block finished crc receive check by the card.
signal 	sd_block_written_internal           :   std_logic;  

--Used to detect if the mem_clk has been started by the host.
signal mem_clk_started                      :   std_logic;  
signal mem_clk_started_follower             :   std_logic; 
signal data_we_active                       :   std_logic; 
signal data_we_active_r                     :   std_logic; 
signal data_we_active_r_follower            :   std_logic;



signal  restart_signal                      :   std_logic;
        

begin 

-- clk_signal <= clk;
	
sd_block_written_flag   <=  sd_block_written_internal;

user_led_n_out(3 downto 0)  <=  not state_leds_top;		

sd_clk  <=  sclk_top_signal	; 

	
	
i_microsd_controller_inner_0 :  microsd_controller_inner 
	generic map (
		clk_divide_g 				  =>	clk_divide_g,
    clk_freq_g            =>  clk_freq_g,
    signalling_18_en_g    =>  signalling_18_en_g
    )
	port map (
    clk						        => clk, 
    rst_n						      => rst_n,
 
    sd_init_start			    => init_start,	
    sd_control				    =>	sd_control_signal,
    sd_status					    =>	sd_status_signal,

    block_read_sd_addr	  =>	block_read_sd_addr_signal,

    cmd						    =>  cmd_top_signal,
    sclk					    =>	sclk_top_signal,
    dat0							=>	dat0_top_signal,
    dat1							=>	dat1_top_signal,
    dat2							=>	dat2_top_signal,
    dat3							=>	dat3_top_signal,
  
  
    block_write_sd_addr	            =>  block_write_sd_addr_signal,
    block_write_data 		            =>  block_write_data_signal,
    num_blocks_to_write	            =>	num_blocks_to_write_signal,
  
    block_byte_data		            =>  block_byte_data_top,
    block_byte_wren		            =>  block_byte_wren_top,
    block_byte_addr		            =>  block_byte_addr_top,
  
    erase_start				      =>  erase_start_signal,
    erase_end					      =>  erase_end_signal,
    cmd_write_en				    =>	cmd_write_en_signal,

    D0_write_en				        =>	D0_write_en_signal,
    D1_write_en				        =>	D1_write_en_signal,
    D2_write_en				        =>	D2_write_en_signal,
    D3_write_en				        =>	D3_write_en_signal,
    state_leds				        =>	state_leds_top,

    ram_read_address	    =>  ram_read_address_top,
    init_done					    =>  init_done_top,
    hs_sdr25_mode_en 	    =>  hs_sdr25_mode_en,
    vc_18_on              =>  V_1_8_ON_OFF,
    vc_33_on              =>  V_3_3_ON_OFF,

    cmd_signal_in			      =>	cmd_top_signal_in,
    D0_signal_in				    =>	D0_top_signal_in,
    D1_signal_in				    =>	D1_top_signal_in,
    D2_signal_in				    =>	D2_top_signal_in,
    D3_signal_in				    =>	D3_top_signal_in,
    
    restart                 => restart_signal,

    prev_block_write_sd_addr 		    => data_current_block_written,		
    prev_block_write_sd_addr_pulse  => sd_block_written_internal,	    

    ext_trigger				      => ext_trigger

    );
	
	
i_data_buffer_0: microsd_buffer 
	generic map (
		buf_size_g 						  => buf_size_g,
    block_size_g 						=> block_size_g
    )
  port map(
    rst_n           => rst_n,
    clk             => clk,            
    mem_address     => ram_read_address_top,
    data_out        => block_write_data_signal, 
    data_input      => data_input,  
    data_we         => data_we,
    --data_clk        => data_clk,
    data_full		    => data_full,        
    sd_write_rdy    => sd_write_rdy_top,        

    sd_write_done				    => sd_write_done_internal,
    buffer_reinit_done	    => buffer_reinit_done_internal,
    data_nblocks            => data_nblocks,
    sd_block_written	      => sd_block_written_internal,
    buffer_level            => buffer_level,
    init_start					    => init_start
  
    );
	

--Read to ram
--read_to_ram  : altsyncram
--	GENERIC MAP (
--		clock_enable_input_a => "BYPASS",
--		clock_enable_output_a => "BYPASS",
--		init_file => "../matlab scripts/512bytecount_zero.mif",
--		intended_device_family => "Cyclone V",
--		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=DEB",
--		lpm_type => "altsyncram",
--		numwords_a => 512,
--		operation_mode => "SINGLE_PORT",
--		outdata_aclr_a => "NONE",
--		outdata_reg_a => "CLOCK0",
--		power_up_uninitialized => "FALSE",
--		read_during_write_mode_port_a => "DONT_CARE",
--		widthad_a => 9,
--		width_a => 8,
--		width_byteena_a => 1
--	)
--	PORT MAP (
--		address_a => block_byte_addr_top,
--		clock0 => clk_internal,
--		data_a => block_byte_data_top,
--		wren_a => block_byte_wren_top
--		--q_a => sub_wire0 --I never read from the ram again, at least not now. 
--	);
	


tri_state_cmd: process(cmd_write_en_signal)
begin
    sd_cmd_out              <=    cmd_top_signal ;
    sd_cmd_dir              <=    cmd_write_en_signal ;

    if (cmd_write_en_signal = '1') then
        cmd_top_signal_in   <=    '1' ;
    else
        cmd_top_signal_in   <=    sd_cmd_in ;
    end if;
end process;


tri_state_D0: process(D0_write_en_signal)
begin
    sd_dat_out (0)          <=    dat0_top_signal ;
    sd_dat_dir (0)          <=    D0_write_en_signal ;

    if (D0_write_en_signal = '1') then
        D0_top_signal_in    <=    '1';
    else
        D0_top_signal_in    <=    sd_dat_in (0);
    end if;
end process;


tri_state_D1: process(D1_write_en_signal)
begin
    sd_dat_out (1)          <=    dat1_top_signal ;
    sd_dat_dir (1)          <=    D1_write_en_signal ;

    if (D1_write_en_signal = '1') then
        D1_top_signal_in    <=    '1';
    else
        D1_top_signal_in    <=    sd_dat_in (1);
    end if;
end process;

tri_state_D2: process(D2_write_en_signal)
begin
    sd_dat_out (2)          <=    dat2_top_signal ;
    sd_dat_dir (2)          <=    D2_write_en_signal ;

    if (D2_write_en_signal = '1') then
        D2_top_signal_in    <=    '1';
    else
        D2_top_signal_in    <=    sd_dat_in (2);
    end if;
end process;

tri_state_D3: process(D3_write_en_signal)
begin
    sd_dat_out (3)          <=    dat3_top_signal ;
    sd_dat_dir (3)          <=    D3_write_en_signal ;

    if (D3_write_en_signal = '1') then
        D3_top_signal_in    <=    '1';
    else
        D3_top_signal_in    <=    sd_dat_in (3);
    end if;
end process; 
--data_nblocks scales down to 128 if its over 128. 
--Otherwise data_nblocks is the number of blocks in a multiblock write.
num_blocks_to_write_signal <= to_integer(unsigned(data_nblocks)) 
                              when (to_integer(unsigned(data_nblocks)) < 128) 
                              else 128;  
        
 
                           
--Setting this bit makes the CMD6 in the data modes switch into SDR25 mode. 
--This should be on 25Mhz to 50Mhz.
--My finding abouts sending CMD6_HS. 
--@ 25Mhz this should be on for 3.3V and off for 1.8V. 
--Above 25Mhz it can be on. Below 25Mhz leave it off.                										
hs_sdr25_mode_en				<= hs_sdr25_mode_g;                   
                                                                   
                                                                    
block_read_sd_addr_signal <= x"00000000";

--This process controls sd_data through use of sd_control_signal. It also handles
--the sync of data between data_buffer and sd_data. 
--The process also is responsible for 
--sampling the start address provided on mem_clk start.
data_buffer_to_sd_data_handler: process(rst_n, clk)
begin
  if (rst_n = '0') then
    stop_write <= '0';
    sd_write_done_internal <= '0';
    num_of_blocks_written <= 0;
    block_write_sd_addr_signal <= x"00000000";
    sd_control_signal <= x"FF"; 
    sd_write_done_internal <= '0';
    mem_clk_started_follower <= '0';
  elsif rising_edge(clk) then

    if (buffer_reinit_done_internal = '1') then
      stop_write <= '0';
      sd_write_done_internal <= '0';
      num_of_blocks_written <= 0;
    end if;
  
    if (mem_clk_started_follower /= mem_clk_started) then
      mem_clk_started_follower <= mem_clk_started;
      --On the first rising edge of mem_clk after a buffer reinit 
      --(or power on) sample the start address.
      if (mem_clk_started = '1') then		
        block_write_sd_addr_signal <= data_sd_start_address;
      end if;
    end if;
    --If there is data in the buffer, begin
    if (sd_write_rdy_top = '1') then 	            
      if (stop_write = '0') then
        --if in idle state change address and data to write.
        if (sd_status_signal = x"01") then  
          --Which mode do we select. Single/m
          --x"44" is the 4 bit multiblock path
          sd_control_signal <= x"44";     
          --Number of single multiblock writes to do.
          num_of_blocks_written <= num_of_blocks_written + num_blocks_to_write_signal; 
          --Only send the sd_control_signal once per APP_WAIT.                       
          stop_write <= '1';              
        end if;
      else
        --We must wait past APP_WAIT of sd_data to change control signal. 
        --We wait until CMD12_INIT of microsd_data FSM. 
        --Works for both 1 bit and 4 bit writing. They both rely 
        --on CMD12 which signifies end of the multiblock write.		
        if (sd_status_signal = x"48") then	   
          --In process of writing data_nblock block 
          if (num_of_blocks_written = to_integer(unsigned(data_nblocks))) then
          --This system keeps track of how many blocks have been singly written. 
          --It will halt writing when the counter reaches X number of blocks. 
            stop_write <= '1';          
            sd_write_done_internal <= '1';
          else
            block_write_sd_addr_signal <= std_logic_vector(unsigned(
                      block_write_sd_addr_signal) + num_blocks_to_write_signal );
          --Keep writing and update the address to write next numb_blocks_to_write.
            stop_write <= '0';	         
          end if;
        sd_control_signal <= x"FF"; 
        end if;
      end if;
    end if;  
  end if;
end process data_buffer_to_sd_data_handler;


--Process to test one erase. TURN OFF WHEN NOTE IN USE
-- process(clk,rst_n)
	-- begin
  
-- if (rst_n = '0') then
    -- stop_write <= '0';
    -- sd_control_signal <= x"FF"; 

-- elsif rising_edge(clk) then
						-- if (stop_write = '0') then
								-- if (sd_status_signal = x"01") then --if in idle state change address and data to write.
                  -- sd_control_signal <= x"0E"; 
                  -- erase_start_signal <= std_logic_vector(to_unsigned(0, 32));
                  -- erase_end_signal <= std_logic_vector(to_unsigned(900000, 32));
								-- elsif (sd_status_signal = x"E0")then --Inside erase path
                  -- sd_control_signal <= x"FF"; 
                  -- stop_write <= '1';
								-- end if;
						-- end if;
		-- end if;
	-- end process;


--data_clk rising edge detection mechanism for grabbing first rising edge of any nblock set. 
--This process will fire first time and then every new nblock thereafter, latching address appropriately. 
buffer_reinit_data_clk_reset:process(rst_n, clk)
begin
  if (rst_n = '0') then
    mem_clk_started <= '0';
    data_we_active_r <= '0';
  elsif rising_edge(clk) then
    if(buffer_reinit_done_internal = '1') then
      mem_clk_started <= '0';
      data_we_active_r <= '1';
    elsif (data_we_active = '1') then
      mem_clk_started <= '1';
      data_we_active_r <= '0';
    end if;
  end if;
end process buffer_reinit_data_clk_reset;

data_clk_sense:process(rst_n, clk)
begin
  if(rst_n = '0') then
    data_we_active_r_follower <= '0';
    data_we_active <= '0';
  elsif rising_edge(clk) then
    if (data_we = '1') then
      if (data_we_active_r_follower /= data_we_active_r) then
        data_we_active_r_follower <= data_we_active_r;	
        if (data_we_active_r = '1') then
          data_we_active <= '0';
        end if;
      else
        data_we_active <= '1';
      end if;
    end if;
  end if;
end process data_clk_sense;

-- --clk_en process
-- --The internal clk will gate after the sd_data state
-- --machine returns to APP_WAIT.
-- clk_en_process: process(rst_n, clk)			
-- begin
-- if (rst_n = '0') then
-- shut_off <= '0';
-- elsif rising_edge(clk) then
	-- if(clock_enable = '0') then
		-- if (sd_status_signal = x"01") then
			-- shut_off <= '1';
    -- end if;
	-- else
			-- shut_off <= '0';
			
	-- end if;
-- end if;
-- end process clk_en_process;
		

end Behavioral;
