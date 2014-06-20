-- // ==========================================================================
-- // CRC Generation Unit - Linear Feedback Shift Register implementation
-- // (c) Kay Gorontzi, GHSi.de, distributed under the terms of LGPL
-- // ==========================================================================
--ADAPTED FROM http://ghsi.de/CRC/index.php?Polynom=10001000000100001&Message=48000001AA


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

------------------------------------------------------------------------------
--
--! @brief      crc16 generation for appending to any sd data sent over the data lines
--! @details     
--!
--! @param      clk                 Component Clock
--! @param      bitval              The current bit input into crc engine  
--! @param      enable              Enable bit for the engine.
--!
--! @param      rst                 Active low reset. Zeroes the crc.
--!
--! @param      crc_out             The current crc engine output
--!
--
------------------------------------------------------------------------------     

entity sd_crc_16 is
port(


    bitval				:in std_logic;
	enable				:in std_logic;
    clk					:in std_logic;
	rst					:in std_logic;
	crc_out			    :out std_logic_vector(15 downto 0)
	);
	
	end sd_crc_16;
	
	architecture Behaviorial of sd_crc_16 is
   

        signal   crc		:std_logic_vector(15 downto 0);
        signal 	inv				:std_logic;	

        
	begin
    
	crc_out <= crc;
    inv <= BITVAL XOR CRC(15);                   
   
   
 process(clk) 
	 begin
	 if(rising_edge(clk)) then
						if (rst = '0') then
							CRC <= x"0000";   
						elsif (enable = '1') then
							CRC(15) <= CRC(14);
							CRC(14) <= CRC(13);
							CRC(13) <= CRC(12);
							CRC(12) <= CRC(11) XOR inv;
							CRC(11) <= CRC(10);
							CRC(10) <= CRC(9);
							CRC(9) <= CRC(8);
							CRC(8) <= CRC(7);
							CRC(7) <= CRC(6);
							CRC(6) <= CRC(5);
							CRC(5) <= CRC(4) XOR inv;
							CRC(4) <= CRC(3);
							CRC(3) <= CRC(2);
							CRC(2) <= CRC(1);
							CRC(1) <= CRC(0);
							CRC(0) <= inv;
							end if;
				end if;
	  end process;
   
end Behaviorial;