
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
%       Note: The registers are 16 bits where the first 7 bits 
%             contain the address and the following 9 bits contain
%             the data.
%
% Script:   LSM9DS1_Register_Settings.m 
% Author:   Ross K. Snider
% Date:     November 7, 2013
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
% Bit7to0 : OFXM7to0. X offset bits(7to0) used to compensate environmental effects. 
% DEFAULT = '00000000' 
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 1
%------------------------------
register{1}.name        = name;
register{1}.description = description;
register{1}.address     = address;  % (in Hex)
register{1}.data        = [bit7to0];


%----------------------------------------------------------------------
%       OFFSET_X_REG_H_M  -  16 bit word two's Complement Magnetometer X Environmental Offset
%       High 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_X_REG_H_M';
description = 'X-Axis Magnetometer Environmental Correction Offset High 8 Bits';
% Register Address (in Hex)
address = '06';  
%------------------------------
% Bit7to0 : OFXM15to8. X offset bits(15to8) used to compensate environmental effects. 
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
%       OFFSET_Y_REG_L_M  - 16 bit word two's Complement Magnetometer Y Environmental Offset
%       Low 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Y_REG_L_M';
description = 'Y-Axis Magnetometer Environmental Correction Offset Low 8 Bits';
% Register Address (in Hex)
address = '07';  
%------------------------------
% Bit7to0 : OFXM7to0. Y offset bits(7to0) used to compensate environmental effects. 
% DEFAULT = '00000000' 
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 3
%------------------------------
register{3}.name        = name;
register{3}.description = description;
register{3}.address     = address;
register{3}.data        = [bit7to0];

%----------------------------------------------------------------------
%       OFFSET_Y_REG_H_M  - 16 bit word two's Complement Magnetometer Y Environmental Offset
%       High 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Y_REG_H_M';
description = 'Y-Axis Magnetometer Environmental Correction Offset High 8 Bits';
% Register Address (in Hex)
address = '08';  
%------------------------------
% Bit7to0 : OFXM15to8. Y offset bits(15to8) used to compensate environmental effects. 
% DEFAULT = '00000000' 
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 4
%------------------------------
register{4}.name        = name;
register{4}.description = description;
register{4}.address     = address;
register{4}.data        = [bit7to0];



%----------------------------------------------------------------------
%       OFFSET_Z_REG_L_M  - 16 bit word two's Complement Magnetometer Y Environmental Offset
%       Low 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Z_REG_L_M';
description = 'Z-Axis Magnetometer Environmental Correction Offset Low 8 Bits';
% Register Address (in Hex)
address = '09';  
%------------------------------
% Bit7to0 : OFXM7to0. Z offset bits(7to0) used to compensate environmental effects. 
% DEFAULT = '00000000' 
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 5
%------------------------------
register{5}.name        = name;
register{5}.description = description;
register{5}.address     = address;
register{5}.data        = [bit7to0];

%----------------------------------------------------------------------
%       OFFSET_Z_REG_H_M  - 16 bit word two's Complement Magnetometer Z Environmental Offset
%       High 8 Bits(page 62)
%----------------------------------------------------------------------
name = 'OFFSET_Z_REG_H_M';
description = 'Z-Axis Magnetometer Environmental Correction Offset High 8 Bits';
% Register Address (in Hex)
address = '0A';  
%------------------------------
% Bit7to0 : OFXM15to8. Z offset bits(15to8) used to compensate environmental effects. 
% DEFAULT = '00000000' 
bit7to0 = '00000000'; 
%------------------------------
% Construct Register 6
%------------------------------
register{6}.name        = name;
register{6}.description = description;
register{6}.address     = address;
register{6}.data        = [bit7to0];




%----------------------------------------------------------------------
%       CTRL_REG1_M  - Magnetometer Temperature Compensation Mode, X/Y Axis Mode
%                      selection, Data Rate, and Self Test Enable (page 63)
%----------------------------------------------------------------------
name = 'CTRL_REG1_M';
description = 'Magnetometer Temp Comp, XY Axis Mode, DataRate, and Self Test EN';
% Register Address (in Hex)
address = '20';  
%------------------------------
% Bit7 : TEMP_COMP. Temperature compensation enable. 
% DEFAULT = '0'
bit7 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit6to5 : OM. X and Y axes operative mode selection.  See table 110. Page 63.
% '00' = Low power mode. 
% '01' = Medium Performance mode.
% '10' = High Performance mode.
% '11' = Ultra-high performance mode. 
% DEFAULT = '00'
bit6to5 = '00';
%------------------------------
% Bit4to2 : DO. Output data rate selection.  See Table 111. Page 63 for options.
% '000' = .625 Hz.
% '001' = 1.25 Hz.
% '010' = 2.5 Hz.
% '011' = 5 Hz.
% '100' = 10 Hz.
% '101' = 20 Hz.
% '110' = 40 Hz.
% '111' = 80 Hz.
% DEFAULT = '100'
bit4to2 = '100';  
%------------------------------
% Bit1 : Must be set to zeros for proper operation
% DEFAULT = '0' 
bit1 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit0 : ST. Self Test Enable. 
% DEFAULT = '0' 
bit0 = '0'; % (0: disable, 1: enable)
%------------------------------
% Construct Register 7
%------------------------------
register{7}.name        = name;
register{7}.description = description;
register{7}.address     = address;
register{7}.data        = [bit7 bit6to5 bit4to2 bit1 bit0];


