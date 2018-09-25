function displayCellAnimation ()
%% This is just for visualizing the distal dendrite structure as it evolves through the learning phase.
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  SM 

% Plot past state of the cell array on the left side
nzInput = find(SM.inputPrevious);
plot(-0.3 *ones(size(nzInput)), nzInput./length(SM.inputPrevious), 'bo'); hold on;

[xAP, yAP] = find (SM.cellActivePrevious); 
xAP = xAP/SM.M; yAP = yAP/SM.N;
plot(xAP, yAP, 'r+'); axis ([-1 4 0 1]); 

% Plot past state of the cell array on the right side

nzInput = find(SM.input);
plot(3.2 *ones(size(nzInput)), nzInput./length(SM.input), 'bo');

[xCP, yCP] = find (SM.cellPredicted); 
xCP = xCP/SM.M + 2; yCP = yCP/SM.N;
plot(xCP, yCP, 'bs', 'MarkerSize', 10);  hold on;

[xCP, yCP] = find (SM.cellLearn); 
xCP = xCP/SM.M + 2; yCP = yCP/SM.N;
plot(xCP, yCP, 'mo', 'MarkerSize', 10);  hold on;

[xCP, yCP] = find (SM.cellLearnPrevious); 
xCP = xCP/SM.M; yCP = yCP/SM.N;
plot(xCP, yCP, 'mo', 'MarkerSize', 10);  hold on;

[xCA, yCA] = find (SM.cellActive); 
xCA = xCA/SM.M + 2; yCA = yCA/SM.N;
plot(xCA, yCA, 'r+');  hold on;

[dendrite, ~, cellID] = find(SM.dendriteToCell); 
yDendrite = dendrite(logical(SM.dendriteActive))./SM.totalDendrites;
xDendrite = 1.5 *ones(size(yDendrite));
[xCell, yCell] = ind2sub([SM.M, SM.N], cellID);
yCell = yCell(logical(SM.dendriteActive))/SM.N; xCell = xCell(logical(SM.dendriteActive))/SM.M + 2; 


line ([xDendrite'; xCell'], [yDendrite'; yCell'], 'Marker','.','LineStyle','-', 'color', 'g');


[~, ~, cellID] = find(SM.synapseToCell); 
[xCell, yCell] = ind2sub([SM.M, SM.N], cellID);
%yCell2 = yCell/SM.N; xCell2 = xCell/SM.M; 
yCell = yCell(SM.synapseActive)/SM.N; xCell = xCell(SM.synapseActive)/SM.M; 

[~, ~, dendrite] = find(SM.synapseToDendrite); 
yDendrite = dendrite(SM.synapseActive)./SM.totalDendrites;
xDendrite = 1.5 *ones(size(yDendrite));
%yDendrite2 = dendrite/SM.totalDendrites;
%xDendrite2 = 1.5 *ones(size(yDendrite2));

%line ([xDendrite2'; xCell2'], [yDendrite2'; yCell2'], 'Marker','.','LineStyle','-.', 'color', 'g');
line ([xDendrite'; xCell'], [yDendrite'; yCell'], 'Marker','.','LineStyle','-', 'color', 'g');


yDendrite = dendrite./SM.totalDendrites;
xDendrite = 1.5 *ones(size(yDendrite));
plot (xDendrite, yDendrite, 'ro');


hold off;



