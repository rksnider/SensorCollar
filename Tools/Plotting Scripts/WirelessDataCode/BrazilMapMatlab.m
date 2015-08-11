% 
% % Base latitude and longitude for the area
% latLon = [7+31./60+53.3/3600 36+17./60+29.94/3600];
function BrazilMapMatlab(rs,names,pname,lw)
% Set the default interpreter
set(0,'defaulttextinterpreter','latex')
% % Read in the map
areaMap = imread('Area_marmoset groups_altitudes.tif'); 
offset = 225;
fade = 1;

% Set the scale
dPix = (757.5-559.6)/200;
c = ['y-.'; 'c-.'; 'm-.'; 'g-.'; 'w-.'; 'r-.';'b-.';'y- ';'c- ';'m- ';'g- ';'w- ';'r- ';'b- '; 'y: ';'c: ';'m: ';'g: ';'w: ';'r: ';'b: '];
% Radii for the db
% [-45 -55 -65 -75 -85 -95 ]
% rs = [100; 200; 300; 400; 500; 600; 700; 800; 900; 1000]*dPix;

figure
subplot(111)
% For 2 stations in the Algaroba area
image(areaMap(:,1+offset:1450+offset,:)*fade);
set(gca,'XTickLabel','','YTickLabel','')
axis square
hold on

% Two stations
x = [ 350 ]';
y = [ 550 ]';
  
% Radii for the db
% [-45 -55 -65 -75 -85 ]
for i = 1:size(x,1)
    drawCircle(x(i),y(i),rs,c,lw)
end
title(pname,'fontsize',20)
plegend=legend(names);
set(plegend,'interpreter','latex','fontsize',16)
end