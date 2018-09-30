function displayCellAnimation ()
%% This is for visualizing the state of the sequence memory module as it evolves through the learning phase.
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  SM 

% [dendrite, ~, cellID] = find(SM.dendriteToCell); 
% yDendrite = dendrite./SM.totalDendrites;
% xDendrite = 1.5 *ones(size(yDendrite));
% plot (xDendrite, yDendrite, 'ro'); hold on;
% h=text(1.4,0.85,'Dendrites (circles)'); set(h,'Rotation',90);

% yDendrite = dendrite(logical(SM.dendriteActive))./SM.totalDendrites;
% xDendrite = 1.5 *ones(size(yDendrite));
% [xCell, yCell] = ind2sub([SM.M, SM.N], cellID);
% yCell = yCell(logical(SM.dendriteActive))/SM.N; xCell = xCell(logical(SM.dendriteActive))/SM.M + 2; 
% 
% line ([xDendrite'; xCell'], [yDendrite'; yCell'], 'Marker','.','LineStyle','-', 'color', 'g');
% hold on;
% 
% [~, ~, cellID] = find(SM.synapseToCell); 
% [xCell, yCell] = ind2sub([SM.M, SM.N], cellID);
% %yCell2 = yCell/SM.N; xCell2 = xCell/SM.M; 
% yCell = yCell(SM.synapseActive)/SM.N; xCell = xCell(SM.synapseActive)/SM.M; 
% 
% [~, ~, dendrite] = find(SM.synapseToDendrite); 
% yDendrite = dendrite(SM.synapseActive)./SM.totalDendrites;
% xDendrite = 1.5 *ones(size(yDendrite));
% %yDendrite2 = dendrite/SM.totalDendrites;
% %xDendrite2 = 1.5 *ones(size(yDendrite2));
% 
% %line ([xDendrite2'; xCell2'], [yDendrite2'; yCell2'], 'Marker','.','LineStyle','-.', 'color', 'g');
% line ([xDendrite'; xCell'], [yDendrite'; yCell'], 'Marker','.','LineStyle','-', 'color', 'g');
% hold on;

% Plot past state of the cell array on the left side
nzInput = find(SM.inputPrevious);
plot(-0.3 *ones(size(nzInput)), nzInput./length(SM.inputPrevious), 'bo'); hold on;

[xAP, yAP] = find (SM.cellActivePrevious); 
xAP = xAP/SM.M; yAP = yAP/SM.N;
plot(xAP, yAP, 'r+'); axis ([-1 4 0 1]); 

% Plot current state of the cell array on the right side

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



text(0, -0.05, 'Previous time period')
text(2, -0.05, 'Current time period')
h=text(-0.5,0.85,'Current input to SM'); set(h,'Rotation',90);
h=text(3.4,0.85,'Current input to SM'); set(h,'Rotation',90);
h=text(0.1,1.01, 'Columnlar cells'); 
h=text(2.1,1.01, 'Columnlar cells'); 

title ('States of Sequence Memory Cells and Their Connections', 'Position', [0.5, 1.03])
hold off;




