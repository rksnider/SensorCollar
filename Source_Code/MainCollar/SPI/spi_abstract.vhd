------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      SPI Bus Handler. Shifts and Receives data on the SPI bus.
--!             
--! @details   
--! @copyright  
--! @author     
--! @version    
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
--
--! @brief      An SPI abstraction. State machine which puts data on MOSI
--!             and receives data on MISO. A somewhat fancy serializer. 
--! @details     
--!
--! @param      clk         System clock which drives entity. 
--!                         The inverse of this clock is conditionally
--!                         put out on the sclk line. This allows SPI
--!                         at the frequency of the clk.
--! @param      rst_n             Reset to initial conditions.
--! @param      mosi_data_i            Byte to send to the SPI device
--! @param      miso_data_o            Byte received from the SPI device
--! @param      mosi_data_valid_i      Indication by user that data_i is valid.
--! @param      mosi_data_ack_o        '1' when more data can be accepted at data_i.
--!                                     Host should send and signal another byte upon '1', halt
--!                                     upon '0'    
--! @param      miso_data_valid_o      miso_data_o is valid. Sample it now. 
--!
--! @param      miso     Master Input Slave Output
--! @param      mosi     Master Output Slave Input
--! @param      sclk     SPI Clk
--! @param      cs_n     Chip Select

--
------------------------------------------------------------------------------

--Usage Instructions and Explanation.
--Byte data to send to the slave device over MOSI is put into mosi_data_i. 
--The data is marked valid with a '1' on mosi_data_valid_i.
--This data is sent out on the MOSI line. If another byte is to follower on the
--MOSI line (with cs_n remaining down), the mosi_data_ack_o should be read until it is '1'. At this point 
--the next byte should be put into mosi_data_i and signalled with mosi_data_valid_i.
--If another byte does not follow and mosi_data_valid_i is not pulsed, the state
--machine will stop, return to wait state, and the cs_n line will be returned high. 

--For every byte sent out on MOSI a MISO byte is read. These bytes are presented
-- at miso_data_o and are marked valid with '1' on miso_data_valid_o. 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity spi_abstract is
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
end spi_abstract;

architecture Behavioral of spi_abstract is


	--FSM Signals
	type		spi_state	is 
  (SPI_WAIT,
  SPI_CS,
  SPI_SHIFT,
  SPI_CSN
										 );
						
  signal cur_spi_state  : spi_state;

  --Data is read off MISO into this register.
  signal  read_shift          :std_logic_vector(7 downto 0);
  
  --Data is shifted out of these signals.
  --The next byte to be shifted after the current one is done
  --is stored in send_shift_next.
  signal  send_shift          :std_logic_vector(7 downto 0);
  signal  send_shift_next     :std_logic_vector(7 downto 0);
  
  --This signal allows us to only sample mosi_data_valid_i once per pulse.
  signal  mosi_data_valid_i_follower  : std_logic;

  
  --Signal that more data can be accepted and mosi_data_ack_o can be set high.
  signal  data_read  : std_logic;
  signal  data_read_follower  : std_logic;
  --Signal state machine that new data exists to be shifted.
  signal  new_data  : std_logic;
	
	--SD Card I/O signals

	signal	cs_n_signal					:std_logic;	
	signal	mosi_signal					:std_logic;	


  
  signal  rd_en : std_logic;
  signal  wr_en : std_logic;

  
  --Clk_off is the always on inverted clk signal.
  --Clk_off must be gated with sclk_en to produce sclk sent out 
  --of entity.
  signal  clk_off  : std_logic;
  signal  sclk_en : std_logic;
  --Put send_shift_next into send_shift.
  signal  reload : std_logic;
  
  --Track bits in byte.
  signal  bits_sent : unsigned(7 downto 0);
  

begin
			
	mosi <= mosi_signal;					
	cs_n <= cs_n_signal;			


----------------------------------------------------------------------------
--
--! @brief      Main state machine.
--!          
--! @details    State machine is comprised of wait, cs_n, shift and cs_n states.
--!             The bulk of the state machine occurs in shift where new data
--!             must be sensed, the shift register reloaded, and bit counts
--!             reset IF more data is to be sent. The state machine doesn't does
--!             all this single handedly, but signals some other support processes. 
--!              
--!           
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------  


	next_state : process(clk,rst_n)
