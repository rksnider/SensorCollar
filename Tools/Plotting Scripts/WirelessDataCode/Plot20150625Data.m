% clear all
% close all
% clc

% Set the default interpreter
set(0,'defaulttextinterpreter','latex')

% Set some plotting constants
delta = 10;

% Read in all the data
ReadLunchrun
ReadAfternoon
ReadLR
ReadAR

% Track reciever packet errors
LRError = [];
ARError = [];

% Convert the cells to usable data
NAR = size(ARdBmCells,1);
NLR = size(LRdBmCells,1);

% Trim the lat and long arrays
AfternoonLatitude = deg2rad(AfternoonLatitude(2:end));
AfternoonLongitude = deg2rad(AfternoonLongitude(2:end));
LunchLatitude = deg2rad(LunchLatitude(2:end));
LunchLongitude = deg2rad(LunchLongitude(2:end));
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
        if lastError  == i - 1
            currentErrors = currentErrors+1;
            lastError = i;
        else
            lastError = i;
            if currentErrors > AMaxRow
                AMaxRow = currentErrors;
            end
            currentErrors = 1;
        end
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
        if lastError  == i - 1
            currentErrors = currentErrors+1;
            lastError = i;
        else
            lastError = i;
            if currentErrors > LMaxRow
                LMaxRow = currentErrors;
            end
            currentErrors = 1;
        end
    end
    
end

% Calculate the distance using the haversine formula
Rearth = 6371e+3;
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

% Create a time array of the appropriate length
maxDelay = 2e-5;

% LR and AR array start and end points
LStartLoc = find(LRTime-LunchTime(2)>0,1);
AStartLoc = find(ARTime-AfternoonTime(2)>0,1);

AEndLoc = find(ARTime-AfternoonTime(end-2)>0,1)-200;
LEndLoc = find(LRTime-LunchTime(end-1)>0,1);

ABreakLoc = find(ARTime(2:end)-ARTime(1:end-1)>maxDelay);
LBreakLoc = find(LRTime(2:end)-LRTime(1:end-1)>maxDelay);

% Break points for the Afternoon and Lunch arrays
AStop = find(AfternoonTime-ARTime(ABreakLoc)>0,1);
LStop = find(LunchTime-LRTime(LBreakLoc)>0,1);

AStart = find(AfternoonTime-ARTime(ABreakLoc+1)>0,1);
LStart = find(LunchTime-LRTime(LBreakLoc+1)>0,1);

AfternoonTimeCorrected = [ AfternoonTime(3:AStop)' AfternoonTime(AStart:end)']';
LunchTimeCorrected     = [ LunchTime(3:LStop)' LunchTime(LStart:end)']';

AdCorrected = [Ad(1:AStop-1)' Ad(AStart-1:end)']';
LdCorrected = [Ld(1:LStop-1)' Ld(LStart-1:end)']';

% Pick out the points to plot
awayARTime = ARTime(AStartLoc:ABreakLoc);
towardARTime = ARTime(ABreakLoc+1:AEndLoc);

awayAdist = interp1(AfternoonTimeCorrected,AdCorrected,awayARTime);
towardAdist = interp1(AfternoonTimeCorrected,AdCorrected,towardARTime);

awayLRTime = LRTime(LStartLoc:LBreakLoc);
towardLRTime = LRTime(LBreakLoc+1:LEndLoc);

awayLdist = interp1(LunchTimeCorrected,LdCorrected,awayLRTime);
towardLdist = interp1(LunchTimeCorrected,LdCorrected,towardLRTime);

awayAdBm = ARdBm(AStartLoc:ABreakLoc);
towardAdBm = ARdBm(ABreakLoc+1:AEndLoc);
awayLdBm = LRdBm(LStartLoc:LBreakLoc);
towardLdBm = LRdBm(LBreakLoc+1:LEndLoc);

% [awayAdist,inds] = sort(awayAdist);

% Update the error lists
ARError = ARError(ARError > AStartLoc);
LRError = LRError(LRError > LStartLoc);
ARError = ARError(ARError < AEndLoc);
LRError = LRError(LRError < LEndLoc);

AErrorAway = ARError(ARError < ABreakLoc)-AStartLoc;
AErrorToward   = ARError(ARError > ABreakLoc) - ABreakLoc;
LErrorAway = LRError(LRError < LBreakLoc)-LStartLoc;
LErrorToward = LRError(LRError > LBreakLoc)-LBreakLoc;

% Determine the probabilities of successful transmission within a certain
% range
ranges = 0:delta:20;
AAsf = zeros(size(awayAdBm));
ATsf = zeros(size(towardAdBm));
LAsf = zeros(size(awayLdBm));
LTsf = zeros(size(towardLdBm));
AAsf(AErrorAway) = 1;
LAsf(LErrorAway) = 1;
ATsf(AErrorToward) = 1;
LTsf(LErrorToward) = 1;

