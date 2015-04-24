function default_register = LSM9DS1_Register_Default_Settings()
%--------------------------------------------------------------------------
% Default Register Settings for the ST Microelectronics LSM9DS1 9-axis Motion Sensor 
%
% To be used in in determining which user settings should be written at
% power up since there is no need to write default register values.
% 
% To change the default settings, go the particular register below
% and change the bit settings. Then run the script to generate VHDL code
% that can be cut and pasted into the init/powerup section. 
% There are xx registers, yy which are writable (See Register Map, 
% Table 17, page 38 of data sheet):
%
% Writable Registers:
%
%       ------------------------------------------------
%       Accelerometer/Gyroscope Writable Registers
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
%       Note: The registers are 16 bits where the first 7 bits 
%             contain the address and the following 9 bits contain
%             the data.
%
% Script:   LSM9DS1_Register_Settings.m 
% Author:   Ross K. Snider
% Date:     
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
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 1
%------------------------------
default_register{1}.name        = name;
default_register{1}.description = description;
default_register{1}.address     = address;  % (in Hex)
default_register{1}.data        = [bit7to0];

%----------------------------------------------------------------------
%       ACT_DUR  -  Inactivity duration register
%      (page 41)
%----------------------------------------------------------------------
name = 'ACT_DUR';
description = 'Inactivity Register';
% Register Address (in Hex)
address = '05';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 2
%------------------------------
default_register{2}.name        = name;
default_register{2}.description = description;
default_register{2}.address     = address;
default_register{2}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_CFG_XL  -  Linear acceleration threshold interrupt generator
%       configuration register (page 41)
%----------------------------------------------------------------------
name = 'INT_GEN_CFG_XL';
description = 'Accelerometer : Threshold Interrupt Generator Setup Register';
% Register Address (in Hex)
address = '06';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 3
%------------------------------
default_register{3}.name        = name;
default_register{3}.description = description;
default_register{3}.address     = address;
default_register{3}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_X_XL  - X-axis acceleration threshold register
%       (page 42)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_X_XL';
description = 'X-axis acceleration threshold register';
% Register Address (in Hex)
address = '07';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 4
%------------------------------
default_register{4}.name        = name;
default_register{4}.description = description;
default_register{4}.address     = address;
default_register{4}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_Y_XL  - Y-axis acceleration threshold register
%       (page 42)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_Y_XL';
description = 'Y-axis acceleration threshold register';
% Register Address (in Hex)
address = '08';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 5
%------------------------------
default_register{5}.name        = name;
default_register{5}.description = description;
default_register{5}.address     = address;
default_register{5}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_Z_XL  - Z-axis acceleration threshold register
%       (page 43)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_Z_XL';
description = 'Z-axis acceleration threshold register';
% Register Address (in Hex)
address = '09';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 6
%------------------------------
default_register{6}.name        = name;
default_register{6}.description = description;
default_register{6}.address     = address;
default_register{6}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_DUR_XL  - Duration of the Linear Acceleration Interrupt Pulse
%       (page 43)
%----------------------------------------------------------------------
name = 'INT_GEN_DUR_XL';
description = 'Duration of the Linear Acceleration Interrupt Pulse';
% Register Address (in Hex)
address = '0A';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 7
%------------------------------
default_register{7}.name        = name;
default_register{7}.description = description;
default_register{7}.address     = address;
default_register{7}.data        = [bit7to0];

