
% Read in the data
parallel          = dlmread('20150616_parallelData.dat');           % mA
parallelShaded    = dlmread('20150616_parallelDataShaded.dat');     % mA
seriesDiode       = dlmread('20150616_seriesData.dat');             % mA
seriesDiodeShaded = dlmread('20150616_seriesDataShaded.dat');       % mA

% Create the variables
suns = .3:.1:1;

mppcps = 0:.05:2.15;
mppcs = 0:.1:4.5;
mppcss = 0:.1:4.35;

% Plot some stuff
steps = 1;
Nparallel = size(parallel,1);
NparallelS = size(parallelShaded,1);
Nseries   = size(seriesDiode,1);
NseriesS  = size(seriesDiodeShaded,1);
Nsun      = size(suns,2);
figure
subplot(223)
hold on
for i = 1:steps:Nsun
    plot(mppcps,5*parallel(:,i),'k.')
end
hold off
title('Parallel Power Vs MPPC Voltage (Unshaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')
subplot(224)
hold on
for i = 1:steps:Nsun
    plot(mppcps,5*parallelShaded(:,i),'k.')
end
hold off
title('Parallel Power Vs MPPC Voltage (Shaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')

subplot(221)
surf(suns,mppcps,5*parallel)
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Unshaded)')

subplot(222)
surf(suns,mppcps,5*parallelShaded)
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Shaded)')

% Repeat for the series data
figure
subplot(223)
hold on
for i = 1:steps:Nsun
    plot(mppcs,5*seriesDiode(:,i),'k-')
end
hold off
title('Series Power Vs MPPC Voltage (Unshaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')
subplot(224)
hold on
for i = 1:steps:Nsun
    plot(mppcss,5*seriesDiodeShaded(:,i),'k-')
end
hold off
title('Series Power Vs MPPC Voltage (Shaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')

subplot(221)
surf(suns,mppcs,5*seriesDiode)
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Unshaded)')

subplot(222)
surf(suns,mppcss,5*seriesDiodeShaded)
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Shaded)')
% Find the best voltages for the parallel
format compact
inds = [];
for i = 1:Nsun
    inds(i) = find(parallel(:,i) == max(parallel(:,i)),1);
end
bestVs = mppcps(inds);
disp('parallel unshaded')
[suns' bestVs']
inds = [];
for i = 1:Nsun
    inds(i) = find(parallelShaded(:,i) == max(parallelShaded(:,i)),1);
end
bestVs = mppcps(inds);
disp('parallel shaded')
[suns' bestVs']
inds = [];
for i = 1:Nsun
    inds(i) = find(seriesDiode(:,i) == max(seriesDiode(:,i)),1);
end
bestVs = mppcs(inds);
disp('series unshaded')
[suns' bestVs']
inds = [];
for i = 1:Nsun
    inds(i) = find(seriesDiodeShaded(:,i) == max(seriesDiodeShaded(:,i)),1);
end
bestVs = mppcs(inds);
disp('series shaded')
[suns' bestVs']
format loose