
function y = main  (inFile, outFile, displayFlag)
% This is the main function that (i) sets up the parameters, (ii)
% initializes the spatial pooler, and (iii) iterates through the data and
% feed it through the spatial pooler and temporal memory modules.
%
% Not all aspects of NUPIC descrived in the link below are implemented.
% http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42
%
% Parameters follow the ones specified at
%https://github.com/numenta/nupic/blob/master/src/nupic/frameworks/opf/common_models/anomaly_params_random_encoder/best_single_metric_anomaly_params_tm_cpp.json


global  SM SP anomalyScores iteration predictions

%% parameters for sequence memory
SM.N = 2048; %Number of columns N
SM.M = 32; %Number of cells per column M
SM.Nd = 128; %Maximum number of dendritic segments per cell
SM.Ns = 40; %Maximum number of synapses per dendritic segment


SM.Theta = 15; %Dendritic segment activation threshold
SM.minPositiveThreshold = 7; 
SM.P_initial = 0.21; %Initial synaptic permanence
SM.P_thresh = 0.5; %Connection threshold for synaptic permanence
SM.P_incr = 0.04; %Synaptic permanence increment
SM.P_decr = 0.008; %Synaptic permanence decrement
SM.P_decr_pred = 0.001; %Synaptic permanence decrement for predicted inactive segments

%% parameters for spatial pooler

% according to a paper "Effect of Spatial Pooler Initialization on Column Activity in
% Hierarchical Temporal Memory" (1 - connectPerm < Theta/width) of input
% representation

SP.potentialPct = 0.8; % Input percentage that are potential synapse
SP.connectPerm = 0.2; % Synapses with permanence above this are considered connected.
SP.synPermActiveInc = 0.003; % Increment permanence value for active synapse
SP.synPermInactiveDec = 0.0005; % Decrement of permanence for inactive synapse
SP.stimulusThreshold = 2; % Background noise level from the encoder. Usually set to very low value.
SP.activeSparse = 0.02; % sparsity of the representation
SP.maxBoost = 1; %10;
SP.width = 21; %21; % number of bits that are one for each state in the input.


%% Setup arrays for sequence memory
% Copy of cell states used to predict
SM.CellActive = logical(sparse(SM.M, SM.N));
SM.CellPredicted = logical(sparse(SM.M, SM.N));
SM.CellActivePrevious = logical(sparse(SM.M, SM.N)); % previous time

SM.SynapseWith = logical(sparse(SM.M, SM.N));
SM.SynapseWithPrevious = logical(sparse(SM.M, SM.N));


SM.learnFlag = sparse(SM.M, SM.N);
SM.numDendritesPerCell = sparse (SM.M, SM.N); % stores number of dendrite information per cell
SM.numSynapsesPerCell = sparse (SM.M, SM.N); % stores number of dendrite information per cell


% new data structure base on pointers between
% synapse -> dendrites -> cells and
%    |-> cells
% permanence is stored indexed by the synapses

SM.MaxDendrites = round (SP.activeSparse * SM.N * SM.M * SM.Nd);
SM.MaxSynapses = round (SP.activeSparse * SM.N * SM.M * SM.Nd * SM.Ns);
SM.totalDendrites = 0;
SM.totalSynapses = 0;

SM.SynapseToCell = sparse (SM.MaxSynapses, 1);
SM.SynapseToDendrite = sparse (SM.MaxSynapses, 1);
SM.SynapsePermanence = sparse (SM.MaxSynapses, 1);
SM.SynapseActive = sparse (SM.MaxSynapses, 1);
SM.SynapsePositive = sparse (SM.MaxSynapses, 1);


SM.DendriteToCell = sparse (SM.MaxDendrites, 1);
SM.DendritePositive = sparse (SM.MaxDendrites, 1);
SM.DendriteActive = sparse (SM.MaxDendrites, 1);


%% Setup arrays for spatial pooler

SP.boost = ones (SM.N, 1);
SP.activeDutyCycle = zeros (SM.N, 1);
SP.overlapDutyCycle = zeros (SM.N, 1);
SP.minDutyCycle = zeros (SM.N, 1);


