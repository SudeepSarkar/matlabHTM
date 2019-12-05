function data = encoderNAB_synthetic (filename, width)
% Encodes the data in the input csv file provided in the Numenta Anomaly
% Database, in the file -- filename, in terms of binary semantic
% representations. 
% 
% width: number of bits of overlap between semantically consecutive
% representation, i.e. between say the numbers 3 and 4.
%
% Output: data with following fields
% data.name -- list of field names - subset of 'data_value', 'month', 'day_of_week','time_of_day', 'weeeknd'
% data.fields -- array of values identifying the fields in the
%                representation 1-'data_value', 2-'month', 3-'day_of_week',
%                4-'time_of_day', 5-'weeeknd' 
% data.buckets -- number of possible values (alphabets) for each of the fields
% data.value -- quantized values of the input sequence in terms of the buckets
% data.code -- binary code for the quantized values. 
% data.width -- number of bits of overlap between semantically consecutive
%               values
% data.circularP -- indicates if the field is circular, like time of the day 
% data.shift -- shifts between consecutive values of a feild, i.e. between
%               representation of numbers 2 and 3, for example.
% data.N -- number of data elements
% data.nBits -- number of bits representing each field. 
%
% data.numentaAnomalyScore 
% data.numentaRawAnomalyScore 

% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
fieldNames = {'data_value', 'month', 'day_of_week','time_of_day', 'weeeknd'};
%data.fields = [1, 4, 5];
%data.fields = [1];
data.fields = 1; %[1, 4];

data.buckets = 120; %[120, 12, 7, 24, 2];
data.width = [width, width, width, width, width];

data.circularP = [false]; %[false, true, true, true, true];
data.shift = [1 1 1 1 width];

%% Read data
readData = importdata (filename);

%data.N = 100;
data.N = length(readData)-1;

%dateTime = readData.textdata (2:data.N+1, 1);

%rawData = datevec(dateTime); %[y, month, d, timeOfDay, m, s]e
%rawData(:,3) = weekday(dateTime);
%rawData(:,5) = ((rawData(:,3) == 1) + (rawData(:,3) == 7)) + 1.0; %weekend 
% energy, month, day of the week, time of day, weekend, seconds (not used)
%rawData (:, 4) = rawData (:, 4); 
rawData (:, 1) = readData (2:length(readData),1);

%% Need to check data in numenta for comparison
%data.labels = readData.data(:,4);
%data.numentaAnomalyScore = readData.data(:,2);
%data.numentaRawAnomalyScore = readData.data(:,3);
    
%% Decide on bits of representation 

data.nBits = data.shift.*data.buckets;
data.nBits (5) = 2* data.width(5); % month is a two level category data

data.nBits(1) = data.shift(1)*data.buckets(1) + data.width(1) - 1;

%% assign selected data as specified in the variable data.fields to the output

%fprintf(1, '\n Bits of rep:');
%for  i=1:length(data.fields)
%1 = data.fields(i);
data.name{1} = fieldNames(1);

%quantize data
dataRange = (max(rawData(:, 1)) - min (rawData(:, 1)));
if (dataRange)
    data.value{1} = floor((data.buckets(1) - 1)* (rawData(:, 1) - min (rawData(:, 1)))./...
    dataRange +1);
else
    data.value{1} = ones(size(rawData(:, 1)));
end

data.code{1} = encoderScalar (data.nBits(1), data.buckets(1), data.width(1), data.shift (1));
%fprintf(1, '%d ', data.nBits(1));
%end


function [SDR] = encoderScalar (n, buckets, width, shift)
% used for 

SDR = [];
sdr = [ones(1, width) zeros(1, n - width)]';
for i = 1:buckets
    SDR = [SDR sdr];
    sdr = circshift(sdr, [shift 0]);
end

SDR = SDR';