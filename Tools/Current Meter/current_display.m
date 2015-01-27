function current_display (mamps, segs, segno, display_spec, columns, rows)
%CURRENT_DISPLAY    Display current sample segment extracted from a file.
% usage current_display (mamps, segs, segno [,display_spec [,columns [,rows]]])
%             mamps = Vector of milliamp samples taken.
%              segs = Vector of the start of different sample segments taken.
%             segno = Segment number to display.
%      display-spec = Either: pageno or [start-millisec end-millisec]
%            pageno = Page to display (0 display everthing on one page).
%       [start end] = Vector specifying the start and end samples to plot.
%           columns = Number of columns per row.
%              rows = Number of rows on the graph.  [start end] overrides this.

sample_time = 0.575 ;       % Milliseconds per sample

%   Determine the start and end of the segment.

if (segno < length (segs))
    seglen = double (segs (segno + 1) - segs (segno)) ;
else
    seglen = double (length (mamps) - segs (segno)) ;
end

segstart   = double (segs (segno)) ;
segend     = segstart + seglen - 1 ;

samp_start = 1 ;
samp_end   = seglen ;

%   Set the arguments defaults.

if (nargin < 4)
    pageno = 0 ;
else
    %   Display spec is start and end time in milliseconds.
    %   Convert these times into sample offsets into the segment.

    if (length (display_spec) > 1)
        start_tm = double (display_spec (1)) ;
        end_tm   = double (display_spec (2)) ;

        if (start_tm < 0.0)
            start_tm = 0.0 ;
        end

        if (start_tm > end_tm)
            temp     = start_tm;
            start_tm = end_tm;
            end_tm   = temp ;
        end

        samp_start = fix (start_tm * 1000 / sample_time) + 1 ;
        samp_end   = fix (end_tm   * 1000 / sample_time + 0.5) + 1 ;

        if (samp_end > seglen)
            samp_end = seglen ;
        end

        pageno     = -1 ;

    %   Display the entire segment if the display spec is empty or invalid.

    elseif (length (display_spec) < 1)
        pageno     = 0 ;
    elseif (display_spec < 0)
        pageno     = 0 ;

    %   The display spec is a page number.

    else
        pageno = display_spec ;
    end
end

%   Set the default rows and columns if necessary.

if (nargin < 5)
    rows = 5 ;
end

if (nargin < 6)
    columns = 200 ;
end

%   Calculate the number of rows and columns needed when the samples
%   to display are specified explicitly.

samp_count  = samp_end - samp_start + 1 ;

if (pageno < 0)
    if (samp_count < columns)
        rows    = 1 ;
        columns = samp_count ;
    elseif (samp_count > rows * columns)
        pageno  = 0 ;
    else
        rows    = fix ((samp_count - 1) / columns) + 1 ;
    end
end

%   Set the dimensions of the figure.

figure

dispcnt = rows * columns ;

seqcnt  = zeros (rows, columns) ;

for k = 1:rows
    seqcnt (k,:) = ((k-1) * columns) : (k * columns - 1) ;
end

%   Extract the samples to display from the measurements.

if (pageno == 0)
    if (samp_count < dispcnt)
        samples = [mamps(segstart+samp_start-1 : segstart+samp_end-1), ...
                   zeros(1,dispcnt-samp_count,'single')] ;
    else

        %   Combine and average multiple samples to produce a page
        %   of results.

        sampcmb = samp_count / dispcnt ;

        cmbcnt = 0 ;
        cmbamt = 0 ;
        cmbno  = 0 ;
        sampno = 0 ;

        samples = zeros (1, dispcnt, 'single') ;

        for k = 1:samp_count
            cmbcnt = cmbcnt + 1 ;

            if (cmbcnt >= sampcmb)
                sampno = sampno + 1 ;
                samples (sampno) = single (cmbamt / cmbno) ;
                cmbcnt = cmbcnt - sampcmb ;
                cmbamt = 0 ;
                cmbno  = 0 ;
            end

            cmbamt = cmbamt + mamps (segstart+k-1) ;
            cmbno  = cmbno + 1 ;
        end

        %   Finish any left over amount.

        if (sampno < dispcnt)
            sampno = sampno + 1 ;
            samples (sampno) = single (cmbamt / cmbno) ;
        end
    end

    %   Produce the X axis times.

    pagetimes = seqcnt .* (sample_time * sampcmb) / 1000 ;

else

    %   Set where to start the figure in the samples.

    if (pageno < 0)
        pagestart = samp_start - 1;
    else
        pagestart = (pageno - 1) * dispcnt ;
    end

    pagetimes = (seqcnt + pagestart) .* sample_time / 1000 ;

    offset    = segstart + pagestart ;

    if (samp_count - pagestart < dispcnt)
        samples = [mamps(offset : segstart + samp_end - 1),   ...
                   zeros(1, pagestart + dispcnt - samp_count, 'single')] ;
    else
        samples = mamps (offset : (offset + dispcnt - 1)) ;
    end
end

%   Plot the lines of the display.

top = double (max (samples)) * 1.1 ;

subplots = zeros (1, rows) ;

for k = 1:rows
    subplots (k) = subplot (rows,1,k) ; hold off ;

    %   Determine the range to display on the current line and
    %   display the line.

    rstart = (k - 1) * columns + 1 ;
    rend   = k * columns ;

    stem (pagetimes(k,:),samples(rstart : rend),'b.-') ;

    axis ([pagetimes(k,1) pagetimes(k,columns) 0 top]) ;

    xlabel ('Seconds') ;
    ylabel ('Milliamps') ;
    grid    minor ;
end

if (pageno < 0)
    title (subplots (1), ...
           sprintf ('Current Usage for Segment %d Seconds %.3f to %.3f', ...
                    segno, start_tm, end_tm)) ;
else
    title (subplots (1), ...
           sprintf ('Current Usage for Segment %d Page %d', ...
                     segno, pageno)) ;
end
