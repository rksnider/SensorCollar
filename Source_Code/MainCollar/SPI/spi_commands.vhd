------------------------------------------------------------------------------
----
----! @file       spi_commands.vhd
----! @brief      SPI addressed command abstraction
----!             Send a command/address/payload onto an SPI slave. 
----!             
----! @details   
----! @copyright  
----! @author     Chris Casebeer
----! @version    
----!@date       1_13_2015
----!@copyright
----
----This program is free software : you can redistribute it and / or modify
----it under the terms of the GNU General Public License as published by
----the Free Software Foundation, either version 3 of the License, or
----(at your option) any later version.
----
----This program is distributed in the hope that it will be useful,
----but WITHOUT ANY WARRANTY; without even the implied warranty of
----MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
----GNU General Public License for more details.
----
----You should have received a copy of the GNU General Public License
----along with this program.If not, see <http://www.gnu.org/licenses/>.
----
----Chris Casebeer
----Electrical and Computer Engineering
----Montana State University
----610 Cobleigh Hall
----Bozeman, MT 59717
----christopher.casebee1@msu.montana.edu
----
------------------------------------------------------------------------------
------------------------------------------------------------------------------

------------------------------------------------------------------------------
--
--! @brief      An SPI addressed command abstraction
--! @details    
--!   
--! @param      command_used_g        Use a command with the abstraction. 
--! @param      address_used_g        Use an address with the abstraction.  
--! @param      command_width_bytes_g       The width of the command in bytes. Must be >=1;  
--! @param      address_width_bytes_g       The width of the address in bytes. Must be >=1;  
--!                                         If no address is used, this must be set to 0.
--! @param      data_length_bit_width_g     The bit width of the data_length_in
--!                                         port. Allows greater payload lengths.      
--! @param      cpol_cpha             Target a 00 or 11 implementation of SPI. Default is 00.    
--!
--! @param      clk                   System clock which drives entity. This is also your SPI clock speed.
--! @param      rst_n                 Active Low reset to reset entity 
--! @param      command_in            Command to send to spi slave.
--! @param      address_in            Address to send after command if addressed. 
--! @param      address_en_in         Enable the use of an address with the command. 
--! @param      data_length_in        The length of the payload in bytes(write/read)
--!                                   which will come after command/address
--!                                      
--! @param      master_slave_data_in            Initial payload byte or next payload byte to send over SPI.
--!                                             This data is sampled by the entity on
--!                                             master_slave_data_rdy_in. A new piece of payload data
--!                                             can only be accepted by the entity upon 
--!                                             master_slave_data_ack_out going high.
--! @param      master_slave_data_rdy_in        Indicate that a new initial command set is ready or a new
--!                                             data payload byte is ready. 
--!                                             This should be a pulse of spi_commands clk width. 
--!                                             This is easily done if spi_commands
--!                                             from the same clk as the input clk to spi_commands.
--!                                             Must be pulsed with input clk width. Spi_commands relies on this signal
--!                                             going low between data payload bytes. 
--!                                            
--!                                                 
--! @param      master_slave_data_ack_out   The entity can accept another payload byte upon
--!                                         this line going high (RISING EDGE). User should then
--!                                         signal a new payload byte with a rdy_in pulse. 
--!                                         This line is map of spi_abstract's mosi_data_ack_o.
--!                                         However, due to the command nature of spi_command, 
--!                                         master_slave_data_ack_out only goes high (more data accepted to be accepted)
--!                                         after the command/address/beginning of first data byte have been moved. 
--! @param      command_busy_out            The spi command abstraction is busy
--!                                         servicing a command. Do not attempt
--!                                         to send another command. If this is '0'
--!                                         the entity is ready to send another command.
--!                                         Cannot be checked before one clock period of input clock.
--! @param      command_done                Command done pulse.
--!
--! @param      slave_master_data_out       The MISO byte is valid  
--! @param      slave_master_data_ack_out   A payload associated byte has been 
--!                                         received back from the slave. Sample
--!                                         slave_master_data_out now.    
--!                                         This is a relay of the spi_abstract signal 
--!                                         miso_data_valid_o. However in this implementation
--!                                         it is only relayed upon completion of command/address
--!                                         portion of the SPI data set. 
--!                                         
--! @param      miso       MISO line from device  
--! @param      mosi       MOSI line to device   
--! @param      sclk       SCLK line to device   
--! @param      cs_n       CS_N line to device   
--
------------------------------------------------------------------------------

-- Usage instructions and Description:

