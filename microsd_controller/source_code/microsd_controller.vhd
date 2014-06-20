----------------------------------------------------------------------------------------------------
--
-- Filename:     	microsd_controller.vhd
-- Description:  	Source code for microsd serial data logger
-- Author:			Christopher Casebeer
-- Creation Date:	June 2014			
-----------------------------------------------------------------------------------------------------
--
-- Version 1.0
--
-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------
--            
--    Copyright (C) 2014  Ross K. Snider and Christopher C. Casebeer
--
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--    Christopher Casebeer
--    Electrical and Computer Engineering
--    Montana State University
--    610 Cobleigh Hall
--    Bozeman, MT 59717
--    christopher.casebee1@msu.montana.edu
--    
--


--In SD mode, data lines must be pulled up with a weak pull up resistor. 
--This can be accomplished with either the Assignment editor of quartus OR
--pull up resistors built into the socket is being used. For example, if GPIO 
--is used then program weak pull up. If SD card slot of BeMicroCV is used
--nothing else is needed. When using a level translator however, the lines 
--are simply set high prior to a receiving a low start bit. Pull up resistors 
--might not translate across level translator as was the case in this development. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ; 

--Library used for dual port ram.
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;





------------------------------------------------------------------------------
--
--! @brief      microsd_controller is the top component of the serial logging design.
--! @details    
--!
--! @param      BUFSIZE             Number of bytes in the buffer. Must be specified as N * 512 bytes.   
--! @param      HS_SDR25_MODE       When operating clk @ 25Mhz or below, set '0'. @ above 25Mhz  set to '1'.
--! @param      CLK_DIVIDE          The sd card init clock should be close to 400k. 
--!                                 Specify this number to divide the provided data clock to an ~400k init clock. 

--! @param      rst_n               Reset will cause the card to reinitialize immediately back 
--!                                 to the data_wait state.microsd_controller's address into the memory.
--!
--! @param      clk                 Data Transmission Clock. Clock can be from 400kHz 
--!                                 to 100MHz depending on timing of target device.
--! @param      clock_enable                Disable the component. The component will finish 
--!                                         its current write if writing, and then gate its clock.
--! @param      data_input                  Data presented a byte at a time.   
--!                                         This is written into the components buffers. 
--!                               
--! @param      data_we                     Data is clocked into the internal buffer on the rising edge.
--!                                         Host should control this clock appropriately. 
--!                              
--! @param      data_full                   Buffer is full. Stop sending data.
--!
--! @param      data_sd_start_address       The beginning address on the card the multiblock should be written.
--!                              
--! @param      data_nblocks     N blocks ready to be written into buffer and out to sd card.  
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
--! @param      V_3_3_ON_OFF        Wired to 3.3 switch on/off control. 
--!                                 Output of switch goes to level translator sd card side bank control.
--! @param      V_1_8_ON_OFF        Wired to 1.8 switch on/off control. 
--!                                 Output of switch goes to level translator sd card side bank control.
--! @param      init_start          Start the init process.
--! @param      user_led_n_out      Init start pushbutton or poweron. 
--
------------------------------------------------------------------------------





entity microsd_controller is
 generic(
    
    --BUFSIZE is the size of the internal buffer. It is N*512 bytes. 
        BUFSIZE                             :natural   := 2048;                 
		HS_SDR25_MODE						:std_logic := '1';                  
        CLK_DIVIDE                          :natural   := 128                   
    );

    port(

        rst_n                               :in      std_logic;                                     
        clk                                 :in      std_logic;                                     
        clock_enable                        :in      std_logic;                                     
        

   
        data_input                          :in      std_logic_vector(7 downto 0);                  
        data_we                             :in      std_logic;                                     
        data_full                           :out     std_logic;                                     


        
        data_sd_start_address               :in      std_logic_vector(31 downto 0);                 
        data_nblocks                        :in      std_logic_vector(31 downto 0);                 
                           

                          
        data_current_block_written          :out     std_logic_vector(31 downto 0);                 
        sd_block_written_flag               :out     std_logic;                                         

 
		sd_clk                         	    :out     std_logic;                                                                      
       
		sd_cmd                              :inout   std_logic;                                                            
        sd_dat                        		:inout   std_logic_vector(3 downto 0);                  


        
        V_3_3_ON_OFF                        :out     std_logic;                                     
        V_1_8_ON_OFF                        :out     std_logic;                                     
        
        
        --Personal Debug for now
        
        init_start                          :in     std_logic;                                  
        user_led_n_out                      :out    std_logic_vector(3 downto 0)

	);
