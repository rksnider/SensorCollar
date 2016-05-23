--
--
-- Filename:     	    microsd_init.vhd
-- Description:  	    Source code for microsd serial data logger
-- Author:			      Christopher Casebeer
-- Lab:               Dr. Snider
-- Department:        Electrical and Computer Engineering
-- Institution:       Montana State University
-- Support:           This work was supported under NSF award No. DBI-1254309
-- Creation Date:	    June 2014	
--		
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
--    Information on the MIT license 
--    can be found at http://opensource.org/licenses/MIT
--
--


library IEEE ;                  
use IEEE.STD_LOGIC_1164.ALL ;   
use IEEE.NUMERIC_STD.ALL ;   
use IEEE.MATH_REAL.ALL ;    



--
--
--! @brief      sd_init is the portion of the microsd_controller
--!             which guides the microSD card through initialization
--! @details     
--!             
--! @param      signalling_18_en_g  Attempt to switch into 1.8V signalling            
--! @param      clk                 Input clock, Init Component Logic Clk 
--!                                 (~400kHZ) 
--! @param      rst_n               Active-low system reset
--! @param      sd_init_start_in    Start signal from input pushbutton 
--!                                 Active Low
--!
--! @param      cmd_out           cmd line output.
--!
--! @param      dat0_out          dat0 line output.
--! @param      dat3_out          dat3 line output.
--!
--! @param      sclk_out          Sclk sent to card. 
--!                               Simply a reroute of clk
--! @param      D0_signal_in      dat0 tri-state line read.
--!
--! @param      init_done_out           SD Initialization Complete
--! @param      signalling_18_en_in     1.8V Switch Enable During Init
--!
--! @param      cmd_write_en_out        Enable Write on CMD line
--! @param      D3_write_en_out         dat3 write enable
--! @param      cmd_signal_in           cmd tri-state line read
--!
--! @param      rca_out             Relative Card Address passed to sd_data. 
--! @param      restart_out         Command response failures exceeded
--!                                 restart the sd card. 
--! @param      vc_18_on_out        Enable  1.8V signal to level translator
--! @param      vc_33_on_out        Enable  3.3V signal to level translator
--! @param      state_leds_out      State indication for leds
--!
--! @param      ext_trigger_out     External trigger bit. 
--!                                 Used to trigger an Oscope if need arise.
--! @param      card_serial_out     32 bit card serial taken on init.
--!
   
entity microsd_init is
  generic(
    signalling_18_en_g    :     std_logic
  );
	port(
    clk					          :in	    std_logic;	
    rst_n_in 				      :in	    std_logic;	
    sd_init_start_in	    :in	    std_logic;	
    cmd_out               :out    std_logic;	
    dat0_out			        :out    std_logic;	
    dat3_out 			        :out    std_logic;	
    sclk_out 		          :out    std_logic;	
    D0_signal_in  		    :in	    std_logic;  
    init_done_out			    :out	  std_logic;	
    cmd_write_en_out		  :out 	  std_logic;  
    D3_write_en_out		    :out 	  std_logic;  
    cmd_signal_in  	      :in	    std_logic;  
    rca_out				        :out	  std_logic_vector(15 downto 0);
    restart_out           :out    std_logic; 
    vc_18_on_out          :out    std_logic;
    vc_33_on_out          :out    std_logic;
    state_leds_out			  :out	  std_logic_vector(3 downto 0);
    ext_trigger_out       :out    std_logic;
    card_serial_out       :out    std_logic_vector(31 downto 0)
		 
  );
end microsd_init;




--! microsd_init is responsible for handling sd card initialization 
--! which happens 
--! only once per card power on. This includes switching the card into 1.8V
--! mode as well as handing off RCA address for all future commands. 
--! 
--! 
--! 

architecture Behavioral of microsd_init is


--Turn on debug processes. 
--If debugging, turn this on.
--If not, save the logic/timing. 
constant DEBUG_ON   : std_logic := '0';

component microsd_crc_7 is
  port(
      bitval				:in std_logic;
      enable				:in std_logic;
      clk					  :in std_logic;
      rst					  :in std_logic;
      crc_out		    :out std_logic_vector(6 downto 0)
  );
end component;


--FSM Signals
type  sd_ctrl_state	is (START_WAIT, PWR_ON, 
  CMD0_INIT, CMD0_SEND, CMD0_READ, 
  CMD8_INIT, CMD8_SEND, CMD8_READ, 
  CMD55_INIT, CMD55_SEND, CMD55_READ,
  ACMD41_INIT, ACMD41_SEND, ACMD41_READ, 
  CMD2_INIT, CMD2_SEND, CMD2_READ, 
  CMD3_INIT, CMD3_SEND, CMD3_READ, 
  CMD11_INIT, CMD11_SEND, CMD11_READ,CMD11_READ_PAUSE,
  VOLTAGE_SWITCH,VOLTAGE_SWITCH_WAIT,
  ERROR, IDLE);
						
--State signals
signal	next_state					:sd_ctrl_state;	-- FSM next-state variable
signal	current_state				:sd_ctrl_state;	-- FSM current-state variable

-- PWR_ON_DELAY0 Process Signals
signal	pwr_on_delay_en			    :std_logic;
signal	pwr_on_delay_count		  :integer range 0 to 2**8 - 1;
signal	pwr_on_delay_done			  :std_logic;

-- CMD_SEND0 Process Signals

signal	output_command				  :std_logic_vector(47 downto 0);
signal	command_send_en			    :std_logic;
signal	command_send_done			  :std_logic;
signal	command_send_bit_count	    :unsigned(5 downto 0);
  signal  cmdstartbit               :std_logic;
  
  -- 48-bit SD Card command register
signal	command_signal				  :std_logic_vector(47 downto 0); 

