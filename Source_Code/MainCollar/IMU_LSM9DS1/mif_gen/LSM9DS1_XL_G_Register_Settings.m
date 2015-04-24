
%--------------------------------------------------------------------------
% Register Settings for the ST Microelectronics LSM9DS1 9-axis Motion Sensor 
%
% To be used in setting initial register values on power up.
%
% The following files are needed for a complete LSM9DS1 IMU register set-up.
% LSM9DS1_XL_G_Register_Defualts.m
% LSM9DS1_XL_G_Register_Settings.m
% LSM9DS1_M_Register_Defualts.m
% LSM9DS1_M_Register_Settings.m
%
%
% The run process is as follows. 
% Edit and run LSM9DS1_XL_G_Register_Settings.m followed by edit and run of 
% LSM9DS1_M_Register_Settings.m. This sequence will produce 'LSM9DS1_Register_Settings_Startup_Memory.mif'
% This mif file should be used to initialize the two port memory that exists in LSM9DS1_top.vhd
% 
% To change the default settings, go the particular register below
% and change the bit settings. Then run the script to generate VHDL code
% that can be cut and pasted into the init/powerup section. 
% There are xx registers, yy which are writeable (See Register Map, 
% Table 17, page 38 of data sheet):
%
% Writeable Registers:
%
%       ------------------------------------------------
%       Accelerometer/Gyroscope Writeable Registers
%       ------------------------------------------------
%       ACT_THS -
%       ACT_DUR - 
%       INT_GEN_CFG_XL -
%       INT_GEN_THS_X_XL -
%       INT_GEN_THS_Y_XL -
%       INT_GEN_THS_Z_XL -
%       INT_GEN_DUR_XL - 
%       REFERENCE_G - 
%       INT1_CTRL -
%       INT2_CTRL -
%       CTRL_REG1_G -
%       CTRL_REG2_G -
%       CTRL_REG3_G -
%       ORIENT_CFG_G -
%       CTRL_REG4 
%       CTRL_REG5_XL 
%       CTRL_REG6_XL 
%       CTRL_REG7_XL 
%       CTRL_REG8 
%       CTRL_REG9 
%       CTRL_REG10 
%       FIFO_CTRL 
%       INT_GEN_CFG_G 
%       INT_GEN_THS_XH_G 
%       INT_GEN_THS_XL_G 
%       INT_GEN_THS_YH_G 
%       INT_GEN_THS_YL_G 
%       INT_GEN_THS_ZH_G 
%       INT_GEN_THS_ZL_G 
%       INT_GEN_DUR_G 
%       --------------------------------
%       Magnetometer Writeable Registers
%       --------------------------------
%       OFFSET_X_REG_L_M
%       OFFSET_X_REG_H_M 
%       OFFSET_Y_REG_L_M 
%       OFFSET_Y_REG_H_M 
%       OFFSET_Z_REG_L_M 
%       OFFSET_Z_REG_H_M 
%       CTRL_REG1_M 
%       CTRL_REG2_M 
%       CTRL_REG3_M 
%       CTRL_REG4_M 
%       CTRL_REG5_M 
%       INT_CFG_M
%
%
%
%
%
%
%%DATA REGISTERS OF INTEREST.
%
%One can read all 6 registers with auto increment on. 
%
%OUT_X_L_G % Address 18
%OUT_X_H_G
%OUT_Y_L_G
%OUT_Y_H_G
%OUT_Z_L_G
%OUT_Z_H_G % Address 1D
%
%One can read all 6 registers with auto increment on. 
%OUT_X_L_XL % Address 28
%OUT_X_H_XL
%OUT_Y_L_XL
%OUT_Y_H_XL
%OUT_Z_L_XL
%OUT_Z_H_XL % Address 2D
%
%
% Script:   LSM9DS1_Register_Settings.m 
% Author:   Chris Casebeer
% Date:     November 20, 2014
%----------------------------------------------------------------------
clear all
close all


%--------------------------------------------------------------------------
%       ACT_THS  -  Gyroscope Activity Threshold Register
%       (page 41)
%--------------------------------------------------------------------------
name = 'ACT_THS';
description = 'Gyroscope : Activity Threshold Register';
% Register Address (in Hex)
address = '04';  
%------------------------------
% bit7 : SLEEP_ON_INACT_EN. Gyroscope operating mode during inactivity.
% 0 = Gyroscope in power down.
% 1 = Gyroscope in sleep mode. 
% DEFAULT = '0' 
bit7 = '0'; 
%------------------------------
% Bit6to0 : ACT_THS. Inactivity threshold. 
% DEFAULT = '0000000'
bit6to0 = '0000000'; 
%------------------------------
% Construct Register 1
%------------------------------
register{1}.name        = name;
register{1}.description = description;
register{1}.address     = address;  % (in Hex)
register{1}.data        = [bit7 bit6to0];

