function compute_predictive_states ()
% This function computes the indices of the cells in predicted state and stores it in the sparse array 
% SM.CellPredicted. In the process of computing this, it stores the count of active synapses for the dendrites 
% feeding from the currently  active cells. It keeps two kinds of counts — count of active synapses in 
% SM.DendriteActive and count of positive synapses in SM.DendritePositive 
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  SM;

%% Initialize the active and Positive synapse and dendrite to NULL sets
%
% Note --- the underlying synapse/dendrite/cell pointer-based data structure is oriented in the following way
% Cell body affecting (input) <-- synapse --> dendrites�--> cell body affected (output)

%SM.SynapseActive = []; %(:) = 0; % synapses that have permanences above a threshold
SM.DendriteActive (:) = 0;
%SM.SynapsePositive = []; %(:) = 0; % synapses that have positive permanences 
SM.DendritePositive (:) = 0;


%% Mark the synapses that are on cells with active input and also those that 
% could be potentially active had their (positive) permanence been higher.

% synapse is an index of the synapses along with corresponding cell body it is connected to in cellID

[synapse, ~, cellID] = find(SM.SynapseToCell);

% x is a vector of (linear) indices of active cells - note cellID contains the indices of the cells corresponding to 
% each of the synapses -- so a particular cell index will appear multiple times. 
% Thus, size of x is NOT the equal to the number of active cells, 
% but is equal to the number of synapses connected to active cells.

x = SM.CellActive(cellID) > 0;
synapseInput = synapse(x);
% synapse(x) is a list of synapses connected to active cells


SM.synapseActive = find(SM.SynapsePermanence > SM.P_thresh);
SM.synapseActive = intersect(synapseInput, SM.synapseActive);
SM.synapsePositive = find(SM.SynapsePermanence > 0);
SM.synapsePositive = intersect(synapseInput, SM.synapsePositive);

%% Mark the active dendrites -- those with more that Theta number of active synapses

% First it computes the count of active synapses for each dendrite in SM.DendriteActive, indexed by the dendrites
% x is the list of active synapses, i.e. synapses connected to active input and with permanence above P_thresh
% SynapseToDendrite is an array that stores the dendrite id for each synapse
% histogram of the array SynapseToDendrite (x) would do the job too.
%

d = SM.SynapseToDendrite(SM.synapseActive);
[y, i] = hist (d, unique(d));
SM.DendriteActive (i) = y;


SM.DendriteActive = double(SM.DendriteActive > SM.Theta);


%% Mark the potentially active dendrites with their total

d = SM.SynapseToDendrite(SM.synapsePositive);
[y, i] = hist (d, unique(d));
SM.DendritePositive (i) = y;

%% Mark the predicted cells as those with at least one active dendrite
% DendriteToCell vector stores the index of the cell body it is connected to (affecting)
%   multiple dendrites can be connected to a cell body so the vector will have repeating entries of cell indices
%  

SM.CellPredicted (:)= 0; 
[x, ~, ~] = find(SM.DendriteActive); % active dendrites
u = unique(SM.DendriteToCell(x));

SM.CellPredicted (u) = true;




