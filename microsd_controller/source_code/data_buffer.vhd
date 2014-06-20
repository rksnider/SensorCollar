----------------------------------------------------------------------------------------------------
--
-- Filename:     	data_buffer.vhd
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
--    541 Cobleigh Hall
--    Bozeman, MT 59717
--    christopher.casebee1@msu.montana.edu
--    
--



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ;     
 
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;



------------------------------------------------------------------------------
--
--! @brief      Data buffer of the microsd_controller
--! @details    The host puts data here while the card is busy writing that data. 
--!
--! @param      BUFSIZE         Number of bytes in the double buffer. Must be specified as N * 512 bytes.   
--! @param      rst_n           Reset to initial conditions.
--! @param      clk             Data Transmission Clock. Clock can be from 400kHz to 100MHz 
--!                             depending on timing of target device.
--! @param      mem_address     microsd_controller's address into the memory.
--!
--! @param      data_out        Data presented a byte at a time. 
--! @param      mem_output      Data presented a byte at a time.     
--! @param      mem_clk         Data is clocked into the circular buffer on the rising edge.
--!                               
--! @param      sd_write_rdy    Go bit for the sd card to start writing.
--!                              
--! @param      buf_ful         Buffer is full. Signal to the host.
--!
--! @param      sd_write_done   N blocks has been written. Reset the buffer to accept more data.
--!                              
--! @param      buffer_reinit_done  Signal to microsd_controller that  buffer reinit is done.
--!                              
--!
--! @param      sd_write_count      N blocks ready to be written into buffer and out to sd card.
--! @param      sd_block_written    Block received succesfully by the sd card.
--!
--! @param      init_start      Init start pushbutton or poweron.  
--
------------------------------------------------------------------------------

entity data_buffer is

    generic(
    
        BUFSIZE                             :natural                                               
    );

    port(
        rst_n                               :in         std_logic;
        clk                            	    :in         std_logic;                                  
        mem_address				            :in 	    std_logic_vector(8 downto 0);               
        data_out                            :out        std_logic_vector(7 downto 0);              
        mem_output                          :in         std_logic_vector(7 downto 0);               
        mem_clk                             :in         std_logic;                                 
        sd_write_rdy                        :out        std_logic;                                 		
        buf_ful						        :out	    std_logic;                                 
        sd_write_done					    :in		    std_logic;							       
        buffer_reinit_done			        :out 		std_logic;                                  
        sd_write_count                      :in         std_logic_vector(31 downto 0);             
        sd_block_written				    :in         std_logic;                                 
        init_start					        :in 		std_logic                                  
    );
end data_buffer;



--! data_buffer takes data from the host on rising edge of mem_clk. It store into a 2 port ram. Upon 
--! the first block written into the buffer, sd_data is signalled to begin writing.  data_buffer
--! keeps track of the number of blocks which have been written to buffer. When data_nblocks have
--! have been written, the component will raise buf_ful and signal the host to stop writing data.
    




architecture Behavioral of data_buffer is

--Calculation of the address size based on the BUFSIZE given! Data is always 8 bits. 
--The buffer is made up of blocks (512bytes) and bytes in those blocks. The BUFFSIZE generic is a multiple of blocks ie 2048 = 4 *512. In this instance 4 block addresses are sequenced through by this buffer. 

signal mem_address_c    :std_logic_vector(natural(trunc(log2(real(BUFSIZE-1)))) downto 0);  --Incrementing address for a 512 byte data with 1 byte word

