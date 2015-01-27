function [mamps, stimes, segs, sdata] = current_samples (sample_file, ma_scale)
%CURRENT_SAMPLES    Read current samples from a file and return them.
% usage [mamps, stimes, segs, sdata] = current_samples (sample_file, ma_scale)
%             mamps = Vector of milliamp samples taken.
%            stimes = Vector of milliseconds the samples taken at.
%              segs = Vector of the start of different sample segments taken.
%             sdata = Vector of data input taken at same time as samples.
%       sample_file = Name of the file to read 16 bit signed samples from.
%          ma_scale = Milliamps per sample tick.

%   Open the sample file.

sfile = fopen (sample_file, 'r') ;

mamps  = [] ;
stimes = [] ;
segs   = [] ;
sdata  = [] ;

if (sfile < 0)
    sprintf ('Unable to open sample file "%s"\n', sample_file)
    return
end

%   Process the lines in the sample file throwing out the first ones.

milli   = uint32 (0) ;
lasttm  = uint32 (0) ;

while (feof (sfile) ~= 1)

    sline = fgets (sfile) ;

    if (sline (1) == '>')
        break ;
    end
end

%   Process all data lines in the file.

while (feof (sfile) ~= 1)

    if (length (sline) > 0)

        %   Start a new set of samples.

        if (sline (1) == '>')

            %   Get the new time and throw out the sub-millisecond part.

            tms = sscanf (sline, '> %8x%4x%2x') ;

            milli = uint32 ((tms (1) * 65536 + tms (2)) / 1000) ;

            %   Get the data input associated with the samples.

            datain = uint8 (tms (3)) ;

            %   Log new measurement segment starts.

            if (length (segs) == 0 || milli - lasttm > 1000)
                segs = [segs, uint32(length (stimes) + 1)] ;
            end

            lasttm = milli ;
        else

            %   Read a new set of samples and convert them to milliamps.

            sampset   = sscanf (sline, '%4x')' ;
            sampneg   = sampset > 32767 ;
            sampminus = (sampset - 65536) .* sampneg ;
            sampplus  = sampset .* (~ sampneg) ;
            samples   = single ((sampminus + sampplus) * ma_scale) ;

            times     = milli  * ones (1, length (samples), 'uint32') ;
            data      = datain * ones (1, length (samples), 'uint8') ;
            mamps     = [mamps,  samples] ;
            stimes    = [stimes, times] ;
            sdata     = [sdata,  data] ;
        end
    end

    %   Get the next line from the file.

    sline = fgetl (sfile) ;

end

fclose (sfile) ;
