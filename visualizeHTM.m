function y = visualizeHTM (iteration, x, data)

global  SM  anomalyScores

subplot(10, 1, 1); spy(SM.CellPredicted); title ('Predicted cells')
subplot(10, 1, 2); spy(SM.CellActive); title ('Active cells')

subplot(10, 1, 3); plot(x); axis([1 length(x) 0 1]); title ('Input')

[~, ~, cellID] = find(SM.DendriteToCell);
C = sparse (SM.M, SM.N); C(unique(cellID)) = 1;
subplot (10,1, 2); hold on; plot(logical(sum(C)) & logical(sum(SM.CellActive)), 'r'); hold off;


subplot (10,1,5); plot (SM.DendriteActive (1:SM.totalDendrites ))
title ('Active Dendrites')

subplot (10,1,6); plot (SM.SynapseActive (1:SM.totalSynapses))
title ('Active Synapses')

nData = length(data.value{1});
subplot(10,1,9); plot(data.value{1}(max(1, iteration-1000): min(nData, iteration+10)), 'b'); axis tight; hold on; title ('Input Signal');

hold off;
        
subplot(10,1,8); 
plot(anomalyScores(max(1, iteration-1000): iteration)); axis ([1 min(iteration+10, 1010) 0 1]); 
title ('Anomaly Scores');

subplot(10,1,10); 
plot(data.numentaRawAnomalyScore(max(1, iteration-1000): iteration)); axis ([1, min(iteration+10, 1010) 0 1]); 
title ('Numenta Anomaly Scores');

   
 
