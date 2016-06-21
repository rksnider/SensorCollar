----------------------------------------------------------------------------
--
--! @file       rtc_inquire.vhd
--! @brief      DS1371 Real Time Clock Inquiry and Set Machine
--! @details    State machine to pull/push registers from I2C
--!             RTC using I2C subsystems.
--! @author     Chris Casebeer
--! @date       1_20_2016
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
--! @brief      RTC Clock DS1371 Push/Pull/Setup Registers
--! @details    
--!   

--! @param    startup_in            Signal to push initial config register.
--! @param    startup_done_out      Init done. 

--! @param    cmd_offset_in         Offset of command structures in I2C_CMDS.mif
--!                                 as defined in I2C_cmd_pkg.vhd  
--! @param    cmd_count_in          Sequential commands to execute.
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
    
--! @param    time_of_day_set_in      Signal to set the time of day of RTC
--! @param    time_of_day_in          Time to write to the RTC. 
--! @param    tod_set_done_out        TOD setting prodedure done. 

--! @param    tod_get_in           Signal to get the TOD off the RTC.
--! @param    tod_out                Retrieved time_of_day off the RTC.    
--! @param    tod_get_valid_out     The TOD_OUT is now valid.       


--! @param    alarm_set_in            Signal to set the alarm of RTC   
--! @param    alarm_in                Alarm to write to the RTC.
--! @param    alarm_set_done_out      Alarm setting prodedure done. 

--! @param     rtc_sec_out          Set SystemTime upon boot. 
--! @param     rtc_sec_load_out     Set SystemTime flag.
--! @param     rtc_sec_in           Update RTC time from SystemTime
--! @param     rtc_sec_set_in       Update RTC time from SystemTime flag
--
------------------------------------------------------------------------------





--RTC_INQUIRE_TOP interacts with systemtime.vhd. It presents the TOD to 
--systemtime upon boot only if valid. RTC TOD is updated whenever systemtime
--indicates. 

--5_24_2016
--Added SR latch to catch fast 50Mhz pulse coming from SystemTime.




--TODO:
--No repeated starts are used. 
--This actually has to do with I2C_IO.
--The I2C_IO EN latch needs to be held between writes and reads to 
--enact a repeated start. So far this change isn't needed. 





library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.


library WORK ;                   --! General libraries.
use WORK.I2C_CMDS_PKG.ALL ;
library GENERAL ;
USE GENERAL.compile_start_time_pkg.ALL;

entity rtc_inquire_top is

  Generic (
  
  tod_bytes             :natural := 4;
  alarm_bytes           :natural := 3;
  
  mem_bits_g            : natural  := 10;

  cmd_offset_g          : natural   := 0 ;
  write_offset_g        : natural   := 256 ;
  read_offset_g         : natural   := 512

  ) ;
  Port (
    clk                   : in  std_logic ;
    rst_n                 : in  std_logic ;
    
    startup_in               : in std_logic;
    startup_done_out         : out std_logic;
    
    cmd_offset_out        : out   unsigned (mem_bits_g-1 downto 0) ;
    cmd_count_out         : out   unsigned (7 downto 0) ;
    cmd_start_out         : out   std_logic ;
    cmd_busy_in           : in    std_logic ;
    
    mem_clk_out                           : out std_logic;
    mem_address_signal_b_out          : out unsigned (mem_bits_g-1 downto 0) ;
    mem_datafrom_signal_b_in          : in std_logic_vector (7 downto 0) ;
    mem_datato_signal_b_out           : out std_logic_vector (7 downto 0) ;
    mem_read_en_signal_b_out          : out std_logic ;
    mem_write_en_signal_b_out         : out std_logic ;
    
    i2c_req_out           : out   std_logic ;
    i2c_rcv_in            : in    std_logic ;

    tod_set_in            : in    std_logic;
    tod_set_done_out      : out    std_logic;
    tod_in                : in   std_logic_vector(tod_bytes*8-1 downto 0);
    
    tod_get_in            : in   std_logic;
    tod_out               : out   std_logic_vector(tod_bytes*8-1 downto 0);     
    tod_get_valid_out     : out   std_logic; 

    alarm_set_in          : in    std_logic;    
    alarm_in              : in   std_logic_vector(alarm_bytes*8-1 downto 0);
    alarm_set_done_out    : out    std_logic;
    
    rtc_interrupt_enable  : out   std_logic;
    rtc_sec_out           : out   unsigned (tod_bytes*8-1 downto 0) ;
    rtc_sec_load_out      : out   std_logic ;
    rtc_sec_in            : in    unsigned (tod_bytes*8-1 downto 0) ;
    rtc_sec_set_in        : in    std_logic 
    
    
    
  
  

  ) ;