%----------------------------------------------------------------------
%       ACT_DUR  -  Inactivity duration register
%      (page 41)
%----------------------------------------------------------------------
name = 'ACT_DUR';
description = 'Inactivity Register';
% Register Address (in Hex)
address = '05';  
%------------------------------
%bit7to0 : ACT_DUR. Inactivity Duration
% DEFAULT = '00000000' 
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 2
%------------------------------
register{2}.name        = name;
register{2}.description = description;
register{2}.address     = address;
register{2}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_CFG_XL  -  Linear acceleration threshold interrupt generator
%       configuration register (page 41)
%----------------------------------------------------------------------
name = 'INT_GEN_CFG_XL';
description = 'Accelerometer : Threshold Interrupt Generator Setup Register';
% Register Address (in Hex)
address = '06';  
%------------------------------
% Bit7 : AOI_XL. AND/OR combination of the following interrupt events. 
% '1' = AND combination.
% '0' = OR combination.
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6 : 6D. 6-directional detection function for interrupt. 
% DEFAULT = '0'
bit6 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit5 : ZHIE_XL. Enable interrupt generation on XL Z axis high event. 
% '1' = Interrupt request on XL value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit5 = '0';
%------------------------------
% Bit4 : ZLIE_XL. Enable interrupt generation on XL Z axis low event. 
% '1' = Interrupt request on XL value lower than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit4 = '0';
%------------------------------
% Bit3 : YHIE_XL. Enable interrupt generation on XL Y axis high event. 
% '1' = Interrupt request on XL value lower than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit3 = '0';
%------------------------------
% Bit2 : YLIE_XL. Enable interrupt generation on XL Y axis low event. 
% '1' = Interrupt request on XL value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit2 = '0';
%------------------------------
% Bit1 : XHIE_XL. Enable interrupt generation on XL X axis high event. 
% '1' = Interrupt request on XL value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit1 = '0';
%------------------------------
% Bit0 : XLIE_XL. Enable interrupt generation on XL X axis low event. 
% '1' = Interrupt request on XL value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit0 = '0';
%------------------------------
% Construct Register 3
%------------------------------
register{3}.name        = name;
register{3}.description = description;
register{3}.address     = address;
register{3}.data        = [bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0];



%----------------------------------------------------------------------
%       INT_GEN_THS_X_XL  - X-axis acceleration threshold register
%       (page 42)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_X_XL';
description = 'X-axis acceleration threshold register';
% Register Address (in Hex)
address = '07';  
%------------------------------
% Bit7to0 : THS_XL_X. X-Axis interrupt threshold.
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 4
%------------------------------
register{4}.name        = name;
register{4}.description = description;
register{4}.address     = address;
register{4}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_Y_XL  - Y-axis acceleration threshold register
%       (page 42)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_Y_XL';
description = 'Y-axis acceleration threshold register';
% Register Address (in Hex)
address = '08';  
%------------------------------
% Bit7to0 : THS_XL_Y. Y-Axis interrupt threshold.
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 5
%------------------------------
register{5}.name        = name;
register{5}.description = description;
register{5}.address     = address;
register{5}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_Z_XL  - Z-axis acceleration threshold register
%       (page 43)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_Z_XL';
description = 'Z-axis acceleration threshold register';
% Register Address (in Hex)
address = '09';  
%------------------------------
% Bit7to0 : THS_XL_Z. Z-Axis interrupt threshold.
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 6
%------------------------------
register{6}.name        = name;
register{6}.description = description;
register{6}.address     = address;
register{6}.data        = [bit7to0];


%----------------------------------------------------------------------
%       INT_GEN_DUR_XL  - Duration of the Linear Acceleration Interrupt Pulse
%       (page 43)
%----------------------------------------------------------------------
name = 'INT_GEN_DUR_XL';
description = 'Duration of the Linear Acceleration Interrupt Pulse';
% Register Address (in Hex)
address = '0A';  
%------------------------------
%Bit7 : WAIT_XL. Wait function enabled. Wait for DUR_XL before exit interrupt.
% DEFAULT = '0'
bit7 = '0';  % (0: disable, 1: enable)
%------------------------------
%Bit6to0 : DUR_XL. Duration value.
% DEFAULT = '0000000'
bit6to0 = '0000000'; 
%------------------------------
% Construct Register 7
%------------------------------
register{7}.name        = name;
register{7}.description = description;
register{7}.address     = address;
register{7}.data        = [bit7 bit6to0];

%----------------------------------------------------------------------
%       REFERENCE_G  -  Reference Value for gyroscopes digital high-pass
%       filter. (page 43)
%----------------------------------------------------------------------
name = 'REFERENCE_G';
description = 'Reference Value for gyroscopes digital high-pass filter';
% Register Address (in Hex)
address = '0B';  
%------------------------------
%Bit7to0 : REF_G. Reference value for gyroscope HPF.
% DEFAULT = '00000000'
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 8
%------------------------------
register{8}.name        = name;
register{8}.description = description;
register{8}.address     = address;
register{8}.data        = [bit7to0];