end microsd_controller;


--!A chunk of data of N blocks (a block is 512 bytes) is signalled to to be written through use of data_nblocks.
--!The card expects the N blocks to flow through its internal buffer. The component should be presented with data only on the rising
--!edge of mem_clk and not when data_full is '1';
--!The number of blocks to be written to the card will be written starting at sd card block 
--!address data_sd_start_address. data_nblocks represents the number of blocks (512 bytes each) which
--!will be  to the component's buffers and written to the sd card starting at 
--!data_sd_start_address. The component will reset its buffers after it has written this data_nblocks blocks. 
--!The card signals with sd_block_written_flag pulse that the last block written at data_current_block_written address was successful.  
--!The bidirectional lines are tri-states internally. 
--!sd_cmd and sd_dat thus must be inout to top entity and tied to bidirectional pins.
--!By default the card will transmit data at 1.8V signalling level. To achieve this a 
--!level translator must be present between the FPGA GPIO (3.3V) and the sd card. The outputs of the switches are tied together.
--!and routed to the voltage reference port of the level translator. 
--!The component will handle the switching of the sd card side supply voltage pin 
--!of the level translator. An internal signal of the design can also be changed easily to run  the card in 3.3V mode if so desired.

architecture Behavioral of microsd_controller is


component microsd_controller_inner 
	generic(
    
        CLK_DIVIDE                      :natural                                   
    );
	port(

        clk							    :in	    std_logic; 							
        rst_n							:in 	std_logic;							
        sd_init_start					:in	    std_logic;							
		  

        sd_control					    :in	    std_logic_vector(7 downto 0);       
        sd_status						:out	std_logic_vector(7 downto 0);      
		  
        block_read_sd_addr			    :in	    std_logic_vector(31 downto 0);


        block_byte_data				    :out	std_logic_vector(7 downto 0);		
        block_byte_wren				    :out	std_logic;							
        block_byte_addr				    :out	std_logic_vector(8 downto 0) ;      

		
		  
        block_write_sd_addr			    :in	    std_logic_vector(31 downto 0);      
        block_write_data				:in 	std_logic_vector(7 downto 0);		
        num_blocks_to_write			    :in 	integer range 0 to 2**16 - 1;	 
		  
        ram_read_address				:out 	std_logic_vector(8 downto 0); 	    
		  
        erase_start					    :in 	std_logic_vector(31 downto 0);	    
        erase_end						:in 	std_logic_vector(31 downto 0);	   

          
		  dat0							:out	std_logic;                          
		  dat1							:out	std_logic;                           
		  dat2							:out	std_logic;
		  dat3							:out	std_logic;                           
		  cmd							:out	std_logic;
		  sclk							:out	std_logic;                           
		 
		  
		  prev_block_write_sd_addr 			:out	std_logic_vector(31 downto 0);   
		  prev_block_write_sd_addr_pulse    :out	std_logic;						 
		  
		  cmd_write_en				:out std_logic;     
		  D0_write_en				:out std_logic;
		  D1_write_en				:out std_logic;
		  D2_write_en				:out std_logic;
		  D3_write_en				:out std_logic;
		  
		  cmd_signal_in			    :in	std_logic;      
		  D0_signal_in				:in	std_logic;
		  D1_signal_in				:in	std_logic;
		  D2_signal_in				:in	std_logic;
		  D3_signal_in				:in	std_logic;
			
		  voltage_switch_en			:out std_logic;     
          signalling_18_en			:in std_logic;      
		  hs_sdr25_mode_en			:in std_logic;      
		  state_leds				:out std_logic_vector(3 downto 0);  
		  init_out_sclk_signal		:out std_logic;     
		  
		  init_done					:out std_logic;     

		  ext_trigger				:out std_logic      
	
	);
	end component;
	

-- --Debug ram. I read data off the sd card and store it here. Debuggable as its single clock single port. 
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



component data_buffer is
    generic(

        BUFSIZE                             :natural    
    );
    port(
        rst_n                               :in      std_logic;
        clk                            		:in      std_logic;  
		mem_address						    :in 	 std_logic_vector(8 downto 0);
        data_out                            :out     std_logic_vector(7 downto 0);  
		mem_output                          :in      std_logic_vector(7 downto 0);    
        mem_clk                             :in      std_logic;                                     
        sd_write_rdy                        :out     std_logic;                                     
		buf_ful								:out	 std_logic;
		sd_write_done						:in		 std_logic;										
		buffer_reinit_done					:out     std_logic;
		sd_write_count                 	    :in      std_logic_vector(31 downto 0);                 
		sd_block_written				    :in      std_logic;
		init_start						    :in 	 std_logic
    );
