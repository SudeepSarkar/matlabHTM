function initialize ()

% This is the function that (i) sets up the parameters and (ii) initializes
% the data structures for the spatial pooler and sequence memory
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

global  SM SP TP data

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
    
        
  
    %% parameters for sequence memory
    SM.N = 2048; %Number of columns N
    SM.M = 32; %Number of cells per column M
    SM.Nd = 128; %Maximum number of dendritic segments per cell
    SM.Ns = 128; %Maximum number of synapses per dendritic segment
    SM.Nss = 30; %Maximum number of synapses per dendritic segment

    SM.Theta = 20; %Dendritic segment activation threshold
    SM.minPositiveThreshold = 10;
    SM.P_initial = 0.24; %Initial synaptic permanence
    SM.P_thresh = 0.5; %Connection threshold for synaptic permanence
    SM.P_incr = 0.04; %Synaptic permanence increment
    SM.P_decr = 0.008; %Synaptic permanence decrement
    SM.P_decr_pred = 0.001; %0.001; %Synaptic permanence decrement for predicted inactive segments
    
    %% parameters for temporal pooler
    
    TP.potentialPct = 0.5; % Input percentage that are potential synapse
    TP.connectPerm = 0.1; % Synapses with permanence above this are considered connected.
    TP.initialConnectPerm = 0.101; % Synapses with permanence above this are considered connected.
    TP.synPermActiveInc = 0.1; % Increment permanence value for active synapse
    TP.synPermInactiveDec = 0.01; % Decrement of permanence for inactive synapse
    TP.stimulusThreshold = 3; % Background noise level from the encoder. Usually set to very low value.
    TP.activeSparse = 0.02; % sparsity of the representation
    TP.maxBoost = 2; %10;
    
    TP.weightActive = 1.0;
    TP.weightPredictedActive = 10.0;
    TP.historyLength = 10;
    TP.maxUnionActivity = 0.02;
    TP.baseLinePersistence = 0;
    TP.extraPersistence = 1;
    TP.halfLifePersistence = 20;
    %% Setup arrays for spatial pooler
    
    SP.boost = ones (SM.N, 1);
    SP.activeDutyCycle = zeros (SM.N, 1);
    SP.overlapDutyCycle = zeros (SM.N, 1);
    SP.minDutyCycle = zeros (SM.N, 1);
    
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
    
    %% Setup arrays for sequence memory
    % Copy of cell states used to predict
    SM.cellActive = logical(sparse(SM.M, SM.N));
    SM.predictedActive = logical(sparse(SM.M, SM.N));
    SM.cellActivePrevious = logical(sparse(SM.M, SM.N)); % previous time

    SM.cellPredicted = logical(sparse(SM.M, SM.N));
    SM.cellPredictedPrevious = logical(sparse(SM.M, SM.N));

    SM.cellLearn = logical(sparse(SM.M, SM.N));
    SM.cellLearnPrevious = logical(sparse(SM.M, SM.N));
    
    % new data structure base on pointers between
    % synapse -> dendrites -> cells and
    %    |-> cells
    % permanence is stored indexed by the synapses
    
    SM.maxDendrites = round (SP.activeSparse * SM.N * SM.M * SM.Nd);
    SM.maxSynapses = round (SP.activeSparse * SM.N * SM.M * SM.Nd * SM.Ns);
    SM.totalDendrites = 0;
    SM.totalSynapses = 0;
    SM.newDendriteID = 1;
    SM.newSynapseID = 1;

    SM.numDendritesPerCell = sparse (SM.M, SM.N); % stores number of dendrite information per cell
    SM.numSynapsesPerCell = sparse (SM.M, SM.N); % stores number of dendrite information per cell
    SM.numSynpasesPerDendrite = sparse (SM.maxDendrites, 1);

    SM.synapseToCell = sparse (SM.maxSynapses, 1);
    SM.synapseToDendrite = sparse (SM.maxSynapses, 1);
    SM.synapsePermanence = sparse (SM.maxSynapses, 1);
    SM.synapseActive = []; %sparse (SM.maxSynapses, 1);
    SM.synapsePositive = []; %sparse (SM.maxSynapses, 1);
    SM.synapseLearn = []; %sparse (SM.maxSynapses, 1);
    
    SM.dendriteToCell = sparse (SM.maxDendrites, 1);
    SM.dendritePositive = sparse (SM.maxDendrites, 1);
    SM.dendriteActive = sparse (SM.maxDendrites, 1);
    SM.dendriteLearn = sparse (SM.maxDendrites, 1);
    

   
     %% Setup arrays for Temporal pooler
    
    TP.N = SM.N;
    TP.iN = SM.M * SM.N; % number of input bits
    
    TP.boost = ones (TP.N, 1);
    TP.activeDutyCycle = zeros (TP.N, 1);
    TP.overlapDutyCycle = zeros (TP.N, 1);
    TP.minDutyCycle = zeros (TP.N, 1);
    TP.poolingActivation = zeros (TP.N, 1);
    TP.poolingTimer = ones(TP.N, 1)*1000;
    TP.poolingActivationInitLevel = zeros (TP.N, 1);
    
    TP.dendrites = zeros (TP.N, 1);
    TP.nDendrites = 0;
    TP.nSynapses = 0;
    TP.synapseToCell = sparse (TP.iN, 1);
    TP.synapsePermanence = sparse (TP.iN, 1);
    TP.synapseToDendrite = sparse (TP.iN, 1);
    
    %TP.synapse = sparse (TP.N, TP.iN);
    TP.activeSynapses = logical(sparse (TP.iN, TP.historyLength));
    TP.historyIndex = 1;
    TP.unionSDR = zeros(TP.N, 1);
    TP.unionSDRhistory  = zeros (5000, TP.N);