%----------------------------------------------------------------------
%       INT1_CTRL   -  INT1 pin interrupt configuration (page 43)
%----------------------------------------------------------------------
name = 'INT1_CTRL';
description = 'Set the interrupt type associated with this pin';
% Register Address (in Hex)
address = '0C';  
%------------------------------
% Bit7 : INT1_IG_G. Gyroscope interrupt enable on INT 1_A/G
% DEFAULT = '0'
bit7 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit6 : INT_IG_XL.  Accelerometer interrupt generator on INT 1_A/G.
% DEFAULT = '0'
bit6 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit5 : INT_FSS5. FSS5 interrupt enable on INT 1_A/G
% DEFAULT = '0'
bit5 = '0';  % (0: disable, 1: enable)
%------------------------------
% Bit4 : INT_OVR. Overrun interrupt on INT 1_A/G. 
% DEFAULT = '0' 
bit4 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit3 : INT_FTH.  FIFO threshold interrupt on INT 1_A/G.
% DEFAULT = '0' 
bit3 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit2 : INT_Boot. Boot status available on INT 1_A/G.
% DEFAULT = '0'
bit2 = '0';
%------------------------------
% Bit1 : INT1_DRDY_G
% 1 = Gyroscope Data Ready on INT 1_A/G pin Enabled
% 0 = Gyroscope Data Ready on INT 1_A/G pin Disabled
% DEFAULT = '0'
bit1 = '1'; 
%------------------------------
% Bit0 : INT1_DRDY_XL
% 1 = Accelerometer Data Ready on INT 1_A/G pin Enabled
% 0 = Accelerometer Data Ready on INT 1_A/G pin Disabled
% DEFAULT = '0'
bit0 = '0'; 
%------------------------------
% Construct Register 9
%------------------------------
register{9}.name        = name;
register{9}.description = description;
register{9}.address     = address;
register{9}.data        = [bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0];


%----------------------------------------------------------------------
%       INT2_CTRL   -  INT2 pin interrupt configuration (page 43)
%----------------------------------------------------------------------
name = 'INT2_CTRL';
description = 'Set the interrupt type associated with this pin';
% Register Address (in Hex)
address = '0D';  
%------------------------------
% Bit7 : INT2_INACT. Inactivity interrupt output signal. 
% 1 = No interrupt has been generated.
% 0 = One or more interrupt events have been generated.
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6 :  Must be set to zero for proper operation
% DEFAULT = '0'
bit6 = '0'; 
%------------------------------
% Bit5 : INT2_FSS5. FSS5 interrupt enable on INT 2_A/G
% DEFAULT = '0'
bit5 = '0';  % (0: disable, 1: enable)
%------------------------------
% Bit4 : INT2_OVR. Overrun interrupt on INT 2_A/G. 
% DEFAULT = '0' 
bit4 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit3 : INT2_FTH.  FIFO threshold interrupt on INT2_A/G.
% DEFAULT = '0' 
bit3 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit2 : INT2_DRDY_TEMP. Temperature data ready on INT2_A/G.
% DEFAULT = '0'
bit2 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit1 : INT2_DRDY_G
% 1 = Gyroscope Data Ready on INT 2_A/G pin Enabled
% 0 = Gyroscope Data Ready on INT 2_A/G pin Disabled
% DEFAULT = '0'
bit1 = '0';  
%------------------------------
% Bit0 : INT2_DRDY_XL
% 1 = Accelerometer Data Ready on INT 2_A/G pin Enabled
% 0 = Accelerometer Data Ready on INT 2_A/G pin Disabled
% DEFAULT = '0'
bit0 = '1'; 
%------------------------------
% Construct Register 10
%------------------------------
register{10}.name        = name;
register{10}.description = description;
register{10}.address     = address;
register{10}.data         = [bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0];


%----------------------------------------------------------------------
%       CTRL_REG1_G  -  ODR Selection and Bandwidth Selection
%       for accelerometer and gyroscope activated (page 45)
%----------------------------------------------------------------------
name = 'CTRL_REG1_G';
description = 'ODR, Full Scale Detection, and Bandwidth Selection for both Gyro/Accel';
% Register Address (in Hex)
address = '10';  
%------------------------------
% bit7to5 : ODR_G. Gyroscope output data rate selection. See Table 46 Page 45 for
%            options
% DEFAULT = '000' 
% '110' chooses ODR of 952 Hz and Cutoff of 100Hz after LPF1
bit7to6 = '000';
%------------------------------
% bit4to3 : FS_G. Gyroscope Full Scale Selection
% '00' = 245 dps
% '01' = 500 dps
% '10' = Not Available
% '11' = 2000 dps
% DEFAULT = '00'
bit4to3 = '00'; 
%------------------------------
% bit2 : Must be set to zeros for proper operation
% DEFAULT = '0' 
bit2 = '0';
%------------------------------
% bit1to0 : Gyroscope Bandwidth Selection after LPF2. See Table 47 Page 46.
% DEFAULT = '00'
bit1to0 = '00'; 
%------------------------------
% Construct Register 11
%------------------------------
register{11}.name        = name;
register{11}.description = description;
register{11}.address     = address;
register{11}.data        = [bit7to6 bit4to3 bit2 bit1to0];


%These two control registers kept at default values. 
%CTRL_REG2_G 
%CTRL_REG3_G

%----------------------------------------------------------------------
%       CTRL_REG2_G  -  Interrupt and Data Path Muxing for the Gyroscope 
%       Position of HPF and LPF before FIFO as well as interrupt position(page 48)
%----------------------------------------------------------------------
name = 'CTRL_REG2_G';
description = 'Interrupt and Data Path Muxing for the Gyroscope';
% Register Address (in Hex)
address = '11';  
%------------------------------
% bit7to4 : Must be set to zeros for proper operation
% DEFAULT = '0000' 
bit7to4 = '0000';
%------------------------------
% bit3to2 : INT_SEL. INT selection configuration. See Figure 28.
% DEFAULT = '00'
bit3to2 = '00'; 
%------------------------------
% bit1to0 : OUT_SEL. OUT selection configuration. See Figure 28.
% DEFAULT = '00' 
bit1to0 = '00';
%------------------------------
% Construct Register 12
%------------------------------
register{12}.name        = name;
register{12}.description = description;
register{12}.address     = address;
register{12}.data        = [bit7to4 bit3to2 bit1to0];


