----------------------------------------------------------------------------------------------------
-- Filename:     	microsd_controller_inner.vhd
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
--    Copyright (C) 2014  Ross K. Snider and Christopher N. Casebeer
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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;




------------------------------------------------------------------------------
--
--! @brief      sd_data is the portion of microsd_controller which handles write comms with sd card.
--! @details     
--!
--! @param      clk             Input clock, Data Component Logic Clk and Data Transmission Clock  
--! @param      rst_n           Start signal from input pushbutton
--! @param      sd_init_start           Reset to initial conditions.
--! @param      sd_control              Used to select pathway in Data Component.
--! @param      sd_status               Current State of State Machine.
--!
--! @param      block_byte_data         Read data from SD card memory
--! @param      block_byte_wren         Signals that a data byte has been read. Ram wr_en.    
--! @param      block_read_sd_addr      Address to read block from on sd card.
--!                               
--! @param      block_byte_addr         Address to write read data to in ram..
--!                              
--! @param      block_write_sd_addr     Address where block is written on sd card.
--!
--! @param      block_write_data        Byte that will be written
--!                              
--! @param      num_blocks_to_write     Number of blocks to be written in CMD25.
--!                              
--!
--! @param      ram_read_address        Where block_write_data is read from.
--! @param      erase_start             Start address of erase.
--!
--! @param      erase_end               Stop address of erase.
--! @param      state_leds              Used to encode current state to Leds.
--! @param      prev_block_write_sd_addr        The last address to be successfully written valid on
--!                                             prev_block_write_sd_addr_pulse '1'
--!
--! @param      prev_block_write_sd_addr_pulse  prev_block_write_sd_addr is valid
--!
--! @param      cmd_write_en                    Tri State Enable
--! @param      D0_write_en         Tri State Enable  
--! @param      D1_write_en         Tri State Enable  
--! @param      D2_write_en         Tri State Enable
--! @param      D3_write_en         Tri State Enable 
--!
--! @param      cmd_signal_in       Read value of the tri-stated line.
--! @param      D0_signal_in        Read value of the tri-stated line.   
--! @param      D1_signal_in        Read value of the tri-stated line.   
--! @param      D2_signal_in        Read value of the tri-stated line.   
--! @param      D3_signal_in        Read value of the tri-stated line. 
--!  
--! @param      card_rca            Card RCA is passed from init.
--! @param      init_done           Card has passed init phase.
--! @param      signalling_18_en    Card should go into 1.8V mode during init.
--! @param      hs_sdr25_mode_en        Card should transition to hs_sdr25 mode before first CMD25. 
--! @param      init_out_sclk_signal      400k init clocked out to voltage switching process.
--! @param      voltage_switch_en      Enable voltage switching sequence.
--!    
--! @param      dat0                dat0 line out
--! @param      dat1                dat1 line out
--! @param      dat2                dat2 line out
--! @param      dat3                dat3 line out
--! @param      cmd                 cmd line out
--! @param      sclk                clk sent to sd card
--!
--! @param      ext_trigger         External trigger bit. Used to trigger an Oscope if need arise.
--!
--
------------------------------------------------------------------------------    


entity microsd_controller_inner is
 generic(
    
        CLK_DIVIDE                          :natural                                    
    );
	port(

        clk								    :in	    std_logic;                          
        rst_n							    :in	    std_logic;
        sd_init_start				        :in	    std_logic;	                        
		  
		
        sd_control					        :in	    std_logic_vector(7 downto 0);       
        sd_status						    :out	std_logic_vector(7 downto 0);       
		  

        block_byte_data			            :out	std_logic_vector(7 downto 0);		
        block_byte_wren			            :out	std_logic;							
        block_read_sd_addr			        :in	    std_logic_vector(31 downto 0);      
        block_byte_addr			            :out	std_logic_vector(8 downto 0) ;     
       
  
        block_write_sd_addr		            :in	    std_logic_vector(31 downto 0);     
        block_write_data			        :in	    std_logic_vector(7 downto 0);       
        num_blocks_to_write		            :in     integer range 0 to 2**16 - 1;	    
        ram_read_address				    :out    std_logic_vector(8 downto 0);       
		  
        erase_start					        :in 	std_logic_vector(31 downto 0);      
        erase_end						    :in 	std_logic_vector(31 downto 0);     
		  
        state_leds					        :out	std_logic_vector(3 downto 0);       
		  
        prev_block_write_sd_addr 			:out	std_logic_vector(31 downto 0);		
        prev_block_write_sd_addr_pulse      :out	std_logic;
		  
        cmd_write_en					    :out    std_logic;                      
        D0_write_en					        :out    std_logic;
        D1_write_en					        :out    std_logic;
        D2_write_en					        :out    std_logic;
        D3_write_en					        :out    std_logic;
		  
        cmd_signal_in					    :in 	std_logic;                         
        D0_signal_in					    :in	    std_logic;
        D1_signal_in					    :in	    std_logic;
        D2_signal_in					    :in	    std_logic;
        D3_signal_in					    :in	    std_logic;
		  

        init_done						    :out    std_logic;                         
        signalling_18_en			        :in     std_logic;                          
        hs_sdr25_mode_en				    :in     std_logic;                       

        init_out_sclk_signal			    :out    std_logic;                          
            
    --SD Signals 
        voltage_switch_en			        :out    std_logic;                         
        dat0							    :out	std_logic;
        dat1							    :out	std_logic;
        dat2							    :out	std_logic;
        dat3							    :out	std_logic;
        cmd								    :out	std_logic;
        sclk							    :out	std_logic;
     
		  
		    
        ext_trigger				            :out     std_logic                          

	);
