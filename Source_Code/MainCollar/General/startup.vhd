-- @file       startup.vhd
-- @brief      Sequence the startup of the entities of the collar project
-- @details    
-- @author     Chris Casebeer
-- @date       10_28_2014
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
use WORK.PC_STATUSCONTROL_PKG.ALL ;


LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;


--
--! @brief      Sequence the startup of system components
--! @details    
--!         
--! @param    pc_control_reg_out  Control register sent to CPLD
--! @param    pc_status_set   Status register has been set. 
--!
--! @param    sd_contr_start_out          : out  std_logic ;       
--! @param    sd_contr_done_in            : in  std_logic ;
--!
--! @param    sdram_start_out             : out  std_logic ;
--! @param    sdram_done_in               : in  std_logic ;
--!
--! @param    imu_start_out              : out std_logic ;
--! @param    imu_done_in                : in std_logic ;
--!
--! @param    mems_start_out            : out std_logic ;
--! @param    mems_done_in              : in  std_logic ;
--!
--! @param    mag_start_out             : out   std_logic ;
--! @param    mag_done_in               : in    std_logic ;
--!
--! @param    gps_start_out             : out   std_logic ;
--! @param    gps_done_in               : in    std_logic ;
--!


entity Startup is


  Port (
    clk                 : in    std_logic ;
    rst_n               : in    std_logic ;
    
    
    pc_control_reg_out  : out std_logic_vector (ControlSignalsCnt_c-1
                                          downto 0);
                                                      
    pc_status_set_in        : in std_logic;
 
    sd_contr_start_out        : out  std_logic ;       
    sd_contr_done_in          : in  std_logic ;
    
    sdram_start_out           : out  std_logic ;
    sdram_done_in             : in  std_logic ;
      
    imu_start_out             : out std_logic ;
    imu_done_in               : in std_logic ;
    
    mems_start_out            : out std_logic ;
    mems_done_in              : in  std_logic ;
    
    mag_start_out             : out   std_logic ;
    mag_done_in               : in    std_logic ;
    
    gps_start_out             : out   std_logic ;
    gps_done_in               : in    std_logic 
    
    

) ;

end Startup ;


architecture Behavior of Startup is



type STARTUP_STATE is   (
    STATE_WAIT,
    
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
    START_MEMS_WAITDONE

    );
    
