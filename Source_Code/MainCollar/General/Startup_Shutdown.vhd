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
use WORK.PC_STATUSCONTROL_PKG.ALL;
use WORK.Collar_Control_pkg.ALL;

use WORK.SHARED_SDC_VALUES_PKG.ALL ;


LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


--
--! @brief      Sequence the startup of system components
--! @details
--!
--! @param    pc_control_reg_out  Control register sent to CPLD
--! @param    pc_status_set       Status register has been set.
--!
--! @param    sd_contr_start_out       Start bit to the microsd_controller.
--! @param    sd_contr_done_in         Microsd_Controller startup done.
--!
--! @param    sdram_start_out          Start bit to the sdram_controller.
--! @param    sdram_done_in            sdram_controller startup done in
--!
--! @param    imu_start_out            IMU startup bit out
--! @param    imu_done_in              IMU startup startup done in
--!
--! @param    mems_start_out           MEMS startup bit out
--! @param    mems_done_in             MEMS startup startup done in
--!
--! @param    mag_start_out            MagMem startup bit out (populate buffer)
--! @param    mag_done_in              MagMem startup startup done
--!
--! @param    gps_start_out            GPS startup bit out
--! @param    gps_done_in              GPS startup startup done in
--!
--! @param    txrx_start_out           Transceiver startup bit out
--! @param    txrx_done_in             Transceiver startup done in
--!    
--! @param    shutdown_in             Initiate shutdown of entire system
--!    
--! @param    statctl_startup_out     Give permissions to statctl to start.
--!    
--! @param    rem_cap_mah_valid_in    Bat Capcity from Batmonitor is valid. 
--! @param    rem_cap_mah_in          Bat Capcity as read from Batmonitor.


--!


entity Startup_Shutdown is

  Generic (
    clk_freq_g            : natural := 50e6
    );
  Port (
    clk                 : in    std_logic ;
    rst_n               : in    std_logic ;

    pc_control_reg_out  : out   std_logic_vector (ControlSignalsCnt_c-1
                                                  downto 0) ;
                                                  
    pc_control_reg_in  : in   std_logic_vector (ControlSignalsCnt_c-1
                                                  downto 0) ;

    pc_status_set_in    : in    std_logic ;

    sd_contr_start_out  : out   std_logic ;
    sd_contr_done_in    : in    std_logic ;

    sdram_start_out     : out   std_logic ;
    sdram_done_in       : in    std_logic ;

    imu_start_out       : out   std_logic ;
    imu_done_in         : in    std_logic ;
    
    rtc_start_out       : out   std_logic ;
    rtc_done_in         : in    std_logic ;
    
    batmon_start_out    : out   std_logic ;
    batmon_done_in      : in    std_logic ;

    mems_start_out      : out   std_logic ;
    mems_done_in        : in    std_logic ;

    mag_start_out       : out   std_logic ;
    mag_done_in         : in    std_logic ;

    gps_start_out       : out   std_logic ;
    gps_done_in         : in    std_logic ;

    txrx_start_out      : out   std_logic ;
    txrx_done_in        : in    std_logic ;
    
    shutdown_in         : in    std_logic ;
    
    statctl_startup_out   : out std_logic;
    
    rem_cap_mah_valid_in  : in   std_logic ; 
    rem_cap_mah_in        : in   std_logic_vector (15 downto 0)

) ;

end Startup_Shutdown ;


