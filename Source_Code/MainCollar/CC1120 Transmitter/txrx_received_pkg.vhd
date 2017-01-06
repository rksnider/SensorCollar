----------------------------------------------------------------------------
--
--! @file       TXRX_received_pkg.vhd
--! @brief      Definitions used for packet receiving.
--! @details    Message definitions for TXRX received messages.
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.MATH_REAL.ALL ;        --! Real numbers in constants.

library GENERAL ;               --! General libraries
use GENERAL.UTILITIES_PKG.ALL ;
use GENERAL.GPS_CLOCK_PKG.ALL ;

package TXRX_received_pkg is

  --------------------------------------------------------------------------
  --  Mesage definitions.
  --  The message authentication field is calculated with a Message
  --  Authentication Code (MAC) algorithm such as ISO/IEC 9797-1 using
  --  its MAC algorithm 1 (CBC-MAC) and randomly generated AES keys for
  --  each device.
  --------------------------------------------------------------------------

  --  Message field lengths.

  constant txrx_msg_len_bits_c    : natural := 8 ;
  constant txrx_msg_addr_bits_c   : natural := 32 ;
  constant txrx_msg_id_bits_c     : natural := gps_time_bytes_c * 8 ;
  constant txrx_msg_auth_bits_c   : natural := 32 ;

  --  Message prefix inserted when the message is received.

  constant txrx_mp_length_str_c   : natural := 0 ;
  constant txrx_mp_length_len_c   : natural := txrx_msg_len_bits_c ;

  constant txrx_mp_length_c       : natural := txrx_mp_length_str_c +
                                               txrx_mp_length_len_c ;

  --  Message header fields.

  constant txrx_mh_type_bits_c    : natural := 8 ;

  constant txrx_mh_tp_listen_c    : natural := 1 ;
  constant txrx_mh_tp_release_c   : natural := 2 ;

  constant txrx_mh_dstaddr_str_c  : natural := txrx_mp_length_c ;
  constant txrx_mh_dstaddr_len_c  : natural := txrx_msg_addr_bits_c ;
  constant txrx_mh_srcaddr_str_c  : natural := txrx_mh_dstaddr_str_c +
                                               txrx_mh_dstaddr_len_c ;
  constant txrx_mh_srcaddr_len_c  : natural := txrx_msg_addr_bits_c ;
  constant txrx_mh_msgid_str_c    : natural := txrx_mh_srcaddr_str_c +
                                               txrx_mh_srcaddr_len_c ;
  constant txrx_mh_msgid_len_c    : natural := txrx_msg_id_bits_c ;
  constant txrx_mh_msgauth_str_c  : natural := txrx_mh_msgid_str_c +
                                               txrx_mh_msgid_len_c ;
  constant txrx_mh_msgauth_len_c  : natural := txrx_msg_auth_bits_c ;
  constant txrx_mh_msgtype_str_c  : natural := txrx_mh_msgauth_str_c +
                                               txrx_mh_msgauth_len_c ;
  constant txrx_mh_msgtype_len_c  : natural := txrx_mh_type_bits_c ;

  constant txrx_mh_length_c       : natural := txrx_mh_msgtype_str_c +
                                               txrx_mh_msgtype_len_c -
                                               txrx_mp_length_c ;

  --  Listen message fields.

  constant txrx_ml_listen_bits_c  : natural := 8 ;

  constant txrx_ml_listen_str_c   : natural := txrx_mp_length_c +
                                               txrx_mh_length_c ;
  constant txrx_ml_listen_len_c   : natural := txrx_ml_listen_bits_c ;

  constant txrx_ml_length_c       : natural := txrx_ml_listen_str_c +
                                               txrx_ml_listen_len_c -
                                               txrx_mp_length_c -
                                               txrx_mh_length_c ;

  --  Release message fields.

  constant txrx_mr_release_bits_c : natural := 8 ;

  constant txrx_mr_release_str_c  : natural := txrx_mp_length_c +
                                               txrx_mh_length_c ;
  constant txrx_mr_release_len_c  : natural := txrx_mr_release_bits_c ;

  constant txrx_mr_length_c       : natural := txrx_mr_release_str_c +
                                               txrx_mr_release_len_c -
                                               txrx_mp_length_c -
                                               txrx_mh_length_c ;

end package TXRX_received_pkg ;
