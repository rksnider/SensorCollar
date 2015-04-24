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
%%DATA REGISTERS OF INTEREST.
%These could be 
%
%One can read all 6 registers with auto increment on. 
%
%OUT_X_L_M % Address 05
%OUT_X_H_M
%OUT_Y_L_M
%OUT_Y_H_M
%OUT_Z_L_M
%OUT_Z_H_M % Address 09
%
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
%       OFFSET_X_REG_L_M  - 16 bit word two's Complement Magnetometer X Environmental Offset
%       Low 8 Bits(page 62)
%--------------------------------------------------------------------------
name = 'OFFSET_X_REG_L_M';
description = 'X-Axis Magnetometer Environmental Correction Offset Low 8 Bits';
% Register Address (in Hex)
address = '05';  
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
%       OFFSET_X_REG_H_M  -  16 bit word two's Complement Magnetometer X Environmental Offset
%       High 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_X_REG_H_M';
description = 'X-Axis Magnetometer Environmental Correction Offset High 8 Bits';
% Register Address (in Hex)
address = '06';  
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
%       OFFSET_Y_REG_L_M  - 16 bit word two's Complement Magnetometer Y Environmental Offset
%       Low 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Y_REG_L_M';
description = 'Y-Axis Magnetometer Environmental Correction Offset Low 8 Bits';
% Register Address (in Hex)
address = '07';  
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
%       OFFSET_Y_REG_H_M  - 16 bit word two's Complement Magnetometer Y Environmental Offset
%       High 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Y_REG_H_M';
description = 'Y-Axis Magnetometer Environmental Correction Offset High 8 Bits';
% Register Address (in Hex)
address = '08';  
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
%       OFFSET_Z_REG_L_M  - 16 bit word two's Complement Magnetometer Y Environmental Offset
%       Low 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Z_REG_L_M';
description = 'Z-Axis Magnetometer Environmental Correction Offset Low 8 Bits';
% Register Address (in Hex)
address = '09';  
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
%       OFFSET_Z_REG_H_M  - 16 bit word two's Complement Magnetometer Z Environmental Offset
%       High 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Z_REG_H_M';
description = 'Z-Axis Magnetometer Environmental Correction Offset High 8 Bits';
% Register Address (in Hex)
address = '0A';  
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
%       CTRL_REG1_M  - Magnetometer Temperature Compensation Mode, X/Y Axis Mode
%                      selection, Data Rate, and Self Test Enable (page 63)
%----------------------------------------------------------------------
name = 'CTRL_REG1_M';
description = 'Magnetometer Temp Comp, XY Axis Mode, DataRate, and Self Test EN';
% Register Address (in Hex)
address = '20';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00010000'; 
%------------------------------
% Construct Register 7
%------------------------------
default_register{7}.name        = name;
default_register{7}.description = description;
default_register{7}.address     = address;
default_register{7}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG2_M  -  Scale selection, Reboot Memory Content, Soft Reset
%                       (page 64)
%----------------------------------------------------------------------
name = 'CTRL_REG2_M';
description = 'Full scale config, Reboot, and Soft Reset';
% Register Address (in Hex)
address = '21';  
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
%       CTRL_REG3_M   -  I2C Disable, LowPowerMode, SPI Mode, Operating Mode (page 64)
%----------------------------------------------------------------------
name = 'CTRL_REG3_M';
description = 'I2C Disable, LowPowerMode, SPI Mode, Operating Mode';
% Register Address (in Hex)
address = '22';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
bit7to0 = '00000011'; 
%------------------------------
% Construct Register 9
%------------------------------
default_register{9}.name        = name;
default_register{9}.description = description;
default_register{9}.address     = address;
default_register{9}.data        = [bit7to0];

%----------------------------------------------------------------------
%       CTRL_REG4_M  -  Z Axis Mode Selection, Endianess (page 65)
%----------------------------------------------------------------------
name = 'CTRL_REG4_M';
description = 'Z Axis Mode Selection, Endianess';
% Register Address (in Hex)
address = '23';  
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
%       CTRL_REG5_M  -  Block Data Update. Continuous or MSB/LSB Read Update (page 65)
%----------------------------------------------------------------------
name = 'CTRL_REG5_M';
description = 'Block Data Update. Continuous or MSB/LSB Read Update';
% Register Address (in Hex)
address = '24';  
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
%       INT_CFG_M  -  Enable/Disable Interrupt on X/Y/Z, Interrupt High Low, Latch Interrupt
%                     and Interrupt Enable on INT_M pin (page 67)
%----------------------------------------------------------------------
name = 'INT_CFG_M';
description = 'ODR, Full Scale Detection, and Bandwidth Selection for both Gyro/Accel';
% Register Address (in Hex)
address = '30';  
%------------------------------
% DEFAULT value (See Register map table 21 on page 38)
% Discrepancy in the default value listed in the table. Should probably be 0.
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 12
%------------------------------
default_register{12}.name        = name;
default_register{12}.description = description;
default_register{12}.address     = address;
default_register{12}.data        = [bit7to0];



%---------------------------------------------------------------
% Check if the fields have the correct number of bits....
%---------------------------------------------------------------
for reg_index = 1:length(default_register)
    if length(default_register{reg_index}.data) ~= 8
        reg_index  % we have a problem.....
        pause
    end
end






