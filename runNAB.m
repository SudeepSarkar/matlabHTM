function runNAB (startFile, endFile, displayFlag, createModelFlag)
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

%% Sequences in parallel now
for i=startFile:endFile
    
    fid = fopen('fileList.txt', 'r');
    file_name = textscan(fid,'%*n %s',1,'delimiter','\n', 'headerlines',i-1);
    file_name = cell2mat(file_name{1});
    fclose (fid);

    close all;
    clear global;

    [~, name, ~] = fileparts(file_name);

    timing_starts = tic;
    %% Create Model
    if createModelFlag
        main  (file_name, name, displayFlag, true, 'none');
    end

    %% Time to process
    matlabHTM_timing_dataset = toc(timing_starts);
    fprintf ('\nProcessing Time is: %s\n',matlabHTM_timing_dataset);
    save (sprintf('Output/time_HTM_%s.mat',name),'matlabHTM_timing_dataset','-append');
    fprintf ('\n%d:iteration_finished_properly,%d\n',i);
end
exit