begin
    if rst_n = '0' then
    cur_spi_state <= SPI_WAIT;
    miso_data_valid_o <= '0';
    data_read <= '0';
    reload <= '0';
          
    miso_data_o <= (others => '0');
    bits_sent <= (others => '0');

    elsif rising_edge(clk) then
        --Default values. 
          miso_data_valid_o <= '0';

          if (data_read_follower = '1' and  data_read ='1') then
            data_read <= '0';
          end if;

      case cur_spi_state is


        when SPI_WAIT =>
          if (new_data = '1') then 
            cur_spi_state <= SPI_CS;
            data_read <= '1';
            reload <= '1';
          end if;

          
        when SPI_CS =>
          reload <= '0';
        --Wait for reload to be done.
        if (reload = '0') then
              cur_spi_state <= SPI_SHIFT;
        end if;



        when SPI_SHIFT =>
        reload <= '0';
        bits_sent <= bits_sent + 1;
        --Here we sense for new data sent to the abstraction. If new data 
        --is sent in time, the next byte is seamlessly put out onto MOSI.
        --If data is not presented in time, the state machine stops
        --and cs_n is returned high. 
        --New data. Reload shift register.
          if (bits_sent = 6 and new_data = '1') then
            reload <= '1';
          
          elsif (bits_sent = 7 and new_data = '1') then 
            cur_spi_state <= SPI_SHIFT;
            data_read <= '1';

            miso_data_valid_o <= '1';
            miso_data_o <= read_shift;
            bits_sent <= to_unsigned(0,bits_sent'length);

          elsif (bits_sent = 7 and new_data = '0') then
            miso_data_valid_o <= '1';
            miso_data_o <= read_shift;
            cur_spi_state <= SPI_CSN;
            bits_sent <= to_unsigned(0,bits_sent'length);
          else
            cur_spi_state <= SPI_SHIFT;
          end if;
        
        
        when SPI_CSN =>
        reload <= '0';
        cur_spi_state <= SPI_WAIT;

      
      end case;
      end if;
   
	end process;
  

  
----------------------------------------------------------------------------
--
--! @brief      Main state machine output logic.
--!          
--! @details    Output logic enabling miso/mosi data shifting, cs_n on/off, and 
--!             gating sclk. 
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------

  --Interesting. Developing purely in Altera, one can put
  --changing values in output_logic, not so in Modelsim.
  --Thus changing logic should be moved into a clocked process. 
  
  
  output_logic : process(rst_n,cur_spi_state,send_shift)

begin

if rst_n = '0' then

  --Default values
  rd_en <= '0';
  wr_en <= '0';
  cs_n_signal <= '1';
  sclk_en <= '0';
  mosi_signal <= '0';
  
  else
  
  
    case cur_spi_state is

      when SPI_WAIT =>
      cs_n_signal <= '1';
      sclk_en <= '0'; 
      rd_en <= '0';
      wr_en <= '0';
      
      when SPI_CS =>
      sclk_en <= '0';
      cs_n_signal <= '0';
      rd_en <= '0';
      wr_en <= '0';

      when SPI_SHIFT =>
      mosi_signal <= send_shift(7);
      rd_en <= '1';
      wr_en <= '1';
      cs_n_signal <= '0';
      sclk_en <= '1';

      
      when SPI_CSN =>
      
      rd_en <= '0';
      wr_en <= '0';
      cs_n_signal <= '1';
      sclk_en <= '0'; 

      
		end case;
  end if;
    
	end process;
  
  --
  
  --A scheme used whereby clk is divided to generate sclk. 
  --This design was shelved as full clk (50Mhz) speed was needed. 
-- clk_ce_gen:	process(clk, rst_n)
-- begin
  -- if (rst_n = '0') then
  -- sclk_signal <= '0';
  -- sample_ce <= '0'; 
  -- send_ce <= '0';
  -- elsif rising_edge(clk) then
        -- --These enables are placed such that samples can be done on 
        -- --rising edge of sclk_signal via sample_ce and data can be pushed
        -- --onto mosi via send_ce.
        -- --Use of clock enables allows everything to be rising_edge. 
        -- sclk_signal <= not sclk_signal;
        -- sample_ce <=  sclk_signal;
        -- send_ce <=  not sclk_signal;
  -- end if;
-- end process;

  
----------------------------------------------------------------------------
--
--! @brief      Read bits off MISO
--!          
--! @details    Sample data off MISO into read_shift on the rising edge of sclk.
--!             This is the only process to run off the inverted clock_off signal. 
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------
rcv_MISO:	process(clk_off,rst_n)
begin
  if (rst_n = '0') then
    read_shift <=  (others => '0');
  elsif rising_edge(clk_off) then
       if(rd_en = '1') then
       read_shift(7 downto 0) <= read_shift(6 downto 0) & miso;
       end if;
  end if;
end process;

----------------------------------------------------------------------------
--
--! @brief      Shift data out onto MOSI.
--!          
--! @details    Shift data out onto MOSI on the rising edge of clk, which is the 
--!             falling edge of sclk. A reload signal will reload the shift register.
--!             This can be done as it occurs on the falling edge of sclk.
--!             This part of the algorithm adapts to both cpolcpha of 00 and 11.
--!             This scheme of delaying the first byte sent out 
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------

send_MOSI:	process(clk,rst_n)
begin
  if (rst_n = '0') then
     send_shift <= (others => '0');
  elsif rising_edge(clk) then
    if (reload = '1') then
      send_shift <= send_shift_next;
    else
        if (wr_en = '1') then
              send_shift(7 downto 0) <= send_shift(6 downto 0) & '0';
        end if;
    end if;
  end if;
end process;
  
  ----------------------------------------------------------------------------
--
--! @brief    Sample new byte sent to the entity and signal ready. 
--!          
--! @details    This process is responsible for one off accepting new data bytes
--!             presented to the process.  It then can signal that new data
--!             has been presented at the state machine should keep shifting. 
--!             The process also listens to data_read, which will then set mosi_data_ack_o
--!             high signalling to the user that more data can be presented.
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------

mosi_data_valid_i_process:	process(clk,rst_n)
begin
  if (rst_n = '0') then
 
 
  data_read_follower <= '0';
  mosi_data_valid_i_follower  <= '0';
  new_data  <= '0';
  mosi_data_ack_o <= '1';
  send_shift_next <= (others => '0');
 
  elsif clk'event and clk = '1' then
   
    if (mosi_data_valid_i_follower /= mosi_data_valid_i) then
        mosi_data_valid_i_follower <= mosi_data_valid_i;
      if (mosi_data_valid_i = '1') then
        send_shift_next <= mosi_data_i;
        new_data <= '1';
        mosi_data_ack_o <= '0';
      end if;
    elsif (data_read_follower /= data_read) then
      data_read_follower <= data_read;
      if (data_read = '1') then
      new_data <= '0';
      mosi_data_ack_o <= '1';
      end if;

    end if;
  end if;
end process;


  ----------------------------------------------------------------------------
--
--! @brief      Create the sclk 
--!          
--! @details    Sclk is the inverted clk, gated with a sclk_en signal.
--!             Thus data can be shifted onto MOSI on the rising edge of clk.
--!             Data can be read off MISO on the rising edge of the actual
--!             sclk or clk_off (sclk before gating.) This design was chosen 
--!             specifically to allow for a full 50Mhz sclk.
--!            
--!           
--
--! @param    clk             Take action on positive edge.
--! @param    rst_n           rst_n to initial state.
--
----------------------------------------------------------------------------

	
--Generate the sclk sent to the SPI slave.
--Gate that clock with sclk_en.

--Gating the clocks in the following fashion is all that is needed to 
--implement CPOL_CPHA 11. This is due to the fact that rising edge of clk
--is used to turn on the sclk. At this point sclk is inverted and the
--first bit is put on the line immediately as sclk goes from '1' to '0'. 
--This is what we want to happen in the 11 case. No other dummy bits or
-- delays on mosi shift are needed. 

  
  
  
  clk_off <= not clk;
  
--CPOL_CPHA '00'
cpol_cpha00 : if (cpol_cpha = "00") generate
  sclk <= sclk_en and clk_off;
end generate;
  
--CPOL_CPHA '11'
cpol_cpha11 : if (cpol_cpha = "11") generate
  sclk <= clk_off when sclk_en = '1' else '1';
end generate;



	
end Behavioral;