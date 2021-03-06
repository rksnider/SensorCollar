---------------------------------
--
--! @file       $File$
--! @brief      Initialize and Control the TI CC1120 Transmitter 
--! @brief      (Adapted from code Written by Chris Casebeer)
--! @details    CC1120 TI Transmitter.
--! @copyright  
--! @author     Tyler B. Davis
--! @version    $Revision$

--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
--  Tyler B. Davis
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  tyler.davis5@msu.montana.edu
--
---------------------------------




---------------------------------
--
--! @brief      Initialize and Control the TI CC1120 Transmitter.
--! @details    
--!   

---------------------------------

--This piece of VHDL code is to be used with the following two matlab scripts.

-- Running these two scripts in the above order will generate an associated mif file



library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.


--A dual port ram is used.
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

LIBRARY GENERAL ;     
USE GENERAL.UTILITIES_PKG.ALL;          --  Use General Purpose Libraries
USE GENERAL.GPS_Clock_pkg.ALL;          --  Use GPS Clock information.

 ---------------------------------------------------------------------------
--
--!	@brief 	TI Transmitter initialization and control.
--! @details
--! @param		command_used_g        		SPI_COMMANDS_GENERIC
--! @param   	address_used_g        		SPI_COMMANDS_GENERIC
--!                                     
--! @param     command_width_bytes_g 		SPI_COMMANDS_GENERIC
--! @param     address_width_bytes_g 		SPI_COMMANDS_GENERIC
--! @param     data_length_bit_width_g 	SPI_COMMANDS_GENERIC
--!
--! @param 		clk            						System clock which drives the entity
--! @param		rst_n       						Active low reset to the reset entity
--!
--! @param 		startup_in 								'1' causes the state machine to load 
--!																			the registers
--! @param		startup_complete_out  		Signal to indicate the startup has 
--! 																		finished
--! @param		current_fpga_time_in     		Current time according to the FPGA
--!
--! @param		data_addr_in 							Data address to use when 
--!																			reading/writing the payload
--! @param		data_len_in    						Length of the payload to read from 
--! 																		memory
--! @param		op_complete_out						Bit to inidcate whether the 
--! 																		operation was completed	 
--! @param 		tx_req_in									Signal to start transmitting
--! @param 		rx_req_in									Signal to start listening
--! @param		sleep_req_in							Signal to put the chip to sleep
--! @param 		op_complete_out 					The TX/RX operation completed 
--!																			successfully
--! @param 		op_error_out 							THe TX/RX operation was unsuccessful
--! @param    spi_clk_out             	SCLK of the SPI interface.
--! @param    mosi_out             			MOSI.
--! @param    miso_out             			MISO.
--! @param    cs_n_out         					cs_n of the SPI interface. 
--!
--! @param	rx_rdy_in 							Interrupt when recieving a packet 
--! 																(Tie to the GPIO3 pin)

entity CC1120_top is

  Generic (
  -- Initialize constants relating to the device   
		command_used_g              : std_logic := '1';
		address_used_g              : std_logic := '0';
		command_width_bytes_g       : natural   := 1;
		address_width_bytes_g       : natural   := 1;
		data_length_bit_width_g     : natural   := 8;
		packet_length_bytes					: natural 	:= 30;
		status_start_g 							: natural   := 6;
		status_end_g 								: natural   := 4
  ) ;
  Port (
    clk                   : in    std_logic ;
    rst_n              		: in    std_logic ;
    startup_in            : in    std_logic;
    startup_complete_out  : out   std_logic;
    current_fpga_time_in  : in    std_logic_vector(gps_time_bytes_c*8-1 
																										downto 0);
		data_addr_in					: in 		std_logic_vector(7 downto 0);
		data_len_in    				: in  	std_logic_vector(data_length_bit_width_g-1 
																										downto 0);
    tx_req_in							: in 		std_logic;
		rx_req_in							: in 		std_logic;
		sleep_req_in					: in 		std_logic;
		op_complete_out   		: out 	std_logic; 
		op_error_out					: out 	std_logic;
    spi_clk_out           : out 	std_logic;
    mosi_out            	: out 	std_logic;
		miso_in            	  : in  	std_logic;
    cs_n_out            	: out 	std_logic;
    rx_time_out    				: out 	std_logic_vector (gps_time_bytes_c*8-1 
																										downto 0);
		rx_rdy_in 						: in 		std_logic
		
  ) ;

end entity CC1120_top ;


