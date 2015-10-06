----------------------------------------------------------------------------
--
--! @file       magmem_controller.vhd
--! @brief      Magnetic Memory Controller
--! @details    Maintains and flushes FPGA buffer to teh Magnetic Memory
--! @author     Chris Casebeer
--! @date       1_13_2015
--! @copyright  
--
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
--  Chris Casebeer
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  christopher.casebee1@msu.montana.edu
--
----------------------------------------------------------------------------

------------------------------------------------------------------------------
--
--! @brief      Magnetic Memory Update and Startup Fetch State Machine.
--! @details    
--!   
--! @param      mag_interval_ms_g     The millisecond interval at which magnetic
--!                                   memory should be updated. Must be a power
--!                                   of 2.  Reduce for simulation. 
--! @param      tRDP_sleep_mode_exit_time_us     Time waited in us by the controller
--!                                   after a wake command is sent to the magmem.
--!                                   Reduce for simulation.              
--! @param      buffer_bytes_g        The total number of bytes in the 2 port
--!                                   ram which is copied to the magnetic 
--!                                   memory. This is used to determine
--!                                   address sizes.     
--! @param      buffer_num_g          The number of buffers within the
--!                                   buffer_bytes_g. This is used to generate
--!                                   inner buffer addresses.    
--! @param      command_used_g        SPI_COMMANDS_GENERIC
--! @param      address_used_g        SPI_COMMANDS_GENERIC
--!                                     
--! @param      command_width_bytes_g SPI_COMMANDS_GENERIC
--! @param      address_width_bytes_g SPI_COMMANDS_GENERIC
--! @param      data_length_bit_width_g SPI_COMMANDS_GENERIC
--!
--!
--!          
--!
--! @param      clk                   System clock which drives entity. 
--! @param      rst_n                 Active Low reset to reset entity 

--! @param      startup               '1' causes state machine to fetch data from 
--!                                   magnetic memory and store it to the 2 port
--!                                   ram      
--! @param      startup_finished      The startup fetch has finished.
--! @param      mag_ram_clk_a         Clock provided to buffer side A. System Facing.                     
--! @param      mag_ram_wr_en_a       wr_en A of dual port ram. System Facing.
                         
--! @param      mag_ram_rd_en_a       rd_en A of dual port ram. System Facing.
--! @param      mag_ram_address_a     address A of dual port ram. System Facing.
--!                                                 
--! @param      mag_ram_data_a        data port A of dual port ram. System Facing.
--!                                   Use of this port will require memory request
--!                                   and grant.      
--! 
--! @param      mem_req_a_out         Request access to the A side of the dual
--!                                   port ram.
--! @param      mem_rec_a_in          Access is granted to the A side of the dual
--!                                   port ram. 
--! @param      ram_mag_q_b           Data output of the B side of dual port ram.
--!                                   magmem_controller facing.
--!                                        
--! @param      ram_mag_data_b        Data in of the B side of dual port ram. 
--!                                   magmem_controller facing.
--! @param      mag_ram_rd_en_b       rd_en B of dual port ram.  magmem_controller facing   
--! @param      mag_ram_wr_en_b       wr_en B of dual port ram.  magmem_controller facing  
--! @param      mag_ram_address_b     address B of dual port ram. magmem_controller facing 

--!                                        
--! @param      miso       MISO line from device  
--! @param      mosi       MOSI line to device   
--! @param      sclk       SCLK line to device   
--! @param      cs_n       CS_N line to device   
--!
--! @param      fpga_time   fpga time since rest. Used for magnetic memory
--!                         update interval. 
--! @param      current_active_ram_buffer This indicates the currently active
--!                                       buffer of the 2 port ram. This is the buffer
--!                                       to which system devices should be writing.
--!                                       This pointer is managed by magmem_controller 
--!                                       as is only altered whem magmem_controller
--!                                       has acquired access to Port A of memory.  
--
------------------------------------------------------------------------------

--Usage Instructions and Description.

-- The magmem controller does two primary things. It either reads or writes to
-- magnetic memory using the SPI bus. Magmem_controller uses the spi_commands
-- entity to push commands/addresses/data to the magnetic memory controller.
-- The primary state machine can flow through a series of states to read a 512 byte
-- buffer off the magnetic memory or copy a buffer existing in a dual port ram 
-- onto the magnetic memory. 

-- Data which will end up on magnetic memory is stored in a 2 port ram. Various
-- devices update fields in an active buffer of the ram from the A side. Magmem_controller
-- can then use the B side of the 2 port ram to copy contents to the magnetic memory. 