%----------------------------------------------------------------------
%       CTRL_REG2_M  -  Scale selection, Reboot Memory Content, Soft Reset
%                       (page 64)
%----------------------------------------------------------------------
name = 'CTRL_REG2_M';
description = 'Full scale config, Reboot, and Soft Reset';
% Register Address (in Hex)
address = '21';  
%------------------------------
% Bit7 : Must be set to zeros for proper operation
% DEFAULT = '0'
bit7 = '0'; 
%------------------------------
% Bit6to5 : FS. Full scale configuration.
% '00' =  +/- 4 gauss
% '01' =  +/- 8 gauss
% '10' =  +/- 12 gauss
% '11' =  +/- 16 gauss
% DEFAULT = '00'
bit6to5 = '00';
%------------------------------
% Bit4 :  Must be set to zeros for proper operation
% DEFAULT = '0'
bit4 = '0'; 
%------------------------------
% Bit3 : REBOOT. Reboot memory content.
% '0' = Normal Mode.
% '1' = Reboot Memory Content.
% DEFAULT = '0' 
bit3 = '0'; 
%------------------------------
% Bit2 : SOFT_RST. Configuration and user register reset function. 
% '0' = Default Value.
% '1' = Reset Operation.
% DEFAULT = '0' 
bit2 = '0';
%------------------------------
% Bit1 : Must be set to zeros for proper operation
% DEFAULT = '0' 
bit1 = '0'; 
%------------------------------
% Bit0 :  Must be set to zeros for proper operation
% DEFAULT = '0' 
bit0 = '0'; 
%------------------------------
% Construct Register 8
%------------------------------
register{8}.name        = name;
register{8}.description = description;
register{8}.address     = address;
register{8}.data        = [bit7 bit6to5 bit4 bit3 bit2 bit1 bit0];


%----------------------------------------------------------------------
%       CTRL_REG3_M   -  I2C Disable, LowPowerMode, SPI Mode, Operating Mode (page 64)
%----------------------------------------------------------------------
name = 'CTRL_REG3_M';
description = 'I2C Disable, LowPowerMode, SPI Mode, Operating Mode';
% Register Address (in Hex)
address = '22';  
%------------------------------
% Bit7 : I2C_DISABLE. Disable/Enable I2C interface.
% DEFAULT = '0'
bit7 = '0'; % (1: disable, 0: enable)
%------------------------------
% Bit6 : Must be set to zeros for proper operation
% DEFAULT = '0'
bit6 = '0';
%------------------------------
% Bit5 : LP. Low-power mode configuration. Default value: 0
%             If this bit is ‘1’, the DO[2:0] is set to 0.625 Hz and the system performs, for each
%             channel, the minimum number of averages. Once the bit is set to ‘0’, the magnetic
%             data rate is configured by the DO bits in the CTRL_REG1_M (20h) register.
% DEFAULT = '0'
bit5 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit4to3 :  Must be set to zeros for proper operation
% DEFAULT = '00'
bit4to3 = '00'; 
%------------------------------
% Bit2 : SIM. SPI Serial Interface mode selection. 
% '0' = SPI only write operations.
% '1' = SPI read and write operations.
% DEFAULT = '0' 
bit2 = '0'; 
%------------------------------
% Bit1to0 : MD. Operating mode selection.
% '00' = Continuous conversion mode.
% '01' = Single conversion mode. 
% '10' = Power-down mode. 
% '11' = Power-down mode. 
% DEFAULT = '11' 
bit1to0 = '00';
%------------------------------
% Construct Register 9
%------------------------------
register{9}.name        = name;
register{9}.description = description;
register{9}.address     = address;
register{9}.data        = [bit7 bit6 bit5 bit4to3 bit2 bit1to0];


%----------------------------------------------------------------------
%       CTRL_REG4_M  -  Z Axis Mode Selection, Endianess (page 65)
%----------------------------------------------------------------------
name = 'CTRL_REG4_M';
description = 'Z Axis Mode Selection, Endianess';
% Register Address (in Hex)
address = '23';  
%------------------------------
% Bit7to4 :  Must be set to zeros for proper operation
% DEFAULT = '0000'
bit7to4 = '0000';
%------------------------------
% Bit3to2 : OMZ. Z-axis operative mode selection. 
% '00' = Lower power mode. 
% '01' = Medium Performance Mode.
% '10' = High Performance Mode.
% '11' = Ultra-high performance mode. 
% DEFAULT = '00'
bit3to2 = '00';
%------------------------------
% Bit1 : BLE. Big Little Endian Data Selection
% '0' = Data LSb at lower address.
% '1' = Data MSb at lower address.
% DEFAULT = '0'
bit5 = '0'; 
%------------------------------
% Bit0 :  Must be set to zeros for proper operation
% DEFAULT = '0'
bit0 = '0'; 
%------------------------------
% Construct Register 10
%------------------------------
register{10}.name        = name;
register{10}.description = description;
register{10}.address     = address;
register{10}.data        = [bit7to4 bit3to2 bit1 bit0];

