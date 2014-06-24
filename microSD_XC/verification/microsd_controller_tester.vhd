----------------------------------------------------------------------------------------------------
--
-- Filename:     	    microsd_tester.vhd
-- Description:  	    Source code for microsd serial data logger
-- Author:			    Christopher Casebeer
-- Lab:                 Dr. Snider
-- Department:          Electrical and Computer Engineering
-- Institution:         Montana State University
-- Support:             This work was supported under NSF award No. DBI-1254309
-- Creation Date:	    June 2014	
--		
-----------------------------------------------------------------------------------------------------
--
-- Version 1.0
--
-----------------------------------------------------------------------------------------------------
--
-- Modification Hisory (give date, author, description)
--
-- None
--
-- Please send bug reports and enhancement requests to Dr. Snider at rksnider@ece.montana.edu
--
-----------------------------------------------------------------------------------------------------
--
--	  This software is released under
--            
--    The MIT License (MIT)
--
--    Copyright (C) 2014  Christopher C. Casebeer and Ross K. Snider
--
--    Permission is hereby granted, free of charge, to any person obtaining a copy
--    of this software and associated documentation files (the "Software"), to deal
--    in the Software without restriction, including without limitation the rights
--    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--    copies of the Software, and to permit persons to whom the Software is
--    furnished to do so, subject to the following conditions:
--
--    The above copyright notice and this permission notice shall be included in
--    all copies or substantial portions of the Software.
--
--    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
--    THE SOFTWARE.
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
-----------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ;   

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

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




--Data pulled from ram and sent to card.
signal ct_data		            :   std_logic_vector(7 downto 0);
--Data transmit counter. 
signal ct_data_count	        :   natural;    
--Block transmit counter.  
signal block_count              :   unsigned(31 downto 0);
--nblock done. The first nblock set of data and commands has finished.  
signal n_block_done             :   std_logic := '0';        
signal n_block_done_follower    :   std_logic; 
  
--data_full flag. 
signal buffer_full_abstract		:   std_logic;
--data_full flag follower.              
signal buffer_full_abstract_follower 	    :   std_logic;      


signal sd_dat_abstract		    :   std_logic_vector(3 downto 0);
  
--This is the sd block address which was last written successfully. It passed CRC response check.  
signal sd_last_block_written_abstract         :   std_logic_vector(31 downto 0);
--Last block written pulse. 
signal sd_block_written_abstract              :   std_logic;  


signal VC_22960_33_ON	        :   std_logic := '0';	
signal VC_22960_18_ON	        :   std_logic := '0';

--Power up sequence bit.
signal power_up_done	        :   std_logic := '0';
--Rst_n pulse on startup.   
signal rst_n			        :   std_logic := '0';
--Should be used instead of pushbutton to auto init card on startup.   
signal sd_init_start_top	    :   std_logic := '1';   


signal pll_lock 		        :   std_logic;
signal pll_clk			        :   std_logic;

--Init push button has been pressed.
signal init_started 	        :   std_logic;  

signal signal_tap_clock		    :   std_logic;
 --Count used for signal tap clock gen
signal cnt					    :   integer range 0 to 2**12 - 1;  
--data_we passed to controller.  
signal mem_clk_abstract         :   std_logic;
--data_we follower.  
signal mem_clk_abstract_follower 		    :   std_logic;  
  
--Start address passed to controller.  
signal sd_start_address_internal            :   std_logic_vector(31 downto 0)  := std_logic_vector(to_unsigned(0,32));
--data_nblocks passed to controller. 
signal sd_write_count_internal              :   unsigned(31 downto 0) 			:= to_unsigned(16,32);                
--Count the number of nblocks sent to card.
signal num_writes			    :   natural ;
--Turn on the data_we to the component. 
signal mem_clk_en			    :   std_logic ;

--Address to data output is delayed two clock cycles.
--data_we must be delayed two clock cycles while data
--gets out of ram. 
signal ct_data_lag_done              :   std_logic;
signal ct_data_lag_counter      :   unsigned(2 downto 0);





	attribute noprune: boolean;
	attribute noprune of signal_tap_clock : signal is true;
    attribute noprune of ct_data_lag_done: signal is true;
    attribute noprune of ct_data_lag_counter: signal is true;
		  
		  
		  
		  
		  
		  
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
        
        init_start                          => sd_init_start_top,                                     
        user_led_n_out                      => user_led_n

	);
    
    
