----------------------------------------------------------------------------
--
--! @file       I2C_IO.vhd
--! @brief      I2C bus I/O processing module.
--! @details    This module executes I2C I/O using a general command
--!             structure stored in memory.
--! @author     Emery Newlon
--! @date       January 2015
--! @copyright  Copyright (C) 2015 Ross K. Snider and Emery L. Newlon
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
--  Emery Newlon
--  Electrical and Computer Engineering
--  Montana State University
--  610 Cobleigh Hall
--  Bozeman, MT 59717
--  emery.newlon@msu.montana.edu
--
----------------------------------------------------------------------------

library IEEE ;                      --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;       --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;          --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;            --! Real number functions.

library GENERAL ;                   --! General libraries.
use GENERAL.UTILITIES_PKG.ALL ;

library WORK ;                      --! Local libraries.
use WORK.I2C_CMDS_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      I2C bus I/O processing module.
--! @details    This module executes I2C I/O using a general command
--!             structure stored in memory.  The data is sent and received
--!             in a set of subcommands to prevent the data streams from
--!             becoming too long for the device to handle.  Writes are done
--!             before reads.
--!             This structure format is:
--!   1 byte      Subcmd Delay    Microseconds to delay between subcommands.
--!   3 bytes     Cmd Delay       Microseconds to delay after the command.
--!   1 byte      I2C Address     Address of the device to talk to.
--!   1 byte      Write Length    Number of bytes to write.
--!   1 byte      Write Offset    Offset from start of write section to
--!                               write from.
--!   1 byte      Write Max       Maximum number of bytes to write in a
--!                               subcommand.
--!   1 byte      Read Length     Number of bytes to read after writing.
--!   1 byte      Read Offset     Offset from start of read section to
--!                               read into.
--!   1 byte      Read Max        Maximum number of bytes to read in a
--!                               subcommand.
--!
--! @param      clk_freq_g        Frequency of the process clock in cycles
--!                               per second.
--! @param      i2c_freq_g        Frequency of the I2C bus clock in cycles
--!                               per second.
--! @param      mem_bits_g        Number of bits of a memory address.
--! @param      cmd_offset_g      Offset of the command table in memory.
--! @param      write_offset_g    Offset of bytes to write in memory.
--! @param      read_offset_g     Offset of bytes to read into memory.
--! @param      clk               Clock to run processes with.
--! @param      reset             True to reset the module.
--! @param      i2c_req_out       Request and hold the I2C bus when one,
--!                               release it when 0.
--! @param      i2c_rcv_in        I2C bus allocation request granted.
--! @param      i2c_ena_out       Enable an I2C bus transaction via the
--!                               i2c_master module.
--! @param      i2c_addr_out      I2C device address for this transaction.
--! @param      i2c_rw_out        I2C bus read = '1' or write = '0'.
--! @param      i2c_data_wr_out   I2C bus byte to write next.
--! @param      i2c_busy_in       I2C bus is busy with the transaction.
--! @param      i2c_data_rd_in    I2C bus byte read last.
--! @param      i2c_ack_error_in  I2C bus acknowledge failed.
--! @param      mem_req_out       Request and hold the memory block
--!                               when '1', release it when '0'.
--! @param      mem_rcv_in        Memory allocation request granted.
--! @param      mem_address_out   Address of next byte to access in memory.
--! @param      mem_datafrom_in   Data byte read from memory.
--! @param      mem_datato_out    Data byte written to memory.
--! @param      mem_read_en_out   Carry out a memory read.
--! @param      mem_write_en_out  Carry out a memory write.
--! @param      cmd_offset_in     Offset of the first command to execute.
--! @param      cmd_count_in      Number of sequencial commands to execute.
--! @param      cmd_start_in      When '1' start executing a command
--!                               sequence.
--! @param      cmd_busy_out      Set to '1' when executing a command.
--!                               Cleared when the command done executing.
--
----------------------------------------------------------------------------