end component;


signal  dat0_top_signal						:	std_logic;  --Signals to be sent to card.				
signal  dat1_top_signal						:	std_logic;
signal  dat2_top_signal						:	std_logic;
signal  dat3_top_signal						:	std_logic;
signal  sclk_top_signal						:	std_logic;		
signal  cmd_top_signal						:	std_logic;

signal  cmd_top_signal_in					:	std_logic;  --Tri-State Read Signals   	    
signal  D0_top_signal_in			        :	std_logic;	
signal  D1_top_signal_in			        :	std_logic;	
signal  D2_top_signal_in			        :	std_logic;	
signal  D3_top_signal_in			        :	std_logic;	

signal  sd_control_signal					:	std_logic_vector(7 downto 0);       --sd_data will leave its APP_WAIT state to do execute differt commands. 
signal  sd_status_signal					:	std_logic_vector(7 downto 0);       --Byte enconding of the current state of sd_data. Not complete or unique.


signal  block_read_sd_addr_signal		    :	std_logic_vector(31 downto 0);      ---Where on sd card a block will be read.

signal	block_byte_data_top			        :	std_logic_vector(7 downto 0);		--Read data from SD card memory
signal 	block_byte_wren_top			        :	std_logic;							--Signals that a data byte has been red. Ram wr_en.
signal  block_byte_addr_top			        :	std_logic_vector(8 downto 0);       --Address to write read data to in ram.

signal  block_write_sd_addr_signal	    	:	std_logic_vector(31 downto 0);      --The address for the current CMD25
signal  block_write_data_signal		      	: 	std_logic_vector(7 downto 0);       --Data sent to card
signal  num_blocks_to_write_signal		    :	integer range 0 to 2**16 - 1;       --Number of blocks to be sent in any multiblock write.

signal  erase_start_signal					:	std_logic_vector(31 downto 0);	    --Start address for an erase.    
signal  erase_end_signal				    : 	std_logic_vector(31 downto 0);      --End   address for an erase. 

signal  stop_write 							:	std_logic;                          --Once off control signal for sd_buffer_to_sd_data process

signal  state_leds_top						:	std_logic_vector(3 downto 0);       --Used to simply push sd_data current state to Leds.

signal  cmd_write_en_signal 		        :	std_logic;  --Enables for the tri-state output
signal  D0_write_en_signal					:	std_logic;
signal  D1_write_en_signal					:	std_logic;
signal  D2_write_en_signal					:	std_logic;
signal  D3_write_en_signal					:	std_logic;

signal  ram_read_address_top			    :	std_logic_vector(8 downto 0);   --Where sd_data is going to fetch its data from to write to card

signal  num_of_single_blocks_to_write 	    :   natural;    --Counter to keep track of how many blocks have been written. 

signal  init_done_top					    :   std_logic;  --sd_init has finished init.

signal 	voltage_switch_en_top			    :   std_logic ; --Starts the switching process on the voltages.
signal 	voltage_switch_lag_counter		    :   integer range 0 to 2**4 - 1;    --Wait time between 3.3V off and 1.8V on
signal 	voltage_switch_run				    :   std_logic;                      --The voltage switch has finished.

signal	signalling_18_en				    :   std_logic;      --Bit used to enable 1.8V transition during init.
signal 	hs_sdr25_mode_en				    :   std_logic;      --Bit used to enable CMD6 hs_sdr25 mode transition before first CMD25 in the data core.

signal	ext_trigger_top			            :   std_logic;      --ext_trigger bit which can be used for an oscope.

signal  VC_22966_33_ON	                    :	std_logic;	    --Voltage switch on_off bit.
signal  VC_22966_18_ON	                    :	std_logic;	    --Voltage switch on_off bit.

signal	init_sclk_signal_top                :   std_logic;      --Clk used in association with switch on_off process. Slower init clock. Switch happens during init.

signal 	buf_ful_top                         :   std_logic := '0';       --Bit signifying that buffer is either full OR data_nblocks number of blocks has streamedand the card must first flush the buffer to the card.
signal 	sd_write_rdy_top                    :   std_logic := '0';       --Bit signifying that buffer has at least 1 writeable block in it.

