function current_graph (mamps, sdata, segs, segno, zones)
%CURRENT_GRAPH    Graph current sample segment extracted from a file.
% usage current_graph (mamps, sdata, segs, segno [,zones])
%             mamps = Vector of milliamp samples taken.
%             sdata = Vector of inputs taken with the samples.
%              segs = Vector of the start of different sample segments taken.
%             segno = Segment number to display.
%             zones = Vector of std-dev multiples about mean to shade.

if (nargin < 5)
    zones = [3.0 5.0 7.0] ;
end

sample_time = 0.575 ;       % Milliseconds per sample

zcolors  = [[0.8 0.8 0.8]; [0.9 0.9 0.9]; [1.0 1.0 0.5]; [1.0 0.7 0.5] ; ...
            [0.9 0.5 0.5]] ;
extcolor = [1.0 0.0 0.0] ;

incolors = [[0.0 0.0 1.0]; [0.0 1.0 0.0]; [0.0 0.0 0.0]; [1.0 1.0 1.0]; ...
            [0.0 0.0 1.0]; [0.0 1.0 0.0]; [0.0 0.0 0.0]; [1.0 1.0 1.0]] ;

%   Determine the start and end of the segment.

if (segno < length (segs))
    seglen = double (segs (segno + 1) - segs (segno)) ;
else
    seglen = double (length (mamps) - segs (segno)) ;
end

segstart = double (segs (segno)) ;
segend   = segstart + seglen - 1 ;

%   Determine the parameters of the plot area.

avg      = mean (mamps (segstart:segend)) ;
std_dev  = std  (mamps (segstart:segend)) ;

bounds   = sort (zones) .* std_dev ;

high     = (max (mamps (segstart:segend)) - avg) * 1.10 ;
low      = (avg - min (mamps (segstart:segend))) * 1.10 ;
bound    = max ([high low max(bounds)]) ;

top      = avg + bound * 1.10 ;
bottom   = avg - bound * 1.10 ;

zborders = [(avg - zones .* std_dev) ; (avg + zones .* std_dev)]' ;

%   Plot regions.

figure

segtimes = (0 : seglen - 1) .* (sample_time / 1000) ;

allx     = [segtimes(1) segtimes(seglen)] ;

fill_x = [segtimes(1) segtimes(seglen) segtimes(seglen) segtimes(1)] ;

fill (fill_x, [top top bottom bottom], extcolor, 'EdgeColor', 'none'), hold on ;

for k = length(zones):-1:1
    fill_y = [zborders(k,1) zborders(k,1) zborders(k,2) zborders(k,2)] ;
    fill_c = zcolors (k,:) ;

    fill (fill_x, fill_y, fill_c, 'EdgeColor', 'none'), hold on ;
end

%   Plot the input data.

data_offset = bound * 10.0 / 1000.0 ;
data_width  = 3 ;

for k = 1 : length(incolors)
    line_y = top - k * data_offset ;

    plot (allx,[line_y line_y],'LineWidth', data_width,             ...
          'Color', incolors(length(incolors)-k+1,:)), hold on ;
end

for k = 1 : length(incolors)
    line_y = bottom + k * data_offset ;

    plot (allx,[line_y line_y], 'LineWidth', data_width,            ...
          'Color', incolors(k,:)), hold on ;
end

for k = 0 : length(incolors) / 2 - 1
    data_y = bottom + data_offset .* ((k * 2 + 2) -                 ...
                double (bitand (bitshift (uint8(sdata), -k),        ...
                        ones (1, length(sdata), 'uint8')))) ;

    plot(segtimes, data_y(segstart : segend),                       ...
         'LineWidth', data_width,                                   ...
         'Color', extcolor), hold on ;
end

for k = length(incolors) / 2 - 1 : -1 : 0
    data_y = top - data_offset .* ((k * 2 + 1) +                    ...
                double (bitand (bitshift (uint8(sdata), k-7),       ...
                        ones (1, length(sdata), 'uint8')))) ;

    plot(segtimes, data_y(segstart : segend),                       ...
         'LineWidth', data_width, 'Color', extcolor), hold on ;
end

%   Plot the sample data.

plot (segtimes,mamps(segstart : segend), 'b'), hold on ;
plot (allx, [avg avg], 'g'), hold off ;

axis ([segtimes(1) segtimes(seglen) bottom top]) ;

xlabel ('Seconds') ;
ylabel ('Milliamps') ;
grid    minor ;

title (sprintf ('Current Usage for Segment %d. Mean = %g mA, Std Deviation %g mA', ...
                segno, avg, std_dev)) ;
