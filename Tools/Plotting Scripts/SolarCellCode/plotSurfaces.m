clear all
close all
clc


% Read in the data
mas = dlmread('seriesData.dat');        % mA
map = dlmread('parallelData.dat');      % mA

% Set the constants
seriesR = (100:25:500)*1e+3;            % Ohms
parallelR = (100:5:200)*1e+3;           % Ohms
suns = .3:.05:1;                        % Sun Brightness
Vout = 5;                               % Volts
AMPPC = 10e-6;                          % Amps

% Calculate the powers
seriesP = mas*1e-3*Vout;                % Watts
parallelP = map*1e-3*Vout;              % Watts

% Calculate the MPPC voltage
seriesV = seriesR*AMPPC;                % Volts
parallelV = parallelR*AMPPC;            % Volts


% Plot some stuff
steps = 1;
Nparallel = size(map,1);
Nseries   = size(mas,1);
Nsun      = size(suns,2);
figure
subplot(223)
hold on
for i = 1:steps:Nsun
    plot(parallelV,parallelP(:,i),'k.')
end
hold off
title('Power Vs MPPC Voltage (Parallel)')
xlabel('MPPC [V]')
ylabel('Power [W]')
subplot(224)
hold on
for i = 1:steps:Nsun
    plot(seriesV,seriesP(:,i),'k.')
end
hold off
title('Power Vs MPPC Voltage (Series)')
xlabel('MPPC [V]')
ylabel('Power [W]')

subplot(221)
surf(suns,parallelV,parallelP)
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [W]')
title('Power Surface (Parallel)')

subplot(222)
surf(suns,seriesV,seriesP)
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [W]')
title('Power Surface (Parallel)')

% Find the best voltages for the parallel
inds = [];
for i = 1:Nsun
    inds(i) = find(parallelP(:,i) == max(parallelP(:,i)),1);
end
bestVs = parallelV(inds);
[suns' bestVs']