signal 	shut_off 			                :   std_logic;  --Bit flag set which will gate clock upon setting enable bit of the entire component to '0'. 
signal	clk_internal		                :   std_logic;  --Main system clock. Renamed signal to allow shutoff with gating.

signal 	sd_write_done_internal          	:   std_logic;  --The current block passed crc receive check by the sd card.
signal 	buffer_reinit_done_internal	        :   std_logic;  --data_buffer has finished reinit.
signal 	sd_block_written_internal           :   std_logic;  --sd_block_written_flag. Last block finished crc receive check by the card.

signal mem_clk_started                      :   std_logic; --Used to detect if the mem_clk has been started by the host. 
signal mem_clk_started_follower             :   std_logic; --Used to detect if the mem_clk has been started by the host. 	
signal data_we_active                       :   std_logic; --Used to detect if the mem_clk has been started by the host. 
signal data_we_active_r                     :   std_logic; --Used to detect if the mem_clk has been started by the host.
signal data_we_active_r_follower            :   std_logic; --Used to detect if the mem_clk has been started by the host.
        
    

	begin 


 		
	data_full                       <=      buf_ful_top;

	V_3_3_ON_OFF                    <= 	    VC_22966_33_ON ;
	V_1_8_ON_OFF                    <= 	    VC_22966_18_ON ;
	
	sd_block_written_flag           <=      sd_block_written_internal;
	
	clk_internal                    <=      clk when (shut_off = '0') else '0';
    
    user_led_n_out(3 downto 0) 	    <=	    not state_leds_top;		
    
    sd_clk						    <=      sclk_top_signal	; 

	
	
i_microsd_controller_inner_0 :  microsd_controller_inner 
	generic map (
		CLK_DIVIDE 					    =>	CLK_DIVIDE
	)
	port map (
		  --System Signals
        clk						        => clk_internal, 
        rst_n						    => rst_n,
		 
        sd_init_start			        => init_start,	
		  --Control Signals
        sd_control				        =>	sd_control_signal,
        sd_status					    =>	sd_status_signal,
 

        block_read_sd_addr		        =>	block_read_sd_addr_signal,
		
		  --SD Signals
        cmd						        =>  cmd_top_signal,
        sclk						    =>	sclk_top_signal,
        dat0							=>	dat0_top_signal,
        dat1							=>	dat1_top_signal,
        dat2							=>	dat2_top_signal,
        dat3							=>	dat3_top_signal,
		  
		  
        block_write_sd_addr	            =>  block_write_sd_addr_signal,
        block_write_data 		        =>  block_write_data_signal,
        num_blocks_to_write	            =>	num_blocks_to_write_signal,
		  
        block_byte_data		            =>  block_byte_data_top,
        block_byte_wren		            =>  block_byte_wren_top,
        block_byte_addr		            =>  block_byte_addr_top,
		  
        erase_start				        =>  erase_start_signal,
        erase_end					    =>  erase_end_signal,
        cmd_write_en				    =>	cmd_write_en_signal,

        D0_write_en				        =>	D0_write_en_signal,
        D1_write_en				        =>	D1_write_en_signal,
        D2_write_en				        =>	D2_write_en_signal,
        D3_write_en				        =>	D3_write_en_signal,
        state_leds				        =>	state_leds_top,

        ram_read_address		        =>  ram_read_address_top,
        init_done					    =>  init_done_top,
        voltage_switch_en               =>  voltage_switch_en_top,
        hs_sdr25_mode_en 	            =>  hs_sdr25_mode_en,
        signalling_18_en			    =>  signalling_18_en,
        init_out_sclk_signal            =>  init_sclk_signal_top,

        cmd_signal_in			        =>	cmd_top_signal_in,
        D0_signal_in				    =>	D0_top_signal_in,
        D1_signal_in				    =>	D1_top_signal_in,
        D2_signal_in				    =>	D2_top_signal_in,
        D3_signal_in				    =>	D3_top_signal_in,

        prev_block_write_sd_addr 		=> data_current_block_written,		
        prev_block_write_sd_addr_pulse  => sd_block_written_internal,	    

        ext_trigger				        => ext_trigger_top

	);
	
	
