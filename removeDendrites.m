function y = removeDendrites ()
% This function purges old dendrites that have not been active for a while.
% It looks for dendrites with less than SM.Thresh synapses that are above
% SM.P_thresh -- the permanence threshold.

%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global SM


%% Find the indices of the synapses that have permanence below threshold, SM.P_thresh

% SynapseToDendrite is an array that stores the dendrite id for each synapse
% synapse -- array of synapse ids.
% dendrites -- id of corresponding dendrites
[synapse, ~, dendrites] = find(SM.synapseToDendrite); %aligned to synapses

% synapses that are above threshold permanence
aboveThresh = find(SM.synapsePermanence > SM.P_thresh);

% synapse IDs that are below threshold
belowThresh = setdiff (synapse, aboveThresh);

%% Find indices of dendrites that have never been active so far, i.e. has 
% less than SM.Thresh synapses above pemanence threshold SM.P_thresh

d = nonzeros(SM.synapseToDendrite(belowThresh)); % list of dendrites indexed by synapse
uniqueDendrite = nonzeros(unique(d));
countD = histc (nonzeros(d), uniqueDendrite);

lowActivityDendrities = (countD > (SM.numSynpasesPerDendrite(uniqueDendrite)' - SM.Theta));
% index of dendrites that have less than SM.Theta number of inactive dendrites
% i.e. was never active.
removeDendrites = uniqueDendrite(lowActivityDendrities);

%% Perform the actual removal, i.e. set the corresponding entries to zero. Note 
% that the indices of newly added dendrities and synapses will keep
% increasing. We do not attempt to "shift" the remaining dendrites "down"
% the indices. If we had 100 dendrites indexed from 1 through 100 and we
% removed the first ten, then the remaining dendrites will be indexed 10
% through 100, they are shifted down to 1 through 90.

if (removeDendrites)
    removeSynapses = synapse(ismember(dendrites, removeDendrites));
    
    c = nonzeros(SM.synapseToCell(removeSynapses)); % indexed by synapse
    %[y, i] = hist (c, unique(c));
    ud = nonzeros(unique(c));
    y = histc (nonzeros(d), ud);
    
    SM.numSynapsesPerCell (ud) = SM.numSynapsesPerCell (ud) - y';
    
    
    c = nonzeros(SM.dendriteToCell(removeDendrites)); % indexed by synapse
    %[y, i] = hist (c, unique(c));
    ud = nonzeros(unique(c));
    y = histc (nonzeros(d), ud);
    
    SM.numDendritesPerCell (ud) = SM.numDendritesPerCell(ud) - y';
    
    
    SM.synapseToCell (removeSynapses) = 0;
    SM.synapseToDendrite (removeSynapses) = 0;
    SM.synapsePermanence(removeSynapses) = 0;
    SM.synapseActive(removeSynapses) = 0;
    SM.synapsePositive(removeSynapses) = 0;
    SM.synapseLearn(removeSynapses) = 0;
    
    SM.dendriteToCell (removeDendrites) = 0;
    SM.dendritePositive (removeDendrites) = 0;
    SM.dendriteActive (removeDendrites) = 0;
    SM.dendriteLearn (removeDendrites) = 0;
    nRD = nnz(removeDendrites);
    nRS = nnz(removeSynapses);
    SM.totalDendrites = SM.totalDendrites - nRD;
    SM.totalSynapses = SM.totalSynapses - nRS;
    SM.numSynpasesPerDendrite (removeDendrites) = 0;
    
    fprintf(1, '\n Removed %d dendrites and %d synapses', nRD, nRS);
end;




