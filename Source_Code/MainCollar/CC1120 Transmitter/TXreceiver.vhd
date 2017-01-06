----------------------------------------------------------------------------
--
--! @file       TXreceiver.vhd
--! @brief      Receive TXRX messages.
--! @details    Receive and process messages from Transmit/Receiver.
--! @author     Emery Newlon
--! @date       December 2016
--! @copyright  Copyright (C) 2016 Ross K. Snider and Emery L. Newlon
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


library IEEE ;                  --  Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --  Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --  Use numeric standard.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;
use GENERAL.GPS_CLOCK_PKG.ALL ;
use GENERAL.TXRX_RECEIVED_PKG.ALL ;


----------------------------------------------------------------------------
--
--! @brief      Receive TXRX messages.
--! @details    Receive and process messages from Transmit/Receiver.
--!
--! @param      sys_addr_bits_g   Number of bits in the system address.
--! @param      addr_bits_g       Number of bits used in memory address.
--! @param      data_bits_g       Number of bits wide the memory data is.
--! @param      reset             Reset the module to initial state.
--! @param      clk               Clock used for logic.
--! @param      sys_address_in    The system address of this device.
--! @param      rcv_start_in      A message has been received.
--! @param      rcv_done_out      The message has been processed.
--! @param      authreq_out       Request access to the authenticator.
--! @param      authrcv_in        Authenticator access received.
--! @param      authenticate_out  Authenticate the following series of
--! @param                        bytes.  This goes high to start
--!                               authentication and low again when all
--!                               bytes have been processed.
--! @param      authdone_in       Authentication of the message is done.
--!                               This will go high when the authentication
--!                               is terminated and the authentication code
--!                               is ready.  It will stay high until the
--!                               next authentication begins.
--! @param      authbyte_out      Next byte to add to the authenticaion
--!                               string.
--! @param      authnext_out      The next byte is ready.  This is initially
--!                               set to 0 when authentication starts and
--!                               remains 0 until the done indicator goes
--!                               to 0.  It then goes high indicating
--!                               a byte is ready to process.  It stays
--!                               high until the byte has been processed,
--!                               then goes low until the ready indicator
--!                               also goes low.  The next byte will be
--!                               processed in the same way or
--!                               authentication will stop if no more bytes
--!                               are in the message.
--! @param      authready_in      The authenticator is ready for the next
--!                               byte.  It is initially 0 until a byte is
--!                               received and has been processed.  At that
--!                               point it goes high until the next byte
--!                               indicator goes low.  It then goes low
--!                               and remains so until the next byte has
--!                               been received and processed.
--! @param      authcode_in       Authentication code for the message.
--! @param      memreq_out        Requests access to memory.
--! @param      memrcv_in         Received access to memory.
--! @param      mem_clk           Clock used to access memory.
--! @param      mem_read_en_out   Carry out a memory read.
--! @param      mem_address_out   Address of memory to access.
--! @param      mem_datafrom_in   Data read from memory.
--! @param      listen_out        The current listen mode.
--! @param      release_out       Release the device.
--! @param      busy_out          The component is busy processing.
--
----------------------------------------------------------------------------

entity TXreceiver is
  Generic (
    sys_addr_bits_g   : natural := 32 ;
    addr_bits_g       : natural := 10 ;
    data_bits_g       : natural := 8 ;
    auth_bits_g       : natural := txrx_msg_auth_bits_c
  ) ;
  Port (
    reset             : in    std_logic ;
    clk               : in    std_logic ;
    sys_address_in    : in    std_logic_vector (sys_addr_bits_g-1
                                                downto 0) ;
    rcv_start_in      : in    std_logic ;
    rcv_done_out      : out   std_logic ;
    authreq_out       : out   std_logic ;
    authrcv_in        : in    std_logic ;
    authenticate_out  : out   std_logic ;
    authdone_in       : in    std_logic ;
    authbyte_out      : out   std_logic_vector (data_bits_g-1 downto 0) ;
    authnext_out      : out   std_logic ;
    authready_in      : in    std_logic ;
    authcode_in       : in    std_logic_vector (auth_bits_g-1 downto 0) ;
    memreq_out        : out   std_logic ;
    memrcv_in         : in    std_logic ;
    mem_clk           : out   std_logic ;
    mem_read_en_out   : out   std_logic ;
    mem_address_out   : out   std_logic_vector (addr_bits_g-1 downto 0) ;
    mem_datafrom_in   : in    std_logic_vector (data_bits_g-1 downto 0) ;
    listen_out        : out   std_logic ;
    release_out       : out   std_logic ;
    busy_out          : out   std_logic
  ) ;