%----------------------------------------------------------------------
%       CTRL_REG3_G  -  Gyroscope Low Power,HP Filter Enable and Cutoff (page 47)
%----------------------------------------------------------------------
name = 'CTRL_REG3_G';
description = 'Gyroscope Low Power,HP Filter Enable and Cutoff';
% Register Address (in Hex)
address = '12';  
%------------------------------
% Bit7 : LP_mode. Low Power Mode Enable.
% DEFAULT = '0'
bit7 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit6 :  High Pass Filter enable. 
% DEFAULT = '0'
bit6 = '0';  % (0: disable, 1: enable)
%------------------------------
% Bit5to4 : Must be set to zeros for proper operation
% DEFAULT = '00'
bit5to4 = '00';  
%------------------------------
% Bit3to0 : HPCF_G. Gyroscope high pass filter cutoff frequency.
% DEFAULT = '0000' 
bit3to0 = '0000';
%------------------------------
% Construct Register 13
%------------------------------
register{13}.name        = name;
register{13}.description = description;
register{13}.address     = address;
register{13}.data        = [bit7 bit6 bit5to4 bit3to0];


%----------------------------------------------------------------------
%       ORIENT_CFG_G  -  Gyroscope axis signs and user orientation selection (page 48)
%----------------------------------------------------------------------
name = 'ORIENT_CFG_G';
description = 'Gyroscope axis signs and user orientation selection';
% Register Address (in Hex)
address = '13';  
%------------------------------
% Bit7to6 :  Must be set to zeros for proper operation
% DEFAULT = '00'
bit7to6 = '00'; 
%------------------------------
% Bit5 :  SignX_G. Pitch axis X angular rate sign.
% '0' = Positive Sign
% '1' = Negative Sign
% DEFAULT = '0'
bit5 = '0'; 
%------------------------------
% Bit4 :  SignY_G. Pitch axis Y angular rate sign.
% '0' = Positive Sign
% '1' = Negative Sign
% DEFAULT = '0'
bit4 = '0'; 
%------------------------------
% Bit3 :  SignZ_G. Pitch axis Z angular rate sign.
% '0' = Positive Sign
% '1' = Negative Sign
% DEFAULT = '0'
bit3 = '0'; 
%------------------------------
% Bit2to0 :  Orient. Directional user orientation selection.
% DEFAULT = '000'
bit2to0 = '000'; 
%------------------------------
% Construct Register 14
%------------------------------
register{14}.name        = name;
register{14}.description = description;
register{14}.address     = address;
register{14}.data        = [bit7to6 bit5 bit4 bit3 bit2to0];


%----------------------------------------------------------------------
%       CTRL_REG4  -  On/Off for Gyroscope Axis, Latched Interrupt, 4D/6D
%       position recognition (page 50-51)
%----------------------------------------------------------------------
name = 'CTRL_REG4';
description = 'On/Off for Gyroscope Axis, Latched Interrupt, 4D/6D position recognition';
% Register Address (in Hex)
address = '1E';  
%------------------------------
% Bit7to6 : Must be set to zeros for proper operation
% DEFAULT = '00' 
bit7to6 = '00';
%------------------------------
% Bit5 : Zen_G
% DEFAULT = '1' 
bit5 = '1'; % (0: disable, 1: enable)
%------------------------------
% Bit4 : Yen_G
% DEFAULT = '1' 
bit4 = '1'; % (0: High, 1: Low)
%------------------------------
% Bit3 : Xen_G
% DEFAULT = '1' 
bit3 = '1'; % (0: push-pull, 1: open drain)
%------------------------------
% Bit2 :  Must be set to zero for proper operation
% DEFAULT = '0' 
bit2 = '0'; 
%------------------------------
% Bit1 : Latched Interrupt
% DEFAULT = '0' 
bit1 = '0'; % (0: interrupt request not latched, 1: interrupt request latched)
%------------------------------
% Bit0 : 6D vs 4D interrupt generator position recognition
% DEFAULT = '0' 
bit0 = '0'; % (0: disable, 1: enable)

%------------------------------
% Construct Register 15
%------------------------------
register{15}.name        = name;
register{15}.description = description;
register{15}.address     = address;
register{15}.data        = [bit7to6 bit5 bit4 bit3 bit2 bit1 bit0];