architecture behavior of CC1120_top is

	-- Define the states for the chips
  type TXRX_STATE is   (
	
	-- Waiting for something to happen
  TXRX_STATE_IDLE,
	
	-- Initialize the registers
	TXRX_STATE_INIT,
	TXRX_STATE_INIT_FETCH,
	TXRX_STATE_INIT_FETCH_NUM,
	TXRX_STATE_INIT_WRITE,
	TXRX_STATE_INIT_WAIT,
	TXRX_STATE_INIT_EXTENDED_WRITE,
	
	
	-- Power down when not active (flushes BOTH FIFOS)
	TXRX_STATE_SLEEP,
	
	-- Calibrate the device
	TXRX_STATE_CALIBRATE,
	
	-- Settling state
	TXRX_STATE_SETTLING,
	
	-- Fast action TX ready
	-- TXRX_STATE_FSTXON, 
    
	-- Transmit states
	TX_STATE_LOAD,
	TX_STATE_PUSH,
	TX_STATE_PUSH_WAIT,
	TX_STATE_DONE,
	TX_STATE_FIFO_ERROR,
	
	-- Recieve states
	RX_STATE_LISTEN,
	RX_STATE_FETCH,
	RX_STATE_FETCH_SETUP,
	RX_STATE_WRITE,
	RX_STATE_DONE,
  RX_STATE_FIFO_ERROR
	
  );
	
	-- Addresses where the number of registers to initialize is and the start 
	-- of the values
  constant txrx_initbuffer_num_loc_c : std_logic_vector(7 downto 0) := x"00";
	constant txrx_initbuffer_data_start_loc_c : std_logic_vector(7 downto 0) := x"01";
    
  -- Define the current state of the ship
  signal cur_txrx_state   : TXRX_STATE;
  
  -- Define the register size
  constant TXRX_INIT_REGISTER_SIZE 					: natural := 2;
	constant TXRX_INIT_EXTENDED_REGISTER_SIZE : natural := 3;
  
  -- Beginning of the FIFO registers for direct access
  constant tx_fifo_start_addr : std_logic_vector(7 downto 0) := x"3F";
  constant rx_fifo_start_addr : std_logic_vector(7 downto 0) := x"3F"; 
  
  -- Set the strobe address length for the command byte
  constant strobe_reg_len_c : natural := 6;
  
  -- Command addresses (Command strobes)
  constant tx_en          :   std_logic := '1';   		-- Transmission bit
  constant rx_en          :   std_logic := '0';				-- Recieve bit
		
	-- Reset the chip 0x30
  constant sres_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(48,strobe_reg_len_c)); 
  
	-- enable and cal freq synthesizer 0x31
	constant sfstxon_addr_c 
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(49,strobe_reg_len_c)); 
  
	-- enter xoff state 0x32
	constant sxoff_addr_c   
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(50,strobe_reg_len_c)); 
  
	-- Calibrate frequency synthesizer 0x33
	constant scal_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(51,strobe_reg_len_c)); 
  
	-- Enable RX 0x34
	constant srx_addr_c     
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(52,strobe_reg_len_c)); 
  
	-- Enable TX 0x35
	constant stx_addr_c     
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(53,strobe_reg_len_c)); 
  
	-- Exit TX/RX, deactivate freq synthesizer 0x36
	constant sidle_addr_c   
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(54,strobe_reg_len_c));   
 
  -- Automatic frequency compensation 0x37
	constant safc_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(55,strobe_reg_len_c)); 
		
  -- automatic RX polling  0x38
	constant swor_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(56,strobe_reg_len_c)); 
		
	-- Enter sleep mode (CS_N = 0) 0x39
	constant spwd_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(57,strobe_reg_len_c));
 
 -- Flush RX FIFO   0x3A
	constant sfrx_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(58,strobe_reg_len_c));
		
	-- Flush TX FIFO 0x3B
	constant sftx_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(59,strobe_reg_len_c)); 
  
	-- Reset the eWor timer 0x3C
	constant sworrst_addr_c 
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(60,strobe_reg_len_c)); 
	
	-- No operation (get status byte) 0x3D
	constant snop_addr_c    
		:  std_logic_vector (strobe_reg_len_c - 1 downto 0) 
		:= std_logic_vector(to_unsigned(61,strobe_reg_len_c));
		
	-- Define the state constants for the status bit
	constant IDLE  			: std_logic_vector(2 downto 0) := "000";
	constant RX        	: std_logic_vector(2 downto 0) := "001";
	constant TX        	: std_logic_vector(2 downto 0) := "010";
	constant FSTXON    	: std_logic_vector(2 downto 0) := "011";
	constant CALIBRATE  : std_logic_vector(2 downto 0) := "100";
	constant SETTLING  	: std_logic_vector(2 downto 0) := "101";
	constant RXFIFOERR 	: std_logic_vector(2 downto 0) := "110";
	constant TXFIFOERR 	: std_logic_vector(2 downto 0) := "111";
	
	-- Define the extended register space address
	constant EXT_REG_ADDR_c : std_logic_vector(6 downto 0) := "0101111";
		