-- CMD_READ_R1_RESPONSE0 Signals
signal	read_bytes					    :std_logic_vector(47 downto 0) ;
signal	read_r1_response_done	  :std_logic;
signal	r1_response_bytes			  :std_logic_vector(47 downto 0) ;
signal	read_r1_response_en		  :std_logic;
signal	response_1_status			  :std_logic_vector(31 downto 0) ;
signal	response_1_current_state_bits : std_logic_vector(3 downto 0);

-- CMD_READ_R2_RESPONSE0 Signals
signal	r2_response_bytes			  :std_logic_vector(135 downto 0);	
signal	read_r2_response_done	  :std_logic;
signal	read_r2_bytes				    :std_logic_vector(135 downto 0);
signal	read_r2_response_en		  :std_logic;

--Parts of the CID register
signal  MID   :std_logic_vector(7 downto 0);
signal  OID   :std_logic_vector(15 downto 0);
signal  PNM   :std_logic_vector(39 downto 0);
signal  PRV   :std_logic_vector(7 downto 0);
signal  PSN   :std_logic_vector(31 downto 0);
signal  MDT   :std_logic_vector(11 downto 0);




-- CMD_READ_R3_RESPONSE0 Signals
signal	r3_response_bytes			  :std_logic_vector(47 downto 0);   
signal	read_r3_response_done	  :std_logic;
signal	read_r3_bytes				    :std_logic_vector(47 downto 0);
signal	read_r3_response_en		  :std_logic;

-- CMD_READ_R6_RESPONSE0 Signals
signal	r6_response_bytes			  :std_logic_vector(47 downto 0);
signal	read_r6_response_done	  :std_logic;
signal	read_r6_bytes				    :std_logic_vector(47 downto 0);
signal	read_r6_response_en		  :std_logic;
  
  signal 	response_6_status 	  :std_logic_vector (15 downto 0); 


-- CMD_READ_R7_RESPONSE0 Signals
signal	r7_response_bytes			  :std_logic_vector(47 downto 0);
signal	read_r7_response_done	  :std_logic;
signal	read_r7_bytes				    :std_logic_vector(47 downto 0);
signal	read_r7_response_en		  :std_logic;



--SD Card I/O signals
signal	dat0_signal					:std_logic;	        
signal	dat3_signal					:std_logic;	        
signal	cmd_signal					:std_logic;	        
signal	cmd_signal_in_signal		:std_logic;	
signal  cmd_write_en   : std_logic;
signal  D3_write_en    : std_logic;
	
--Command Payload Signals
-- This bit indicates whether or not the SD card is SDSC(0), 
--or SDHC/SDXC(1). Might better be a generic. Was always set to '1'
-- during development as I was using a SDXC card.
signal	sd_hcs_bit					:std_logic := '1';		
--Default RCA addressed used with ACMD41 on init
signal 	card_rca_signal 			:std_logic_vector (15 downto 0); 


	
--Voltage Switch Signals
--Once off signal to track number of 
--d0-d3 transitions during voltage translate.
signal 	d0_signal_in_follower		:std_logic; 
signal	d0_signal_in_count			:unsigned (1 downto 0);
signal	voltage_switch_done			:std_logic;
signal	voltage_switch_en_signal	:std_logic;


--CRC7 Signals
signal  crc7_bitval_signal      :std_logic;
signal  crc7_rst_signal	        :std_logic;
signal	crc7_signal			        :std_logic_vector(6 downto 0);
signal 	crc7_gen_en 		        :std_logic;
signal 	crc7_done 			        :std_logic;
signal	crc7_send_bit_count	    :unsigned (5 downto 0);	

    
--Debug Signals    
signal 	init_counter		        :unsigned(31 downto 0);

--Sclk Enable
signal  sclk_en                 :std_logic;

  
--Voltage Switch Signals
--Wait time between 3.3V off and 1.8V on
--Wait time on 1.8V turn on to sclk turned back on (stabilize 1.8V)
signal 	voltage_switch_lag_counter		      :   unsigned(11 downto 0); 
signal  voltage_switch_18_stabilize         :   unsigned(11 downto 0); 
--The voltage switch has finished.  
signal 	voltage_switch_run				        :   std_logic;  

--Wait after cmd_11_read to turn the clk off. 
signal 	cmd_11_read_done_pause_counter	  :   unsigned(11 downto 0); 
signal 	cmd_11_read_done_pause_en		      :   std_logic;
signal 	cmd_11_read_done_pause_done		    :   std_logic;

  
  --Synchronize the reset into the 400k domain.
signal rst_n_s         :   std_logic := '1';
signal rst_n           :   std_logic  := '1';
signal clk_inv         :    std_logic;





attribute noprune: boolean;
attribute noprune of response_1_status : signal is true;
attribute noprune of response_1_current_state_bits : signal is true;
attribute noprune of crc7_done : signal is true;
attribute noprune of init_counter : signal is true;


-- signal  sd_init_start_a     : std_logic;
signal  sd_init_start_s     : std_logic;
signal  sd_init_start_r_c   : std_logic;




-- attribute keep: boolean;
-- attribute keep of sd_init_start_a : signal is true;
-- attribute keep of sd_init_start_s : signal is true;

begin

i_sd_crc7_0:	microsd_crc_7 
  port map (
  bitval        => crc7_bitval_signal,
  enable        => crc7_gen_en,
  clk 	        => clk,
  rst           => crc7_rst_signal,
  crc_out       => crc7_signal
  );
	

-- I/O Signal Assignments
sclk_out <= clk and sclk_en;					    
clk_inv <= not clk;    
cmd_signal_in_signal <= cmd_signal_in;


process(clk_inv,rst_n)
begin
  if (rst_n = '0') then
	elsif (rising_edge(clk_inv)) then
    cmd_out           <= cmd_signal;						
    dat3_out          <= dat3_signal;		
    cmd_write_en_out  <=  cmd_write_en;          
    D3_write_en_out	  <=	D3_write_en;
	end if;
end process;