signal  cur_state : STARTUP_STATE;
    
    
signal pc_status_set_follower :std_logic;
signal pc_status_set_s        :std_logic;
signal pc_status_set          :std_logic;



  -- alias CTL_MainPowerSwitch     : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_MainPowerSwitch_e)) ;
  -- alias CTL_RechargeSwitch      : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_RechargeSwitch_e)) ;
  -- alias CTL_SolarCtlShutdown    : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_SolarCtlShutdown_e)) ;
  -- alias CTL_LevelShifter3p3     : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_LevelShifter3p3_e)) ;
  -- alias CTL_LevelShifter1p8     : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_LevelShifter1p8_e)) ;
  -- alias CTL_InertialOn1p8       : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_InertialOn1p8_e)) ;
  -- alias CTL_InertialOn2p5       : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_InertialOn2p5_e)) ;
  -- alias CTL_MicLeftOn           : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_MicLeftOn_e)) ;
  -- alias CTL_MicRightOn          : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_MicRightOn_e)) ;
  -- alias CTL_SDRAM_On            : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_SDRAM_On_e)) ;
  -- alias CTL_SDCardOn            : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_SDCardOn_e)) ;
  -- alias CTL_MagMemOn            : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_MagMemOn_e)) ;
  -- alias CTL_GPS_On              : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_GPS_On_e)) ;
  -- alias CTL_DataTX_On           : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_DataTX_On_e)) ;
  -- alias CTL_FPGA_Shutdown       : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_FPGA_Shutdown_e)) ;
  -- alias CTL_FLASH_Granted       : std_logic is
        -- PC_ControlReg (ControlSignals'pos (Ctl_FLASH_Granted_e)) ;

--Debug
signal sd_contr_start_out_debug : std_logic_vector(0 downto 0);

signal pc_control_reg : std_logic_vector (ControlSignalsCnt_c-1
                                          downto 0);
       
--Pure Debug       
signal start_mems_signal : std_logic_vector(0 downto 0);
    
begin

pc_control_reg_out <= pc_control_reg;

  -- in_system_probe0 : altsource_probe
    -- GENERIC MAP (
      -- enable_metastability => "NO",
      -- instance_id => "sds",
      -- probe_width => 1,
      -- sld_auto_instance_index => "YES",
      -- sld_instance_index => 0,
      -- source_initial_value => "0",
      -- source_width => 1,
      -- lpm_type => "altsource_probe"
    -- )
    -- PORT MAP (
      -- probe => sd_contr_start_out_debug,
      -- source => sd_contr_start_out_debug
    -- );
    
   -- sd_contr_start_out <=  sd_contr_start_out_debug(0);
   
   
     -- in_system_probe1 : altsource_probe
    -- GENERIC MAP (
      -- enable_metastability => "NO",
      -- instance_id => "cr",
      -- probe_width => pc_control_reg'length,
      -- sld_auto_instance_index => "YES",
      -- sld_instance_index => 0,
      -- source_initial_value => "0",
      -- source_width => pc_control_reg'length,
      -- lpm_type => "altsource_probe"
    -- )
    -- PORT MAP (
      -- probe => pc_control_reg,
      -- source => pc_control_reg
    -- );
    
    
      in_system_probe0 : altsource_probe
    GENERIC MAP (
      enable_metastability => "NO",
      instance_id => "sds",
      probe_width => 1,
      sld_auto_instance_index => "YES",
      sld_instance_index => 0,
      source_initial_value => "0",
      source_width => 1,
      lpm_type => "altsource_probe"
    )
    PORT MAP (
      probe => start_mems_signal,
      source => start_mems_signal
    );
    






    
startup_state_machine:  process (clk, rst_n)
begin
  if (rst_n = '0') then
  
    cur_state <= STATE_WAIT;
    sd_contr_start_out    <= '0';
    sdram_start_out       <= '0';  
    imu_start_out         <= '0';
    mems_start_out        <= '0';
    mag_start_out         <= '0';
    gps_start_out         <= '0';
   

 
  elsif (clk'event and clk = '1') then
  
  
  pc_status_set_s <= pc_status_set_in;
  pc_status_set <= pc_status_set_s;
    
  
    case cur_state is
    
      when STATE_WAIT =>
        cur_state <=  START_SDCTRL;

      when START_SDCTRL =>
        pc_control_reg (ControlSignals'pos (Ctl_SDCardOn_e))  <= '1';
        cur_state <=  START_SDCTRL_WAITDONE;
        
      when START_SDCTRL_WAITDONE =>
        if (pc_status_set_follower /= pc_status_set) then
          pc_status_set_follower <= pc_status_set;
            if (pc_status_set = '1') then
              sd_contr_start_out    <= '1';
              cur_state <=  START_SDRAM;
            end if;
        end if;
  
      when START_SDRAM =>
        pc_control_reg (ControlSignals'pos (Ctl_SDRAM_On_e))  <= '1';
        cur_state <=  START_SDRAM_WAITDONE;
        
      when START_SDRAM_WAITDONE =>
       if (pc_status_set_follower /= pc_status_set) then
          pc_status_set_follower <= pc_status_set;
            if (pc_status_set = '1') then
              sdram_start_out    <= '1';
            end if;
        end if;
        
        if (sdram_done_in = '1') then
          cur_state <=  START_MAGRAM;
        end if;
        
        
        
            
      when START_MEMS =>
        if (start_mems_signal(0) = '1') then
          pc_control_reg (ControlSignals'pos (Ctl_MicLeftOn_e))  <= '1';
          cur_state <=  START_MEMS_WAITDONE;
        end if;
      
      when START_MEMS_WAITDONE =>
        if (pc_status_set_follower /= pc_status_set) then
          pc_status_set_follower <= pc_status_set;
            if (pc_status_set = '1') then
              mems_start_out    <= '1';
              cur_state <=  START_GPS;
            end if;
        end if;
  
      when START_MAGRAM =>
        mag_start_out <= '1';
        cur_state <=  START_MAGRAM_WAITDONE;

      when START_MAGRAM_WAITDONE =>
        cur_state <=  START_MEMS;
  
      when START_GPS =>
        gps_start_out <= '1';
        cur_state <=  START_GPS_WAITDONE;
        
      when START_GPS_WAITDONE =>
  
    
    end case;
      
  end if;
end process startup_state_machine;
    

end Behavior ;