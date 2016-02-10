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
------------------------------------------------------------------------------

--Usage Instructions and Description.


library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.




LIBRARY GENERAL ;     
USE GENERAL.GPS_Clock_pkg.ALL; 




entity i2c_top_level is

  Port (
    clk               : in  std_logic ;
    rst_n             : in  std_logic ;
    
    sda_out 			        : out std_logic;  
    scl_out			          : out std_logic;
    
    scl_dir             : in std_logic;
    sda_dir             : in std_logic;
    
    sda_in 			        : in std_logic;  
    scl_in		          : in std_logic

  ) ;

end entity i2c_top_level ;



architecture behavior of i2c_top_level is


--I'm not going to put in the allocator into this code. 
--I know that it works..........worked?


    constant mem_bits_g            : natural   := 10 ;
  
    signal i2c_req_signal             : std_logic ;
    signal i2c_rcv_signal             : std_logic ;
    signal i2c_ena_signal             : std_logic ;
    signal i2c_addr_signal            : std_logic_vector (6 downto 0) ;
    signal i2c_rw_signal              : std_logic ;
    signal i2c_data_wr_signal         : std_logic_vector (7 downto 0) ;
    signal i2c_busy_signal            : std_logic ;
    signal i2c_data_rd_signal         : std_logic_vector (7 downto 0) ;
    signal i2c_ack_error_signal       : std_logic ;
    
    signal mem_clk_a                    :std_logic;
    signal mem_address_signal_a         : unsigned (mem_bits_g-1 downto 0) ;
    signal mem_datafrom_signal_a        : std_logic_vector (7 downto 0) ;
    signal mem_datato_signal_a          : std_logic_vector (7 downto 0) ;
    signal mem_read_en_signal_a         : std_logic ;
    signal mem_write_en_signal_a        : std_logic ;
    

    signal mem_clk_b                    : std_logic;
    signal mem_address_signal_b         : unsigned (mem_bits_g-1 downto 0) ;
    signal mem_datafrom_signal_b        : std_logic_vector (7 downto 0) ;
    signal mem_datato_signal_b          : std_logic_vector (7 downto 0) ;
    signal mem_read_en_signal_b         : std_logic ;
    signal mem_write_en_signal_b        : std_logic ;

    signal cmd_offset_signal          :   unsigned (mem_bits_g-1 downto 0) ;
    signal cmd_count_signal           :   unsigned (7 downto 0) ;
    signal cmd_start_signal           :   std_logic ;
    signal cmd_busy_signal            :   std_logic ;
    
    signal inv_clk : std_logic;
    signal reset    : std_logic;
    signal sda_top    : std_logic;
    signal scl_top    : std_logic;

  
component i2c_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 1_000_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component i2c_master;


component I2C_cmds IS
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
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
END component I2C_cmds;


component batmon_inquire is

  Generic (
  clk_freq_g               : natural  := 50E6;
  update_interval_ms_g     : natural  := 10;
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
    
    mem_req_out           : out   std_logic ;
    mem_rcv_in            : in    std_logic ;
    
    voltage_mv_out            : out   std_logic_vector (15 downto 0)
  ) ;

end component batmon_inquire ;

component I2C_IO is

  Generic (
    clk_freq_g            : natural   := 1e6 ;
    i2c_freq_g            : natural   := 4e5 ;
    mem_bits_g            : natural   := 10 ;
    cmd_offset_g          : natural   := 0 ;
    write_offset_g        : natural   := 256 ;
    read_offset_g         : natural   := 512
  ) ;
  Port (
    clk                   : in    std_logic ;
    reset                 : in    std_logic ;

    i2c_req_out           : out   std_logic ;
    i2c_rcv_in            : in    std_logic ;
    i2c_ena_out           : out   std_logic ;
    i2c_addr_out          : out   std_logic_vector (6 downto 0) ;
    i2c_rw_out            : out   std_logic ;
    i2c_data_wr_out       : out   std_logic_vector (7 downto 0) ;
    i2c_busy_in           : in    std_logic ;
    i2c_data_rd_in        : in    std_logic_vector (7 downto 0) ;
    i2c_ack_error_in      : in    std_logic ;

    mem_req_out           : out   std_logic ;
    mem_rcv_in            : in    std_logic ;
    mem_address_out       : out   unsigned (mem_bits_g-1 downto 0) ;
    mem_datafrom_in       : in    std_logic_vector (7 downto 0) ;
    mem_datato_out        : out   std_logic_vector (7 downto 0) ;
    mem_read_en_out       : out   std_logic ;
    mem_write_en_out      : out   std_logic ;

    cmd_offset_in         : in    unsigned (mem_bits_g-1 downto 0) ;
    cmd_count_in          : in    unsigned (7 downto 0) ;
    cmd_start_in          : in    std_logic ;
    cmd_busy_out          : out   std_logic

  ) ;