end entity rtc_inquire_top ;



architecture behavior of rtc_inquire_top is


    type RTC_INQ is   (
    
    RTC_STATE_WAIT,
    RTC_STATE_WAIT_START,
    RTC_STATE_CONF,
    RTC_STATE_CONF_START,
    RTC_STATE_CONF_WAIT,
    

    RTC_STATE_TOD_GET_SETUP,
    RTC_STATE_TOD_GET,
    RTC_STATE_TOD_GET_WAIT,
    RTC_STATE_TOD_GET_READ_SETUP,
    RTC_STATE_TOD_GET_READ,
    
    
    RTC_STATE_TOD_STARTUP_CHECK,
    
    
    RTC_STATE_ALARM_READ_CONSTANTS_SETUP,
    RTC_STATE_ALARM_SET_WRITE_SETUP,
    RTC_STATE_ALARM_SET_WRITE,
    RTC_STATE_ALARM_SET_SETUP,
    RTC_STATE_ALARM_SET,
    RTC_STATE_ALARM_SET_WAIT,
    RTC_STATE_ALARM_SET_WAIT_DONE,
    
    
    RTC_STATE_TOD_READ_CONSTANTS_SETUP,
    RTC_STATE_TOD_SET_WRITE_SETUP,
    RTC_STATE_TOD_SET_WRITE,
    RTC_STATE_TOD_SET_SETUP,
    RTC_STATE_TOD_SET,
    RTC_STATE_TOD_SET_WAIT,
    RTC_STATE_TOD_SET_WAIT_DONE,
    
    
    
    state_init_cmd_e,
    state_read_cmd_e

    );
    


  signal cur_state   : RTC_INQ;
  signal next_state  : RTC_INQ; 
  signal final_state : RTC_INQ;
  
--Below is Emery's code.
--I need access to the mif file stored variables.
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
  signal time_of_day : std_logic_vector (tod_bytes*8-1 downto 0);
  signal alarm : std_logic_vector (alarm_bytes*8-1 downto 0);

  
  signal mem_address_signal_b     : unsigned (mem_bits_g-1 downto 0) ;
  signal mem_datato_signal_b      : std_logic_vector (7 downto 0) ;
  signal mem_read_en_signal_b     : std_logic ;
  signal mem_write_en_signal_b    : std_logic ;
    
    
    
  signal cmd_busy_in_follower : std_logic;
  
  signal cmd_offset   : unsigned (mem_bits_g-1 downto 0);

--SR Latch from Faster Domain. Use SR_FlipFlop

  signal    rtc_sec_set_in_q          : std_logic; 
  signal    rtc_sec_set_in_reset      : std_logic; 
  signal    rtc_sec_set_in_reg        : std_logic;
  
  
component SR_FlipFlop is

  Generic (
    set_edge_detect_g     : std_logic := '0' ;
    clear_edge_detect_g   : std_logic := '0'
  ) ;
  Port (
    reset_in              : in    std_logic ;
    set_in                : in    std_logic ;
    result_rd_out         : out   std_logic ;
    result_sd_out         : out   std_logic
  ) ;

end component SR_FlipFlop ;


begin

mem_clk_out <= not clk;


  mem_address_signal_b_out <= mem_address_signal_b;
  mem_datato_signal_b_out <= mem_datato_signal_b;
  mem_read_en_signal_b_out <= mem_read_en_signal_b;
  mem_write_en_signal_b_out <= mem_write_en_signal_b;




  
  SR_rtc_sec_set_in_0:SR_FlipFlop 

  Generic Map (
    set_edge_detect_g     => '0',
    clear_edge_detect_g   => '0'
  ) 
  Port Map (
    reset_in              =>  rtc_sec_set_in_reset,
    set_in                =>  rtc_sec_set_in,
    result_rd_out         =>  rtc_sec_set_in_reg
    --result_sd_out       => 
  ) ;
  
  