%----------------------------------------------------------------------
%       REFERENCE_G  -  Reference Value for gyroscopes digital high-pass
%       filter. (page 43)
%----------------------------------------------------------------------
name = 'REFERENCE_G';
description = 'Reference Value for gyroscopes digital high-pass filter';
% Register Address (in Hex)
address = '0B';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 8
%------------------------------
default_register{8}.name        = name;
default_register{8}.description = description;
default_register{8}.address     = address;
default_register{8}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT1_CTRL   -  INT1 pin interrupt configuration (page 43)
%----------------------------------------------------------------------
name = 'INT1_CTRL';
description = 'Set the interrupt type associated with this pin';
% Register Address (in Hex)
address = '0C';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 9
%------------------------------
default_register{9}.name        = name;
default_register{9}.description = description;
default_register{9}.address     = address;
default_register{9}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT2_CTRL  -  INT2 pin interrupt configuration (page 43)
%----------------------------------------------------------------------
name = 'INT2_CTRL';
description = 'Set the interrupt type associated with this pin';
% Register Address (in Hex)
address = '33';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 10
%------------------------------
default_register{10}.name        = name;
default_register{10}.description = description;
default_register{10}.address     = address;
default_register{10}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG1_G  -  ODR Selection and Bandwidth Selection
%       for accelerometer and gyroscope activated (page 45)
%----------------------------------------------------------------------
name = 'CTRL_REG1_G';
description = 'ODR, Full Scale Detection, and Bandwidth Selection for both Gyro/Accel';
% Register Address (in Hex)
address = '10';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 11
%------------------------------
default_register{11}.name        = name;
default_register{11}.description = description;
default_register{11}.address     = address;
default_register{11}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG2_G  -  Interrupt and Data Path Muxing for the Gyroscope 
%       Position of HPF and LPF before FIFO as well as interrupt position(page 48)
%----------------------------------------------------------------------
name = 'CTRL_REG2_G';
description = 'Interrupt and Data Path Muxing for the Gyroscope';
% Register Address (in Hex)
address = '11';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 12
%------------------------------
default_register{12}.name        = name;
default_register{12}.description = description;
default_register{12}.address     = address;
default_register{12}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG3_G  -  Gyroscope Low Power,HP Filter Enable and Cutoff (page 47)
%----------------------------------------------------------------------
name = 'CTRL_REG3_G';
description = 'Gyroscope Low Power,HP Filter Enable and Cutoff';
% Register Address (in Hex)
address = '12';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 13
%------------------------------
default_register{13}.name        = name;
default_register{13}.description = description;
default_register{13}.address     = address;
default_register{13}.data        = [bit7to0];

%----------------------------------------------------------------------
%       ORIENT_CFG_G  -  Gyroscope axis signs and user orientation selection (page 48)
%----------------------------------------------------------------------
name = 'ORIENT_CFG_G';
description = 'Gyroscope axis signs and user orientation selection';
% Register Address (in Hex)
address = '13';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 14
%------------------------------
default_register{14}.name        = name;
default_register{14}.description = description;
default_register{14}.address     = address;
default_register{14}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG4  -  On/Off for Gyroscope Axis, Latched Interrupt, 4D/6D
%       position recognition (page 50-51)
%----------------------------------------------------------------------
name = 'CTRL_REG4';
description = 'On/Off for Gyroscope Axis, Latched Interrupt, 4D/6D position recognition';
% Register Address (in Hex)
address = '1E';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00111000'; 
%------------------------------
% Construct Register 15
%------------------------------
default_register{15}.name        = name;
default_register{15}.description = description;
default_register{15}.address     = address;
default_register{15}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG5_XL -  Decimation of Accelerometer Data and Axis On_Off (page 51)
%----------------------------------------------------------------------
name = 'CTRL_REG5_XL';
description = 'Decimation of Accelerometer Data and Axis On_Off';
% Register Address (in Hex)
address = '1F';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00111000'; 
%------------------------------
% Construct Register 16
%------------------------------
default_register{16}.name        = name;
default_register{16}.description = description;
default_register{16}.address     = address;
default_register{16}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG6_XL -  Accelerometer Only ODR, Full Scale, Bandwidth,
%       Anti Aliasing Filter Bandwidth (page 52)
%----------------------------------------------------------------------
name = 'CTRL_REG6_XL';
description = 'Accelerometer ODR, BW, AntiAliasing BW and Full-Scale Select';
% Register Address (in Hex)
address = '20';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 17
%------------------------------
default_register{17}.name        = name;
default_register{17}.description = description;
default_register{17}.address     = address;
default_register{17}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG7_XL -  High Res Mode Accelerometer, HP/LP Filter Cutoff Select
%       Filtered Data Selection, and HPF enable on interrupt (page 53)
%----------------------------------------------------------------------
name = 'CTRL_REG7_XL';
description = 'Accelerometer High Res mode,Digital Filter and Select';
% Register Address (in Hex)
address = '21';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 18
%------------------------------
default_register{18}.name        = name;
default_register{18}.description = description;
default_register{18}.address     = address;
default_register{18}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG8 -  General Device Function Register. Reboot Memory Content,
%       block data update, interrupt active level, push_pull/open-drain interrupt pin
%       selection, SPI wire mode, address auto increment, big endian little endian selection
%       software reset   (page 53)
%----------------------------------------------------------------------
name = 'CTRL_REG8';
description = 'Device Function Register: Interrupt Levels, SPI Wire Number, Endianess';
% Register Address (in Hex)
address = '22';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000100'; 
%------------------------------
% Construct Register 19
%------------------------------
default_register{19}.name        = name;
default_register{19}.description = description;
default_register{19}.address     = address;
default_register{19}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG9 -  Gyroscope Sleep Mode Enable, Temp data storage in FIFO,
%       data available bit, I2C disable, FIFO Memory Enable, Enable FIFO Threshold. (page 54)
%----------------------------------------------------------------------
name = 'CTRL_REG9';
description = 'Gyroscope Sleep Mode EN, Temp FIFO, data available bit, I2C disable, FIFO Memory Enable, Enable FIFO Threshold.';
% Register Address (in Hex)
address = '23';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 20
%------------------------------
default_register{20}.name        = name;
default_register{20}.description = description;
default_register{20}.address     = address;
default_register{20}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG10 -  Gyroscope/Accelerometer Self Test Enable Bits (page 54)
%----------------------------------------------------------------------
name = 'CTRL_REG10';
description = 'Gyroscope/Accelerometer Self Test';
% Register Address (in Hex)
address = '24';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 21
%------------------------------
default_register{21}.name        = name;
default_register{21}.description = description;
default_register{21}.address     = address;
default_register{21}.data        = [bit7to0];

