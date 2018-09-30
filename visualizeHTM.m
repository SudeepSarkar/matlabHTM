function visualizeHTM (iteration)
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  anomalyScores data
        
subplot(3,2,1); 
plot(data.value{1}, 'b'); hold on; axis('tight'); plot([iteration iteration], [0 100], 'r'); hold off;
title ('Input Signal ');


subplot(3,2,3); 
plot(anomalyScores(max(1, iteration-1000): iteration)); axis ([1 min(iteration+10, 1010) 0 1]); 
title ('Our Computed Anomaly Scores');

subplot(3,2,5); 
plot(data.numentaRawAnomalyScore(max(1, iteration-1000): iteration)); axis ([1, min(iteration+10, 1010) 0 1]); 
title ('Numenta Anomaly Scores (NUPIC)');

   
 
