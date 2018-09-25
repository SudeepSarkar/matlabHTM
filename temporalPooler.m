function unionSDR = temporalPooler (learnP, displayFlag)
% This function implements the 2015 version of the temporal pooler concept
% as outlined at 
%
% https://github.com/numenta/nupic.research/wiki/Overview-of-the-Temporal-Pooler
%
% and using implementations at
% https://github.com/numenta/nupic.research/wiki/Union-Pooler-Psuedocode ,
% https://github.com/numenta/nupic.research/blob/master/htmresearch/algorithms/union_temporal_pooler.py
% and
% https://github.com/numenta/nupic.research/blob/master/htmresearch/frameworks/union_temporal_pooling/union_temporal_pooler_experiment.py
%
% The first component of the temporal pooler implements a modified spatial pooler. It receives 
% two inputs from the preceding sequence memory (SM) layer: 1) the set of cells in the SM that are 
% active (SM.cellActive), and 2) the subset of those active cells that were predicted previously 
% (SM.predictedActive). 

  
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  SM TP

 
%% Connect new proximal dendrites and associated synapses in the TP to the 
% active cells in the SM. Add new dendrite connections as necessary to cover 
% the current active cells. The outputs are the dendrite outputs and the
% inputs are the active, a subset of which are correctly predicted active,
% cells in the sequence memory (SM). We add dendrites as necessary to cover
% the active cells.
% 
% There is ONE proximal dendrite per column
%
% SM.cellActive (sparse array) has all the active cells
% SM.predictedActive (sparse array) has the predicted active cells


currentOut = find(TP.dendrites);
activeInput = find(SM.cellActive); % can also be SM.cellActive
[~, ~, cellID] = find(TP.synapseToCell); 
% SM cell (linear) indices, aligned with synapse indices in TP

% SM cells not currently covered by synapses
newIn = setdiff (activeInput, cellID);

if (newIn)
    
    % fractions of active cells that are a new and not covered
    newFraction = length(newIn)/length(activeInput);  
    % the number of new outputs, i.e. dendrites that we need
    nOut = round (newFraction*TP.activeSparse*TP.N);

    if (newFraction < 0.5)
        % expand existing dendrites if the fraction of new cells is low.
        newOut = randi(length(currentOut), 1, nOut);
        newOut = currentOut (newOut);
    else
        availableDendrites = find(TP.dendrites == 0);
        newOut = randi(length(availableDendrites), 1, nOut); % randomly pick a fraction of the available output columns
        newOut = availableDendrites(newOut);
        TP.dendrites (newOut)  = 1;
    end
    
    % create newOut dendrities linked to newIn cells
    if (newIn)
        if (newOut)
            addTPDendrites (newIn, newOut)
        end
    end
       
end

%% Compute current active cells based on current input  

% Compute proximal dendrite overlaps with active and active-predicted inputs
% Column activations are determined via the connections of the proximal dendrites 
% as per the standard SP algorithm, but with one exception: the inputs to each 
% column are a weighted average of the active inputs and the predicted active inputs. 


[synapse, ~, cellID] = find(TP.synapseToCell);

x = SM.cellActive(cellID) > 0;

% x is a vector of (linear) indices of active cells - note cellID contains 
% the indices of the cells corresponding to  each of the synapses -- so a particular 
% cell index will appear multiple times. 
% Thus, size of x is NOT the equal to the number of active cells, 
% but is equal to the number of synapses connected to active cells.
synapseInput = synapse(x); % synapses connected to active cells
aboveThresh = find(TP.synapsePermanence > TP.connectPerm);
activeSynapses = intersect(synapseInput, aboveThresh); 

overlapActive = zeros (TP.N, 1);
d = TP.synapseToDendrite(activeSynapses); % dendrites with active synapses
ud = nonzeros(unique(d));
y = histc (nonzeros(d), ud);
overlapActive (ud) = y; % number of active synapses for each dendrite


x = SM.predictedActive(cellID) > 0;
synapseInputPredicted = synapse(x);
predictedActiveSynapses = intersect(synapseInputPredicted, aboveThresh);

overlapPredictedActive = zeros (TP.N, 1);
d = TP.synapseToDendrite(predictedActiveSynapses);
ud = nonzeros(unique(d));
y = histc (nonzeros(d), ud);
overlapPredictedActive (ud) = y;

totalOverlap = overlapActive * TP.weightActive + overlapPredictedActive * TP.weightPredictedActive;

% Here totalOverlap is the input to the standard SP. The output of the SP is the
% set of columns with the strongest inputs determined via the standard SP
% winner-take-all competition. This allows us to give cells that were successfully
% predicted a larger impact on the output of the TP. The motivation for doing this
% is that after learning, states that are predicted by the SM are temporal instances
% that belong to the same semantic category as the preceding states, and therefore
% should form a part of the stable semantic representation produced by the TP.