-- The two port ram stores a number of buffers. Generics specify the number of buffers
-- and their sizes in this 2 port ram. The idea is that the system devices write important
-- information that should be saved to the magnetic memory into parts of this 2 port ram.
-- A system level package will define areas to which the devices will write. Flashblock 
-- could also be responsible for writing so of this information.

-- At a certain interval specified by mag_interval_ms_g, the magmem_controller
-- state machine will start and copy one of the 2 port ram buffer to the other. 
-- Magmem_controller does this by requesting access to the A side system facing
-- ports of the ram. The B side is the side that magmem_controller has exclusive control over.
-- Magmem_controller then streams the data from one buffer out of side B and 
-- writes it to the other buffer on side A.
-- Upon copying the buffers, the new active buffer is updated. This is the buffer 
-- which the system will now write to. This is enacted by passing out the active
-- buffer address (upper address bits) out the entity for use by the system level 
-- 2 port ram and the resource mux. 

-- Magmem_controller now issues a write command to the magnetic memory and streams
-- a buffer worth of bytes to the magnetic memory over the SPI bus and the MOSI line.
-- Upon finishing the stream, magnetic memory controller issues a sleep command to conserve 
-- power. It then waits for the next mag_interval_ms_g number of milliseconds. 

-- magmem_controller in its current state is generically specified to handle 2 
-- 512 byte buffers in the 2 port ram. However through use of generics of the entity
-- and constants of the architecture, these can be easily changed. The entity
-- has been coded in hopes that many buffers of a different size from 512 bytes
-- could be used. 


-- Magmem_controller is also capable of receiving a startup request and copying
-- the last written buffer existing in the magnetic memory to the first buffer
-- of the dual port ram. This is done with a read command issued to the
-- magnetic memory controller, followed by streaming the MISO bytes received
-- into the first position of the 2 port ram using the b side of that ram.
-- Upon completion of this full buffer read and write into the 2 port ram,
-- magmem signals startup_finished.

--Investigations of the populated magnetic memory on the powerboard devmonitor
--has shown that the write_protect line is not needed to write to the
--magnetic memory. Also of note is that the chip select line should remain 
--high whenever the chip is on and not being communicated with. The act of
--lowering the chip select line increases current consumption by 20x+.




library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.




LIBRARY GENERAL ;     
USE GENERAL.GPS_Clock_pkg.ALL;  



entity magmem_controller is

  Generic (
  
  clk_freq_g            :natural  := 50E6;
  mag_interval_ms_g     : natural := 2;
  tRDP_sleep_mode_exit_time_us : natural := 2; --Nominally 400.

  buffer_bytes_g        : natural := 1024;
  buffer_num_g          : natural := 2;

  command_used_g        : std_logic := '1';
  address_used_g        : std_logic := '1';
  command_width_bytes_g : natural := 1;
  address_width_bytes_g : natural := 3;
  data_length_bit_width_g : natural := 10
  

  ) ;
  Port (
    clk               : in  std_logic ;
    rst_n             : in  std_logic ;
    

    startup           : in  std_logic;    
    startup_finished  : out std_logic;  
    mag_ram_clk_a     : out std_logic;
    mag_ram_wr_en_a   : out std_logic;  
    mag_ram_rd_en_a   : out std_logic;  
    mag_ram_address_a : out std_logic_vector(natural(trunc(log2(real(buffer_bytes_g-1)))) downto 0);
    mag_ram_data_a    : out std_logic_vector(7 downto 0);
    
    mem_req_a_out     : out std_logic;  
    mem_rec_a_in      : in std_logic;  
     
    ram_mag_q_b       : in std_logic_vector(7 downto 0);
    ram_mag_data_b    : out std_logic_vector(7 downto 0);
    mag_ram_clk_b     : out std_logic;
    mag_ram_rd_en_b   : out std_logic;  
    mag_ram_wr_en_b   : out std_logic;  
    mag_ram_address_b : out std_logic_vector(natural(trunc(log2(real(buffer_bytes_g-1)))) downto 0);
    
    miso 			        : in std_logic;  
    mosi 			        : out std_logic;  
    sclk 			        : out std_logic;  
    cs_n 			        : out std_logic;
    
    fpga_time        : in  std_logic_vector(gps_time_bits_c-1 downto 0);
    current_active_ram_buffer : out   std_logic_vector(natural(trunc(log2(real(
                                  buffer_num_g-1)))) downto 0)

  ) ;

end entity magmem_controller ;



