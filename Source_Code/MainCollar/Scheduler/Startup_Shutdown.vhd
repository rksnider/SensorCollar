-- @file       Startup_Shutdown.vhd
-- @brief      Sequence the startup and shutdown of the entities of the
--              collar project
-- @details
-- @author     Chris Casebeer
-- @date       2_12_2015
-- @copyright
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
--


library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Use Real math.



LIBRARY GENERAL ;
use WORK.Utilities_pkg.all;
use WORK.PC_STATUSCONTROL_PKG.ALL;
use WORK.Collar_Control_pkg.ALL;

use WORK.SHARED_SDC_VALUES_PKG.ALL ;


LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


--
--! @brief    Sequence the startup of system components
--! @details  Start up all the system's devices in the order required for
--!           them to operate properly or shutdown these devices in the
--!           order for them to shutdown properly.
--!
--! @param    clk                   Clock driving the logic.  It can be
--!                                 gated on the busy output port.
--! @param    rst_n                 Reset on low.
--! @param    busy_out              Entity Busy.  Turn on the input clock.
--! @param    pc_control_reg_out    Control register sent to CPLD.
--! @param    pc_control_reg_in     Control settings from other components.
--! @param    pc_status_set_in      CPLC status register has been set.
--!
--! @param    sd_contr_start_out    Start the microsd_controller.
--! @param    sd_contr_started_in   Microsd_Controller startup done.
--! @param    sd_contr_stop_out     Stop the micro-SD controller.
--! @param    sd_contr_stopped_in   The micro-SD controller has stopped.
--!
--! @param    sdram_start_out       Start the sdram_controller.
--! @param    sdram_started_in      sdram_controller startup done
--! @param    sdram_stop_out        Stop the sdram_controller.
--! @param    sdram_stopped_in      sdram_controller has stopped
--!
--! @param    imu_start_out         Start the IMU
--! @param    imu_started_in        IMU has started
--! @param    imu_stop_out          Stop the IMU
--! @param    imu_stopped_in        IMU has stopped
--!
--! @param    mems_start_out        Start the MEMS michrophones
--! @param    mems_started_in       MEMS microphones has started
--! @param    mems_stop_out         Stop the MEMS microphones
--! @param    mems_stopped_in       MEMS michrophones have stopped
--!
--! @param    mag_start_out         Start the MagMem
--! @param    mag_started_in        MagMem startup done
--! @param    mag_stop_out          Stop the MagMem
--! @param    mag_stopped_in        MagMem stopped
--!
--! @param    gps_start_out         Start the GPS
--! @param    gps_started_in        The GPS has started
--! @param    gps_stop_out          Stop the GPS
--! @param    gps_stopped_in        The GPS has stopped
--!
--! @param    txrx_start_out        Start the Transceiver
--! @param    txrx_started_in       The Transceiver has started
--! @param    txrx_stop_out         Stop the Transceiver
--! @param    txrx_stopped_in       The Transceiver has stopped
--!
--! @param    flashblock_start_out  Start Flashblock
--! @param    flashblock_started_in Flashblock has started
--! @param    flashblock_stop_out   Stop Flashblock
--! @param    flashblock_stopped_in Flashblock stopped
--!
--! @param    onoff_start_out       Start the On/Off Scheduler
--! @param    onoff_started_in      The On/Off Scheduler has started
--! @param    onoff_stop_out        Stop the On/Off Scheduler
--! @param    onoff_stopped_in      The On/Off Scheduler has stopped
--!
--! @param    shutdown_in           Initiate shutdown of entire system
--!
--! @param    statctl_startup_out   Startup the power controller
--!                                 status/control communicator
--!
--!


