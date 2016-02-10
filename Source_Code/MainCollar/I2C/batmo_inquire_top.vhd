----------------------------------------------------------------------------
--
--! @file       batmon_inquire.vhd
--! @brief      bq27520 polling state machine
--! @details    State machine to pull registers from bq27520g4
--!             battery monitor using I2C subsystems.
--! @author     Chris Casebeer
--! @date       1_15_2016
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
--! @brief      Battery Monitor G4 Information Retrieve.
--! @details    
--!   

  
--! @param   clk_freq_g               Clk Frequency. 
--! @param   update_interval_ms_g     Interval to poll the batmon.
  
--! @param   mem_bits_g           I2C Memory Address Bit Count
--! @param   simulate_g           Skip poll wait when simulation.
--! @param   cmd_offset_g         Location of the commands in the I2C memory
--! @param   write_offset_g       Location of the write from locations in the I2C memory
--! @param   read_offset_g        Location of the read to locations in the I2C memory

--! @param    startup              The machine will begin polling the batmon.

--! @param    cmd_offset_out        Offset of the command structure in I2C_CMDS.mif
--!                                 as defined in I2C_cmd_pkg.vhd  
--! @param    cmd_count_out         Sequential commands to execute at I2C_IO
--! @param    cmd_start_out         Start the I2C_IO machine.
--! @param    cmd_busy_in           I2C_IO is busy.

--! @param    mem_clk                          b side I2C memory clock.
--! @param    mem_address_signal_b_out          b side I2C memory adress in
--! @param    mem_datafrom_signal_b_in          b side I2C memory data out
--! @param    mem_datato_signal_b_out           b side I2C memory data in
--! @param    mem_read_en_signal_b_out          b side I2C memory read enable
--! @param    mem_write_en_signal_b_out         b side I2C memory write enable
     
--! @param    i2c_req_out           Request i2c core and b side memory.
--! @param    i2c_rcv_in            i2c core and b side memory granted. 
    
--! @param    voltage_mv            Voltage as read by the bq27520
--! @param    current_ma            Instant mA read by the bq27520
--! @param    capacity_mah          bq27520's estimate of the bat capacity
--
------------------------------------------------------------------------------


--This machine uses the I2C_IO which uses the I2C_master machine to 
--interact with the TI bQ27520G4 Battery Monitor chip.

--This machine polls the following information off the G4. 
--Voltage
--Instant Current
--Remaining capacity in mAh. 


--TODO:
--I2C Repeated Starts at this level and the I2C_IO level 
--haven't been considered yet. 



library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.


library WORK ;                   --! General libraries.
use WORK.I2C_CMDS_PKG.ALL ;

entity batmon_inquire is

  Generic (
  
  clk_freq_g               : natural  := 50E6;
  update_interval_ms_g     : natural  := 1;
  
  mem_bits_g               : natural  := 10;
  simulate_g               : std_logic := '0';
  cmd_offset_g          : natural   := 0 ;
  write_offset_g        : natural   := 256 ;
  read_offset_g         : natural   := 512

  ) ;
  Port (
    clk                   : in  std_logic ;
    rst_n                 : in  std_logic ;
    
    startup               : in std_logic;
    
    cmd_offset_out        : out   unsigned (mem_bits_g-1 downto 0) ;
    cmd_count_out         : out   unsigned (7 downto 0) ;
    cmd_start_out         : out   std_logic ;
    cmd_busy_in           : in    std_logic ;
    
    mem_clk                           :  out std_logic;
    mem_address_signal_b_out          : out unsigned (mem_bits_g-1 downto 0) ;
    mem_datafrom_signal_b_in          : in std_logic_vector (7 downto 0) ;
    mem_datato_signal_b_out           : out std_logic_vector (7 downto 0) ;
    mem_read_en_signal_b_out          : out std_logic ;
    mem_write_en_signal_b_out         : out std_logic ;
    
    i2c_req_out           : out   std_logic ;
    i2c_rcv_in            : in    std_logic ;
    
    voltage_mv_out            : out   std_logic_vector (15 downto 0);
    rem_cap_mah_out           : out   std_logic_vector (15 downto 0);
    inst_cur_ma_out           : out   std_logic_vector (15 downto 0)
  

  ) ;

