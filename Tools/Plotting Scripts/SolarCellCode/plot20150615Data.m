
% Set the default interpreter as latex
set(0,'defaulttextinterpreter','latex')

% Read in the data
parallel = dlmread('20150615_parallelData.dat');
parallelShaded = dlmread('20150615_parallelDataShaded.dat');

seriesDiode = dlmread('20150615_seriesDataDiode.dat');
seriesDiodeShaded = dlmread('20150615_seriesDataDiodeShaded.dat');

mppcPShaded = 0:.1:2.2;
mppcP = 0:.05:2.25;
mppcSDShaded = 0:.1:4.5;
mppcSD = 0:.05:4.7;

% Find the maximum points
SDmax = find(seriesDiode == max(seriesDiode),1);
SDShadedmax = find(seriesDiodeShaded == max(seriesDiodeShaded),1);
parallelmax = find(parallel == max(parallel),1);
parallelShadedmax = find(parallelShaded == max(parallelShaded),1);

seriesMax = [ mppcSD(SDmax),seriesDiode(SDmax) ];
seriesMaxShaded = [ mppcSDShaded(SDShadedmax),seriesDiodeShaded(SDShadedmax) ];
parallelMax = [ mppcP(parallelmax) parallel(parallelmax) ];
parallelMaxShaded = [ mppcPShaded(parallelShadedmax) parallelShaded(parallelShadedmax)];
% Plot the data
figure
subplot(211)
hold on
plot(mppcSD,seriesDiode,'k.')
plot(mppcSDShaded,seriesDiodeShaded,'k*')
plot(seriesMax(1), seriesMax(2),'ro','linewidth',5)
plot(seriesMaxShaded(1), seriesMaxShaded(2),'rs','linewidth',5)
hold off
title('Solar Panels In Series With Bypass Diodes','fontsize',20)
xlabel('MPPC [V]','fontsize',16)
ylabel('Output Current [mA]','fontsize',16)
plegend = legend('Unshaded','One Panel Shaded', ...
    ['Full Light Max: $' num2str(seriesMax(2)) '$ mA'], ['Shaded Max: $' num2str(seriesMaxShaded(2)) '$ mA']);
set(plegend,'fontsize',12,'location','northwest')

subplot(212)
hold on
plot(mppcP,parallel,'k.')
plot(mppcPShaded,parallelShaded,'k*')
plot(parallelMax(1), parallelMax(2),'ro','linewidth',5)
plot(parallelMaxShaded(1), parallelMaxShaded(2),'rs','linewidth',5)
hold off
title('Solar Panels In Parallel','fontsize',20)
xlabel('MPPC [V]','fontsize',16)
ylabel('Output Current [mA]','fontsize',16)
plegend = legend('Unshaded','One Panel Shaded', ...
    ['Full Light Max: $' num2str(parallelMax(2)) '$ mA'], ['Shaded Max: $' num2str(parallelMaxShaded(2)) '$ mA']);
set(plegend,'fontsize',12,'location','northwest')