architecture Behavior of Startup_Shutdown is

  type STARTUP_STATE is   (
    STATE_WAIT,
    STATE_ON_WAIT,

    -- START_SDLOADER,
    -- START_SDLOADER_WAITDONE,

    START_SDCTRL,
    START_SDCTRL_WAITDONE,

    START_SDRAM,
    START_SDRAM_WAITDONE,

    START_MAGRAM,
    START_MAGRAM_WAITDONE,

    START_GPS,
    START_GPS_WAITDONE,

    START_MEMS,
    START_MEMS_WAITDONE,

    START_IMU,
    START_IMU_WAITDONE,

    START_TXRX,
    START_TXRX_WAITDONE,
    
    START_RTC,
    START_RTC_WAITDONE,
    
        
    START_BATMON,
    START_BATMON_WAITDONE,

    
    STATE_DONE,
    
    STOP_WAIT,
    STOP_WAIT_DEBUG,
    
    STOP_SDCTRL,
    --STOP_SDCTRL_WAITDONE,
    
    STOP_SDRAM,
    --STOP_SDRAM_WAITDONE,
    
    STOP_MAGRAM,
    --STOP_MAGRAM_WAITDONE,
    
    STOP_GPS,
    --STOP_GPS_WAITDONE,
    
    STOP_MEMS,
    --STOP_MEMS_WAITDONE,
    
    STOP_IMU,
    --STOP_IMU_WAITDONE,
    
    STOP_TXRX,
    
    STOP_FPGA

  );

  signal cur_state        : STARTUP_STATE;
  signal next_state       : STARTUP_STATE;

  --  Synchronization signals.

  signal pc_status_set_s  : std_logic ;
  signal sd_contr_done_s  : std_logic ;
  signal sdram_done_s     : std_logic ;
  signal imu_done_s       : std_logic ;
  signal mems_done_s      : std_logic ;
  signal mag_done_s       : std_logic ;
  signal gps_done_s       : std_logic ;
  signal txrx_done_s      : std_logic ;
  signal shutdown_s       : std_logic ;
  signal rtc_done_s       : std_logic;
  signal batmon_done_s    : std_logic;

  signal pc_status_set    : std_logic ;
  signal sd_contr_done    : std_logic ;
  signal sdram_done       : std_logic ;
  signal imu_done         : std_logic ;
  signal mems_done        : std_logic ;
  signal mag_done         : std_logic ;
  signal gps_done         : std_logic ;
  signal txrx_done        : std_logic ;
  signal shutdown         : std_logic;
  signal rtc_done         : std_logic;
  signal batmon_done      : std_logic;
  signal pc_status_set_follower :std_logic;
  
  
  
  --Starting to talk to the IMU immediately after powering it on
  --does not work. This timeout it set for one second.
  constant imu_delay : natural := spi_clk_freq_c * 1;
  signal    imu_delay_count :  unsigned(natural(trunc(log2(real(
                              imu_delay-1)))) downto 0);  

  --Debug
  signal sd_contr_start_out_debug : std_logic_vector(0 downto 0);

  signal pc_control_reg : std_logic_vector (ControlSignalsCnt_c-1
                                            downto 0) := (others => '0') ;

  --Pure Debug
  signal start_signal : std_logic_vector(0 downto 0);
  
  --DEBUG SIGNALS
  signal rtc_startup  : std_logic_vector(0 downto 0);
  constant shutdown_delay : natural := spi_clk_freq_c * 30;
  signal  shutdown_delay_count :  unsigned(natural(trunc(log2(real(
                            shutdown_delay-1)))) downto 0);  
  
  signal main_on_debug : std_logic_vector(0 downto 0);
  signal recharge_on_debug : std_logic_vector(0 downto 0);
  signal solar_on_debug : std_logic_vector(0 downto 0);
  