%----------------------------------------------------------------------
%       FIFO_CTRL -  FIFO Mode selection bits and threshold level (page 56)
%----------------------------------------------------------------------
name = 'FIFO_CTRL';
description = 'FIFO Mode selection bits and threshold level';
% Register Address (in Hex)
address = '2E';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 22
%------------------------------
default_register{22}.name        = name;
default_register{22}.description = description;
default_register{22}.address     = address;
default_register{22}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_CFG_G -  Gyroscope interrupt generator config register (page 57-58)
%----------------------------------------------------------------------
name = 'INT_GEN_CFG_G';
description = 'Gyroscope interrupt generator config register';
% Register Address (in Hex)
address = '30';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 23
%------------------------------
default_register{23}.name        = name;
default_register{23}.description = description;
default_register{23}.address     = address;
default_register{23}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_XH_G -  Gyroscope X Axis Interrupt Threshold High 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_XH_G';
description = 'Gyroscope X Axis Interrupt Threshold';
% Register Address (in Hex)
address = '31';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 24
%------------------------------
default_register{24}.name        = name;
default_register{24}.description = description;
default_register{24}.address     = address;
default_register{24}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_XL_G -  Gyroscope X Axis Interrupt Threshold Low 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_XL_G';
description = 'Gyroscope X Axis Interrupt Threshold';
% Register Address (in Hex)
address = '32';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 25
%------------------------------
default_register{25}.name        = name;
default_register{25}.description = description;
default_register{25}.address     = address;
default_register{25}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_YH_G -  Gyroscope Y Axis Interrupt Threshold High 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_YH_G';
description = 'Gyroscope Y Axis Interrupt Threshold';
% Register Address (in Hex)
address = '33';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 26
%------------------------------
default_register{26}.name        = name;
default_register{26}.description = description;
default_register{26}.address     = address;
default_register{26}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_YL_G -  Gyroscope Y Axis Interrupt Threshold Low 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 58)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_YL_G';
description = 'Gyroscope Y Axis Interrupt Threshold';
% Register Address (in Hex)
address = '34';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 27
%------------------------------
default_register{27}.name        = name;
default_register{27}.description = description;
default_register{27}.address     = address;
default_register{27}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_ZH_G - Gyroscope Z Axis Interrupt Threshold High 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 59)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_ZH_G';
description = 'Gyroscope Z Axis Interrupt Threshold';
% Register Address (in Hex)
address = '35';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 28
%------------------------------
default_register{28}.name        = name;
default_register{28}.description = description;
default_register{28}.address     = address;
default_register{28}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_THS_ZL_G - Gyroscope Z Axis Interrupt Threshold Low 8 Bits 
%       Two's Complement 15 bit word. Decrement or Reset Counter Select (page 59)
%----------------------------------------------------------------------
name = 'INT_GEN_THS_ZL_G';
description = 'Gyroscope Z Axis Interrupt Threshold';
% Register Address (in Hex)
address = '36';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 29
%------------------------------
default_register{29}.name        = name;
default_register{29}.description = description;
default_register{29}.address     = address;
default_register{29}.data        = [bit7to0];

%----------------------------------------------------------------------
%       INT_GEN_DUR_G  -  Gyroscope Interrupt Fall Time (page 59)
%----------------------------------------------------------------------
name = 'INT_GEN_DUR_G';
description = 'Gyroscope Interrupt Fall Time';
% Register Address (in Hex)
address = '37';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 30
%------------------------------
default_register{30}.name        = name;
default_register{30}.description = description;
default_register{30}.address     = address;
default_register{30}.data        = [bit7to0];


%---------------------------------------------------------------
% Check if the fields have the correct number of bits....
%---------------------------------------------------------------
for reg_index = 1:length(default_register)
    if length(default_register{reg_index}.data) ~= 8
        reg_index  % we have a problem.....
        pause
    end
end