-- SPI is a interchip device bus which is used to send data back and forth
-- between two devices. Data is synchronous to a clock (sclk) which the 
-- master supplies to the slave. Data is sent from the master to the slave
-- on the MOSI line. Data is sent back to the master on the MISO line. 
-- All data is valid on the rising edge of sclk. The chip select line
-- can be used to select specific slaves given a shared bus. In a single slave
-- scenario is simply starts or ends a communication.

-- A command is sent to the spi slave by loading 
-- command_in,address_in,address_en_in,data_length_in,master_slave_data_in and then
-- pulsing master_slave_data_rdy_in for one clock period of CLK.
-- The abstraction will process this amount of data over the SPI bus. It will
-- then drive master_slave_data_ack_out high to signal that another 
-- byte of the payload should be sent to the entity. This is when the
-- user of the entity should update master_slave_data_in and pulse 
-- master_slave_data_rdy_in. The total number of master_slave_data_rdy_in's pulses 
-- sent to the entity should match exactly the data_length_in on the first master_slave_data_rdy.
-- This is because the first byte of payload is associated with the first master_slave_data_rdy

-- For every data section byte sent to the slave device, 
-- a byte is received back from the SPI slave over the MISO line. 
-- This byte is loaded into slave_master_data_out and indicated
-- valid by a pulse on slave_master_data_ack_out. 
-- The data should be taken at this time if of interest. 


--To read data from a device we must continually sent 00's over the MOSI line. 
--This keeps the abstraction clocking data from the device (keeping cs_n and the 
--clock on). This means that master_slave_data_ack_out must be responded to
--and master_slave_data_rdy_in pulsed appropriately to keep the abstraction ON.

--If a command or address are to be omitted such as in the case
--of the SPI bus functioning as a register transfer between devices, 
--the generics command_used_g and address_used_g can be set to 0. This
--will make the abstraction ignore the command/address ports and send
--the first data byte and subsequent payload bytes. The first byte
--sent to the slave in this instance will have an associated slave_master_data_ack_out.

--In the instance of addressed commands, the first slave_master_data_ack_out
--signal will be associated with the first data byte of payload sent out on MOSI. 

--slave_master_data_ack_out is a conditional map of spi_abstract's,
--miso_data_valid_o. 

--Received bytes are only signalled ready at slave_master_data_ack_out
--that are associated with the sent data portion bytes of the master.
--Thus bytes received back by master when the master is sending out
--command or address sections of the payload are not relayed up. This is
--because in most instances these bytes are not used by the host.

--If the first byte sent to the slave does have an associated response byte
--simply disable command and address portions of the payload by setting generics
--to zero and setting address_en_in to 0 when sending the data. 

--slave_master_data_ack_out is a conditional map of spi_abstract's,
--miso_data_valid_o. 

--TODO:
--Make the command_used and address_used into entity port signals instead of generics.
--If this was done, the slave_master_data_ack_out_en could then be
--dynamically moved depending on what kind of command/address/data combo
--is needed to be sent out. Currently this is statically compiled.

--Possibly allow master_slave_data_rdy_in to function without pulsing. 
--This might be helpful in reading where static MOSI data is being sent.

--Allow command to be turned off and on without generic. 
--Or simply just remove generics all together and rely on ports. 

--Allow a pathway for address without a command. 


--GOTCHAS:
--Do not strobe master_slave_data_rdy_in and then immediately strobe it
--again with another command set a cycle later. The second command set will
--be lost. 
--Wait for the command_busy_out to go high and then lower before attempting
--to load another command set. The alternative is to pause for a clock cycle
--and then recheck command_busy_out for sending another command set.

--SPI_COMMANDS is checking its input signals in clocked processes running at clk_in speed.
--This means that excercising spi_commands from a faster clock domain will possibly fail.
--It can be done, but the normal pulse durations must be of spi_command's clk duration. 