%----------------------------------------------------------------------
%       CTRL_REG5_M  -  Block Data Update. Continuous or MSB/LSB Read Update (page 65)
%----------------------------------------------------------------------
name = 'CTRL_REG5_M';
description = 'Block Data Update. Continuous or MSB/LSB Read Update';
% Register Address (in Hex)
address = '24';  
%------------------------------
% Bit7 :  Must be set to zeros for proper operation
% DEFAULT = '0'
bit7 = '0';
%------------------------------
% Bit6 : BDU. Block data update for magnetic data. 
% '0' = Continuous update. 
% '1' = Output registers not updated until MSB and LSB have been read.
% DEFAULT = '0'
bit6 = '0';
%------------------------------
% Bit5to0 :  Must be set to zeros for proper operation
% DEFAULT = '000000'
bit5to0 = '000000'; 
%------------------------------
% Construct Register 11
%------------------------------
register{11}.name        = name;
register{11}.description = description;
register{11}.address     = address;
register{11}.data        = [bit7 bit6 bit5to0];



%----------------------------------------------------------------------
%       INT_CFG_M  -  Enable/Disable Interrupt on X/Y/Z, Interrupt High Low, Latch Interrupt
%                     and Interrupt Enable on INT_M pin (page 67)
%----------------------------------------------------------------------
name = 'INT_CFG_M';
description = 'ODR, Full Scale Detection, and Bandwidth Selection for both Gyro/Accel';
% Register Address (in Hex)
address = '30';  
%------------------------------
% Bit7 : XIEN. Enable interrupt generation on X-Axis.
% DEFAULT = '0'
bit7 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit6 : YIEN. Enable interrupt generation on Y-axis. 
% DEFAULT = '0'
bit6 = '0';
%------------------------------
% Bit5 : ZIEN. Enable interrupt generation on Z-axis.
% DEFAULT = '0'
bit5 = '0'; % (0: disable, 1: enable)
%------------------------------
% Bit4to3 :  Must be set to zeros for proper operation
% DEFAULT = '0'
bit4to3 = '00'; 
%------------------------------
% Bit2 : IEA. Interrupt active configuration on INT_MAG.
% '0' = low.
% '1' = high.
% DEFAULT = '0' 
bit2 = '0'; 
%------------------------------
% Bit1 : IEL. Latch interrupt request. 
% '0' = Interrupt request latched. Once latched INT_M remains state until
%       INT_SRC_M is read.
% '1' = Interrupt request not latched.
% DEFAULT = '0' 
bit1 = '0';
%------------------------------
% Bit0 : Interrupt enable on INT_M pin. 
% DEFAULT = '0' 
bit0 = '0'; % (0: disable, 1: enable)
%------------------------------
% Construct Register 12
%------------------------------
register{12}.name        = name;
register{12}.description = description;
register{12}.address     = address;
register{12}.data        = [bit7 bit6 bit5 bit4to3 bit2 bit1 bit0];

%%%%%%%%%%%%%%%%%%%Work complete line. 

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
default_register = LSM9DS1_M_Register_Default_Settings();


a = fi(0,0,7,0); % value=0, unsigned=0, word_length=7 bits, fraction_length=0 bits
%---------------------------------------------------------------
% Print out VHDL code that can be used for signal constants
% that can be cut & pasted into xyz.vhd
%---------------------------------------------------------------

%Maintenance of the mif_index structure;
load('mif_file_xl_g.mat');
mag_mif_start = length(mif_file);
mif_index = length(mif_file);
b = fi(0,0,8,0);


fid = fopen('LSM9DS1_M_Register_Settings_VHDL_code.txt','w');
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
        mif_index = mif_index + 1;
        b.bin = register{reg_index}.data;
        mif_file{mif_index}.data = [a.hex b.hex]

        
        
    else
        indentical_count = indentical_count + 1;

    end
end
fclose(fid);

indentical_count

%At location 2 in memory is where number of mag registers changed
%is stored.
mif_file{2}.data = num2str(mif_index - mag_mif_start,'%x');
fid2 = fopen('LSM9DS1_Register_Settings_Startup_Memory.mif','w');
fprintf(fid2,'--MIF data generated by MATLAB\n');
fprintf(fid2,'--Date: %s \n\n', date);
fprintf(fid2,'WIDTH=16;\n');
fprintf(fid2,'DEPTH=256;\n');
fprintf(fid2,'ADDRESS_RADIX=HEX;\n');
fprintf(fid2,'DATA_RADIX=HEX;\n');
fprintf(fid2,'CONTENT BEGIN\n');

for k = 1:length(mif_file)
fprintf(fid2,'%x : %s;\n',k-1,mif_file{k}.data);
end
fprintf(fid2,'END;');
fclose(fid2);









