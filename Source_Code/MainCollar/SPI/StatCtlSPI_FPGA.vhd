----------------------------------------------------------------------------
--
--! @file       StatCtlSPI_FPGA.vhd
--! @brief      FPGA Status/Control Registers SPI interface.
--! @details    The FPGA reads the Power Controller Status and User Flash
--!             Memory while writing the Power Controller Control Register
--!             via an SPI interface.
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

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.


library WORK ;                      --! Local Libaries
use WORK.PC_STATUSCONTROL_PKG.All ;


----------------------------------------------------------------------------
--
--! @brief      FPGA Controller Status/Control Registers SPI interface.
--! @details    If either the control register on the FPGA changes or the
--!             status_chng_in line to the FPGA changes, the FPGA should
--!             start the register transfer over the SPI bus.
--!
--! @param      status_bits_g   The number of bits in the Power Controller's
--!                             status register.
--! @param      control_bits_g  The number of bits in the Power Controller's
--!                             control register.
--! @param      clk             Driving clock for the component.
--! @param      status_in       The Power Controller's status register.
--! @param      status_chg_in   Set when the status register has changed
--!                             since it was last tranferred by SPI.
--!                             Start a transfer on the FPGA master.
--! @param      status_set_out  The status register has been updated.
--! @param      control_in      The FPGAs  control register.
--! @param      busy_out        The component is busy communicating.
--! @param      sclk            SCLK of SPI
--! @param      mosi            MOSI of SPI
--! @param      miso            MISO of SPI
--! @param      cs_n            CS_N of SPI.
--!                             Note that the spi_commands should be set to
--!                             CPOL_CPHA = '11' generic, as that was CPLD
--!                             expects.
--
----------------------------------------------------------------------------

entity StatCtlSPI_FPGA is

  Generic (
    status_bits_g           : natural := 16 ;
    control_bits_g          : natural := 16 ;
    flash_bytes_transfer    : natural := 0 ;
    data_length_bit_width_g : natural := 8
  ) ;
  Port (
    clk                     : in    std_logic ;
    rst_n                   : in    std_logic ;
    status_out              : out   std_logic_vector (status_bits_g-1
                                                      downto 0) ;
    status_chg_in           : in    std_logic ;
    status_set_out          : out   std_logic ;
    control_in              : in    std_logic_vector (control_bits_g-1
                                                      downto 0) ;
    busy_out                : out   std_logic ;

    sclk                    : out   std_logic ;
    mosi                    : out   std_logic ;
    miso                    : in    std_logic ;
    cs_n                    : out   std_logic
  ) ;

end entity StatCtlSPI_FPGA ;


architecture rtl of StatCtlSPI_FPGA is

 type STATCTRL_STATE is   (

    STATCRL_WAIT,
    STATCRL_SETUP,
    STATCRL_TRANSFER,
    STATCRL_TRANSFER_DONE
    );

  signal cur_statctrl_state         : STATCTRL_STATE;
  signal next_statctrl_state        : STATCTRL_STATE;

  --  Determine if the entity is busy.

  signal process_busy               : std_logic ;

  --  Using a value of 0 on the command_width and address_width will
  --  break the signals down the instantiations, so a value of 1 is used.

  constant command_width_bytes_c    : natural := 1;
  constant address_width_bytes_c    : natural := 1;

  --  Intermediate port mapping signals of the spi_commands entity. These
  --  are how I interact with that entity.

  signal    command_spi_signal                :
                std_logic_vector (command_width_bytes_c*8-1 downto 0);
  signal    address_spi_signal                :
                std_logic_vector(address_width_bytes_c*8-1 downto 0);
  signal    address_en_spi_signal             : std_logic;
  signal    data_length_spi_signal            :
                std_logic_vector(data_length_bit_width_g - 1 downto 0);
  signal    master_slave_data_spi_signal      :
                std_logic_vector(7 downto 0);
  signal    master_slave_data_rdy_spi_signal  : std_logic;
  signal    master_slave_data_ack_spi_signal  : std_logic;
  signal    master_slave_data_ack_spi_signal_follower : std_logic;
  signal    command_busy_spi_signal           : std_logic;
  signal    slave_master_data_spi_signal      :
                std_logic_vector(7 downto 0);
  signal    slave_master_data_ack_spi_signal  : std_logic;

  signal    control_in_follower               :
                std_logic_vector (control_bits_g-1 downto 0);

  signal    status_shift                      :
                std_logic_vector (status_bits_g-1 downto 0) ;

  signal    control_shift                     :
                std_logic_vector (control_bits_g-1 downto 0) ;

  signal    status_chg_in_follower            : std_logic;

  --  Control bits must be a byte bit count.

  constant control_register_byte_count_c      : natural :=
              control_bits_g / 8;
  constant status_register_byte_count_c       : natural :=
              status_bits_g / 8;

  --  Counts used to keep track of read bytes off MISO.

  signal byte_read_count            : unsigned (data_length_bit_width_g-1
                                                downto 0);
  signal byte_read_number           : unsigned (data_length_bit_width_g-1
                                                downto 0);

  signal startup_en                 : std_logic;

  signal startup_processed          : std_logic;
  signal startup_processed_follower : std_logic;

  component spi_commands is
    generic (
      command_used_g            : std_logic := '0';
      address_used_g            : std_logic := '0';
      command_width_bytes_g     : natural := 1;
      address_width_bytes_g     : natural := 1;
      data_length_bit_width_g   : natural := 10;
      cpol_cpha                 : std_logic_vector (1 downto 0) := "11"
    );
    port(
      clk	                      : in	  std_logic;
      rst_n 	                  : in	  std_logic;

      command_in                : in    std_logic_vector
                                          (command_width_bytes_g*8-1
                                           downto 0);
      address_in                : in    std_logic_vector
                                          (address_width_bytes_g*8-1
                                           downto 0);
      address_en_in             : in    std_logic;
      data_length_in            : in    std_logic_vector
                                          (data_length_bit_width_g-1
                                           downto 0);
      master_slave_data_in      : in    std_logic_vector (7 downto 0);
      master_slave_data_rdy_in  : in    std_logic;
      master_slave_data_ack_out : out   std_logic;
      command_busy_out          : out   std_logic;
      slave_master_data_out     : out   std_logic_vector (7 downto 0);
      slave_master_data_ack_out : out   std_logic;

      miso 				              : in	  std_logic;
      mosi 				              : out  std_logic;
      sclk 				              : out  std_logic;
      cs_n 				              : out  std_logic
		);
  end component spi_commands;


