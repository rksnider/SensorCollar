library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


------------------------------------------------------------------------------
--
--! @brief      mems_top is the portion of microsd_controller which handles write comms with sd card.
--! @details     
--!
------------------------------------------------------------------------------
--
--! @brief      mems_top interfaces with CIC Decimation Filter
--! @details     
--!
--! @param      clk             3.6Mhz Clock  
--! @param      rst_n           Negative Reset    
--! @param      clk_enable      
--! @param      pdm_bit         Output of Mems Mic. 1 or 0.
--! @param      filter_out      Signed PCM Word Out
--! @param      clock_out       Divide by 64 clock    
--!
--
------------------------------------------------------------------------------   

entity mems_top_16 is

    port(
    clk         :   IN    std_logic; 
    rst_n       :   IN    std_logic; 
    clk_enable  :   IN    std_logic; 
    pdm_bit     :   IN    std_logic; 
    filter_out  :   OUT   std_logic_vector(15 DOWNTO 0); -- sfix16
    clock_out   :   OUT   std_logic  --clk / 64. 
    );
end mems_top_16;


architecture Behavioral of mems_top_16 is


component Hd_16 IS
   PORT( clk                             :   IN    std_logic; 
         clk_enable                      :   IN    std_logic; 
         reset                           :   IN    std_logic; 
         filter_in                       :   IN    std_logic_vector(1 DOWNTO 0); -- sfix2
         filter_out                      :   OUT   std_logic_vector(15 DOWNTO 0); -- sfix16_E4
         ce_out                          :   OUT   std_logic  
         );

END component;


--Convert PDM bit to s2,0.
signal  pdm_bit_signal  :   std_logic_vector(1 downto 0);


begin 

--hd_full_i takes a 2 bit signed value. 
--However the bit off microphone is 0/1 PDM. 
--Assuming filter_in is -1 or 1. 
with pdm_bit select 
			pdm_bit_signal  <=	"11" when '0',
                                "01" when others;



i_Hd_16_0 : Hd_16 
  PORT MAP( clk                         =>  clk,
        clk_enable                      =>  clk_enable,
        reset                           =>  not rst_n,
        filter_in                       =>  pdm_bit_signal,
        filter_out                      =>  filter_out,
        ce_out                          =>  clock_out
        );



end Behavioral;