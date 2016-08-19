function y = reinforce_synapse (sdr)
%
% This function performs Hebbian learning on the HTM array. At the core, the operation 
% is quite simple increase the permanences of the synapses contributing to a 
% correctly  predicted cell and decease the permanences of the synapses feeding into 
% incorrectly predicted cells.
% 
% Note that only the active segments (could be more than one) of a correctly predicted cell and 
% one segment in a bursting column are reinforced. Permanences of active segments of a wrongly 
% predicted cell are decreased.

global SM;

 
%% Step 1: Find active dendrites connected to active cells to reinforce
% Note SM.DendriteActive already has dendrites with at least Theta number of synapses 
% marked with 1. This was done in compute_predicted_states. Dendrites could be active for 
% cells that are (i) active (tagged as SM.learnFlag == 1 in compute_active_cells), and (ii) 
% predicted cells, not active (tagged as SM.learnFlag == 3 in compute_active_cells). 
% Dendrites connected to category cells from (i) will be tagged with with the number
% 2 in the DendriteActive array after the following operations.

% dendrite  - cellID pair
%
[dendrite, ~, cellID] = find(SM.DendriteToCell); % note same cellID might be repeated
%[d, ~, ~] = find(SM.learnFlag(cellID) == 1); 
d = SM.learnFlag(cellID) == 1; 
%
% d marks the active cells -- index corresponds to the (dendrite, CellID) pairs
% dendrite(d) are the dendrites connected to active cells.
%
SM.DendriteActive(dendrite(d)) = SM.DendriteActive(dendrite(d)) + 1;


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
        SM.DendriteActive (burstingDendrites(id)) = 2;
        %fprintf (1, '\n Reinforce dendrite %d in column %d', ...
        %    burstingDendrites(id), j);
    end
    
end;


%% Step 3: Update permanences of synapses of correctly predicted cells
% Find the active synapses of active dendrites connected to an correctly
% predicted cell. And then update their permanence -- boost the permanence
% of the ones that were predicted correctly from the previous cycle (tagged with
% SM.DendriteActive = 2) and weaken the permanence of the predicted cells from pervious cycle % that are not active (tagged with SM.DendriteActive = 1). The boost is proportional to the 
% total "positive" sum of the dendrite synapses. This value is "passed down” to the synapse 
% level in the following steps here. In the last statement the synapse permanences
% are updated based this dendrite level value (posSum).

% create a list of synapse-dendrite pairs
[synapse, ~, dendriteID] = find(SM.SynapseToDendrite);

% d is a list of active dendrites -- dendrites with more than Theta number of active synapses
% that did not make correct prediction -- we have to demphasize these dendrites
%
%[d, ~, ~] = find(SM.DendriteActive(dendrite) == 1);
d = SM.DendriteActive(dendrite) == 1;
SM.DendritePositive(d) = 0;  


%[x, ~, ~] = find(SM.DendriteActive(dendriteID) ~= 0);
x = SM.DendriteActive(dendriteID) ~= 0;
s = synapse(x); d = dendriteID(x);

selectPositive = (SM.SynapsePermanence(s) > 0); 
s = s (selectPositive); d = d (selectPositive);


SM.SynapsePermanence(s) = SM.SynapsePermanence(s) ...
    + (SM.P_incr * SM.DendritePositive(d) - SM.P_decr);

%% Step 4: Demphasize synapses that predicted cells that are not in active input columns

%[d, ~, ~] = find(SM.learnFlag(cellID) == 3); % wrongly predicted cells
d = SM.learnFlag(cellID) == 3;
x = ismember(dendriteID, dendrite(d));
s = synapse(x);
s = s (SM.SynapsePermanence(s) > 0);

SM.SynapsePermanence(s) = SM.SynapsePermanence(s)  - SM.P_decr_pred;


      
  