if (learnP) 
    boostedOverlaps = totalOverlap.*TP.boost; 
else 
    boostedOverlaps = totalOverlap;
end

[~,I] = sort (boostedOverlaps, 'descend');
activeDendrites = (boostedOverlaps > TP.stimulusThreshold);
activeDendrites (I (round (TP.activeSparse*TP.N) : TP.N)) = 0;

if (displayFlag)
    subplot(10,1,1); 
    plot(sum(SM.cellActive)>0, 'b.'); hold on; 
    plot(sum(SM.predictedActive)>0, 'r'); hold off;
    title ('active cells (red), predicted active cells (blue)');
    
    subplot(10,1,2); 
    plot(overlapActive, 'b.'); hold on;
    plot (overlapPredictedActive, 'r'); 
    hold off;
    title ('overlapPredictedActive (red) overlapActive (blue)');
    
    subplot(10,1,3); plot(activeDendrites, 'b.'); hold on;
    title ('active dendrites (blue) union SDR (red)'); 
end

activeDendrites = find(activeDendrites);

%% Union Pooling Process

TP.poolingActivation = TP.poolingActivationInitLevel .* exp(-0.7*TP.poolingTimer/TP.halfLifePersistence);

% Adds overlaps from specified active cells to cells' pooling activation using logistic.

TP.poolingActivation (activeDendrites) = TP.poolingActivation (activeDendrites) + ...
    TP.baseLinePersistence + ...
    TP.extraPersistence./(1 + exp(-(overlapPredictedActive (activeDendrites) - TP.stimulusThreshold)));

% increase pooling timers for all cells with non-zero timer value.
TP.poolingTimer = TP.poolingTimer + (TP.poolingTimer > 0);

% reset pooling timer for active cells

TP.poolingTimer (activeDendrites) = 0;
TP.poolingActivationInitLevel (activeDendrites) = TP.poolingActivation (activeDendrites);

if (displayFlag)
    subplot(10,1,4); plot(TP.synapsePermanence(1:TP.nSynapses), 'b'); hold on;
    plot(TP.dendrites, 'r'); hold off;
    
    title ('synapses (blue) and dendrites (red)');
    
    subplot(10,1,5); plot(TP.poolingActivation, 'r'); hold on; 
    %plot(TP.poolingTimer, 'b'); 
    %plot(TP.poolingActivationInitLevel, 'g'); 
    hold off;
    title ('Pooling Activation (red)  poolingTimer (blue) poolingActivationInit (green)');
    
  
end

%% Sparsification

% The output SDR of the TP is determined via a winner-take-all competition
% based on the persistence values of the bits in the UP. The output of the TP
% at a given time step is the set of bits with the top X% persistence in that
% time step. Here X is a configurable parameter that defaults to 20%.
% inhibit responses -- pick the top k columns

% Compute the current most salient cells in terms of poolingActivation.
% Cells with zero poolingActivation cannot win.

[~,I] = sort (TP.poolingActivation, 'descend');
TP.unionSDR = TP.poolingActivation > 0.1;
TP.unionSDR (I (round (TP.maxUnionActivity*TP.N) : TP.N)) = 0;

unionSDR = find(TP.unionSDR); 
% list of active columns (dendrite ids), rather than a logical array aligned 
% with the columns

if (displayFlag)
    subplot(10,1,3); plot(TP.unionSDR, 'r'); hold off;
end