for i = 1:(size(ranges,2)-1)
    [AAPc(i),AAdBm(i),AANpts(i)] = correctProb(AAsf,awayAdist,awayAdBm,ranges(i),ranges(i+1));
    [LAPc(i),LAdBm(i),LANpts(i)] = correctProb(LAsf,awayLdist,awayLdBm,ranges(i),ranges(i+1));
    [ATPc(i),ATdBm(i),ATNpts(i)] = correctProb(ATsf,towardAdist,towardAdBm,ranges(i),ranges(i+1));
    [LTPc(i),LTdBm(i),LTNpts(i)] = correctProb(LTsf,towardLdist,towardLdBm,ranges(i),ranges(i+1));
end
% figure
% plot(awayAdist,awayAdBm,'k-')
% hold on
% for i = 1:size(AErrorAway,2)
%     inds = AErrorAway(i)-1:AErrorAway(i)+1;
%    plot(awayAdist(inds),awayAdBm(inds),'r-')
% end
% hold off
% title('RSSI dBm Vs Distance (Walking Away First Trip)','fontsize',20)
% xlabel('Distance [m]','fontsize',16)
% ylabel('RSSI [dBm]','fontsize',16)
% 
% 
% figure
% plot(towardAdist,towardAdBm,'k-')
% set(gca,'XDir','Reverse')
% hold on
% for i = 1:size(AErrorToward,2)
%     inds = AErrorToward(i)-1:AErrorToward(i)+1;
%    plot(towardAdist(inds),towardAdBm(inds),'r-')
% end
% hold off
% title('RSSI dBm Vs Distance (Walking Toward First Trip)','fontsize',20)
% xlabel('Distance [m]','fontsize',16)
% ylabel('RSSI [dBm]','fontsize',16)
% figure
% plot(awayLdist,awayLdBm,'k-')
% hold on
% for i = 1:size(LErrorAway,2)
%     inds = LErrorAway(i)-1:LErrorAway(i)+1;
%    plot(awayLdist(inds),awayLdBm(inds),'r-')
% end
% hold off
% title('RSSI dBm Vs Distance (Walking Away Second Trip)','fontsize',20)
% xlabel('Distance [m]','fontsize',16)
% ylabel('RSSI [dBm]','fontsize',16)
% figure
% plot(towardLdist,towardLdBm,'k-')
% set(gca,'XDir','Reverse')
% hold on
% for i = 1:size(LErrorToward,2)
%     inds = LErrorToward(i)-1:LErrorToward(i)+1;
%    plot(towardLdist(inds),towardLdBm(inds),'r-')
% end
% hold off
% title('RSSI dBm Vs Distance (Walking Toward Second Trip)','fontsize',20)
% xlabel('Distance [m]','fontsize',16)
% ylabel('RSSI [dBm]','fontsize',16)
% 
% disp(sprintf('Probability Of Successful Packet (First Run)'))
% for i = 1:(size(ranges,2)-1)
%    disp(sprintf('%.2f to %.2f dBm \t:\t %.4f',ranges(i),ranges(i+1),APc(i))) 
% end
% 
% disp(sprintf('Probability Of Successful Packet (Second Run)'))
% for i = 1:(size(ranges,2)-1)
%    disp(sprintf('%.2f to %.2f dBm \t:\t %.4f',ranges(i),ranges(i+1),LPc(i))) 
% end
% 
% % Create an axis label set
% labels = [];
% for i = 2:size(ranges,2)
%     labels = [labels; [sprintf('%04.0f',ranges(i-1)) ' to ' sprintf('%04.0f',ranges(i))]];
% end
% Nticks = size(ranges,2)-1;
% figure
% subplot(111)
% plot(ATPc,'k.')
% text((1:Nticks)+.025,ATPc-.001,num2str(ATPc'))
% set(gca,'XTickLabel',labels)
% set(gca,'Xtick',1:Nticks)
% title('Probability of Correct Packet Being Recieved (Walking Toward First Trip)','fontsize',20)
% xlabel('dBm Range','fontsize',16)
% ylabel('$P(C)$','fontsize',16)
% figure
% subplot(111)
% plot(AAPc,'k.')
% text((1:Nticks)+.025,AAPc-.001,num2str(AAPc'))
% set(gca,'XTickLabel',labels)
% set(gca,'Xtick',1:Nticks)
% title('Probability of Correct Packet Being Recieved (Walking Away First Trip)','fontsize',20)
% xlabel('dBm Range','fontsize',16)
% ylabel('$P(C)$','fontsize',16)
% figure
% subplot(111)
% plot(LTPc,'k.')
% text((1:Nticks)+.025,LTPc-.001,num2str(LTPc'))
% set(gca,'XTickLabel',labels)
% set(gca,'Xtick',1:Nticks)
% title('Probability of Correct Packet Being Recieved (Walking Toward Second Trip)','fontsize',20)
% xlabel('dBm Range','fontsize',16)
% ylabel('$P(C)$','fontsize',16)
% figure
% subplot(111)
% plot(LAPc,'k.')
% text((1:Nticks)+.025,LAPc-.001,num2str(LAPc'))
% set(gca,'XTickLabel',labels)
% set(gca,'Xtick',1:Nticks)
% title('Probability of Correct Packet Being Recieved (Walking Away Second Trip)','fontsize',20)
% xlabel('dBm Range','fontsize',16)
% ylabel('$P(C)$','fontsize',16)

%% Print a table
disp(sprintf('\t\t\t\t\tWalking Away'))
disp(sprintf('__________________________________________________________________'))
disp(sprintf('\tDistance\t\t\t\tP(F)      Avg RSSI dBm    N Points'))
for i = 1:(size(ranges,2)-1)
   disp(sprintf('%7.2f to %7.2f m \t:\t %.6f\t:\t%.4f\t:\t%i',ranges(i),ranges(i+1),(AAPc(i) + LAPc(i))/2,(AAdBm(i)+LAdBm(i))/2,(AANpts(i)+LANpts(i)))) 
end
disp(sprintf('\n\n'))
disp(sprintf('\t\t\t\t\tWalking Toward'))
disp(sprintf('__________________________________________________________________'))
disp(sprintf('\tDistance\t\t\t\tP(F)      Avg RSSI dBm    N Points'))
for i = 1:(size(ranges,2)-1)
   disp(sprintf('%7.2f to %7.2f m \t:\t %.6f\t:\t%.4f\t:\t%i',ranges(i),ranges(i+1),(ATPc(i) + LTPc(i))/2,(ATdBm(i)+LTdBm(i))/2,(ATNpts(i)+LTNpts(i)))) 
end

N = 10;
figure
subplot(221)
plot(runningAverage(awayAdist,N),runningAverage(awayAdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Away First Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)
subplot(222)
plot(runningAverage(awayLdist,N),runningAverage(awayLdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Away Second Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)
subplot(223)
plot(runningAverage(towardAdist,N),runningAverage(towardAdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Toward First Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)
subplot(224)
plot(runningAverage(towardLdist,N),runningAverage(towardLdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Toward Second Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)

figure
subplot(221)
plot(log10(runningAverage(awayAdist,N)),runningAverage(awayAdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Away First Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)
subplot(222)
plot(log10(runningAverage(awayLdist,N)),runningAverage(awayLdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Away Second Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)
subplot(223)
plot(log10(runningAverage(towardAdist,N)),runningAverage(towardAdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Toward First Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)
subplot(224)
plot(log10(runningAverage(towardLdist,N)),runningAverage(towardLdBm,N),'k-')
title('RSSI dBm Vs Distance (Walking Toward Second Trip)','fontsize',16)
xlabel('Distance [m]','fontsize',14)
ylabel('RSSI [dBm]','fontsize',14)


lw = 3;
names = [];
direction = 'Toward';
pname = ['$P(E)$ For $' sprintf('%.2f',ranges(1)) '$ to $' sprintf('%.2f',ranges(end)) '$ Meters $\Delta=' sprintf('%.2f',ranges(2)-ranges(1)) '$'];
for i = 1:size(ranges,2)-1
    num = (ATPc(i)+LTPc(i))/2;
    if ~isnan(num)
        names = [names; sprintf('$P(E) = %.4f$',num)];
    else
        names = [names; ['No Data' repmat(' ',1,size(names,2)-size('No Data',2))]];
    end
end
BrazilMapMatlab(ranges(2:end)',names,[ pname ' (' direction ')'],lw)
% names = [];
% pname = ['RSSI dBm For $' sprintf('%.2f',ranges(1)) '$ to $' sprintf('%.2f',ranges(end)) '$ Meters $\Delta=' sprintf('%.2f',ranges(2)-ranges(1)) '$'];
% for i = 1:size(ranges,2)-1
%     num = (ATdBm(i)+LTdBm(i))/2;
%     if ~isnan(num)
%         names = [names; sprintf('%9.4f dBm',num)];
%     else
%         names = [names; ['No Data' repmat(' ',1,size(names,2)-size('No Data',2))]];
%     end
% end
% BrazilMapMatlab(ranges(2:end)',names,[ pname ' (' direction ')'],lw)