constant BYTE_ADDR_LEN  :natural := 9;
constant BLOCK_ADDR_LEN :natural := (mem_address_c'length - BYTE_ADDR_LEN);


signal level 		    :natural;                                                                      --Data level in the buffer.
signal max_level_pre 	:unsigned(mem_address_c'length - BYTE_ADDR_LEN - 1 downto 0) := (others => '1');    --Simply a signal to allow creation of signal max_level.
signal max_level        :natural := to_integer(max_level_pre) + 1;                                          --The max level that can be reached given the size of the buffer.



signal  ram_byte_address_wr     :unsigned (BYTE_ADDR_LEN-1 downto 0);            -- The byte write pointer.
signal  ram_block_address_wr    :unsigned (BLOCK_ADDR_LEN-1 downto 0);           --The block write pointer.

signal  ram_byte_address_rd     :unsigned (BYTE_ADDR_LEN-1 downto 0);                               --The byte read pointer.
signal  ram_block_address_rd    :unsigned (BLOCK_ADDR_LEN-1 downto 0);                              --The block read pointer.


signal  buf_ful_internal 	    :std_logic;                                                  --Buffer is full.
signal  sd_write_rdy_internal   :std_logic;                                                  --The buffer has at least one block in it. Signal microsd_controller to start write.

signal  buffer_reinit_done_internal :std_logic;

signal  ram_byte_address_wr_follower    :unsigned (BYTE_ADDR_LEN-1 downto 0);    --Follower of the byte write address.


signal  num_blocks_through_buffer       :unsigned(31 downto 0);      --Keep track of number of blocks pushed into buffer. When N blocks have been pushed, keep BUF_FUL high as to prevent more data coming in until sd is done. 


--DEBUG
signal init_started : std_logic;


begin 

ram_byte_address_rd <= unsigned(mem_address);
buf_ful <= buf_ful_internal;
sd_write_rdy <= sd_write_rdy_internal;
buffer_reinit_done <= buffer_reinit_done_internal;

	
	--Altera 2 port synchronous ram. 

internal_buffer_instant : altsyncram
	GENERIC MAP (
		address_aclr_b => "NONE",
		address_reg_b => "CLOCK1",
		clock_enable_input_a => "BYPASS",
		clock_enable_input_b => "BYPASS",
		clock_enable_output_b => "BYPASS",
		intended_device_family => "Cyclone V",
		lpm_type => "altsyncram",
		numwords_a => BUFSIZE,						--BUFSIZE determined
		numwords_b => BUFSIZE,						--BUFSIZE determined
		operation_mode => "DUAL_PORT",
		outdata_aclr_b => "NONE",
		outdata_reg_b => "CLOCK1",
		power_up_uninitialized => "FALSE",
		widthad_a => mem_address_c'length,		--BUFSIZE determined
		widthad_b => mem_address_c'length,		--BUFSIZE determined
		width_a => 8,
		width_b => 8,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => std_logic_vector(ram_block_address_wr) & std_logic_vector(ram_byte_address_wr),    --data_buffer handled write pointer.                
		clock0 => mem_clk,                                                                              --Host mem_clk.
		data_a => 	mem_output,                                                                         --Host data.
		wren_a => '1',  
		address_b => std_logic_vector(ram_block_address_rd) & std_logic_vector(ram_byte_address_rd),    --sd_data's byte read address and data_buffers handled block address.
		clock1 => clk,                                                                                  --System clock.
		q_b => data_out	                                                                                --The data sent to sd_data for writing to the sd card.
	);
	
	
--Start the process upon init_start.
process(rst_n,clk)
begin
if (rst_n = '0') then
    init_started <= '0';
elsif rising_edge(clk) then
		if(init_start = '0') then
			init_started <= '1';
		end if;
end if;
end process;

--Read and write pointer handling. 

process(rst_n,clk)
begin
if (rst_n = '0') then

   level <= 0;
   num_blocks_through_buffer   <= (others => '0');  
   buffer_reinit_done_internal <= '0';
   ram_byte_address_wr_follower <= (others => '0');
   ram_block_address_rd <= (others => '0');
   
   

elsif rising_edge(clk) then
	if (init_started = '1') then

		if (ram_byte_address_wr_follower /= ram_byte_address_wr) then
		ram_byte_address_wr_follower <= ram_byte_address_wr;
            --Increase the level only once (followers) when ram_byte_address_wr is 511. 
            --Also increment the num of blocks through buffer.
			if (ram_byte_address_wr = 511) then					                
					level <= level + 1;
					num_blocks_through_buffer <= num_blocks_through_buffer + 1;
				end if;
		end if;
        --If the last block was recieved by the card successfully. crc check received back okay.
		if (sd_block_written = '1' ) then                                                   
                        --Do not empty level until reinit if we've written Nblocks. 
						if (num_blocks_through_buffer = unsigned(sd_write_count)) then		
							ram_block_address_rd <= ram_block_address_rd + 1;
                        --Else decrease the level of the buffer. Move to reading the next block in the buffer.
						elsif(ram_byte_address_rd = 0) then                                 
							level <= level - 1;
							ram_block_address_rd <= ram_block_address_rd + 1;
						end if;
		end if; 
		
            --If the last block was received okay, then reinit the buffer 
            --level and the blocks count that has flowed through buffer.
			if (sd_write_done = '1') then                                                   
				buffer_reinit_done_internal <= '1';
				level <= 0;
				num_blocks_through_buffer <= (others => '0');
			else
				buffer_reinit_done_internal <= '0';                                        
			end if;
	

	end if;
end if;
end process;


--Write and read clock domains should be completely seperate. Currently they are not. 
--Handshake of the level is required to completely seperate the domains.

process(rst_n,mem_clk)
begin
if (rst_n = '0') then

ram_block_address_wr <=  (others => '0');
ram_byte_address_wr  <=  (others => '0');

elsif rising_edge(mem_clk) then
	if (init_started = '1') then
             --If the wr pointer is at the end of the block, 
             --increase the block write address and always increase the byte write address. 
			if(level /= max_level) then	                                   
					if (ram_byte_address_wr = 511) then
						ram_block_address_wr <= ram_block_address_wr + 1;
					end if;
				ram_byte_address_wr <= ram_byte_address_wr + 1;
			end if;
	end if;
		
end if;
end process;


--If more than 0 blocks have flowed through the buffer, signal microsd_controller to begin writing data. 		
sd_write_rdy_internal 	<= '0' when (num_blocks_through_buffer = 0) else '1';           
--If the level is at max_level, signal buffer full. 	
buf_ful_internal <= '1' when (level = max_level) else '0';                             




   
end Behavioral;