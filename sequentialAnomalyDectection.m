
function anomalyLikelihood = sequentialAnomalyDectection (anomalyScores, shortW, displayFlag, labelStart)
% This function detects anomalies in a sequence of raw scores according the
% method outlined in "Real-Time Anomaly Detection for Streaming Analytics",
% arXiv:1607.02480v1 [cs.AI] 8 Jul 2016 
% The input is a vector of raw scores and output is a zero-one vector of
% decisions with 1 denoting the points where an anomaly was detected.
%
% Was not able to exactly replicate the NUPIC likelihood normalization
% strategy. I suspect there are small but important "hacks" that need to
% implemented.
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
N = length(anomalyScores);

%% Incrementally estimate mean and standard deviation
% The problem, together with a better solution, is described in Donald Knuth's "The Art of Computer Programming, Volume 2: Seminumerical Algorithms", section 4.2.2. The solution is
% to compute mean and standard deviation using a recurrence relation, like this:
% M(1) = x(1), M(k) = M(k-1) + (x(k) - M(k-1)) / k
%  S(1) = 0, S(k) = S(k-1) + (x(k) - M(k-1)) * (x(k) - M(k))
% for 2 <= k <= n, then
% sigma = sqrt(S(n) / (n - 1))
% Knuth attributes this method to B.P. Welford, Technometrics, 4,(1962), 419-420.

mu = zeros(N, 1);
sigma = zeros(N, 1);
trN = min (750, round(0.15*N));

mu (trN) = anomalyScores(trN); sigma (trN) = 0.0;
for k=trN+1:N
    mu (k) = ((k-1-trN)*  mu(k-1) + anomalyScores(k))/(k-trN);
    sigma (k) = sigma (k-1) + (anomalyScores(k) - mu(k))*(anomalyScores(k) - mu(k));
end
sigma = sqrt(sigma./[1:trN,1:N-trN]');
%% Ignore scores upto this point
% parameters specified in https://drive.google.com/file/d/0B1_XUjaAXeV3dW1kX1B3VkYwOFE/view
%trN = min (750, round(0.15*N));
if (labelStart < trN) 
    fprintf(1, '\n Label in probabationary period');
end

%% Short term filter (smooth) the raw scores
% chossing median over mean did not result in better performance

filteredScores = zeros (N, 1);
for (k = shortW+1 : N)
    filteredScores (k) = sum(anomalyScores(k-shortW : k))/shortW;
end


%% Compute tail anomalyLikelihood

zScores = (filteredScores - mu)./(sigma); zScores(1:trN) = 0;
zScores = (zScores > 0).*zScores; % keep only positive zScores

anomalyLikelihood = 1 - exp(-zScores.^2/2); %erf(zScores); %1 - 2*qfunc(zScores);
anomalyLikelihood (1:trN) = 0;

%%%

if displayFlag
    subplot(8,1,6); plot(filteredScores); title ('Short Term mean');axis('tight');
    subplot(8,1,6); hold on; plot(mu, 'g'); title ('Short Term mean');axis('tight');
    subplot(8,1,6); hold on; plot(mu-sigma, 'm'); title ('Short Term mean'); hold off; axis('tight');
    subplot(8,1,6); hold on; plot(mu+sigma, 'm'); title ('Short Term mean'); hold off; axis('tight');
    subplot(8,1,8); plot(anomalyLikelihood,'b'); title ('Anomaly Likelihood'); hold off; axis([0 N 0 1]);
    subplot(8,1,7); plot(zScores,'b'); title ('z scores'); hold off; axis('tight');
end
