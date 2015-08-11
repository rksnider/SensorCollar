close all
clear all
clc

areaMap = imread('Area_marmoset groups_altitudes.tif');
% worldmap([-9 -5],[-38 -34])
% load geoid
% geoshow(geoid, geoidrefvec, 'DisplayType', 'texturemap');
% load coast
% geoshow(lat, long)

% Plotting window
lat = [-7.52 -7.54 -7.52 -7.54 ]; 
lon = [-36.305 -36.285 -36.305 -36.285 ]; 

% % stationlatlon = [-7-31./60-43.37/3600 -36-17./60-49.93/3600];
% stationlatlon = [ -7.530301603456211 -36.296636274531579];
% figure
% hold on
% plot(lon,lat,'.r','MarkerSize',1) 
% plot(stationlatlon(2), stationlatlon(1),'r.','Markersize',20)
% hold off
% plot_google_map('MapType','hybrid')
% figure
% hold on
% plot(lon,lat,'.r','MarkerSize',1) 
% plot(stationlatlon(2), stationlatlon(1),'r.','Markersize',20)
% hold off
% plot_google_map('MapType','terrain')
% 
% Map of Bozeman Area
figure
bozemanlatlon = [45.6778 -111.0472];
blatlon = repmat(bozemanlatlon,4,1);
sf = .02;
plot(blatlon(:,2)-[sf;sf;-sf;-sf], blatlon(:,1)-[sf;sf;-sf;-sf],'.r')
plot_google_map('MapType','terrain')

% Map of Chris's trip
figure
% Read in all the data
ReadLunchrun
ReadAfternoon
subplot(121)
plot(AfternoonLongitude,AfternoonLatitude)
plot_google_map('Maptype','terrain')
subplot(122)
plot(LunchLongitude,LunchLatitude)
plot_google_map('Maptype','terrain')