%% Downconverter for Invensense's Digital MEMS Microphone INMP621
% This file creates the downconveter VHDL code for Invensense's INMP621
% digital MEMS microphone.  Downconversion first lowpass filters the input PDM signal to attenuate
% the frequencies that will alias when subsampled. The datasheet of the target part can be found at:  
% http://invensense.com/mems/microphone/documents/INMP621.pdf
%
%----------------------------------------------------------------------------------------------------
%
% Filename:     	DownConverter.m
% Description:  	The Matlab Script create VHDL code for a CIC
%                   downconvert
% Author:			Ross K. Snider
% Lab:              Dr. Snider
% Department:       Electrical and Computer Engineering
% Institution:      Montana State University
% Support:          This work was supported under NSF award No. DBI-1254309
% Creation Date:	June 2014	
%		
%---------------------------------------------------------------------------------------------------
%
% Version 1.0
%
%---------------------------------------------------------------------------------------------------
%
% Modification Hisory (give date, author, description)
%
% None
%
% Please send bug reports and enhancement requests to Dr. Snider at rksnider@ece.montana.edu
%
%---------------------------------------------------------------------------------------------------

%clear all;
%close all;

%% Set Initial Parameters
% The maximum rated clock frequency for the INMP621 is 3.6 MHz so we will
% set this as the input sample rate.
Fs_in             = 3.6e6;                      % input sample rate
Decimation_factor = 64;                         % decimation factor
Fs_out            = Fs_in/Decimation_factor;    % output sample rate

bps_in          = Fs_in;
Bytes_sec_in    = bps_in/8;

disp(['The input sample rate is '  num2str(Fs_in/1000000) ' Msamples/sec '])
disp(['The input data rate is ' num2str(bps_in/1000000) ' Mbps, which is '  num2str(Bytes_sec_in/1000) ' KBytes/sec']) 
disp(['The decimation factor is '  num2str(Decimation_factor) ' which gives an output sample rate of ' num2str(Fs_out/1000) ' Ksamples/sec '])

%% Understanding the CIC Filter Parameters
% A good overview of CIC decimation filters by Richard Lyons can be found
% at:
% http://www.embedded.com/design/configurable-systems/4006446/Understanding-cascaded-integrator-comb-filters
% .  Note figure 10 from the Richard Lyons article for the Differential Delay
% effects (N in the figure).  The differential delay will determine the
% number of nulls in the frequency response.  It is typically set to 1.
%
% The Matlab digital filter design function fdesign() can design CIC
% decimators.  Type >>help fdesign.decimator to see all the decimator types.  
%
% We will use the CIC decimator, which can except the following options:
%

get(fdesign.decimator)

%% Set the CIC Decimator Options
% The primary CIC decimator design options are the following:
%
% # Decimation Factor - The samping rate reduction factor.
% # Differential_Delay - Typically set to 1
% # Passband Frequency (normalized)
% # Aliasing_Attenuation - Attenuation outside of passband
%

Differential_Delay = 1;
Passband_Frequency = 0.1;  % normalized frequency 
Aliasing_Attenuation = 60;  % in dB
fd1 = fdesign.decimator(Decimation_factor,'cic',Differential_Delay,'fp,ast',Passband_Frequency,Aliasing_Attenuation)

%% Create Two VHDL designs.  
% The first design will keep full numeric precision.  The second design will force the output to be a 16-bit word.
% In both cases the input will be 2-bits (signed one bit PDM value).  The
% is done be setting InputWordLength=2 and InputFracLength=0.
%
% The default is full precision so we don't need to do anything more.

Hd_full = design(fd1);
set(Hd_full,'InputWordLength',2);
set(Hd_full,'InputFracLength',0);

%% Full precision Case
% The settings for the full precision case can be seen below. Notice that
% FilterInternals='FullPrecision' and that OutputWordLength=20.

get(Hd_full)

%% Full precision frequency response
% The frequency response can be seen below.  Notice that the dotted red
% lines mark our Passband_Frequency and Aiasing Attenuation (we are below what we specified, which is good).
%

fvtool(Hd_full)

%% Generate VHDL code for the full precision case.
% Next we generate the VHDL code for the full precision case.
%

generatehdl(Hd_full)
fdhdltool(Hd_full)

%% Create the 16-bit Design
% In a similar manner we create the VHDL code with a 16-bit output word. We
% now set FilterInternals='MinWordLengths' and OutputWordLength=16
%

Hd_16   = design(fd1);
set(Hd_16,'InputWordLength',2);
set(Hd_16,'InputFracLength',0);
set(Hd_16,'FilterInternals','MinWordLengths');
set(Hd_16,'OutputWordLength',16);


%% 16-bit Case
% The settings for the 16-bit case can be seen below. 
%

get(Hd_16)

%% 16-bit frequency response
% The frequency response can be seen below.  Notice that the dotted red
% lines mark our Passband_Frequency and Aiasing Attenuation (we are below what we specified, which is good).
%

fvtool(Hd_16)
fdhdltool(Hd_16)

%% Generate VHDL code for the 16-bit case.
% Next we generate the VHDL code for the 16-bit case.
%

generatehdl(Hd_16)

%% Data Savings
% Do we save data space by down converting?

disp(['The PDM input data rate is ' num2str(Bytes_sec_in/1000) ' KBytes/sec'])
disp(['The 20-bit output data rate is ' num2str((Fs_out*20/8)/1000) ' KBytes/sec a reduction factor of ' num2str(Bytes_sec_in/(Fs_out*20/8)) ])
disp(['The 16-bit output data rate is ' num2str((Fs_out*16/8)/1000) ' KBytes/sec a reduction factor of ' num2str(Bytes_sec_in/(Fs_out*16/8)) ])


