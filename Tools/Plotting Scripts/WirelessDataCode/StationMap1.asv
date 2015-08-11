clear all
close all
clc

% Set the default interpreter
set(0,'defaulttextinterpreter','latex')

% Read in the map
areaMap = imread('Area_marmoset groups_altitudes.tif'); 
offset = 225;
fade = 1;
%% Best Case
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on

% Two stations
x = [   267.9662 432.5608 ]';
y = [   590.3054 501.7865 ]';
  
% Set the scale
dPix = (757.5-559.6)/200;
c = ['y-';'c-';'m-';'g-';'w-';'r-'];
% Radii for the db
% [-45 -55 -65 -75 -85 -95 ]
rs = [50; 133; 200; 325; 525]*dPix;
for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c)
end
title('Best Case Range','fontsize',20)
plegend=legend('-45 dBm', '-55 dBm', '-65 dBm', '-75 dBm', '-85 dBm');
set(plegend,'interpreter','latex','fontsize',16)

figure
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on

% Two stations
x = [   350 ]';
y = [   550 ]';
  
% Radii for the db
% [-45 -55 -65 -75 -85 ]
for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c)
end
title('Best Case Range','fontsize',20)
plegend=legend('-45 dBm', '-55 dBm', '-65 dBm', '-75 dBm', '-85 dBm');
set(plegend,'interpreter','latex','fontsize',16)

% Plot the Vacas area

x = [1249.8];
y = [1110.4];
figure
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on
for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c)
end
title('Best Case Range','fontsize',20)
plegend=legend('-45 dBm', '-55 dBm', '-65 dBm', '-75 dBm', '-85 dBm');
set(plegend,'interpreter','latex','fontsize',16)


figure
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on
rs = [0; 25; 75; 167; 275; 333]*dPix;
for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c)
end
title('Worst Case Range','fontsize',20)
plegend=legend('-45 dBm', '-55 dBm', '-65 dBm', '-75 dBm', '-85 dBm', '-90 dBm');
set(plegend,'interpreter','latex','fontsize',16)
%% Worst case
figure
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on

% Two stations
x = [   267.9662 432.5608 ]';
y = [   590.3054 501.7865 ]';
  

for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c)
end
title('Worst Case Range','fontsize',20)
plegend=legend('-45 dBm', '-55 dBm', '-65 dBm', '-75 dBm', '-85 dBm', '-90 dBm');
set(plegend,'interpreter','latex','fontsize',16)
figure
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on

% Two stations
x = [   350 ]';
y = [   550 ]';
  
% Radii for the db
% [-45 -55 -65 -75 -85 ]
for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c)
end
title('Worst Case Range','fontsize',20)
plegend=legend('-45 dBm', '-55 dBm', '-65 dBm', '-75 dBm', '-85 dBm', '-90 dBm');
set(plegend,'interpreter','latex','fontsize',16)