%----------------------------------------------------------------------
%       CTRL_REG5_XL -  Decimation of Accelerometer Data and Axis On_Off (page 51)
%----------------------------------------------------------------------
name = 'CTRL_REG5_XL';
description = 'Decimation of Accelerometer Data and Axis On_Off';
% Register Address (in Hex)
address = '1F';  
%------------------------------
% Bit7to6 : Decimation of Acceleration Data on OUT REG/FIFO.
% '01' = update every 2 samples
% '10' = update every 4 samples
% '11' = update every 8 samples
% DEFAULT = '00' %No decimation 
bit7to6 = '00';
%------------------------------
% Bit5 : Zen_XL. Accelerometer Z-axis output enable.
% DEFAULT = '1' 
bit6to5 = '1'; % (0: disable, 1: enable)
%------------------------------
% Bit4 : Yen_XL. Accelerometer Y-axis output enable.
% DEFAULT = '1' 
bit4 = '1'; % (0: disable, 1: enable)
%------------------------------
% Bit3 : Xen_XL. Accelerometer X-axis output enable.
% DEFAULT = '1' 
bit3 = '1'; % (0: disable, 1: enable)
%------------------------------
% Bit2to0 :  Must be set to zero for proper operation
% DEFAULT = '000' 
bit2to0 = '000'; 
%------------------------------
% Construct Register 16
%------------------------------
register{16}.name        = name;
register{16}.description = description;
register{16}.address     = address;
register{16}.data        = [bit7to6 bit5 bit4 bit3 bit2to0];


%----------------------------------------------------------------------
%       CTRL_REG6_XL -  Accelerometer Only ODR, Full Scale, Bandwidth,
%       Anti Aliasing Filter Bandwidth (page 52)
%----------------------------------------------------------------------
name = 'CTRL_REG6_XL';
description = 'Accelerometer ODR, BW, AntiAliasing BW and Full-Scale Select';
% Register Address (in Hex)
address = '20';  
%------------------------------
% bit7to5 : Decimation of Acceleration Data on OUT REG/FIFO.
% '000' = Power Down
% '001' = 10Hz
% '010' = 50Hz
% '011' = 119Hz
% '100' = 238Hz
% '101' = 476Hz
% '110' = 952Hz
% DEFAULT = '000'
bit7to5 = '110';
%------------------------------
% bit4to3 : FS_XL full scale selection.
% '00' = +/- 2g
% '01' = N/A
% '10' = +/- 4g
% '11' = +/- 8g
% DEFAULT = '00' 
bit4to3 = '00';
%------------------------------
% Bit2 : BW_SCAL_ODR. Bandwidth Selection.
% '1' = Bandwidth selected according to BW_XL.
% '0' = Bandwidth determined by ODR selection (see table 64. page 52)
% DEFAULT = '0' 
bit2 = '0'; %
%------------------------------
% bit1to0 : BW_XL. Anti-aliasing filter bandwidth selection.
% '00' = 408Hz
% '01' = 211Hz
% '10' = 105Hz
% '11' = 50Hz
% DEFAULT = '00' 
bit1to0 = '00'; 
%------------------------------
% Construct Register 17
%------------------------------
register{17}.name        = name;
register{17}.description = description;
register{17}.address     = address;
register{17}.data        = [bit7to5 bit4to3 bit2 bit1to0];


%----------------------------------------------------------------------
%       CTRL_REG7_XL -  High Res Mode Accelerometer, HP/LP Filter Cutoff Select
%       Filtered Data Selection, and HPF enable on interrupt (page 53)
%----------------------------------------------------------------------
name = 'CTRL_REG7_XL';
description = 'Accelerometer High Res mode,Digital Filter and Select';
% Register Address (in Hex)
address = '21';  
%------------------------------
% Bit7 : High Resolution Mode for Accelerometer Data
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6to5 : Accelerometer Digital Filter (High Pass and Low Pass) cutoff frequency
%           selection. 
% '00' = ODR/50
% '01' = ODR/100
% '10' = ODR/9
% '11' = ODR/400
% DEFAULT = '00'
bit6to5 = '00';
%------------------------------
% Bit4to3 : Must be set to zero for proper operation 
% DEFAULT = '00'
bit4to3 = '00';
%------------------------------
% Bit2 : Filtered data selection.
% '0' = Internal Filter Bypassed
% '1' = Data from internal filter sent to output register
% DEFAULT = '0' 
bit2 = '0';
%------------------------------
% Bit1 : Must be set to zero for proper operation
% DEFAULT = '0' 
bit1 = '0'; %
%------------------------------
% Bit0 : High-pass filter enabled for acceleration sensor interrupt function.
% '0' = Filter bypassed
% '1' = Filter enabled
% DEFAULT = '0' 
bit0 = '0'; 
%------------------------------
% Construct Register 18
%------------------------------
register{18}.name        = name;
register{18}.description = description;
register{18}.address     = address;
register{18}.data        = [bit7to0];