architecture behavior of magmem_controller is


    type MAG_WRITE is   (
    MAG_STATE_WAIT,
    MAG_STATE_MEM_LOCK,
    MAG_STATE_COPY_SETUP,
    MAG_STATE_COPY,
    MAG_STATE_COPY_END,
    MAG_STATE_WRITE_WR_EN,
    MAG_STATE_WRITE_SETUP,
    MAG_STATE_WRITE_COMMAND,
    MAG_STATE_WRITE_PAYLOAD,
    MAG_STATE_WRITE_LOC,
    MAG_STATE_STARTUP_LOC_SETUP,
    MAG_STATE_STARTUP_LOC_READ,
    MAG_STATE_STARTUP_READ_SETUP,
    MAG_STATE_STARTUP_READ,
    MAG_STATE_WAKE,
    MAG_STATE_WAKE_WAIT,
    MAG_STATE_SLEEP,
    MAG_STATE_PAUSE
    );
    


  signal cur_mag_state   : MAG_WRITE;
  signal next_mag_state  : MAG_WRITE; 
  
  
  
  
  
  
  --Characterize the Mag Mem Programming Interface
  --EVERSPIN Magnetic Memory Specific Constants
  
  constant  WRITE_INSTRUCTION   : std_logic_vector  := x"02";
  constant  READ_INSTRUCTION    : std_logic_vector  := x"03";
  constant  WRSR_INSTRUCTION    : std_logic_vector  := x"01";
  constant  RDSR_INSTRUCTION    : std_logic_vector  := x"05";
  constant  WREN_INSTRUCTION    : std_logic_vector  := x"06";
  
  constant  SLEEP_INSTRUCTION   : std_logic_vector  := x"B9";
  constant  WAKE_INSTRUCTION    : std_logic_vector  := x"AB";


  --I could programatically find the minimum size needed to hold counter
  --An optimization saved for later.
  signal tRDP_cycle_count : natural ; 
  

  
  signal startup_en : std_logic;
  signal startup_follower : std_logic;
  
  signal  startup_processed : std_logic;
  signal  startup_processed_follower : std_logic;
  