process(clk, rst_n)
begin
  if(rst_n = '0') then
    sd_init_start_s <= '1';	
    sd_init_start_r_c <= '1';
      

  elsif (clk'event and clk= '1') then
  
    rst_n_s <= rst_n_in;
    rst_n <= rst_n_s;

    sd_init_start_s <= sd_init_start_in;
    sd_init_start_r_c <= sd_init_start_s;
  end if;
end process;

card_serial_out <= PSN;

	
--
--
--NEXT-STATE LOGIC PROCESS		        
--
--

--Main State Machine. 
next_state_logic : process(clk, rst_n)
begin
 if(rst_n = '0') then
 
  current_state <= START_WAIT;	
  
  
  pwr_on_delay_en 		<= '0';

  command_send_en 		<= '0';

  read_r1_response_en	    <= '0';
  read_r2_response_en 	  <= '0';
  read_r3_response_en 	  <= '0';
  read_r6_response_en     <= '0';
  read_r7_response_en	    <= '0';
  command_signal			    <= x"FFFFFFFFFFFF";
  init_done_out 			    <= '0';
  crc7_gen_en			        <= '0';	
  rca_out                 <= x"0000";
  voltage_switch_en_signal <= '0';
  
  cmd_write_en	  <= '0';
  D3_write_en     <= '0';
  ext_trigger_out <= '0';
  sclk_en <= '1';
  
  cmd_11_read_done_pause_en <= '0';
  
  
  
  
  
  
 
  elsif (rising_edge(clk)) then

  
  cmd_write_en	  <= '0';
  D3_write_en     <= '0';
  command_send_en <= '0';
  
  
  read_r1_response_en	    <= '0';
  read_r2_response_en 	  <= '0';
  read_r3_response_en 	  <= '0';
  read_r6_response_en     <= '0';
  read_r7_response_en	    <= '0';
  
  crc7_gen_en			        <= '0';	
  sclk_en                 <= '1';
  cmd_11_read_done_pause_en <= '0';
  
		
  case current_state is
		
    when START_WAIT =>
      --Wait for active-low pushbutton press to start initialization process
      --or a low pulse of sd_init_start_in.
      if (sd_init_start_r_c = '0') then 
        current_state <= PWR_ON;
      end if;

      
    --Send > 74 clock cycles with all lines pulled up. 
    --Hold over from SPI mode.
    when PWR_ON =>  
    
      pwr_on_delay_en <= '1';
    
      if (pwr_on_delay_done = '1') then	
        current_state	<= CMD0_INIT;	
      end if;

    --CMD_0. Reset the SD Card.  GO_IDLE_STATE

    when CMD0_INIT => 	
    
      command_signal <= '0' & '1' & "000000" & x"00000000" & "1001010" & '1'; 
      current_state <= CMD0_SEND;
     
      
      
    when CMD0_SEND =>
    command_send_en <= '1';
    cmd_write_en  <= '1';
    D3_write_en   <= '1';
    dat3_signal <= '1';
    
      if (command_send_done = '1') then
        current_state <= CMD0_READ;
      end if;
        
    when CMD0_READ =>

      current_state <= CMD8_INIT;

        
    --CMD8				
    --Sends SD Memory Card interface
    --condition, which includes host supply
    --voltage information and asks the card
    --whether card supports voltage.
    --Reserved bits shall be set to '0'.
    --Send CMD8 (SEND_IF_COND) to the SD card. 
    --Expand the SD card instruction set.
    when CMD8_INIT =>  
    command_signal <= '0' & '1' & "001000" & x"00000" 
                        & "0001" & "10101010" & "1000011" & '1'; 
    
    current_state <= CMD8_SEND;
        
    when CMD8_SEND =>
    command_send_en <= '1';
    cmd_write_en  <= '1';
      if (command_send_done = '1') then
        current_state <= CMD8_READ;
      end if;
        
    when CMD8_READ =>
    read_r7_response_en <= '1';
      if (read_r7_response_done = '1') then
        --This is checking R7 response for echo back pattern.
        --Card will not respond it voltage level is not accepted.
        if (r7_response_bytes(15 downto 8) = "10101010") then  
          current_state <= CMD55_INIT;
        else
          current_state <= ERROR;
        end if;
    -- elsif (cmd_resend_en = '1') then
            -- next_state <= CMD8_INIT;
      end if;
        
    --Send CMD55 (APP_CMD) to the SD card to preface 
    --impending application-specific command. 
    when CMD55_INIT =>  
          command_signal <= '0' & '1' 
                        & "110111" & x"00000000" & "0110010" & '1'; 
      
      current_state <= CMD55_SEND;
        
    when CMD55_SEND =>
    
    command_send_en <= '1';
    cmd_write_en    <= '1';
      if (command_send_done = '1') then
        current_state <= CMD55_READ;
      end if;
        
    when CMD55_READ =>
     read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --This bit is the APP_CMD bit of the status register. 
        --The other bit set on first CMD55 response is READY FOR DATA.
        if (r1_response_bytes(13) = '1') then   
          current_state <= ACMD41_INIT;
        else
          current_state <= ERROR;
        end if;
        -- elsif(cmd_resend_en = '1') then
        -- next_state <= CMD55_INIT;
      end if;
    -- Send ACMD41 (SD_SEND_OP_COND) Here we send
    --host capacity support info and to begin card initialization process. 
    --See output logic for contents. 
    --ACMD41 is sent repeatedly with the same setup as the first ACMD41 sent.
    --The card becomes initialized and ready to continue when the R3 response
    --which cotains the OCR register has bit 31 set to a '1', the Card power
    --up status bit. Only then do we continue.
    --ACMD41 currently doesn't have any command resend error handling.
    --
    when ACMD41_INIT =>  
    
    if(signalling_18_en_g = '1') then
      --More bits of ACMD41 can be set. Page 23 of SD Spec. 
      --Card kept to SDXC and Power saving.
      --1.8V or 3.3V signalling is decided here.
      --FF80 references 23 downto 8 of OCR register.
      command_signal <= '0' & '1' & "101001" & '0' 
                        & sd_hcs_bit & "000001" 
                        & x"FF80" & x"00" & "0001000" & '1'; 
      else
      command_signal <= '0' & '1' & "101001" & '0' 
                        & sd_hcs_bit & "000000" 
                        & x"FF80" & x"00" &   "0001011" & '1';	
                                                                                                                              
      end if;
      
      current_state <= ACMD41_SEND;

    when ACMD41_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
      if (command_send_done = '1') then
        current_state <= ACMD41_READ;
      end if;
        
    when ACMD41_READ =>
    read_r3_response_en <= '1';
      if (read_r3_response_done = '1') then
          --OCR (31) of R3 gets set to 1 when the init phase is over. 
          --We check for that bit in the R3 response here. 
        if (r3_response_bytes(39) ='1') then 
          --If switching voltages is a go, proceed to CMD11.
          --Signified by bit 24 of OCR, Switching to 1.8V Accepted.
          --**NOTE** bit 24 of OCR will come back '0' if the card
          --is already in 1.8V mode from reinitializing w/o
          --doing a power cycle.
          if (r3_response_bytes(32) = '1') then	
            current_state <= CMD11_INIT;
          else
            current_state <= CMD2_INIT;
          end if;
        --Otherwise keeps sending CMD55/ACMD41. Do not change ACMD41. 
        else 	
            --Go back and send another CMD55 followed by ACMD41
          current_state <= CMD55_INIT;					
        end if;
        
        -- elsif(cmd_resend_en = '1') then
            -- next_state <= CMD55_INIT;
      end if;
        
        
    --Voltage switch command. Depends on the S18A bit in the ACMD41 response.
    --If 1, Voltage switch is possible....send CMD 11. 		
    when CMD11_INIT =>
    command_signal <= '0' & '1' 
                        & "001011" & x"00000000" & "0111011" & '1';
                            
      current_state <= CMD11_SEND;

    when CMD11_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
      if (command_send_done = '1') then
        current_state <= CMD11_READ;
      end if;
    --Returning R1 type response means the card starts voltage switch sequence.
    when CMD11_READ =>	
    
    read_r1_response_en <= '1';    
      if (read_r1_response_done = '1') then	
        current_state <= CMD11_READ_PAUSE;
      -- elsif(cmd_resend_en = '1') then
      -- next_state <= CMD11_INIT;
      end if;
        
    --Returning R1 type response 
    --means the card starts voltage switch sequence.
    when CMD11_READ_PAUSE =>		
    cmd_11_read_done_pause_en <= '1';    
      if (cmd_11_read_done_pause_done = '1') then	
        current_state <= VOLTAGE_SWITCH;
        -- elsif(cmd_resend_en = '1') then
        -- next_state <= CMD11_INIT;
      end if;
        
        
    when VOLTAGE_SWITCH =>
      --Voltage switch sequence is done when d0-d3 goes high.
      --d0 going high detection is handled in other process.
      --Card waits for level translation to finish as the card itself
      --detects 1.8V signalling on the lines.
      --Turn the clk back on (output logic) after the 1.8V comes on.
      voltage_switch_en_signal <= '1';
      sclk_en <= '0';
      if (voltage_switch_run = '1') then		
        current_state <= VOLTAGE_SWITCH_WAIT;
      end if;
    when VOLTAGE_SWITCH_WAIT =>
    voltage_switch_en_signal <= '1';
      --Voltage switch sequence is done when d0-d3 goes high.
      --d0 going high detection is handled in other process.
      --Card waits for level translation to finish as the card itself
      --detects 1.8V signalling on the lines.
      --Here I turn the sclk back on and wait. 
      --This way the clk is turned off momentarily. 
      if (voltage_switch_done = '1') then			    
        current_state <= CMD2_INIT;
      end if;
        
    --Get CID (unique card identification from card.
    when CMD2_INIT =>
      command_signal <= '0' & '1' & "000010" & x"00000000" & "0100110" & '1';
            
      current_state <= CMD2_SEND;

    when CMD2_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
      if (command_send_done = '1') then
        current_state <= CMD2_READ;
      end if;
        
    --Nothing is done with the CID at this time. 
    when CMD2_READ =>		
    read_r2_response_en <= '1';
      if (read_r2_response_done = '1') then			
        current_state <= CMD3_INIT;
        -- elsif (cmd_resend_en = '1') then
        -- next_state <= CMD2_INIT;
      end if;
        
    --Get address of the card (RCA).
    --All commands after this need this RCA number.
    when CMD3_INIT => 
    command_signal <= '0' & '1' & "000011" & x"0000000001"; 
        
      current_state <= CMD3_SEND;

    when CMD3_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en <= '1';	
      if (command_send_done = '1') then
        current_state <= CMD3_READ;
      end if;
        
    when CMD3_READ =>
    read_r6_response_en <= '1';    
      --RCA is stored on r6 done. 
      --RCA is stored in the r6 read response process. 
      if (read_r6_response_done = '1') then
        --Card is in standby mode Binary Coded Decimal == 3 means standby. 
        --Initial CMD3 yields BCD 2 == INIT. 
        --I am waiting for card to be in standby here.
        --Not needed most likely as card state 
        --in response is at the time of cmd issue. 
        --So the card is most likely in standby
        --after the first CMD3. Two CMD3's are sent anway.

        if (response_6_status(12 downto 9) = "0011") then 
          rca_out <=  card_rca_signal;
          init_done_out <= '1';         
          current_state <= IDLE;
        else 
          current_state <= CMD3_INIT;
        end if;
        -- elsif(cmd_resend_en = '1') then
        -- next_state <= CMD3_INIT;
      end if;

    when ERROR =>
      current_state <= ERROR; 
        
    when IDLE =>
      -- Everything initialized properly, hand-off operation to data FSM
      --current_state <= IDLE;	
      
  

    end case;
  end if;
end process;
	
	
	
--
--
--OUTPUT LOGIC PROCESS
--
--
-- process(current_state) 
    
-- begin
        
  -- -- Default Signal Values
  -- pwr_on_delay_en 		<= '0';
  -- command_load_en 		<= '0';
  -- command_send_en 		<= '0';

  -- read_r1_response_en	    <= '0';
  -- read_r2_response_en 	  <= '0';
  -- read_r3_response_en 	  <= '0';
  -- read_r6_response_en     <= '0';
  -- read_r7_response_en	    <= '0';
  -- command_signal			    <= x"FFFFFFFFFFFF";
  -- init_done_out_s	 			        <= '0';
  -- crc7_gen_en			        <= '0';	
  -- rca_out                 <= x"0000";
  -- voltage_switch_en_signal <= '0';
  
  -- cmd_write_en	  <= '0';
  -- D3_write_en     <= '0';
  -- ext_trigger_out <= '0';
  -- sclk_en <= '1';
  
  -- cmd_11_read_done_pause_en <= '0';

        
        
  -- case current_state is
    
    -- when START_WAIT =>

      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- state_leds_out <= "1010";
      -- --state_leds_out <= "1110";
      
      -- cmd_write_en			<= '0';
            
    -- when PWR_ON =>      
      -- -- Hold MOSI high, CS_N high while clocking for more than 74 cycles 
      -- --Hold over from SPI. Kept in.

      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- pwr_on_delay_en <= '1';
      -- -- While in PWR_ON state, display "0000" on LEDs
      -- state_leds_out <= "0000";				
      
      -- cmd_write_en  <= '1';
            
            
    -- --
    -- --CMD0(Card Reset)
    -- --
            
    -- when CMD0_INIT => -- Set up the FSM to transmit CMD0 to the SD card

      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';							
      -- dat0_signal <= '1';
      -- --Initialize the command data with CMD0 contents
      -- command_signal <= '0' & '1' & "000000" & x"00000000" & "1001010" & '1'; 
      -- command_load_en <= '1';
      -- state_leds_out <= "0001";							
      -- cmd_write_en  <= '0';
            
    -- when CMD0_SEND =>

      -- --cmd_signal <= output_command(47);
      -- --Initialize the command data with CMD0 contents
      -- command_signal <= '0' & '1' & "000000" & x"00000000" & "1001010" & '1'; 
      -- dat0_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds_out <= "0010";
      -- cmd_write_en  <= '1';
      -- --Get into SD mode by holding dat3/CS_N '1' during sending CMD0.
      -- --Do not rely on pullups to get to the card. Actively drive
      -- --this line in case a level translator is inserted.
      -- D3_write_en   <= '1';
            
    -- when CMD0_READ =>

      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
  -- --	read_r1_response_en  <= '1';
      -- state_leds_out <= "0011";
      
      -- cmd_write_en  <= '0';
      -- D3_write_en   <= '0';
            
            
    -- --
    -- --CMD8(SEND_IF_COND)
    -- --
            
    -- when CMD8_INIT =>
            
      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';							
      -- dat0_signal <= '1';
      -- --Command format follows
      -- --start bit    
      -- --cmd index 
      -- --stuff bits 
      -- --0001b 2.7-3.6V  
      -- --check pattern 
      -- --crc7 
      -- --end bit
      -- command_signal <= '0' & '1' & "001000" & x"00000" 
                        -- & "0001" & "10101010" & "1000011" & '1'; 

      -- command_load_en <= '1';
      -- state_leds_out <= "0100";							
      -- cmd_write_en  <= '0';
      -- D3_write_en   <= '0';
            
                
            
    -- when CMD8_SEND =>

      -- --cmd_signal     <= output_command(47);
      -- command_signal <= '0' & '1' & "001000" & x"00000" 
                        -- & "0001" & "10101010" & "1000011" & '1'; 
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds_out <= "0101";
      
      -- cmd_write_en  <= '1';
      -- D3_write_en   <= '0';  
            
    -- when CMD8_READ =>

      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- read_r7_response_en <= '1';
      -- state_leds_out <= "0110";
      
      -- cmd_write_en  <= '0';
      -- D3_write_en   <= '0';      
            
            
    -- --
    -- --CMD55(APP_CMD) This command is sent before any ACMD. 
    -- --This simply tells the card that an expanded command is coming next.
    -- --
            
    -- when CMD55_INIT =>

      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';
      
      -- command_signal <= '0' & '1' 
                        -- & "110111" & x"00000000" & "0110010" & '1'; 
      -- command_load_en <= '1';
      -- state_leds_out <= "0111";							
      
      -- cmd_write_en  <= '0';
      -- D3_write_en   <= '0';      
    -- when CMD55_SEND =>

      -- --cmd_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "110111" & x"00000000" & "0110010" & '1'; 
      
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- command_send_en <= '1';
      -- state_leds_out <= "1000";
      
      -- cmd_write_en    <= '1';
      -- D3_write_en   <= '0';      
    -- when CMD55_READ =>

        
      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- read_r1_response_en <= '1';
      -- state_leds_out <= "1001";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en   <= '0';      
            
            
    -- -----------
    -- --ACMD41(SD_SEND_OP_COND) Main init command. 
    -- --Power Savings, Signalling Level and Card Type Specified.
    -- --Hosts repeatedly issues this command until card is ready
    -- --(response bit indicates ready. OCR(31)) 
    -- -----------
            
    -- when ACMD41_INIT =>

        
      -- --cmd_signal  <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- if(signalling_18_en_g = '1') then
      -- --More bits of ACMD41 can be set. Page 23 of SD Spec. 
      -- --Card kept to SDXC and Power saving.
      -- --1.8V or 3.3V signalling is decided here.
      -- --FF80 references 23 downto 8 of OCR register.
      -- command_signal <= '0' & '1' & "101001" & '0' 
                        -- & sd_hcs_bit & "000001" 
                        -- & x"FF80" & x"00" & "0001000" & '1'; 
      -- else
      -- command_signal <= '0' & '1' & "101001" & '0' 
                        -- & sd_hcs_bit & "000000" 
                        -- & x"FF80" & x"00" &   "0001011" & '1';	
                                                                                                                              
      -- end if;
      
      -- command_load_en <= '1';	
      -- state_leds_out <= "1010";							
      
      -- cmd_write_en			<= '0';
      -- D3_write_en   <= '0';      
    -- when ACMD41_SEND =>

      -- --cmd_signal <= output_command(47);
      
      -- if(signalling_18_en_g = '1') then
        -- --More bits of ACMD41 can be set. Page 23 of SD Spec. 
        -- --Card kept to SDXC and Power saving.
        -- --1.8V or 3.3V signalling is decided here.
        -- --FF80 references 23 downto 8 of OCR register.
        -- command_signal <= '0' & '1' & "101001" & '0' 
        -- & sd_hcs_bit & "000001" 
        -- & x"FF80" & x"00" & "0001000" & '1'; 
      -- else
        -- command_signal <= '0' & '1' & "101001" & '0' 
        -- & sd_hcs_bit & "000000" 
        -- & x"FF80" & x"00" &   "0001011" & '1';	
      -- --6941FF8000  with Voltage Switch CRC7  0001000
      -- --6940FF8000  w/o Voltage Switch CRC7 	0001011
      -- end if;
            
      -- dat0_signal <= '1';
      -- dat3_signal <= '1';
      
      -- command_send_en <= '1';
      -- state_leds_out <= "1011";
      
      -- cmd_write_en			<= '1';
      -- D3_write_en   <= '0';      
    -- when ACMD41_READ =>

       
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- read_r3_response_en <= '1';
      -- state_leds_out <= "1100";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';      
            
    -- -----------
    -- --CMD11(VOLTAGE SWITCH COMMAND/RESPONSE)
    -- -----------
            
    -- when CMD11_INIT =>

    
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- --Taken page 25 SD Spec 3.01. 
      -- command_signal <= '0' & '1' 
                        -- & "001011" & x"00000000" & "0111011" & '1'; 				
      -- command_load_en <= '1';
      -- state_leds_out <= "1101";							
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
    -- when CMD11_SEND =>

      -- --cmd_signal <= output_command(47);
      -- --Taken page 25 SD Spec 3.01. 
      -- command_signal <= '0' & '1' 
                        -- & "001011" & x"00000000" & "0111011" & '1'; 				
      -- dat0_signal <= '1';
      -- dat3_signal <= '1';
      
      -- command_send_en <= '1';
      -- state_leds_out <= "1110";
      
      -- cmd_write_en			<= '1';
      -- D3_write_en       <= '0';          
            
            
    -- when CMD11_READ =>

        
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- read_r1_response_en <= '1';
      -- state_leds_out <= "0001";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
            
    -- when  CMD11_READ_PAUSE =>
    
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- state_leds_out <= "0001";
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';    
      -- cmd_11_read_done_pause_en <= '1';
            
    -- -----------
    -- --Custom state. This is where the level shifter is switched 
    -- --to new voltage level.
    -- --The SD card halts with d0 low until the levels are changed. 
    -- -----------

    -- when VOLTAGE_SWITCH =>

            
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- voltage_switch_en_signal <= '1';
      
      -- state_leds_out <= "0001";
      
      -- sclk_en <= '0';
      -- ext_trigger_out <= '0';
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
    -- when VOLTAGE_SWITCH_WAIT =>

            
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- voltage_switch_en_signal <= '1';
      
      -- state_leds_out <= "0001";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
    -- -----------
    -- --CMD2(GET CID UNIQUE CARD IDENTIFICATION NUMBER)
    -- -----------
            
    -- when CMD2_INIT =>

    
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- command_signal <= '0' & '1' & "000010" & x"00000000" & "0100110" & '1'; 
      -- command_load_en <= '1';
      -- state_leds_out <= "1101";							
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
    -- when CMD2_SEND =>

      -- --cmd_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "000010" & x"00000000" & "0100110" & '1'; 
      -- dat0_signal <= '1';
      -- dat3_signal <= '1';
      
      -- command_send_en <= '1';
      -- state_leds_out <= "1110";
      
      -- cmd_write_en			<= '1';
      -- D3_write_en       <= '0';          
    -- when CMD2_READ =>

            
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- read_r2_response_en <= '1';
      -- state_leds_out <= "0001";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';    
    -- -----------
    -- --CMD3(GET RCA Relative Card Address)
    -- -----------
    -- -----------CMD3 w/ CRC gen

    -- when CMD3_INIT =>

            
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- --IMPORTANT: The CRC7 is defaulted to x"01". It will be filled
      -- --by CRC7GEN and CMD_SEND. 
      -- --The 1 is the end transmission bit.
      -- command_signal <= '0' & '1' & "000011" & x"0000000001";  
      -- command_load_en <= '1';
      -- state_leds_out <= "0010";							
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
    -- when CMD3_SEND =>

      -- --cmd_signal <= output_command(47);
      -- --IMPORTANT: The CRC7 is defaulted to x"01". It will be filled 
      -- --by CRC7GEN and CMD_SEND. 
      -- --The 1 is the end transmission bit.
      -- command_signal <= '0' & '1' & "000011" & x"0000000001";  
      
      -- dat0_signal <= '1';
      -- dat3_signal <= '1';
      
      -- command_send_en <= '1';
      -- state_leds_out <= "0011";
      
      -- cmd_write_en			<= '1';
      -- D3_write_en       <= '0';    
      -- crc7_gen_en <= '1';					
      -- --This command is sent with a CRC7 generated for it. CRC7 is not hardcoded. 
      -- --crc7_gen_en enabled while sending command
      -- --if you want CRC7 appended during send. Not absolutely needed here, but
      -- --always neeeded after we received variable RCA and start including
      -- --it inside every command thereafter.
            
    -- when CMD3_READ =>

        
      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      
      -- read_r6_response_en <= '1';
      -- state_leds_out <= "0100";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
            
    -- when ERROR =>

      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- state_leds_out <= "1111";
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';          
    -- when IDLE =>

      -- --cmd_signal <= '1';
      -- dat3_signal <= '1';
      -- dat0_signal <= '1';
      -- -- Initialization process is done. This will trigger the DATA 
      -- -- mode on the mux one level up.
      -- init_done_out_s	 <= '1';					    
      -- state_leds_out <= "1000";						
      
      -- cmd_write_en			<= '0';
      -- D3_write_en       <= '0';    
      -- --Now that INIT is done, send the RCA signal to the sd_data code. 
      -- rca_out <=  card_rca_signal;			    
            

        

    -- end case;

-- end process;
	
  
  

  
--SD Card Protocol requires that 74 SD clock cycles come before CMD0 on 
--startup. This is also a requirement of SPI mode, but cs_n is held low in
--that instance.
power_on_delay:	process(rst_n, clk)
	begin
    if (rst_n = '0') then
    
    pwr_on_delay_count <= 0;
    pwr_on_delay_done <= '0';
    
	elsif rising_edge(clk) then
    if (pwr_on_delay_en = '1') then
      if (pwr_on_delay_count = 152) then
        pwr_on_delay_done <= '1';
      else
        pwr_on_delay_done <= '0';
        pwr_on_delay_count <= pwr_on_delay_count + 1;
      end if;
    else
      pwr_on_delay_count <= 0;
      pwr_on_delay_done <= '0';
    end if;
	end if;
end process power_on_delay;	
	
  
cmd_signal <= output_command(47) when (cmdstartbit = '1') else '1';

--SEND ANY CMD with CRC7 APPEND
cmd_send:	process(rst_n, clk_inv)
begin					
  if (rst_n = '0') then
    cmdstartbit             <= '0';
    command_send_done       <= '0';
    command_send_bit_count  <= (others => '0');
    output_command          <= x"FFFFFFFFFFFF";

  --Data is shifted on falling edge of clock.

  
  elsif rising_edge(clk_inv) then  
    
  --cmdstarbit is a once off start bit align. 
    if (command_send_en = '1' and cmdstartbit = '0') then	
      output_command <= command_signal;
      cmdstartbit <= '1';
    elsif (command_send_en = '1' and cmdstartbit = '1') then 					
        if (command_send_bit_count = to_unsigned(48,command_send_bit_count'length)) then
          command_send_done <= '1';
          command_send_bit_count <= (others => '0');
        elsif (crc7_done = '1') then
          output_command <= crc7_signal & '1' & x"FFFFFFFFFF";	
          command_send_bit_count <= command_send_bit_count + 1;
        else
          command_send_bit_count <= command_send_bit_count + 1;
          output_command <= output_command(46 downto 0) & '1';							
        end if;
    else
      output_command <= x"FFFFFFFFFFFF";
      command_send_done <= '0';  -- Default Values
      cmdstartbit       <= '0';
    end if;
  end if;
end process  cmd_send;
	
--CRC7 Gen and Append Process. Used only for CMD3 in this init code. 
--All other CRC7 portions of commands are hard coded. 

crc7_bitval_signal <= output_command(47);	
crc7_done <= '1' when (crc7_send_bit_count = to_unsigned(40, crc7_send_bit_count'length))
                else '0';
crc7_rst_signal <= '1' when (crc7_gen_en = '1') else '0' ;
			
crc7_gen:	process(rst_n, clk_inv)
begin	
  if (rst_n = '0') then
    crc7_send_bit_count <= (others => '0');
  elsif rising_edge(clk_inv) then
    if (crc7_gen_en = '1') then	
      crc7_send_bit_count <= crc7_send_bit_count + 1;
    else 
      crc7_send_bit_count <= (others => '0');
    end if;
  end if;		
end process crc7_gen;

--Below are incoming response handlers which sample the cmd lines
--for responses sent after commands. 

cmd_read_r1_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    read_r1_response_done <= '0';
    read_bytes <= x"FFFFFFFFFFFF";
    r1_response_bytes <= x"FFFFFFFFFFFF";
    response_1_status <= (others => '0');
    response_1_current_state_bits <= (others => '0');
  
  elsif rising_edge(clk) then		
    read_r1_response_done <= '0';
    if (read_r1_response_en = '1') then
      if (read_bytes(47) = '0') then
        read_r1_response_done <= '1';
        r1_response_bytes <= read_bytes;
        --Debug register to look at card status field of r1 response
        response_1_status <= read_bytes(39 downto 8); 
        --A debug register to look at 
        --CARD STATE of the card status response field.
        response_1_current_state_bits <= read_bytes(20 downto 17); 
        read_bytes <= x"FFFFFFFFFFFF";
      else
        read_bytes <= read_bytes(46 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process cmd_read_r1_response;
	
cmd_read_r2_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    read_r2_response_done <= '0';
    read_r2_bytes <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    r2_response_bytes <= x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
    PSN <= (others => '0');
  elsif rising_edge(clk) then	
    read_r2_response_done <= '0';
    if (read_r2_response_en = '1') then
      if (read_r2_bytes(135) = '0') then
        read_r2_response_done <= '1';
        --Pull out the PSN of the card. 
        PSN <= read_r2_bytes (56 downto 25);
        r2_response_bytes <= read_r2_bytes;
        read_r2_bytes <= (others => '1');
      else
        read_r2_bytes <= read_r2_bytes(134 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process cmd_read_r2_response;	

	
cmd_read_r3_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
  
    read_r3_response_done <= '0';
    read_r3_bytes <= x"FFFFFFFFFFFF";
    r3_response_bytes <= x"FFFFFFFFFFFF";
  
  elsif rising_edge(clk) then
    read_r3_response_done <= '0';
    if (read_r3_response_en = '1') then
      if (read_r3_bytes(47) = '0') then
        read_r3_response_done <= '1';
        r3_response_bytes <= read_r3_bytes;
        read_r3_bytes <= x"FFFFFFFFFFFF";
      else
        read_r3_bytes <= read_r3_bytes(46 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process cmd_read_r3_response;
	
		
cmd_read_r6_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    read_r6_response_done <= '0';
    read_r6_bytes <= x"FFFFFFFFFFFF";
    r6_response_bytes  <= x"FFFFFFFFFFFF";
    card_rca_signal <= (others => '0');
    response_6_status <= (others => '0');

  elsif rising_edge(clk) then
    read_r6_response_done <= '0';
    if (read_r6_response_en = '1') then
      if (read_r6_bytes(47) = '0') then
        read_r6_response_done <= '1';
        r6_response_bytes <= read_r6_bytes;
        --Store the RCA returned for later use in all commands.
        card_rca_signal 	<= read_r6_bytes(39 downto 24);	
        --Debug utility. Handy for looking at the R6 status bits.                
        response_6_status <= read_r6_bytes(23 downto 8);					 
        read_r6_bytes <= x"FFFFFFFFFFFF";
      else
        read_r6_bytes <= read_r6_bytes(46 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process cmd_read_r6_response;
	

	
cmd_read_r7_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    read_r7_response_done <= '0';
    r7_response_bytes  <= x"FFFFFFFFFFFF";
    read_r7_bytes <= x"FFFFFFFFFFFF";
  elsif rising_edge(clk) then
    read_r7_response_done <= '0';
    if (read_r7_response_en = '1') then
      if (read_r7_bytes(47) = '0') then
        read_r7_response_done <= '1';
        r7_response_bytes <= read_r7_bytes;
        read_r7_bytes <= x"FFFFFFFFFFFF";
      else
        read_r7_bytes <= read_r7_bytes(46 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process cmd_read_r7_response;


use_debug:
	if ( DEBUG_ON = '1') generate
    --DEBUG COUNTER
    --Counter used for measuring time sd card spends in INIT state.
    COUNT_INIT_TIME: process(rst_n, clk)
    begin
      if (rst_n = '0') then
        init_counter <= (others => '0');
      elsif rising_edge(clk) then
        if (current_state /= START_WAIT) then
          if (current_state = IDLE) then
          else
            init_counter <= init_counter + 1;
          end if;
        end if;
      end if;
    end process COUNT_INIT_TIME; 

end generate use_debug;



--Here the voltage on the signal lines is changed through 
--interacting with the switch 
--controlling the voltage level pin of the level translator.


--Info on the length of switch is NOT provided in the sd spec.
--Try wait 6 ms.
--1 400kHz tick is 2.5us.
use_18_switch:
  if (signalling_18_en_g = '1') generate
 
    voltage_switch_process: process(rst_n, clk)    --Sclk is ~400kHz.
    begin
      if(rst_n = '0') then
        vc_33_on_out	<= '1';	
        vc_18_on_out	<= '0';	
        voltage_switch_run <= '0';
        voltage_switch_lag_counter <= (others => '0');
        voltage_switch_18_stabilize <= (others => '0');
      elsif rising_edge(clk) then
        if (voltage_switch_run = '0') then
          if ( voltage_switch_en_signal = '1') then
            if (voltage_switch_lag_counter =  
                        to_unsigned(100,voltage_switch_lag_counter'length)) then
              if (voltage_switch_18_stabilize =  
                        to_unsigned(160,voltage_switch_18_stabilize'length)) then
                voltage_switch_run <= '1';
                vc_33_on_out	<=  '0';	
                vc_18_on_out	<= '1';
              else
                voltage_switch_18_stabilize <=  voltage_switch_18_stabilize + 1;
                vc_33_on_out	<=  '0';	
                vc_18_on_out	<= '1';
              end if;
            else
           
               vc_33_on_out	<= '0';	
               vc_18_on_out	<= '0';	
               voltage_switch_run <= '0';
               voltage_switch_lag_counter <=  voltage_switch_lag_counter + 1;
             end if;
          else
           vc_33_on_out	<= '1';	
           vc_18_on_out	<= '0';	
           voltage_switch_run <= '0';
          end if ;
        else  
        end if;
      end if;
        
    end process voltage_switch_process;


  --Here we wait for d0 to return high and stay high before continuing with init.
  --d0 will only return high after sd card senses new signalling levels.
  --The card is sensing the voltage level of the clk line most likely.
  -- After the R1 response post CMD11, the card will drop d0.
  --d0 only returns to high after the line voltages have changed.

  Voltage_Switch_Complete:	process(rst_n, clk)
  begin
    if (rst_n = '0') then
      d0_signal_in_count <= "00";
      d0_signal_in_follower <= '1';
      voltage_switch_done <= '0';
    elsif rising_edge(clk) then
      if (voltage_switch_en_signal = '1') then  
        --Follower signals allow detecting a transition once 
        --and not multiple times. 
        if(d0_signal_in_follower /= d0_signal_in) then
          d0_signal_in_follower <= d0_signal_in;
          if (d0_signal_in = '1') then
            d0_signal_in_count <=  d0_signal_in_count + 1;
          end if;
        end if;
      else
        d0_signal_in_count <= "00";
        d0_signal_in_follower <= '1';
      end if;
      
      if (d0_signal_in_count = 1) then    
        voltage_switch_done <= '1';
      else
        voltage_switch_done <= '0';
      end if;
    end if;

  end process Voltage_Switch_Complete;


  -- Pause for 1ms. After R1 from CMD 11 read.
  cmd_11_read_pause: process(rst_n, clk)    --Sclk is ~400kHz.
  begin
    if(rst_n = '0') then
      cmd_11_read_done_pause_done <= '0';
      cmd_11_read_done_pause_counter <= (others => '0');
    elsif rising_edge(clk) then
      if (cmd_11_read_done_pause_en = '1') then
        if (cmd_11_read_done_pause_counter =  
                  to_unsigned(20,cmd_11_read_done_pause_counter'length)) then
          cmd_11_read_done_pause_done <= '1';
        else
          cmd_11_read_done_pause_counter <= cmd_11_read_done_pause_counter + 1;
        end if;
      end if;
    end if;
      
  end process cmd_11_read_pause;

end generate use_18_switch;

end Behavioral;