entity Startup_Shutdown is

  Generic (
    clk_freq_g            : natural := 50e6
  ) ;
  Port (
    clk                   : in    std_logic ;
    rst_n                 : in    std_logic ;

    busy_out              : out   std_logic;

    pc_control_reg_out    : out   std_logic_vector (ControlSignalsCnt_c-1
                                                    downto 0) ;

    pc_control_reg_in     : in    std_logic_vector (ControlSignalsCnt_c-1
                                                    downto 0) ;

    pc_status_set_in      : in    std_logic ;

    sd_contr_start_out    : out   std_logic ;
    sd_contr_started_in   : in    std_logic ;
    sd_contr_stop_out     : out   std_logic ;
    sd_contr_stopped_in   : in    std_logic ;

    sdram_start_out       : out   std_logic ;
    sdram_started_in      : in    std_logic ;
    sdram_stop_out        : out   std_logic ;
    sdram_stopped_in      : in    std_logic ;

    imu_start_out         : out   std_logic ;
    imu_started_in        : in    std_logic ;
    imu_stop_out          : out   std_logic ;
    imu_stopped_in        : in    std_logic ;

    rtc_start_out         : out   std_logic ;
    rtc_started_in        : in    std_logic ;
    rtc_stop_out          : out   std_logic ;
    rtc_stopped_in        : in    std_logic ;

    batmon_start_out      : out   std_logic ;
    batmon_started_in     : in    std_logic ;
    batmon_stop_out       : out   std_logic ;
    batmon_stopped_in     : in    std_logic ;

    mems_start_out        : out   std_logic ;
    mems_started_in       : in    std_logic ;
    mems_stop_out         : out   std_logic ;
    mems_stopped_in       : in    std_logic ;

    mag_start_out         : out   std_logic ;
    mag_started_in        : in    std_logic ;
    mag_stop_out          : out   std_logic ;
    mag_stopped_in        : in    std_logic ;

    gps_start_out         : out   std_logic ;
    gps_started_in        : in    std_logic ;
    gps_stop_out          : out   std_logic ;
    gps_stopped_in        : in    std_logic ;

    txrx_start_out        : out   std_logic ;
    txrx_started_in       : in    std_logic ;
    txrx_stop_out         : out   std_logic ;
    txrx_stopped_in       : in    std_logic ;

    flashblock_start_out  : out   std_logic ;
    flashblock_started_in : in    std_logic ;
    flashblock_stop_out   : out   std_logic ;
    flashblock_stopped_in : in    std_logic ;

    onoff_start_out       : out   std_logic ;
    onoff_started_in      : in    std_logic ;
    onoff_stop_out        : out   std_logic ;
    onoff_stopped_in      : in    std_logic ;

    shutdown_in           : in    std_logic ;

    statctl_startup_out   : out   std_logic
) ;

end Startup_Shutdown ;