entity I2C_IO is

  Generic (
    clk_freq_g            : natural   := 1e6 ;
    i2c_freq_g            : natural   := 4e5 ;
    mem_bits_g            : natural   := 9 ;
    cmd_offset_g          : natural   := 0 ;
    write_offset_g        : natural   := 128 ;
    read_offset_g         : natural   := 256
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

    cmd_offset_in         : in    unsigned (mem_bites_g-1 downto 0) ;
    cmd_count_in          : in    unsigned (7 downto 0) ;
    cmd_start_in          : in    std_logic ;
    cmd_busy_out          : out   std_logic

  ) ;

end entity I2C_IO ;


architecture rtl of I2C_IO is

  --  Find the conversion from microseconds to clock cycles.  The
  --  divide by 1 million microseconds per second is done in two parts to
  --  prevent the cycle factor shift multiply results from exceeding the
  --  size of number that will fit in a natural (32 bits).

  constant cycle_factor_shift_c : natural := 10 ;

  constant cycle_factor_mult_c  : natural :=
              ((clk_freq_g / 1000) * (2 ** cycle_factor_shift)) / 1000 ;

  signal subcmd_delay_cycles    : unsigned (31 downto 0) ;
  signal cmd_delay_cycles       : unsigned (31 downto 0) ;

  signal delay_count            : unsigned (31 downto 0) ;

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
              natural (trunc (((real) (cmd_struct_len_c + 7)) / 8.0)) ;

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

  --  I2C control signals.

  signal i2c_latch            : std_logic ;

  --  Command processing signals.

  signal cmd_number           : unsigned (7 downto 0) ;

  signal nextcmd_address      : unsigned (mem_bits_g-1 downto 0) ;

  --  Data processing signals.

  signal byte_count           : unsigned (7 downto 0) ;
  signal byte_max             : unsigned (7 downto 0) ;

  signal next_data_address    : unsigned (mem_bits_g-1 downto 0) ;

  signal save_count           : unsigned (byte_count'length-1 downto 0) ;
  signal save_address         : unsigned (next_data_address'length-1
                                          downto 0) ;

  --  Command processing states.

  type cmd_states_t is (
    state_wait_e,
    state_mem_alloc_e,
    state_init_cmd_e,
    state_read_cmd_e,
    state_do_writes_e,
    state_write_busy_e,
    state_do_reads_e,
    state_read_busy_e,
    state_save_byte_e,
    state_cmdwait_e
  ) ;

  signal cur_state            : cmd_states_t ;

begin

  --  Output locally readable signals.

  i2c_ena_out             <= i2c_latch ;

  --  Continuously calculate delays in cycles to handle calculations that
  --  are much longer than single clock cycles.

  subcmd_delay_cycles     <=
              RESIZE (SHIFT_RIGHT (subcmd_delay *
                                   const_unsigned (cycle_factor_mult_c),
                                   cycle_factor_shift_c),
                      subcmd_delay_cycles'length) ;

  cmd_delay_cycles        <=
              RESIZE (SHIFT_RIGHT (cmd_delay *
                                   const_unsigned (cycle_factor_mult_c),
                                   cycle_factor_shift_c),
                      cmd_delay_cycles'length) ;


  --------------------------------------------------------------------------
  --  Command Processing.
  --------------------------------------------------------------------------

  cmd_process : process (reset, clk)
    variable byte_address : unsigned (mem_bits_g-1 downto 0) ;
  begin

    if (reset = '1')
      cur_state         <= state_wait_e ;
      mem_req_out       <= '0' ;
      i2c_req_out       <= '0' ;
      i2c_latch         <= '0' ;
      cmd_busy_out      <= '0' ;
      save_count        <= (others => '0') ;
      save_address      <= (others => '0') ;

    elsif (rising_edge (clk)) then

      --  Limit memory writes to a single clock cycle.

      mem_write_en_out  <= '0' ;

      --  Proceed through the command processing states.

      case (cur_state)

        --  Wait until a command sequence is started.  Then allocate the
        --  I2C bus.

        when state_wait_e       =>
          cmd_busy_out          <= '0' ;
          i2c_req_out           <= '0' ;
          mem_req_out           <= '0' ;
          mem_read_en_out       <= '0' ;

          if (cmd_start_in = '1') then
            cur_state           <= state_mem_alloc_e ;
            cmd_busy_out        <= '1' ;
            i2c_req_out         <= '1' ;
          end if ;

        --  Allocate memory when the I2C bus has been allocated.

        when state_mem_alloc_e  =>

          if (i2c_rcv_in = '1') then
            cur_state           <= state_init_cmd_e ;
            mem_req_out         <= '1' ;
          end if ;

        --  Initialize the command sequence to execute.

        when state_init_cmd_e   =>

          if (mem_rcv_in = '1') then
            cur_state           <= state_read_cmd_e ;
            cmd_number          <= (others => '0') ;
            byte_count          <= (others => '0') ;
            byte_address        := cmd_offset_in +
                                   const_unsigned (cmd_offset_g) ;
            mem_address_out     <= byte_address ;
            mem_read_en_out     <= '1' ;
            nextcmd_address     <= byte_address + 1 ;
          end if ;

        --  Read the command information.  New bytes are added at the top
        --  and shifted downward.

        when state_read_cmd_e   =>
          if (byte_count /= cmd_struct_bytes_c) then
            byte_count          <= byte_count + 1 ;

            cmd_struct (cmd_struct_len_c-9 downto 0)                  <=
                              cmd_struct (cmd_struct_len_c-1 downto 8) ;
            cmd_struct (cmd_struct_len_c-1 downto cmd_struct_len_c-8) <=
                              mem_data_from_in ;

            mem_address_out     <= nextcmd_address ;
            nextcmd_address     <= nextcmd_address + 1 ;
          else
            cmd_number          <= cmd_number + 1 ;

            --  Start writing data out.

            cur_state           <= state_do_writes_e ;
            byte_address        := RESIZE (write_offset,
                                           byte_address'length) +
                                   write_offset_g ;
            mem_address_out     <= byte_address ;
            next_data_address   <= byte_address + 1 ;
            byte_count          <= (others => '0') ;
            byte_max            <= write_max ;
            delay_count         <= (others => '0') ;
            i2c_addr_out        <=
                    std_logic_vector (i2c_address (6 downto 0)) ;
            i2c_rw_out          <= '0' ;
          end if ;

        --  Start writing data to the I2C bus.  When the first write of a
        --  subcommand is started the next can be queued.  When the first
        --  finishes the second will be started immediatly as long as the
        --  latch signal is still high.  The latch signal must be low after
        --  the start of the last write of the subcommand or a new write
        --  would be started after the last one finished.
        --  To accomplish this checks to determine if the subcommand is on
        --  the last byte must be done before waiting for that byte and the
        --  latch line dropped if it is the last one.  All this is done by
        --  starting writes after all the checks have been made.

        when state_do_writes_e  =>

          if (mem_rcv_in = '1') then
            if (i2c_latch = '1' and i2c_ack_error_in = '1') then
              --  Redo the subcommand.

              byte_count          <= save_count ;
              next_data_address   <= save_address ;
              mem_address_out     <= save_address - 1 ;
              mem_read_en_out     <= '1' ;
              i2c_latch           <= '0' ;

            elsif (byte_count = write_length) then
              --  Wait for subcommand delay.

              if (i2c_latch = '1') then
                cur_state         <= state_write_busy_e ;
                i2c_latch         <= '0' ;
              else

                --  All writes are done.  Start doing reads.

                cur_state         <= state_do_reads_e ;
                mem_read_en_out   <= '0' ;
                next_data_address <= RESIZE (read_offset,
                                             next_data_address'length) +
                                     read_offset_g ;
                byte_count        <= (others => '0') ;
                byte_max          <= read_max ;
                i2c_rw_out        <= '1' ;
              end if ;

            elsif (byte_count = byte_max) then
                --  Send additional data in a new subcommand.

                cur_state         <= state_write_busy_e ;
                byte_max          <= byte_max + write_max ;
                i2c_latch         <= '0' ;
              end if ;

            else
              --  Send a byte to the I2C bus.

              if (i2c_latch = '1') then
                cur_state         <= state_write_busy_e ;
              else
                save_count        <= byte_count ;
                save_address      <= next_data_address ;
              end if ;

              i2c_data_wr_out     <= mem_data_from_in ;
              i2c_latch           <= '1' ;
              byte_count          <= byte_count + 1 ;
              mem_address_out     <= next_data_address ;
              next_data_address   <= next_data_address + 1 ;
            end if ;
          end if ;

        --  Wait until the write not busy.

        when state_write_busy_e =>
          mem_req_out           <= '0' ;
          mem_read_en_out       <= '0' ;

          if (i2c_ack_error_in = '1') then
            cur_state           <= state_do_write_e ;
            i2c_latch           <= '1' ;
            mem_req_out         <= '1' ;

          elsif (i2c_busy_in = '0') then
              --  Wait for subcommand delay when this was the last write.

            if (i2c_latch = '0' and
                (delay_count /= subcmd_delay_cycles)) then
              delay_count       <= delay_count + 1 ;
            else
              delay_count       <= (others => '0') ;

              cur_state         <= state_do_write_e ;
              mem_req_out       <= '1' ;
              mem_read_en_out   <= '1' ;
            end if ;
          end if ;

        --  Start reading data from the I2C bus.  Checks to determine if
        --  this is the last read of a subcommand are made before waiting
        --  for the read to finish.  If it is the last one the latch is
        --  clear so that another read is not started when this one is
        --  done.  Otherwise the latch line is left high to continue a
        --  multi-byte read operation.

        when state_do_reads_e  =>

          if (mem_rcv_in = '1') then
            if (byte_count = read_length) then
              --  Wait for the last read to finish.

              if (i2c_latch = '1') then
                cur_state         <= state_read_busy_e ;
                i2c_latch         <= '0' ;
              else

                --  All reads are done.  Do command wait.

                cur_state         <= state_cmdwait_e ;
              end if ;

            elsif (byte_count = byte_max) then
                --  Read additional data in a new subcommand.

                cur_state         <= state_read_busy_e ;
                byte_max          <= byte_max + read_max ;
                i2c_latch         <= '0' ;
              end if ;

            elsif (i2c_latch = '1') then
              cur_state           <= state_read_busy_e ;

            else
              --  Get a byte from the I2C bus.

              i2c_latch           <= '1' ;
              byte_count          <= byte_count + 1 ;
            end if ;
          end if ;

        --  Wait until the bus is not busy.

        when state_read_busy_e =>
          mem_req_out             <= '0' ;

          if (i2c_busy_in = '0') then
            if (i2c_latch = '0' and
                (delay_count /= subcmd_delay_cycles)) then

              --  Wait for subcommand delay.

              delay_count         <= delay_count + 1 ;
            else
              cur_state           <= state_save_byte_e ;
              delay_count         <= (others => '0') ;

              --  Save the byte read immediately even if the memory bus is
              --  not yet available.  The latch line is cleared indicating
              --  that the read has finished.  It will be set high again
              --  immediately if more reads need to be done for the
              --  subcommand.

              mem_req_out         <= '1' ;
              mem_datato_out      <= i2c_data_rd_in ;
              i2c_latch           <= '0' ;
            end if ;
          end if ;

        --  Save the last byte read.

        when state_save_byte_e  =>
          if (mem_rcv_in = '1') then
            cur_state             <= state_do_read_e ;
            mem_write_en          <= '1' ;
            mem_address_out       <= next_data_address ;
            next_data_address     <= next_data_address + 1 ;
          end if ;

        --  Carry out delay after a command has finished.

        when state_cmdwait_e    =>
          mem_req_out             <= '0' ;

          if (delay_count /= cmd_delay_cycles) then
            delay_count           <= delay_count + 1 ;
          else
            --  Start the next command if they have not all been done.

            if (cmd_number /= cmd_count_in) then
              mem_req_out         <= '1' ;

              if (mem_rcv_in = '1') then
                cur_state         <= state_read_cmd_e ;
                byte_count        <= (others => '0') ;
                mem_read_en_out   <= '1' ;
                mem_address_out   <= nextcmd_address ;
                nextcmd_address   <= nextcmd_address + 1 ;
              end if ;
            else
              cur_state           <= state_wait_e ;
            end if ;
          end if ;

      end ;
    end if ;
  end process cmd_process ;

end architecture rtl ;
