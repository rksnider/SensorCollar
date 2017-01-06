--
--
-- Filename:      microsd_data.vhd
-- Description:   Source code for microsd serial data logger
-- Author:			  Christopher Casebeer
-- Lab:           Dr. Snider
-- Department:    Electrical and Computer Engineering
-- Institution:   Montana State University
-- Support:       This work was supported under NSF award No. DBI-1254309
-- Creation Date:	    June 2014
--
--
--
--Version 1.0
--
--
--
--Modification Hisory (give date, author, description)
--
--None
--
--Please send bug reports and enhancement requests
--to Dr. Snider at rksnider@ece.montana.edu
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
--    Information on the MIT license can be found
--    at http://opensource.org/licenses/MIT
--



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ;




--!
--!
--! @brief      microsd_data is the portion of microsd_controller
--!             which handles
--!             data communications with the microSD card.
--!
--! @details
--! @param      clk_freq_g        Used to determine command time outs.
--! @param      clk             Logic Clk and Data Transmission Clock
--! @param      rst_n           Active Low Reset
--! @param      sd_control      Used to select pathway in Data Component.
--! @param      sd_status       Current State of State Machine.
--!
--! @param      block_byte_data       Read data from SD card memory
--! @param      block_byte_wren       Signals that a data byte has been read.
--! @param      block_read_sd_addr    Address to read block from on sd card.
--! @param      block_byte_addr       Address to write read data to in ram.
--!
--! @param      block_write_sd_addr   Address where block is written on sd card.
--! @param      block_write_data      Byte that will be written
--! @param      num_blocks_to_write   Number of blocks to be written in CMD25.
--! @param      ram_read_address      Where block_write_data is read from.
--!
--!
--! @param      erase_start           Start address of erase.
--! @param      erase_end             Stop address of erase.
--! @param      state_leds            Used to encode current state to Leds.
--! @param      prev_block_write_sd_addr  The last address to be
--!                                       successfully written valid on
--!                                       prev_block_write_sd_addr_pulse '1'
--!
--! @param      prev_block_write_sd_addr_pulse  prev_block_write_sd_addr is valid
--! @param      cmd_write_en        Tri State Enable
--! @param      D0_write_en         Tri State Enable
--! @param      D1_write_en         Tri State Enable
--! @param      D2_write_en         Tri State Enable
--! @param      D3_write_en         Tri State Enable
--! @param      cmd_signal_in       Read value of the tri-stated line.
--! @param      D0_signal_in        Read value of the tri-stated line.
--! @param      D1_signal_in        Read value of the tri-stated line.
--! @param      D2_signal_in        Read value of the tri-stated line.
--! @param      D3_signal_in        Read value of the tri-stated line.
--! @param      card_rca_in         Card RCA is passed from init.
--! @param      init_done_in        Card has passed init phase.
--! @param      hs_sdr25_mode_en    Card should transition to
--!                                 hs_sdr25 mode before first CMD25.
--! @param      voltage_switch_en   Enable voltage switching sequence.
--! @param      dat0                dat0 line out
--! @param      dat1                dat1 line out
--! @param      dat2                dat2 line out
--! @param      dat3                dat3 line out
--! @param      cmd                 cmd line out
--! @param      sclk                clk sent to sd card
--! @param      restart             Card should be restarted at upper level
--! @param      data_send_crc_error Card has sensed a data CRC error
--! @param      ext_trigger         External trigger bit.
--!                                 Used to trigger an Oscope if need arise.
--!


entity microsd_data is
	generic(
    clk_freq_g              :natural
  );
	port(

    clk								      :in	    std_logic;
    rst_n							      :in	    std_logic;



    sd_control					    :in	  std_logic_vector(7 downto 0);
    sd_status						    :out	std_logic_vector(7 downto 0);



    block_byte_data			    :out	std_logic_vector(7 downto 0);
    block_byte_wren			    :out	std_logic;
    block_read_sd_addr		  :in	  std_logic_vector(31 downto 0);
    block_byte_addr			    :out	std_logic_vector(8 downto 0) ;


    block_write_sd_addr		  :in	    std_logic_vector(31 downto 0);
    block_write_data			  :in	    std_logic_vector(7 downto 0);
    num_blocks_to_write		  :in     integer range 0 to 2**16 - 1;
    ram_read_address			  :out    std_logic_vector(8 downto 0);

    erase_start					    :in 	std_logic_vector(31 downto 0);
    erase_end						    :in 	std_logic_vector(31 downto 0);

    state_leds					    :out	std_logic_vector(3 downto 0);

    prev_block_write_sd_addr 			      :out	std_logic_vector(31 downto 0);
    prev_block_write_sd_addr_pulse      :out	std_logic;

    cmd_write_en_out					    :out    std_logic;
    D0_write_en_out						      :out    std_logic;
    D1_write_en_out						      :out    std_logic;
    D2_write_en_out						      :out    std_logic;
    D3_write_en_out						      :out    std_logic;

    cmd_signal_in					    :in 	  std_logic;
    D0_signal_in					    :in	    std_logic;
    D1_signal_in					    :in	    std_logic;
    D2_signal_in					    :in	    std_logic;
    D3_signal_in					    :in	    std_logic;

    card_rca_in 					        :in	    std_logic_vector(15 downto 0);


    init_done_in						      :in     std_logic;

    hs_sdr25_mode_en				  :in     std_logic;

--SD Signals
    voltage_switch_en		  :out  std_logic;
    dat0							    :out	std_logic;
    dat1							    :out	std_logic;
    dat2							    :out	std_logic;
    dat3							    :out	std_logic;
    cmd								    :out	std_logic;
    sclk							    :out	std_logic;

    restart               :out  std_logic;
    data_send_crc_error   :out  std_logic;

    ext_trigger				    :out  std_logic

  );
end microsd_data;


--! microsd_data is responsible for writing, reading, and erase of the card.
--! It also handles switching into 4 bit mode
--! and also switching  into different speed modes.



--!TODO
--Check the COM_CRC_ERROR and ILLEGAL_COMMAND on the command which was sent
--does not make any sense. Those bits are supposed to examined with a CMD13
--after the previous command failed.
--Illegal command and CRC error will result in a timeout for any command.
--All those checks should be removed.

--All the following state are protected against CRC failure.
-- CMD7_INIT
-- CMD55_INIT_ACMD6
-- ACMD6_INIT
-- CMD6_INIT_4
-- CMD25_INIT_4
-- CMD12_INIT
-- CMD12_INIT_ABORT
-- CMD13_INIT_MULTI_4
-- CMD13_INIT_TIMEOUT_REC
-- CMD13_INIT


architecture Behavioral of microsd_data is

--DEBUG SWITCH--


--Turn on debug processes.
--If debugging, turn this on.
--If not, save the logic/timing.
constant DEBUG_ON   : std_logic := '0';


--Turn off/on simulating CRC errors in commands/data.
constant data_errors_enabled    :std_logic := '0';
constant cmd_errors_enabled     :std_logic := '0';
--Every N cmds/blocks sent to device, insert incorrect CRC.
--This is the way I test failure.
constant cmd_error_rate_control     :natural := 1024;
constant data_error_rate_control    :natural := 1024;


--DEBUG SWITCH--



component microsd_crc_7 is
  port (
    bitval				:in std_logic;
    enable				:in std_logic;
    clk			      :in std_logic;
    rst					  :in std_logic;
    crc_out				:out std_logic_vector(6 downto 0)
);
end component;

component microsd_crc_16 is
  port (
    bitval				:in std_logic;
    enable				:in std_logic;
    clk					  :in std_logic;
    rst					  :in std_logic;
    crc_out				:out std_logic_vector(15 downto 0)
  );
end component;