architecture rtl of Startup_Shutdown is

  type STARTUP_STATE is   (
    STATE_WAIT,
    STATE_START,
    STATE_DONE,

    STATE_STOP,
    STATE_SHUTDOWN,

    STATE_START_NEXT,
    STATE_STOP_NEXT,

    STATE_ON_WAIT,

    START_MAGRAM,
    START_MAGRAM_WAITDONE,
    STOP_MAGRAM,

    START_SDCTRL,
    START_SDCTRL_WAITDONE,
    STOP_SDCTRL,

    START_SDRAM,
    START_SDRAM_WAITDONE,
    STOP_SDRAM,

    START_MEMS,
    START_MEMS_WAITDONE,
    STOP_MEMS,

    START_IMU,
    START_IMU_WAITDONE,
    STOP_IMU,

    START_GPS,
    START_GPS_PULSE,
    START_GPS_WAITDONE,
    STOP_GPS,

    START_TXRX,
    START_TXRX_WAITDONE,
    STOP_TXRX,

    START_I2C,
    STOP_I2C,

    START_RTC,
    STOP_RTC,

    START_BATMON,
    STOP_BATMON,

    START_FLASHBLOCK,
    START_FLASHBLOCK_WAITDONE,
    STOP_FLASHBLOCK,

    START_ONOFF,
    STOP_ONOFF,

    STOP_FPGA
  );

  constant DEBUG_ON : std_logic := '1';


  signal cur_state            : STARTUP_STATE;
  signal next_state           : STARTUP_STATE;

  type states_table_t is array (natural range <>) of STARTUP_STATE ;

  constant start_states_c     : states_table_t :=
  (
    START_MAGRAM,
    START_SDCTRL,
    START_SDRAM,
    START_FLASHBLOCK,
    START_MEMS,
    START_IMU,
    START_I2C,
    START_RTC,
    START_BATMON,
    START_GPS,
    START_TXRX,
    START_ONOFF,
    STATE_DONE
  ) ;

  constant stop_states_c      : states_table_t :=
  (
    STOP_MEMS,
    STOP_IMU,
    STOP_RTC,
    STOP_BATMON,
    STOP_I2C,
    STOP_FLASHBLOCK,
    STOP_SDRAM,
    STOP_SDCTRL,
    STOP_GPS,
    STOP_TXRX,
    STOP_MAGRAM,
    STOP_ONOFF,
    STOP_FPGA
  ) ;

  signal state_count          :
      unsigned (const_bits (maximum (start_states_c'length,
                                     stop_states_c'length))-1 downto 0) ;

  --  Synchronization signals.

  signal pc_status_set_s      : std_logic ;
  signal pc_status_set        : std_logic ;
  signal pc_status_set_follower : std_logic ;
  signal sd_contr_started_s   : std_logic ;
  signal sd_contr_stopped_s   : std_logic ;
  signal sd_contr_started     : std_logic ;
  signal sd_contr_stopped     : std_logic ;
  signal sdram_started_s      : std_logic ;
  signal sdram_stopped_s      : std_logic ;
  signal sdram_started        : std_logic ;
  signal sdram_stopped        : std_logic ;
  signal imu_started_s        : std_logic ;
  signal imu_stopped_s        : std_logic ;
  signal imu_started          : std_logic ;
  signal imu_stopped          : std_logic ;
  signal mems_started_s       : std_logic ;
  signal mems_stopped_s       : std_logic ;
  signal mems_started         : std_logic ;
  signal mems_stopped         : std_logic ;
  signal mag_started_s        : std_logic ;
  signal mag_stopped_s        : std_logic ;
  signal mag_started          : std_logic ;
  signal mag_stopped          : std_logic ;
  signal gps_started_s        : std_logic ;
  signal gps_stopped_s        : std_logic ;
  signal gps_started          : std_logic ;
  signal gps_stopped          : std_logic ;
  signal txrx_started_s       : std_logic ;
  signal txrx_stopped_s       : std_logic ;
  signal txrx_started         : std_logic ;
  signal txrx_stopped         : std_logic ;
  signal rtc_started_s        : std_logic;
  signal rtc_stopped_s        : std_logic;
  signal rtc_started          : std_logic;
  signal rtc_stopped          : std_logic;
  signal batmon_started_s     : std_logic;
  signal batmon_stopped_s     : std_logic;
  signal batmon_started       : std_logic;
  signal batmon_stopped       : std_logic;
  signal flashblock_started_s : std_logic;
  signal flashblock_stopped_s : std_logic;
  signal flashblock_started   : std_logic;
  signal flashblock_stopped   : std_logic;
  signal onoff_started_s      : std_logic ;
  signal onoff_stopped_s      : std_logic ;
  signal onoff_started        : std_logic ;
  signal onoff_stopped        : std_logic ;


  --Starting to talk to the IMU immediately after powering it on
  --does not work. This timeout it set for one second.

  constant  imu_delay_c       : natural := spi_clk_freq_c * 1;

  signal    imu_delay_count   : unsigned (const_bits (IMU_delay_c)-1
                                          downto 0);

  signal pc_control_reg : std_logic_vector (ControlSignalsCnt_c-1
                                            downto 0) :=
                                                (others => '0') ;

  signal shutdown       : std_logic ;
  signal shutdown_s     : std_logic ;
  signal shutdown_ff    : std_logic ;
  signal running        : std_logic ;
  signal process_busy   : std_logic ;

  --Debug

  signal sd_contr_start_out_debug : std_logic_vector (0 downto 0);
  signal start_signal             : std_logic_vector (0 downto 0);
  signal rtc_startup              : std_logic_vector (0 downto 0);

  constant shutdown_delay_c       : natural := spi_clk_freq_c * 30;

  signal shutdown_delay_count     :
              unsigned (const_bits (shutdown_delay_c)-1 downto 0);
  signal main_on_debug            : std_logic_vector (0 downto 0);
  signal recharge_on_debug        : std_logic_vector (0 downto 0);
  signal solar_on_debug           : std_logic_vector (0 downto 0);

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

  busy_out                    <= process_busy or shutdown_ff ;

  pc_control_reg_out          <= pc_control_reg OR pc_control_reg_in
                                    when (running = '1') else
                                 pc_control_reg ;

  shutdown_sig : SR_FlipFlop
    Port Map (
      reset_in              => rst_n,
      set_in                => shutdown_in,
      result_rd_out         => shutdown_ff
    ) ;

  -- in_system_probe0 : altsource_probe
    -- GENERIC MAP (
      -- enable_metastability => "NO",
      -- instance_id => "sta",
      -- probe_width => 1,
      -- sld_auto_instance_index => "YES",
      -- sld_instance_index => 0,
      -- source_initial_value => "0",
      -- source_width => 1,
      -- lpm_type => "altsource_probe"
    -- )
    -- PORT MAP (
      -- probe => start_signal,
      -- source => start_signal
    -- );

  -- in_system_probe4 : altsource_probe
    -- GENERIC MAP (
      -- enable_metastability => "NO",
      -- instance_id => "mai",
      -- probe_width => 1,
      -- sld_auto_instance_index => "YES",
      -- sld_instance_index => 0,
      -- source_initial_value => "1",
      -- source_width => 1,
      -- lpm_type => "altsource_probe"
    -- )
    -- PORT MAP (
      -- probe => main_on_debug,
      -- source => main_on_debug
    -- );

  -- in_system_probe5 : altsource_probe
    -- GENERIC MAP (
      -- enable_metastability => "NO",
      -- instance_id => "rec",
      -- probe_width => 1,
      -- sld_auto_instance_index => "YES",
      -- sld_instance_index => 0,
      -- source_initial_value => "1",
      -- source_width => 1,
      -- lpm_type => "altsource_probe"
    -- )
    -- PORT MAP (
      -- probe => recharge_on_debug,
      -- source => recharge_on_debug
    -- );

    -- in_system_probe6 : altsource_probe
    -- GENERIC MAP (
      -- enable_metastability => "NO",
      -- instance_id => "sol",
      -- probe_width => 1,
      -- sld_auto_instance_index => "YES",
      -- sld_instance_index => 0,
      -- source_initial_value => "0",
      -- source_width => 1,
      -- lpm_type => "altsource_probe"
    -- )
    -- PORT MAP (
      -- probe => solar_on_debug,
      -- source => solar_on_debug
    -- );





  -- The ideas here are as follows:
  -- Sequence the turning on/off of the entities.
  -- The physical component voltage is turned on via CPLD control register
  -- setting.
  -- Then the collar component is told to start its initialization.
  -- The state machine waits for the component to give the go ahead
  -- The next component is turned on

  -- Shutdown examines the power controller status register return
  -- and begins shutting off components.



  startup_shutdown_state_machine:  process (clk, rst_n)
  begin
    if (rst_n = '0') then

      cur_state               <= STATE_WAIT;

      pc_control_reg          <= (others => '0');
      pc_control_reg (ControlSignals'pos (Ctl_MainPowerSwitch_e))   <= '1';
      pc_control_reg (ControlSignals'pos (Ctl_RechargeSwitch_e))    <= '1';
      pc_control_reg (ControlSignals'pos (Ctl_SolarCtlShutdown_e))  <= '0';
      pc_status_set           <= '0';
      pc_status_set_s         <= '0';
      pc_status_set_follower  <= '0';
      sd_contr_start_out      <= '0';
      sd_contr_started        <= '0';
      sd_contr_started_s      <= '0';
      sd_contr_stop_out       <= '0';
      sd_contr_stopped        <= '0';
      sd_contr_stopped_s      <= '0';
      sdram_start_out         <= '0';
      sdram_started           <= '0';
      sdram_started_s         <= '0';
      sdram_stop_out          <= '0';
      sdram_stopped           <= '0';
      sdram_stopped_s         <= '0';
      imu_start_out           <= '0';
      imu_started             <= '0';
      imu_started_s           <= '0';
      imu_stop_out            <= '0';
      imu_stopped             <= '0';
      imu_stopped_s           <= '0';
      mems_start_out          <= '0';
      mems_started            <= '0';
      mems_started_s          <= '0';
      mems_stop_out           <= '0';
      mems_stopped            <= '0';
      mems_stopped_s          <= '0';
      mag_start_out           <= '0';
      mag_started             <= '0';
      mag_started_s           <= '0';
      mag_stop_out            <= '0';
      mag_stopped             <= '0';
      mag_stopped_s           <= '0';
      gps_start_out           <= '0';
      gps_started             <= '0';
      gps_started_s           <= '0';
      gps_stop_out            <= '0';
      gps_stopped             <= '0';
      gps_stopped_s           <= '0';
      txrx_start_out          <= '0';
      txrx_started            <= '0';
      txrx_started_s          <= '0';
      txrx_stop_out           <= '0';
      txrx_stopped            <= '0';
      txrx_stopped_s          <= '0';
      batmon_start_out        <= '0';
      batmon_started          <= '0';
      batmon_started_s        <= '0';
      batmon_stop_out         <= '0';
      batmon_stopped          <= '0';
      batmon_stopped_s        <= '0';
      rtc_start_out           <= '0';
      rtc_started             <= '0';
      rtc_started_s           <= '0';
      rtc_stop_out            <= '0';
      rtc_stopped             <= '0';
      rtc_stopped_s           <= '0';
      flashblock_start_out    <= '0';
      flashblock_started      <= '0';
      flashblock_started_s    <= '0';
      flashblock_stop_out     <= '0';
      flashblock_stopped      <= '0';
      flashblock_stopped_s    <= '0';
      onoff_start_out         <= '0';
      onoff_started           <= '0';
      onoff_started_s         <= '0';
      onoff_stop_out          <= '0';
      onoff_stopped           <= '0';
      onoff_stopped_s         <= '0';
      shutdown                <= '0';
      shutdown_s              <= '0';

      running                 <= '0';
      StatCtl_startup_out     <= '0';
      process_busy            <= '1';
      imu_delay_count         <= (others => '0') ;
      shutdown_delay_count    <= (others => '0') ;

    elsif (falling_edge (clk)) then

      --  Synchronize input signals from other clock domains.

      pc_status_set           <= pc_status_set_s ;
      sd_contr_started        <= sd_contr_started_s ;
      sd_contr_stopped        <= sd_contr_stopped_s ;
      sdram_started           <= sdram_started_s ;
      sdram_stopped           <= sdram_stopped_s ;
      imu_started             <= imu_started_s ;
      imu_stopped             <= imu_stopped_s ;
      mems_started            <= mems_started_s ;
      mems_stopped            <= mems_stopped_s ;
      mag_started             <= mag_started_s ;
      mag_stopped             <= mag_stopped_s ;
      gps_started             <= gps_started_s ;
      gps_stopped             <= gps_stopped_s ;
      txrx_started            <= txrx_started_s ;
      txrx_stopped            <= txrx_stopped_s ;
      batmon_started          <= batmon_started_s;
      batmon_stopped          <= batmon_stopped_s;
      rtc_started             <= rtc_started_s;
      rtc_stopped             <= rtc_stopped_s;
      flashblock_started      <= flashblock_started_s;
      flashblock_stopped      <= flashblock_stopped_s;
      onoff_started           <= onoff_started_s;
      onoff_stopped           <= onoff_stopped_s;
      shutdown                <= shutdown_s;

    elsif (rising_edge (clk)) then

      pc_status_set_s         <= pc_status_set_in ;
      sd_contr_started_s      <= sd_contr_started_in ;
      sd_contr_stopped_s      <= sd_contr_stopped_in ;
      sdram_started_s         <= sdram_started_in ;
      sdram_stopped_s         <= sdram_stopped_in ;
      imu_started_s           <= imu_started_in ;
      imu_stopped_s           <= imu_stopped_in ;
      mems_started_s          <= mems_started_in ;
      mems_stopped_s          <= mems_stopped_in ;
      mag_started_s           <= mag_started_in ;
      mag_stopped_s           <= mag_stopped_in ;
      gps_started_s           <= gps_started_in ;
      gps_stopped_s           <= gps_stopped_in ;
      txrx_started_s          <= txrx_started_in ;
      txrx_stopped_s          <= txrx_stopped_in ;
      batmon_started_s        <= batmon_started_in;
      batmon_stopped_s        <= batmon_stopped_in;
      rtc_started_s           <= rtc_started_in;
      rtc_stopped_s           <= rtc_stopped_in;
      flashblock_started_s    <= flashblock_started_in;
      flashblock_stopped_s    <= flashblock_stopped_in;
      onoff_started_s         <= onoff_started_in ;
      onoff_stopped_s         <= onoff_stopped_in ;
      shutdown_s              <= shutdown_ff ;

      --  Set entries not otherwise set in the state machine.

      pc_control_reg (ControlSignals'pos (Ctl_MainPowerSwitch_e))   <= '1';
      pc_control_reg (ControlSignals'pos (Ctl_RechargeSwitch_e))    <= '1';
      pc_control_reg (ControlSignals'pos (Ctl_SolarCtlShutdown_e))  <= '0';
      pc_control_reg (ControlSignals'pos (Ctl_LevelShifter3p3_e))   <= '0';
      pc_control_reg (ControlSignals'pos (Ctl_LevelShifter1p8_e))   <= '0';
      pc_control_reg (ControlSignals'pos (Ctl_FLASH_Granted_e))     <= '0';
      pc_control_reg (ControlSignals'pos (Ctl_RTC_Int_e))           <= '0';

      --  Startup and shutdown in an orderred fashion.

      case cur_state is

        --  Begin the startup process.

        when STATE_WAIT           =>
          --if (start_signal(0) = '1') then
            cur_state         <= STATE_START;
          --end if;

        when STATE_START          =>
          StatCtl_startup_out <= '1';
          state_count         <= (others => '0') ;
          cur_state           <= STATE_START_NEXT ;

        when STATE_START_NEXT     =>
          cur_state           <= start_states_c (TO_INTEGER (state_count)) ;
          state_count         <= state_count + 1 ;

        when STATE_DONE           =>
          running                   <= '1' ;
          process_busy              <= '0';
          cur_state                 <= STATE_STOP ;

        --  Wait until a shutdown is indicated before starting the
        --  shutdown process.

        when STATE_STOP           =>
          if (shutdown = '1') then
            running                 <= '0' ;
            process_busy            <= '1' ;
            cur_state               <= STATE_SHUTDOWN ;
          end if;

          --Debug the main and recharge switches from here.
          -- pc_control_reg (ControlSignals'pos (Ctl_MainPowerSwitch_e))   <=
                                                    -- main_on_debug(0);
          -- pc_control_reg (ControlSignals'pos (Ctl_RechargeSwitch_e))    <=
                                                    -- recharge_on_debug(0);
          -- pc_control_reg (ControlSignals'pos (Ctl_SolarCtlShutdown_e))  <=
                                                    -- solar_on_debug(0);

        when STATE_SHUTDOWN     =>
          if (shutdown_delay_count =
              to_unsigned (shutdown_delay_c,
                           shutdown_delay_count'length)) then
            state_count       <= (others => '0') ;
            cur_state         <= STATE_STOP_NEXT ;
          else
            shutdown_delay_count <= shutdown_delay_count + 1;
          end if;

        when STATE_STOP_NEXT    =>
          cur_state           <= stop_states_c (TO_INTEGER (state_count)) ;
          state_count         <= state_count + 1 ;

        --  Wait for the on/off change to take effect.

        when STATE_ON_WAIT        =>
          if (pc_status_set_follower /= pc_status_set) then
              pc_status_set_follower <= pc_status_set;

            if (pc_status_set = '1') then
              cur_state             <= next_state;
            end if;
          end if;

        --  Handle the magnetic memory.

        when START_MAGRAM           =>
          if (Collar_Control_useMagMem_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_MagMemOn_e))  <= '1';
            next_state        <= START_MAGRAM_WAITDONE;
            cur_state         <= STATE_ON_WAIT;
          else
            cur_state         <= STATE_START_NEXT;
          end if;

        when START_MAGRAM_WAITDONE  =>
          mag_start_out       <= '1';

          if (mag_started = '1') then
            mag_start_out     <= '0' ;
            cur_state         <= STATE_START_NEXT;
          end if;

        when STOP_MAGRAM            =>
          if (Collar_Control_useMagMem_c = '1') then
            mag_stop_out      <= '1' ;

            if (mag_stopped = '1') then
              mag_stop_out    <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_MagMemOn_e))  <= '0';
              next_state      <= STATE_STOP_NEXT;
              cur_state       <= STATE_ON_WAIT;
            end if ;
          else
            cur_state         <= STATE_STOP_NEXT;
          end if;

        --  SD Card handling states.

        when START_SDCTRL           =>
          if (Collar_Control_useSDH_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_SDCardOn_e))  <= '1';
            cur_state           <= STATE_ON_WAIT;
            next_state          <= START_SDCTRL_WAITDONE;
          else
           cur_state            <= STATE_START_NEXT;
          end if;

        when START_SDCTRL_WAITDONE =>
          sd_contr_start_out    <= '1';

          if (sd_contr_started = '1') then
            sd_contr_start_out  <= '0' ;
            cur_state           <= STATE_START_NEXT;
          end if;

        when STOP_SDCTRL            =>
          if (Collar_Control_useSDH_c = '1') then
            sd_contr_stop_out   <= '1' ;

            if (sd_contr_stopped = '1') then
              sd_contr_stop_out <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_SDCardOn_e))  <= '0';
              cur_state         <= STATE_ON_WAIT;
              next_state        <= STATE_STOP_NEXT;
            end if ;
          else
            cur_state           <= STATE_STOP_NEXT;
          end if;

        --  SDRam handling states.

        when START_SDRAM            =>
          if (Collar_Control_useSDRAM_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_SDRAM_On_e))  <= '1';
            next_state        <= START_SDRAM_WAITDONE;
            cur_state         <= STATE_ON_WAIT;
          else
            cur_state         <= STATE_START_NEXT;
          end if;

        when START_SDRAM_WAITDONE   =>
          sdram_start_out     <= '1';

          if (sdram_started = '1') then
            sdram_start_out   <= '0' ;
            cur_state         <= STATE_START_NEXT;
          end if;

        when STOP_SDRAM             =>
          if (Collar_Control_useSDRAM_c = '1') then
            sdram_stop_out    <= '1' ;

            if (sdram_stopped = '1') then
              sdram_stop_out  <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_SDRAM_On_e))  <= '0';
              next_state      <= STATE_STOP_NEXT;
              cur_state       <= STATE_ON_WAIT;
            end if ;
          else
            cur_state         <= STATE_STOP_NEXT;
          end if;

        --  Handle the MEMS microphones.

        when START_MEMS             =>
          if (Collar_Control_usePDMmic_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_MicRightOn_e))  <= '1';
            pc_control_reg (ControlSignals'pos (Ctl_MicLeftOn_e))   <= '1';
            next_state        <= START_MEMS_WAITDONE;
            cur_state         <= STATE_ON_WAIT;
          else
            cur_state         <= STATE_START_NEXT;
          end if;

        when START_MEMS_WAITDONE    =>
          mems_start_out      <= '1';

          if (mems_started = '1') then
            mems_start_out    <= '0' ;
            cur_state         <= STATE_START_NEXT;
          end if;

        when STOP_MEMS              =>
          if (Collar_Control_usePDMmic_c = '1') then
            mems_stop_out     <= '1' ;

            if (mems_stopped = '1') then
              mems_stop_out   <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_MicRightOn_e)) <= '0';
              pc_control_reg (ControlSignals'pos (Ctl_MicLeftOn_e))  <= '0';
              next_state      <= STATE_STOP_NEXT;
              cur_state       <= STATE_ON_WAIT;
            end if ;
          else
            cur_state         <= STATE_STOP_NEXT;
          end if;

        --  Handle the Inertial Movement Unit.

        when START_IMU              =>
          if (Collar_Control_useInertial_c = '1') then
            --Audio Recording Collar for now turns on both 1p8 and 2p5 at
            --the same time. See the Audio_Recording_Collar CPLD top level.
            pc_control_reg (ControlSignals'pos (Ctl_InertialOn1p8_e)) <= '1';
            pc_control_reg (ControlSignals'pos (Ctl_InertialOn2p5_e)) <= '1';
            next_state        <= START_IMU_WAITDONE;
            cur_state         <= STATE_ON_WAIT;
          else
            cur_state         <= STATE_START_NEXT;
          end if;

        when START_IMU_WAITDONE     =>
          if (imu_delay_count = to_unsigned (imu_delay_c,
                                             imu_delay_count'length)) then
            imu_start_out     <= '1';

            if (imu_started = '1') then
              imu_start_out   <= '0' ;
              cur_state       <= STATE_START_NEXT;
            end if;
          else
            imu_delay_count   <= imu_delay_count + 1;
          end if;

        when STOP_IMU               =>
          if (Collar_Control_useInertial_c = '1') then
            imu_stop_out      <= '1' ;

            if (imu_stopped = '1') then
              imu_stop_out    <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_InertialOn1p8_e)) <= '0';
              pc_control_reg (ControlSignals'pos (Ctl_InertialOn2p5_e)) <= '0';
              next_state      <= STATE_STOP_NEXT;
              cur_state       <= STATE_ON_WAIT;
            end if ;
          else
            cur_state         <= STATE_STOP_NEXT;
          end if;

        --  Handle the GPS.
        --  The scheduler will turn the device on and off if it is used.

        when START_GPS              =>
          if (Collar_Control_useGPS_c = '1') then
            if (Collar_Control_useScheduler_c = '1') then
              pc_control_reg (ControlSignals'pos (Ctl_GPS_On_e))  <= '0';
            else
              pc_control_reg (ControlSignals'pos (Ctl_GPS_On_e))  <= '1';
            end if ;

            next_state        <= START_GPS_PULSE;
            cur_state         <= STATE_ON_WAIT;
          else
            cur_state         <= STATE_START_NEXT;
          end if ;

        when START_GPS_PULSE        =>
          gps_start_out       <= '1';
          cur_state           <= START_GPS_WAITDONE;

        when START_GPS_WAITDONE     =>
          gps_start_out       <= '0';

          if (gps_started = '1') then
            cur_state         <= STATE_START_NEXT;
          end if;

        when STOP_GPS               =>
          if (Collar_Control_useGPS_c = '1') then
            gps_stop_out      <= '1' ;

            if (gps_stopped = '1') then
              gps_stop_out    <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_GPS_On_e))  <= '0';
              next_state      <= STATE_STOP_NEXT;
              cur_state       <= STATE_ON_WAIT;
            end if ;
          else
            cur_state         <= STATE_STOP_NEXT;
          end if ;

        --  Handle the data transmitter.
        --  The scheduler will turn the device on and off if it is used.

        when START_TXRX             =>
          if (Collar_Control_useRadio_c = '1') then
            if (Collar_Control_useScheduler_c = '1') then
              pc_control_reg (ControlSignals'pos (Ctl_DataTx_On_e))  <= '0';
            else
              pc_control_reg (ControlSignals'pos (Ctl_DataTx_On_e))  <= '1';
            end if ;

            next_state          <= START_TXRX_WAITDONE;
            cur_state           <= STATE_ON_WAIT;
          else
            cur_state           <= STATE_START_NEXT;
          end if ;

        when START_TXRX_WAITDONE    =>
          txrx_start_out        <= '1';

          if (txrx_started = '1') then
            txrx_start_out      <= '0' ;
            cur_state           <= STATE_START_NEXT;
          end if;

        when STOP_TXRX              =>
          if (Collar_Control_useRadio_c = '1') then
            txrx_stop_out       <= '1' ;

            if (txrx_stopped = '1') then
              txrx_stop_out     <= '0' ;
              pc_control_reg (ControlSignals'pos (Ctl_DataTX_On_e))  <= '0';
              next_state        <= STATE_STOP_NEXT;
              cur_state         <= STATE_ON_WAIT;
            end if ;
          else
            cur_state           <= STATE_STOP_NEXT;
          end if ;

        --  Handle the I2C Bus.

        when START_I2C              =>
          if (Collar_Control_useI2C_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_vcc1p8_aux_ctrl_e))  <= '1';
            next_state          <= STATE_START_NEXT;
            cur_state           <= STATE_ON_WAIT;
          else
            cur_state           <= STATE_START_NEXT;
          end if;

        when STOP_I2C               =>
          if (Collar_Control_useI2C_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_vcc1p8_aux_ctrl_e))  <= '0';
            next_state          <= STATE_STOP_NEXT;
            cur_state           <= STATE_ON_WAIT;
          else
            cur_state           <= STATE_STOP_NEXT;
          end if ;

        --  Handle the real time clock.

        when START_RTC              =>
          if (Collar_Control_useI2C_c = '1') then
            rtc_start_out       <= '1';

            if (rtc_started = '1') then
              rtc_start_out     <= '0' ;
              cur_state         <= STATE_START_NEXT;
            end if;
          else
            cur_state           <= STATE_START_NEXT;
          end if;

        when STOP_RTC               =>
          if (Collar_Control_useI2C_c = '1') then
            rtc_stop_out        <= '1' ;

            if (rtc_stopped = '1') then
              rtc_stop_out      <= '0' ;
              cur_state         <= STATE_STOP_NEXT;
            end if ;
          else
            cur_state           <= STATE_STOP_NEXT;
          end if ;

        --  Handle the battery monitor.

        when START_BATMON           =>
          if (Collar_Control_useI2C_c = '1') then
            batmon_start_out    <= '1';

            if (batmon_started = '1') then
              batmon_start_out  <= '0' ;
              cur_state         <= STATE_START_NEXT;
            end if;
          else
           cur_state            <= STATE_START_NEXT;
          end if;

        when STOP_BATMON            =>
          if (Collar_Control_useI2C_c = '1') then
            batmon_stop_out     <= '1' ;

            if (batmon_stopped = '1') then
              batmon_stop_out   <= '0' ;
              cur_state         <= STATE_STOP_NEXT;
            end if ;
          else
            cur_state           <= STATE_STOP_NEXT;
          end if ;

        --  Handle flash block.

        when START_FLASHBLOCK       =>
          if (Collar_Control_useFlashBlock_c = '1') then
            cur_state           <= START_FLASHBLOCK_WAITDONE;
          else
            cur_state           <= STATE_START_NEXT;
          end if;

        when START_FLASHBLOCK_WAITDONE =>
          flashblock_start_out    <= '1';

          if (flashblock_started = '1') then
            flashblock_start_out  <= '0' ;
            cur_state             <= STATE_START_NEXT;
          end if;

        when STOP_FLASHBLOCK          =>
          flashblock_stop_out   <= '1' ;

          if (flashblock_stopped = '1') then
            flashblock_stop_out <= '0' ;
            cur_state           <= STATE_STOP_NEXT;
          end if ;

        --  Handle the on/off scheduler.
        --  The scheduler will turn the system on and off if it is used.

        when START_ONOFF              =>
          if (Collar_Control_useScheduler_c = '1') then
            onoff_start_out     <= '1';

            if (onoff_started = '1') then
              onoff_start_out   <= '0' ;
              cur_state         <= STATE_START_NEXT;
            end if;
          else
            cur_state           <= STATE_START_NEXT;
          end if ;

        when STOP_ONOFF               =>
          if (Collar_Control_useScheduler_c = '1') then
            onoff_stop_out      <= '1' ;

            if (onoff_stopped = '1') then
              onoff_stop_out    <= '0' ;
              cur_state         <= STATE_STOP_NEXT;
            end if ;
          else
            cur_state           <= STATE_STOP_NEXT;
          end if ;

        --  Turn off the system.

        when STOP_FPGA =>
          pc_control_reg (ControlSignals'pos (Ctl_FPGA_Shutdown_e))  <= '1';

      end case;

    end if;
  end process startup_shutdown_state_machine;


end rtl ;