%----------------------------------------------------------------------
%       CTRL_REG8 -  General Device Function Register. Reboot Memory Content,
%       block data update, interrupt active level, push_pull/open-drain interrupt pin
%       selection, SPI wire mode, address auto increment, big endian little endian selection
%       software reset   (page 53)
%----------------------------------------------------------------------
name = 'CTRL_REG8';
description = 'Device Function Register: Interrupt Levels, SPI Wire Number, endianess';
% Register Address (in Hex)
address = '22';  
%------------------------------
% Bit7 : BOOT. Reboot memory content. 
% '1' = Reboot Memory Content
% '0' = Normal Mode
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6 : BDU. Block Data Update. 
% '1' = Output registers updated on MSB LSB Read
% '0' = Continuous Mode
% DEFAULT = '0'
bit6 = '0';
%------------------------------
% Bit5 : H_LACTIVE. Interrupt Activation Level.
% '1' = Active High
% '0' = Active Low
% DEFAULT = '0'
bit5 = '0';
%------------------------------
% Bit4 : PP_OD. Push-pull/open-drain selection on INT1_A/G and INT2_A/G
% '1' = Push-Pull Mode
% '0' = Open-Drain Mode
% DEFAULT = '0'
bit4 = '0';
%------------------------------
% Bit3 : SIM. SPI Serial Interface Mode Selection
% '1' = 3-wire interface
% '0' = 4-wire interface
% DEFAULT = '0'
bit3 = '0';
%------------------------------
% Bit2 : IF_ADD_INC. Register address automatically incremented during a multiple
%                     byte access with a serial interface. (I2C or SPI)
% DEFAULT = '1' % (0: disable, 1: enable)
bit2 = '1';
%------------------------------
% Bit1 : BLE. Big/Little Endian Data Selection
% '1' = Big Endian
% '0' = Little Endian
% DEFAULT = '0'
bit1 = '0';
%------------------------------
% Bit0 : SW_RESET. Software Reset.
% '1' = Reset Device.
% '0' = Normal Mode
% DEFAULT = '0'
bit0 = '0';
%------------------------------
% Construct Register 19
%------------------------------
register{19}.name        = name;
register{19}.description = description;
register{19}.address     = address;
register{19}.data        = [bit7 bit6 bit5 bit4 bit3 bit2 bit1 bit0];



%----------------------------------------------------------------------
%       CTRL_REG9 -  Gyroscope Sleep Mode Enable, Temp data storage in FIFO,
%       data available bit, I2C disable, FIFO Memory Enable, Enable FIFO Threshold. (page 54)
%----------------------------------------------------------------------
name = 'CTRL_REG9';
description = 'Gyroscope Sleep Mode EN, Temp FIFO, data available bit, I2C disable, FIFO Memory Enable, Enable FIFO Threshold.';
% Register Address (in Hex)
address = '23';  
%------------------------------
% Bit7 : Must be set to zero for proper operation
% DEFAULT = '0'
bit7 = '0'; 
%------------------------------
% Bit6 : SLEEP_G. Gyroscope Sleep Mode Enable.
% DEFAULT = '0'
bit6 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit5 : Must be set to zero for proper operation
% DEFAULT = '0'
bit5 = '0';
%------------------------------
% Bit4 : FIFO_TEMP_EN. Temperature data storage in FIFO.
% '1' = Temperature data stored in FIFO.
% '0' = Temperature data not stored in FIFO.
% DEFAULT = '0'
bit4 = '0';
%------------------------------
% Bit3 : DRDY_mask_bit. Data available enable bit. 
% '1' = DA timer enabled.
% '0' = DA timer disabled.
% DEFAULT = '0'
bit3 = '0';
%------------------------------
% Bit2 : I2C_DISABLE
% '1' = I2C disabled. SPI only.
% '0' = Both I2C and SPI enabled.
% DEFAULT = '0'
bit2 = '0';
%------------------------------
% Bit1 : FIFO_EN. FIFO Memory Enabled.
% DEFAULT = '0'
bit1 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit0 : STOP_ON_FTH. Enable FIFO threshold level use.
% '1' = FIFO Depth is limited to threshold level
% '0' = FIFO Depth is not limited.
% DEFAULT = '0'
bit0 = '0';

%------------------------------
% Construct Register 20
%------------------------------
register{20}.name        = name;
register{20}.description = description;
register{20}.address     = address;
register{20}.data        = [bit7to0];



%----------------------------------------------------------------------
%       CTRL_REG10 -  Gyroscope/Accelerometer Self Test Enable Bits (page 54)
%----------------------------------------------------------------------
name = 'CTRL_REG10';
description = 'Gyroscope/Accelerometer Self Test';
% Register Address (in Hex)
address = '24';  
%------------------------------
% Bit7to3 : Must be set to zero for proper operation
% DEFAULT = '00000'
bit7to3 = '00000';
%------------------------------
% Bit2 : ST_G. Angular rate sensor self-test enable.
% '1' = Self Test Enabled.
% '0' = Self Test Disabled.
% DEFAULT = '0'
bit2 = '0';
%------------------------------
% Bit1 : Must be set to zero for proper operation
% DEFAULT = '0'
bit1 = '0';
%------------------------------
% Bit0 : ST_XL. Linear acceleration sensor self-test enable.
% '1' = Self Test Enabled.
% '0' = Self Test Disabled.
% DEFAULT = '0'
bit0 = '0';
%------------------------------
% Construct Register 21
%------------------------------
register{21}.name        = name;
register{21}.description = description;
register{21}.address     = address;
register{21}.data        = [bit7to3 bit2 bit1 bit0];