rtc_state_machine:  process (clk, rst_n)
variable byte_address : unsigned (mem_bits_g-1 downto 0) ;
begin
  if (rst_n = '0') then
  
    cmd_offset_out        <= (others => '0');
    cmd_count_out         <= (others => '0');
    cur_state             <= RTC_STATE_WAIT;
    next_state            <= RTC_STATE_WAIT;
    final_state           <= RTC_STATE_WAIT;
    cmd_start_out         <= '0';
    byte_count            <= (others => '0');
    cmd_busy_in_follower  <= '1';
    inquiry_timeout <= to_unsigned(0,inquiry_timeout'length);
    
    
    startup_done_out     <= '0';
    
    i2c_req_out           <= '0';
    
    
    cmd_offset_out        <= (others => '0');
    cmd_count_out         <= (others => '0');
    cmd_start_out         <= '0';
    
    
    mem_address_signal_b    <= (others => '0');
    mem_datato_signal_b     <= (others => '0');
    mem_read_en_signal_b    <= '0';
    mem_write_en_signal_b   <= '0';
    rtc_interrupt_enable    <= '0';
    rtc_sec_out         <= (others => '0');
    rtc_sec_load_out    <= '0';
 
 
 
  elsif (clk'event and clk = '1') then

  
      tod_set_done_out <= '0';
      tod_get_valid_out <= '0';
      alarm_set_done_out <= '0';
      
      
      tod_set_done_out <= '0';     
      tod_get_valid_out <= '0';         
      alarm_set_done_out <= '0';   
  
  
      rtc_sec_load_out <= '0';
      
      rtc_sec_set_in_reset <= '0';
  
    case cur_state is
    

      
      when RTC_STATE_WAIT   =>

        if (startup_in = '1') then
          cur_state <=  RTC_STATE_TOD_GET_SETUP;
          final_state <= RTC_STATE_TOD_STARTUP_CHECK;
        end if;
        

      when RTC_STATE_WAIT_START =>

        if (tod_set_in = '1') then 
          cur_state <= RTC_STATE_TOD_READ_CONSTANTS_SETUP;
          time_of_day <= tod_in;
        elsif (tod_get_in = '1') then
          cur_state <= RTC_STATE_TOD_GET_SETUP;
          final_state <= RTC_STATE_WAIT_START;
        elsif (alarm_set_in = '1') then
          cur_state <= RTC_STATE_ALARM_READ_CONSTANTS_SETUP;
          alarm <= alarm_in;
        elsif (rtc_sec_set_in_reg = '1') then
          rtc_sec_set_in_reset <= '1';
          cur_state <= RTC_STATE_TOD_READ_CONSTANTS_SETUP;
          time_of_day <= std_logic_vector(rtc_sec_in);
        else
          cur_state <= RTC_STATE_WAIT_START;
        end if;
        
        
      when RTC_STATE_CONF   =>

      if (cmd_busy_in = '0') then
        i2c_req_out           <= '1';
        cmd_offset_out        <= to_unsigned(I2C_RTC_Init_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_RTC_Init_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
        cur_state            <= RTC_STATE_CONF_START;      
      end if;


      when RTC_STATE_CONF_START    =>
        if (i2c_rcv_in = '1') then
          cmd_start_out         <= '1';
          --Make sure the I2C system started.
          if (cmd_busy_in = '1') then
            cur_state            <= RTC_STATE_CONF_WAIT;
             cmd_start_out         <= '0';
          end if;
        end if;
          
      when RTC_STATE_CONF_WAIT    =>
       
        if (cmd_busy_in = '0') then
          i2c_req_out           <= '0';
          cur_state            <= RTC_STATE_WAIT_START;
          startup_done_out     <= '1';
        end if;
      
      when RTC_STATE_TOD_GET_SETUP   =>

      if (cmd_busy_in = '0') then
        i2c_req_out           <= '1';
        cmd_offset_out        <= to_unsigned(I2C_RTC_GetTime_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_RTC_GetTime_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
        cur_state            <= RTC_STATE_TOD_GET;      
      end if;


      when RTC_STATE_TOD_GET    =>
      if (i2c_rcv_in = '1') then
        cmd_start_out         <= '1';
        cur_state            <= RTC_STATE_TOD_GET_WAIT;
      end if;

      when RTC_STATE_TOD_GET_WAIT =>
      
      if (cmd_busy_in = '1') then 
        cmd_start_out         <= '0';
        cur_state            <= state_init_cmd_e;
        next_state            <= RTC_STATE_TOD_GET_READ_SETUP;
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
        
        
      when RTC_STATE_TOD_GET_READ_SETUP    =>
        mem_read_en_signal_b      <= '1';

        mem_address_signal_b      <=  RESIZE (read_offset,
                                             next_data_address'length) +
                                     read_offset_g ;
                                     
        byte_count                <= TO_UNSIGNED (0, byte_count'length) ; 
          if ( cmd_busy_in = '0') then 
            cur_state            <= RTC_STATE_TOD_GET_READ;
        end if;
      
      when RTC_STATE_TOD_GET_READ    =>
        if (byte_count = I2C_RTC_GetTime_rdlen) then
          cur_state     <= final_state;
          tod_out       <= time_of_day;
          tod_get_valid_out   <= '1';
          mem_read_en_signal_b     <= '0' ;
          i2c_req_out               <= '0';
          
        else
        --Low order bit shows up first on the I2C bus.
          time_of_day <= mem_datafrom_signal_b_in & time_of_day(I2C_RTC_GetTime_rdlen*8-1 downto 8) ;
          byte_count  <= byte_count + 1 ;
          mem_address_signal_b      <=  mem_address_signal_b + 1;
        end if;
        

        --Check TOD against compile time. 
      when RTC_STATE_TOD_STARTUP_CHECK    =>
        
        if ( time_of_day > std_logic_vector(to_unsigned(compile_timestamp_c,time_of_day'length))) then 
        rtc_sec_out <= unsigned(time_of_day);
        rtc_sec_load_out <= '1';
        cur_state     <= RTC_STATE_CONF;
        else
        
        cur_state     <= RTC_STATE_CONF;
        
        end if;
        

        --Idea here.
        --Grab all the constants. 
        --Write the value (TOD) in memory
        --Enage the I2C core.
        --Set ALARM
      when RTC_STATE_ALARM_READ_CONSTANTS_SETUP   =>
      
        cmd_offset_out        <= to_unsigned(I2C_RTC_SetAlarm_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_RTC_SetAlarm_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length); 
        i2c_req_out           <= '1' ;        
        if (i2c_rcv_in = '1') then 
           cur_state            <= state_init_cmd_e;
           next_state           <= RTC_STATE_ALARM_SET_WRITE_SETUP;
        end if;
          

        
        
      when RTC_STATE_ALARM_SET_WRITE_SETUP    =>
      

        mem_write_en_signal_b     <= '1';
        --We only want to fill in the tod and not the RTC address. 
        --1 byte I2C device address 4 bytes tod. 
        mem_address_signal_b      <=  RESIZE (write_offset + 1,
                                             next_data_address'length) +
                                     write_offset_g ;
        mem_datato_signal_b       <= alarm(7 downto 0);
        alarm                     <= x"00" & alarm(I2C_RTC_SetAlarm_wrlen*8-1 downto 8);
        byte_count                <= TO_UNSIGNED (1, byte_count'length) ;
        cur_state                 <= RTC_STATE_ALARM_SET_WRITE;

        
        
        
      when RTC_STATE_ALARM_SET_WRITE    =>
        if (byte_count = I2C_RTC_SetAlarm_wrlen) then
          cur_state            <= RTC_STATE_ALARM_SET_SETUP;
          mem_write_en_signal_b     <= '0' ;
        else
          mem_datato_signal_b <= alarm(7 downto 0);
          alarm <= x"00" & alarm(I2C_RTC_SetAlarm_wrlen*8-1 downto 8);
          
         
          
          
          byte_count  <= byte_count + 1 ;
          mem_address_signal_b      <=  mem_address_signal_b + 1;
        end if;
        
      when RTC_STATE_ALARM_SET_SETUP  =>

     
       
        cmd_offset_out        <= to_unsigned(I2C_RTC_SetAlarm_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_RTC_SetAlarm_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
        cur_state            <= RTC_STATE_ALARM_SET;      



      when RTC_STATE_ALARM_SET   =>
      if (i2c_rcv_in = '1') then 
        cmd_start_out         <= '1';
        cur_state             <= RTC_STATE_ALARM_SET_WAIT;
      end if;
      
      when RTC_STATE_ALARM_SET_WAIT =>
      cmd_start_out         <= '0';
      if (cmd_busy_in = '1') then 
        cur_state           <= RTC_STATE_ALARM_SET_WAIT_DONE;
      end if;

      when RTC_STATE_ALARM_SET_WAIT_DONE    =>
      if (cmd_busy_in = '0') then 
      --Here I branch back to register config.
      --To reset the WACE bit/and the AF bit. 
        cur_state            <= RTC_STATE_CONF;
        alarm_set_done_out  <= '1';
      --Set the interrupt enable. 
      --Once per startup. 
      --Shutdown code should disable it. 
        rtc_interrupt_enable <= '1';
        i2c_req_out     <= '0';
      end if;
    
      --Idea here.
      --Grab all the constants. 
      --Write the value (TOD) in memory
      --Enage the I2C core.
      --Set TOD
      when RTC_STATE_TOD_READ_CONSTANTS_SETUP   =>
      
        cmd_offset_out        <= to_unsigned(I2C_RTC_SetTime_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_RTC_SetTime_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length); 
        i2c_req_out           <= '1' ;        
        if (i2c_rcv_in = '1') then 
           cur_state            <= state_init_cmd_e;
           next_state           <= RTC_STATE_TOD_SET_WRITE_SETUP;
        end if;
          

        
        
      when RTC_STATE_TOD_SET_WRITE_SETUP    =>
      

        mem_write_en_signal_b      <= '1';
        --Skip the address in the mif file, which will be written out. 
        mem_address_signal_b      <=  RESIZE (write_offset + 1,
                                             next_data_address'length) +
                                     write_offset_g ;
        mem_datato_signal_b <= time_of_day(7 downto 0);
        time_of_day <= x"00" & time_of_day(I2C_RTC_SetTime_wrlen*8-1 downto 8);
        byte_count                <= TO_UNSIGNED (1, byte_count'length) ;
        cur_state            <= RTC_STATE_TOD_SET_WRITE;

        
        
        
      when RTC_STATE_TOD_SET_WRITE    =>
        if (byte_count = I2C_RTC_SetTime_wrlen) then
          cur_state            <= RTC_STATE_TOD_SET_SETUP;
          mem_write_en_signal_b     <= '0' ;
          
        else
          mem_datato_signal_b <= time_of_day(7 downto 0);
          time_of_day <= x"00" & time_of_day(I2C_RTC_SetTime_wrlen*8-1 downto 8);
          byte_count  <= byte_count + 1 ;
          mem_address_signal_b      <=  mem_address_signal_b + 1;
        end if;
        
      when RTC_STATE_TOD_SET_SETUP  =>


        cmd_offset_out        <= to_unsigned(I2C_RTC_SetTime_cmd,cmd_offset_out'length);
        cmd_offset            <= to_unsigned(I2C_RTC_SetTime_cmd,cmd_offset_out'length);
        cmd_count_out         <= to_unsigned(1,cmd_count_out'length);
        cur_state            <= RTC_STATE_TOD_SET;      



      when RTC_STATE_TOD_SET   =>
      
      --if (i2c_rcv_in = '1') then
        cmd_start_out         <= '1';
        cur_state            <= RTC_STATE_TOD_SET_WAIT;
      --end if;
      
      
      when RTC_STATE_TOD_SET_WAIT =>
      
      if (cmd_busy_in = '1') then 
        cmd_start_out         <= '0';
        cur_state            <= RTC_STATE_TOD_SET_WAIT_DONE;
      end if;

      when RTC_STATE_TOD_SET_WAIT_DONE    =>
      if (cmd_busy_in = '0') then 
        cur_state           <= RTC_STATE_WAIT_START;
        tod_set_done_out    <= '1';
        i2c_req_out         <= '0';
      end if;
      







      end case ;
  end if ;
end process rtc_state_machine ;


  


end behavior ;
