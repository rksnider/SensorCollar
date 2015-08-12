------------------------------------------------------------------------------
--
--! @file       sd_loader.vhd
--! @brief      sdloader is an interface between the output buffer of the sdram and the 
--!             microsd_controller system. sdloader also handles saving/loading
--!             properties of the microsd_controller entity to persistent ram.
--! @details    
--! @copyright  2015
--! @author     Christopher Casebeer
--! @version    
--
------------------------------------------------------------------------------

------------------------------------------------------------------------------
--
--! @brief      microsd_controller loader. Take data from sdram outbuffer and
--!             load to the microsd_controller internal buffer. This entity
--!             also interacts with magnetic memory buffer to save
--!             relevant microsd_controller information to magnetic memory. 
--! @details    
--!   
--! @param      OUTMEM_BUFFROWS     SDRAM_CONTROLLER constant.
--! @param      OUTMEM_BUFFCOUNT    SDRAM_CONTROLLER constant.
--! @param      SDRAM_SPACE         SDRAM_CONTROLLER constant.
--! @param      sdram_outbuf_size_bytes_g Size of the sdram_outbuf in bytes.
--! @param      buf_size_g          Size of microsd_controller internal buffer, bytes.
--! @param      block_size_g        Size of a sd card block. Minimal addressable data size.
 
--! @param      clk                 Entity clock.

--! @param      rst_n               Negative Reset
  
--! @param      startup_in          Startup Enable Pulse for Entity.
--! @param      data_nbytes_in      The number of bytes the sdram_controller
--!                                 wants to send to the microsd card.
--!                                     
--! @param      outbuf_data_rdy_in  data_nbytes is valid and data should
--!                                 start to be sent.  


--! @param      outbuf_sd_q_b_in      Data bus of the sdram output buffer.
--! @param      sd_outbuf_rd_en_b_out Read Enable on B port of output buffer.
--!
--! @param      sd_outbuf_address_b_out       Address of output buffer.
--! @param      mem_req_a_out                 Memory Request line for the magnetic
--!                                           memory buffer port A. 
--!                                           (Where persistent info is stored
--!                                           before sending to magnetic memory.)
--! @param      mem_rec_a_in                  Memory Received line for the magnetic
--!                                           memory buffer port A.
--!
--! @param      sd_magram_wr_en_a_out       Magnetic Memory 2PBuffer WR_EN Port A
--!                                          
--!                                   
--! @param      sd_magram_rd_en_a_out       Magnetic Memory 2PBuffer RD_EN Port A
--!                     
--! @param      sd_magram_address_a_out     Address of Magnetic Memory 2PBuffer System Facing.
--!                      
--! @param      sd_magram_data_a_out        Data in port of Port A Magnetic Memory 2 Port
--!                                         Buffer System Facing.
--!
--! @param      magram_sd_q_a_in            Data out port of Port A Magnetic Memory 2 Port
--!                                         Buffer System Facing.
--!
--! @param      dw_en                       Direct Write Enable from flash-block.
--!                                         This causes sd_loader to calculate a critical block number.
--! @param      crit_block_serviced         The critical block assembled in response
--!                                         to a critical system event has been
--!                                         written to sd flash. 
                             
--! @param      data_input                  Data_input to microsd_controller.                    
--! @param      data_we                     Data write enable to microsd_controller.    
--! @param      data_full                   Buffer full from microsd_controller                                   
--! @param      data_sd_start_address       Start address to begin writing data
--!                                         on microsd card.                
--! @param      data_nblocks                The number of blocks to be clocked to
--!                                         sd card through microsd_controller.                                                                                          
--! @param      data_current_block_written  Last block successfully written to sd card.                
--! @param      sd_block_written_flag       Flag associated with last successful block written
--!                                         to microsd.       
--! @param      buffer_level                Current level of internal microsd_controller
--!                                         buffer.  
--! @param      blocks_past_crit            When dw_en goes high, this is the number of blocks past the critical
--! @param                                  block that have been formed.
------------------------------------------------------------------------------

--Usage Instructions and Description.

--sdloader is responsible for detecting data_rdy signal from the 
--sdram controller and copying from the output buffer of the sdram controller
--to the microsd_controller's internal buffer. The loader
--must halt upon the buffer in the microsd_controller becoming full.
--The loader will wait until the data has been written to the sd card
--and sdloader will continue copying/filling. 