--Signals for the one port init buffer.
  signal txrx_initbuffer_address_std : std_logic_vector(7 downto 0);
  signal txrx_initbuffer_address : unsigned(7 downto 0);
  signal txrx_initbuffer_rd_en : std_logic;
  signal txrx_initbuffer_wr_en : std_logic;
  signal txrx_initbuffer_q : std_logic_vector(23 downto 0);
  signal txrx_initbuffer_data : std_logic_vector(23 downto 0);
  signal dprspr_clk : std_logic;

  -- Signles to hold the sample data
  signal tx_data : std_logic_vector(packet_length_bytes*8-1 downto 0);
  signal rx_data : std_logic_vector(packet_length_bytes*8-1 downto 0);
	
	
	-- Memory access bits
	constant RD_EN_BIT : std_logic := '1';
  constant WR_EN_BIT : std_logic := '0';
	constant STDFIFO   : std_logic_vector (5 downto 0) := "111111";
	
	-- Burst bits
	constant BURST     : std_logic := '1';
	constant nBurst    : std_logic := '0';
    
	  --These numbers are stored as 16 bit values in memory.
  signal  txrx_init_number : unsigned (7 downto 0);
  signal  spi_commands_complete : unsigned( 7 downto 0);
	
	-- Interrupts for the TI chip
	signal rx_rdy_follower : std_logic;
	signal rx_req						: std_logic;
  signal rx_req_processed : std_logic;
  signal rx_req_processed_follower : std_logic;
  
  signal tx_rdy_follower : std_logic;
	signal tx_req					: std_logic;
  signal tx_processed : std_logic;
  signal tx_processed_follower : std_logic;
	
	signal op_error 		: 	std_logic;
	
	-- These signals delay the dpr r/w actions
	signal dpr_action : std_logic := '0';
	
	
	-- Create a signal to track whether a packet was transmitted
	signal loading_packet   : std_logic := '0';
	signal loaded_packet    : std_logic := '0';
	signal packet_byte_num  : natural   := 0;
	signal command_sent 		: std_logic := '0';
	
	-- Create signals for the dual-port RAM
	signal data_addr					: std_logic_vector(7 downto 0);
	signal data_read_en 			: std_logic := '0';
	signal data_write_en			: std_logic := '0';
	signal data_to 						: std_logic_vector(7 downto 0);
	signal data_from      		: std_logic_vector(7 downto 0);
  
  --Intermediate port mapping signals of the spi_commands entity.
  signal    command_spi_signal      : std_logic_vector(
																			command_width_bytes_g*8-1 downto 0);
  signal    address_spi_signal      : std_logic_vector(
																			address_width_bytes_g*8-1 downto 0);
  signal    address_en_spi_signal   : std_logic;
  signal    data_length_spi_signal  : std_logic_vector(
																			data_length_bit_width_g - 1 downto 0);
  signal    master_slave_data_spi_signal : std_logic_vector(7 downto 0);
  signal    master_slave_data_rdy_spi_signal :  std_logic;
  signal    master_slave_data_ack_spi_signal : std_logic;
  signal    master_slave_data_ack_spi_signal_follower : std_logic;
  signal    command_busy_spi_signal :   std_logic;
  signal    command_done_spi_signal :   std_logic;
  signal    command_done_spi_signal_follower :   std_logic;
  signal    slave_master_data_spi_signal :std_logic_vector(7 downto 0);
  signal    slave_master_data_ack_spi_signal :std_logic;
		
		
	--These signals
	signal miso_signal : std_logic;
	signal cs_n_signal : std_logic;
	
	-- Startup signals for the chip
	signal startup_en : std_logic;
	signal startup_follower : std_logic;
	
	-- Sleep signal for the chip
	signal sleep_en : std_logic;
	
	-- FIFO flushing signals
	signal tx_fifo_flush : std_logic;
	signal rx_fifo_flush : std_logic;
	  
	--Processed signals allow servicing the startup_in signal in.
	signal  txrx_processed : std_logic;
	signal  txrx_processed_follower : std_logic;
	
		--Processed signals allow servicing the startup_in signal in.
	signal  startup_processed : std_logic;
	signal  startup_processed_follower : std_logic;
	
	--Startup complete indicate that main state machine can begin
	--looking for interrupts. 
	signal  startup_complete : std_logic;
      
  --Byte counts related to transferring bytes. 
  signal byte_count : unsigned (data_length_bit_width_g-1 downto 0);
  signal byte_number : unsigned (data_length_bit_width_g-1 downto 0);
	
  --Counts used to keep track of read bytes off MISO.
  signal byte_read_count  : unsigned (data_length_bit_width_g-1 downto 0);
  signal byte_read_number : unsigned (data_length_bit_width_g-1 downto 0);
	
	-- Synchronization signals
	signal tx_sync  : std_logic; 
	signal rx_sync  : std_logic; 
	
	-- current fpga_time
	signal txrx_fpga_time : std_logic_vector (gps_time_bytes_c*8-1 downto 0);

      
  component spi_commands is
  generic(
  
		command_used_g        : std_logic := '1';
		address_used_g        : std_logic := '0';
		command_width_bytes_g : natural := 1;
		address_width_bytes_g : natural := 1;
		data_length_bit_width_g : natural := 10;
		cpol_cpha             : std_logic_vector(1 downto 0) := "00"
  
	);
	port(
    clk	            :in	std_logic;	
    rst_n 	        :in	std_logic;	

    command_in            : in  std_logic_vector(command_width_bytes_g*8-1 
																									downto 0);
    address_in            : in  std_logic_vector(address_width_bytes_g*8-1 
																									downto 0);
    address_en_in         : in  std_logic;
    data_length_in        : in  std_logic_vector(data_length_bit_width_g-1 
																									downto 0);   
    master_slave_data_in  : in std_logic_vector(7 downto 0);   
    master_slave_data_rdy_in  : in  std_logic;
    master_slave_data_ack_out :out  std_logic;
    command_busy_out      : out std_logic;
    command_done          : out std_logic;
    slave_master_data_out : out std_logic_vector(7 downto 0);
    slave_master_data_ack_out : out std_logic;

    miso 				:in	  std_logic;	
    mosi 				:out  std_logic;	
    sclk 				:out  std_logic;	
    cs_n 				:out  std_logic		 
		);
