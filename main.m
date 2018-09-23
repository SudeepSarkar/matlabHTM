function y = main  (inFile, outFile, displayFlag, learnFlag, learntDataFile)
% This is the main function that (i) sets up the parameters, (ii)
% initializes the spatial pooler, and (iii) iterates through the data and
% feed it through the spatial pooler and temporal memory modules.
%
% We follow the implementation that is sketched out at
%http://numenta.com/assets/pdf/biological-and-machine-intelligence/0.4/BaMI-Temporal-Memory.pdf
%
% Not all aspects of NUPIC descrived in the link below are implemented.
% http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42
%
% Parameters follow the ones specified at
%https://github.com/numenta/nupic/blob/master/src/nupic/frameworks/opf/common_models/anomaly_params_random_encoder/best_single_metric_anomaly_params_tm_cpp.json
%
%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
% on https://github.com/SudeepSarkar/matlabHTM

global  SP SM TP data anomalyScores iteration predictions


if learnFlag
  %% Encode Input into Binary Semantic Representation
    %data = encoderInertial (inFile, SP.width);

   SP.width = 21; %21; % number of bits that are one for each state in the input.
   data = encoderNAB (inFile, SP.width);
    
   %% initialize parameters and data structures for spatial pooler (SP), 
   % sequence memory (SM), and temporal pooler (TP). 
   initialize;
    
    %% Learning mode for Spatial Pooler
    fprintf(1, '\n Learning sparse distributed representations using spatial pooling...');
    trN = min (750, round(0.15*data.N));
    for iteration = 1:trN
        x = [];
        for  i=1:length(data.fields);
            j = data.fields(i);
            x = [x data.code{j}(data.value{j}(iteration),:)];
        end
         xSM = spatialPooler (x, true, false);
        
        ri = (xSM* double(SP.synapse > SP.connectPerm)) > 1;
        rError = nnz(x(1:data.nBits(1))) - nnz(ri(1:data.nBits(1)) & x(1:data.nBits(1)));
        if (rError ~= 0) fprintf(1, '%4.3f ', rError); end;
    
    end; 
    fprintf(1, 'done.');
else
    %% already learnt spatial pooler and sequence memory is present in learntDataFile
    load (learntDataFile);
    data = encoderNAB (inFile, SP.width);

end;  
  

hold off;

%% Setup arrays
predictions = zeros(2, data.N); % initialize array allocaton -- faster on matlab
MaxDataValue = max(data.value{1});
SM.inputPrevious = zeros(SM.N, 1);
data.inputCodes = [];
data.outputCodes = [];

if displayFlag
    h1 = gcf;
    figure; h2 = gcf;
    figure(h1);
end;
fprintf('\n Running input of length %d through sequence memory to detect anomaly...', data.N);

%% Interate
for iteration = 1:data.N
    
    %% Run through Spatial Pooler(without learning)
    x = [];
    for  i=1:length(data.fields);
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration),:)];
    end
    data.inputCodes = [data.inputCodes; x];
    SP.boost = ones (SM.N, 1);
    SM.input = spatialPooler (x, false, displayFlag);
    data.outputCodes = [data.outputCodes; SM.input];
    
    
    %% Anomaly detection score
    % Two option -- (i) based on reconstructed signal or (ii) based on predicted SM
    % signal. Option (i) assumes that we have a good SP that is invertible.
    % It did not result in good performance
    
    pi = logical(sum(SM.cellPredicted));
    
    %     %option (i)
    %         ri = (pi* double(SP.synapse > SP.connectPerm)) > 1;
    %         anomalyScores (iteration) = 1 - nnz(ri(1:data.nBits(1)) & x(1:data.nBits(1)))/...
    %             nnz(x(1:data.nBits(1)));
    %     %
    %option (ii)
    anomalyScores (iteration) = 1 - nnz(pi & SM.input)/nnz(SM.input);
    
    %% Decode prediction from previous state and compare to current input.
    
    if (displayFlag)
        [pState, conf] = decodePrediction (pi);
        
        if (pState)
            predictions(1, iteration) = min(pState);
            predictions(2, iteration) = max(pState);
            predictions(3, iteration) = round(sum(pState.*conf)/sum(conf));
        else predictions([1 2 3], iteration) = 1;
        end;
    end;
    
    %%
    %anomalyScores (iteration) = compute_active_cells (SM.input); % based on x and PI_1 (prediction from past cycle)
    markActiveStates (); % based on x and PI_1 (prediction from past cycle)
    
    %% Learn
    
    if learnFlag
       markLearnStates ();
       updateSynapses ();
       
    end;
    
    %% Temporal Pooling -- remove comments below to invoke temporal pooling.
%     if (iteration > 150)
%         temporalPooler (true, displayFlag);
%         TP.unionSDRhistory (mod(iteration-1, size(TP.unionSDRhistory, 1))+1, :) =  TP.unionSDR;
%         
%     end;
    %% DISPLAY
    
    if (rem (iteration, 100) == 0)
        fprintf(1, '\n Fraction done: %3.2f, SM.totalDendrites: %d, SM.totalSynapses: %d', ...
            iteration/data.N, SM.totalDendrites, SM.totalSynapses);
        %imagesc(TP.unionSDRhistory); pause (0.00001);

    end;
    if (displayFlag)
        fprintf(1, '\n Fraction done: %3.2f Input:%d SM.totalDendrites: %d, SM.totalSynapses: %d, anomalyScore= %4.3f', ...
            iteration/data.N, data.value{1}(iteration), SM.totalDendrites, SM.totalSynapses, ...
            anomalyScores(iteration));
        if (iteration > 2)
%             figure(h2);
%             displayCellAnimation;
%             figure(h1);
            visualizeHTM (iteration, SM.input, data); pause (0.0001);
        end;
    end;
    
    %% Predict next state
    SM.cellPredictedPrevious = SM.cellPredicted;
    
    markPredictiveStates ();
    
    %%
    
    %%
    %sum(ismember(find(SM.cellLearn), find(SM.cellActive)))

    SM.cellActivePrevious = SM.cellActive;
    SM.inputPrevious = SM.input;
    SM.cellLearnPrevious = SM.cellLearn;
    
    
end;
fprintf('\n Running input of length %d through sequence memory to detect anomaly...done', data.N);

%visualizeHTM (iteration, SM.input, data);
% imagesc(TP.unionSDRhistory); pause (0.00001);
% pause (0.0000000000001);

if learnFlag
    save (sprintf('Output/HTM_SM_%s.mat', outFile), ...
        'SM', 'SP', 'data', 'anomalyScores', 'predictions',...
        '-v7.3');
else
    save (sprintf('Output/HTM_SM_%s_L.mat', outFile), ...
        'SM', 'SP', 'data', 'anomalyScores', 'predictions',...
        '-v7.3');
end;





