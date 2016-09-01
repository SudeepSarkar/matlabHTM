function y = reinforce_synapse ()
%
% This function performs Hebbian learning on the HTM array. At the core, the operation 
% is quite simple increase the permanences of the synapses contributing to a 
% correctly  predicted cell and decease the permanences of the synapses feeding into 
% incorrectly predicted cells.
%  
% There are Four possible cases
% Type 1  - Active segments (could be more than one) of a correctly predicted cell
%     are reinforced.
% Type 2  - One segment in a bursting column are reinforced. 
% Type 3  - Permanences of active segments of a wrongly predicted cell are decreased. 
% Type 4  - Permanences of non-active segments of a correctly predicted cell are
%      decreased. as well
% 
% Note that only the active segments (could be more than one) of a correctly predicted cell and 
% one segment in a bursting column are reinforced. Permanences of active segments of a wrongly 
% predicted cell are decreased.
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%



displayFlag = false;

global SM;

% dendrite  - cellID pair
[dendrite, ~, cellID] = find(SM.DendriteToCell); % note same cellID might be repeated
% create a list of synapse-dendrite pairs
[synapse, ~, dendriteID] = find(SM.SynapseToDendrite);
% create a list of synapse-preCell pairs
[synapse, ~, preCell] = find(SM.SynapseToCell);
 
%% Step 1: Find active dendrites connected to active cells to reinforce
% Note SM.DendriteActive already has dendrites with at least Theta number of synapses 
% marked with 1. This was done in compute_predicted_states. Dendrites could be active for 
% cells that are (i) active (tagged as SM.learnFlag == 1 in compute_active_cells), and (ii) 
% predicted cells, not active (tagged as SM.learnFlag == 3 in compute_active_cells). 
%

reinforceDendrites = (SM.learnFlag(cellID) == 1); 
% logical array aligned wth dendrites -- true if corresponding dendrite is connected to
% active cells



%% Step 2: Select dendrites from one cell in a bursting column to reinforce.
% The selection is based on the sum of the positive permanence of the dendrites connected 
% to a cell. Mark corresponding dendrite with SM.DendriteActive = 2.
% iterate through the bursting columns to find the dendrite to update 
% - one dendrite per column
%
n = length (SM.burstColumns);
for (k=1:n) % iterate though bursting columns
    j = SM.burstColumns(k); 
    cellIndex = (j-1)*SM.M + [1:SM.M];
    burstingDendrites = ismember (SM.DendriteToCell, cellIndex);
    burstingDendrites = find(burstingDendrites);
    if (burstingDendrites)
        [~, id] = max(SM.DendritePositive(burstingDendrites));
        
        if (reinforceDendrites (burstingDendrites(id)))
            fprintf (1, '\n \t Error = Reinforce dendrite %d in column %d',  burstingDendrites(id), j);
        end;
        reinforceDendrites (burstingDendrites(id)) = true;
    end
    
end;


%% Step 3: Update permanences of synapses of correctly predicted cells
% Find the active synapses of active dendrites connected to an correctly
% predicted cell. And then update their permanence -- boost the permanence
% of the ones that were predicted correctly from the previous cycle (tagged with
% SM.DendriteActive = 2) and weaken the permanence of the predicted cells from pervious cycle % that are not active (tagged with SM.DendriteActive = 1). The boost is proportional to the 
% total "positive" sum of the dendrite synapses. This value is "passed down" to the synapse 
% level in the following steps here. In the last statement the synapse permanences
% are updated based this dendrite level value (posSum).

reinforceSynapses = ismember(dendriteID, dendrite(reinforceDendrites)); % logical array aligned with the synapses

preSynapticActiveCells = SM.CellActivePrevious (preCell); % logical array aligned with synapses

strengthenSynapses = synapse(reinforceSynapses & preSynapticActiveCells & (SM.SynapsePermanence(synapse) < 1));

weakenSynapses = synapse(reinforceSynapses & ~preSynapticActiveCells & (SM.SynapsePermanence(synapse) > 0));

SM.SynapsePermanence(strengthenSynapses) = SM.SynapsePermanence(strengthenSynapses) + SM.P_incr;
%    + (SM.P_incr * SM.DendritePositive( dendriteID(strengthenSynapses) ));

SM.SynapsePermanence(weakenSynapses) = SM.SynapsePermanence(weakenSynapses) - SM.P_decr;
%     - (SM.P_decr * SM.DendritePositive( dendriteID(weakenSynapses) ));



%% Step 5: Demphasize synapses that predicted cells that are not in active input columns

d = (SM.learnFlag(cellID) == 3); %logical array array aligned with the dendrites
x = ismember(dendriteID, dendrite(d)); % logical array aligned with the synapses
s = synapse(x);
s = s (SM.SynapsePermanence(s) > 0);


SM.SynapsePermanence(s) = SM.SynapsePermanence(s) - SM.P_decr_pred;
%    - SM.P_decr_pred* SM.DendritePositive( dendriteID(s) );

      
  