end component;

-- Create a dual-port RAM component to store and retrieve the packets
component CC1120_DPR is
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rden_a		: IN STD_LOGIC  := '1';
		rden_b		: IN STD_LOGIC  := '1';
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component CC1120_DPR;


begin

	-- Set the init address
	txrx_initbuffer_address_std <= std_logic_vector(txrx_initbuffer_address);
	
	-- Create an inverted clock to use when interacting with the DPR
	dprspr_clk <= not clk;

	-- initialize the startup_complete_out signal
	startup_complete_out <= startup_complete;
	
	spi_commands_cc1120 : spi_commands 

  generic map (
  command_used_g        => command_used_g,
  address_used_g        => address_used_g,
  command_width_bytes_g => command_width_bytes_g,
  address_width_bytes_g => address_width_bytes_g,
  data_length_bit_width_g => data_length_bit_width_g,
  cpol_cpha            => "00"
  )
	port map(
    clk	            => clk,
    rst_n 	        => rst_n,

    command_in      => command_spi_signal, 
    address_in      => address_spi_signal, 
    address_en_in   => address_en_spi_signal,
    data_length_in  => data_length_spi_signal,
    
    master_slave_data_in      =>  master_slave_data_spi_signal,   
    master_slave_data_rdy_in  =>  master_slave_data_rdy_spi_signal,
    master_slave_data_ack_out =>  master_slave_data_ack_spi_signal,
    command_busy_out          =>  command_busy_spi_signal,
    command_done              =>  command_done_spi_signal,
    slave_master_data_out     =>  slave_master_data_spi_signal,
    slave_master_data_ack_out =>  slave_master_data_ack_spi_signal,

    miso 				  => miso_signal,
    mosi 					=> mosi_out,
    sclk 					=> spi_clk_out,
    cs_n 					=> cs_n_signal
		 
		);
    
--This memory holds the non-default registers for the CC1120. These
--are set on startup_in. This memory is initialized with a mif file. 
 altsyncram_component : altsyncram
 GENERIC MAP (
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "CC1120_DEFAULT_MODE.mif",
		intended_device_family => "Cyclone V",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 256,
		operation_mode => "SINGLE_PORT",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		power_up_uninitialized => "FALSE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		widthad_a => 8,
		width_a => 24,
		width_byteena_a => 1
	)
	PORT MAP (
		address_a => txrx_initbuffer_address_std,
		clock0 => dprspr_clk,
		data_a => txrx_initbuffer_data,
		wren_a => txrx_initbuffer_wr_en,
		rden_a => txrx_initbuffer_rd_en,
		q_a => txrx_initbuffer_q
	);
	
	-- Port mapping for the dual-port RAM
	dpr_component : CC1120_DPR
	port map	(
		address_a		=> data_addr,
		clock_a			=> dprspr_clk,
		data_a			=> data_from,
		rden_a			=> data_read_en,
		wren_a			=> data_write_en,
		q_a					=> data_to,
		
		address_b 	=> (others => '0'),
		clock_b 		=> '0',
		rden_b			=> '0',
		wren_b			=> '0',
		data_b 			=> (others => '0')
		
	);


---------------------------------
--
--! @brief    Interact with the CC1120 transmitter. 
--!          
--! @details  Do the following things.
--!           Initialize the registers of the CC1120 which differ from default.
--!           Respond to TX and RX commands.
--!  
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
---------------------------------