begin

  --  Determine if the entity is busy.

  busy_out      <= '1' when ((process_busy   = '1')                   or
                             (startup_en     = '1')                   or
                             (control_in    /= control_in_follower)   or
                             (status_chg_in /= status_chg_in_follower))
                       else '0' ;


  --------------------------------------------------------------------------
  --
  --! @brief    Capture the Status Register from the CPLD and push out the
  --!           Control register from the FPGA.
  --!
  --! @details  Do the following things.
  --!           If either the status_chg_in line changes (the status
  --!           register on the cpld has changed) or the control register
  --!           of the FPGA has changed, shift the registers between the
  --!           devices.
  --!           Makes heavy use of the spi_commands framework.
  --!           The state machine waits for an event, then loads the
  --!           spi_command entity with the data and says go. This
  --!           implementation is unique as no command/address are used,
  --!           only data.  The state machine then waits for the correct
  --!           number of bytes to come back and shifts them into the
  --!           status_shift register, as control register is shifted out.
  --!           The state machine is sensitive to the number of bytes read
  --!           back on MISO and not the number of bytes sent out on MOSI.
  --!           (MISO byte acks come later than the point at which a MOSI
  --!           byte is sent out.)
  --!
  --! @param    clk             Take action on positive edge.
  --! @param    rst_n           Reset to initial state.
  --
  --------------------------------------------------------------------------

  statcrl_FPGA_state_machine : process (clk, rst_n)
  begin
    if (rst_n = '0') then

      cur_statctrl_state                <= STATCRL_WAIT;
      process_busy                      <= '0' ;

      command_spi_signal                <= (others => '0');
      address_spi_signal                <= (others => '0');
      master_slave_data_spi_signal      <= (others => '0');
      address_en_spi_signal             <= '0';
      data_length_spi_signal            <= (others => '0');
      master_slave_data_rdy_spi_signal  <= '0';

      startup_processed                 <= '0';
      status_out                        <= (others => '0');
      status_shift                      <= (others => '0');
      status_set_out                    <= '0';

      control_shift                     <= (others => '0');

    elsif (clk'event and clk = '1') then

      --  Default signal states.

      master_slave_data_rdy_spi_signal  <= '0';

      if (startup_processed = '1' and startup_processed_follower = '1') then
        startup_processed               <= '0';
      end if;


      case cur_statctrl_state is

        when STATCRL_WAIT =>

          status_set_out          <= '0' ;

          if (startup_en = '1') then
            cur_statctrl_state    <= STATCRL_SETUP;
            startup_processed     <= '1';
            control_shift         <= control_in;
            process_busy          <= '1' ;
          else
            process_busy          <= '0' ;
          end if;

        --  This is somewhat new. This SPI is bidirectional.

        when STATCRL_SETUP =>

          byte_read_count           <=
                to_unsigned (0, byte_read_count'length);
          byte_read_number          <=
                to_unsigned (status_register_byte_count_c +
                             flash_bytes_transfer,byte_read_number'length);

          if (command_busy_spi_signal = '0') then
            command_spi_signal      <= std_logic_vector (
                      to_unsigned (0, command_spi_signal'length));
            address_spi_signal      <= std_logic_vector (
                      to_unsigned (0, command_spi_signal'length));
            address_en_spi_signal   <= '0';
            data_length_spi_signal  <= std_logic_vector (
                      to_unsigned (status_register_byte_count_c +
                                   flash_bytes_transfer,
                                   data_length_spi_signal'length));
            master_slave_data_spi_signal
                                    <=
                      control_shift (control_shift'length-1 downto
                                     control_shift'length-8);
            control_shift           <=
                      control_shift (control_shift'length-9 downto 0) &
                      x"00";

            master_slave_data_rdy_spi_signal
                                    <= '1';
            cur_statctrl_state      <= STATCRL_TRANSFER;

          end if;

        when STATCRL_TRANSFER =>
          --  Here we are concerned about getting the needed bytes back, not
          --  that we have finished sending the control register.
          --  We do not maintain a byte_count (bytes pushed) but rather
          --  a byte_read_count as we are concerned about getting all read bytes
          --  back.

          if (byte_read_count = byte_read_number) then
            cur_statctrl_state  <= STATCRL_TRANSFER_DONE;
          elsif (slave_master_data_ack_spi_signal = '1') then
            status_shift        <= status_shift (status_shift'length-9
                                                 downto 0) &
                                   slave_master_data_spi_signal;
            byte_read_count     <= byte_read_count + 1;
          end if;

          if (master_slave_data_ack_spi_signal_follower /=
              master_slave_data_ack_spi_signal) then

            master_slave_data_ack_spi_signal_follower
                                <= master_slave_data_ack_spi_signal;

            if (master_slave_data_ack_spi_signal = '1') then
              master_slave_data_spi_signal
                                <= control_shift (control_shift'length-1
                                                  downto
                                                  control_shift'length-8);
              control_shift     <= control_shift (control_shift'length-9
                                                  downto 0) & x"00";
              master_slave_data_rdy_spi_signal
                                <= '1';
            end if;
          else
            master_slave_data_rdy_spi_signal
                                <= '0';
          end if;

      when STATCRL_TRANSFER_DONE =>
        cur_statctrl_state      <= STATCRL_WAIT;
        status_out              <= status_shift;
        status_set_out          <= '1' ;

      end case ;
    end if ;
  end process statcrl_FPGA_state_machine ;


  spi_commands_master_statctl_fpga : spi_commands

    generic map (
      command_used_g            => '0',
      address_used_g            => '0',
      command_width_bytes_g     => 1,
      address_width_bytes_g     => 1,
      data_length_bit_width_g   => data_length_bit_width_g,
      cpol_cpha                 => "11"
    )
    port map (
      clk	                      => clk,
      rst_n 	                  => rst_n,

      command_in                => command_spi_signal,
      address_in                => address_spi_signal,
      address_en_in             => address_en_spi_signal,
      data_length_in            => data_length_spi_signal,

      master_slave_data_in      =>  master_slave_data_spi_signal,
      master_slave_data_rdy_in  =>  master_slave_data_rdy_spi_signal,
      master_slave_data_ack_out =>  master_slave_data_ack_spi_signal,
      command_busy_out          =>  command_busy_spi_signal,
      slave_master_data_out     =>  slave_master_data_spi_signal,
      slave_master_data_ack_out =>  slave_master_data_ack_spi_signal,

      miso 				              => miso,
      mosi 					            => mosi,
      sclk 					            => sclk,
      cs_n 					            => cs_n
		);


  --------------------------------------------------------------------------
  --!
  --! @brief      output logic of the statctrl_machine
  --!
  --! @details    Not output logic at this time.

  --! @param      clk     Take action on positive edge.
  --! @param      rst_n   Reset to initial state.
  --!
  --------------------------------------------------------------------------

  statctrl_machine_output :  process (cur_statctrl_state)
  begin

    case cur_statctrl_state is

      when STATCRL_WAIT =>
      when STATCRL_SETUP =>
      when STATCRL_TRANSFER =>
      when STATCRL_TRANSFER_DONE =>

    end case;

  end process statctrl_machine_output ;


  --------------------------------------------------------------------------
  --!
  --! @brief    track_statuschng_in and control register changes.
  --!
  --! @details  If the CPLD signals a status register change on the status
  --!           register change in line or the control register has changed
  --!           changed start an SPI transfer.
  --! @param    clk       Take action on positive edge.
  --! @param    rst_n     Reset to initial state.
  --!
  --------------------------------------------------------------------------

  track_statuschng_in: process (clk, rst_n)
  begin
    if (rst_n = '0') then
      status_chg_in_follower        <= '0';
      startup_en                    <= '0';

      --This will guarantee a initial push on startup.

      control_in_follower           <= (others => '1');


    elsif (clk'event and clk = '1') then

      if (control_in_follower /= control_in) then
        control_in_follower         <= control_in ;
        startup_en                  <= '1' ;

      elsif (status_chg_in_follower /= status_chg_in) then
        status_chg_in_follower      <= status_chg_in;

        if (status_chg_in = '1') then
          startup_en                <= '1';
        end if;

      elsif (startup_processed_follower /= startup_processed) then
        startup_processed_follower  <= startup_processed ;

        if (startup_processed = '1') then
          startup_en                <= '0' ;
        end if ;
      end if;
    end if;
  end process;

end architecture rtl ;