-- Addressing used on the two sides of the ram buffer.
-- Calculate the address signals for the two sides of ram
-- Separate them into buffer selections and inner buffer addressing.

  constant BUFFER_WIDTH_BYTES   : natural := 1;

    signal inner_buffer_addr_a    :  unsigned(natural(trunc(log2(real(
                                  (buffer_bytes_g/buffer_num_g)
                                  /BUFFER_WIDTH_BYTES-1)))) downto 0); 
                                  
                 
    signal buffer_sel_addr_a    :  unsigned(natural(trunc(log2(real(
                                  buffer_num_g-1)))) downto 0); 
                

    signal inner_buffer_addr_b    :  unsigned(natural(trunc(log2(real(
                                  (buffer_bytes_g/buffer_num_g)
                                  /BUFFER_WIDTH_BYTES-1)))) downto 0); 
                                  
   
                      
    signal buffer_sel_addr_b    :  unsigned(natural(trunc(log2(real(
                                  buffer_num_g-1)))) downto 0); 
                                  

                                  

                                  
                                  
    --Which buffer is active?
    --The non_active_buffer is the one which the magmem_controller 
    --reads data out of. 
    signal active_buffer : unsigned(buffer_sel_addr_a' length - 1 downto 0);
    signal not_active_buffer  : unsigned(buffer_sel_addr_a' length - 1 downto 0);
    
    --This is the byte location in magnentic memory where the last current buffer
    --number is stored. This is read on startup.
    constant VALID_BUFFER_MEM_LOC : natural := 1024;
    --Magnetic Memory Buffer Structure. 
    constant MAG_BUFFER_BYTES  : natural := 512;
    constant MAG_BUFFER_SHIFT : natural := natural(log2(real(512)));
    constant MAG_BUFFER_NUM : natural := 2;
    constant MAG_BUFFER_WIDTH : natural := 1;
    
  signal    mag_mem_address   :  unsigned(natural(trunc(log2(real(
                                  (MAG_BUFFER_BYTES)
                                  /MAG_BUFFER_WIDTH-1)))) downto 0); 
                                  
  --Since we are using the SPI interface of the magnetic memory, the
  --upper bits are coded to fill the rest of the SPI address width.
  signal    active_mag_buffer : unsigned(natural(trunc(log2(real(MAG_BUFFER_NUM-1)))) downto 0);
--The location of the startup_buffer on magnetic memory from which we will start reading
--on startup. This signal is filled after reading VALID_BUFFER_MEM_LOC on the magnetic memory.
  signal    startup_mag_buffer : unsigned(natural(trunc(log2(real(
                                  (MAG_BUFFER_NUM)-1)))) downto 0);

    
  --Intermediate port mapping signals of the spi_commands entity. These are
  --how I interact with that entity. 
  signal    command_spi_signal    :   std_logic_vector(command_width_bytes_g*8-1 downto 0);
  signal    address_spi_signal     :  std_logic_vector(address_width_bytes_g*8-1 downto 0);
  signal    address_en_spi_signal   : std_logic;
  signal    data_length_spi_signal  : std_logic_vector(data_length_bit_width_g - 1 downto 0);
  signal    master_slave_data_spi_signal : std_logic_vector(7 downto 0);
  signal    master_slave_data_rdy_spi_signal :  std_logic;
  signal    master_slave_data_ack_spi_signal : std_logic;
  signal    master_slave_data_ack_spi_signal_follower : std_logic;
  signal    command_busy_spi_signal:   std_logic;
  signal    slave_master_data_spi_signal :std_logic_vector(7 downto 0);
  signal    slave_master_data_ack_spi_signal :std_logic;
  
  
  --GPS_TIME record type allows enabling magmem_controller at specific
  --time intervals. 
  signal fpga_time_record : GPS_TIME;
  signal fpga_ms_bit : std_logic;
  signal fpga_ms_bit_follower : std_logic;
  

    
  

  --Byte counts related to transferring bytes. Either 2port to 2port
  --or 2 port to magnetic memory.
  signal byte_count : unsigned (data_length_bit_width_g-1 downto 0);
  signal byte_number : unsigned (data_length_bit_width_g-1 downto 0);
  --Counts used to keep track of read bytes off MISO.
  signal byte_read_count  : unsigned (data_length_bit_width_g-1 downto 0);
  signal byte_read_number : unsigned (data_length_bit_width_g-1 downto 0);
  

  
  
  --Signal state machine to start writing ram to magnetic memory.
  signal mag_update : std_logic;
  signal update_processed_follower : std_logic;
  signal update_processed : std_logic;
  --Buffer signals
  --Output signals can't be read directly. 
  
  signal mag_ram_rd_en_b_signal : std_logic;
  signal cs_n_siganl            : std_logic;
  
  --Startup_Finished Output Buffer
  signal startup_finished_out : std_logic;

component spi_commands is
 generic(

  command_used_g        : std_logic := '1';
  address_used_g        : std_logic := '1';
  command_width_bytes_g : natural := 1;
  address_width_bytes_g : natural := 3;
  data_length_bit_width_g : natural := 10;
  cpol_cpha             : std_logic_vector(1 downto 0) := "00"
  
);
	port(
      clk	            :in	std_logic;	
		  rst_n 	        :in	std_logic;
      
      command_in      : in  std_logic_vector(command_width_bytes_g*8-1 downto 0);
      address_in      : in  std_logic_vector(address_width_bytes_g*8-1 downto 0);
      address_en_in   : in  std_logic;
      data_length_in  : in  std_logic_vector(data_length_bit_width_g - 1 downto 0);
      
      master_slave_data_in      :in   std_logic_vector(7 downto 0);
      master_slave_data_rdy_in  :in   std_logic;
      master_slave_data_ack_out :out  std_logic;
      command_busy_out          :out  std_logic;
      command_done              :out  std_logic;

      slave_master_data_out     : out std_logic_vector(7 downto 0);
      slave_master_data_ack_out : out std_logic;

      miso 				:in	  std_logic;	
      mosi 				:out  std_logic;	
      sclk 				:out  std_logic;	
      cs_n 				:out  std_logic
		 
		);
end component;


begin



spi_commands_slave : spi_commands 

  generic map (
  command_used_g        => command_used_g,
  address_used_g        => address_used_g,
  command_width_bytes_g => command_width_bytes_g,
  address_width_bytes_g => address_width_bytes_g,
  data_length_bit_width_g => data_length_bit_width_g
  )
	port map(
    clk	            => clk,
    rst_n 	        => rst_n,

    command_in      => command_spi_signal, 
    address_in      =>  address_spi_signal, 
    address_en_in   => address_en_spi_signal,
    data_length_in  => data_length_spi_signal,
    
    master_slave_data_in    =>  master_slave_data_spi_signal,   
    master_slave_data_rdy_in =>   master_slave_data_rdy_spi_signal,
    master_slave_data_ack_out =>  master_slave_data_ack_spi_signal,
    command_busy_out => command_busy_spi_signal,
    --command_done =>
    slave_master_data_out => slave_master_data_spi_signal,
    slave_master_data_ack_out => slave_master_data_ack_spi_signal,

    miso 				  => miso,
    mosi 					=> mosi,
    sclk 					=> sclk,
    cs_n 					=> cs_n_siganl
		 
		);


mag_ram_clk_a     <= not clk;
mag_ram_clk_b     <= not clk;
mag_ram_address_a <=  std_logic_vector(buffer_sel_addr_a) & std_logic_vector(inner_buffer_addr_a);
mag_ram_address_b <=  std_logic_vector(buffer_sel_addr_b) & std_logic_vector(inner_buffer_addr_b);

  --Buffer signals
  --Output signals can't be read directly. 
mag_ram_rd_en_b <= mag_ram_rd_en_b_signal;
cs_n            <= cs_n_siganl;

--Take FPGA_TIME input to ms bit of interest for mag_update toggle. 

fpga_time_record <= TO_GPS_TIME(fpga_time);

--Here we pick out the correct bit of fpga_time_record to serve as the 
--milisecond toggle of interest, mag_interval_ms_g

--fpga_ms_bit <= fpga_time_record.millisecond_nanosecond(natural(trunc(log2(real(mag_interval_ms_g)))));

--This is the original design. However it triggers too slowly for testbench use. 
fpga_ms_bit <= fpga_time_record.week_millisecond(natural(trunc(log2(real(mag_interval_ms_g)))));

--The only data I will ever send to mag_ram_data_a is the output of mag_ram_q_b.
--This happens when I copy one buffer to the other using both ports. 
mag_ram_data_a <= ram_mag_q_b;

--Push the active buffer out the entity for concatenation at the address of Port A.
current_active_ram_buffer <= std_logic_vector(active_buffer);

startup_finished <= startup_finished_out;



----------------------------------------------------------------------------
--
--! @brief    Send buffer to magnetic memory or execute a copy to 2 port ram from 
--!           magnetic memory on startup
--!          
--! @details  Master state machine which handles copy of magram_buffer
--!           to magnetic memory after locking that ram. The state machine
--!           uses spi_commands entity to communicate with the spi magnetic memory. 
--!           The state machine also handles startup, where the last buffer
--!           written to the magnetic memory is copied back into the 2 port ram.
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------


mag_state_machine:  process (clk, rst_n)
begin
  if rst_n = '0' then
  
    active_buffer       <= to_unsigned(0,active_buffer'length);
    not_active_buffer   <= to_unsigned(1,active_buffer'length);
    cur_mag_state       <= MAG_STATE_WAIT ;
    inner_buffer_addr_a <= to_unsigned(0,inner_buffer_addr_b'length);
    inner_buffer_addr_b <= to_unsigned(0,inner_buffer_addr_b'length);
    mag_ram_wr_en_a     <= '0';

    
    active_mag_buffer <= to_unsigned(0,active_mag_buffer' length);
    mag_mem_address <= to_unsigned(0,mag_mem_address' length);

    
    byte_number <= to_unsigned(0,byte_number'length);
    byte_count <= to_unsigned(0,byte_count'length);
    
    
    buffer_sel_addr_a <= to_unsigned(0,buffer_sel_addr_a'length);
    buffer_sel_addr_b <= to_unsigned(0,buffer_sel_addr_b'length);
    
    
    
    command_spi_signal   <= (others => '0');
    address_spi_signal     <= (others => '0');
    address_en_spi_signal  <= '0';
    data_length_spi_signal  <= (others => '0');

    master_slave_data_spi_signal  <= (others => '0');

    master_slave_data_rdy_spi_signal <= '0';
    master_slave_data_ack_spi_signal_follower <= '0';
  
    startup_processed <= '0';
    startup_finished_out  <= '0';
    
    update_processed <= '0';
    
    
    --DEBUG RESET
    --tRDP_cycle_count <= clk_freq_g/1E6 * tRDP_sleep_mode_exit_time_us - 10;
    --DEBUG RESET
    tRDP_cycle_count <= 0;
 
  elsif clk'event and clk = '1' then

  
  --Default signal states.
  master_slave_data_rdy_spi_signal <= '0';
  
  if (startup_processed = '1' and startup_processed_follower = '1') then
    startup_processed <= '0';
  end if;
  
  if (update_processed = '1' and update_processed_follower = '1') then
    update_processed <= '0';
  end if;
  
  

    case cur_mag_state is

    
      
      when MAG_STATE_WAIT   =>

        --Keep the follower in sync during the wait state. 
        master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
        if (mag_update = '1' and startup_finished_out = '1') then
          cur_mag_state  <=   MAG_STATE_WAKE;
          next_mag_state <=   MAG_STATE_MEM_LOCK;
        elsif (startup_en = '1') then
          cur_mag_state  <=  MAG_STATE_WAKE;
          next_mag_state <=     MAG_STATE_STARTUP_LOC_SETUP;
        end if;
        
        
        
      when MAG_STATE_WAKE   =>

        if (command_busy_spi_signal = '0') then
          command_spi_signal <= WAKE_INSTRUCTION;
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(0,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";
          master_slave_data_rdy_spi_signal <= '1';
          cur_mag_state <= MAG_STATE_WAKE_WAIT;
        end if;
        
      when MAG_STATE_WAKE_WAIT =>
      --This check on cs_n captures a couple cn_n '1's before the command 
      --is sent. For pristine working, this should be fixed. 
      if ( cs_n_siganl = '1') then
        if (tRDP_cycle_count = clk_freq_g/1E6 * tRDP_sleep_mode_exit_time_us) then
          cur_mag_state <= next_mag_state;
          --DEBUG RESET
          --tRDP_cycle_count <= clk_freq_g/1E6 * tRDP_sleep_mode_exit_time_us - 10;
          --DEBUG RESET
          tRDP_cycle_count <= 0;
        else
          tRDP_cycle_count <= tRDP_cycle_count + 1;
        end if;
      end if;
      

        
        

      when MAG_STATE_MEM_LOCK   =>
      --We have memory. Copy buffer.
      --mem_req_a set by output logic process.
      if (mem_rec_a_in = '1') then
       cur_mag_state <= MAG_STATE_COPY_SETUP;
      end if;


      when MAG_STATE_COPY_SETUP    =>


      inner_buffer_addr_a <= to_unsigned(0,inner_buffer_addr_a'length);
      inner_buffer_addr_b <= to_unsigned(0,inner_buffer_addr_b'length);
      cur_mag_state <= MAG_STATE_COPY;
      
      buffer_sel_addr_b <= active_buffer;
      buffer_sel_addr_a <= not_active_buffer;


      --Now write one buffer of 2 port ram into the other using both 
      --ports of the ram.
      when MAG_STATE_COPY     =>

      mag_ram_wr_en_a <= mag_ram_rd_en_b_signal;
      inner_buffer_addr_a <= inner_buffer_addr_b;
      
      if(inner_buffer_addr_b /= (buffer_bytes_g/buffer_num_g - 1)) then
        inner_buffer_addr_b <= inner_buffer_addr_b + 1;
      else
        cur_mag_state <= MAG_STATE_COPY_END;
      end if;



      when MAG_STATE_COPY_END =>
      mag_ram_wr_en_a <= mag_ram_rd_en_b_signal;
      active_buffer <= not_active_buffer;
      not_active_buffer <= active_buffer;
      cur_mag_state <= MAG_STATE_WRITE_SETUP;
      
      mag_mem_address <= to_unsigned(0,mag_mem_address' length);
      

      when MAG_STATE_WRITE_SETUP =>
        --The magmem address only needs first position, after that
        --it is a stream write. 
      buffer_sel_addr_b <= not_active_buffer;

      inner_buffer_addr_b <= to_unsigned(0,inner_buffer_addr_b'length);
      byte_count <= to_unsigned(0,byte_count'length);
      byte_number <= to_unsigned(MAG_BUFFER_BYTES,byte_number'length);
      cur_mag_state <= MAG_STATE_WRITE_COMMAND;
      

      when MAG_STATE_WRITE_COMMAND =>
     

        if (command_busy_spi_signal = '0') then
          command_spi_signal <= WRITE_INSTRUCTION;
          address_spi_signal <= std_logic_vector(resize(active_mag_buffer,address_width_bytes_g*8 - mag_mem_address'length))
          & std_logic_vector(mag_mem_address);
          address_en_spi_signal <= '1';
          data_length_spi_signal <= std_logic_vector(to_unsigned(MAG_BUFFER_BYTES,data_length_spi_signal'length));
          master_slave_data_spi_signal <= ram_mag_q_b;
          inner_buffer_addr_b <= inner_buffer_addr_b + 1;
          master_slave_data_rdy_spi_signal <= '1';
          byte_count <= byte_count + 1;
          cur_mag_state <= MAG_STATE_WRITE_PAYLOAD;
        end if;
        
       
        
      when MAG_STATE_WRITE_PAYLOAD =>
      
       if (byte_count = byte_number) then
        cur_mag_state <= MAG_STATE_WRITE_LOC;

        
       elsif (master_slave_data_ack_spi_signal_follower /= master_slave_data_ack_spi_signal) then
       master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
              if(master_slave_data_ack_spi_signal = '1') then
              inner_buffer_addr_b <= inner_buffer_addr_b + 1;
              master_slave_data_spi_signal <= ram_mag_q_b;
              byte_count <= byte_count + 1;
              master_slave_data_rdy_spi_signal <= '1';
              end if;
      else
        master_slave_data_rdy_spi_signal <= '0';
      end if;
      

      when MAG_STATE_WRITE_LOC =>
      

          if (command_busy_spi_signal = '0') then
            command_spi_signal <= WRITE_INSTRUCTION;
            address_spi_signal <= std_logic_vector(to_unsigned(VALID_BUFFER_MEM_LOC,address_spi_signal'length));
            address_en_spi_signal <= '1';
            --The buffer we just read from.
            data_length_spi_signal <= std_logic_vector(to_unsigned(1,data_length_spi_signal'length));
            master_slave_data_spi_signal <= std_logic_vector(resize(active_mag_buffer,master_slave_data_spi_signal'length));
            
            master_slave_data_rdy_spi_signal <= '1';
            --Here I wait one cycle for command_busy_spi_signal to 
            --go high.
            cur_mag_state <= MAG_STATE_PAUSE;
            next_mag_state <= MAG_STATE_SLEEP ;
            active_mag_buffer <= active_mag_buffer + 1;
            update_processed <= '1'; 
          end if;

      
      
      
      when MAG_STATE_STARTUP_LOC_SETUP =>
      startup_processed <= '1';
        if (command_busy_spi_signal = '0') then
          command_spi_signal <= READ_INSTRUCTION;
          address_spi_signal <= std_logic_vector(to_unsigned(VALID_BUFFER_MEM_LOC,address_spi_signal'length));
          address_en_spi_signal <= '1';
          data_length_spi_signal <= std_logic_vector(to_unsigned(1,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";
          
          master_slave_data_rdy_spi_signal <= '1';
          cur_mag_state <= MAG_STATE_STARTUP_LOC_READ;
          
          
          byte_read_count   <= to_unsigned(0,byte_count'length);
          byte_read_number  <= to_unsigned(1,byte_number'length);
          
        end if;
      

      when MAG_STATE_STARTUP_LOC_READ =>
      if (master_slave_data_ack_spi_signal_follower /= master_slave_data_ack_spi_signal) then
      master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
              --Push x00 to the spi slave to receive the READ bytes back.
              if(master_slave_data_ack_spi_signal = '1') then
              master_slave_data_spi_signal <= x"00";
              master_slave_data_rdy_spi_signal <= '1';
              end if;
      else
      master_slave_data_rdy_spi_signal <= '0';
      end if;
        
        if (byte_read_count = byte_read_number) then
              startup_mag_buffer <= resize(unsigned(slave_master_data_spi_signal),startup_mag_buffer'length);
              cur_mag_state <= MAG_STATE_STARTUP_READ_SETUP;
        elsif(slave_master_data_ack_spi_signal = '1') then
              byte_read_count <= byte_read_count + 1;
        end if;
            
      
      
      
      when MAG_STATE_STARTUP_READ_SETUP =>
      byte_read_count <= to_unsigned(0,byte_count'length);
      byte_read_number <= to_unsigned(MAG_BUFFER_BYTES,byte_number'length);
      --Allows the first byte to go to the 0 address.
      --Address is incremented on first read byte. 
      inner_buffer_addr_b <= (others => '1');
      buffer_sel_addr_b   <= to_unsigned(0,buffer_sel_addr_b'length);
      
        if (command_busy_spi_signal = '0') then
          command_spi_signal <= READ_INSTRUCTION;
          --Shift the buffer number left to address correct address. 
          address_spi_signal <= std_logic_vector(shift_left(resize(startup_mag_buffer,address_spi_signal'length),MAG_BUFFER_SHIFT));
          address_en_spi_signal <= '1';
          data_length_spi_signal <= std_logic_vector(to_unsigned(MAG_BUFFER_BYTES,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";
          
          master_slave_data_rdy_spi_signal <= '1';
          cur_mag_state <= MAG_STATE_STARTUP_READ;
          
        end if;


      when MAG_STATE_STARTUP_READ =>

      
      if(byte_read_count = byte_read_number) then
      cur_mag_state <= MAG_STATE_WRITE_WR_EN;
      startup_finished_out  <= '1';
      elsif (slave_master_data_ack_spi_signal = '1') then
        ram_mag_data_b <= slave_master_data_spi_signal;
        byte_read_count <= byte_read_count + 1;
        inner_buffer_addr_b <= inner_buffer_addr_b + 1;
      end if;
      
      
      if (master_slave_data_ack_spi_signal_follower /= master_slave_data_ack_spi_signal) then
      master_slave_data_ack_spi_signal_follower <= master_slave_data_ack_spi_signal;
              --Push x00 to the spi slave to receive the READ bytes back.
              if(master_slave_data_ack_spi_signal = '1') then
              master_slave_data_spi_signal <= x"00";
              master_slave_data_rdy_spi_signal <= '1';
              end if;
      else
      master_slave_data_rdy_spi_signal <= '0';
      end if;
      
      when  MAG_STATE_WRITE_WR_EN => 
        if (command_busy_spi_signal = '0') then
          command_spi_signal <= WREN_INSTRUCTION;
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(0,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";
          master_slave_data_rdy_spi_signal <= '1';
          cur_mag_state <= MAG_STATE_SLEEP;
        end if;

      
      
      
      when MAG_STATE_SLEEP =>

        if (command_busy_spi_signal = '0') then
          command_spi_signal <= SLEEP_INSTRUCTION;
          address_en_spi_signal <= '0';
          data_length_spi_signal <= std_logic_vector(to_unsigned(0,data_length_spi_signal'length));
          master_slave_data_spi_signal <= x"00";
          master_slave_data_rdy_spi_signal <= '1';
          cur_mag_state <= MAG_STATE_WAIT;
        end if;
        
      when MAG_STATE_PAUSE =>

          cur_mag_state <= next_mag_state;

      end case ;
  end if ;
end process mag_state_machine ;


 ----------------------------------------------------------------------------
  --
  --! @brief    The output logic for the cur_mag_state state machine.
  --! @details  

  
  --! @param    clk       Take action on positive edge.
  --! @param    rst_n           rst_n to initial state.
  --!
  --!          
  ----------------------------------------------------------------------------

mag_write_output:  process (cur_mag_state)
begin
  
  mem_req_a_out <= '0';
  mag_ram_wr_en_b <= '0';
  mag_ram_rd_en_b_signal <= '0';
  mag_ram_rd_en_a <= '0';
  
case cur_mag_state is
  
    when MAG_STATE_WAIT =>
  
    when MAG_STATE_MEM_LOCK =>
    mem_req_a_out <= '1';
    
    when MAG_STATE_COPY_SETUP =>
    mem_req_a_out <= '1';
    when MAG_STATE_COPY =>
    mag_ram_rd_en_b_signal <= '1';
    mem_req_a_out <= '1';
        
    when MAG_STATE_COPY_END =>
    mem_req_a_out <= '1';
    
    when  MAG_STATE_WRITE_WR_EN => 
           
    when MAG_STATE_WRITE_SETUP =>
    mag_ram_rd_en_b_signal <= '1';
    
    when MAG_STATE_WRITE_COMMAND =>
    mag_ram_rd_en_b_signal <= '1';
    
    when MAG_STATE_WRITE_PAYLOAD =>
    mag_ram_rd_en_b_signal <= '1';
    
    when MAG_STATE_WRITE_LOC =>
    
    when MAG_STATE_STARTUP_LOC_SETUP =>
    
    when MAG_STATE_STARTUP_LOC_READ =>
    
    when MAG_STATE_STARTUP_READ_SETUP =>
    
    when MAG_STATE_STARTUP_READ =>
    mag_ram_wr_en_b <= '1';
    
    when MAG_STATE_WAKE =>
    when MAG_STATE_WAKE_WAIT =>
    when MAG_STATE_SLEEP =>
    when MAG_STATE_PAUSE =>

 
end case;



end process mag_write_output ;
  



    ----------------------------------------------------------------------------
  --
  --! @brief      Startup_en process
  --!             
  --! @details    Catch the startup_en line. Signal state machine to start.
  --!             De-assert the startup_en upon state machine starting. 
  --!           
  --!
  --! @param    clk       Take action on positive edge.
  --! @param    rst_n           rst_n to initial state.
  --
  ----------------------------------------------------------------------------

startup_catch: process (clk, rst_n)
begin
  if (rst_n = '0') then

  startup_processed_follower <= '0';
  startup_follower <= '0';
  startup_en <= '0';

  elsif (clk'event and clk = '1') then

    if (startup_follower /= startup) then
      startup_follower <= startup;

      if (startup = '1') then
      startup_en <= '1';
      end if;
        
    elsif(startup_processed_follower /= startup_processed) then
     startup_processed_follower <= startup_processed ;
      if (startup_processed = '1') then
          startup_en          <= '0' ;
      end if ;
        
    end if;
    
       

  end if ;
end process startup_catch ;
   ----------------------------------------------------------------------------
  --
  --! @brief    Signal that its time to update magnetic memory from the 2 port ram. 
  --! @details  Use the FPGA clock which is a ms/ns clk.
  --!           
  --! @param    clk       Take action on positive edge.
  --! @param    rst_n           rst_n to initial state.
  --
  ----------------------------------------------------------------------------
  time_out:  process (clk, rst_n)
  begin
    if (rst_n = '0') then
      mag_update <= '0';
      fpga_ms_bit_follower <= '0';

      update_processed_follower <= '0';
      
    elsif (clk'event and clk = '1') then

      if(fpga_ms_bit_follower /= fpga_ms_bit) then
        fpga_ms_bit_follower <= fpga_ms_bit;
        mag_update <= '1';
      elsif(update_processed_follower /= update_processed) then
        update_processed_follower <= update_processed ;
          if (update_processed = '1') then
            mag_update <= '0';
          end if;
      end if;

    end if ;
  end process time_out ;
  


end behavior ;