end entity TXreceiver ;


architecture rtl of TXreceiver is

  --  Synchronizers.

  signal sys_address_s    : std_logic_vector (sys_address_in'length-1
                                              downto 0) ;
  signal rcv_start        : std_logic ;
  signal rcv_start_s      : std_logic ;
  signal authrcv          : std_logic ;
  signal authrcv_s        : std_logic ;
  signal authdone         : std_logic ;
  signal authdone_s       : std_logic ;
  signal authready        : std_logic ;
  signal authready_s      : std_logic ;
  signal authcode_s       : std_logic_vector (authcode_in'length-1
                                              downto 0) ;
  signal memrcv           : std_logic ;
  signal memrcv_s         : std_logic ;

  --  Receive and authentication control.

  signal rcv_done         : std_logic ;
  signal authenticate     : std_logic ;
  signal proc_busy        : std_logic ;

  --  Memory access and buffering.

  constant byte_length_tbl_c  : integer_vector :=
  (
    txrx_mp_length_len_c,
    txrx_mh_dstaddr_len_c,
    txrx_mh_srcaddr_len_c,
    txrx_mh_msgid_len_c,
    txrx_mh_msgauth_len_c,
    txrx_mh_msgtype_len_c,
    txrx_ml_listen_len_c,
    txrx_mr_release_len_c
  ) ;

  constant byte_buffer_size_c : natural :=
                  (max_integer (byte_length_tbl_c) + 7) / 8 ;


  signal byte_buffer      : unsigned (byte_buffer_size_c*8-1 downto 0) ;
  signal byte_count       : unsigned (txrx_mp_length_len_c-1 downto 0) ;

  signal mem_address      : unsigned (mem_address_out'length-1 downto 0) ;
  signal mem_datafrom     : std_logic_vector (mem_datafrom_in'length-1
                                              downto 0) ;

  signal data_shift       : std_logic ;

  component Shifter is
    Generic (
      bits_wide_g           : natural   := 32 ;
      shift_bits_g          : natural   :=  8 ;
      shift_right_g         : std_logic := '1'
    ) ;
    Port (
      clk                   : in    std_logic ;
      load_buffer_in        : in    std_logic_vector (bits_wide_g-1
                                                      downto 0) ;
      load_in               : in    std_logic ;
      shift_enable_in       : in    std_logic ;
      buffer_out            : out   std_logic_vector (bits_wide_g-1
                                                      downto 0) ;
      early_lastbits_out    : out   std_logic_vector (shift_bits_g-1
                                                      downto 0) ;
      lastbits_out          : out   std_logic_vector (shift_bits_g-1
                                                      downto 0) ;
      shift_inbits_in       : in    std_logic_vector (shift_bits_g-1
                                                      downto 0)
    ) ;
  end component Shifter ;

  --  Data from the message.

  alias txrx_mp_length      : unsigned (txrx_mp_length_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_mp_length_len_c) ;
  alias txrx_mh_dstaddr     : unsigned (txrx_mh_dstaddr_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_mh_dstaddr_len_c) ;
  alias txrx_mh_msgid       : unsigned (txrx_mh_msgid_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_mh_msgid_len_c) ;
  alias txrx_mh_authcode    : unsigned (txrx_mh_msgauth_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_mh_msgauth_len_c) ;
  alias txrx_mh_type        : unsigned (txrx_mh_msgtype_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_mh_msgtype_len_c) ;
  alias txrx_ml_listen      : unsigned (txrx_ml_listen_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_ml_listen_len_c) ;
  alias txrx_mr_release     : unsigned (txrx_mr_release_len_c-1 downto 0) is
                              byte_buffer (byte_buffer'length-1 downto
                                           byte_buffer'length-
                                           txrx_mr_release_len_c) ;

  signal msg_length         : unsigned (txrx_mp_length'length-1 downto 0) ;
  signal save_msgid         : unsigned (txrx_mh_msgid'length-1 downto 0) ;
  signal last_msgid         : unsigned (txrx_mh_msgid'length-1 downto 0) ;

  --  Process state control.

  type ReceiverState_t is
  (
    rcv_state_wait_e,
    rcv_state_memload_e,
    rcv_state_start_e,
    rcv_state_lencheck_e,
    rcv_state_dstcheck_e,
    rcv_state_dupcheck_e,
    rcv_state_auth_e,
    rcv_state_auth_read_e,
    rcv_state_auth_wait_e,
    rcv_state_auth_next_e,
    rcv_state_auth_done_e,
    rcv_state_type_e,
    rcv_state_listen_e,
    rcv_state_release_e,
    rcv_state_done_e
  ) ;

  signal cur_state        : ReceiverState_t ;
  signal next_state       : ReceiverState_t ;


begin

  --  Clocking.

  mem_clk                     <= not clk ;

  busy_out                    <= proc_busy or rcv_start_in ;

  --  Output local signals.

  rcv_done_out                <= rcv_done ;
  authenticate_out            <= authenticate ;
  mem_address_out             <= std_logic_vector (mem_address) ;

  --  Buffer shifter.

  buffer_shift : component Shifter
    Generic Map (
      bits_wide_g             => byte_buffer'length,
      shift_bits_g            => mem_datafrom_in'length,
      shift_right_g           => '1'
    )
    Port Map (
      clk                     => clk,
      load_buffer_in          => (others => '0'),
      load_in                 => '0',
      shift_enable_in         => data_shift,
      unsigned (buffer_out)   => byte_buffer,
      shift_inbits_in         => mem_datafrom
    ) ;

  --------------------------------------------------------------------------
  --  Receiver process.
  --  Process received messages and set the resulting flags.
  --------------------------------------------------------------------------

  receiver : process (reset, clk)
  begin
    if (reset = '1') then
      proc_busy               <= '0' ;
      rcv_done                <= '0' ;
      authrcv                 <= '0' ;
      authrcv_s               <= '0' ;
      authenticate            <= '0' ;
      rcv_start               <= '0' ;
      rcv_start_s             <= '0' ;
      authdone                <= '0' ;
      authdone_s              <= '0' ;
      authready               <= '0' ;
      authready_s             <= '0' ;
      authcode_s              <= (others => '0') ;
      memrcv                  <= '0' ;
      memrcv_s                <= '0' ;
      sys_address_s           <= (others => '0') ;
      last_msgid              <= (others => '0') ;
      data_shift              <= '0' ;
      authreq_out             <= '0' ;
      memreq_out              <= '0' ;
      mem_read_en_out         <= '0' ;
      listen_out              <= '0' ;
      release_out             <= '0' ;
      cur_state               <= rcv_state_wait_e ;

    --  A synchronizer is used to insure that the request received indicator
    --  is valid and stable.

    elsif (falling_edge (clk)) then
      rcv_start               <= rcv_start_s ;
      authrcv                 <= authrcv_s ;
      authdone                <= authdone_s ;
      authready               <= authready_s ;
      authcode_s              <= authcode_in ;
      memrcv                  <= memrcv_s ;
      sys_address_s           <= sys_address_in ;

    elsif (rising_edge (clk)) then
      rcv_start_s             <= rcv_start_in ;
      authrcv_s               <= authrcv_in ;
      authdone_s              <= authdone_in ;
      authready_s             <= authready_in ;
      memrcv_s                <= memrcv_in ;

      --  Reset all single clock cycle flags.

      data_shift              <= '0' ;

      --  Process messages.

      case cur_state is

        --  Wait until there is something to process.

        when rcv_state_wait_e     =>
          if (rcv_start = '0' and rcv_done = '1') then
            proc_busy         <= '0' ;
            rcv_done          <= '0' ;
          end if ;

          if (rcv_start = '1' and rcv_done = '0') then
            proc_busy         <= '1' ;
            memreq_out        <= '1' ;
            cur_state         <= rcv_state_start_e ;
          end if ;

        --  Load a field from memory.

        when rcv_state_memload_e    =>
          data_shift          <= '1' ;
          mem_datafrom        <= mem_datafrom_in ;

          if (byte_count /= 1) then
            byte_count        <= byte_count - 1 ;
            mem_address       <= mem_address + 1 ;
          else
            mem_read_en_out   <= '0' ;
            cur_state         <= next_state ;
          end if ;

        --  Check the message length.  The length itself is not included
        --  in the length count.

        when rcv_state_start_e      =>
          if (memrcv = '1') then
            byte_count        <= TO_UNSIGNED ((txrx_mp_length_len_c + 7) / 8,
                                              byte_count'length) ;
            mem_address       <= TO_UNSIGNED (txrx_mp_length_str_c / 8,
                                              mem_address'length) ;
            mem_read_en_out   <= '1' ;
            cur_state         <= rcv_state_memload_e ;
            next_state        <= rcv_state_lencheck_e ;
          end if ;

        when rcv_state_lencheck_e   =>
          if (txrx_mp_length < (txrx_mh_length_c + 7) / 8) then
            cur_state         <= rcv_state_done_e ;
          else
            msg_length        <= txrx_mp_length ;

            byte_count        <= TO_UNSIGNED ((txrx_mh_dstaddr_len_c + 7) / 8,
                                              byte_count'length) ;
            mem_address       <= TO_UNSIGNED (txrx_mh_dstaddr_str_c / 8,
                                              mem_address'length) ;
            mem_read_en_out   <= '1' ;
            cur_state         <= rcv_state_memload_e ;
            next_state        <= rcv_state_dstcheck_e ;
          end if ;

        --  Determine if the message is meant for us.

        when rcv_state_dstcheck_e   =>
          if (txrx_mh_dstaddr /= unsigned (sys_address_s)) then
            cur_state         <= rcv_state_done_e ;
          else
            byte_count        <= TO_UNSIGNED ((txrx_mh_msgid_len_c + 7) / 8,
                                              byte_count'length) ;
            mem_address       <= TO_UNSIGNED (txrx_mh_msgid_str_c / 8,
                                              mem_address'length) ;
            mem_read_en_out   <= '1' ;
            cur_state         <= rcv_state_memload_e ;
            next_state        <= rcv_state_dupcheck_e ;
          end if ;

        --  Determine if this message has already been received.

        when rcv_state_dupcheck_e   =>
          if (txrx_mh_msgid <= last_msgid) then
            cur_state         <= rcv_state_done_e ;
          else
            authreq_out       <= '1' ;
            save_msgid        <= txrx_mh_msgid ;

            byte_count        <= TO_UNSIGNED ((txrx_mh_msgauth_len_c + 7) / 8,
                                              byte_count'length) ;
            mem_address       <= TO_UNSIGNED (txrx_mh_msgauth_str_c / 8,
                                              mem_address'length) ;
            mem_read_en_out   <= '1' ;
            cur_state         <= rcv_state_memload_e ;
            next_state        <= rcv_state_auth_e ;
          end if ;

        --  Authenticate the message.  The authentication code in the
        --  message is replace with zeros for this operation.  The message
        --  length is skipped as it is not part of the transmitted message.

        when rcv_state_auth_e       =>
          if (authrcv = '1') then
            authenticate      <= '1' ;
            authnext_out      <= '0' ;

            if (authdone = '0') then
              byte_count      <= RESIZE (msg_length, byte_count'length) ;
              mem_address     <= TO_UNSIGNED ((txrx_mp_length_c + 7) / 8,
                                              mem_address'length) ;
              mem_read_en_out <= '1' ;
              cur_state       <= rcv_state_auth_read_e ;
            end if ;
          end if ;

        when rcv_state_auth_read_e  =>
          if (mem_address <  (txrx_mh_msgauth_str_c + 7) / 8 or
              mem_address >= (txrx_mh_msgauth_str_c +
                              txrx_mh_msgauth_len_c + 7) / 8) then
            authbyte_out      <= mem_datafrom_in ;
          else
            authbyte_out      <= (others => '0') ;
          end if ;

          authnext_out        <= '1' ;
          cur_state           <= rcv_state_auth_wait_e ;

        when rcv_state_auth_wait_e  =>
          if (authready = '1') then
            mem_read_en_out   <= '0' ;
            authnext_out      <= '0' ;
            cur_state         <= rcv_state_auth_next_e ;
          end if ;

        when rcv_state_auth_next_e  =>
          if (authready = '0') then
            if (byte_count /= 1) then
              byte_count      <= byte_count - 1 ;
              mem_address     <= mem_address + 1 ;
              mem_read_en_out <= '1' ;
              cur_state       <= rcv_state_auth_read_e ;
            else
              authenticate    <= '0' ;
              cur_state       <= rcv_state_auth_done_e ;
            end if ;
          end if ;

        when rcv_state_auth_done_e  =>
          if (authdone = '1') then
            if (txrx_mh_authcode /= unsigned (authcode_s)) then
              cur_state       <= rcv_state_done_e ;
            else
              authreq_out     <= '0' ;
              last_msgid      <= save_msgid ;

              byte_count      <= TO_UNSIGNED ((txrx_mh_msgtype_len_c +
                                               7) / 8,
                                              byte_count'length) ;
              mem_address     <= TO_UNSIGNED (txrx_mh_msgtype_str_c / 8,
                                              mem_address'length) ;
              mem_read_en_out <= '1' ;
              cur_state       <= rcv_state_memload_e ;
              next_state      <= rcv_state_type_e ;
            end if ;
          end if ;

        --    Handle messages of the types known.

        when rcv_state_type_e       =>
          if (txrx_mh_type = txrx_mh_tp_listen_c) then
            if (msg_length < (txrx_mh_length_c +
                              txrx_ml_length_c + 7) / 8) then
              cur_state       <= rcv_state_done_e ;
            else
              byte_count      <= TO_UNSIGNED ((txrx_ml_listen_len_c +
                                               7) / 8,
                                              byte_count'length) ;
              mem_address     <= TO_UNSIGNED (txrx_ml_listen_str_c / 8,
                                              mem_address'length) ;
              mem_read_en_out <= '1' ;
              cur_state       <= rcv_state_memload_e ;
              next_state      <= rcv_state_listen_e ;
            end if ;

          elsif (txrx_mh_type = txrx_mh_tp_release_c) then
            if (msg_length < (txrx_mh_length_c +
                              txrx_mr_length_c + 7) / 8) then
              cur_state       <= rcv_state_done_e ;
            else
              byte_count      <= TO_UNSIGNED ((txrx_mr_release_len_c +
                                               7) / 8,
                                              byte_count'length) ;
              mem_address     <= TO_UNSIGNED (txrx_mr_release_str_c / 8,
                                              mem_address'length) ;
              mem_read_en_out <= '1' ;
              cur_state       <= rcv_state_memload_e ;
              next_state      <= rcv_state_release_e ;
            end if ;

          else
            cur_state         <= rcv_state_done_e ;
          end if ;

        --  Handle listen messages.

        when rcv_state_listen_e     =>
          if (txrx_ml_listen = 0) then
            listen_out        <= '0' ;
          elsif (txrx_ml_listen = 1) then
            listen_out        <= '1' ;
          end if ;

          cur_state           <= rcv_state_done_e ;

        --  Handle release messages.

        when rcv_state_release_e    =>
          if (txrx_mr_release = 0) then
            release_out       <= '0' ;
          elsif (txrx_mr_release = 1) then
            release_out       <= '1' ;
          end if ;

          cur_state           <= rcv_state_done_e ;

        --  Done with message.

        when rcv_state_done_e       =>
          authreq_out         <= '0' ;
          memreq_out          <= '0' ;
          rcv_done            <= '1' ;
          cur_state           <= rcv_state_wait_e ;

      end case ;
    end if ;
  end process receiver ;

end architecture rtl ;
