clear
close all
clc

% Read in the map
areaMap = imread('BozemanMap.png');


% Set some plotting constants
delta = 100;

% Track reciever packet errors
LRError = [];
ARError = [];

% Read in all the data
ReadLunchrun
ReadAfternoon
ReadLR
ReadAR

% Convert the cells to usable data
NAR = size(ARdBmCells,1);
NLR = size(LRdBmCells,1);

% Trim the lat and long arrays
AMaxRow = 0;
LMaxRow = 0;
lastError = 0;
currentErrors = 1;

for i = 1:NAR
    cellVal = ARdBmCells{i};
    if size(cellVal,2) < 16
        ARdBm(i) = str2num(cellVal(3:5)); %#ok
    else
        ARdBm(i) = ARdBm(i-1); %#ok
    end
    if ARdBm(i) > 0
        ARdBm(i) = ARdBm(i-1); %#ok
    end
    if size(cellVal,2) > 5
        ARError(end+1) = i; %#ok
    end
    
end
for i = 1:NLR
    cellVal = LRdBmCells{i};
    if size(cellVal,2) < 6
        LRdBm(i) = str2num(cellVal(3:5)); %#ok 
    elseif size(cellVal,2) < 11
        LRdBm(i) = str2num(cellVal(6:end)); %#ok
    elseif size(cellVal,2) < 16
        LRdBm(i) = str2num(cellVal(3:5)); %#ok    
        
    else
        LRdBm(i) = LRdBm(i-1); %#ok
    end
    if LRdBm(i) > 0
        LRdBm(i) = LRdBm(i-1); %#ok
    end
    if size(cellVal,2) > 11
        LRError(end+1) = i;  %#ok
       
    end
    
end

% Find the coordinate transform
kagy  = [152.7166 537.6035];
greek = [384.5951 384.1444];
start = [157.0897 085.5537];

kagylatlon  = [45+39./60+37.15/3600 -(111+2./60+48.19/3600)];
greeklatlon = [45+39./60+45.21/3600 -(111+2./60+30.12/3600)];
startlatlon = [45+40./60+01.39/3600 -(111+2./60+48.04/3600)];

deltalat = abs(kagylatlon(1)-greeklatlon(1));
deltalon = -abs(kagylatlon(2)-greeklatlon(2));

deltaxpix = abs(kagy(1)-greek(1));
deltaypix = abs(kagy(2)-greek(2));

scaleFactors = [-deltaypix/deltalat -deltaxpix/deltalon];

offset = startlatlon - [start(2) start(1)]./scaleFactors;

% Format the lat and lons
Alatlon = [AfternoonLatitude(2:end) AfternoonLongitude(2:end)];
Llatlon = [LunchLatitude(2:end) LunchLongitude(2:end)];
reps = size(Alatlon,1);
Alatlon = (Alatlon - repmat(offset,reps,1)).*repmat(scaleFactors,reps,1);
reps = size(Llatlon,1);
Llatlon = (Llatlon - repmat(offset,reps,1)).*repmat(scaleFactors,reps,1);

% Calculate the distance using the haversine formula
Rearth = 6371e+3;
AfternoonLatitude = deg2rad(AfternoonLatitude(2:end));
AfternoonLongitude = deg2rad(AfternoonLongitude(2:end));
LunchLatitude = deg2rad(LunchLatitude(2:end));
LunchLongitude = deg2rad(LunchLongitude(2:end));
AdeltaLat = AfternoonLatitude(2:end) - AfternoonLatitude(1);
LdeltaLat = LunchLatitude(2:end) - LunchLatitude(1);

AdeltaLon = AfternoonLongitude(2:end) - AfternoonLongitude(1);
LdeltaLon = LunchLongitude(2:end) - LunchLongitude(1);

Aa = power(sin(AdeltaLat./2),2) + cos(AfternoonLatitude(2:end)).*...
            cos(AfternoonLatitude(1:end-1)).*power(sin(AdeltaLon./2),2);

