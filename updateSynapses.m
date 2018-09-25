function updateSynapses ()
%
% This function performs Hebbian learning on the HTM array. This is the last phase of an iteration.
% This update is based on the learnState of a cell.
% For all cells with learnState of 1, synapses that were active in the previous iteration get their
% permanence counts incremented by permanenceInc. All other synapses get their permanence counts decremented by
% permanenceDec.
%
% We negatively reinforce all segments of cell with incorrect prediction. Permanence counts for synapses
% are decremented by predictedSegmentDec.
%


%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%


global SM;

% dendrite  - cellID pair
[dendrite, ~, cellID] = find(SM.dendriteToCell); % note same cellID might be repeated
% create a list of synapse-dendrite pairs
[~, ~, dendriteID] = find(SM.synapseToDendrite);
% create a list of synapse-preCell pairs
[synapse, ~, preCell] = find(SM.synapseToCell);

%% Step 1: Find active dendrites connected to active cells to reinforce
% Note SM.DendriteActive already has dendrites with at least Theta number of synapses
% marked with 1. This was done in compute_predicted_states. Dendrites could be active for
% cells that are (i) active (tagged as SM.learnFlag == 1 in compute_active_cells), and (ii)
% predicted cells, not active (tagged as SM.learnFlag == 3 in compute_active_cells).
%

reinforceDendrites = (SM.cellLearn(cellID) == 1);

% logical array aligned wth dendrites -- true if corresponding dendrite is connected to
% active cells

%% Step 3: Update permanences of synapses of correctly predicted cells
% Find the active synapses of active dendrites connected to an correctly
% predicted cell. And then update their permanence -- boost the permanence
% of the ones that were predicted correctly from the previous cycle (tagged with
% SM.DendriteActive = 2) and weaken the permanence of the predicted cells from pervious cycle % that are not active (tagged with SM.DendriteActive = 1). The boost is proportional to the
% total "positive" sum of the dendrite synapses. This value is "passed down" to the synapse
% level in the following steps here. In the last statement the synapse permanences
% are updated based this dendrite level value (posSum).

reinforceSynapses = ismember(dendriteID, dendrite(reinforceDendrites)); % logical array aligned with the synapses

%preSynapticActiveCells = SM.cellActivePrevious (preCell); % logical array aligned with synapses

strengthenSynapses = synapse(reinforceSynapses & (SM.synapsePermanence(synapse) < 1));

%strengthenSynapses = synapse(reinforceSynapses & preSynapticActiveCells & (SM.synapsePermanence(synapse) < 1));

%weakenSynapses = synapse(reinforceSynapses & ~preSynapticActiveCells & (SM.synapsePermanence(synapse) > 0));

SM.synapsePermanence(strengthenSynapses) = SM.synapsePermanence(strengthenSynapses) + SM.P_incr;

%SM.synapsePermanence(weakenSynapses) = SM.synapsePermanence(weakenSynapses) - SM.P_decr;




%% Step 5: Demphasize synapses that predicted cells that are not in active input columns

cp = (SM.cellPredicted(cellID) == 1); %logical array aligned with the dendrites
cpp = (SM.cellActive(cellID) == 0);
d = cp & cpp;
%d = (SM.learnFlag(cellID) == 3); %logical array array aligned with the dendrites
x = ismember(dendriteID, dendrite(d)); % logical array aligned with the synapses
s = synapse(x);
s = s (SM.synapsePermanence(s) > 0);

SM.synapsePermanence(s) = SM.synapsePermanence(s) - SM.P_decr_pred;