--SD Loader is meant to sit at the same level as microsd_controller. It interfaces
--with the sd memory output buffer and feeds the inputs of the microsd_controller.

--sdloader also reads and writes the persistent magnetic memory buffer.
--sdloader fetches the startup address and also writes the last block successfully
--written back to that position so that it will be available on next startup. 
--sdloader does this by interfacing with the magnetic memory dual port buffer managed by
--magmem_controller. 

--The main sdloader state machine has been written to be block (512 bytes) 
--aware as this is the minimum data length in which microsd_controller works
--with and interval at which the microsd_buffer will become full. Thus sdloader will check 
--for buffer_full events at 512 bytes intervals. 



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL ;   


library GENERAL;
USE GENERAL.SDRAM_Information_pkg.all;    --Parameters related to SDRAM
USE GENERAL.UTILITIES_PKG.ALL;            --Use General Purpose Libraries    
USE GENERAL.magmem_buffer_def_pkg.all;    --Magnetic Memory Buffer Size and Locations.

entity sd_loader is

generic(

    OUTMEM_BUFFROWS       : natural     := 1 ;
    OUTMEM_BUFFCOUNT      : natural     := 2 ;
    SDRAM_SPACE           : SDRAM_Capacity_t  := SDRAM_32_Capacity_c; 
    
    sdram_outbuf_size_bytes_g : natural := 4096;
    
    buf_size_g            :   natural := 2048;
    block_size_g          :   natural := 512

);

    port(
    
		clk        : in std_logic;
    rst_n      : in std_logic;
     
    startup_in              : in std_logic;
    
    data_nbytes_in          : in std_logic_vector(const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                              SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;
    outbuf_data_rdy_in      : in std_logic;
    
    outbuf_sd_q_b_in        : in std_logic_vector(7 downto 0);
    sd_outbuf_rd_en_b_out   : out std_logic;  
    sd_outbuf_address_b_out : out std_logic_vector(natural(trunc(log2(real(sdram_outbuf_size_bytes_g-1)))) downto 0);
    --sd_outbuf_address_b_out : out std_logic_vector(natural(trunc(log2(real(OUTMEM_BUFFCOUNT * OUTMEM_BUFFROWS *
    --                                  SDRAM_SPACE.ROWBITS /
    --                                  SDRAM_SPACE.DATABITS - 1)))) downto 0); --Currently 9downto0.

    mem_req_a_out           : out std_logic;  
    mem_rec_a_in            : in std_logic;  
    
    sd_magram_wr_en_a_out   : out std_logic;  
    sd_magram_rd_en_a_out   : out std_logic;  
    sd_magram_address_a_out : out std_logic_vector(natural(trunc(log2(real(magmem_buffer_bytes-1)))) downto 0);
    sd_magram_data_a_out    : out std_logic_vector(7 downto 0);
    magram_sd_q_a_in        : in std_logic_vector(7 downto 0);
    
    
    dw_en                   : in std_logic;
    crit_block_serviced     : out std_logic;
    
    
    --Signals passed out from microsd_controller instant.
                                       
    data_input                         :out      std_logic_vector(7 downto 0);                   
    data_we                            :out      std_logic;    
    data_full                          :in       std_logic;                                     
    data_sd_start_address              :out      std_logic_vector(31 downto 0);                 
    data_nblocks                       :out      std_logic_vector(31 downto 0);                                                                                          
    data_current_block_written         :in       std_logic_vector(31 downto 0);                
    sd_block_written_flag              :in       std_logic;      
    buffer_level                       :in       std_logic_vector (natural(trunc(log2(real(buf_size_g/block_size_g)))) downto 0);

    blocks_past_crit                   :in std_logic_vector(7 downto 0)    
            

    );
end entity sd_loader;


architecture Behavioral of sd_loader is


------------------------------------------------SD LOADER Signals


    type SD_LOAD_STATE is   (
    SD_LOAD_WAIT,
    SD_STARTUP_FETCH_START_ADDRESS_SETUP,
    SD_STARTUP_FETCH_START_ADDRESS,
    SD_STARTUP_STORE_START_ADDRESS_SETUP,
    SD_STARTUP_STORE_START_ADDRESS,
    SD_LOAD_COPY,
    SD_LOAD_BUF_FUL,
    SD_LOAD_WRITE_DONE
    );
    
    
signal cur_sdload_state   : SD_LOAD_STATE;


signal data_nblocks_signal : std_logic_vector(31 downto 0);



signal sd_outbuf_address_b :
unsigned(natural(trunc(log2(real(sdram_outbuf_size_bytes_g-1)))) downto 0);

-- signal sd_outbuf_address_b :
-- unsigned(natural(trunc(log2(real(OUTMEM_BUFFCOUNT * OUTMEM_BUFFROWS *
                                      -- SDRAM_SPACE.ROWBITS /
                                      -- SDRAM_SPACE.DATABITS - 1)))) downto 0);
                                      
                                      
--No longer needed. buffer pulls data_full high upon level = max_level -1 
--and data_we (beginning to write last block) allowing plenty of time
--for writing process to halt. 
--If the data_full is pulled on a byte level, its much harder to stop the writing
--entity (sdloader)
-- signal sd_outbuf_address_b_backup :
-- unsigned(natural(trunc(log2(real(OUTMEM_BUFFCOUNT * OUTMEM_BUFFROWS *
                                      -- SDRAM_SPACE.ROWBITS /
                                      -- SDRAM_SPACE.DATABITS - 1)))) downto 0);



--Warning. These have the potential to overflow if you send too much data too fast.
--These are 26 bit counters. Good to 65536mB. Will fail at 100mB!

signal data_nbytes_internal   : unsigned(const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                                SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;
                                  
signal data_nbyte_updated :   unsigned(const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                              SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;
                              
signal data_nbyte_count :     unsigned(const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                              SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;
                              
signal data_nblocks_updated : unsigned(const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                              SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;
                              
signal data_nblocks_internal : unsigned(const_bits (SDRAM_SPACE.BANKS * SDRAM_SPACE.ROWCOUNT *
                              SDRAM_SPACE.ROWBITS / 8 - 1) - 1 downto 0) ;


--  Multi-byte transfer signals.

constant block_size_c : natural := 512;


--Hold the # 512.
signal byte_count             : unsigned (9 downto 0) ;
signal byte_number            : unsigned (9 downto 0) ;
  
--data_nblocks passed to controller. 

signal sd_write_count_internal :   unsigned(31 downto 0); 	

--Output buffer which allows reading this signal.
signal sd_outbuf_rd_en_b : std_logic;

signal sd_magram_address_a : unsigned(natural(trunc(log2(real(magmem_buffer_bytes-1)))) downto 0);	


signal sd_block_address_store : std_logic_vector(31 downto 0);
-- signal sd_block_written_flag_internal : std_logic;
signal sd_block_written_flag_follower : std_logic;   


--State Machine Acknowledgement.
signal startup_done : std_logic;
signal startup_done_follower : std_logic;

signal  address_saved : std_logic;
signal  address_saved_follower : std_logic;

signal  save_address : std_logic;
signal  copy_en : std_logic;
signal  copy_en_processed : std_logic;
signal  copy_en_processed_follower : std_logic;
signal  startup_en : std_logic;



signal outbuf_data_rdy_follower : std_logic;
signal startup_follower : std_logic;

signal copy_done : std_logic;


signal data_n_byte_sampled : std_logic;
signal data_n_byte_sampled_follower : std_logic;


signal dw_en_follower : std_logic;
signal critical_block_number : unsigned(31 downto 0);
-- signal buffer_level_internal : std_logic_vector(natural(trunc(log2(real(buf_size_g/block_size_g)))) downto 0);     

-- signal data_current_block_written_internal : std_logic_vector(31 downto 0);


begin 


sd_magram_address_a_out <= std_logic_vector(sd_magram_address_a);


sd_outbuf_address_b_out <= std_logic_vector(sd_outbuf_address_b);

sd_outbuf_rd_en_b_out <= sd_outbuf_rd_en_b;

--Convert bytes to blocks (block = 512 bytes) by dividing by 2^9=512.
--& Output buffer
-- data_nblocks_signal <= std_logic_vector(resize(shift_right(unsigned(data_nbytes_in),9),data_nblocks_signal'length));
-- data_nblocks <= data_nblocks_signal;

--data_nblocks was not being held during a process. sd_loader should hold data_nblocks.
data_nblocks <= std_logic_vector(resize(data_nblocks_internal,data_nblocks'length));
data_nblocks_updated <= resize(shift_right(data_nbyte_updated,9),data_nblocks_updated'length);
data_nblocks_internal <= resize(shift_right(data_nbytes_internal,9),data_nblocks_internal'length);

data_sd_start_address    <= std_logic_vector(sd_write_count_internal);   

data_input      <= outbuf_sd_q_b_in;
    
 ----------------------------------------------------------------------------
  --
  --! @brief    The main state machine for sdloader 
  --! @details  Use states to fill the sd_card_controller's internal (2k) buffer
  --!           from a larger 2 port ram, which is itself filled from physical  memory.
  --!           The state machine will pause upon microsd_controller's internal buffer
  --!           buffer filling, until more data can be pushed. This is up to the 
  --!           required amt of data (data_nblocks) has been sent. block == 512 bytes. 

  --! @param    clk       Take action on positive edge.
  --! @param    rst_n           rst_n to initial state.
  --!
  --!          
  ----------------------------------------------------------------------------
    
sdloader_state_machine:  process (clk, rst_n)
begin
  if rst_n = '0' then
  
  sd_outbuf_address_b <= to_unsigned(0,sd_outbuf_address_b'length);
  sd_magram_address_a <= to_unsigned(0,sd_magram_address_a'length); 
  sd_magram_data_a_out <= x"00";
 
  data_we <= '0';
 
  data_nbytes_internal  <= to_unsigned(0,data_nbytes_internal'length);
 
  sd_outbuf_address_b <= to_unsigned(0,sd_outbuf_address_b'length);
 
  byte_count <= to_unsigned(0,byte_count'length);
  byte_number <= to_unsigned(0,byte_number'length);
 
  data_nbyte_count <= to_unsigned(1,data_nbyte_count'length);
  
  
  startup_done <= '0';

  
  address_saved <= '0';
  
  data_n_byte_sampled <= '0';
  
  copy_en_processed <= '0';
  
  sd_block_address_store <= (others => '0');
  
  cur_sdload_state   <= SD_LOAD_WAIT ;

 
  elsif clk'event and clk = '1' then

  
  --Default signal states.


  --Reset inter process acknowledgements.
  if (startup_done = '1' and startup_done_follower = '1') then
    startup_done <= '0';
  end if;
  
  if (address_saved = '1' and address_saved_follower = '1') then
    address_saved <= '0';
  end if;
  
  if (data_n_byte_sampled = '1' and data_n_byte_sampled_follower = '1') then
    data_n_byte_sampled <= '0';
  end if;
  
  if (copy_en_processed_follower = '1' and copy_en_processed = '1') then
      copy_en_processed <= '0';
  end if;
  
  

    case cur_sdload_state is


      when SD_LOAD_WAIT          =>
      
        if (copy_en = '1') then
          if (data_full = '0') then
          copy_en_processed <= '1';
          cur_sdload_state  <=  SD_LOAD_COPY;
          data_nbytes_internal <= data_nbyte_updated;
          data_n_byte_sampled <= '1';
          byte_number       <= TO_UNSIGNED (block_size_c-1,
                                            byte_number'length) ;
          byte_count        <= TO_UNSIGNED (0, byte_count'length) ;
          end if;
        elsif (startup_en = '1') then
          cur_sdload_state <= SD_STARTUP_FETCH_START_ADDRESS_SETUP;
        elsif (save_address = '1') then
          cur_sdload_state <= SD_STARTUP_STORE_START_ADDRESS_SETUP;
          sd_block_address_store <= data_current_block_written;
        end if;


      when SD_STARTUP_FETCH_START_ADDRESS_SETUP =>
      
        if (mem_rec_a_in = '1') then 
          cur_sdload_state <= SD_STARTUP_FETCH_START_ADDRESS;
        end if;

        sd_magram_address_a     <= TO_UNSIGNED (sd_card_start_location_c,
                                        sd_magram_address_a'length) ;            
        
        byte_number       <= TO_UNSIGNED (sd_card_start_location_length_bytes_c,
                                          byte_number'length) ;
        byte_count        <= TO_UNSIGNED (0, byte_count'length) ;
      
      
      when SD_STARTUP_FETCH_START_ADDRESS =>
        if byte_count = byte_number then
          cur_sdload_state   <= SD_LOAD_WAIT ;
          startup_done <= '1';
        else
        --The 4 bytes value is stored little endian.
        
          sd_write_count_internal <=  unsigned(magram_sd_q_a_in 
          & std_logic_vector(sd_write_count_internal(31 downto 8))); 
          byte_count        <= byte_count + 1 ;
          sd_magram_address_a <= sd_magram_address_a + 1;
        end if ;   
        
      when SD_STARTUP_STORE_START_ADDRESS_SETUP =>
      
        if (mem_rec_a_in = '1') then 
          cur_sdload_state <= SD_STARTUP_STORE_START_ADDRESS;
        end if;
          
        sd_magram_address_a   <= TO_UNSIGNED (sd_card_start_location_c,
                                            sd_magram_address_a'length) ;            
        
        byte_number       <= TO_UNSIGNED (sd_card_start_location_length_bytes_c,
                                          byte_number'length) ;
        byte_count        <= TO_UNSIGNED (1, byte_count'length) ;
        
        
        sd_magram_data_a_out <=  sd_block_address_store(7 downto 0); 
      
      when SD_STARTUP_STORE_START_ADDRESS =>
          if byte_count = byte_number then
            --One way to wait till save_address is turned off so that
            --we don't immediately process again.
            if (address_saved_follower = '1') then
              cur_sdload_state   <= SD_LOAD_WAIT ; 
            end if;
            address_saved <= '1';
          else
          --The 4 bytes value is stored little endian.
            sd_magram_data_a_out <=  sd_block_address_store(7 downto 0); 
            sd_block_address_store <= x"00" & sd_block_address_store(31 downto 8);
            byte_count        <= byte_count + 1 ;
            sd_magram_address_a <= sd_magram_address_a + 1;
          end if ;   
      
      
      
        
      when SD_LOAD_COPY =>
      --One clock cycle lag on wr_en to allow rd_en data to show up.
      --Data from sdram bufout to microsd is a direct port map.
        data_we <= sd_outbuf_rd_en_b;

        if(data_nbyte_count = data_nbytes_internal) then
          cur_sdload_state <= SD_LOAD_WRITE_DONE;
          sd_outbuf_address_b <= sd_outbuf_address_b + 1;
          --512 bytes have been sent, pause to wait for buf_ful.
        elsif(byte_count = byte_number) then
          cur_sdload_state <= SD_LOAD_BUF_FUL;
          sd_outbuf_address_b <= sd_outbuf_address_b + 1;
          data_nbyte_count <= data_nbyte_count + 1;
        else
          sd_outbuf_address_b <= sd_outbuf_address_b + 1;
          data_nbyte_count <= data_nbyte_count + 1;
          byte_count <= byte_count + 1;
        end if;
        
      when SD_LOAD_BUF_FUL =>
      data_we <= sd_outbuf_rd_en_b;
      if (data_full = '0') then
        cur_sdload_state  <=  SD_LOAD_COPY;
        byte_count <= to_unsigned(0,byte_count'length);
      end if;
        
        
      when SD_LOAD_WRITE_DONE =>
      data_we <= sd_outbuf_rd_en_b;
        sd_write_count_internal <= sd_write_count_internal + shift_right(data_nbytes_internal,9);
        cur_sdload_state <= SD_LOAD_WAIT;
        data_nbyte_count <= to_unsigned(1,data_nbyte_count'length);
        


      end case ;
  end if ;
end process sdloader_state_machine ;


 ----------------------------------------------------------------------------
  --
  --! @brief    The output logic for the cur_sd_loader state machine.
  --! @details  

  
  --! @param    clk       Take action on positive edge.
  --! @param    rst_n           rst_n to initial state.
  --!
  --!          
  ----------------------------------------------------------------------------

sd_loader_output:  process (cur_sdload_state)
begin
  

  mem_req_a_out <= '0';

  sd_magram_rd_en_a_out <= '0';
  sd_magram_wr_en_a_out <= '0';
  sd_outbuf_rd_en_b <= '0';
  copy_done <= '0';


case cur_sdload_state is
    
  when SD_LOAD_WAIT =>

  when SD_STARTUP_FETCH_START_ADDRESS_SETUP =>
  mem_req_a_out <= '1';
  when SD_STARTUP_FETCH_START_ADDRESS =>
  mem_req_a_out <= '1';
  sd_magram_rd_en_a_out <= '1';  

  when SD_STARTUP_STORE_START_ADDRESS_SETUP =>
  mem_req_a_out <= '1';

  when SD_STARTUP_STORE_START_ADDRESS =>
  sd_magram_wr_en_a_out <= '1';  
  mem_req_a_out <= '1';


  when SD_LOAD_COPY =>
  sd_outbuf_rd_en_b <= '1';
  
  when SD_LOAD_BUF_FUL =>
  sd_outbuf_rd_en_b <= '0';

  when SD_LOAD_WRITE_DONE =>
  copy_done <= '1';

 
end case;
end process sd_loader_output ;
    
  ----------------------------------------------------------------------------
  --
  --! @brief    Identify interrupts signifying startup, critical block calculation,
  --!           sd_block_written_flag (-> magnetic memory), and maintenance of 
  --!           data_nbyte count in relation to outbuf_data_rdy_in pulses from 
  --!           sdram_controller. 
  --! @details  

  
  --! @param    clk       Take action on positive edge.
  --! @param    rst_n           rst_n to initial state.
  --!
  --!          
  ----------------------------------------------------------------------------
interrupt_processor: process (clk, rst_n)
begin
  if rst_n = '0' then

outbuf_data_rdy_follower <= '0';
copy_en <= '0';
copy_en_processed_follower <= '0';


save_address <= '0';

crit_block_serviced <= '0';


data_nbyte_updated    <= to_unsigned(0,data_nbytes_internal'length);
data_n_byte_sampled_follower <= '0';

address_saved_follower <= '0';
startup_done_follower <= '0'; 
startup_follower <= '0';
startup_en <= '0';



  elsif clk'event and clk = '1' then

  --Here we accumulate data_nbytes into data_nbyte_updated.
  --If the state machine processes the last data_nbyte_updated,
  --simply reset data_nbyte_updated to data_nbytes_in, throwing
  --away previous accumulation.
  
    --Default data_n_byte state;
    data_n_byte_sampled_follower <= '0';
    if (outbuf_data_rdy_follower /= outbuf_data_rdy_in) then
      outbuf_data_rdy_follower <= outbuf_data_rdy_in;

      if (outbuf_data_rdy_in = '1') then
        if (data_n_byte_sampled = '1') then
          copy_en <= '1';
          data_n_byte_sampled_follower <= data_n_byte_sampled;
          data_nbyte_updated <= unsigned(data_nbytes_in);
        else
          copy_en <= '1';
          data_nbyte_updated <= data_nbyte_updated + 
                unsigned(data_nbytes_in);
        end if;
      end if;

        
        
    elsif(copy_en_processed_follower /= copy_en_processed) then
    copy_en_processed_follower <= copy_en_processed;
      if (copy_en_processed = '1') then
          copy_en <= '0';
      end if ;
    end if;
    
    --Identify a critical block in the data stream and alert when 
    --it has been written to flash. 
    --dw_en will always pulse high even if dw mode is never entered. 
    if (dw_en_follower /= dw_en) then
      dw_en_follower <= dw_en;
      if (dw_en = '1') then
      --While buf_full goes high on the dw_en edge of buffer_level==3, the buffer_level does not
      --increment until the last byte is written.  This allows sampling of buffer_level directly.
      --To calculate the critical block number we need the blocks in the buffer, the blocks currently being serviced
      --in the state machine, the blocks awaiting servicing that came in during force_we
      --mode through pulsing of data_rdy_in, and finally the blocks sitting on the 
      --data_n_bytes_in port which are not associated with a data_rdy_in pulse because in direct
      --write mode this byte number is passed directly from flashblock through sdram_controller.
        critical_block_number <= unsigned(data_current_block_written) + unsigned(buffer_level) +
        unsigned(data_nblocks_signal) + unsigned(data_nblocks_updated) + unsigned(data_nblocks_internal) - unsigned(blocks_past_crit);
      end if;
    end if;
    
    
    if (startup_follower /= startup_in) then
      startup_follower <= startup_in;
      if (startup_in = '1') then
        startup_en <= '1';
      end if;
        
    elsif(startup_done_follower /= startup_done) then
     startup_done_follower <= startup_done ;
      if (startup_done = '1') then
        startup_en <= '0';
      end if ;
        
    end if;
    
    
    --Save the last written sd address into the magnetic memory buffer.
    
    if (sd_block_written_flag_follower /= sd_block_written_flag) then
      sd_block_written_flag_follower <= sd_block_written_flag;
      if (sd_block_written_flag = '1') then
        save_address <= '1';

        if (unsigned(data_current_block_written) = critical_block_number) then
         --This will last one whole block.This is probably okay for now.
          crit_block_serviced <= '1';
        else
          crit_block_serviced <= '0';
        end if;
        
        
      end if;
        
    elsif(address_saved_follower /= address_saved) then
     address_saved_follower <= address_saved ;
      if (address_saved = '1') then
        save_address <= '0';
      end if ;
        
    end if;
    
       

  end if ;
end process interrupt_processor ;



end Behavioral;