end entity batmon_inquire ;



architecture behavior of batmon_inquire is


    type BATMON_INQ is   (
    BATMON_STATE_WAIT,
    BATMON_STATE_WAIT_START,
    BATMON_STATE_VOLTAGE_SETUP,
    BATMON_STATE_VOLTAGE,
    BATMON_STATE_VOLTAGE_WAIT,
    BATMON_STATE_VOLTAGE_READ_SETUP,
    BATMON_STATE_VOLTAGE_READ,
    BATMON_STATE_CURRENT_SETUP,
    BATMON_STATE_CURRENT,
    BATMON_STATE_CURRENT_WAIT,
    BATMON_STATE_CURRENT_READ_SETUP,
    BATMON_STATE_CURRENT_READ,
    BATMON_STATE_CAPACITY_SETUP,
    BATMON_STATE_CAPACITY,
    BATMON_STATE_CAPACITY_WAIT,
    BATMON_STATE_CAPACITY_READ_SETUP,
    BATMON_STATE_CAPACITY_READ,
    state_init_cmd_e,
    state_read_cmd_e
    

    );
    


  signal cur_state   : BATMON_INQ;
  signal next_state  : BATMON_INQ; 
  
--Below is Emery's code.
--I need access to the mif file stored dual port variables.
--Most notably where to read the written values from. 
-----------------------------------------------  
  
  --  Command structure and mapping.  The field length, start, and end
  --  constants are defined in the order they are stored in memory
  --  (lowest to highest byte).  The bytes are loaded into the top byte of
  --  the structure's bit vector and shifted right as other bytes are
  --  added.  This results in the first bytes being the lowest bits in the
  --  bit vector.

  constant subcmd_delay_len_c   : natural := 8 ;
  constant cmd_delay_len_c      : natural := 24 ;
  constant i2c_address_len_c    : natural := 8 ;
  constant write_length_len_c   : natural := 8 ;
  constant write_offset_len_c   : natural := 8 ;
  constant write_max_len_c      : natural := 8 ;
  constant read_length_len_c    : natural := 8 ;
  constant read_offset_len_c    : natural := 8 ;
  constant read_max_len_c       : natural := 8 ;

  constant subcmd_delay_str_c   :
                natural := 0                  + subcmd_delay_len_c - 1 ;
  constant cmd_delay_str_c      :
                natural := subcmd_delay_str_c + cmd_delay_len_c ;
  constant i2c_address_str_c    :
                natural := cmd_delay_str_c    + i2c_address_len_c ;
  constant write_length_str_c   :
                natural := i2c_address_str_c  + write_length_len_c ;
  constant write_offset_str_c   :
                natural := write_length_str_c + write_offset_len_c ;
  constant write_max_str_c      :
                natural := write_offset_str_c + write_max_len_c ;
  constant read_length_str_c    :
                natural := write_max_str_c    + read_length_len_c ;
  constant read_offset_str_c    :
                natural := read_length_str_c  + read_offset_len_c ;
  constant read_max_str_c       :
                natural := read_offset_str_c  + read_max_len_c ;

  constant subcmd_delay_end_c   : natural := 0 ;
  constant cmd_delay_end_c      : natural := subcmd_delay_str_c + 1 ;
  constant i2c_address_end_c    : natural := cmd_delay_str_c    + 1 ;
  constant write_length_end_c   : natural := i2c_address_str_c  + 1 ;
  constant write_offset_end_c   : natural := write_length_str_c + 1 ;
  constant write_max_end_c      : natural := write_offset_str_c + 1 ;
  constant read_length_end_c    : natural := write_max_str_c    + 1 ;
  constant read_offset_end_c    : natural := read_length_str_c  + 1 ;
  constant read_max_end_c       : natural := read_offset_str_c  + 1 ;

  constant cmd_struct_len_c     : natural := read_max_str_c     + 1 ;

  constant cmd_struct_bytes_c   : natural :=
              natural (trunc (real((cmd_struct_len_c + 7) / 8))) ;

  --  Define the structure signal and the field aliases within it.

  signal cmd_struct           : unsigned (cmd_struct_len_c-1 downto 0) ;

  alias subcmd_delay          : unsigned (subcmd_delay_len_c-1 downto 0) is
              cmd_struct (subcmd_delay_str_c  downto subcmd_delay_end_c) ;

  alias cmd_delay             : unsigned (cmd_delay_len_c-1 downto 0) is
              cmd_struct (cmd_delay_str_c     downto cmd_delay_end_c) ;

  alias i2c_address           : unsigned (i2c_address_len_c-1 downto 0) is
              cmd_struct (i2c_address_str_c   downto i2c_address_end_c) ;

  alias write_length          : unsigned (write_length_len_c-1 downto 0) is
              cmd_struct (write_length_str_c  downto write_length_end_c) ;

  alias write_offset          : unsigned (write_offset_len_c-1 downto 0) is
              cmd_struct (write_offset_str_c  downto write_offset_end_c) ;

  alias write_max             : unsigned (write_max_len_c-1 downto 0) is
              cmd_struct (write_max_str_c     downto write_max_end_c) ;

  alias read_length           : unsigned (read_length_len_c-1 downto 0) is
              cmd_struct (read_length_str_c   downto read_length_end_c) ;

  alias read_offset           : unsigned (read_offset_len_c-1 downto 0) is
              cmd_struct (read_offset_str_c   downto read_offset_end_c) ;

  alias read_max              : unsigned (read_max_len_c-1 downto 0) is
              cmd_struct (read_max_str_c      downto read_max_end_c) ;
              
  --  Command processing signals.

  signal cmd_number           : unsigned (7 downto 0) ;

  signal nextcmd_address      : unsigned (mem_bits_g-1 downto 0) ;

  --  Data processing signals.
  signal byte_count : unsigned (7 downto 0);
  signal byte_max             : unsigned (7 downto 0) ;

  signal next_data_address    : unsigned (mem_bits_g-1 downto 0) ;

  signal save_count           : unsigned (byte_count'length-1 downto 0) ;
  signal save_address         : unsigned (next_data_address'length-1
                                          downto 0) ;
                                          
--------------------------
--------------------------

  signal byte_address : unsigned (mem_bits_g-1 downto 0) ;
  

  --Do not exceed this counter with your timeout value. 
  signal inquiry_timeout : unsigned(8 downto 0);
  

  --Fields of interset right now.
  signal voltage_mv : std_logic_vector (I2C_BM_Voltage_rdlen*8-1 downto 0);
  signal rem_cap_mah : std_logic_vector (I2C_BM_Voltage_rdlen*8-1 downto 0);
  signal inst_cur_ma : std_logic_vector (I2C_BM_Voltage_rdlen*8-1 downto 0);
  
  signal mem_address_signal_b     : unsigned (mem_bits_g-1 downto 0) ;
  signal mem_datato_signal_b      : std_logic_vector (7 downto 0) ;
  signal mem_read_en_signal_b     : std_logic ;
  signal mem_write_en_signal_b    : std_logic ;
  

  signal cmd_busy_in_follower : std_logic;
  
  signal cmd_offset   : unsigned (mem_bits_g-1 downto 0);

begin

mem_clk <= not clk;


  mem_address_signal_b_out <= mem_address_signal_b;
  mem_datato_signal_b_out <= mem_datato_signal_b;
  mem_read_en_signal_b_out <= mem_read_en_signal_b;
  mem_write_en_signal_b_out <= mem_write_en_signal_b;



batmon_state_machine:  process (clk, rst_n)
variable byte_address : unsigned (mem_bits_g-1 downto 0) ;
begin
  if (rst_n = '0') then
  
    cmd_offset_out        <= (others => '0');
    cmd_count_out         <= (others => '0');
    cur_state             <= BATMON_STATE_WAIT;
    cmd_start_out         <= '0';
    byte_count            <= (others => '0');
    cmd_busy_in_follower  <= '1';
    inquiry_timeout <= to_unsigned(0,inquiry_timeout'length);
 
  elsif (clk'event and clk = '1') then

  
  
    case cur_state is


      when BATMON_STATE_WAIT   =>

        if (startup = '1') then
          cur_state <=  BATMON_STATE_WAIT_START;
        end if;
        

      when BATMON_STATE_WAIT_START =>
        if (simulate_g = '1') then 
          cur_state <= BATMON_STATE_VOLTAGE_SETUP;
        elsif (inquiry_timeout = to_unsigned(clk_freq_g/1E6 * update_interval_ms_g,inquiry_timeout'length)) then
          cur_state <= BATMON_STATE_VOLTAGE_SETUP;
          inquiry_timeout <= to_unsigned(0,inquiry_timeout'length);
        else
          inquiry_timeout <= inquiry_timeout + 1;
        end if;
      
      when BATMON_STATE_VOLTAGE_SETUP   =>
      i2c_req_out           <= '1' ;
      if (i2c_rcv_in = '1') then 
        if (cmd_busy_in = '0') then
          cmd_offset_out        <= to_unsigned(I2C_BM_Voltage_cmd,cmd_offset_out'length);
          cmd_offset            <= to_unsigned(I2C_BM_Voltage_cmd,cmd_offset_out'length);
          cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
          cur_state            <= BATMON_STATE_VOLTAGE;      
        end if;
      end if;


      when BATMON_STATE_VOLTAGE    =>
      
      cmd_start_out         <= '1';
      cur_state            <= BATMON_STATE_VOLTAGE_WAIT;

      when BATMON_STATE_VOLTAGE_WAIT =>
      cmd_start_out         <= '0';
      if (cmd_busy_in = '1') then 
        cur_state            <= state_init_cmd_e;
        next_state            <= BATMON_STATE_VOLTAGE_READ_SETUP;
      end if;
      
      --Initialize the command sequence to execute.
      --Grab the data out of the mif file.
      --The write/read location in the dual port memory is needed. 
      --These states taken out of I2C_cmds.mif.
      when state_init_cmd_e   =>

        --if (mem_rcv_in = '1') then
          cur_state           <= state_read_cmd_e ;
          cmd_number          <= (others => '0') ;
          byte_count          <= (others => '0') ;
          byte_address        := cmd_offset +
                                   to_unsigned(cmd_offset_g,cmd_offset'length) ;

          mem_address_signal_b     <= byte_address ;
          mem_read_en_signal_b     <= '1' ;
          nextcmd_address           <= byte_address + 1 ;
        --end if ;

      --  Read the command information.  New bytes are added at the top
      --  and shifted downward.

      when state_read_cmd_e   =>
        if (byte_count /= cmd_struct_bytes_c) then
          byte_count          <= byte_count + 1 ;

          cmd_struct (cmd_struct_len_c-9 downto 0)                  <=
                            cmd_struct (cmd_struct_len_c-1 downto 8) ;
          cmd_struct (cmd_struct_len_c-1 downto cmd_struct_len_c-8) <=
                            unsigned(mem_datafrom_signal_b_in) ;
                            
          mem_address_signal_b     <= nextcmd_address ;
          nextcmd_address     <= nextcmd_address + 1 ;

        else
          --  Start writing data out.
          cur_state           <= next_state ;
          mem_read_en_signal_b     <= '0' ;
        end if ;
     
      
      when BATMON_STATE_VOLTAGE_READ_SETUP    =>
        mem_read_en_signal_b      <= '1';

        mem_address_signal_b      <=  RESIZE (read_offset,
                                             next_data_address'length) +
                                     read_offset_g ;
                                     
        byte_count                <= TO_UNSIGNED (0, byte_count'length) ; 
          if ( cmd_busy_in = '0') then 
            --mem_req_out               <= '1';
            --if (mem_rcv_in = '1') then 
              cur_state            <= BATMON_STATE_VOLTAGE_READ;
          --end if;
        end if;
      
      when BATMON_STATE_VOLTAGE_READ    =>
        if (byte_count = I2C_BM_Voltage_rdlen) then
          cur_state            <= BATMON_STATE_CURRENT_SETUP;
          voltage_mv_out        <= voltage_mv;
          mem_read_en_signal_b     <= '0' ;
        else
        --Low order bit shows up first on the I2C bus.
        --They are stored little endian in the ram as well. 
          voltage_mv <= mem_datafrom_signal_b_in & voltage_mv(I2C_BM_Voltage_rdlen*8-1 downto 8) ;
          byte_count  <= byte_count + 1 ;
          mem_address_signal_b      <=  mem_address_signal_b + 1;
        end if;
        
        
        ----Current
      when BATMON_STATE_CURRENT_SETUP   =>

      if (cmd_busy_in = '0') then
        cmd_offset_out        <= to_unsigned(I2C_BM_InstCur_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_BM_InstCur_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
        cur_state            <= BATMON_STATE_CURRENT;      
      end if;


      when BATMON_STATE_CURRENT    =>
      
      cmd_start_out         <= '1';
      cur_state            <= BATMON_STATE_CURRENT_WAIT;

      when BATMON_STATE_CURRENT_WAIT =>
      cmd_start_out         <= '0';
      --mem_req_out           <= '1' ;
      if (cmd_busy_in = '1') then 
        cur_state            <= state_init_cmd_e;
        next_state            <= BATMON_STATE_CURRENT_READ_SETUP;
      end if;

      when BATMON_STATE_CURRENT_READ_SETUP    =>
        mem_read_en_signal_b      <= '1';

        mem_address_signal_b      <=  RESIZE (read_offset,
                                             next_data_address'length) +
                                     read_offset_g ;
                                     
        byte_count                <= TO_UNSIGNED (0, byte_count'length) ; 
          if ( cmd_busy_in = '0') then 
            --mem_req_out               <= '1';
            --if (mem_rcv_in = '1') then 
              cur_state            <= BATMON_STATE_CURRENT_READ;
          --end if;
        end if;
      
      
      
      when BATMON_STATE_CURRENT_READ    =>
        if (byte_count = I2C_BM_InstCur_rdlen) then
          cur_state            <= BATMON_STATE_CAPACITY_SETUP;
          inst_cur_ma_out        <= inst_cur_ma;
          mem_read_en_signal_b     <= '0' ;
        else
          inst_cur_ma <= mem_datafrom_signal_b_in & inst_cur_ma(I2C_BM_InstCur_rdlen*8-1 downto 8) ;
          byte_count  <= byte_count + 1 ;
          mem_address_signal_b      <=  mem_address_signal_b + 1;
        end if;
        
        
      ---Capacity
        
        
      when BATMON_STATE_CAPACITY_SETUP   =>

        if (cmd_busy_in = '0') then
          cmd_offset_out        <= to_unsigned(I2C_BM_RemCap_cmd,cmd_offset_out'length);
          cmd_offset            <= to_unsigned(I2C_BM_RemCap_cmd,cmd_offset_out'length);
          cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
          cur_state            <= BATMON_STATE_CAPACITY;      
        end if;


      when BATMON_STATE_CAPACITY    =>
      
        cmd_start_out         <= '1';
        cur_state            <= BATMON_STATE_CAPACITY_WAIT;

      when BATMON_STATE_CAPACITY_WAIT =>
        cmd_start_out         <= '0';
        --mem_req_out           <= '1' ;
        if (cmd_busy_in = '1') then 
          cur_state            <= state_init_cmd_e;
          next_state            <= BATMON_STATE_CAPACITY_READ_SETUP;
        end if;

      when BATMON_STATE_CAPACITY_READ_SETUP    =>
        mem_read_en_signal_b      <= '1';

        mem_address_signal_b      <=  RESIZE (read_offset,
                                             next_data_address'length) +
                                     read_offset_g ;
                                     
        byte_count                <= TO_UNSIGNED (0, byte_count'length) ; 
          if ( cmd_busy_in = '0') then 
            --mem_req_out               <= '1';
            --if (mem_rcv_in = '1') then 
              cur_state            <= BATMON_STATE_CAPACITY_READ;
          --end if;
        end if;
      
      
      
      when BATMON_STATE_CAPACITY_READ    =>
        if (byte_count = I2C_BM_RemCap_rdlen) then
          cur_state            <= BATMON_STATE_WAIT_START;
          rem_cap_mah_out        <= rem_cap_mah;
          mem_read_en_signal_b     <= '0' ;
          i2c_req_out           <= '0' ;
        else
          rem_cap_mah <= mem_datafrom_signal_b_in & rem_cap_mah(I2C_BM_RemCap_rdlen*8-1 downto 8);
          byte_count  <= byte_count + 1 ;
          mem_address_signal_b      <=  mem_address_signal_b + 1;
        end if;

      end case ;
  end if ;
end process batmon_state_machine ;



end behavior ;