--This 2 port ram is initialized with 512 bytes of random uint8 integers
--created with the included matlab script. The script will also generate
--a 1MB .bin file for comparison with function cmp in linux.  
altsyncram_component : altsyncram
	GENERIC MAP (
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "../matlab scripts/512bytecount_rand.mif",
		intended_device_family => "Cyclone V",
		lpm_hint => "ENABLE_RUNTIME_MOD=YES,INSTANCE_NAME=RAND",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 9,
		width_a => 8,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => std_logic_vector(to_unsigned(ct_data_count,9)),
		clock0 => pll_clk,
		data_a => x"00",
		wren_a =>'0',
		q_a => ct_data
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

    --Turn off the other voltage switch I didn't use.
	EG_TOP(22) <=  VC_22960_33_ON ;	
	EG_TOP(23) <=  VC_22960_18_ON ;	
            
     
-------------------------------------------------------
--CLOCK USED FOR SIGNAL TAP SAMPLING
-------------------------------------------------------	
--signal_tap_clock <= CLOCK_50;	

--Wiring to pin will preserve for Signal Tap.
gpio(0) <= signal_tap_clock;	
signal_tap_clock				<= pll_clk;
-- signal_tap_clock_GEN:	process(CLOCK_50)
-- begin 
	-- if rising_edge(CLOCK_50) then 
		-- if(cnt = 1) then 						
        -- --A clock divider like so divides the period of the clock by (count+1)*2. 
			-- signal_tap_clock				<= not signal_tap_clock; 
			-- cnt								 <= 0; 
		-- else 
		-- cnt <= cnt + 1 ; 
	-- end if; 
-- end if; 
-- end process; 

--Pulling data out of the ram has a 2 clock cycle lag. 
--Thus we only start data_we after a 2 clock cycle lag
--on the address.  
--This counter and lag must be reset after each buffer_full
--event as the address value continues to increment.
data_delay:process(rst_n,pll_clk)
begin
if(rst_n = '0') then
        ct_data_lag_counter     <= "001";
        ct_data_lag_done          <= '0';
elsif rising_edge(pll_clk) then
    if (init_started = '1') then
        if (buffer_full_abstract = '1') then
           ct_data_lag_counter     <= "001";
           ct_data_lag_done <= '0';
        else
            if (ct_data_lag_counter = 0) then
                ct_data_lag_done <= '1';
            else
                ct_data_lag_counter     <= ct_data_lag_counter - 1;
            end if;
        end if;
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

--Delayed read of buffer_full and n_block_done.
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
-- a 128x16 nblock write excercising either one large write or many small 
-- writes (with many internal buffer resets)
-- Address into ram data is incremented.
-- It tracks the block_count to determine if data_nblocks has 
-- been sent. Num_writes can then specify X data_nblock sets to be sent in total.
-- The address passed into the microsd_controller will increment appropriately 
-- at the end of sending a data_nblock, as to place the next nblock contiguous. 

test_writing:process(rst_n, pll_clk)
begin
if (rst_n = '0') then
n_block_done <= '0';
block_count  <= x"00000000";
num_writes <= 0;
--ct_data <= x"00";
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
            --Address increment starts 2 clocks before data_we
            --is enabled. 
            if (buffer_full_abstract = '0') then
                    if (ct_data_count = 511) then           
                        ct_data_count <= 0;
                        block_count <= block_count + 1;
                        --Prev used for dummy counter data.
                        -- ct_data <= ct_data + 1;
                    else
                        ct_data_count <= ct_data_count + 1;
                    end if;
            else
                    --Reset address after buf_ful event
                    --due to 2 cycle delay out of ram.
                    --Count gets ahead of data and needs
                    --reset. 
                    ct_data_count <= 0;
            end if;
        else

            if( buffer_full_abstract_follower = '0') then
                --If we've written the total number of sequential nblock sets we want, stop. 
                if (num_writes = 128) then          
                else
                --If not send another nblock set of data. Uncomment for 128*16 data_nblocks. 
                --Commented for 2048 data_nblocks.
                n_block_done <= '0';              
                end if;
            end if;
			
        end if;


    end if;
end if;
end process;

--data_we gating scheme in relation to pulling data out of ram.
mem_clk_enable:process(rst_n, pll_clk)
begin
if (rst_n = '0') then
mem_clk_en <= '0';
elsif falling_edge(pll_clk) then

	if (buffer_full_abstract = '0' and init_started = '1' and n_block_done_follower = '0' and ct_data_lag_done = '1') then
		mem_clk_en <= '1';
	else
		mem_clk_en <= '0';
	end if;

end if;
end process mem_clk_enable;


mem_clk_abstract <= pll_clk and mem_clk_en;

--Drive reset low on power up.
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