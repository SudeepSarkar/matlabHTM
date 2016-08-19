function y = displayCellAnimation ()
%% This is just for visualizing the distal dendrite structure as it evolves through the learning phase.

global  SM 

% Plot past state of the cell array on the left side
nzInput = find(SM.InputPrevious);
plot(-0.3 *ones(size(nzInput)), nzInput./length(SM.InputPrevious), 'bo'); hold on;

[xAP, yAP] = find (SM.CellActivePrevious); 
xAP = xAP/SM.M; yAP = yAP/SM.N;
plot(xAP, yAP, 'r+'); axis ([-1 4 0 1]); 

% Plot past state of the cell array on the right side

nzInput = find(SM.Input);
plot(3.2 *ones(size(nzInput)), nzInput./length(SM.Input), 'bo');

[xCP, yCP] = find (SM.CellPredicted); 
xCP = xCP/SM.M + 2; yCP = yCP/SM.N;
plot(xCP, yCP, 'bs', 'MarkerSize', 10);  hold on;

[xCA, yCA] = find (SM.CellActive); 
xCA = xCA/SM.M + 2; yCA = yCA/SM.N;
plot(xCA, yCA, 'r+');  hold on;

[dendrite, ~, cellID] = find(SM.DendriteToCell); 
yDendrite = dendrite(logical(SM.DendriteActive))./SM.totalDendrites;
xDendrite = 1.5 *ones(size(yDendrite));
[xCell, yCell] = ind2sub([SM.M, SM.N], cellID);
yCell = yCell(logical(SM.DendriteActive))/SM.N; xCell = xCell(logical(SM.DendriteActive))/SM.M + 2; 


line ([xDendrite'; xCell'], [yDendrite'; yCell'], 'Marker','.','LineStyle','-', 'color', 'g');


[synapse2, ~, cellID] = find(SM.SynapseToCell); 
[xCell, yCell] = ind2sub([SM.M, SM.N], cellID);
yCell = yCell(logical(SM.SynapseActive))/SM.N; xCell = xCell(logical(SM.SynapseActive))/SM.M; 

[synapse1, ~, dendrite] = find(SM.SynapseToDendrite); 
yDendrite = dendrite(logical(SM.SynapseActive))./SM.totalDendrites;
xDendrite = 1.5 *ones(size(yDendrite));

line ([xDendrite'; xCell'], [yDendrite'; yCell'], 'Marker','.','LineStyle','-', 'color', 'g');


yDendrite = dendrite./SM.totalDendrites;
xDendrite = 1.5 *ones(size(yDendrite));
plot (xDendrite, yDendrite, 'ro');


hold off;



