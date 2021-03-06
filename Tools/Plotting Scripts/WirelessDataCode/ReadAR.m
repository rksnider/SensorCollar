%% Import data from text file.
% Script for importing data from the following text file:
%
%    C:\Users\tyler.davis5\Dropbox\SummerWork2015\WirelessData\20150626_FullAntennaWalkSecondWalk
%
% To extend the code to different selected data or a different text file,
% generate a function instead of a script.

% Auto-generated by MATLAB on 2015/06/25 15:55:41

%% Initialize variables.
filename = 'C:\Users\tyler.davis5\Dropbox\SummerWork2015\WirelessData\20150626_FullAntennaWalkSecondWalk';

%% Format string for each line of text:
%   column1: date strings (%s)
%	column34: text (%s)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%12s%2*s%5*s%2*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%3*s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Convert the contents of column with dates to serial date numbers using date format string (datenum).
dataArray{1} = datenum(dataArray{1}, 'HH:MM:SS');

%% Allocate imported array to column variable names
ARTime = dataArray{:, 1};
ARdBmCells = dataArray{:, 2};

%% Clear temporary variables
clearvars filename formatSpec fileID dataArray ans;