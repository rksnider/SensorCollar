----------------------------------------------------------------------------------------------------
--
-- Filename:     	microsd_controller_tester.vhd
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

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ;   



entity microsd_controller_tester is

    port(
    
		  --System Signals
		  --Dat2 EDGE40 EDGE 49 EDGE14
		  --Dat3 Edge 42 EDGE50 EDGE15
		  --CMD Edge 66  EDGE 60 EDGE25
		  --Clk Edge 46 Edge 51  EDGE 16
		  --Dat0 Edge 48 Edge 52  EDGE 17
		  --Data1 Edge 50 Edge 53   EDGE 18
		 CLOCK_50				:in	std_logic; --Input clock, 50-MHz max
		 --Subtract 1 from 1-79
		 EG_BOTTOM              :inout std_logic_vector(25 downto 0);
		 --Subtract 35 from 2-80
		 EG_TOP                 :inout std_logic_vector(28 downto 0);
		 tact					:in	std_logic_vector (1 downto 0);	-- Start signal from input pushbutton
		 gpio 				    :inout STD_LOGIC_VECTOR(10 downto 0);
		 user_led_n				:out std_logic_vector(3 downto 0)    --LEDS not used must be tied. Default on, I believe. 
         
    );
end microsd_controller_tester;



architecture Behavioral of microsd_controller_tester is

component data_pll is
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
	--	outclk_1 : out std_logic;        -- outclk1.clk
		locked   : out std_logic         --  locked.export
	);
end component;



component microsd_controller is
  generic(
        BUFSIZE                             :   natural := 2048;              
        HS_SDR25_MODE					    :   std_logic := '1';             
        CLK_DIVIDE                          :   natural := 128                 
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
        sd_clk                              :out     std_logic;                                     
        sd_cmd                              :inout   std_logic;                                                                    
        sd_dat                              :inout   std_logic_vector(3 downto 0);                            
        V_3_3_ON_OFF                        :out     std_logic;                
        V_1_8_ON_OFF                        :out     std_logic;                  

        init_start                          :in      std_logic;                  
        user_led_n_out                      :out     std_logic_vector(3 downto 0)

	);
end component;




signal ct_data		            :   unsigned(7 downto 0);   --Dummy data to be written to card.
signal ct_data_count	        :   natural;    --Data transmit counter.
  
signal block_count              :   unsigned(31 downto 0);  --Block transmit counter.
signal n_block_done             :   std_logic := '0';       --nblock done. The first nblock set of data and commands has finished. 
signal n_block_done_follower    :   std_logic; 
  
  
signal buffer_full_abstract		:   std_logic;              --data_full flag
signal buffer_full_abstract_follower 	    :std_logic;     --data_full flag follower. 


signal sd_dat_abstract		    :   std_logic_vector(3 downto 0);
  
  
signal sd_last_block_written_abstract         :   std_logic_vector(31 downto 0);  --This is the sd block address which was last written successfully. It passed CRC response check.
signal sd_block_written_abstract              :   std_logic;  --Last block written pulse.


signal VC_22960_33_ON	        :   std_logic := '0';	
signal VC_22960_18_ON	        :   std_logic := '0';

signal power_up_done	        :   std_logic := '0';   --Power up sequence bit.
signal rst_n			        :   std_logic := '0';   --Rst_n pulse on startup.
signal sd_init_start_top	    :   std_logic := '1';   --Should be used instead of pushbutton to auto init card on startup.


signal pll_lock 		        :   std_logic;
signal pll_clk			        :   std_logic;


signal init_started 	        :   std_logic;  --Init push button has been pressed.

signal signal_tap_clock		    :   std_logic;
signal cnt					    :   integer range 0 to 2**12 - 1;   --Count used for signal tap clock gen
  
signal mem_clk_abstract         :   std_logic;  --data_we passed to controller.
signal mem_clk_abstract_follower 		    :   std_logic;  --data_we follower.
  
  
signal sd_start_address_internal            :   std_logic_vector(31 downto 0)  := std_logic_vector(to_unsigned(0,32)); --Start address passed to controller.
signal sd_write_count_internal              :   unsigned(31 downto 0) 			:= to_unsigned(2048,32);                --data_nblocks passed to controller.
  
signal num_writes			    :   natural ;
  
signal mem_clk_en			    :   std_logic ;
		  
		  
		  
		  
		  
		  
begin 