La = power(sin(LdeltaLat./2),2) + cos(LunchLatitude(2:end)).*...
            cos(LunchLatitude(1:end-1)).*power(sin(LdeltaLon./2),2);

Ac = 2*atan2(sqrt(Aa),sqrt(1-Aa));
Lc = 2*atan2(sqrt(La),sqrt(1-La));
Ad = Ac*Rearth;
Ld = Lc*Rearth;


%% P(E)
% Determine the probabilities of successful transmission within a certain
% range

N = 10;
AError = zeros(size(ARdBm));
LError = zeros(size(LRdBm));
AError(ARError) = 1;
LError(LRError) = 1;

APe = [];
LPe = [];
for i = 1:(length(AError)-N)
   APe(i) = 1/N*sum(AError(i:(i+N-1))); 
end
for i = 1:(length(LError)-N)
    LPe(i) = 1/N*sum(LError(i:(i+N-1)));
end

%% Plotting


[Lmean, Lvar] = runningAverage(LRdBm,N);
Ldist = interp1(LunchTime(2:end-1),Ld,LRTime);
[Ldist, ~] = runningAverage(Ldist,N);

[Amean, Avar] = runningAverage(ARdBm,N);
Adist = interp1(AfternoonTime(2:end-1),Ad,ARTime);
[Adist, ~] = runningAverage(Adist,N);


figure
subplot(121)
image(areaMap)

xstart = 180;
xend = 180+25;
ystart = 83;
yend = 730;
Amid = size(Amean,2)/2;
Lmid = size(Lmean,2)/2;

x = linspace(xstart,xend,2);
y = linspace(ystart,yend,Amid)';
x = repmat(x,size(y,1),1);
y = repmat(y,1,size(x,2));
z=repmat(Amean(1:Amid),size(x,2),1)';
sp = 121;
cmap = jet;


% bars(2) = surf(x-27-100,y,repmat(Avar(1:Amid),size(x,2),1)');
% bars(3) = surf(x,y,repmat(Amean(Amid+1:end),size(x,2),1)');
% bars(4) = surf(x+27,y,repmat(Avar(Amid+1:end),size(x,2),1)');
plotChris('First Trip Away Means',20,-50,-100,x,y,z,sp,cmap,1,0)
sp=122;
cmap=jet;
subplot(sp)
image(areaMap)
z = repmat(Avar(1:Amid),size(x,2),1)';
plotChris('First Trip Away Variances',20,max(max(Avar(1:Amid))),min(min(Avar(1:Amid))),x,y,z,sp,cmap,1,0)
figure
sp=121;
subplot(sp)
image(areaMap)
z=repmat(APe(1:Amid),size(x,2),1)';
plotChris('First Trip Away $P(E)$',20,max(max(APe(1:Amid))),min(min(APe(1:Amid))),x,y,z,sp,cmap,1,4)

figure
sp=121;
subplot(sp);
image(areaMap)
z=repmat(Amean(1:Amid),size(x,2),1)';
plotChris('First Trip Toward Means',20,max(max(Amean(Amid+1:end))),min(min(Amean(Amid+1:end))),x,y,z,sp,cmap,1,0)
sp=122;
cmap=jet;
subplot(sp)
image(areaMap)
z = repmat(Avar(Amid+1:end),size(x,2),1)';
plotChris('First Trip Toward Variances',20,max(max(Avar(Amid+1:end))),min(min(Avar(Amid+1:end))),x,y,z,sp,cmap,1,0)
figure
sp=121;
subplot(sp)
image(areaMap)
z=repmat(APe(Amid+1:end),size(x,2),1)';
plotChris('First Trip Toward $P(E)$',20,max(max(APe(Amid+1:end))),min(min(APe(Amid+1:end))),x,y,z,sp,cmap,1,4)

