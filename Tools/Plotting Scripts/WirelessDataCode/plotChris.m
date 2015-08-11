function plotChris(ptitle,Ncb,upper,lower,x,y,z,sp,cmap,trip,rnd)
    % Set some defaults
    spacing = 50;

    % Set the default interpreter
    set(0,'defaulttextinterpreter','latex')

    % Set some plotting constants
    delta = 100;

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

    spacingVal = spacing;
    % Plot the data
    subplot(sp)
    if trip == 1
    hold on
    plot(Alatlon(:,2),Alatlon(:,1))
    title(ptitle,'fontsize',20)
    for i = 1:size(Alatlon,1)-2
        if Ad(i) > spacingVal
            t=text(Alatlon(i,2)-65,Alatlon(i,1), [sprintf('%.1f',spacingVal) '$\rightarrow$ ']);
            set(t,'color','k')
            spacingVal = spacingVal+spacing;
        end
    end
    hold off
    end
    if trip == 2
        hold on
        plot(Llatlon(:,2),Llatlon(:,1))
        title('Second Route','fontsize',20)
        spacingVal = spacing;
        for i = 1:size(Llatlon,1)-2
            if Ld(i) > spacingVal
                t=text(Llatlon(i,2)-65,Llatlon(i,1), [sprintf('%.1f',spacingVal) '$\rightarrow$ ']);
                set(t,'color','k')
                spacingVal = spacingVal+spacing;
            end
        end
    end
    hold on
    bars = surf(x,y,z);
    hold off
    set(bars,'EdgeColor','none','LineStyle','none','FaceLighting','phong');
    % Setup the colormaps
    caxis([lower upper])
    colormap(cmap);
    b = colorbar;
    set(b,'YTick',linspace(0,64,Ncb),'YTickLabel',floor(linspace(lower,upper,Ncb)*10^rnd)/10^rnd)

end