end component I2C_IO ;
  

    

  

begin
 
 
--Unidirectional test for now.  
sda_out <= sda_top;
scl_out <= scl_top;


--Simulate pull up in modelsim. 
scl_out <= '1' when scl_top = 'Z' else scl_top;
sda_out <= '1' when sda_top = 'Z' else sda_top;

tri_state_sda: process(sda_dir)
begin
    if (sda_dir = '1') then
        sda_top   <=    sda_in ;
    else
        sda_top   <=    'Z' ;
    end if;
end process;

tri_state_scl: process(scl_dir)
begin
    if (scl_dir = '1') then
        scl_top   <=    scl_in ;
    else
        scl_top   <=    'Z' ;
    end if;
end process;


reset <= not rst_n;
inv_clk <= clk;

i2c_cmds_i0: I2C_cmds 
	PORT MAP
	(
		address_a		=> std_logic_vector(mem_address_signal_a),
		address_b		=> std_logic_vector(mem_address_signal_b),
		clock_a		  => inv_clk,
		clock_b		  => inv_clk,
		data_a		  => mem_datato_signal_a,
		data_b		  => mem_datato_signal_b,
		rden_a		  => mem_read_en_signal_a,
		rden_b		  => mem_read_en_signal_b,
		wren_a		  => mem_write_en_signal_a,
		wren_b		  => mem_write_en_signal_b,
		q_a		      => mem_datafrom_signal_a,
		q_b		      => mem_datafrom_signal_b
	);




 i2c_master_i0 :i2c_master 

  PORT MAP(
    clk         => clk,
    reset_n     => rst_n,
    ena         => i2c_ena_signal,
    addr        => i2c_addr_signal,
    rw          => i2c_rw_signal,
    data_wr     => i2c_data_wr_signal,
    busy        => i2c_busy_signal,
    data_rd     => i2c_data_rd_signal,
    ack_error   => i2c_ack_error_signal,
    sda         => sda_top,
    scl         => scl_top
    
  );


i2c_io_i0: I2C_IO

  Generic Map (
    clk_freq_g           =>  50e6,
    i2c_freq_g            =>  1e6 
    -- mem_bits_g            : natural   := 9 ;
    -- cmd_offset_g          : natural   := 0 ;
    -- write_offset_g        : natural   := 128 ;
    -- read_offset_g         : natural   := 256
  ) 
  Port Map (
    clk                   => clk,
    reset                 => reset, 

    --i2c_req_out           => i2c_req_signal
    i2c_rcv_in            => '1',
    i2c_ena_out           => i2c_ena_signal,
    i2c_addr_out          => i2c_addr_signal,
    i2c_rw_out            => i2c_rw_signal,
    i2c_data_wr_out       => i2c_data_wr_signal,
    i2c_busy_in           => i2c_busy_signal,
    i2c_data_rd_in        => i2c_data_rd_signal,
    i2c_ack_error_in      => i2c_ack_error_signal,

   -- mem_req_out           => mem_req_signal_b
    mem_rcv_in            => '1',
    mem_address_out       => mem_address_signal_a,
    mem_datafrom_in       => mem_datafrom_signal_a,
    mem_datato_out        => mem_datato_signal_a,
    mem_read_en_out       => mem_read_en_signal_a,
    mem_write_en_out      =>  mem_write_en_signal_a,

    cmd_offset_in        =>  cmd_offset_signal,
    cmd_count_in         =>  cmd_count_signal,
    cmd_start_in         =>  cmd_start_signal,
    cmd_busy_out         =>  cmd_busy_signal

  ) ;


bm_inquire_i0 : batmon_inquire
  Generic Map (
  
    simulate_g  => '1'
  
  )
  Port Map (
    clk                  => clk,
    rst_n                => rst_n,
    
    startup              => '1',

    cmd_offset_out       => cmd_offset_signal,
    cmd_count_out        => cmd_count_signal,
    cmd_start_out        => cmd_start_signal,
    cmd_busy_in          => cmd_busy_signal,
    
    
    mem_clk                       => mem_clk_b,
    mem_address_signal_b_out          => mem_address_signal_b,
    mem_datafrom_signal_b_in         => mem_datafrom_signal_b,
    mem_datato_signal_b_out           => mem_datato_signal_b,
    mem_read_en_signal_b_out          => mem_read_en_signal_b,
    mem_write_en_signal_b_out         => mem_write_en_signal_b,
    
   -- mem_req_out           : out   std_logic ;
    mem_rcv_in            => '1'
    
    --voltage_mv            : out   std_logic (15 downto 0);
 

  ) ;


  


end behavior ;