begin

  pc_control_reg_out <= pc_control_reg;

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
      sd_contr_done           <= '0';
      sd_contr_done_s         <= '0';
      sdram_start_out         <= '0';
      sdram_done              <= '0';
      sdram_done_s            <= '0';
      imu_start_out           <= '0';
      imu_done                <= '0';
      imu_done_s              <= '0';
      mems_start_out          <= '0';
      mems_done               <= '0';
      mems_done_s             <= '0';
      mag_start_out           <= '0';
      mag_done                <= '0';
      mag_done_s              <= '0';
      gps_start_out           <= '0';
      gps_done                <= '0';
      gps_done_s              <= '0';
      txrx_start_out          <= '0';
      txrx_done               <= '0';
      txrx_done_s             <= '0';
      shutdown                <= '0';
      shutdown_s              <= '0';
      batmon_done             <= '0';
      batmon_done_s           <= '0';
      rtc_done                <= '0';
      rtc_done_s              <= '0';
      
      
      StatCtl_startup_out      <= '0';

    elsif (falling_edge (clk)) then

      --  Synchronize input signals from other clock domains.

      pc_status_set           <= pc_status_set_s ;
      sd_contr_done           <= sd_contr_done_s ;
      sdram_done              <= sdram_done_s ;
      imu_done                <= imu_done_s ;
      mems_done               <= mems_done_s ;
      mag_done                <= mag_done_s ;
      gps_done                <= gps_done_s ;
      txrx_done               <= txrx_done_s ;
      shutdown                <= shutdown_s;
      batmon_done             <= batmon_done_s;
      rtc_done                <= rtc_done_s;

    elsif (rising_edge (clk)) then

      pc_status_set_s         <= pc_status_set_in ;
      sd_contr_done_s         <= sd_contr_done_in ;
      sdram_done_s            <= sdram_done_in ;
      imu_done_s              <= imu_done_in ;
      mems_done_s             <= mems_done_in ;
      mag_done_s              <= mag_done_in ;
      gps_done_s              <= gps_done_in ;
      txrx_done_s             <= txrx_done_in ;
      shutdown_s              <= shutdown_in ;
      batmon_done_s           <= batmon_done_in;
      rtc_done_s              <= rtc_done_in;

      case cur_state is

        when STATE_ON_WAIT    =>
          if (pc_status_set_follower /= pc_status_set) then
              pc_status_set_follower <= pc_status_set;

            if (pc_status_set = '1') then
              cur_state             <= next_state;
            end if;
          end if;

        when STATE_WAIT =>
          if (start_signal(0) = '1') then
            cur_state <=  START_MAGRAM;
            

            StatCtl_startup_out <= '1';
          end if;


        when START_SDCTRL =>
        if (Collar_Control_useSDH_c = '1') then
          pc_control_reg (ControlSignals'pos (Ctl_SDCardOn_e))  <= '1';
          cur_state   <= STATE_ON_WAIT;
          next_state  <= START_SDCTRL_WAITDONE;
        else
         cur_state   <= START_SDRAM;
        end if;

        when START_SDCTRL_WAITDONE =>
          sd_contr_start_out          <= '1';

          if (sd_contr_done = '1') then
            cur_state <=  START_SDRAM;
          end if;


        when START_SDRAM =>
         if (Collar_Control_useSDRAM_c = '1') then
          pc_control_reg (ControlSignals'pos (Ctl_SDRAM_On_e))  <= '1';
          next_state  <= START_SDRAM_WAITDONE;
          cur_state   <= STATE_ON_WAIT;
          else
          cur_state   <= START_MEMS;
          end if;

        when START_SDRAM_WAITDONE =>
          sdram_start_out    <= '1';

          if (sdram_done = '1') then
            cur_state <=  START_MEMS;
          end if;


        when START_MEMS =>
          if (Collar_Control_usePDMmic_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_MicRightOn_e))  <= '1';
            pc_control_reg (ControlSignals'pos (Ctl_MicLeftOn_e))  <= '1';
            next_state  <=  START_MEMS_WAITDONE;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  START_IMU;
          end if;

        when START_MEMS_WAITDONE =>
          mems_start_out    <= '1';

          if (mems_done = '1') then
            cur_state   <=  START_IMU;
          end if;


        when  START_IMU =>
          if (Collar_Control_useInertial_c = '1') then
            --Audio Recording Collar for now turns on both 1p8 and 2p5 at
            --the same time. See the Audio_Recording_Collar CPLD top level.
            pc_control_reg (ControlSignals'pos (Ctl_InertialOn1p8_e)) <= '1';
            pc_control_reg (ControlSignals'pos (Ctl_InertialOn2p5_e)) <= '1';
            next_state  <=  START_IMU_WAITDONE;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  START_GPS;
          end if;
          

        when  START_IMU_WAITDONE =>
        
          if (imu_delay_count = to_unsigned(imu_delay,imu_delay_count'length)) then
            --imu_delay_count <= to_unsigned(0,imu_delay_count'length);
            imu_start_out    <= '1';
              if (imu_done = '1') then
                cur_state <=  START_GPS;
              end if;
          else
            imu_delay_count <= imu_delay_count + 1;
          end if;
        
        


        when START_MAGRAM =>
          if (Collar_Control_useMagMem_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_MagMemOn_e))  <= '1';
            next_state  <=  START_MAGRAM_WAITDONE;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state <=  START_SDCTRL;
          end if;

        when START_MAGRAM_WAITDONE =>
          mag_start_out    <= '1';

          if (mag_done = '1') then
            cur_state     <=  START_SDCTRL;
          end if;


        when START_GPS =>
          if (Collar_Control_useGPS_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_GPS_On_e))  <= '1';
            next_state  <=  START_GPS_WAITDONE;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  START_TXRX;
          end if ;

        when START_GPS_WAITDONE =>
          gps_start_out    <= '1';

          if (gps_done = '1') then
            cur_state   <=  START_TXRX;
          end if;


        when START_TXRX =>
          if (Collar_Control_useRadio_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_DataTX_On_e))  <= '1';
            next_state  <=  START_TXRX_WAITDONE;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  START_RTC;
          end if ;

        when START_TXRX_WAITDONE =>
          txrx_start_out    <= '1';

          if (txrx_done = '1') then
            cur_state   <=  START_RTC;
          end if;
          
        when START_RTC =>
          if(Collar_Control_useI2C_c = '1') then 
            cur_state   <=  START_RTC_WAITDONE;
            pc_control_reg (ControlSignals'pos (Ctl_vcc1p8_aux_ctrl_e))  <= '1';
          else
            cur_state   <=  START_BATMON;
          end if;


        when START_RTC_WAITDONE =>
          rtc_start_out    <= '1';
                      
          if (rtc_done = '1') then
            cur_state   <=  START_BATMON;
          end if;
          
          
        when START_BATMON =>
          if(Collar_Control_useI2C_c = '1') then 
            cur_state   <=  START_BATMON_WAITDONE;
          else
           cur_state   <=  STATE_DONE;
          end if;
          
        when START_BATMON_WAITDONE =>
          batmon_start_out    <= '1';

          if (batmon_done = '1') then
            cur_state   <=  STATE_DONE;
          end if;
          

          
          


        when STATE_DONE           =>
          cur_state <= STOP_WAIT;
          
          
        --This state should be moved to individual entities which 
        --feed startup_shutdown. 
        --Evaluate stop conditions. 
        when STOP_WAIT  =>

          if (shutdown = '1') then
            next_state  <=  STOP_SDCTRL;
            cur_state   <=  STOP_WAIT_DEBUG;
          elsif ( (unsigned(rem_cap_mah_in) < to_unsigned(50,rem_cap_mah_in'length)) AND
            rem_cap_mah_valid_in = '1') then

            
            next_state  <=  STOP_SDCTRL;
            cur_state   <=  STOP_WAIT_DEBUG;
          end if;
          
        pc_control_reg  <= pc_control_reg OR pc_control_reg_in  ;

                 
        --Debug the main and recharge switches from here. 
        pc_control_reg (ControlSignals'pos (Ctl_MainPowerSwitch_e))  <= main_on_debug(0);
        pc_control_reg (ControlSignals'pos (Ctl_RechargeSwitch_e))  <= recharge_on_debug(0);
        pc_control_reg (ControlSignals'pos (Ctl_SolarCtlShutdown_e))  <= solar_on_debug(0);
        
        
        
          
        when STOP_WAIT_DEBUG   =>
          if (shutdown_delay_count = to_unsigned(shutdown_delay,shutdown_delay_count'length)) then
            cur_state <= next_state;
          else
            shutdown_delay_count <= shutdown_delay_count + 1;
          end if;



        when STOP_SDCTRL =>
        if (Collar_Control_useSDH_c = '1') then
          pc_control_reg (ControlSignals'pos (Ctl_SDCardOn_e))  <= '0';
          cur_state   <= STATE_ON_WAIT;
          next_state  <= STOP_SDRAM;
        else
           cur_state   <= STOP_SDRAM;
        end if;

        when STOP_SDRAM =>
        if (Collar_Control_useSDRAM_c = '1') then
          pc_control_reg (ControlSignals'pos (Ctl_SDRAM_On_e))  <= '0';
          next_state  <= STOP_MEMS;
          cur_state   <= STATE_ON_WAIT;
        else
        cur_state   <= STOP_MEMS;
        
        end if;

        when STOP_MEMS =>
          if (Collar_Control_usePDMmic_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_MicLeftOn_e))  <= '0';
            next_state  <=  STOP_IMU;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  STOP_IMU;
          end if;

        when  STOP_IMU =>
          if (Collar_Control_useInertial_c = '1') then
            --Audio Recording Collar for now turns on both 1p8 and 2p5 at
            --the same time. See the Audio_Recording_Collar CPLD top level.
            pc_control_reg (ControlSignals'pos (Ctl_InertialOn1p8_e)) <= '0';
            pc_control_reg (ControlSignals'pos (Ctl_InertialOn2p5_e)) <= '0';
            next_state  <=  STOP_MAGRAM;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  STOP_MAGRAM;
          end if;


        when STOP_MAGRAM =>
          if (Collar_Control_useMagMem_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_MagMemOn_e))  <= '0';
            next_state  <=  STOP_GPS;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state <=  STOP_GPS;
          end if;

        when STOP_GPS =>
          if (Collar_Control_useGPS_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_GPS_On_e))  <= '0';
            next_state  <=  STOP_TXRX;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  STOP_TXRX;
          end if ;

        when STOP_TXRX =>
          if (Collar_Control_useRadio_c = '1') then
            pc_control_reg (ControlSignals'pos (Ctl_DataTX_On_e))  <= '0';
            next_state  <=  STOP_FPGA;
            cur_state   <=  STATE_ON_WAIT;
          else
            cur_state   <=  STOP_FPGA;
          end if ;

          
        when STOP_FPGA =>
          pc_control_reg (ControlSignals'pos (Ctl_FPGA_Shutdown_e))  <= '1';
          
          


      end case;

    end if;
  end process startup_shutdown_state_machine;




end Behavior ;