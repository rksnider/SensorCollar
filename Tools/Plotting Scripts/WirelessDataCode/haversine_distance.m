function d = haversine_distance(lat,lon,units)

    if ~exist('units','var')
        units = 'rad';
    end
    if strcmp(units,'deg')
        disp('Converting units to radians')
        lat = deg2rad(lat);
        lon = deg2rad(lon);
    end
    % Calculate the distance using the haversine formula
    Rearth = 6371e+3;
    
    % Find the change in latitude and longitude
    deltaLat = lat(2:end) - lat(1);
    deltaLon = lon(2:end) - lon(1);

    % Calculate the 'a' factor
    a = power(sin(deltaLat./2),2) + cos(lat(2:end)).*...
                cos(lat(1:end-1)).*power(sin(deltaLon./2),2);
            
    % Calculate the 'c' factor
    c = 2*atan2(sqrt(a),sqrt(1-a));
    
    % Determine the approximate distance
    d = c*Rearth;
end