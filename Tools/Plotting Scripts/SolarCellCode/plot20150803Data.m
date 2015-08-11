clear
close all
clc

%% Read in the data
fullunshaded          = dlmread('20150803_full_unshaded.dat');           % mA
fullshaded            = dlmread('20150803_full_shaded.dat');     % mA
fullhalfshades        = dlmread('20150803_full_shaded_halves.dat');             % mA
smallcutunshaded      = dlmread('20150803_smallcut_unshaded.dat');       % mA
largecutunshaded      = dlmread('20150803_largecut_unshaded.dat');       % mA
smallcuthalfshades    = dlmread('20150803_smallcut_halfshaded.dat');       % mA

%% Plotting Variables

% Sun arrays
longsuns = .3:.05:1;
shortsuns = .3:.1:1;

% MPPC voltages
longmppc  = 0:.05:2.35;
shortmppc = 0:.1:2.3;

% Number of elements in each array
Nlong = size(fullunshaded,2);
Nshort = size(largecutunshaded,2);
Nlongsun = size(longsuns,2);
Nshortsun = size(shortsuns,2);
steps = 1;
%% Surfaces for the full cell (unshaded and shaded)

% The full solar panel
figure
subplot(223)
hold on
for i = 1:steps:Nlongsun
    plot(longmppc,5*fullunshaded(:,i),'k-')
end
hold off
title('Full Solar Cell Power vs MPPC (Unshaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')
subplot(224)
hold on
for i = 1:steps:Nlongsun
    plot(longmppc(2:end),5*fullshaded(:,i),'k-')
end
hold off
title('Full Solar Cell Power Vs MPPC Voltage (Shaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')

subplot(221)
s = surf(longsuns,longmppc,5*fullunshaded);
set(s,'EdgeColor','none','LineStyle','none','FaceLighting','phong');
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Full Cell Unshaded)')
colormap(jet)
colorbar

subplot(222)
s = surf(longsuns,longmppc(2:end),5*fullshaded);
set(s,'EdgeColor','none','LineStyle','none','FaceLighting','phong');
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Full Cell Shaded)')
colormap(jet)
colorbar

% Cutting the edge off
figure
subplot(223)
hold on
for i = 1:steps:Nshortsun
    plot(shortmppc,5*smallcutunshaded(:,i),'k-')
end
hold off
title('$\frac{4}{5}$ Solar Cell Power vs MPPC (Unshaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')
subplot(224)
hold on
for i = 1:steps:Nshortsun
    plot(shortmppc,5*largecutunshaded(:,i),'k-')
end
hold off
title('$\frac{1}{2}$ Solar Cell Power Vs MPPC Voltage (Unshaded)')
xlabel('MPPC [V]')
ylabel('Power [mW]')

subplot(221)
s = surf(shortsuns,shortmppc,5*smallcutunshaded);
set(s,'EdgeColor','none','LineStyle','none','FaceLighting','phong');
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Unshaded)')
colormap(jet)
colorbar

subplot(222)
s = surf(shortsuns,shortmppc,5*largecutunshaded);
set(s,'EdgeColor','none','LineStyle','none','FaceLighting','phong');
xlabel('Suns')
ylabel('MPPC [V]')
zlabel('Power [mW]')
title('Power Surface (Unshaded)')
colormap(jet)
colorbar

% Plot the shaded directional comparisons
figure
hold on
plot(shortmppc,fullhalfshades(:,1),'k-')
plot(shortmppc,fullhalfshades(:,2),'k-.')
plot(shortmppc,fullhalfshades(:,3),'k:')
plot(shortmppc,fullhalfshades(:,4),'k--')
hold off
title('Full Solar Cell Current vs Shading Direction')
xlabel('MPPC [V]')
ylabel('Current [mA]')
plegend = legend('Bottom Half','Top Half','Left Half','Right Half');
set(plegend,'interpreter','latex','fontsize',10,'location','northwest');
figure
hold on
plot(shortmppc,smallcuthalfshades(:,1),'k-')
plot(shortmppc,smallcuthalfshades(:,2),'k-.')
plot(shortmppc,smallcuthalfshades(:,3),'k:')
plot(shortmppc,smallcuthalfshades(:,4),'k--')
hold off
title('$\frac{4}{5}$ Solar Cell Current vs Shading Direction')
xlabel('MPPC [V]')
ylabel('Current [mA]')
plegend = legend('Bottom Half','Top Half','Left Half','Right Half');
set(plegend,'interpreter','latex','fontsize',10,'location','northwest');
% Find the best voltages for the parallel
format compact
inds = [];
for i = 1:Nlongsun
    inds(i) = find(fullunshaded(:,i) == max(fullunshaded(:,i)),1);
end
bestVs = longmppc(inds);
disp('full unshaded')
[longsuns' bestVs']
inds = [];
for i = 1:Nlongsun
    inds(i) = find(fullshaded(:,i) == max(fullshaded(:,i)),1);
end
bestVs = longmppc(inds);
disp('full shaded')
[longsuns' bestVs']
inds = [];
for i = 1:Nshortsun
    inds(i) = find(smallcutunshaded(:,i) == max(smallcutunshaded(:,i)),1);
end
bestVs = shortmppc(inds);
disp('small cut unshaded')
[shortsuns' bestVs']
inds = [];
for i = 1:Nshortsun
    inds(i) = find(largecutunshaded(:,i) == max(largecutunshaded(:,i)),1);
end
bestVs = shortmppc(inds);
disp('large cut shaded')
[shortsuns' bestVs']
format loose