function y = visualizeHTM (iteration, x, data)
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  SM  anomalyScores predictions

%subplot(10, 1, 1); spy(SM.cellPredicted); title ('Predicted cells')
%subplot(10, 1, 3); spy(SM.cellActive); title ('Active cells')
%subplot (10,1,2); spy(SM.cellLearn); title ('Learning cells')

%subplot(10, 1, 3); plot(x); axis([1 length(x) 0 1]); title ('Input')

% [~, ~, cellID] = find(SM.dendriteToCell);
% C = sparse (SM.M, SM.N); C(unique(cellID)) = 1;
% subplot (10,1, 2); hold on; plot(logical(sum(C)) & logical(sum(SM.cellActive)), 'r'); hold off;
% 

subplot (10,1,4); plot (SM.dendritePositive (1:SM.totalDendrites ))
title ('Positive Dendrites')

% subplot (10,1,1); plot (nonzeros(SM.synapseToDendrite)); axis('tight');
% title ('Synapse to Dendrites')
% 
% [i, c] = ind2sub([SM.M, SM.N], nonzeros(SM.synapseToCell));
% x = zeros(SM.N, 1); x(c) = 2;
% subplot (10,1,2); plot (x, 'r'); axis('tight'); hold on;
% plot(SM.inputPrevious, 'g'); hold off;
% title ('Synapse to Cells')

% subplot (10,1,5); plot (SM.synapseLearn, ones(size(SM.synapseLearn)), 'bo')
% title ('Learn Synapses')

subplot (10,1,6); plot (nonzeros(SM.synapsePermanence)); axis('tight');
title ('Synapse Permanences')
        
subplot(10,1,7); 
plot(data.value{1}, 'b'); hold on; axis('tight'); plot([iteration iteration], [0 100], 'r'); hold off;
title ('Input Signal');

nData = length(data.value{1});
subplot(10,1,8); plot(data.value{1}(max(1, iteration-1000): min(nData, iteration+10)), 'b'); axis tight;  title ('Input Signal');
hold on;
subplot(10,1,8); plot(predictions(1, max(1, iteration-1000): min(nData, iteration+10)), 'r'); axis tight;  title ('Input Signal');
subplot(10,1,8); plot(predictions(2, max(1, iteration-1000): min(nData, iteration+10)), 'r'); axis tight;  title ('Input Signal');
hold off

subplot(10,1,9); 
plot(anomalyScores(max(1, iteration-1000): iteration)); axis ([1 min(iteration+10, 1010) 0 1]); 
title ('Anomaly Scores');

subplot(10,1,10); 
plot(data.numentaRawAnomalyScore(max(1, iteration-1000): iteration)); axis ([1, min(iteration+10, 1010) 0 1]); 
title ('Numenta Anomaly Scores');

   
 