CC1120_state_machine:  process (clk, rst_n)
begin
  if (rst_n = '0') then

		-- Set the r/w enable to 0
		txrx_initbuffer_wr_en <= '0';

    -- Reset the byte counts
		byte_count <= to_unsigned(0,byte_count'length);
		byte_number <= to_unsigned(0,byte_number'length);
				
		-- Reset the spi commands and interface signals
		command_spi_signal  <= (others => '0');
		master_slave_data_spi_signal  <= (others => '0');
		address_en_spi_signal <= '0';
		data_length_spi_signal  <= (others => '0');
		master_slave_data_rdy_spi_signal <= '0';
		
		-- reset the init number
		txrx_init_number  <= (others => '0');
				
		-- Reset the data arrays
		tx_data    <= (others => '0');
		rx_data    <= (others => '0');
		op_complete_out    <= '0';
		
		-- Reset the byte read count and number
		byte_read_count  <= to_unsigned(0,byte_count'length);
		byte_read_number <= to_unsigned(0,byte_number'length);
	 
	 -- Reset the startup_in processed variable
		startup_processed <= '0';
		
		-- Reset the buffer address and
		txrx_initbuffer_address  <= (others => '0');
		startup_complete <= '0';

		-- Reset command buffer
		command_done_spi_signal_follower <= '0';
 
		-- Strobe the FIFO flushes (first bit doesn't matter, second must be 0)
		if (tx_fifo_flush = '0' and command_busy_spi_signal = '0') then
			command_spi_signal <= BURST & nBURST & sftx_addr_c;
			address_en_spi_signal <= '0';
			tx_fifo_flush <= '1';
			
		elsif (rx_fifo_flush = '0' and command_busy_spi_signal = '0') then
			command_spi_signal <= BURST & nBURST & sfrx_addr_c;
			address_en_spi_signal <= '0';
			rx_fifo_flush <= '1';
			
		-- Set the current state to idle when the TX/RX FIFOs are flushed
		else
			cur_txrx_state <= TXRX_STATE_IDLE;
			tx_fifo_flush <= '0';
			rx_fifo_flush <= '0';
		end if;		
			 
 
  elsif (clk'event and clk = '1') then
  
	--Default signal states.
	master_slave_data_rdy_spi_signal <= '0';

  if (startup_processed = '1' and startup_processed_follower = '1') then
    startup_processed <= '0';
  end if;
  
  -- If the 
  if (txrx_processed = '1' and txrx_processed_follower = '1') then
    txrx_processed <= '0';
  end if;
		
	if (slave_master_data_spi_signal(status_start_g downto status_end_g) = 
				RXFIFOERR and rx_en = '1') then 
		cur_txrx_state <= RX_STATE_FIFO_ERROR;
	end if;
	
	if (slave_master_data_spi_signal(status_start_g downto status_end_g) = 
				TXFIFOERR and tx_en = '1') then 
		cur_txrx_state <= TX_STATE_FIFO_ERROR;
	end if;
	
  if (tx_req_in = '1') then
		tx_req <= '1';
	end if;

	if (rx_req_in = '1') then
		rx_req <= '1';
	end if;

	if (sleep_req_in = '1') then
		sleep_en <= '1';
	end if;
  
		-- FIXME: Condition on MISO status byte as well.
    case cur_txrx_state is

			-- Wake the chip when in sleep mode
      when TXRX_STATE_SLEEP          =>
				sleep_en <= '0';
				-- If the startup_in bit is flipped, change state, send command to 
				-- go to idle state (Calibration happens before TX or RX NOT idle)
				if (startup_en = '1') then
					cur_txrx_state  <=  TXRX_STATE_IDLE;
				end if;
				
				-- Idle state.  Wait for TX or RX commands
			when TXRX_STATE_IDLE		=>
				tx_req <='1';
			
			  if (startup_en = '1' and startup_complete = '0') then
					cur_txrx_state  <=  TXRX_STATE_INIT;
					txrx_initbuffer_rd_en <= '1';
				end if;
				
				if (op_error = '1') then 
					op_error_out <= '1';
					op_error <= '1';
					
				else
					op_error <= '0';
					op_error_out <= '0';
				end if;
				
			
				-- If the startup_in goes low, put the chip to sleep
				if (sleep_en = '1' and command_busy_spi_signal = '0') then 
						command_spi_signal <= BURST & nBURST & spwd_addr_c;
						address_en_spi_signal <= '0';
						data_length_spi_signal <= 
																				std_logic_vector(to_unsigned(
																					0,data_length_spi_signal'length));
						master_slave_data_rdy_spi_signal <= '1';
						cur_txrx_state <= TXRX_STATE_SLEEP;
		
				-- If the chip has started and is in idle, then check to see if 
				-- a TX or RX is suggested
				elsif (startup_complete = '1') then
					txrx_initbuffer_rd_en <= '0';
					-- If the TX or RX state is requested, change state and send the 
					-- calibrate command strobe
					if  ((rx_req = '1' or tx_req = '1') and 
								command_busy_spi_signal = '0') then
							command_spi_signal <= BURST & nBURST & scal_addr_c;
							address_en_spi_signal <= '0';
							data_length_spi_signal <= 
																			std_logic_vector(to_unsigned(
																				0,data_length_spi_signal'length));
							master_slave_data_rdy_spi_signal <= '1';
							cur_txrx_state  <=  TXRX_STATE_CALIBRATE;
					end if;
					
				end if;
				
				-- Load in the default registers
				when TXRX_STATE_INIT =>
					txrx_initbuffer_address <= unsigned(txrx_initbuffer_num_loc_c);
					cur_txrx_state <= TXRX_STATE_INIT_FETCH_NUM;
					--Startup_processed moved here to allow enough time for startup_en
					--to go low before IMU_STATE_WAIT checks it again. 
					startup_processed <= '1';
					
		    when TXRX_STATE_INIT_FETCH_NUM =>
    
					byte_count <= to_unsigned(0,byte_count'length);
					byte_number <= resize(unsigned(txrx_initbuffer_q),byte_number'length);
					
					--I only read 8 bits of data here from a 16 bit spot. I do this because
					--I use this number in addressing into a 256 spot ram and I do not need
					--bits 15 through 8. 
					txrx_init_number <= unsigned(txrx_initbuffer_q(7 downto 0));
					txrx_initbuffer_address <= unsigned(txrx_initbuffer_data_start_loc_c);
					cur_txrx_state <= TXRX_STATE_INIT_FETCH;
					
				when TXRX_STATE_INIT_FETCH =>
					if (byte_count = byte_number) then 
						startup_complete <= '1';
						cur_txrx_state <= TXRX_STATE_IDLE;
					else
						cur_txrx_state <= TXRX_STATE_INIT_WRITE;
					end if;
    
				when TXRX_STATE_INIT_WRITE =>
				
					if (command_busy_spi_signal = '0') then
							if (txrx_initbuffer_q(23 downto 16) = "00000000") then 
								command_spi_signal <= WR_EN_BIT & txrx_initbuffer_q(14 downto 8);
								master_slave_data_spi_signal <= txrx_initbuffer_q(7 downto 0);
								address_en_spi_signal <= '0';
								cur_txrx_state <= TXRX_STATE_INIT_WAIT;
								data_length_spi_signal <= std_logic_vector(to_unsigned(TXRX_INIT_REGISTER_SIZE-1,data_length_spi_signal'length));
								txrx_initbuffer_address <= txrx_initbuffer_address + 1;
								master_slave_data_rdy_spi_signal <= '1';
								byte_count <= byte_count + 1;

							else
								command_spi_signal <= WR_EN_BIT & EXT_REG_ADDR_c;
								master_slave_data_spi_signal <= txrx_initbuffer_q(15 downto 8);
								address_en_spi_signal <= '0';
								data_length_spi_signal <= std_logic_vector(to_unsigned(TXRX_INIT_EXTENDED_REGISTER_SIZE-1,data_length_spi_signal'length));
								txrx_initbuffer_address <= txrx_initbuffer_address + 1;
								master_slave_data_rdy_spi_signal <= '1';
								byte_count <= byte_count + 1;
								cur_txrx_state <= TXRX_STATE_INIT_EXTENDED_WRITE;
							end if;							
					end if;
				
				when TXRX_STATE_INIT_EXTENDED_WRITE =>
					if (slave_master_data_ack_spi_signal = '1') then
						master_slave_data_spi_signal <= txrx_initbuffer_q(7 downto 0);
						master_slave_data_rdy_spi_signal <= '1';
						cur_txrx_state <= TXRX_STATE_INIT_WAIT;

					end if;
				
				 when TXRX_STATE_INIT_WAIT =>
				
					--Wait for a register to complete going out before continuing. 
					--This is necessary for cs_n multiplexing.
					--This is necessary as no spi_command ack's come back for command only.
					--if (command_done_spi_signal_follower /= command_done_spi_signal) then
					--command_done_spi_signal_follower <= command_done_spi_signal;
					if(command_done_spi_signal = '1') then
						cur_txrx_state <= TXRX_STATE_INIT_FETCH;
					end if;
					
					
				-- Check to see if the frequency is calibrated, and if so, change 
				-- to the data pushing/fetching states
				when TXRX_STATE_CALIBRATE	=> 
				
					-- Check the recieved status byte
					-- conditional statement 
					data_addr <= data_addr_in;
					if (master_slave_data_spi_signal(
								status_start_g downto status_end_g) 
								= SETTLING) then 
						cur_txrx_state <= TXRX_STATE_SETTLING;
					else
						if (tx_req = '1') then
								cur_txrx_state  <=  TX_STATE_LOAD;
						end if;
						
						-- Check to see if the receive state is requested, if so strobe
						-- the rx command and switch to the listen state.
						if (rx_req = '1' and command_busy_spi_signal = '0') then
								command_spi_signal <= BURST & nBURST & srx_addr_c;
								address_en_spi_signal <= '0';
								cur_txrx_state  <=  RX_STATE_LISTEN;
						end if;
					end if;
					

				when TXRX_STATE_SETTLING =>
				
					-- Send noop command to get the status byte					
					if (command_busy_spi_signal = '0') then
								command_spi_signal <= BURST & nBURST & snop_addr_c;
								address_en_spi_signal <= '0';
								master_slave_data_rdy_spi_signal <= '1';
								data_length_spi_signal <= std_logic_vector(to_unsigned(
																					0,data_length_spi_signal'length));
					end if;
					
					-- Move on to the next mode
					if (tx_req = '1') then
						cur_txrx_state <= TX_STATE_LOAD;
						data_read_en <= '1';
						--cur_txrx_state <= RX_STATE_WRITE;
					end if;
					
						if (rx_req = '1') then
						cur_txrx_state <= RX_STATE_LISTEN;
						command_spi_signal <= BURST & nBURST & srx_addr_c;
						address_en_spi_signal <= '0';
						data_length_spi_signal <= std_logic_vector(to_unsigned(
																					0,data_length_spi_signal'length));
						master_slave_data_rdy_spi_signal <= '1';
					end if;
					
				when TX_STATE_LOAD =>
					
					if (byte_read_count = packet_length_bytes) then 
						cur_txrx_state <= TX_STATE_PUSH;
						data_read_en <= '0';
						byte_read_count <= to_unsigned(0,byte_count'length);
						dpr_action <= '0';
					elsif (dpr_action = '0') then 
						-- Pick out the next byte to read
						 tx_data(
							8*packet_length_bytes-to_integer(byte_read_count)*8-1 downto
							8*packet_length_bytes-(to_integer(byte_read_count) + 1)*8) 
								<= data_to ;
						byte_read_count <= byte_read_count + 1;
						dpr_action <= '1';
					else 
						dpr_action <= '0';
						data_addr <= std_logic_vector(unsigned(data_addr) + 1);
					end if;
				  
				-- Push all the data to the FIFO, then 
				when TX_STATE_PUSH =>
					-- Send the standard fifo strobe for filling the TX buffer, then 
					-- include the length of the packet immeidately afterward.
					if (command_busy_spi_signal = '0' and loading_packet = '0') then
						command_spi_signal <= WR_EN_BIT & BURST & STDFIFO;
						address_en_spi_signal <= '0';
						data_length_spi_signal <= 
							std_logic_vector(to_unsigned(packet_length_bytes,
																						data_length_spi_signal'length));
						master_slave_data_spi_signal <= tx_data(packet_length_bytes*8-1-packet_byte_num*8 
												downto (packet_length_bytes*8-(packet_byte_num + 1)*8));
						master_slave_data_rdy_spi_signal <= '1';
						cur_txrx_state <= TX_STATE_PUSH_WAIT;
						loading_packet <= '1';
						packet_byte_num <= packet_byte_num + 1;
					
					-- When the standard FIFO is 'active', only send data.
					else
										
						-- Load the data a byte at a time into the FIFO
						master_slave_data_spi_signal <= 
									tx_data((packet_length_bytes*8-1- packet_byte_num*8)
												downto (packet_length_bytes*8-(packet_byte_num+1)*8)); 
						master_slave_data_rdy_spi_signal <= '1';
						cur_txrx_state <= TX_STATE_PUSH_WAIT;
						packet_byte_num <= packet_byte_num + 1;
					end if;
			
			when TX_STATE_PUSH_WAIT =>			
					-- When the end of the data is written to RAM, switch states
					if (packet_length_bytes = packet_byte_num) then 
						loaded_packet <= '1';
						loading_packet <= '0';
						packet_byte_num <= 0;
						cur_txrx_state <= TX_STATE_DONE;
						byte_read_count <= to_unsigned(0,byte_count'length);
					elsif(slave_master_data_ack_spi_signal = '1') then
						cur_txrx_state <= TX_STATE_PUSH;						
					end if;
				
			when TX_STATE_DONE =>
					-- Send the transmitter back to the idle state 
					
				if (command_busy_spi_signal = '0' and command_sent = '0') then
							command_spi_signal <= BURST & nBURST & stx_addr_c;
							address_en_spi_signal <= '0';
							data_length_spi_signal <= 
																				std_logic_vector(to_unsigned(
																					0,data_length_spi_signal'length));
							master_slave_data_rdy_spi_signal <= '1';
							command_sent <= '1';
							loaded_packet <= '0';
				end if;
				if (tx_req = '0' and command_sent = '1') then 
					cur_txrx_state <= TXRX_STATE_IDLE;
					op_complete_out <= '0';
					command_sent <= '0';
				else 
					op_complete_out <= '1';
					tx_req <= '0';
				end if;
					
				
				when TX_STATE_FIFO_ERROR =>
					-- Flush the TX FIFO
					if (command_busy_spi_signal = '0') then
								command_spi_signal <= BURST & nBURST & sftx_addr_c;
								address_en_spi_signal <= '0';
								cur_txrx_state <= TXRX_STATE_IDLE;
								op_error <= '1';
					end if;

				when RX_STATE_LISTEN => 
					-- wait for the rx_rdy_in signal to go high
					if (rx_rdy_in = '1') then
						--cur_txrx_state <= RX_STATE_FETCH_SETUP;			
						cur_txrx_state <= RX_STATE_WRITE;
					end if;
					
				when RX_STATE_FETCH_SETUP =>
					byte_read_count  <= to_unsigned(0,byte_count'length);
      
					if (command_busy_spi_signal = '0') then
						command_spi_signal <= RD_EN_BIT & BURST & STDFIFO;
						address_en_spi_signal <= '0';
						data_length_spi_signal <= std_logic_vector(
																to_unsigned(packet_length_bytes,
																						data_length_spi_signal'length));
						master_slave_data_spi_signal <= x"00";
						master_slave_data_rdy_spi_signal <= '1';
						cur_txrx_state <= RX_STATE_FETCH;
					end if;
				
				when RX_STATE_FETCH => 
				  if(byte_read_count = packet_length_bytes) then
						cur_txrx_state <= RX_STATE_WRITE;
						byte_read_count <= to_unsigned(0,byte_count'length);
						rx_req_processed <= '1';
					elsif (slave_master_data_ack_spi_signal = '1') then
					--Little endian.
					 rx_data <= slave_master_data_spi_signal & rx_data(
																					packet_length_bytes*8-1 downto 8);
					 --Big endian.
						--gyro_sample <= gyro_sample(3*IMU_AXIS_WORD_LENGTH_BYTES*8-1-8 downto 0) & slave_master_data_spi_signal;
						byte_read_count <= byte_read_count + 1;
					end if;
					
					if (master_slave_data_ack_spi_signal_follower /= 
																		master_slave_data_ack_spi_signal) then
							master_slave_data_ack_spi_signal_follower <= 
							master_slave_data_ack_spi_signal;
							--Push x00 to the spi slave to receive the READ bytes back.
						if(master_slave_data_ack_spi_signal = '1') then
							master_slave_data_spi_signal <= x"00";
							master_slave_data_rdy_spi_signal <= '1';
						end if;
					else
					master_slave_data_rdy_spi_signal <= '0';
					end if;
					
				when RX_STATE_WRITE =>
					-- When the end of the data is written to RAM, switch states
					if (byte_read_count = packet_length_bytes) then 
						cur_txrx_state <= RX_STATE_DONE;
						--cur_txrx_state <= TX_STATE_LOAD;
						byte_read_count <= to_unsigned(0,byte_count'length);
						data_write_en <= '0';
						dpr_action <= '0';
					elsif(dpr_action = '0') then 
						-- Pick out the next byte to write
						data_from <= rx_data(packet_length_bytes*8-to_integer(byte_read_count)*8-1 downto
																 packet_length_bytes*8-(to_integer(byte_read_count)+1)*8);
						data_write_en <= '1';
						byte_read_count <= byte_read_count + 1;
						dpr_action <= '1';
						else 
							data_addr <= std_logic_vector(unsigned(data_addr) + 1);
							dpr_action <= '0';
					end if;
					
					
				when RX_STATE_DONE =>
					-- Just send the chip back to idle
					if (rx_req = '0') then 
						cur_txrx_state <= TXRX_STATE_IDLE;
						op_complete_out <= '0';
					else 
						op_complete_out <= '1';
						rx_req <= '0';
					end if;
				
				when RX_STATE_FIFO_ERROR =>
					-- Set the current state to idle when the TX/RX FIFOs are flushed
					if (command_busy_spi_signal = '0') then
								command_spi_signal <= BURST & nBURST & sfrx_addr_c;
								address_en_spi_signal <= '0';
								cur_txrx_state <= TXRX_STATE_IDLE;
								op_error <= '1';
								rx_req <= '0';
					end if;
				
      end case ;
  end if ;
end process CC1120_state_machine ;


---------------------------------
--!
--! @brief      data_rdy_catch
--!             
--! @details    Catch the data_rdy_interrupts coming from the IMU. 
--!             Log the fpga_time immediately. 
--!             Then signal state machine to read the appropriate data from IMU 
--!             over SPI.
--!           
--!
--! @param    clk       Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--!
---------------------------------

data_rdy_catch: process (clk, rst_n)
begin
  if rst_n = '0' then

		startup_processed_follower <= '0';
		startup_en <= '0';



  elsif clk'event and clk = '1' then
	
  --Synchronize asynch interrupts.

			if (startup_follower /= startup_in) then
				startup_follower <= startup_in;

				if (startup_in = '1' and startup_complete  = '0') then
					startup_en <= '1';
				end if;
					
			elsif(startup_processed_follower /= startup_processed) then
			 startup_processed_follower <= startup_processed ;
				if (startup_processed = '1') then
						startup_en          <= '0' ;
				end if ;
			end if;   
    end if;
		
		cs_n_out <= cs_n_signal ;
		
end process data_rdy_catch ;

end behavior ;