end microsd_controller_inner;

--! microsd_controller inner simply muxes sd_init and sd_data control lines and signals
--! It also generates the 400k init clock.
--! 

architecture Behavioral of microsd_controller_inner is
	


component sd_init
    port(
        clk					:in	    std_logic;	
        rst_n 				:in	    std_logic;	
        sd_init_start		:in	    std_logic;	
        dat0 			    :out    std_logic;	
        cmd 			    :out    std_logic;	
        sclk 		        :out    std_logic;	
        dat3 			    :out    std_logic;	
        D0_signal_in  		:in	    std_logic;  
        voltage_switch_en	:out    std_logic;  
        init_done			:out	std_logic;	
        signalling_18_en	:in     std_logic;			
        cmd_write_en		:out 	std_logic;  
        cmd_signal_in  	    :in	    std_logic;  
        rca_out				:out	std_logic_vector(15 downto 0);
        state_leds			:out	std_logic_vector(3 downto 0)	
        
        );
end component;
	
component sd_data
    port(
        clk				        :in	    std_logic;	
      
        rst_n 			        :in	    std_logic;	
        dat0 			        :out	std_logic;	
        cmd 		            :out    std_logic;	
        sclk 			        :out    std_logic;	
        dat3 			        :out    std_logic;	
        dat1 			        :out    std_logic;	
        dat2 		            :out    std_logic;	
    
        
        cmd_signal_in  	        :in	    std_logic; 
        D0_signal_in  	        :in	    std_logic;  
        
        
        cmd_write_en	        :out    std_logic; 
        D0_write_en		        :out	 std_logic;	
        D1_write_en		        :out	 std_logic;	
        D2_write_en		        :out	 std_logic;	
        D3_write_en		        :out	 std_logic;	
        
        card_rca 		        :in	    std_logic_vector(15 downto 0);      

        init_done		        :in	    std_logic;	                        
        block_byte_data	        :out	std_logic_vector(7 downto 0);		
        block_byte_wren	        :out	std_logic;							
        block_byte_addr		    :out	std_logic_vector(8 downto 0) ;      
        block_read_sd_addr	    :in	    std_logic_vector(31 downto 0);      
        block_write_sd_addr	    :in	    std_logic_vector(31 downto 0);

        sd_control		        :in	    std_logic_vector(7 downto 0);		
        sd_status			    :out	std_logic_vector(7 downto 0);		
        state_leds			    :out	std_logic_vector(3 downto 0);		
      
        prev_block_write_sd_addr 	    :out	std_logic_vector(31 downto 0);		
        prev_block_write_sd_addr_pulse  :out	std_logic;
      
        erase_start			    :in 	std_logic_vector(31 downto 0);	     
        erase_end		        :in 	std_logic_vector(31 downto 0);	     
        
        hs_sdr25_mode_en	    :in     std_logic;                           
     
        ext_trigger			    :out    std_logic;                           

        ram_read_address	    :out    std_logic_vector(8 downto 0);           
        num_blocks_to_write	    :in 	integer range 0 to 2**16 - 1;        
        block_write_data	    :in     std_logic_vector(7 downto 0)         
        );
end component;
	

-----------------------
--Signal Declarations--
-----------------------

-- Input Signals
signal sd_init_start_signal	:std_logic;

-- Clock Signals
signal clk_400k_signal				:std_logic;
signal clk_400k_count				:integer range 0 to 2**9 - 1;

-- SD_INIT  Signals
signal init_dat0_signal				:std_logic;
signal	init_cmd_signal				:std_logic;
signal	init_sclk_signal			:std_logic;
signal	init_dat3_signal			:std_logic;
signal 	init_done_signal			:std_logic;
signal 	init_state_leds_signal		:std_logic_vector(3 downto 0);
signal  cmd_write_en_init			:std_logic;