component counter_ram IS
	PORT(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component;




--FSM State Variables
type sd_data_state is (ENTRY,
  APP_WAIT,
  CMD7_INIT, CMD7_SEND, CMD7_READ,
  CMD6_INIT, CMD6_SEND, CMD6_READ,
  CMD6_INIT_4, CMD6_SEND_4, CMD6_READ_4,
  CMD17_INIT,  CMD17_SEND,  CMD17_READ, CMD17_READ_DATA,
  CMD24_INIT,CMD24_SEND,CMD24_READ,CMD24_DATA,CMD24_DATA_INIT,
  CMD25_INIT,CMD25_SEND,CMD25_READ,CMD25_DATA,CMD25_DATA_INIT,
  CMD25_DATA_READ_12,CMD25_DATA_READ_13MULTI,
  CMD25_INIT_4,CMD25_SEND_4,CMD25_READ_4,CMD25_DATA_4,CMD25_DATA_INIT_4,
  CMD25_DATA_4_READ_TOKEN,
  CMD25_DATA_4_READ_CRC_SUCCESS,
  CMD25_DATA_4_READ_DECIDE,
  CMD25_DATA_4_RESEND,
  CMD25_INIT_4_RESEND,CMD25_SEND_4_RESEND,
  CMD55_INIT, CMD55_SEND, CMD55_READ,
  CMD55_INIT_ACMD6, CMD55_SEND_ACMD6, CMD55_READ_ACMD6,
  CMD55_INIT_ACMD42, CMD55_SEND_ACMD42, CMD55_READ_ACMD42,
  CMD55_INIT_ACMD13, CMD55_SEND_ACMD13, CMD55_READ_ACMD13,
  CMD32_INIT, CMD32_SEND, CMD32_READ,
  CMD33_INIT, CMD33_SEND, CMD33_READ,
  CMD38_INIT, CMD38_SEND, CMD38_READ,
  ACMD23_INIT, ACMD23_SEND, ACMD23_READ,
  ACMD6_INIT, ACMD6_SEND, ACMD6_READ,
  ACMD13_INIT, ACMD13_SEND, ACMD13_READ,
  ACMD42_INIT, ACMD42_SEND, ACMD42_READ,
--APP_CMD17_DATA, APP_CMD18_DATA, APP_CMD12_INIT,
--APP_CMD12_SEND, APP_CMD12_WAIT, APP_CMD12_READ,
--CMD9_INIT, CMD9_SEND, CMD9_READ,
  CMD12_INIT, CMD12_SEND, CMD12_READ,
  CMD12_INIT_ABORT, CMD12_SEND_ABORT, CMD12_READ_ABORT,
  CMD13_INIT, CMD13_SEND, CMD13_READ,
  CMD13_INIT_TIMEOUT_REC, CMD13_SEND_TIMEOUT_REC, CMD13_READ_TIMEOUT_REC,
  CMD13_INIT_MULTI, CMD13_SEND_MULTI, CMD13_READ_MULTI,
  CMD13_INIT_MULTI_4, CMD13_SEND_MULTI_4, CMD13_READ_MULTI_4,
  DELAY,
--  APP_CMD12_CLEAR_BUFFER, APP_CMD17_CLEAR_BUFFER, APP_ACK_WAIT,
  IDLE, ERROR);






signal current_state	:sd_data_state;
signal return_state   :sd_data_state;

--Return state is a way for exiting a shared CMD, such as CMD55!
--signal return_state		:	sd_data_state;

--	-- SD Data FSM Status and Control Signals
signal	sd_status_signal			:   std_logic_vector(7 downto 0);
signal	sd_control_signal			:   std_logic_vector(7 downto 0);

-- DELAY0 Process Signals
signal	delay_done					  :   std_logic := '0';
signal	delay_count				    :   integer range 0 to 2**8 - 1;
signal	delay_en			        :   std_logic;

-- CMD_SEND0 Process Signals
signal	command_load_en			  :   std_logic;
signal	output_command				:   std_logic_vector(47 downto 0);
signal	command_send_en			  :   std_logic;
signal	command_send_done			:   std_logic;
signal	command_send_bit_count	    :   integer range 0 to 2**6 - 1;

--	-- CMD_READ_R1_RESPONSE0 Signals
signal	read_bytes					  :   std_logic_vector(47 downto 0);
signal	read_r1_response_done	    :   std_logic;
signal	r1_response_bytes			:   std_logic_vector(47 downto 0);
signal	read_r1_response_en	  :   std_logic;
signal	response_1_status			:   std_logic_vector(31 downto 0);
signal	response_1_current_state_bits : std_logic_vector(3 downto 0);
--
--	-- CMD_READ_R2_RESPONSE0 Signals
signal	r2_response_bytes			:   std_logic_vector(135 downto 0);
signal	read_r2_response_done	    :   std_logic;
signal	read_r2_bytes				:   std_logic_vector(135 downto 0);
signal	read_r2_response_en		    :   std_logic;

-- CMD_READ_R6_RESPONSE0 Signals
signal	r6_response_bytes			:   std_logic_vector(47 downto 0);
signal	read_r6_response_done	    :   std_logic;
signal	read_r6_bytes				  :   std_logic_vector(47 downto 0);
signal	read_r6_response_en	  :   std_logic;
signal 	response_6_status     :   std_logic_vector (15 downto 0);

  -- Data Response Token Signals.
signal	reading_data_token_byte			:   std_logic_vector(7 downto 0);
signal 	read_data_token_byte		    :   std_logic_vector(7 downto 0);
signal 	read_data_token_reponse_done    :   std_logic;
signal 	read_data_token_reponse_en		  :   std_logic;

---- SINGLE_BLOCK_READ0 Process Signals
signal	CMD6_D0_read_done			:   std_logic;
signal	block_byte_count			:   unsigned(9 downto 0);
  --Wr_en line on ram.
signal	block_byte_wren_signal	    :   std_logic;
signal	block_bit_count			        :   integer range 0 to 2**3 - 1;
signal	block_start_flag			      :   std_logic;
  --Data being read
signal	block_byte_data_signal	    :   std_logic_vector(7 downto 0);
  --Data done being read and presented to the outside inbetween bytes.
signal	block_byte_data_signal_out	:   std_logic_vector(7 downto 0);
  --Sync bit 0 of read to block_bit_count 0. Otherwise off by one.
signal 	start_read_bit				    :   std_logic;
signal	singleblock_read_done	    :   std_logic;
  --Where to store data as its read from sd card. 512 locations.
signal  ram_write_address_signal    :   std_logic_vector(8 downto 0);
  --Used to enable process involved in single block read.
signal	block_read_process_en	    :   std_logic;





--SD Card I/O signals
signal	CMD_signal					:   std_logic;
signal	dat0_signal					:   std_logic;
signal	dat1_signal					:   std_logic;
signal	dat2_signal					:   std_logic;
signal	dat3_signal					:   std_logic;

   --40-bit SD Card command register used for form cmd.
signal	command_signal				:   std_logic_vector(47 downto 0);

--CRC7 signals
  --Next bit for CRC engine
signal 	crc7_bitval_signal 	  :   std_logic;
signal 	crc7_rst_signal		    :   std_logic;
signal	crc7_signal				    :   std_logic_vector(6 downto 0);
signal 	crc7_gen_en 			    :   std_logic;
signal 	crc7_done 				    :   std_logic;
  --48 bits to count before appending CRC7
signal	crc7_send_bit_count 	    :   integer range 0 to 2**6 - 1;

--CRC16_D0 signals
--Next bit for CRC engine
signal 	crc16_bitval_signal_D0  :   std_logic;
signal 	crc16_rst_signal_D0			:   std_logic;
  --Constant change output of CRC16
signal	crc16_signal_D0				:   std_logic_vector(15 downto 0);
  --Register to capture finished CRC16
signal	crc16_signal_D0_fin			:   std_logic_vector(15 downto 0);
signal 	crc16_gen_en_D0 		    :   std_logic;
signal 	crc16_done_D0 			    :   std_logic;
signal	crc16_send_bit_count_D0		:   integer range 0 to 2**4 - 1;
  --512 bits to count before appending CRC16
signal	crc16_send_byte_count_D0	:   integer range 0 to 2**9 - 1;

--CRC16_D1 signals
signal 	crc16_bitval_signal_D1  :   std_logic;
signal 	crc16_rst_signal_D1			:   std_logic;
signal	crc16_signal_D1				  :   std_logic_vector(15 downto 0);
signal	crc16_signal_D1_fin			:   std_logic_vector(15 downto 0);
signal 	crc16_gen_en_D1 		    :   std_logic;
signal 	crc16_done_D1 			    :   std_logic;
signal	crc16_send_bit_count_D1		:   integer range 0 to 2**4 - 1;
signal	crc16_send_byte_count_D1	:   integer range 0 to 2**9 - 1;

--CRC16_D2 signals
signal 	crc16_bitval_signal_D2  :   std_logic;
signal 	crc16_rst_signal_D2			:   std_logic;
signal	crc16_signal_D2				  :   std_logic_vector(15 downto 0);
signal	crc16_signal_D2_fin			:   std_logic_vector(15 downto 0);
signal 	crc16_gen_en_D2 		    :   std_logic;
signal 	crc16_done_D2 			    :   std_logic;
signal	crc16_send_bit_count_D2		:   integer range 0 to 2**4 - 1;
signal	crc16_send_byte_count_D2	:   integer range 0 to 2**9 - 1;

--CRC16_D3 signals
signal 	crc16_bitval_signal_D3 		:   std_logic;
signal 	crc16_rst_signal_D3			  :   std_logic;
signal	crc16_signal_D3				    :   std_logic_vector(15 downto 0);
signal	crc16_signal_D3_fin			  :   std_logic_vector(15 downto 0);
signal 	crc16_gen_en_D3 	        :   std_logic;
signal 	crc16_done_D3 			      :   std_logic;
signal	crc16_send_bit_count_D3		:   integer range 0 to 2**4 - 1;
signal	crc16_send_byte_count_D3	:   integer range 0 to 2**9 - 1;

--Store the SD cards relative card address
signal   card_rca_signal    :   std_logic_vector(15 downto 0) ;
signal   card_rca_s		      :   std_logic_vector(15 downto 0) ;


--Master Block write process signals.
  --Enable for single block writes.
signal 	block_write_process_en 			:	std_logic;

--Address for reading 512byte ram of tracking collar system
--Starts at address 0.
signal 	ram_read_address_signal			  :	std_logic_vector(8 downto 0);
--Keep track of number of bits written while writing
signal	wr_block_bit_count				:	integer range 0 to 2**4 - 1;
--Keep track of number of bytes written while writing
signal	wr_block_byte_count				:	integer range 0 to 2**10;
--Byte to be written to SD Card
signal 	wr_block_byte_data		    :	std_logic_vector(7 downto 0);

--Flag signalling append of 4 bit crc16.
signal 	append_crc_4_bit          :   std_logic;
--Used to insert start bit into the data send.
signal	start_bit				          :   std_logic;
--Switch for data load on first byte of multiblock send.
signal 	load					            :   std_logic;

--Single block done flag
signal 	block_write_done			    :	std_logic;
--Number of blocks that have been written. Checked to flag multiblock write done.
signal 	num_blocks_written				:	integer range 0 to 2**16 - 1;

--A Multiblock write has finished
signal 	multiblock_write_done			:	std_logic;


--Enable for turning on multiblock writes
signal 	multiblock_en				      :	std_logic;

--Segmenting out 4 bit writing control signals.

--Enable 4 bit multiblock write process
signal 	block_write_process_en_4 	    :	std_logic;


--FSM Flow Signals
--Flag to only execute the ACMD6 wide mode switch
--once vs after every exit from APP_WAIT.
signal widedone 			            :   std_logic;
--Flag to only execute after the CMD6 Access Mode Switch has been completed.
signal ac_mode_switch_done        :   std_logic;


--Tri-State Signals In from SD card
--Tri-state read CMD signal
signal	cmd_signal_in_signal		  :   std_logic;
--Tri-state read D0 signal
signal	D0_signal_in_signal			  :   std_logic;

--Block write data alignment signals
  --Used to align first bit of any command.
signal 	cmdstartbit 			      :   std_logic;





--Last block successfull written and pulse generation signals
--Internal last block written signal
signal 	block_write_sd_addr_interal     :   std_logic_vector(31 downto 0);
--Flag to indicate that we've passed data token read in the CMD25 instance.
signal 	block_success						        :   std_logic;
signal 	block_success_follower			    :   std_logic;
--Flag associated with CMD25_DATA_INIT_4.
--Used to track inter block transmissions and current block count.
signal 	new_block_write								  :   std_logic;
--Flag associated with CMD25_DATA_INIT_4.
--Used to track inter block transmissions and current block count.
signal 	new_block_write_follower		    :   std_logic;
--Flag associated with CMD25_INIT_4.
--Used to track first block of multiblock tranmission.
signal 	first_block_of_multiblock 		  :   std_logic;

--Sclk Enable
signal  sclk_en                 :std_logic;


--Command Timeout Signals
signal  cmd_resend_en               :std_logic;
--Calculation of 100ms timeout counter.
constant  cmd_timeout :natural := integer(trunc((real(clk_freq_g)) * 500.0E-3));

--Signals related to tracking data/cmd retry.
signal  cmd_response_timeout        :natural;
signal  cmd_resend_count            :unsigned (15 downto 0);
signal  restart_response     	      :std_logic;
signal  cmd_resend_timer_en         :std_logic;
signal  cmd_error_rate              :unsigned(natural(trunc(log2(real(cmd_error_rate_control)))) downto 0);
signal  block_resend_count          :unsigned (15 downto 0);
signal  data_error_rate             :unsigned(natural(trunc(log2(real(data_error_rate_control)))) downto 0);





--CRC Error Data Resend Signals
signal  resend                      :std_logic;
signal  resending                   :std_logic;
signal  resend_f                    :std_logic;
signal  restart_crc                 :std_logic;

--Command Error Checking Process Signals
signal  start_error     : std_logic := '0';
signal  CMD7_INIT_check : std_logic;
signal  CMD55_INIT_ACMD6_check : std_logic;
signal  ACMD6_INIT_check  : std_logic;
signal  CMD6_INIT_4_check : std_logic;
signal  CMD25_INIT_4_check  : std_logic;
signal  CMD12_INIT_check    : std_logic;
signal  CMD12_INIT_ABORT_check  : std_logic;
signal  CMD13_INIT_MULTI_4_check  : std_logic;
signal  CMD13_INIT_TIMEOUT_REC_check  : std_logic;





attribute noprune: boolean;
attribute noprune of response_1_status : signal is true;
attribute noprune of response_1_current_state_bits : signal is true;
attribute noprune of cmd_error_rate     : signal is true;
attribute noprune of data_error_rate     : signal is true;
attribute noprune of block_resend_count : signal is true;
attribute noprune of cmd_resend_count   : signal is true;

--DEBUG COUNTERS. Used in profilings inter-write delays.
signal  cmd13multi_counter						  :   unsigned(31 downto 0);
signal  cmd13multi_counter_reg				  :   unsigned(31 downto 0);
signal  cmd13multi_counter_done				  :   std_logic;
signal  CMD25_number						        :   unsigned(10 downto 0);
signal  CMD25_number_1							    :   std_logic;
signal  cmd13multi_counter_done_1		    :   std_logic;
signal  cmd12_13_counter					      :   unsigned(31 downto 0);
signal  cmd12_13_counter_reg 			      :   unsigned(31 downto 0);
signal	cmd25_setup_counter				      :   unsigned(31 downto 0);
signal  cmd25_setup_counter_reg 		    :   unsigned(31 downto 0);


signal init_done_signal : std_logic;
signal init_done_s      : std_logic;

signal  clk_inv  : std_logic;
signal  cmd_write_en  : std_logic;
signal  D0_write_en	  : std_logic;
signal  D1_write_en	  : std_logic;
signal  D2_write_en	  : std_logic;
signal  D3_write_en	  : std_logic;



--Throughput Calculation Signals

constant counts_per_second : natural := clk_freq_g;

constant  throughput_array_length : natural := 4;
constant  kbps_length_bits        :natural := 16;
signal    second_counter : unsigned(natural(trunc(log2(real(clk_freq_g)))) downto 0);
signal    kilobytes_per_second : unsigned(kbps_length_bits-1 downto 0) :=
                                      (others => '0');
type      kilobytes_per_second_t is array (throughput_array_length-1 downto 0) of unsigned(kbps_length_bits-1 downto 0);
signal    kilobytes_per_second_a : kilobytes_per_second_t :=
                                      (others => (others => '0'));
signal    tp_array_pos : unsigned(throughput_array_length-1 downto 0);
signal    prev_block_write_sd_addr_tp_track : unsigned (31 downto 0);

attribute noprune of kilobytes_per_second : signal is true;
attribute noprune of kilobytes_per_second_a : signal is true;

begin

--  Unused ports.

state_leds          <= (others => '0');
voltage_switch_en   <= '0';
restart             <= '0';
data_send_crc_error <= '0';

--CRC used for commands.
i_sd_crc_7_0:	microsd_crc_7
port map (
  bitval      => crc7_bitval_signal,
  enable      => crc7_gen_en,
  clk 		    => clk,
  rst         => crc7_rst_signal,
  crc_out     => crc7_signal
  );

--CRC used for data.
i_sd_crc_16_0:	microsd_crc_16
port map (
  bitval      => crc16_bitval_signal_D0,
  enable      => crc16_gen_en_D0,
  clk 		    => clk,
  rst         => crc16_rst_signal_D0,
  crc_out     => crc16_signal_D0
  );

--CRC used for data.
i_sd_crc_16_1:	microsd_crc_16
port map (
  bitval      => crc16_bitval_signal_D1,
  enable      => crc16_gen_en_D1,
  clk 		    => clk,
  rst         => crc16_rst_signal_D1,
  crc_out     => crc16_signal_D1
  );

--CRC used for data.
i_sd_crc_16_2:	microsd_crc_16
port map (
  bitval      => crc16_bitval_signal_D2,
  enable      => crc16_gen_en_D2,
  clk 		    => clk,
  rst         => crc16_rst_signal_D2,
  crc_out     => crc16_signal_D2
  );

--CRC used for data.
i_sd_crc_16_3:	microsd_crc_16
port map (
  bitval      => crc16_bitval_signal_D3,
  enable      => crc16_gen_en_D3,
  clk 		    => clk,
  rst         => crc16_rst_signal_D3,
  crc_out     => crc16_signal_D3
  );



--Debug Rams to Characterize Inner Multiblock Write Waits.
    -- counter_ram_instant : counter_ram
	-- PORT MAP
	-- (
		-- address		=> std_logic_vector(CMD25_number),
		-- clock		=> clk,
		-- data		=> std_logic_vector(cmd13multi_counter_reg),
		-- wren		=> cmd13multi_counter_done
	-- --	q		=>
	-- );



	-- counter_ram_instant_1 : counter_ram
	-- PORT MAP
	-- (
		-- address		=> std_logic_vector(CMD25_number),
		-- clock		=> clk,
		-- data		=> std_logic_vector(cmd12_13_counter_reg),
		-- wren		=> cmd13multi_counter_done
	-- --	q		=>
	-- );


	-- counter_ram_instant_2 : counter_ram
	-- PORT MAP
	-- (
		-- address		=> std_logic_vector(CMD25_number),
		-- clock		=> clk,
		-- data		=> std_logic_vector(cmd25_setup_counter_reg),
		-- wren		=> cmd13multi_counter_done
	-- --	q		=>
	-- );

  --
-- data_current_block_written
-- and
-- sd_block_written_flag
-- generation.
-- Generate the last successful address written global
-- output as well as the valid pulse which accompanies it.
--




process(clk,rst_n)
begin
  if (rst_n = '0') then
	elsif (falling_edge(clk)) then
    CMD  <= CMD_signal;
		dat0 <= dat0_signal;
		dat1 <= dat1_signal;
		dat2 <= dat2_signal;
		dat3 <= dat3_signal;
    cmd_write_en_out	  <=  cmd_write_en;
    D0_write_en_out		  <=  D0_write_en;
    D1_write_en_out		  <=	D1_write_en;
    D2_write_en_out		  <=	D2_write_en;
    D3_write_en_out		  <=	D3_write_en;
	end if;
end process;



-- I/O Signal Assignments
clk_inv <= not clk;
--Shut the clock to the sd card off when in the APP_WAIT state.
sclk <= '0' when (sclk_en = '0') else clk;





sd_control_signal <= sd_control;
sd_status <= sd_status_signal;


cmd_signal_in_signal <= cmd_signal_in;
D0_signal_in_signal <= D0_signal_in;
ram_read_address <= ram_read_address_signal;

block_byte_data	<= block_byte_data_signal_out	;
block_byte_wren	<= block_byte_wren_signal	;
block_byte_addr <= ram_write_address_signal;

prev_block_write_sd_addr 	 <= block_write_sd_addr_interal;


--Main State Machine.
next_state_logic : process(clk, rst_n)
begin
 if(rst_n = '0') then



  -- Default Signal Values
  command_load_en 			<= '0';
  command_send_en 			<= '0';

  read_r1_response_en		<= '0';
  read_r6_response_en		<= '0';

  command_signal				<= x"FFFFFFFFFFFF";
  sd_status_signal 			<= x"FF";

  crc7_gen_en					  <= '0';
  crc16_gen_en_D0 			<= '0';
  crc16_gen_en_D1 			<= '0';
  crc16_gen_en_D2 			<= '0';
  crc16_gen_en_D3 			<= '0';

  block_write_process_en 	  <= '0';
  block_write_process_en_4 	<= '0';

  multiblock_en  			    <= '0';
  block_read_process_en 	<= '0';
  read_data_token_reponse_en 	<= '0';


  card_rca_signal   <= (others => '0');
  card_rca_s        <= (others => '0');
  delay_en        <= '0';

  resend <= '0';

  sclk_en <= '1';

  block_success   <= '0';
  ext_trigger		  <= '0';
  new_block_write <= '0';

  init_done_signal <= '0';
  init_done_s <= '0';

  current_state <= ENTRY;

  elsif (rising_edge(clk)) then

  command_load_en <= '0';

  cmd_write_en	  <= '0';
  D0_write_en     <= '0';
  D1_write_en     <= '0';
  D2_write_en     <= '0';
  D3_write_en     <= '0';
  command_send_en <= '0';

  read_r1_response_en		<= '0';
  read_r6_response_en		<= '0';

  crc7_gen_en					  <= '0';
  crc16_gen_en_D0 			<= '0';
  crc16_gen_en_D1 			<= '0';
  crc16_gen_en_D2 			<= '0';
  crc16_gen_en_D3 			<= '0';


  sclk_en <= '1';

  block_write_process_en 	  <= '0';
  block_write_process_en_4 	<= '0';

 --This bit held through many states.
  --multiblock_en  			    <= '0';

  block_read_process_en 	    <= '0';
  read_data_token_reponse_en 	<= '0';
  delay_en                    <= '0';
  new_block_write             <= '0';
  resend                      <= '0';
  block_success               <= '0';
  ext_trigger                 <= '0';

  sd_status_signal <= x"FF";




  case current_state is
    when ENTRY =>


      sd_status_signal <= x"00";
      init_done_s <= init_done_in;
      init_done_signal <= init_done_s;

      card_rca_s      <= card_rca_in;
      card_rca_signal <= card_rca_s;

      if (init_done_signal = '1') then
        --Set false path through this signal.

        current_state <= CMD7_INIT;
      end if;
       --Early on in development a delay after initialization proved useful.
    when DELAY =>
    delay_en        <= '1';
      if (delay_done = '1') then
        --Transition to SD's "Transfer State" where we can read and write from.
        current_state <= CMD7_INIT;
      end if;


      --With some slight modifications the block read, single block
      --write, multiblock single bit, multiblock with preerase, and erase can be
      -- brought functional. Focus on 1.8V,4bit,CMD25 development
      --resulted in these other pathways going somewhat unmaintained.
      --Mutliblock read however has never been worked on.
      --The commands for these operations are already researched.
      --Simply excercising the appropriate process enable
      --bits and tweaking FSM pathways would result in these other
      --paths becoming operational.
      --Only the CMD25 pathway is fully functional at this moment.
      --MAIN STATE MACHINE BRANCH
    when APP_WAIT =>
      sd_status_signal <= x"01";
      sclk_en <= '0';


      case sd_control_signal is
        -- Perform a block read
        -- when x"01" =>
          -- current_state <= CMD17_INIT;
        --Perform a multiple block read
        --when x"02" =>
        --current_state <= APP_CMD18_INIT;
        -- --Perform a block write
        -- when x"03" =>
          -- current_state <= CMD24_INIT;

        -- -- Perform a multiblock write single bit
        -- when x"04" =>
          -- --If the hs_sdr25 bit set, insert a CMD6 to switch to sdr25 mode.
          -- if (hs_sdr25_mode_en = '1') then
            -- if ( ac_mode_switch_done = '0') then
              -- current_state 	<=  CMD6_INIT;
            -- --Else start writing.
            -- else
              -- current_state <= CMD25_INIT;
            -- end if;
          -- else
            -- current_state <= CMD25_INIT;
          -- end if;
        -- -- Perform a multiblock write with pre-erase
        -- when x"05" =>
        -- --return_state <= ACMD23_INIT;
          -- current_state <= CMD55_INIT;
        -- -- Perform a multiblock erase.
        -- when x"0E" =>
          -- current_state <= CMD32_INIT;


        -- Perform a multiblock write 4 bit
        --**This is the only pathway currently in operation.**--
        when x"44" =>
          if (widedone = '0') then
            --Do a wide mode (4bit switch).
            --This requires a CMD55 followed by an ACMD6.
            current_state <= CMD55_INIT_ACMD6;
            --hs_sdr25_mode_en check and switch is tied into the
            --next state logic. Unlike in the single bit case above.
          else
            --If already in 4 bit mode, start or continue writing.
            current_state <= CMD25_INIT_4;
          end if;

      -- -- Perform a multiblock read 4 bit
        -- when x"48" =>
          -- if (widedone = '0') then
            -- --Do a wide mode (4bit switch).
            -- --This requires a CMD55 followed by an ACMD6.
            -- current_state <= CMD55_INIT_ACMD6;
            -- return_state <= CMD25_INIT_4
            -- --hs_sdr25_mode_en check and switch is tied into the
            -- --next state logic. Unlike in the single bit case above.
          -- else
            -- --If already in 4 bit mode, start or continue writing.
            -- current_state <= CMD25_INIT_4;
          -- end if;

        when others =>
          current_state <= APP_WAIT;
        end case;


    -----------
    --CMD24(WRITE_SINGLE_BLOCK)
    --Single block write.
    --Not efficient (10x slower) compared to mutliblock (128) writes.
    -----------

    when CMD24_INIT =>
      current_state <= CMD24_SEND;


    when CMD24_SEND =>
      if (command_send_done = '1') then
        current_state <= CMD24_READ;
      end if;

    when CMD24_READ =>
      if (read_r1_response_done = '1') then

        current_state <= CMD24_DATA_INIT;

      end if;

    when CMD24_DATA_INIT =>
      current_state <= CMD24_DATA;


    when CMD24_DATA =>
      if(block_write_done = '1') then
        current_state <= CMD13_INIT;
      end if;

    -----------
    --CMD25(WRITE_MULTIPLE_BLOCK)
    --The multiblock write command.
    --Begins a streaming write to the
    --sd card. This is the 1 bit pathway.
    -----------

    when CMD25_INIT =>
      if(multiblock_write_done = '1') then
        current_state <= CMD12_INIT;
      else
        current_state <= CMD25_SEND;
      end if;

    when CMD25_SEND =>
      if (command_send_done = '1') then
        current_state <= CMD25_READ;
      end if;

    when CMD25_READ =>
      if (read_r1_response_done = '1') then
      --RDY FOR DATA BIT
        if (response_1_status(8) = '1') then
          current_state <= CMD25_DATA_INIT;
        else
          current_state <= ERROR;
        end if;
      end if;



    when CMD25_DATA_INIT =>
      current_state <= CMD25_DATA;



    when CMD25_DATA =>
      if (multiblock_write_done = '1') then
        current_state <= CMD25_DATA_READ_12;
      elsif(block_write_done = '1') then
        current_state <= CMD25_DATA_READ_13MULTI;
      end if;

    when CMD25_DATA_READ_12 =>
      if(read_data_token_reponse_done = '1') then
        --Check that data was received okay.
        --SPI Data token of SD card mode.
        if(read_data_token_byte(3 downto 1) = "010") then
          current_state <= CMD12_INIT;
        else
          current_state <= ERROR;
        end if;
      else
          current_state <= CMD25_DATA_READ_12;
      end if;

    when CMD25_DATA_READ_13MULTI =>
      if(read_data_token_reponse_done = '1') then
        --Check that data was received okay.
        --SPI Data token of SD card mode.
        if(read_data_token_byte(3 downto 1) = "010") then
          current_state <= CMD13_INIT_MULTI;
        else
          current_state <= ERROR;
        end if;
      else
        current_state <= CMD25_DATA_READ_13MULTI;
      end if;



    -----------
    --CMD25(WRITE_MULTIPLE_BLOCK)
    --The multiblock write command.
    --Begins a streaming write to the sd card. This is the 4 bit pathway.
    -----------

    when CMD25_INIT_4 =>

    command_signal <= '0' & '1' & "011001" & block_write_sd_addr & x"01";
    --Multiblock is set on here.
    --It is latched on until CMD12 completes a multiblock.
    --All retry paths do not turn off this bit.
    multiblock_en <= '1';


      if(multiblock_write_done = '1') then
        current_state <= CMD12_INIT;
      else
        current_state <= CMD25_SEND_4;
      end if;

    when CMD25_SEND_4 =>
    command_send_en   <= '1';
    crc7_gen_en       <= '1';
    cmd_write_en			<= '1';

      if (command_send_done = '1') then
        current_state <= CMD25_READ_4;
      end if;

    when CMD25_READ_4 =>
      read_r1_response_en <= '1';


      if (read_r1_response_done = '1') then
        if (response_1_status(8) = '1') then   --RDY FOR DATA BIT
          current_state <= CMD25_DATA_INIT_4;
        else
          return_state <= CMD25_INIT_4;
          current_state <= CMD13_INIT_TIMEOUT_REC;
        end if;
      elsif(cmd_resend_en = '1') then
        return_state <= CMD25_INIT_4;
        current_state <= CMD13_INIT_TIMEOUT_REC;
      end if;


    when CMD25_DATA_INIT_4 =>

      new_block_write <= '1';
      current_state <= CMD25_DATA_4;


    when CMD25_DATA_4 =>


      block_write_process_en_4 <= '1';
      D0_write_en 			<= '1';
      D1_write_en 			<= '1';
      D2_write_en 			<= '1';
      D3_write_en 			<= '1';

      crc16_gen_en_D0 <= '1';
      crc16_gen_en_D1 <= '1';
      crc16_gen_en_D2 <= '1';
      crc16_gen_en_D3 <= '1';


      if(block_write_done = '1') then
        current_state <= CMD25_DATA_4_READ_TOKEN;
      end if;



    when CMD25_DATA_4_READ_TOKEN =>

      read_data_token_reponse_en <= '1';


      if(read_data_token_reponse_done = '1') then
        --Check that data was received okay.SPI Data token of SD card mode.
        if(read_data_token_byte(3 downto 1) = "010") then
          current_state <= CMD25_DATA_4_READ_CRC_SUCCESS;
          block_success <= '1';
        else
        --Else crc token indicates failure.
        --Interesting note here. If a crc error occurs mid
        --multiblock, all further blocks are ignored! Must resend
        --CMD25.
          current_state <= CMD25_DATA_4_RESEND;
        end if;
      else
        current_state <= CMD25_DATA_4_READ_TOKEN;
      end if;

    --Resend bit set in this state to trigger address handling due to error.
    when CMD25_DATA_4_RESEND =>
      resend <= '1';

      current_state <= CMD12_INIT_ABORT;

    when CMD25_INIT_4_RESEND =>
      command_signal <= '0' & '1' & "011001"
                        & block_write_sd_addr_interal & x"01";

      if(multiblock_write_done = '1') then
        current_state <= CMD12_INIT;
      else
        current_state <= CMD25_SEND_4_RESEND;
      end if;
    --This CMD25 contains the address we wish to try write again.
    when CMD25_SEND_4_RESEND =>
      command_send_en <= '1';
      crc7_gen_en <= '1';
      cmd_write_en			<= '1';

      if (command_send_done = '1') then
        current_state <= CMD25_READ_4;
      end if;


    -----------
    --CRC SUCCESS state. This state are included to detect
    --if the last block was received correctly.
    -----------
    when CMD25_DATA_4_READ_CRC_SUCCESS  =>

      current_state <= CMD25_DATA_4_READ_DECIDE;

    when CMD25_DATA_4_READ_DECIDE =>

      if (multiblock_write_done = '1') then
        current_state <= CMD12_INIT;
      else
        current_state <= CMD13_INIT_MULTI_4;
      end if;


    -----------
    --CMD13(SEND_STATUS)
    --Card Status is returned.
    --This is used to check if the card
    --is ready for data before sending
    --another block to the card in a
    --multiblock stream/write.
    -----------

    --CMD 13's are broken into single bit and multi bit and inbetween
    --blocks and at the end of a CMD25/CMD12
    --CMD13 Returns card status field in an R1 response.
    --Used for checking
    --that card is READY_FOR_DATA inbetween blocks of
    --a multiblock write primarily.
    --Other bits of interest are APP_CMD, ILLEGAL COMMAND, etc.
    --CMD13_ is used anywhere but inbetween blocks of a multiblock write.
    when CMD13_INIT =>
      command_signal <= '0' & '1' & "001101"
                         &  card_rca_signal  &  x"000001";


      current_state <= CMD13_SEND;

    when CMD13_SEND =>
    command_send_en   <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en       <= '1';
      if (command_send_done = '1') then
        current_state <= CMD13_READ;
      end if;

    when CMD13_READ =>
    read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
      --Card Status READY_FOR_DATA Page 76 SD Spec.
        if (response_1_status(8) = '1') then
          current_state <= APP_WAIT;
        else
          current_state <= CMD13_INIT;
        end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT;
      end if;



    --This is an example recovery path for command crc error
    --error recovery.

    when CMD13_INIT_TIMEOUT_REC =>
      command_signal <= '0' & '1' & "001101"
                    &  card_rca_signal  &  x"000001";
      current_state <= CMD13_SEND_TIMEOUT_REC;

    when CMD13_SEND_TIMEOUT_REC =>
    command_send_en   <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en       <= '1';

      if (command_send_done = '1') then
        current_state <= CMD13_READ_TIMEOUT_REC;
      end if;

    when CMD13_READ_TIMEOUT_REC =>
      read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --The Card Status READY_FOR_DATA never will go high again in
        --this instance. Send CMD12 again.
        if (return_state = CMD12_INIT_ABORT) then
          current_state <= return_state;
        else
          --Card Status READY_FOR_DATA Page 76 SD Spec.
          if (response_1_status(8) = '1') then
            current_state <= return_state;
          else
            current_state <= CMD13_INIT_TIMEOUT_REC;
          end if;
        end if;

      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_TIMEOUT_REC;
      end if;




    -----------
    --CMD13(SEND_STATUS)
    --SD Status is returned.
    --This is used to check if the
    --card is ready for data before
    --sending another block to the
    --card in a multiblock stream/write.
    -----------
    --**The CMD13 for the 1 bit multiblock path**
    --CMD13 string of commands used with CMD25 Multiblock write.
    --Used between blocks of a multiblock write.
    when CMD13_INIT_MULTI =>
      current_state <= CMD13_SEND_MULTI;

    when CMD13_SEND_MULTI =>
      if (command_send_done = '1') then
        current_state <= CMD13_READ_MULTI;
      end if;

    when CMD13_READ_MULTI =>
      if (read_r1_response_done = '1') then
        --Card Status READY_FOR_DATA
        if (response_1_status(8) = '1') then
          current_state <= CMD25_DATA_INIT;
        else
          current_state <= CMD13_INIT_MULTI;
        end if;
      end if;


    -----------
    --CMD13(SEND_STATUS)
    --SD Status is returned.
    --This is used to check if the card is ready for
    --data before sending another block to the card
    --in a multiblock stream/write.
    -----------
    --The 4 bit multiblock path

    --CMD13 string of commands used with CMD25 Multiblock write.
    --Used between blocks of a multiblock write.
    when CMD13_INIT_MULTI_4 =>
      command_signal <= '0' & '1' & "001101"
                    &  card_rca_signal  &  x"000001";
      current_state <= CMD13_SEND_MULTI_4;


    when CMD13_SEND_MULTI_4 =>
    command_send_en <= '1';
    crc7_gen_en <= '1';

    cmd_write_en			<= '1';
      if (command_send_done = '1') then
        current_state <= CMD13_READ_MULTI_4;
      end if;

    when CMD13_READ_MULTI_4 =>
     read_r1_response_en <= '1';

      if (read_r1_response_done = '1') then
        if (response_1_status(8) = '1') then --Card Status READY_FOR_DATA
          if (resending = '0') then
            current_state <= CMD25_DATA_INIT_4;
          else
            current_state <= CMD25_INIT_4_RESEND;
          end if;
        else
          current_state <= CMD13_INIT_MULTI_4;
        end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_MULTI_4;
      end if;


    -----------
    --CMD7(SELECT/DESELECT_CARD)
    --Take card from Standby to Transfer State.
    -----------
    --After init, take the card from standby to transfer mode.
    --A nice state diagram exists in the SD SPEC. Page 27.
    --Command to take SD card from standby mode to transfer mode,
    --from which data writing is initiated.
    when CMD7_INIT =>
    command_signal <= '0' & '1' & "000111"
                  &  card_rca_signal  &  x"000001";



      current_state <= CMD7_SEND;


    when CMD7_SEND =>
    cmd_write_en			<= '1';
    command_send_en <= '1';
    crc7_gen_en       <= '1';
      if (command_send_done = '1') then
        current_state <= CMD7_READ;
      end if;

    when CMD7_READ =>

    read_r1_response_en <= '1';

      if (read_r1_response_done = '1') then
        --If the bad command or crc error flags are not set.
        if (response_1_status(23 downto 22) = "00") then
          current_state <= APP_WAIT;
        else
          current_state <= CMD7_INIT;
        end if;
      --An example recovery scenario. Additional paths needed
      --for the entire protocol but this is proof that this scheme
      --will work.
      elsif(cmd_resend_en = '1') then
        return_state <= CMD7_INIT;
        current_state <= CMD13_INIT_TIMEOUT_REC;
      end if;


    -----------
    --CMD6(SWITCH_FUNC)
    --Put card into HS_SDR25 Mode for 25-50Mhz.
    -----------
    --CMD6 is the function switch command. Page 41 SD Spec 3.01
    --1 bit pathway

    --CMD6 is the function switch command.
    --We can change speeds and current levels. See page 44 Sd Spec 3.01
    when CMD6_INIT =>
      current_state <= CMD6_SEND;


    when CMD6_SEND =>
      if (command_send_done = '1') then
        current_state <= CMD6_READ;
      end if;

    when CMD6_READ =>
      --CMD6 inquiry and set function both included 512 bits sent
      --back to the host over D0. We must wait for these even if
      --we don't do anything with them currently.
      --Response was checked and written up to verify it was done correctly.
      if (CMD6_D0_read_done = '1') then
        current_state <= CMD25_INIT;
      end if;


    -----------
    --CMD6(SWITCH_FUNC)
    --Put card into HS_SDR25 Mode for 25-50Mhz.
    -----------
    --CMD6 is the function switch command. Page 41 SD Spec 3.01
    --4 bit pathway
    --CMD6 is the function switch command.
    --We can change speeds and current levels.
    --See page 44 Sd Spec 3.01

    when CMD6_INIT_4 =>

      command_signal <= '0' & '1' & "000110"
                        & x"80" & x"FFFFF1"  &  x"01";


      current_state <= CMD6_SEND_4;


    when CMD6_SEND_4 =>
      command_send_en <= '1';
      crc7_gen_en       <= '1';
      cmd_write_en			<= '1';
      if (command_send_done = '1') then
        current_state <= CMD6_READ_4;
      end if;

    when CMD6_READ_4 =>
       read_r1_response_en <= '1';
       block_read_process_en 	<= '1';
      --CMD6 inquiry and set function both included
      --512 bits sent to the host over D0.
      --We must wait for these bit before proceeding,
      --even if they aren't checked
      --with program

      if (CMD6_D0_read_done = '1') then
        current_state <= CMD25_INIT_4;
        --end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_TIMEOUT_REC;
        return_state <= CMD6_INIT_4;
      end if;



		--
    --CMD32/33/38 are the ERASE COMMANDS
    --
    --CMD32(ERASE_WR_BLK_START)  Set start of erase.
    -----------
    when CMD32_INIT =>
    command_signal <= '0' & '1' & "100000" & erase_start & x"01";
      current_state <= CMD32_SEND;

    when CMD32_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en       <= '1';
      if (command_send_done = '1') then
          current_state <= CMD32_READ;
      end if;

    when CMD32_READ =>
    read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --check for COM_CRC_ERROR and ILLEGAL COMMAND
        if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD33_INIT;
        else
          current_state <= ERROR;
        end if;
      end if;
    -----------
    --CMD33(ERASE_WR_BLK_END)  Set end of erase.
    -----------
    when CMD33_INIT =>
    command_signal <= '0' & '1' & "100001" & erase_end & x"01";
      current_state <= CMD33_SEND;

    when CMD33_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en       <= '1';
      if (command_send_done = '1') then
        current_state <= CMD33_READ;
      end if;

    when CMD33_READ =>
    read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --check for COM_CRC_ERROR and ILLEGAL COMMAND
        if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD38_INIT;
        else
          current_state <= ERROR;
        end if;
      end if;
    -----------
    --CMD38(ERASE_WR_BLK_END)  Erase!
    -----------
    when CMD38_INIT =>
    command_signal <= '0' & '1' & "100110" & x"0000000001";

    current_state <= CMD38_SEND;

    when CMD38_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en       <= '1';
      if (command_send_done = '1') then
        current_state <= CMD38_READ;
      end if;

    when CMD38_READ =>
    read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --check for COM_CRC_ERROR and ILLEGAL COMMAND
        if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD13_INIT;
        else
          current_state <= ERROR;
        end if;
      end if;

    -----------
    --CMD12(STOP_TRANSMISSION)
    --Stop a multiblock write transmission.
    -----------
    --CMD12 is the stop data send command. Used to cap a
    --multiblock stream during a CMD25.
    when CMD12_INIT =>
    sd_status_signal <= x"48";
    command_signal <= '0' & '1' & "001100" & x"0000000001";
    multiblock_en <= '0';
    current_state <= CMD12_SEND;

    when CMD12_SEND =>
    command_send_en <= '1';
    cmd_write_en			<= '1';
    crc7_gen_en 			<= '1';
      if (command_send_done = '1') then
        current_state <= CMD12_READ;
      end if;

    when CMD12_READ =>
    read_r1_response_en <= '1';

      if (read_r1_response_done = '1') then
        --check for COM_CRC_ERROR and ILLEGAL COMMAND
        if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD13_INIT;
        else
          current_state <= CMD13_INIT_TIMEOUT_REC;
          return_state <= CMD12_INIT;
        end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_TIMEOUT_REC;
        return_state <= CMD12_INIT;
      end if;


    --These CMD12's are jumped to following a data response token
    --indicating anything besides succesfull receive of a data
    --block by the sd card.
    when CMD12_INIT_ABORT =>
     command_signal <= '0' & '1' & "001100" & x"0000000001";

      current_state <= CMD12_SEND_ABORT;

    when CMD12_SEND_ABORT =>
    cmd_write_en			<= '1';
    crc7_gen_en 			<= '1';
    command_send_en <= '1';
    multiblock_en     <= '1';
      if (command_send_done = '1') then
        current_state <= CMD12_READ_ABORT;
      end if;

    when CMD12_READ_ABORT =>
    read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --check for COM_CRC_ERROR and ILLEGAL COMMAND
        -- if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD13_INIT_MULTI_4;
        -- else
          -- current_state <= ERROR;
        -- end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_TIMEOUT_REC;
        return_state <= CMD12_INIT_ABORT;
      end if;


    -----------
    --CMD55(APP_CMD)
    --This command is sent before any ACMD.
    --This simply tells the card that an expanded command
    --is coming next.
    -----------
    -- Send CMD55 (APP_CMD) to the SD card to preface impending
    -- application-specific command
    when CMD55_INIT =>
      current_state <= CMD55_SEND;

    when CMD55_SEND =>
      if (command_send_done = '1') then
        current_state <= CMD55_READ;
      end if;

    when CMD55_READ =>
      if (read_r1_response_done = '1') then
        --This bit is the APP_CMD bit of the status register.
        --The other bit set on CMD55 response is READY FOR DATA.
        if (r1_response_bytes(13) = '1') then
          --current_state <= return_state;
        else
          current_state <= ERROR;
        end if;
      end if;


    -----------
    --ACMD23(SET_WR_BLK_ERASE_COUNT)
    --Used to pre-erase before a write.
    -----------

    when ACMD23_INIT =>
      current_state <= ACMD23_SEND;

    when ACMD23_SEND =>
      if (command_send_done = '1') then
        current_state <= ACMD23_READ;
      end if;

    when ACMD23_READ =>
      if (read_r1_response_done = '1') then
        --Checksum is okay and command valid.
        if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD25_INIT;
        else
          current_state <= ERROR;
        end if;
      end if;

    -----------
    --ACMD6(SET_BUS_WIDTH)
    --Switch to 4 bit mode. Use D1-D3 now.
    -----------
    --Switches to Wide Mode. 4 bit mode. Data0-Data3 now used.
    when ACMD6_INIT =>
      command_signal <= '0' & '1' & "000110"
                  & x"000000" & "000000" & "10" & x"01";
      current_state <= ACMD6_SEND;

    when ACMD6_SEND =>

    command_send_en   <= '1';
    crc7_gen_en 			<= '1';
    cmd_write_en			<= '1';

      if (command_send_done = '1') then
        current_state <= ACMD6_READ;
      end if;

    when ACMD6_READ =>
    read_r1_response_en <= '1';
      if (read_r1_response_done = '1') then
        --Checksum is okay and command valid.
        if (response_1_status(23 downto 22) = "00") then
          if (hs_sdr25_mode_en = '1') then
            current_state <= CMD6_INIT_4;
          else
            current_state <= CMD25_INIT_4;
          end if;
        else
            current_state <= CMD13_INIT_TIMEOUT_REC;
            return_state <= CMD55_INIT_ACMD6;
        end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_TIMEOUT_REC;
        return_state <= CMD55_INIT_ACMD6;
      end if;


    -----------
    --ACMD13(SD_STATUS)
    --Send back the sd status.
    --Used for Debug.
    --512 status bits will come back on the D0 line.
        -----------

    when ACMD13_INIT =>
      current_state <= ACMD13_SEND;


    when ACMD13_SEND =>
      if (command_send_done = '1') then
        current_state <= ACMD13_READ;
      end if;

    when ACMD13_READ =>
      --512 bits sent to the host over D0. We must wait for these.
      if (CMD6_D0_read_done = '1') then
        current_state <= CMD25_INIT_4;
      end if;



    -----------
    --ACMD42(SET_CLR_CARD_DETECT)
    --Program/Deprogram the pullup resistor on D3.
    --Tested but never used.
    -----------
    --Never implemented, but played with during debugging.

    --Turn off the pullup resistor on DAT3.
    when ACMD42_INIT =>
      current_state <= ACMD42_SEND;


    when ACMD42_SEND =>
      if (command_send_done = '1') then
        current_state <= ACMD42_READ;
      end if;

    when ACMD42_READ =>
      if (read_r1_response_done = '1') then
        if (response_1_status(23 downto 22) = "00") then
          current_state <= CMD55_INIT_ACMD13;
        else
          current_state <= ERROR;
        end if;
      end if;

    -----------
    --CMD17(READ_SINGLE_BLOCK) Read a single block.
    -----------
    --Not completely working but close.


    when CMD17_INIT =>
      current_state <= CMD17_SEND;


    when CMD17_SEND =>
      if (command_send_done = '1') then
        current_state <= CMD17_READ;
      end if;

    when CMD17_READ =>
      if (read_r1_response_done = '1') then
        current_state <= CMD17_READ_DATA;
      end if;

    when CMD17_READ_DATA =>
      if (singleblock_read_done = '1') then
        current_state <= APP_WAIT;
      end if;


    when IDLE 	=>
      current_state <= IDLE;

    when ERROR 	=>
      current_state <= ERROR;


  --The following CMD55s are pathways to get to particular APP CMDS.
  --Each APP CMD has its one CMD55 pathway.
  --This method was done as creating a
  --return_state enumeration caused warnings initially.
  --Send CMD55 (APP_CMD) to the SD card to preface impending
  --application-specific command
    when CMD55_INIT_ACMD6 =>

    command_signal <= '0' & '1' & "110111"
                  & card_rca_signal  &  x"000001";


      current_state <= CMD55_SEND_ACMD6;

    when CMD55_SEND_ACMD6 =>

    command_send_en <= '1';
    crc7_gen_en 			<= '1';
    cmd_write_en			<= '1';

      if (command_send_done = '1') then
        current_state <= CMD55_READ_ACMD6;
      end if;

    when CMD55_READ_ACMD6 =>

    read_r1_response_en <= '1';


      if (read_r1_response_done = '1') then
        --This bit is the APP_CMD bit of the status register.
        --The other bit set on first CMD55 response is READY FOR DATA.
        if (r1_response_bytes(13) = '1') then
          current_state <= ACMD6_INIT;
        elsif (response_1_status(23 downto 22) /= "00") then
          current_state <= CMD55_INIT_ACMD6;
          return_state <= CMD55_INIT_ACMD6;
        else
          current_state <= ERROR;
        end if;
      elsif(cmd_resend_en = '1') then
        current_state <= CMD13_INIT_TIMEOUT_REC;
        return_state <= CMD55_INIT_ACMD6;
      end if;

    -- Send CMD55 (APP_CMD) to the SD card
    --to preface impending application-specific command
    when CMD55_INIT_ACMD42 =>
      current_state <= CMD55_SEND_ACMD42;

    when CMD55_SEND_ACMD42 =>
      if (command_send_done = '1') then
        current_state <= CMD55_READ_ACMD42;
      end if;

    when CMD55_READ_ACMD42 =>
      if (read_r1_response_done = '1') then
      --This bit is the APP_CMD bit of the status register.
      --The other bit set on first CMD55 response is READY FOR DATA.
        if (r1_response_bytes(13) = '1') then
          current_state <= ACMD42_INIT;
        else
          current_state <= ERROR;
        end if;
        -- elsif(cmd_resend_en = '1') then
        -- current_state <= CMD55_INIT_ACMD42;
      end if;

    -- Send CMD55 (APP_CMD) to the SD card to preface impending application-specific command
    when CMD55_INIT_ACMD13 =>
      current_state <= CMD55_SEND_ACMD13;

    when CMD55_SEND_ACMD13 =>
      if (command_send_done = '1') then
        current_state <= CMD55_READ_ACMD13;
      end if;

    when CMD55_READ_ACMD13 =>
      if (read_r1_response_done = '1') then
        --This bit is the APP_CMD bit of the status register.
        --The other bit set on first CMD55 response is READY FOR DATA.
        if (r1_response_bytes(13) = '1') then
          current_state <= ACMD13_INIT;
        else
          current_state <= ERROR;
        end if;
      end if;


  end case;
end if;
end process;


--
-- --
-- --OUTPUT LOGIC PROCESS
-- --


-- process(current_state)
-- begin


  -- -- Default Signal Values
  -- command_load_en 			<= '0';
  -- command_send_en 			<= '0';

  -- read_r1_response_en		<= '0';
  -- read_r6_response_en		<= '0';

  -- command_signal				<= x"FFFFFFFFFFFF";
  -- sd_status_signal 			<= x"FF";

  -- crc7_gen_en					  <= '0';
  -- crc16_gen_en_D0 			<= '0';
  -- crc16_gen_en_D1 			<= '0';
  -- crc16_gen_en_D2 			<= '0';
  -- crc16_gen_en_D3 			<= '0';

  -- block_write_process_en 	  <= '0';
  -- block_write_process_en_4 	<= '0';

  -- multiblock_en  			    <= '0';
  -- block_read_process_en 	<= '0';
  -- read_data_token_reponse_en 	<= '0';

  -- crc16_bitval_signal_D0 <= '0';
  -- crc16_bitval_signal_D1 <= '0';
  -- crc16_bitval_signal_D2 <= '0';
  -- crc16_bitval_signal_D3 <= '0';

  -- dat0_signal <= '1';
  -- dat1_signal <= '1';
  -- dat2_signal <= '1';
  -- dat3_signal <= '1';

  -- card_rca_signal <= card_rca;

  -- resend <= '0';


  -- block_success   <= '0';
  -- ext_trigger		  <= '0';
  -- new_block_write <= '0';


  -- case current_state is

    -- -----------
    -- --ENTRY is the state where the FSM sits while init is done.
    -- -----------

    -- when ENTRY =>

      -- CMD_signal <= '1';

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


      -- card_rca_signal <= card_rca;
      -- state_leds <= "0000";
      -- sd_status_signal <= x"00";

    -- -----------
    -- --APP_WAIT is the central state from
    -- --which a control signal launches
    -- --the state machine.
    -- -----------


    -- when APP_WAIT =>


      -- CMD_signal <= '1';


      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- state_leds <= "0001";
      -- sd_status_signal <= x"01";

    -- -----------
    -- --CMD24(Send Single Block).
    -- --Send a single block to the sd card.
    -- -----------


    -- when CMD24_INIT =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "011000" & block_write_sd_addr & x"01";
      -- command_load_en <= '1';

      -- state_leds <= "0010";
      -- sd_status_signal <= x"02";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD24_SEND =>

      -- CMD_signal <= output_command(47);

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- crc7_gen_en <= '1';

      -- state_leds <= "0011";
      -- sd_status_signal <= x"03";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD24_READ =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- read_r1_response_en <= '1';

      -- state_leds <= "0100";
      -- sd_status_signal <= x"04";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD24_DATA_INIT =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';



      -- state_leds <= "1111";
      -- sd_status_signal <= x"05";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '1';
      -- D1_write_en 			<= '1';
      -- D2_write_en 			<= '1';
      -- D3_write_en 			<= '1';

    -- when CMD24_DATA =>

      -- dat0_signal <= wr_block_byte_data(7);

      -- CMD_signal <= '1';

      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';


      -- block_write_process_en <= '1';

      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '1';

      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc16_gen_en_D0   <= '1';


    -- -----------
    -- --Custom state. Delay inserted when coming into DATA FSM.
    -- --Card was found unresponsive immediately after init.
    -- -----------

    -- when DELAY =>

      -- CMD_signal <= '1';

      -- state_leds <= "0110";
      -- sd_status_signal <= x"0D";
      -- cmd_write_en			<= '0';

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- delay_en          <= '1';


    -- -----------
    -- --CMD13(SEND_STATUS)
    -- --SD Status is returned. This is used to check if the card is
    -- --ready for data before sending another block to the card in
    -- --a multiblock stream/write.
    -- --This CMD13 is used once after CMD12 and not inbetween
    -- --blocks of multiblock write.


    -- when CMD13_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- --IMPORTANT: The CRC7 is defaulted to x"01".
      -- --It will be filled by CRC7GEN and cmdsend processes.
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD13_SEND =>

      -- CMD_signal <= output_command(47);
      -- --IMPORTANT: The CRC7 is defaulted to x"01".
      -- --It will be filled by CRC7GEN and CMD_SEND
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- crc7_gen_en <= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD13_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"68";



    -- -----------
    -- --CMD7(SELECT/DESELECT_CARD)
    -- --Take card from Standby to Transfer State.
    -- -----------


    -- when CMD7_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "000111"
                        -- &  card_rca_signal  &  x"000001";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when CMD7_SEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "000111"
                        -- &  card_rca_signal  &  x"000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc7_gen_en       <= '1';





    -- when CMD7_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- ext_trigger       <= '1';



    -- -----------
    -- --CMD6(SELECT/DESELECT_CARD)
    -- --Put card into HS_SDR25 Mode for 25-50Mhz.
    -- -----------
    -- --CMD6 is the function switch command. Page 41 SD Spec 3.01

    -- when CMD6_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- --This command it attempting an actual switch "80" rather
      -- --than a check [most sig bit] and changing
      -- --to high speed mode, "FFFFF1", the '1' being the mode switch.
      -- command_signal <= '0' & '1' & "000110"
                        -- & x"80" & x"FFFFF1"  &  x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when CMD6_SEND =>

      -- CMD_signal <= output_command(47);
      -- --This command it attempting an actual switch "80" rather
      -- --than a check [most sig bit] and changing
      -- --to high speed mode, "FFFFF1", the '1' being the mode switch.
      -- command_signal <= '0' & '1' & "000110"
                        -- & x"80" & x"FFFFF1"  &  x"01";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc7_gen_en       <= '1';



    -- when CMD6_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- block_read_process_en 	<= '1';

    -- -----------
    -- --CMD6(SWITCH_FUNC)
    -- --Put card into HS_SDR25 Mode for 25-50Mhz.
    -- -----------
    -- --CMD6 is the function switch command. Page 41 SD Spec 3.01
    -- --4 bit pathway
    -- when CMD6_INIT_4 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- --This command does a function switch "80" rather
      -- --than a function check [most sig bit].
      -- --We change to  high speed mode, "FFFFF1",
      -- --the '1' being the mode switch.
      -- command_signal <= '0' & '1' & "000110"
                        -- & x"80" & x"FFFFF1"  &  x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when CMD6_SEND_4 =>

      -- CMD_signal <= output_command(47);
      -- --This command it attempting an actual switch "80" rather
      -- --than a check [most sig bit] and changing
      -- --to high speed mode, "FFFFF1", the '1' being the mode switch.
      -- command_signal <= '0' & '1' & "000110" & x"80"
                        -- & x"FFFFF1"  &  x"01";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- --Here I am driving all the lines into a known state.
      -- --I am sensing the data lines start bit,
      -- --so they need to be in a known state.
      -- --Hopefully these lines won't droop
      -- --(or level translator won't change them)
      -- --before the sd card starts to drive them.
      -- cmd_write_en			<= '1';

      -- --Might not want to do this.
      -- --Either use bus hold or pull up or
      -- --a level translator which will translate this.

      -- D0_write_en 			<= '1';
      -- D1_write_en 			<= '1';
      -- D2_write_en 			<= '1';
      -- D3_write_en 			<= '1';
      -- crc7_gen_en       <= '1';



    -- when CMD6_READ_4 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- block_read_process_en 	<= '1';


    -- -----------
    -- --ACMD13(SD_STATUS)
    -- --Send back the sd status.
    -- --Only used for debug currently.
    -- --512 status bits will come back on the D0 line.
    -- -----------

    -- when ACMD13_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "001101" & x"00" & x"000000"  &  x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when ACMD13_SEND =>

      -- CMD_signal <= output_command(47);
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc7_gen_en       <= '1';



    -- when ACMD13_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- --ACMD13 sends back 512 bit SD STATUS register on D0.
      -- block_read_process_en 	<= '1';


    -- -----------
    -- --ACMD42(SET_CLR_CARD_DETECT)
    -- --Program/Deprogram the pullup resistor on D3.
    -- --Tested but never used.
    -- -----------
    -- --Never implemented, but played with during debugging.

    -- when ACMD42_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- --Least signficant bit '0' in 32 bit stuff bits is disabling
      -- --the pullup resistor on DAT3.
      -- command_signal <= '0' & '1' & "101010" & x"00" & x"000000"  &  x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when ACMD42_SEND =>

      -- CMD_signal <= output_command(47);
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc7_gen_en       <= '1';



    -- when ACMD42_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- -----------
    -- --CMD32(ERASE_WR_BLK_START)
    -- --Set start of erase.
    -- -----------
    -- when CMD32_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "100000" & erase_start & x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when CMD32_SEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "100000" & erase_start & x"01";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


      -- crc7_gen_en       <= '1';

    -- when CMD32_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- -----------
    -- --CMD33(ERASE_WR_BLK_END)
    -- --Set end of erase.
    -- -----------
    -- when CMD33_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "100001" & erase_end & x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';





    -- when CMD33_SEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "100001" & erase_end & x"01";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


      -- crc7_gen_en       <= '1';



    -- when CMD33_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- -----------
    -- --CMD38(ERASE_WR_BLK_END)
    -- --Erase!
    -- -----------

    -- when CMD38_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "100110" & x"0000000001";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when CMD38_SEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "100110" & x"0000000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


      -- crc7_gen_en       <= '1';



    -- when CMD38_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- sd_status_signal <= x"E0";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- -----------
    -- --CMD25(WRITE_MULTIPLE_BLOCK)
    -- --The multiblock write command. Begins a streaming
    -- --write to the sd card. This is the 1 bit pathway.
    -- -----------

    -- when CMD25_INIT =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "011001" & block_write_sd_addr & x"01";
      -- command_load_en <= '1';

      -- state_leds <= "0010";
      -- sd_status_signal <= x"02";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"40";

      -- multiblock_en     <= '1';


    -- when CMD25_SEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "011001" & block_write_sd_addr & x"01";

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- crc7_gen_en <= '1';

      -- state_leds <= "0011";
      -- sd_status_signal <= x"03";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"41";

      -- multiblock_en <= '1';

    -- when CMD25_READ =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0100";
      -- sd_status_signal <= x"04";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '1';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal  <= x"42";

      -- multiblock_en     <= '1';

    -- when CMD25_DATA_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- state_leds <= "1111";
      -- sd_status_signal <= x"05";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"43";

      -- multiblock_en <= '1';

    -- when CMD25_DATA =>

      -- dat0_signal <= wr_block_byte_data(7);
      -- crc16_bitval_signal_D0 <= wr_block_byte_data(7);
      -- crc16_gen_en_D0 <= '1';
      -- CMD_signal <= '1';

      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- block_write_process_en <= '1';
      -- multiblock_en <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '1';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc16_gen_en_D0 <= '1';
      -- sd_status_signal <= x"44";

    -- when CMD25_DATA_READ_12 =>

      -- read_data_token_reponse_en <= '1';
      -- CMD_signal <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";

      -- block_write_process_en <= '1';
      -- multiblock_en <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- sd_status_signal <= x"44";


    -- when CMD25_DATA_READ_13MULTI =>

      -- read_data_token_reponse_en <= '1';
      -- CMD_signal <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";

      -- block_write_process_en <= '1';
      -- multiblock_en <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- sd_status_signal <= x"44";


    -- -----------
    -- --CMD25(WRITE_MULTIPLE_BLOCK)
    -- --The multiblock write command.
    -- --Begins a streaming write to the sd card. This is the 4 bit pathway.
    -- -----------


    -- when CMD25_INIT_4 =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "011001" & block_write_sd_addr & x"01";
      -- command_load_en <= '1';

      -- state_leds <= "0010";
      -- sd_status_signal <= x"02";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"40";

      -- multiblock_en <= '1';


    -- when CMD25_SEND_4 =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "011001" & block_write_sd_addr & x"01";

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- crc7_gen_en <= '1';

      -- state_leds <= "0011";
      -- sd_status_signal <= x"03";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"41";

      -- multiblock_en <= '1';

    -- when CMD25_READ_4 =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0100";
      -- sd_status_signal <= x"04";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"42";

      -- multiblock_en <= '1';

    -- when CMD25_DATA_INIT_4 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- state_leds <= "1111";
      -- sd_status_signal <= x"05";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"43";

      -- multiblock_en <= '1';
      -- new_block_write <= '1';

    -- when CMD25_DATA_4 =>

      -- if (append_crc_4_bit = '0') then
        -- dat0_signal <= wr_block_byte_data(4);
      -- else
        -- dat0_signal <= crc16_signal_D0_fin(15);
      -- end if;

      -- if (append_crc_4_bit = '0') then
        -- dat1_signal <= wr_block_byte_data(5) ;
      -- --Point to test crc errors in stream and resend.
      -- --To disable do not increment data_error_rate.
      -- elsif (data_error_rate = to_unsigned(data_error_rate_control,data_error_rate'length)) then
        -- dat1_signal <= '1';
      -- else
        -- dat1_signal <= crc16_signal_D1_fin(15);
      -- end if;

      -- if (append_crc_4_bit = '0') then
        -- dat2_signal <= wr_block_byte_data(6);
      -- else
        -- dat2_signal <= crc16_signal_D2_fin(15);
      -- end if;

      -- if (append_crc_4_bit = '0') then
        -- dat3_signal <= wr_block_byte_data(7);
      -- else
        -- dat3_signal <=	crc16_signal_D3_fin(15);
      -- end if;
      -- --Send data into CRC components
      -- crc16_bitval_signal_D0 <= wr_block_byte_data(4);
      -- crc16_bitval_signal_D1 <= wr_block_byte_data(5);
      -- crc16_bitval_signal_D2 <= wr_block_byte_data(6);
      -- crc16_bitval_signal_D3 <= wr_block_byte_data(7);

      -- CMD_signal <= '1';
      -- block_write_process_en_4 <= '1';
      -- multiblock_en <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";

      -- cmd_write_en			<= '0';

      -- D0_write_en 			<= '1';
      -- D1_write_en 			<= '1';
      -- D2_write_en 			<= '1';
      -- D3_write_en 			<= '1';

      -- crc16_gen_en_D0 <= '1';
      -- crc16_gen_en_D1 <= '1';
      -- crc16_gen_en_D2 <= '1';
      -- crc16_gen_en_D3 <= '1';

      -- sd_status_signal <= x"44";

    -- -----------
    -- --Read the data response token that comes after a sent block.
    -- --Jump to appropriate CMD (12/13) depending if we want to send more blocks.
    -- -----------


    -- when CMD25_DATA_4_READ_TOKEN =>

      -- read_data_token_reponse_en <= '1';
      -- CMD_signal <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";


      -- multiblock_en <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- sd_status_signal <= x"44";


    -- -----------
    -- --CRC SUCCESS states.
    -- --These are included to detect
    -- --if the last block was received correctly.
    -- -----------



    -- when CMD25_DATA_4_READ_CRC_SUCCESS =>

      -- CMD_signal <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";


      -- multiblock_en <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- sd_status_signal <= x"44";

      -- block_success <= '1';


    -- when CMD25_DATA_4_READ_DECIDE =>

      -- CMD_signal <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";


      -- multiblock_en <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- sd_status_signal <= x"44";



    -- when CMD25_DATA_4_RESEND =>

      -- CMD_signal <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"06";
      -- resend <= '1';


      -- multiblock_en <= '1';

      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

      -- sd_status_signal <= x"44";

    -- when CMD25_INIT_4_RESEND =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "011001"
                        -- & block_write_sd_addr_interal & x"01";
      -- command_load_en <= '1';

      -- state_leds <= "0010";
      -- sd_status_signal <= x"02";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"40";

      -- multiblock_en <= '1';


    -- when CMD25_SEND_4_RESEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "011001"
                        -- & block_write_sd_addr_interal & x"01";

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- crc7_gen_en <= '1';

      -- state_leds <= "0011";
      -- sd_status_signal <= x"03";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal  <= x"41";

      -- multiblock_en     <= '1';




    -- when ERROR =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- state_leds <= "1111";
      -- --state_val <= x"11";
      -- sd_status_signal <= x"08";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when IDLE =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- state_leds <= "1000";
      -- --state_val <= x"12";
      -- sd_status_signal <= x"09";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- -----------
    -- --CMD13(SEND_STATUS)
    -- --Card Status is returned.
    -- --This is used to check if the card is ready
    -- --for data before sending another block to the card
    -- --in a multiblock stream/write.
    -- -----------

    -- when CMD13_INIT_MULTI =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- multiblock_en <= '1';
      -- sd_status_signal <= x"45";

    -- when CMD13_SEND_MULTI =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- crc7_gen_en <= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- multiblock_en <= '1';
      -- sd_status_signal <= x"46";

    -- when CMD13_READ_MULTI =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- multiblock_en <= '1';
      -- sd_status_signal <= x"47";

    -- -----------
    -- --CMD13(SEND_STATUS)
    -- --Card Status is returned. This is used to check
    -- --if the card is ready for data before sending another
    -- --block to the card in a multiblock stream/write.
    -- --4 bit path.
    -- -----------

    -- when CMD13_INIT_MULTI_4 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- multiblock_en <= '1';
      -- sd_status_signal <= x"45";



    -- when CMD13_SEND_MULTI_4 =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- crc7_gen_en <= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- multiblock_en <= '1';
      -- sd_status_signal <= x"46";

    -- when CMD13_READ_MULTI_4 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- multiblock_en <= '1';
      -- sd_status_signal <= x"47";

    -- -----------
    -- --CMD12(STOP_TRANSMISSION)
    -- --Stop a multiblock write transmission.
    -- -----------

    -- when CMD12_INIT =>

      -- CMD_signal <= '1';

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "001100" & x"0000000001";
      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"48";



    -- when CMD12_SEND =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "001100" & x"0000000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- crc7_gen_en 			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"49";


    -- when CMD12_READ =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"4A";


    -- when CMD12_INIT_ABORT =>

      -- CMD_signal <= '1';

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "001100" & x"0000000001";
      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"58";
      -- multiblock_en <= '1';



    -- when CMD12_SEND_ABORT =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "001100" & x"0000000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- crc7_gen_en 			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"59";
      -- multiblock_en <= '1';


    -- when CMD12_READ_ABORT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"5A";
      -- multiblock_en <= '1';

    -- -----------
    -- --CMD55(APP_CMD)
    -- --This command is sent before any ACMD.
    -- --This simply tells the card that an expanded command is coming next.
    -- -----------

    -- when CMD55_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "110111"
                        -- & card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0111";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_SEND =>

      -- CMD_signal <= output_command(47);

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- state_leds <= "1000";
      -- crc7_gen_en 			<= '1';
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_READ =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- read_r1_response_en <= '1';
      -- state_leds <= "1001";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- -----------
    -- --ACMD23(SET_WR_BLK_ERASE_COUNT)
    -- --Used to pre-erase before a write.
    -- -----------


    -- when ACMD23_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "010111" & x"00" & '0' &
      -- std_logic_vector(to_unsigned(num_blocks_to_write,23)) & x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0111";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when ACMD23_SEND =>

      -- CMD_signal <= output_command(47);

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- state_leds <= "1000";
      -- crc7_gen_en 			<= '1';
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when ACMD23_READ =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- read_r1_response_en <= '1';
      -- state_leds <= "1001";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- -----------
    -- --ACMD6(SET_BUS_WIDTH)
    -- --Switch to 4 bit mode. Use D1-D3 now.
    -- -----------


    -- when ACMD6_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- --Bit 0 indicates bus width. 0 = 1 bit 1 = 4 bit.
      -- --The rest are stuff bits. Page 66 SD Protocol.
      -- command_signal <= '0' & '1' & "000110"
                        -- & x"000000" & "000000" & "10" & x"01";
      -- command_load_en <= '1';
      -- state_leds <= "0111";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';



    -- when ACMD6_SEND =>

      -- CMD_signal <= output_command(47);
      -- --Bit 0 indicates bus width. 0 = 1 bit 1 = 4 bit.
      -- --The rest are stuff bits. Page 66 SD Protocol.
      -- command_signal <= '0' & '1' & "000110"
                        -- & x"000000" & "000000" & "10" & x"01";

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- state_leds <= "1000";
      -- crc7_gen_en 			<= '1';
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when ACMD6_READ =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';



      -- read_r1_response_en <= '1';
      -- state_leds <= "1001";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';



    -- -----------
    -- --CMD17(READ_SINGLE_BLOCK) Read a single block.
    -- -----------


    -- when CMD17_INIT =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_signal <= '0' & '1' & "010001"
                        -- &  block_read_sd_addr  &  x"01";

      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';


    -- when CMD17_SEND =>

      -- CMD_signal <= output_command(47);
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- sd_status_signal <= x"43";
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- crc7_gen_en <= '1';



    -- when CMD17_READ =>

      -- CMD_signal 			<= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en 	<= '1';
      -- state_leds				 <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD17_READ_DATA =>

      -- CMD_signal 			<= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- state_leds				 <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- block_read_process_en	 <= '1';


    -- -----------
    -- --  Different exit paths for CMD55 are below.
    -- --  ACMD's must be preceded with CMD55.
    -- -----------

    -- when CMD55_INIT_ACMD6 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "110111"
                        -- & card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0111";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_SEND_ACMD6 =>

      -- CMD_signal <= output_command(47);
      -- command_signal <= '0' & '1' & "110111"
                        -- & card_rca_signal  &  x"000001";

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- state_leds <= "1000";
      -- crc7_gen_en 			<= '1';
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_READ_ACMD6 =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- read_r1_response_en <= '1';
      -- state_leds <= "1001";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_INIT_ACMD42 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "110111"
                        -- & card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0111";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_SEND_ACMD42 =>

      -- CMD_signal <= output_command(47);

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- state_leds <= "1000";
      -- crc7_gen_en 			<= '1';
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_READ_ACMD42 =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- read_r1_response_en <= '1';
      -- state_leds <= "1001";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_INIT_ACMD13 =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_signal <= '0' & '1' & "110111"
                        -- & card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0111";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_SEND_ACMD13 =>

      -- CMD_signal <= output_command(47);

      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- command_send_en <= '1';
      -- state_leds <= "1000";
      -- crc7_gen_en 			<= '1';
      -- cmd_write_en			<= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD55_READ_ACMD13 =>


      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';

      -- read_r1_response_en <= '1';
      -- state_leds <= "1001";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';




    -- when CMD13_INIT_TIMEOUT_REC =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- --IMPORTANT: The CRC7 is defaulted to x"01".
      -- --It will be filled by CRC7GEN and cmdsend processes.
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- command_load_en <= '1';
      -- state_leds <= "0100";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD13_SEND_TIMEOUT_REC =>

      -- CMD_signal <= output_command(47);
      -- --IMPORTANT: The CRC7 is defaulted to x"01".
      -- --It will be filled by CRC7GEN and CMD_SEND
      -- command_signal <= '0' & '1' & "001101"
                        -- &  card_rca_signal  &  x"000001";
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- command_send_en <= '1';
      -- state_leds <= "0101";
      -- cmd_write_en			<= '1';
      -- crc7_gen_en <= '1';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';

    -- when CMD13_READ_TIMEOUT_REC =>

      -- CMD_signal <= '1';
      -- dat0_signal <= '1';
      -- dat1_signal <= '1';
      -- dat2_signal <= '1';
      -- dat3_signal <= '1';
      -- read_r1_response_en <= '1';
      -- state_leds <= "0110";
      -- cmd_write_en			<= '0';
      -- D0_write_en 			<= '0';
      -- D1_write_en 			<= '0';
      -- D2_write_en 			<= '0';
      -- D3_write_en 			<= '0';
      -- sd_status_signal <= x"68";





  -- end case;

-- end process;

--
--Delay Process
--Used upon first coming into microsd_data.
--

-- first_delay :	process(rst_n, clk) is
-- begin
  -- if(rst_n = '0') then
    -- delay_count <= 0;
    -- delay_done <= '0';
	-- elsif rising_edge(clk) then
    -- if (delay_en = '1') then
      -- if (delay_count = 8) then
        -- delay_done <= '1';
      -- else
        -- delay_count <= delay_count + 1;
        -- delay_done <= '0';
      -- end if;
    -- else
        -- delay_count <= 0;
        -- delay_done <= '0';
    -- end if;
  -- end if;
-- end process first_delay ;

--Overview of data flow, crc7 gen, and sampling.
--Data is moved on the negative edge of the clock so its ready for
--sampling on the positive edge of the clock at the SD Card.
--SD card is strictly
--rising edge sampling, apart from more advanced ddr modes.
--The crcs are updated at the same time that data is sampled,
--on the rising edge of the clock.
--The final bit of a crc is quick. The data must be sampled on
--the rising edge, and the crc appended and put on line for sampling
--on following rising edge. This is how it is currently done.


--CRC7 process. --Enabled on ANY CMDXX_SEND state. This process
--is compact. The crc7 is generated streaming and readied within
--1/2 clock cycle for append to streaming data.

crc7_bitval_signal <= output_command(47);
crc7_done <= '1' when (crc7_send_bit_count = 40) else '0';
crc7_rst_signal <= '1' when (crc7_gen_en = '1') else '0' ;

crc7_gen:   process(rst_n, clk)
begin
  if (rst_n ='0') then
    crc7_send_bit_count <= 0;
  elsif falling_edge(clk) then
    if (crc7_gen_en = '1') then
      crc7_send_bit_count <= crc7_send_bit_count + 1;
    else
      crc7_send_bit_count <= 0;
    end if;
  end if;
end process crc7_gen;

--CRC16 process. --Enabled during data transmit CMD24_DATA/CMD25_DATA
CRC16_GEN0:	process(rst_n, clk)
begin
  if (rst_n ='0') then
    crc16_rst_signal_D0 <= '0';
    crc16_send_bit_count_D0 <= 0;
    crc16_done_D0 <= '0';
    crc16_send_byte_count_D0 <= 0;


  elsif falling_edge(clk) then
    if (crc16_gen_en_D0 = '1') then
      if (crc16_send_bit_count_D0 = 7) then
        crc16_send_byte_count_D0 <= crc16_send_byte_count_D0 + 1;
        crc16_send_bit_count_D0 <= 0;
        crc16_rst_signal_D0 <= '1';
        crc16_done_D0 <= '0';
      else
        crc16_rst_signal_D0 <= '1';
        crc16_send_bit_count_D0 <= crc16_send_bit_count_D0 + 1;
        crc16_done_D0 <= '0';
      end if;
    else
        crc16_rst_signal_D0 <= '0';
        crc16_send_bit_count_D0 <= 0;
    end if;

  else --rising edge of clock
    if (crc16_send_bit_count_D0 = 7) then
      if (crc16_send_byte_count_D0 = 511) then   --Assert done
        crc16_done_D0 <= '1';
        crc16_send_bit_count_D0 <= 0;
        crc16_send_byte_count_D0 <= 0;
      end if;
    end if;

  end if;

end process CRC16_GEN0;




--CRC16 process. --Enabled during data transmit CMD24_DATA/CMD25_DATA
CRC16_GEN1:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    crc16_done_D1 <= '0';
    crc16_rst_signal_D1 <= '0';
    crc16_send_bit_count_D1 <= 0;
    crc16_send_byte_count_D1 <= 0;
  elsif falling_edge(clk) then
    if (crc16_gen_en_D1 = '1') then
      if (crc16_send_bit_count_D1 = 7) then
        crc16_send_byte_count_D1 <= crc16_send_byte_count_D1 + 1;
        crc16_send_bit_count_D1 <= 0;
        crc16_rst_signal_D1 <= '1';
        crc16_done_D1 <= '0';
      else
        crc16_rst_signal_D1 <= '1';
        crc16_send_bit_count_D1 <= crc16_send_bit_count_D1 + 1;
        crc16_done_D1 <= '0';
      end if;
    else
        crc16_rst_signal_D1 <= '0';
        crc16_send_bit_count_D1 <= 0;
    end if;

  else --rising edge of clock

    if (crc16_send_bit_count_D1 = 7) then
      if (crc16_send_byte_count_D1 = 511) then   --Assert done
        crc16_done_D1 <= '1';
        crc16_send_bit_count_D1 <= 0;
        crc16_send_byte_count_D1 <= 0;
      end if;
    end if;

  end if;

end process CRC16_GEN1;

--CRC16 process. --Enabled during data transmit CMD24_DATA/CMD25_DATA
CRC16_GEN2:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    crc16_done_D2 <= '0';
    crc16_rst_signal_D2 <= '0';
    crc16_send_bit_count_D2 <= 0;
    crc16_send_byte_count_D2 <= 0;
  elsif falling_edge(clk) then
    if (crc16_gen_en_D2 = '1') then
      if (crc16_send_bit_count_D2 = 7) then
        crc16_send_byte_count_D2 <= crc16_send_byte_count_D2 + 1;
        crc16_send_bit_count_D2 <= 0;
        crc16_rst_signal_D2 <= '1';
        crc16_done_D2 <= '0';
      else
        crc16_rst_signal_D2 <= '1';
        crc16_send_bit_count_D2 <= crc16_send_bit_count_D2 + 1;
        crc16_done_D2 <= '0';
      end if;
    else
      crc16_rst_signal_D2 <= '0';
      crc16_send_bit_count_D2 <= 0;
    end if;

  else --rising edge of clock
    if (crc16_send_bit_count_D2 = 7) then
      if (crc16_send_byte_count_D2 = 511) then   --Assert done
        crc16_done_D2 <= '1';
        crc16_send_bit_count_D2 <= 0;
        crc16_send_byte_count_D2 <= 0;
      end if;
    end if;
  end if;
end process CRC16_GEN2;

--CRC16 process. --Enabled during data transmit CMD24_DATA/CMD25_DATA
CRC16_GEN3:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    crc16_done_D3 <= '0';
    crc16_rst_signal_D3 <= '0';
    crc16_send_bit_count_D3 <= 0;
    crc16_send_byte_count_D3 <= 0;

  elsif falling_edge(clk) then
    if (crc16_gen_en_D3 = '1') then
        if (crc16_send_bit_count_D3 = 7) then
          crc16_send_byte_count_D3 <= crc16_send_byte_count_D3 + 1;
          crc16_send_bit_count_D3 <= 0;
          crc16_rst_signal_D3 <= '1';
          crc16_done_D3 <= '0';
        else
          crc16_rst_signal_D3 <= '1';
          crc16_send_bit_count_D3 <= crc16_send_bit_count_D3 + 1;
          crc16_done_D3 <= '0';
        end if;
    else
      crc16_rst_signal_D3 <= '0';
      crc16_send_bit_count_D3 <= 0;
    end if;

  else --rising edge of clock
    if (crc16_send_bit_count_D3 = 7) then
      if (crc16_send_byte_count_D3 = 511) then   --Assert done
        crc16_done_D3 <= '1';
        crc16_send_bit_count_D3 <= 0;
        crc16_send_byte_count_D3 <= 0;
      end if;
    end if;

  end if;
end process CRC16_GEN3;


--
--Process used and engaged to sent any command to the
--SD card.
--


cmd_signal <= output_command(47) when (cmdstartbit = '1') else '1';

--SEND ANY CMD with CRC7 APPEND
cmd_send:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    cmdstartbit             <= '0';
    command_send_done       <= '0';
    command_send_bit_count  <= 0;
    output_command          <= x"FFFFFFFFFFFF";
  --Data is shifted on falling edge of clock.
  elsif falling_edge(clk) then

  --cmdstarbit is a once off start bit align.
    if (command_send_en = '1' and cmdstartbit = '0') then
      output_command <= command_signal;
      cmdstartbit <= '1';
    elsif (command_send_en = '1' and cmdstartbit = '1') then
        if (command_send_bit_count = 48) then
          command_send_done <= '1';
          command_send_bit_count <= 0;
        elsif (crc7_done = '1') then
          if (cmd_error_rate = to_unsigned(cmd_error_rate_control,cmd_error_rate'length) or
                                start_error = '1') then
            output_command <= "1010101" & '1' & x"FFFFFFFFFF";
            command_send_bit_count <= command_send_bit_count + 1;
          else
            output_command <= crc7_signal & '1' & x"FFFFFFFFFF";
            command_send_bit_count <= command_send_bit_count + 1;
          end if;
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




--Below are incoming response handlers which sample the cmd lines
--for response sent after commands.

read_r1_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    read_r1_response_done <= '0';
    response_1_status <= (others => '1');
    response_1_current_state_bits <= (others => '1');
    r1_response_bytes  <= x"FFFFFFFFFFFF";
    read_bytes <= x"FFFFFFFFFFFF";
  elsif rising_edge(clk) then
    read_r1_response_done <= '0';
    if (read_r1_response_en = '1') then
      if (read_bytes(47) = '0') then
        read_r1_response_done <= '1';
        r1_response_bytes <= read_bytes;
        --Debug register to look at card status field of r1 response
        response_1_status <= read_bytes(39 downto 8);
        --A debug register to look at
        --CARD STATE of the card status reponse field.
        response_1_current_state_bits <= read_bytes(20 downto 17);
        read_bytes <= x"FFFFFFFFFFFF";
      else
        read_bytes <= read_bytes(46 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process read_r1_response;

read_r6_response:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    read_r6_response_done   <= '0';
    r6_response_bytes       <= x"FFFFFFFFFFFF";
    read_r6_bytes           <= x"FFFFFFFFFFFF";
  elsif rising_edge(clk) then
    read_r6_response_done <= '0';
    if (read_r6_response_en = '1') then
      if (read_r6_bytes(47) = '0') then
        read_r6_response_done <= '1';
        r6_response_bytes <= read_r6_bytes;
        --card_rca_signal 	<= read_r6_bytes(39 downto 24);
        --RCA is passed from INIT.
        --response_6_status <= read_r6_bytes(23 downto 8);
        read_r6_bytes <= x"FFFFFFFFFFFF";
      else
        read_r6_bytes <= read_r6_bytes(46 downto 0) & cmd_signal_in_signal;
      end if;
    end if;
  end if;
end process read_r6_response;


--
--Single Block WRITE and Multi Block Write Card Data
--This is the block writing process. It handles both single block and
--multi block writing to the sd card. Supporting processes such as the
--crc gen processes aid it, but the actual data movement is here.
--



--Data is all coming from clocked processes.

  dat0_signal <= wr_block_byte_data(4) when (append_crc_4_bit = '0') else
  crc16_signal_D0_fin(15);

  dat1_signal <= wr_block_byte_data(5) when (append_crc_4_bit = '0') else
  crc16_signal_D1_fin(15);

  dat2_signal <= wr_block_byte_data(6) when (append_crc_4_bit = '0') else
  crc16_signal_D2_fin(15);

  dat3_signal <= wr_block_byte_data(7) when (append_crc_4_bit = '0') else
  crc16_signal_D3_fin(15);

  --Send data into CRC components
  crc16_bitval_signal_D0 <= wr_block_byte_data(4);
  crc16_bitval_signal_D1 <= wr_block_byte_data(5);
  crc16_bitval_signal_D2 <= wr_block_byte_data(6);
  crc16_bitval_signal_D3 <= wr_block_byte_data(7);



master_block_write: process(rst_n, clk) is
begin
  if (rst_n = '0') then
      wr_block_bit_count <= 0;
      wr_block_byte_count <= 0;
      --Best to initialized lines and data to F as start bit
      --is always '0' in communications.
      wr_block_byte_data <= x"FF";
      load <= '1';
      ram_read_address_signal <= "000000000";
      append_crc_4_bit <= '0';
      start_bit <= '0';
  --falling edge of sclk.
  --DATA IS SHIFTED/LOADED ON THE FALLING EDGE OF TRANSMISSION CLOCK.
  elsif falling_edge(clk) 	then
    if (block_write_process_en = '1' or block_write_process_en_4 = '1') then
      --Make sure start bit goes through.
      if ( start_bit = '0') then
        wr_block_byte_data <= x"00";
        start_bit <= '1';
      --Load the first byte. Increment counter accordingly.
      elsif (load = '1') then
        wr_block_byte_data <= block_write_data;
        --if (resending = '0') then
        ram_read_address_signal <= std_logic_vector(
                                unsigned(ram_read_address_signal) + 1);
        --end if;
        load <= '0';

        if(block_write_process_en = '1') then
          wr_block_bit_count <= wr_block_bit_count + 1;
        else -- must be in 4 bit mode.
          wr_block_bit_count <= wr_block_bit_count + 4;
        end if;

      else
        --If we are at the end of a byte
        if (wr_block_bit_count = 8) then
          --If we are at the end of 512 bytes we need to append CRC16 to signal.
          if (block_write_process_en = '1') then
            if (wr_block_byte_count = 511) then
              --Append the first 8 bits of the crc16
              wr_block_byte_data <= crc16_signal_D0(15 downto 8);
              --Grab/Store the entire crc16 at this moment
              crc16_signal_D0_fin <= crc16_signal_D0;
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 1;
            elsif (wr_block_byte_count = 512) then
              wr_block_byte_data <= crc16_signal_D0_fin(7 downto 0);
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 1;
            elsif (wr_block_byte_count = 513) then
              wr_block_byte_data <= x"FF";
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 1;
            else
              wr_block_byte_data <= block_write_data;  --
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 1;
              ram_read_address_signal <= std_logic_vector(
                                      unsigned(ram_read_address_signal) + 1);
            end if;
          else -- must be in 4 bit mode.

            if (wr_block_byte_count = 511) then



              --Append the first 8 bits of the crc16
              append_crc_4_bit <= '1';
               if (data_error_rate = to_unsigned(data_error_rate_control,data_error_rate'length)) then
                --Test an incorrect CRC.
                crc16_signal_D0_fin <= x"AAAA";
                crc16_signal_D1_fin <= crc16_signal_D1;
                crc16_signal_D2_fin <= crc16_signal_D2;
                crc16_signal_D3_fin <= crc16_signal_D3;

                wr_block_byte_count <= wr_block_byte_count + 1;
                wr_block_bit_count <= 1;
              else
              --Grab/Store the entire crc16 at this moment
                crc16_signal_D0_fin <= crc16_signal_D0;
                crc16_signal_D1_fin <= crc16_signal_D1;
                crc16_signal_D2_fin <= crc16_signal_D2;
                crc16_signal_D3_fin <= crc16_signal_D3;

                wr_block_byte_count <= wr_block_byte_count + 1;
                wr_block_bit_count <= 1;
              end if;


            elsif (wr_block_byte_count = 512) then

              --Keep shifting the 16 bits values across the bytes border.
              --Append stop bit onto the crc16.
              crc16_signal_D0_fin <= crc16_signal_D0_fin(14 downto 0) & '1';
              crc16_signal_D1_fin <= crc16_signal_D1_fin(14 downto 0) & '1';
              crc16_signal_D2_fin <= crc16_signal_D2_fin(14 downto 0) & '1';
              crc16_signal_D3_fin <= crc16_signal_D3_fin(14 downto 0) & '1';
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 1;

            elsif (wr_block_byte_count = 513) then
              append_crc_4_bit <= '0';
              wr_block_byte_data <= x"FF";
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 4;
            else
              wr_block_byte_data <= block_write_data;
              wr_block_byte_count <= wr_block_byte_count + 1;
              wr_block_bit_count <= 4;
              ram_read_address_signal <= std_logic_vector(
                                      unsigned(ram_read_address_signal) + 1);
            end if;
          end if;
        else	---else increment along the data by one bit.
          if (block_write_process_en = '1') then
            wr_block_bit_count <= wr_block_bit_count + 1;
            wr_block_byte_data <= wr_block_byte_data(6 downto 0) & '1';
          else --must be in 4 bit mode.
            if(append_crc_4_bit = '1') then
              crc16_signal_D0_fin <= crc16_signal_D0_fin(14 downto 0) & '1';
              crc16_signal_D1_fin <= crc16_signal_D1_fin(14 downto 0) & '1';
              crc16_signal_D2_fin <= crc16_signal_D2_fin(14 downto 0) & '1';
              crc16_signal_D3_fin <= crc16_signal_D3_fin(14 downto 0) & '1';
              wr_block_bit_count <= wr_block_bit_count + 1;
            else
            --4 bit mode will need to increment by 4
            wr_block_bit_count <= wr_block_bit_count + 4;
            --In four bit mode we shift by 4 bits instead of 1.
            wr_block_byte_data <= wr_block_byte_data(3 downto 0) & "1111";

            end if;
          end if;



        end if;
      end if;
    else
      wr_block_bit_count <= 0;
      wr_block_byte_count <= 0;

      wr_block_byte_data <= x"FF";
      load <= '1';
      ram_read_address_signal <= "000000000";
      append_crc_4_bit <= '0';
      start_bit <= '0';
    end if;
  end if;
end process master_block_write;

--
--Block Write Done Signals
--Signal that one block has finished writing
--Multi block is the next process
--

block_write_d:process(rst_n, clk) is
begin
  if ( rst_n = '0') then
    block_write_done <= '0';
    num_blocks_written <= 0;
  elsif falling_edge(clk) then
    if (block_write_process_en = '1') then
      --Account for stop bit.
      if (wr_block_byte_count = 514 and wr_block_bit_count = 1) then
        block_write_done <= '1';
        if(multiblock_en = '1') then
          --Increment how many blocks have finished.
          --Important in multiblock write.
          num_blocks_written <= num_blocks_written + 1;
        end if;
      end if;
    elsif(block_write_process_en_4 = '1') then
      if (wr_block_byte_count = 514 and wr_block_bit_count = 4) then
        --Signal that an entire 512 byte block has finished.
        block_write_done <= '1';
      end if;
    else
      --We need to keep num_blocks_written around inbetween CMD25,
      --but reset once we leave multiblock_en zone.
      if(multiblock_en = '1' and block_success = '1') then
        num_blocks_written <= num_blocks_written + 1;
      elsif(multiblock_en = '1') then
        num_blocks_written <= num_blocks_written;
        block_write_done <= '0';
      else
        block_write_done <= '0';
        num_blocks_written <= 0;
      end if;
    end if;
	end if;
end process block_write_d;

--
-- Multiblock Write Done
-- Signal that the entire multiblock has finished
-- Done by counting the number of single blocks written
--
multiblock_wr_done: process(rst_n,clk) is
	begin
  if (rst_n = '0') then
    multiblock_write_done <= '0';
  elsif rising_edge(clk) then
    if (multiblock_en = '1') then
      if (num_blocks_written = num_blocks_to_write) then
        if (block_success = '1') then
        --Signal that an entire multiblock write has finished.
        multiblock_write_done <= '1';
        end if;
      else
        --Added here to prevent a latch.
        multiblock_write_done <= '0';
      end if;
    else
      multiblock_write_done <= '0';
    end if;
  end if;
end process multiblock_wr_done;



--
-- Block Read Card Data
-- Process responsible for sampling data
-- line when reading from card
--
-- Shift Register and Start Byte Sync
read_shifter: process(rst_n, clk) is
begin

  if (rst_n = '0') then
    block_byte_data_signal <= x"FF";
    block_bit_count <= 0;
    block_start_flag <= '0';
    start_read_bit <= '0';
  elsif rising_edge(clk) then
    if (block_read_process_en = '1') then
      if (block_start_flag = '1') then
        --Sample the D0 line
        --Shift the current value in but only if start bit has passed.
        block_byte_data_signal <= block_byte_data_signal(6 downto 0)
                                  & D0_signal_in_signal;
        -- if (multiblock)
        -- block_byte_data_signal <= block_byte_data_signal(3 downto 0)
                                  -- & D0_signal_in_signal;
        -- block_byte_data_signal <= block_byte_data_signal(3 downto 0)
                                  -- & D1_signal_in_signal;
        -- block_byte_data_signal <= block_byte_data_signal(3 downto 0)
                                  -- & D2_signal_in_signal;
        -- block_byte_data_signal <= block_byte_data_signal(3 downto 0)
                                  -- & D3_signal_in_signal;



        if (block_bit_count = 7) then
          block_bit_count <= 0;
        else
          --Sync the start bit. Sync bit 0 to block_bit_count 0.
          --One off mechanism for the very first bit of a block read.
          if (start_read_bit = '1')		then
            block_bit_count <= block_bit_count + 1;
          else
            start_read_bit <= '1';
          end if;
        end if;
      else
        if (D0_signal_in_signal = '0') then
          block_start_flag <= '1';
          block_bit_count <= 0;
        end if;
      end if;

    else
      block_byte_data_signal <= x"FF";
      block_bit_count <= 0;
      block_start_flag <= '0';
      start_read_bit <= '0';
    end if;

  end if;
end process read_shifter;


--
-- Memory Write Enable Signal Generation
-- Byte Counter, and
-- Address Counter for Single Block Read.
--
read_lines_handler: process(rst_n, clk) is
begin
  if (rst_n = '0') then
    block_byte_wren_signal <= '0';
    --Rather than do another once off flag.I'll roll over on first increment
    --to byte 0 address. Otherwise byte 0 is written to address 1.
    ram_write_address_signal <= (others => '1');
    block_byte_count <=  "0000000000";
	elsif falling_edge(clk) then
    --If we've enabled the read_process
    if (block_read_process_en = '1') then
      --If we've gotten past the start bit 0.
      if (block_start_flag = '1') then
        --If at bit 7 of transmit.
        if (block_bit_count = 7) then
          --DO NOT WRITE THE CRCs to ram. Byte 512 and 513 are CRCs.
          if ( block_byte_count = 512) then
            block_byte_wren_signal <= '0';
            --DO NOT WRITE THE CRCs to ram. Byte 512 and 513 are CRCs.
          elsif ( block_byte_count = 513) then
            block_byte_wren_signal <= '0';
          else
            --Else enable wr_en on a ram.
            block_byte_wren_signal <= '1';
          end if;
        --Copy data to the output register.
        block_byte_data_signal_out <= block_byte_data_signal;
        --Increment Internal bytes read counter. Up to 512 and 513 for CRC.
        block_byte_count <= block_byte_count + 1;
        --Increment Ram write address. Up to 511.
        --Starts at 511 and rolls over at beginning byte 0.
        ram_write_address_signal <= std_logic_vector(
                                  unsigned(ram_write_address_signal) + 1);
        else
          block_byte_wren_signal <= '0';
        end if;
      else
        block_byte_wren_signal <= '0';
      end if;
    else
      block_byte_wren_signal <= '0';
      --Rather than do another once off flag.....
      --I'll roll over on first increment to byte 0 address.
      --Otherwise byte 0 is written to address 1.
      ram_write_address_signal <= (others => '1');
      block_byte_count <=  "0000000000";
    end if;
	end if;
end process read_lines_handler;



--
-- Block Read Done Generation Process
--
block_read_done: process(rst_n, clk) is
begin
  if (rst_n = '0') then
    CMD6_D0_read_done <= '0';
    singleblock_read_done <= '0';
  elsif(rising_edge(clk)) then
    if (block_read_process_en = '1') then
      if (block_byte_count = 66) then
        CMD6_D0_read_done <= '1';
        singleblock_read_done <= '0';
      --CMD 17 read done flag.
      elsif (block_byte_count = 514) then
        singleblock_read_done <= '1';
        CMD6_D0_read_done <= '0';
      else
        CMD6_D0_read_done <= '0';
        singleblock_read_done <= '0';
      end if;
    else
      CMD6_D0_read_done <= '0';
      singleblock_read_done <= '0';
    end if;
  end if;
end process block_read_done;

--
-- Track wide mode (4bit) switch complete --
--
wide_mode_switch_done:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    widedone <= '0';
  elsif rising_edge(clk) then
    if (current_state = ACMD6_READ) then
      widedone <= '1';
    end if;
  end if;
end process wide_mode_switch_done;

--
-- Track Change into HS/SDR25 Mode via CMD6
--

ac_mode_switch_done_process:	process(rst_n, clk)
begin
  if (rst_n = '0') then
    ac_mode_switch_done <= '0';
  elsif rising_edge(clk) then
    if (current_state = CMD6_READ) then
      ac_mode_switch_done <= '1';
    end if;
  end if;
end process ac_mode_switch_done_process;


--
-- Data Response Token Handler  --
-- After sending write data to the sd card --
-- via CMD25, a response comes back immediately --
-- on the D0 line. This response is a Data Response --
-- token indicating data accepted or not --
-- This is not immediately evident in the SD protocol --
-- and the formation of the response is under the SPI --
-- section of the manual. PAGE 132 of 3.01 spec. --
--


READ_DATA_TOKEN_RESPONSE: process(rst_n, clk)
begin
  if (rst_n = '0') then
    reading_data_token_byte <= x"FF";
    read_data_token_reponse_done <= '0';
    read_data_token_byte  <= x"FF";

  elsif rising_edge(clk) then

    read_data_token_reponse_done <= '0';
    if (read_data_token_reponse_en = '1') then
      --If the start bit has landed in bit 4, we are done.
      if (reading_data_token_byte(4) = '0'
                               and reading_data_token_byte(0) = '1' ) then
        read_data_token_reponse_done <= '1';
        read_data_token_byte <= reading_data_token_byte;
        reading_data_token_byte <= x"FF";
      else
        reading_data_token_byte <=  reading_data_token_byte(6 downto 0)
                                    & d0_signal_in_signal;
      end if;
    else
      reading_data_token_byte <= x"FF";
    end if;
  end if;
end process READ_DATA_TOKEN_RESPONSE;


--
--Cmd response timeout process and explanation.
--
--If a response is not received in ~500ms, resend the command.
--If total error count becomes too high, pipe out restart signal
--The resend bit is checked in the next state logic.

--The below process does indeed work. However after a crc command timeout
--a cmd 13 must be sent to clear the status register bits before the card
--will accept the error'ed command again. A cmd_resend_en can be added
--to next state logic to enter CMD13_INIT_TIMEOUT_REC along with an
--appropriate setting of return_state to return to. The only command this was
--tested on was a resend of CMD7 but the path does indeed work. It simply
--needs to be added to all commands where simply resending the command again
--will be the appropriate action. APPCMDS and commands sent in and around
--data will probably need more care.

--APPCMDS might be handled by resending CMD55 if that errors and resending
--CMD55 if the APPCMD itself fails.

--CMD CRC error in response as well as timeout error due to no
--error follow the same pathways for now. A CMD13 is sent and then
--the offending cmd is tried again.

--Exception this are CMD12. Here I just proceed to CMD13. Card seems to
--program anyway.
--APPCMDS. The CMD55 must be resent again.


cmd_response_timeout_handler:	process(rst_n, clk)
begin
  if (rst_n = '0') then

    cmd_response_timeout <= 0;
    cmd_resend_en <= '0';
    cmd_resend_count <= (others => '0');
    restart_response <= '0';
    cmd_resend_timer_en <= '0';
  elsif rising_edge(clk) then

    if (command_send_done = '1') then
      cmd_resend_timer_en <= '1';
    elsif ( command_load_en = '1') then
      cmd_resend_timer_en <= '0';
    end if;

    if (cmd_resend_timer_en = '1') then

      if (cmd_response_timeout = cmd_timeout) then
        cmd_resend_en <= '1';
        cmd_resend_timer_en <= '0';
        cmd_resend_count <= cmd_resend_count + 1;
        if (cmd_resend_count = to_unsigned(63,cmd_resend_count'length)) then
          restart_response <= '1';
        end if;
      else
        cmd_response_timeout <=  cmd_response_timeout + 1;
      end if;
    else
      cmd_resend_en <= '0';
      cmd_response_timeout <= 0;
    end if;
end if;


end process cmd_response_timeout_handler;

--
--Data Block Write CRC Error Handling
--
--Track the number of data resends due to crc errors.
--Below is the data crc error process. In it we  set the resending
--flag to alter state machine pathways following a block crc failure.
--We also increment the data_error_rate to introduce errors into the
--written data at interval.
--To disable the error insertion, simply comment data_error_rates out in
--this process.
--CRC errors in a multiblock stream are handled by sending a CMD12 followed
--by an alternative CMD25 with the address of the last block which caused
--the failure.  The data crc error handling is local to microsd_data. The above
--processes which involve buffers are immune to block resends at this level.
--This is a very good thing.
--Also includes code for inserting data block errors at interval.

resend_count_tracker : process(rst_n, clk)
begin
  if (rst_n = '0') then
    resend_f <= '0';
    block_resend_count <= (others => '0');
    resending <= '0';
    data_error_rate <= to_unsigned(0,data_error_rate'length);
  elsif rising_edge(clk) then
      if(resend_f  /= resend) then
        resend_f <= resend;
        if (resend = '1') then
          resending <= '1';
          if (data_errors_enabled = '1') then
            data_error_rate <= data_error_rate + 1;
          end if;
          if (block_resend_count =  to_unsigned(63,block_resend_count'length)) then
            restart_crc <= '1';
          end if;
          block_resend_count <= block_resend_count + 1;
        end if;
      end if;

      if (block_success = '1') then
        resending <= '0';
        if (data_errors_enabled = '1') then
            data_error_rate <= data_error_rate + 1;
          end if;
      end if;
  end if;
end process resend_count_tracker;

--Debug process to insert command errors.
insert_cmd_errors : process(rst_n, clk)
begin
  if (rst_n = '0') then
    cmd_error_rate <= (others => '0');
  elsif rising_edge(clk) then
    if (cmd_errors_enabled = '1' and command_send_done = '1') then
      cmd_error_rate <= cmd_error_rate + 1;
    end if;

  end if;
end process insert_cmd_errors;


--
-- data_current_block_written
-- and
-- sd_block_written_flag
-- generation.
-- Generate the last successful address written global
-- output as well as the valid pulse which accompanies it.
--

address_success : process (rst_n, clk)
begin
  if (rst_n = '0') then

    first_block_of_multiblock <= '0';
    prev_block_write_sd_addr_pulse <= '0';
    block_write_sd_addr_interal <= (others => '0');

  elsif rising_edge(clk) then
    --Use a follower to do the following only once per change.
    if (block_success_follower /= block_success) then
      block_success_follower <= block_success;
      --We have passed the data token check successfully
      --based on hitting CRC Success States. Create pulse
      --and increment block count.
			if(block_success = '1') then
        prev_block_write_sd_addr_pulse <= '1';
			else
        prev_block_write_sd_addr_pulse <= '0';
			end if;
    end if;
    --Once on a new CMD25_DATA_INIT_4
    if(new_block_write_follower /= new_block_write) then
        new_block_write_follower <= new_block_write;

        --Handling of the block_write_sd_addr_internal is delicate around
        --resending of blocks. However if a resend events doesn't happen on the
        --very first block of the multiblock this process will not be effected.
		if (new_block_write = '1' and resending /= '1') then
      --Here we only increment the success address if the first block
      --of a multiblock has passed. This allows for address 0 to be passed out.
      if(first_block_of_multiblock = '1') then
        block_write_sd_addr_interal <= block_write_sd_addr;
        first_block_of_multiblock <= '0';
      else
        block_write_sd_addr_interal <= std_logic_vector(unsigned(block_write_sd_addr_interal) + 1);
      end if;
		end if;
	end if;
    --If we have returned to APP_WAIT reset the first block flag.
    if (SD_status_signal = x"01") then
        first_block_of_multiblock <= '1';
    end if;

  end if;

end process address_success;



use_debug:
	if ( DEBUG_ON = '1') generate

-- Debug Process to Characterize Inner Multiblock Write Waits.
inner_multiblock_wait: process(clk)
begin
    --Async reset of this debug process casuses problems in the build. Leaving out for now.
-- if (rst_n = '0') then

    -- cmd13multi_counter_done_1 <= '0';
    -- cmd13multi_counter_done <= '0';
    -- cmd13multi_counter <= to_unsigned(0,32);
    -- cmd12_13_counter <= to_unsigned(0,32);
    -- cmd25_setup_counter <= to_unsigned(0,32);
    -- cmd12_13_counter_reg <= to_unsigned(0,32);
    -- cmd13multi_counter_reg <= to_unsigned(0,32);
    -- cmd25_setup_counter_reg <= to_unsigned(0,32);
    -- CMD25_number_1 <= '0';
  if rising_edge(clk) then

    if (init_done_signal = '1') then

      if (current_state = CMD13_INIT_MULTI_4
                            OR current_state = CMD13_READ_MULTI_4
                            OR current_state = CMD13_SEND_MULTI_4) then
        cmd13multi_counter <= cmd13multi_counter + 1;
        cmd13multi_counter_reg <= cmd13multi_counter;
        cmd13multi_counter_done_1	<= '1';

      elsif(current_state = CMD13_INIT
            OR current_state = CMD13_READ
            OR current_state = CMD13_SEND
            OR current_state = CMD12_INIT
            OR current_state = CMD12_SEND
            OR current_state = CMD12_READ) then
        cmd12_13_counter <= cmd12_13_counter + 1;
        cmd12_13_counter_reg <= cmd12_13_counter;
        cmd13multi_counter_done_1	<= '1';

        --Note: This will not include pre_app_wait stuff, but this is
        --more realistic for a post init based delays study.
      elsif(current_state /= APP_WAIT)	then
        --This will include all states that
        --are not APP_WAIT/CMD12/CMD13/CMD13Multi.
        --Includes everything not CMD12/CMD13 related including
        --point 1 which is run up to app_wait.
        cmd25_setup_counter <= cmd25_setup_counter + 1;
        cmd25_setup_counter_reg <= cmd25_setup_counter;
        cmd13multi_counter_done_1	<= '1';

      else--Current state must be app_wait.


        if(cmd13multi_counter_done_1 = '1') then
          cmd13multi_counter_done_1 <= '0';
          cmd13multi_counter_done <= '1';
          CMD25_number_1 <= '1';

        else
          -- Increase the CMD25 counter AFTER we have
          -- stored the previous values.
          if (CMD25_number_1 = '1') then
            CMD25_number <= CMD25_number + 1;
            CMD25_number_1 <= '0';
          end if;

          cmd13multi_counter_done_1 <= '0';
          cmd13multi_counter_done <= '0';
          cmd13multi_counter <= to_unsigned(0,32);
          cmd12_13_counter <= to_unsigned(0,32);
          cmd25_setup_counter <= to_unsigned(0,32);
        end if;

      end if;
    end if;
--
--				end if;
--			end if;
  end if;
end process inner_multiblock_wait;


--Calculate throughput based on sucess address increment.
--Calculate throughput based on last throughput_array_length multiblocks.
throughput_calculate : process (rst_n, clk)
begin
  if (rst_n = '0') then
  prev_block_write_sd_addr_tp_track <= (others => '0');
  kilobytes_per_second_a <= (others => (others => '0'));
  kilobytes_per_second <= (others => '0');
  second_counter <= (others => '0');
  tp_array_pos <=  (others => '0');


  elsif rising_edge(clk) then

    if(second_counter = to_unsigned(counts_per_second,second_counter'length)) then
      kilobytes_per_second <= (others => '0');
      second_counter <= (others => '0');
    end if;

   case current_state is

     when  CMD12_INIT =>
        kilobytes_per_second_a(to_integer(tp_array_pos)) <= kilobytes_per_second;
        tp_array_pos <= tp_array_pos + 1;
      when  CMD25_DATA_4 =>
        second_counter <= second_counter + 1;
        if ( prev_block_write_sd_addr_tp_track /= unsigned(block_write_sd_addr_interal)) then
          if ( prev_block_write_sd_addr_tp_track = (unsigned(block_write_sd_addr_interal) - 2)) then
            kilobytes_per_second <= kilobytes_per_second + 1;
            prev_block_write_sd_addr_tp_track <= unsigned(block_write_sd_addr_interal);
          end if;
        end if;
      when APP_WAIT =>

      when others =>
        second_counter <= second_counter + 1;


    end case;

  end if;
end process throughput_calculate;




--Test all command recovery paths.
--One by one insert an error into each command to test recovery path.
-- This test process was successfully used to insert one error into each
--of the below command types. The commands were verified robust.
cmd_error_check : process (rst_n, clk)
begin
  if (rst_n = '0') then
    start_error <= '0';
    CMD7_INIT_check <= '0';
    CMD55_INIT_ACMD6_check <= '0';
    ACMD6_INIT_check  <= '0';
    CMD6_INIT_4_check <= '0';
    CMD25_INIT_4_check  <= '0';
    CMD12_INIT_check    <= '0';
    CMD12_INIT_ABORT_check  <= '0';
    CMD13_INIT_MULTI_4_check  <= '0';
    CMD13_INIT_TIMEOUT_REC_check  <= '0';



  elsif rising_edge(clk) then

    if ( start_error = '1' and command_send_done = '1') then
      start_error <= '0';
    end if;

   case current_state is

      when CMD7_INIT =>
        if (CMD7_INIT_check = '0') then
          start_error <= '1';
          CMD7_INIT_check <= '1';
        end if;
      when CMD55_INIT_ACMD6  =>
        if (CMD55_INIT_ACMD6_check = '0') then
          start_error <= '1';
          CMD55_INIT_ACMD6_check <= '1';
        end if;
      when ACMD6_INIT  =>
        if (ACMD6_INIT_check = '0') then
          start_error <= '1';
          ACMD6_INIT_check <= '1';
        end if;
      when CMD6_INIT_4  =>
        if (CMD6_INIT_4_check = '0') then
          start_error <= '1';
          CMD6_INIT_4_check <= '1';
        end if;
      when CMD25_INIT_4  =>
        if (CMD25_INIT_4_check = '0') then
          start_error <= '1';
          CMD25_INIT_4_check <= '1';
        end if;
      when CMD12_INIT  =>
        if (CMD12_INIT_check = '0') then
          start_error <= '1';
          CMD12_INIT_check <= '1';
        end if;
      when CMD12_INIT_ABORT  =>
        if (CMD12_INIT_ABORT_check = '0') then
          start_error <= '1';
          CMD12_INIT_ABORT_check <= '1';
        end if;
      when CMD13_INIT_MULTI_4  =>
        if (CMD13_INIT_MULTI_4_check = '0') then
          start_error <= '1';
          CMD13_INIT_MULTI_4_check <= '1';
        end if;
      when CMD13_INIT_TIMEOUT_REC  =>
        if (CMD13_INIT_TIMEOUT_REC_check = '0') then
          start_error <= '1';
          CMD13_INIT_TIMEOUT_REC_check <= '1';
        end if;


      when others =>

    end case;
  end if;
end process cmd_error_check;



end generate use_debug;













end Behavioral;