sd_tester : microsd_controller 
	port map (
    
  
        rst_n                               => rst_n,                                 
        clk                                 => pll_clk,                                     
        clock_enable                        => '1',                                         

        data_input                          => std_logic_vector(ct_data),                   
        data_we                             => mem_clk_abstract,                          
        data_full                           => buffer_full_abstract,                        

        data_sd_start_address               => sd_start_address_internal,                  
        data_nblocks                        => std_logic_vector(sd_write_count_internal),   
                                                                                   
        data_current_block_written          => sd_last_block_written_abstract,              
        sd_block_written_flag               => sd_block_written_abstract ,                      

        sd_clk                         	 	=> EG_BOTTOM(16),                             
        sd_cmd                       	    => EG_BOTTOM(25),                               

        sd_dat(0)                           => EG_BOTTOM(17) ,                           
        sd_dat(1)                           => EG_BOTTOM(18) ,                           
        sd_dat(2)                           => EG_BOTTOM(14) ,                           
        sd_dat(3)                           => EG_BOTTOM(15) ,                            
            
        V_3_3_ON_OFF                        => EG_TOP(24),                                 
        V_1_8_ON_OFF                        => EG_TOP(25),                                
        
        --Personal Debug for now
        
        init_start                          => tact(1),                                     
        user_led_n_out                      => user_led_n

	);

    	
    pll_data : data_pll 
    port map (
        refclk   => CLOCK_50, --  refclk.clk
        rst      => '0', --   reset.reset --Reset is a high '1' reset.
        outclk_0 => pll_clk,		-- outclk0.clk
        locked   => pll_lock        --  locked.export
    );		

	--Drive ununsed pins to known state along the edge connector.
	EG_TOP (21 downto 0) <= (others => '0');
	EG_TOP (28 downto 26) <= (others => '0');
	EG_BOTTOM(13 downto 0) <= (others => '0');
	EG_BOTTOM(24 downto 19) <= (others => '0');

	EG_TOP(22) <=  VC_22960_33_ON ;	
	EG_TOP(23) <=  VC_22960_18_ON ;	
            
     
-------------------------------------------------------
--CLOCK USED FOR SIGNAL TAP SAMPLING
-------------------------------------------------------	
--signal_tap_clock <= CLOCK_50;		
--signal_tap_clock				<= pll_clk;
signal_tap_clock_GEN:	process(CLOCK_50)
begin 
	if rising_edge(CLOCK_50) then 
		if(cnt = 1) then 						
        --A clock divider like so divides the period of the clock by (count+1)*2. 
			signal_tap_clock				<= not signal_tap_clock; 
			cnt								 <= 0; 
		else 
		cnt <= cnt + 1 ; 
	end if; 
end if; 

end process; 

startup_init:process(rst_n, pll_clk)
begin
if (rst_n = '0') then
init_started <= '0';
elsif rising_edge(pll_clk) then
		if(tact(1) = '0') then
			init_started <= '1';
		end if;
end if;
end process startup_init;

test_writing_followers:process(rst_n, pll_clk)
begin
if(rst_n = '0') then

buffer_full_abstract_follower <= '0';
n_block_done_follower <= '0';

elsif rising_edge(pll_clk) then
		if(buffer_full_abstract_follower /= buffer_full_abstract) then
			buffer_full_abstract_follower <= buffer_full_abstract;
		end if;
		
		if(n_block_done_follower /= n_block_done) then
			n_block_done_follower <= n_block_done;
		end if;
end if;
end process test_writing_followers;

-- This is the test writing process. It was used in a 2048 nblock write and 
-- a 128x16nblock write excercising either one large write or many small 
-- writes (with many internal buffer resets)
-- The process increments the dummy data sent to the card by one every 
-- 512 bytes. It tracks the block_count to determine if data_nblocks has 
-- been sent. Num_writes can then specify X data_nblock sets.
-- The address passed into the microsd_controller will increment appropriately 
-- at the end of sending a data_nblock.

test_writing:process(rst_n, pll_clk)
begin
if (rst_n = '0') then
n_block_done <= '0';
block_count  <= x"00000000";
num_writes <= 0;
ct_data <= x"00";
ct_data_count  <= 0;
elsif rising_edge(pll_clk) then
    if (init_started = '1') then

        --n_block_done must be checked outside buff_full for it to be set
        if (block_count = to_integer(sd_write_count_internal)) then			
        
            n_block_done <= '1';
            block_count <= (others => '0');
            num_writes <= num_writes + 1;
            --Change data_sd_start_address for new data_nblocks
            sd_start_address_internal <= std_logic_vector(unsigned(sd_start_address_internal) + sd_write_count_internal);   
        end if;

        if (n_block_done = '0') then
            if (mem_clk_en = '1') then
                    --Only increment ct_data dummy data on block boundries.
                    if (ct_data_count = 511) then           
                        ct_data_count <= 0;
                        block_count <= block_count + 1;
                        ct_data <= ct_data + 1;
                    else
                        ct_data_count <= ct_data_count + 1;
                    end if;
            end if;
        else

            if( buffer_full_abstract_follower = '0') then
                --If we've written the total number of sequential nblock sets we want, stop. 
                if (num_writes = 128) then          
                else
                --If not send another nblock set of data. Uncomment for 128*16 data_nblocks. 
                --Commented for 2048 data_nblocks.
                --n_block_done <= '0';              
                end if;
            end if;
			
        end if;


    end if;
end if;
end process;


mem_clk_enable:process(rst_n, pll_clk)
begin
if (rst_n = '0') then
mem_clk_en <= '0';
elsif falling_edge(pll_clk) then

	if (buffer_full_abstract = '0' and init_started = '1' and n_block_done_follower = '0') then
		mem_clk_en <= '1';
	else
		mem_clk_en <= '0';
	end if;

end if;
end process mem_clk_enable;


mem_clk_abstract <= pll_clk and mem_clk_en;

--Drive reset on power up.
--sd_init_start_top can be used to automatically start card into init on power up. 
power_up_sequence:process(pll_clk)
begin
if rising_edge (pll_clk) then
    if (power_up_done = '0') then
        rst_n <= '0';
        sd_init_start_top <= '1';
        power_up_done <= '1';
    else
        rst_n <= '1';
        sd_init_start_top <= '0';
    end if;
end if;
end process power_up_sequence;


end Behavioral;