-- // ==========================================================================
-- // CRC Generation Unit - Linear Feedback Shift Register implementation
-- // (c) Kay Gorontzi, GHSi.de, distributed under the terms of LGPL
-- // ==========================================================================
--Simple port from Verilog to VHDL by Christopher Casebeer from http://ghsi.de/CRC/index.php?Polynom=10001001&Message=48000001AA


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


--
--! @brief      crc7 generation for appending to any sd command sent over cmd line.
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
    


entity microsd_crc_7 is
port(
  bitval				:in std_logic;
  enable				:in std_logic;
  clk					:in std_logic;
  rst					:in std_logic;
  crc_out			    :out std_logic_vector(6 downto 0)
);
	
end microsd_crc_7;
	
architecture Behaviorial of microsd_crc_7 is
   

signal  crc		                :std_logic_vector(6 downto 0);
signal 	inv		                :std_logic;	
signal 	sclk_follower			:std_logic;	

	
begin
	
crc_out <= crc;
inv <= BITVAL XOR CRC(6);                   
   
   
process(clk) 
begin
  if(rising_edge(clk)) then

    if (rst = '0') then
      CRC <= "0000000";  

    elsif (enable = '1') then
      CRC(6) <= CRC(5);
      CRC(5) <= CRC(4);
      CRC(4) <= CRC(3);
      CRC(3) <= CRC(2) XOR inv;
      CRC(2) <= CRC(1);
      CRC(1) <= CRC(0);
      CRC(0) <= inv;

    end if;
  end if;
end process;
   
end Behaviorial;