%% Input
%[SR, order] = encoderInertial (2048, 31, 16); %Input: (N, nLevels, overlap);

%data = encoderHotGym (SP.width ) ;

data = encoderNAB (inFile, SP.width);


%% Sequence memory (SM) learning
% Initialize the spatial Pooler

iN = sum(data.nBits(data.fields)); % number of input bits
SP.connections = false (SM.N, iN);
SP.synapse = zeros (SM.N, iN);
W = round (SP.potentialPct*iN);

for i=1:SM.N
    randPermTemplate =  SP.connectPerm * rand ([1 W]) + 0.1;
    connectIndex = sort(randi (iN, 1, W)); % 1 by W sized matrix of random inputs.
    SP.synapse (i, connectIndex) = randPermTemplate;
    SP.connections (i, connectIndex) = true;
end;

%% Pre Learn Spatial Pooler
fprintf(1, '\n Learning SP');
for iteration = 1:round(0.5*data.N)
    x = [];
    for  i=1:length(data.fields);
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration),:)];
    end
    [xSM, ~] = spatialPooler (x, true, false);

    ri = (xSM* double(SP.synapse > SP.connectPerm)) > 1;
    rError = nnz(x(1:data.nBits(1))) - nnz(ri(1:data.nBits(1)) & x(1:data.nBits(1)));
    if (rError ~= 0) fprintf(1, '%4.3f ', rError); end;

end;

    
%% Setup arrays 
predictions = zeros(2, data.N); % initialize array allocaton -- faster on matlab
MaxDataValue = max(data.value{1});
SM.InputPrevious = zeros(SM.N, 1);

if displayFlag
    h1 = gcf; 
    figure; h2 = gcf;
    figure(h1);
end;
fprintf('\n Computing sequence memory. Data length = %d ', data.N);
for iteration = 1:data.N
    
    %% Run Spatial pooler
    x = [];
    for  i=1:length(data.fields);
        j = data.fields(i);
        x = [x data.code{j}(data.value{j}(iteration),:)];
    end
    %% Run through Spatial Pooler(without learning)
    SP.boost = ones (SM.N, 1);
    [SM.Input, ~] = spatialPooler (x, false, displayFlag);
   
    %% Anomaly detection score
    pi = logical(sum(SM.CellPredicted));

    anomalyScores (iteration) = 1 - nnz(pi & SM.Input)/nnz(SM.Input);
    
    %% 
    
    compute_active_cells (SM.Input); % based on x and PI_1 (prediction from past cycle)
    

      %% Learn
      
    %if (iteration > 1)
        reinforce_synapse (SM.Input);
    %end;
    grow_dendrite ();

    %%% DISPLAY 
   
    if (rem (iteration, 100) == 0)
        fprintf(1, '\n %3.2f (%d d, %d, %d) As: %4.3f Nu: %4.3f L: %d', ...
            iteration/data.N, data.value{1}(iteration), SM.totalDendrites, SM.totalSynapses, ...
            anomalyScores(iteration),...
            data.numentaAnomalyScore(iteration),...
            data.labels(iteration));
    end;
    if (displayFlag)
        fprintf(1, '\n %d (%d %d d, %d, %d) As: %4.3f Nu: %4.3f L: %d', ...
            iteration, data.value{1}(iteration), data.value{data.fields(2)}(iteration), ...
            SM.totalDendrites, SM.totalSynapses, ...
            anomalyScores(iteration),...
            data.numentaAnomalyScore(iteration),...
            data.labels(iteration));
        %figure(h2); displayCellAnimation; pause (0.0001); figure(h1);
        visualizeHTM (iteration, SM.Input, data); pause (0.0001);
    end;
    %% Predict next state
    SM.CellActivePrevious = SM.CellActive;
    compute_predictive_states;
   
         %%   
    
    %%
    SM.InputPrevious = SM.Input;
    SM.SynapseWithPrevious = SM.SynapseWith;
    
end;
pause (0.0000000000001);


save (sprintf('Output/HTM_SM_%s.mat', outFile), ...
    'SM', 'SP', 'data', 'anomalyScores', 'predictions',...
    '-v7.3');