%----------------------------------------------------------------------
%       FIFO_CTRL -  FIFO Mode selection bits and threshold level (page 56)
%----------------------------------------------------------------------
name = 'FIFO_CTRL';
description = 'FIFO Mode selection bits and threshold level';
% Register Address (in Hex)
address = '2E';  
%------------------------------
% Bit7to5 : FMODE. Fifo mode selection.
% '000' = Bypass Mode. FIFO turned off.
% '001' = FIFO Mode. Stops Collecting data when FIFO is full.
% '010' = Reserved
% '011' = Continuous Mode until trigger is deasserted, then FIFO mode.
% '100' = Bypass mode until trigger is deasserted, then continuous mode. 
% '110' = Continuous mode. If the FIFO is full, the new sample overwrites the older sample.
% DEFAULT = '000'
bit7to5 = '000'; 
%------------------------------
% Bit4to0 : FTH. Fifo threshold level setting. 
% DEFAULT = '00000'
bit4to0 = '00000'; % (0: disable, 1: enable)
%------------------------------
% Construct Register 22
%------------------------------
register{22}.name        = name;
register{22}.description = description;
register{22}.address     = address;
register{22}.data        = [bit7to5 bit4to0];



%----------------------------------------------------------------------
%       INT_GEN_CFG_G -  Gyroscope interrupt generator config register (page 57-58)
%----------------------------------------------------------------------
name = 'INT_GEN_CFG_G';
description = 'Gyroscope interrupt generator config register';
% Register Address (in Hex)
address = '30';  
%------------------------------
% Bit7 : AOI_G. AND/OR combination of the following interrupt events. 
% '1' = AND combination.
% '0' = OR combination.
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6 : LIR_G. Latch gyroscope interrupt request.  
% '1' = Interrupt request latched.
% '0' = Interrupt request not latched.
% DEFAULT = '0' 
bit6 = '0'; 
%------------------------------
% Bit5 : ZHIE_G. Enable interrupt generation on gyroscope yaw Z axis high event. 
% '1' = Interrupt request on G value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit5 = '0';
%------------------------------
% Bit4 : ZLIE_G. Enable interrupt generation on gyroscope yaw Z axis low event. 
% '1' = Interrupt request on G value lower than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit4 = '0';
%------------------------------
% Bit3 : YHIE_G. Enable interrupt generation on gyroscope roll Y axis high event. 
% '1' = Interrupt request on G value lower than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit3 = '0';
%------------------------------
% Bit2 : YLIE_G. Enable interrupt generation on gyroscope roll Y axis low event. 
% '1' = Interrupt request on G value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit2 = '0';
%------------------------------
% Bit1 : XHIE_G. Enable interrupt generation on gyroscope pitch X axis high event. 
% '1' = Interrupt request on G value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit1 = '0';
%------------------------------
% Bit0 : XLIE_G. Enable interrupt generation on gyroscope pitch X axis low event. 
% '1' = Interrupt request on G value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit0 = '0';
%------------------------------
% Construct Register 23
%------------------------------
register{23}.name        = name;
register{23}.description = description;
register{23}.address     = address;
register{23}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_XH_G -  Gyroscope X Axis Interrupt Threshold High 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_XH_G';
description = 'Gyroscope X Axis Interrupt Threshold';
% Register Address (in Hex)
address = '31';  
%------------------------------
% Bit7 : DCRM_G. Decrement or reset counter mode selection.
% '1' = Interrupt request on G value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6to0 : THS_G_. bits 14 to 8 of the threshold value. 
% '1' = Interrupt request on G value higher than preset threshold. 
% '0' = Disable interrupt request.
% DEFAULT = '0000000'
bit0 = '0000000';
%------------------------------
% Construct Register 24
%------------------------------
register{24}.name        = name;
register{24}.description = description;
register{24}.address     = address;
register{24}.data        = [bit7 bit6to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_XL_G -  Gyroscope X Axis Interrupt Threshold Low 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_XL_G';
description = 'Gyroscope X Axis Interrupt Threshold';
% Register Address (in Hex)
address = '32';  
%------------------------------
% Bit7to0 : Bits 7 to 0 of the X axis threshold value. 
% DEFAULT = '00000000'
bit7 = '00000000';
%------------------------------
% Construct Register 25
%------------------------------
register{25}.name        = name;
register{25}.description = description;
register{25}.address     = address;
register{25}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_YH_G -  Gyroscope Y Axis Interrupt Threshold High 8 Bits 
%       Two's Complement 15 bit word.  (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_YH_G';
description = 'Gyroscope Y Axis Interrupt Threshold';
% Register Address (in Hex)
address = '33';  
%------------------------------
% Bit7 : Must be set to zero for proper operation
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6to0 : THS_G_. Bits 14 to 8 of the threshold value. 
% DEFAULT = '0000000'
bit0 = '0000000';
%------------------------------
% Construct Register 26
%------------------------------
register{26}.name        = name;
register{26}.description = description;
register{26}.address     = address;
register{26}.data        = [bit7 bit6to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_YL_G -  Gyroscope Y Axis Interrupt Threshold Low 8 Bits 
%       Two's Complement 15 bit word.  (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_XL_G';
description = 'Gyroscope Y Axis Interrupt Threshold';
% Register Address (in Hex)
address = '34';  
%------------------------------
% Bit7to0 : Bits 7 to 0 of the Y axis threshold value. 
% DEFAULT = '00000000'
bit7 = '00000000';
%------------------------------
% Construct Register 27
%------------------------------
register{27}.name        = name;
register{27}.description = description;
register{27}.address     = address;
register{27}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_ZH_G -  Gyroscope Z Axis Interrupt Threshold High 8 Bits 
%       Two's Complement 15 bit word.  (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_ZH_G';
description = 'Gyroscope Z Axis Interrupt Threshold';
% Register Address (in Hex)
address = '33';  
%------------------------------
% Bit7 : Must be set to zero for proper operation
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6to0 : THS_G_. Bits 14 to 8 of the threshold value. 
% DEFAULT = '0000000'
bit0 = '0000000';
%------------------------------
% Construct Register 28
%------------------------------
register{28}.name        = name;
register{28}.description = description;
register{28}.address     = address;
register{28}.data        = [bit7 bit6to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_ZL_G -  Gyroscope Z Axis Interrupt Threshold Low 8 Bits 
%       Two's Complement 15 bit word.  (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_ZL_G';
description = 'Gyroscope Z Axis Interrupt Threshold';
% Register Address (in Hex)
address = '34';  
%------------------------------
% Bit7to0 : Bits 7 to 0 of the Z axis threshold value. 
% DEFAULT = '00000000'
bit7 = '00000000';
%------------------------------
% Construct Register 29
%------------------------------
register{29}.name        = name;
register{29}.description = description;
register{29}.address     = address;
register{29}.data        = [bit7to0];


%----------------------------------------------------------------------
%       INT_GEN_DUR_G  -  Gyroscope Interrupt Fall Time (page 59)
%----------------------------------------------------------------------
name = 'INT_GEN_DUR_G';
description = 'Gyroscope Interrupt Fall Time';
% Register Address (in Hex)
address = '37';  
%------------------------------
% Bit7 : WAIT : WAIT enable
% DEFAULT = '0' 
bit7 = '0'; % (0: disable, 1: enable)
%------------------------------
% bit6to0 : D6-D0 : Duration value (number of samples)
% DEFAULT = '0000000' 
bit6to0 = '0000000'; 
%------------------------------
% Construct Register 30
%------------------------------
register{30}.name        = name;
register{30}.description = description;
register{30}.address     = address;
register{30}.data        = [bit7 bit6to0];









%---------------------------------------------------------------
% Check if the fields have the correct number of bits....
%---------------------------------------------------------------
for reg_index = 1:length(register)
    if length(register{reg_index}.data) ~= 8
        reg_index  % we have a problem.....
        pause
    end
end


%---------------------------------------------------------------
% Get the Default Register values since we are only interested 
% in non-default values
%---------------------------------------------------------------
default_register = LSM9DS1_XL_G_Register_Default_Settings();


a = fi(0,0,7,0); % value=0, unsigned=0, word_length=7 bits, fraction_length=0 bits


%MIF Head and File Pointer

b = fi(0,0,8,0);
mif_index = 3;


%---------------------------------------------------------------
% Print out VHDL code that can be used for signal constants
% that can be cut & pasted into xyz.vhd
%---------------------------------------------------------------
fid = fopen('LSM9DS1_XL_G_Register_Settings_VHDL_code.txt','w');
fprintf(fid,'------------------------------------------------------------------------\n');
fprintf(fid,'-- Power Up Register Settings to be pasted into LSM9DS1_top.vhd\n');
fprintf(fid,'-- Date generated: %s\n', date);

gen_index = 1;
indentical_count = 0;
for reg_index = 1:length(register)
    if strcmp(register{reg_index}.data, default_register{reg_index}.data) == 0  % generate code if false
        if gen_index < 11
            regstr = ['Reg0'  num2str(gen_index-1)];
        else
            regstr = ['Reg'  num2str(gen_index-1)];
        end
        gen_index = gen_index + 1;
        string = ['---------------------------------------------------------'];
        fprintf(fid,'%s\n',string);
        % Register Description
        string = ['-- ' regstr ' Name: ' register{reg_index}.name];
        fprintf(fid,'%s\n',string);
        string = ['-- ' regstr ' Description: ' register{reg_index}.description];
        fprintf(fid,'%s\n',string);
        if isfield(register{reg_index},'setting_description') 
            string = ['-- Setting Description: ' register{reg_index}.setting_description];
            fprintf(fid,'%s\n',string);      
        end
        % Register Address
        a.hex = register{reg_index}.address;
        binstr = a.bin;
        string = ['constant ' regstr '_Addr : std_logic_vector (6 downto 0) := "' binstr '";  -- Hex Address = ' a.hex];
        fprintf(fid,'%s\n',string);
        % Register Data
        string = ['constant ' regstr '_Data : std_logic_vector (7 downto 0) := "' register{reg_index}.data '";  -- Default = '  default_register{reg_index}.data];
        fprintf(fid,'%s\n',string);
        
        %MIF Generations Addon.
        b.bin = register{reg_index}.data;
        mif_file{mif_index}.data = [a.hex b.hex];
        mif_index = mif_index + 1;

        
        
        
    else
        indentical_count = indentical_count + 1;
    end
end

%Maintenance of the mif_index structure;
%A .mat file variable is saved here that is then used to generate the final mif file
%in LSM9DS1_M_Register_Settings. This is done so as to not have to reparse the mif file. 
%At location 1 in memory is where number of accel/gyro registers changed
%is stored.
mif_file{1}.data = num2str(mif_index - 3,'%x');
save('mif_file_xl_g.mat','mif_file');


fclose(fid);

indentical_count











