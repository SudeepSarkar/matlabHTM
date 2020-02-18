startFile = 74;
endFile = 77;
displayFlag = false;
createModelFlag = true;
time = datetime;
% This function through the entore NAB dataset
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
close all;
if displayFlag
    figure; h1 = gcf; 
end

%% Sequences are being done in parallel now
for i=startFile:endFile
    
    fid = fopen('fileList.txt', 'r');
%    i = 1;
%     while ~feof(fid)
%    fscanf(fid, '%d ', i); % skip the line count in the first column
    file_name = textscan(fid,'%*n %s',1,'delimiter','\n', 'headerlines',i-1);
    file_name = cell2mat(file_name{1});
%    i = i+1;
%     end
    fclose (fid);
    % fprintf(1, '\n %d files to process in total', i);
    close all;
    clear global;

    time_per_dataset = datetime;
    [~, name, ~] = fileparts(file_name);

    %% Create Model
    if createModelFlag
        main  (file_name, name, displayFlag, true, 'none');
    end

    %% Read saved run data --
    % see data field record structure in main.m and other variables stored in the mat file

    %% Moved to bootsraping
    matlabHTM_timing_dataset = diff([time_per_dataset datetime]);
    fprintf ('\nProcessing Time is: %s\n',matlabHTM_timing_dataset);
    save (sprintf('Output/time_HTM_%s.mat',name),'matlabHTM_timing_dataset','-append');

end