-- SD_DATA Signals
signal	data_cmd_signal				:std_logic;
signal	data_sclk_signal			:std_logic;
signal	data_dat3_signal			:std_logic;
signal	data_state_leds_signal		:std_logic_vector(3 downto 0);
signal 	data_dat0_signal			:std_logic;
signal  cmd_write_en_data			:std_logic;	
signal  card_rca_signal			    :std_logic_vector(15 downto 0);
	

	
begin	

sd_init_start_signal <= sd_init_start;

init_done <= init_done_signal;

init_out_sclk_signal <= clk_400k_signal;
	
i_sd_init_0:	sd_init
    port map(
                    clk			        => clk_400k_signal,
                    rst_n 		        => rst_n,
                    sd_init_start       => sd_init_start_signal,
                    dat0 		    	=> init_dat0_signal,
                    cmd 			    => init_cmd_signal,
                    sclk 		    	=> init_sclk_signal,
                    dat3 			    => init_dat3_signal,
                    D0_signal_in  		=> D0_signal_in,
                    voltage_switch_en   => voltage_switch_en,
                    init_done	        => init_done_signal,
                     signalling_18_en	=> signalling_18_en,
                    cmd_write_en        => cmd_write_en_init,
                    cmd_signal_in       => cmd_signal_in,
                    state_leds	        => init_state_leds_signal,
                    rca_out             => card_rca_signal
    
            );
				
i_sd_data_0:	sd_data
    port map(
            clk								=>  clk, 
            rst_n 							=>  rst_n,	 
            dat0 							=>  data_dat0_signal,
            cmd 							=>  data_cmd_signal,
            sclk 							=>  data_sclk_signal,
            dat3 							=>  data_dat3_signal,
            dat1							=>  dat1,
            dat2							=>  dat2,
            cmd_write_en 				    =>  cmd_write_en_data,
            cmd_signal_in 				    =>  cmd_signal_in,
            D0_write_en 					=>  D0_write_en,
            D1_write_en 					=>  D1_write_en,
            D2_write_en 					=>  D2_write_en,
            D3_write_en 					=>  D3_write_en,
            D0_signal_in 				    =>  D0_signal_in,
            card_rca						=>  card_rca_signal,
            init_done						=>  init_done_signal,
            block_read_sd_addr			    =>  block_read_sd_addr,

            block_byte_data		            =>	block_byte_data	,				
            block_byte_wren		            =>	block_byte_wren,
            block_byte_addr		            =>	block_byte_addr	,
                    
                    
            prev_block_write_sd_addr        =>  prev_block_write_sd_addr,
            prev_block_write_sd_addr_pulse  =>  prev_block_write_sd_addr_pulse ,
            
            hs_sdr25_mode_en		        =>  hs_sdr25_mode_en,
                    
            block_write_sd_addr		        =>  block_write_sd_addr,
            block_write_data			    =>	block_write_data, 

            sd_control			            =>  sd_control,
            sd_status				        =>  sd_status,
            state_leds			            =>  data_state_leds_signal,
            num_blocks_to_write		        =>  num_blocks_to_write,
            erase_start			            =>	erase_start,
            ram_read_address			    =>  ram_read_address,
                
            ext_trigger			            =>  ext_trigger	,		
            erase_end				        =>	erase_end
            
        );
			

	
	
	
	with init_done_signal select 
			sclk  <=	data_sclk_signal when '1',
						init_sclk_signal when others;
						
	with init_done_signal select 
			cmd  <=	data_cmd_signal when '1',
						init_cmd_signal when others;
						
	with init_done_signal select 
			dat0  <=	data_dat0_signal when '1',
						init_dat0_signal when others;
						
	with init_done_signal select 
			dat3  <=	data_dat3_signal when '1',
						init_dat3_signal when others;
						
	with init_done_signal select 
			state_leds  <=	data_state_leds_signal when '1',
								init_state_leds_signal when others;
						
	with init_done_signal select 
			cmd_write_en  <=	cmd_write_en_data when '1',
									cmd_write_en_init when others;



	--Generate the 400k clock using the CLK_DIVIDE generic.
process(rst_n,clk)
begin
if (rst_n = '0') then

	clk_400k_signal <= '0';
	clk_400k_count <= 0;

elsif rising_edge(clk) then



            if(clk_400k_count = CLK_DIVIDE/2 - 1) then			--Divides by (count+1)*2 MHZ.
				clk_400k_signal <= not clk_400k_signal;
				clk_400k_count <= 0;
			elsif(init_done_signal = '1') then		
				clk_400k_signal <= '0';
				clk_400k_count <= 0;
			else
				clk_400k_count <= clk_400k_count + 1;	

			end if;			
		end if;
	end process;




end Behavioral;