i_data_buffer_0: data_buffer 
	generic map (
		BUFSIZE 						=> BUFSIZE
	)
    port map(
        rst_n                           => rst_n,
        clk                             => clk_internal,            
        mem_address			            => ram_read_address_top,
		data_out                        => block_write_data_signal, 
        mem_output                      => data_input,                  	  
        mem_clk                         => data_we,                 
        sd_write_rdy                    => sd_write_rdy_top,        
		buf_ful					        => buf_ful_top,
		sd_write_done				    => sd_write_done_internal,
		buffer_reinit_done			    => buffer_reinit_done_internal,
		sd_write_count                  => data_nblocks,
        sd_block_written			    => sd_block_written_internal,
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
	


--Internal Tri-State of all bidirectional lines.
tri_state_cmd: process(cmd_write_en_signal)
begin 
    if (cmd_write_en_signal = '1') then				
        sd_cmd			    <=      cmd_top_signal;
        cmd_top_signal_in   <= 		'1'	;
    else
        sd_cmd			    <=      'Z';
        cmd_top_signal_in   <=      sd_cmd	;
    end if;
end process; 


tri_state_D0: process(D0_write_en_signal)
begin 
    if (D0_write_en_signal = '1') then
        sd_dat(0)		    <=      dat0_top_signal;
        D0_top_signal_in 	<=      '1';
    else
        sd_dat(0)		    <=      'Z';
        D0_top_signal_in 	<=      sd_dat(0);
    end if;
end process; 


tri_state_D1: process(D1_write_en_signal)
begin 
    if (D1_write_en_signal = '1') then
        sd_dat(1)		    <=       dat1_top_signal;
        D1_top_signal_in    <=      '1';
    else
        sd_dat(1)		    <=      'Z';
        D1_top_signal_in    <=  	sd_dat(1);
    end if;
end process; 

tri_state_D2: process(D2_write_en_signal)
begin 
    if (D2_write_en_signal = '1') then
        sd_dat(2)		    <= dat2_top_signal;
        D2_top_signal_in 	<= '1';
    else
        sd_dat(2)		    <= 'Z';
        D2_top_signal_in    <=	sd_dat(2);
    end if;
end process; 

tri_state_D3: process(D3_write_en_signal)
begin 
    if (D3_write_en_signal = '1') then
        
        sd_dat(3)		    <=      dat3_top_signal;
        D3_top_signal_in    <=      '1';
    else

        sd_dat(3)		    <=      'Z';
        D3_top_signal_in    <= 	    sd_dat(3)	;
    end if;
end process; 
--data_nblocks scales down to 128 if its over. Otherwise data_nblocks is the number of multiblocks.
num_blocks_to_write_signal <= to_integer(unsigned(data_nblocks)) when (to_integer(unsigned(data_nblocks)) < 128) else 128;  
        
--If 3.3V mode is desired, set this bit to 0.
signalling_18_en				<= '1';  
                           
--Setting this bit makes the CMD6 in the data modes switch into SDR25 mode. This should be on 25Mhz to 50Mhz.
--My finding abouts sending CMD6_HS. @ 25Mhz this should be on for any 33 and off for 18. 
-- Above 25Mhz it can be on. Below 25Mhz leave it off.                										
hs_sdr25_mode_en				<= HS_SDR25_MODE;                   
                                                                   
                                                                    
block_read_sd_addr_signal <= x"00000000";

--This process controls sd_data through use of sd_control_signal. It also handles
--the sync of data between data_buffer and sd_data. 
--The process also is responsible for sampling the start address provided on mem_clk start.
data_buffer_to_sd_data_handler:process(rst_n, clk_internal)
begin
    if (rst_n = '0') then
        stop_write <= '0';
        sd_write_done_internal <= '0';
        num_of_single_blocks_to_write <= 0;
        block_write_sd_addr_signal <= x"00000000";
        sd_control_signal <= x"FF"; 
        sd_write_done_internal <= '0';
        mem_clk_started_follower <= '0';
    elsif rising_edge(clk_internal) then
		
        if (buffer_reinit_done_internal = '1') then
            stop_write <= '0';
            sd_write_done_internal <= '0';
            num_of_single_blocks_to_write <= 0;
    
        end if;
        
        if (mem_clk_started_follower /= mem_clk_started) then
            mem_clk_started_follower <= mem_clk_started;
            
            if (mem_clk_started = '1') then		--On the first rising edge of mem_clk after a buffer reinit (or power on) sample the start address.

                block_write_sd_addr_signal <= data_sd_start_address;

            end if;
        end if;
        --If there is some data in the buffer, begin
        if (sd_write_rdy_top = '1') then 	            
            if (stop_write = '0') then
                --if in idle state change address and data to write.
                if (sd_status_signal = x"01") then  
                    --Which mode do we select. Single/m
                    sd_control_signal <= x"44";     
                    --Number of single multiblock writes to do.
                    num_of_single_blocks_to_write <= num_of_single_blocks_to_write + num_blocks_to_write_signal; 
                    --APP_WAIT is longer than 1 50_MHZ clock, so a stop bit is need so one increment once.                        
                    stop_write <= '1';              
                    
                end if;
            else
			    --Must wait past APP_WAIT of sd_data to change control signal. CMD12_INIT end of multiblock transmit. 
                --Works for both 1 bit and 4 bit writing. They both rely on CMD12.		
                if (sd_status_signal = x"48") then	   
                    --In process of writing 2048th block. 
                    if (num_of_single_blocks_to_write = to_integer(unsigned(data_nblocks))) then
                            --This system keeps track of how many blocks have been singly written. 
                            --It will halt writing when the counter reach X number of blocks. 
                            stop_write <= '1';          
                            sd_write_done_internal <= '1';
                    else
                            block_write_sd_addr_signal <= std_logic_vector(unsigned(block_write_sd_addr_signal) + num_blocks_to_write_signal );
                            stop_write <= '0';	        --Keep writing. 
                    end if;
                sd_control_signal <= x"FF"; 
                end if;
            end if;
        end if;
				
			
    end if;
end process data_buffer_to_sd_data_handler;


--data_clk rising edge detection mech for grabbing first rising edge of any nblock set. 
--Will fire first time and then every new nblock thereafter, latching address appropriately. 
buffer_reinit_data_clk_reset:process(rst_n, clk_internal)
begin
if (rst_n = '0') then
mem_clk_started <= '0';
data_we_active_r <= '0';
elsif rising_edge(clk_internal) then
    if(buffer_reinit_done_internal = '1') then
        mem_clk_started <= '0';
        data_we_active_r <= '1';
    elsif (data_we_active = '1') then
        mem_clk_started <= '1';
        data_we_active_r <= '0';
	end if;
end if;
end process buffer_reinit_data_clk_reset;

data_clk_sense:process(rst_n, data_we)
begin
if(rst_n = '0') then
    data_we_active_r_follower <= '0';
    data_we_active <= '0';
elsif rising_edge(data_we) then	
    if (data_we_active_r_follower /= data_we_active_r) then
    data_we_active_r_follower <= data_we_active_r;	
        if (data_we_active_r = '1') then
            data_we_active <= '0';
        end if;
    else
        data_we_active <= '1';
    end if;
end if;
end process data_clk_sense;


--Here the voltage on the signal lines is changed through 
--interacting with the switch controlling the voltage level pin of the level translator.
voltage_switch_process: process(rst_n, init_sclk_signal_top)			--Sclk is ~400kHz.
begin
if(rst_n = '0') then
    VC_22966_33_ON	<= '1';	
    VC_22966_18_ON	<= '0';	
    voltage_switch_run <= '0';
    voltage_switch_lag_counter <= 0;
elsif rising_edge(init_sclk_signal_top) then
    if (voltage_switch_run = '0') then
        if ( voltage_switch_en_top = '1') then
            if (voltage_switch_lag_counter =  6) then
            
             VC_22966_33_ON	<=  '0';	
             VC_22966_18_ON	<= '1';
             voltage_switch_run <= '1';
             
            else
            
             VC_22966_33_ON	<= '0';	
             VC_22966_18_ON	<= '0';	
             voltage_switch_run <= '0';
             voltage_switch_lag_counter <=  voltage_switch_lag_counter + 1;
             
             end if;
        
        else
        
         VC_22966_33_ON	<= '1';	
         VC_22966_18_ON	<= '0';	
         voltage_switch_run <= '0';
        
        end if ;

    else
    
    end if;
		
end if;
		
end process voltage_switch_process;

--clk_en process
--The internal clk will gate after the sd_data state
--machine returns to APP_WAIT.
clk_en_process: process(rst_n, clk_internal)			
begin
if (rst_n = '0') then

shut_off <= '0';

elsif rising_edge(clk_internal) then

	if(clock_enable = '0') then
		if (sd_status_signal = x"01") then
			shut_off <= '1';
			end if;
	else
			shut_off <= '0';
			
	end if;

		
end if;
		
end process clk_en_process;
		

end Behavioral;