if (learnP)
    
    %% Perform standard Spatial Pooler learning 
    
    [synapse, ~, dendrite] = find(TP.synapseToDendrite);
    
    % synapses connected to dendrites that are active
    synapseWithOutput = synapse (ismember (dendrite, activeDendrites));
    
    % list of active synapses. i.e. with high permances and connected to active
    % cells and also connect to active dendrites
    activeSynapseWithOutput = intersect (synapseWithOutput, synapseInput);
    
    %logical array aligned with active synapses with active outputs
    activeSynapseWithOutput = ismember (synapse, activeSynapseWithOutput); 
    
    TP.synapsePermanence (activeSynapseWithOutput) = min(1.0, TP.synapsePermanence (activeSynapseWithOutput) + ...
        TP.synPermActiveInc);
   
    synapseWithOutputLogical = ismember (synapse, synapseWithOutput);
    synapseInputLogical = ismember (synapse, synapseInput);

    inactiveSynapses = synapseWithOutputLogical & (~synapseInputLogical);
    
    TP.synapsePermanence (inactiveSynapses) = max(0, TP.synapsePermanence (inactiveSynapses) - ...
        TP.synPermInactiveDec);
    
    
    %% Forward Learning
    %  # Forward learning rule
    %       if outputSDRActive(t, c) and synapseActivePredicted(t, s):
    %         increasePermanence(s)
    
    % synapses connected to dendrites that are active in the unionSDR
    synapseWithOutput = synapse (ismember (dendrite, unionSDR));
    
    activeSynapseWithOutput = intersect (synapseWithOutput, synapseInputPredicted);
    
     TP.synapsePermanence (activeSynapseWithOutput) = min(1.0, TP.synapsePermanence (activeSynapseWithOutput) + ...
        TP.synPermActiveInc);
        
    %% Backward Learning
    %       # Backward learning rule
    %       for t' in [t-n, t-n+1, ... t-1]:
    %         if outputSDRActive(t, c) and synapseActivePredicted(t', s):
    %           increasePermanence(s)
    
    TP.activeSynapses (:, TP.historyIndex) = false;
    TP.activeSynapses (synapseInputPredicted, TP.historyIndex) = true;
    TP.historyIndex = mod(TP.historyIndex, TP.historyLength) + 1;
    
    [activeHistorySynapses, ~] = find(TP.activeSynapses);
    activeHistorySynapseWithOutput = intersect (synapseWithOutput, activeHistorySynapses);
    
    TP.synapsePermanence (activeHistorySynapseWithOutput) = min(1.0, TP.synapsePermanence (activeHistorySynapseWithOutput) + ...
        TP.synPermActiveInc);
     
     %% boosting
%     TP.overlapDutyCycle = 0.9 * TP.overlapDutyCycle + 0.1 * (totalOverlap > TP.stimulusThreshold); % vector
%     
%     TP.minDutyCycle = 0.01 * max (TP.activeDutyCycle);
%     
%     TP.activeDutyCycle = 0.9 * TP.activeDutyCycle;
%     TP.activeDutyCycle(activeDendrites) = 0.1; % need to change into running average later
%     
%     TP.boost = min (TP.maxBoost, max (1.0, TP.minDutyCycle./TP.activeDutyCycle));
%     
%         inDuty = find (TP.overlapDutyCycle < TP.minDutyCycle);
%     
%     
%         [synapse, ~, cellID] = find(TP.synapseToCell);
%     
%         inputCells = cellID(ismember (synapse, predictedActiveSynapses));
%         inputCells = unique(inputCells);
%     
%         if ((isempty(inDuty) == 0) && (isempty(inputCells) == 0))
%             inDuty = inDuty(randi(length(inDuty), 1, ...
%                 min(round (TP.activeSparse*TP.N), length(inDuty))));
%     
%             selectCells = inputCells (randi(length(inputCells), 1, ...
%                 min(round (TP.activeSparse*TP.N), length(inputCells))));
%             % select new inDuty number of outputs with sparsity of TP.activeSparse
%     
%             fprintf(1, '\n -> adding %d output to %d synapses due to boosting', length(inDuty), length(activeSynapses));
%             addTPDendrites (selectCells, inDuty)
%         end
%     
%     if (displayFlag)
%         
%         subplot(10,1,6);
%         plot(TP.activeDutyCycle, 'r.'); hold on;
%         plot(TP.overlapDutyCycle, 'b'); hold off;
%         title ('activeDutyCycle (red), overlapDutyCycle (blue)');
%         
%     end;
end


%%%

function addTPDendrites (newIn, newOut)
% This function is just used for temporal pooling and is used to add new
% dendrites, as identifed in newOut, connected to synapses speficied in
% newIn. A fraction (TP.potentialPct) of  the synapses are randomly selected 
% to connect to each dendrite.

global TP;
nIn = length(newIn);
nOut = length(newOut);
fprintf(1, '\n %d new synapses adding %d output', nIn, nOut);

nNewSynapses = nIn; %round(TP.potentialPct*nIn); 
% each dendrite connect to fraction of the new inputs

nConnections = nNewSynapses * nOut; 
% total of synapses for all the dendrits

newConnection = newIn(randi (nIn, 1, nConnections));
% indices of the new synapses, randomly chosen for ALL the dendrites.

newOut = newOut(randi (nOut, 1, nConnections));
% indices of the output dendrites, aligned with the synapses in the
% newConnection array

TP.synapseToCell (TP.nSynapses+1: TP.nSynapses+nConnections) = newConnection;
TP.synapsePermanence (TP.nSynapses+1: TP.nSynapses+nConnections) = TP.initialConnectPerm;
TP.synapseToDendrite (TP.nSynapses+1: TP.nSynapses+nConnections) = newOut;
TP.nSynapses = TP.nSynapses+nConnections;