--Make sure that the data_length_bit_width_g is large enough to hold
--the data payload size you will load into spi_commands on the data_length_in
--port. Bad things happen if the port size cannot handle the numeric you 
--pass into spi_commands.
--An example. data_length_bit_width_g set at 10 will not handle a 
--1025 length data size. Change the generic to 11. 



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity spi_commands is
  generic(

  command_used_g        : std_logic := '1';
  address_used_g        : std_logic := '1';
  command_width_bytes_g : natural := 1;
  address_width_bytes_g : natural := 1;
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
end spi_commands;

architecture Behavioral of spi_commands is


component spi_abstract is
 generic (
      cpol_cpha : std_logic_vector(1 downto 0) := "11"
 );
	port(
      clk	  :in	std_logic;	
		  rst_n 	    :in	std_logic;	

      mosi_data_i         : in std_logic_vector(7 downto 0);
      miso_data_o         : out std_logic_vector(7 downto 0);
      mosi_data_valid_i 	:in	std_logic;	
      mosi_data_ack_o 	  :out	std_logic;	
      miso_data_valid_o 	:out	std_logic;	
      
		  miso 				:in	std_logic;	
      mosi 				:out  std_logic;	
      sclk 				:out  std_logic;	
      cs_n 				:out  std_logic
		 
		);
end component;
						

    type SPI_STATE is   (
    SPI_STATE_WAIT,
    SPI_STATE_COMMAND,
    SPI_STATE_ADDRESS,
    SPI_STATE_DATA_INITIAL,
    SPI_STATE_DATA,
    SPI_STATE_COMMAND_DONE,
    SPI_STATE_COMMAND_DONE_SIGNAL
    );
    
    
    
  signal cur_spi_state  : SPI_STATE;

  --Registers that store the data presented to the entity on the first
  --master_slave_data_rdy_in
  

  signal command_signal : std_logic_vector(command_width_bytes_g*8-1 downto 0);
  signal address_signal : std_logic_vector(address_width_bytes_g*8-1 downto 0);

  signal address_en_signal :std_logic;
  signal data_signal :std_logic_vector(7 downto 0);
  signal data_length_signal  : unsigned(data_length_bit_width_g - 1 downto 0);
  
  

  --Signals used to interact with the spi_abstract entity.

  signal mosi_data_valid_spi : std_logic;
  signal mosi_data_ack_spi : std_logic;
  signal mosi_data_ack_spi_follower : std_logic;
  signal miso_data_valid_spi : std_logic;
  --Do not assign reset signals to signals which serve only as
  --mapping. They should be reset only at the most base entity. 
  signal miso_data_spi : std_logic_vector(7 downto 0);
  signal mosi_data_spi : std_logic_vector(7 downto 0);
  

  signal byte_count : unsigned (data_length_bit_width_g- 1 downto 0);
  signal byte_number : unsigned (data_length_bit_width_g- 1 downto 0);
  
  --Signals used to only relay slave_master_data_ack's related to the 
  --data payload.
  signal miso_byte_ack_count : unsigned (7 downto 0);
  signal slave_master_data_ack_out_en : std_logic;
  
  --Readable cs_n.
  signal cs_n_signal : std_logic;
  signal cs_n_signal_follower : std_logic;
  
  begin
  

  slave_master_data_out <= miso_data_spi;
  cs_n <= cs_n_signal;
  

  spi_slave: spi_abstract
  generic map(
      cpol_cpha => cpol_cpha
  )
	port map(
      clk	    => clk,
		  rst_n 	      => rst_n,

      mosi_data_i    =>  mosi_data_spi,
      miso_data_o    => miso_data_spi,
      mosi_data_valid_i  => mosi_data_valid_spi,
      mosi_data_ack_o 	  => mosi_data_ack_spi,
      miso_data_valid_o  => miso_data_valid_spi,

		  miso 				=> miso,
      mosi 				=> mosi,
      sclk 				=> sclk,
      cs_n 				=> cs_n_signal
		 
		);

----------------------------------------------------------------------------
--
--! @brief    Send a command/address/data to the SPI slave using SPI_ABSTRACT
--!          
--! @details  This state machine effectively samples the input lines on a rdy_in
--!           pulse. It then sends this data to spi_abstract, waiting for rdy for
--!           more data signals appropriately. The state machine also decides if
--!           command/address are present and behaves accordingly. The state machine
--!           also tracks the number of payload bytes sent, so as to stop spi_abstract
--!           appropriately. 
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------
    
  
spi_command_state_machine:  process (clk, rst_n)
begin
  if rst_n = '0' then

  command_signal <= (others => '0');
  address_signal <= (others => '0');
  address_en_signal <= '0';
  data_signal <= (others => '0');
  data_length_signal  <= (others => '0');
  mosi_data_valid_spi <= '0';


  mosi_data_spi <= (others => '0');
  mosi_data_ack_spi_follower <= '0';
  master_slave_data_ack_out <= '0';
  
  
  cur_spi_state <= SPI_STATE_WAIT;
  
  cs_n_signal_follower <= '1';
  
 
  elsif clk'event and clk = '1' then

  mosi_data_valid_spi <= '0';
  master_slave_data_ack_out <= '0';
  
    case cur_spi_state is

    
    when SPI_STATE_WAIT          =>
      --Reset this follower to detect the first instance of a 
      --data_i_ack positive level.
      mosi_data_ack_spi_follower <= '0';
      if (command_used_g = '1') then
        if (master_slave_data_rdy_in = '1') then

          command_signal <= command_in;
          address_signal <= address_in;
          data_signal <= master_slave_data_in;
          address_en_signal <= address_en_in;
          data_length_signal <= unsigned(data_length_in);
          cur_spi_state <=     SPI_STATE_COMMAND;
          byte_count <= to_unsigned(0,byte_count'length);
          byte_number <= to_unsigned(command_width_bytes_g,byte_number'length);

        end if;
      else
        if (master_slave_data_rdy_in = '1') then
          cur_spi_state <= SPI_STATE_DATA_INITIAL;
          
          command_signal <= command_in;
          address_signal <= address_in;
          data_signal <= master_slave_data_in;
          address_en_signal <= address_en_in;
          data_length_signal <= unsigned(data_length_in);
          --SPI_STATE_DATA_INITIAL requires a byte_count of one.
          byte_count <= to_unsigned(0,byte_count'length);
          byte_number <= to_unsigned(1,byte_count'length);
        end if;
      end if;
      

    when SPI_STATE_COMMAND   =>

      if (byte_count = byte_number) then
          if (address_used_g = '1') then
            if(address_en_in = '1') then
                cur_spi_state <= SPI_STATE_ADDRESS;
                byte_count <= to_unsigned(0,byte_count'length);
                byte_number <= to_unsigned(address_width_bytes_g,byte_number'length);
            elsif(address_en_in = '0' and data_length_signal = to_unsigned(0,data_length_signal'length)) then
                cur_spi_state <= SPI_STATE_COMMAND_DONE;
                --Address 0 and various amt of data.k
            else
                byte_count  <=   to_unsigned(0,byte_count'length);
                byte_number <=  to_unsigned(1,byte_count'length);
                cur_spi_state <= SPI_STATE_DATA_INITIAL;
            end if;
          else
            if (data_length_signal = to_unsigned(0,data_length_signal'length)) then
             cur_spi_state <= SPI_STATE_COMMAND_DONE;
            else
            byte_count  <=   to_unsigned(0,byte_count'length);
            byte_number <=   to_unsigned(1,byte_count'length);
            cur_spi_state <= SPI_STATE_DATA_INITIAL;
            end if;

          end if;
      
      elsif (mosi_data_ack_spi_follower /= mosi_data_ack_spi) then
       
        mosi_data_ack_spi_follower <= mosi_data_ack_spi;
          if ( mosi_data_ack_spi = '1') then
               mosi_data_valid_spi <= '1';
               --Shift out the command section over SPI.
               mosi_data_spi <= command_signal(command_signal'length -1 downto command_signal'length -8);
               
               command_signal (command_signal'length-1 downto 0) <=
               command_signal (command_signal'length-8-1 downto 0) & x"00";
               
               byte_count <= byte_count + 1;
          end if;
      else
          mosi_data_valid_spi <= '0';
      end if;
       
    when SPI_STATE_ADDRESS   =>
    
      if (byte_count = byte_number) then
        if (data_length_signal = to_unsigned(0,data_length_signal'length)) then
          cur_spi_state <= SPI_STATE_COMMAND_DONE;
        else
          cur_spi_state <= SPI_STATE_DATA_INITIAL;
          byte_count <= to_unsigned(0,byte_count'length);
          byte_number <= to_unsigned(1,byte_count'length);
        end if;

      elsif (mosi_data_ack_spi_follower /= mosi_data_ack_spi) then
              mosi_data_ack_spi_follower <= mosi_data_ack_spi;
              if ( mosi_data_ack_spi = '1') then
                 mosi_data_valid_spi <= '1';
                 
                 mosi_data_spi <= address_signal(address_signal'length-1 downto address_signal'length -8);
                 
                 
                 address_signal (address_signal'length-1 downto 0) <=
                 address_signal (address_signal'length-8-1 downto 0) & x"00";
                 
                 byte_count <= byte_count + 1;
              end if;

      else
      mosi_data_valid_spi <= '0';
            

      end if;
      

    when SPI_STATE_DATA_INITIAL   =>
     
     if (byte_count = byte_number) then
        cur_spi_state <= SPI_STATE_DATA;
        byte_number <= data_length_signal;
      
      elsif (mosi_data_ack_spi_follower /= mosi_data_ack_spi) then
          mosi_data_ack_spi_follower <= mosi_data_ack_spi;
            if ( mosi_data_ack_spi = '1') then
            mosi_data_valid_spi <= '1';
            mosi_data_spi <= data_signal;
            byte_count <= byte_count + 1;
            end if;
             
      else
      mosi_data_valid_spi <= '0';
      end if;

    when SPI_STATE_DATA   =>  

      if (byte_count = byte_number) then
        cur_spi_state <= SPI_STATE_COMMAND_DONE;
      else        
      --Relay mosi_data_ack_spi to upper entity. It must 
      --decide to send data in relation to the ack_out signal.
        master_slave_data_ack_out <= mosi_data_ack_spi;
        if (master_slave_data_rdy_in = '1') then
            mosi_data_spi <= master_slave_data_in;
            mosi_data_valid_spi <= '1';
            byte_count <= byte_count + 1;
        else
            mosi_data_valid_spi <= '0';
        end if;
      end if;
      
      --Allow csn to come back up after a full command
      --CSN comes back after spi_abstract is left without any new data.
      --This is necessary between commands. 
      when SPI_STATE_COMMAND_DONE   =>      
        if (cs_n_signal_follower /= cs_n_signal) then
        cs_n_signal_follower <= cs_n_signal;
          if (cs_n_signal = '1') then
          cur_spi_state <= SPI_STATE_COMMAND_DONE_SIGNAL;
          end if;
        end if; 
        
        
        
      when SPI_STATE_COMMAND_DONE_SIGNAL   => 
        cur_spi_state <= SPI_STATE_WAIT;
        
        
      end case ;
  end if ;
end process spi_command_state_machine ;

----------------------------------------------------------------------------
--
--! @brief    Output logic of the main state machine.
--!          
--! @details  As of right now, command_busy is associated with every state, 
--!           except wait state.
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------

spi_state_output:  process (cur_spi_state)
begin

--Default values
command_busy_out <= '1';
command_done <= '0';
  
case cur_spi_state is

  when SPI_STATE_WAIT =>
  command_busy_out <= '0';
  when SPI_STATE_COMMAND =>
  when SPI_STATE_ADDRESS =>
  when SPI_STATE_DATA_INITIAL =>
  when SPI_STATE_DATA =>
  when SPI_STATE_COMMAND_DONE => 
  when SPI_STATE_COMMAND_DONE_SIGNAL =>
  command_done <= '1';

 
end case;

end process spi_state_output ;

----------------------------------------------------------------------------
--
--! @brief    Associate miso_data_acks with payload portion of command stream.
--!          
--! @details  This process is responsible for only passing the slave_master_data_ack_out's
--!           which are associated with the payload/data bytes of the command stream. In general the data received
--!           back on miso during command/address send out are not used by the host.
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------


slave_master_data_out_handler : process(clk,rst_n)
begin
if rst_n = '0' then
  miso_byte_ack_count <= to_unsigned(0,miso_byte_ack_count'length);
  slave_master_data_ack_out_en <= '0';
  slave_master_data_ack_out <= '0';
elsif rising_edge(clk) then

    if (cur_spi_state = SPI_STATE_WAIT) then
    miso_byte_ack_count <= to_unsigned(0,miso_byte_ack_count'length);
    slave_master_data_ack_out_en <= '0';
    elsif ( miso_data_valid_spi = '1') then
    miso_byte_ack_count <= miso_byte_ack_count + 1;
    end if;


  if(command_used_g = '1' and address_used_g = '1') then
    if ( miso_byte_ack_count = to_unsigned(command_width_bytes_g + address_width_bytes_g,miso_byte_ack_count'length)) then
      slave_master_data_ack_out_en <= '1';
    end if;
  elsif(command_used_g = '1' and address_used_g = '0') then
   if ( miso_byte_ack_count = to_unsigned(command_width_bytes_g,miso_byte_ack_count'length)) then
      slave_master_data_ack_out_en <= '1';
    end if;
  end if;
  
  --Strictly speaking there isn't a pathway for an address used 
  --without a command. 
  if(command_used_g = '0' and address_used_g = '0') then
    slave_master_data_ack_out_en <= '1';
  end if;
  
  if (slave_master_data_ack_out_en = '1') then
  slave_master_data_ack_out <= miso_data_valid_spi; 
  end if;

   
end if;
end process slave_master_data_out_handler;


	
end Behavioral;