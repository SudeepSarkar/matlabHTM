function [S_A, perfectScore, nullScore] = computeScore (detections, labels, A_tp, A_fp, A_fn)
% This function is used to score the anomalied detected and marked in the
% vector "detections". The scoring methodology follows https://github.com/numenta/NAB
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%

N = length(detections);
labels (N) = 0;
% force the last label to be an non-anomaly -- makes the logic for
% computing scores easier without impact on the overall score.

nullScore = 0;

dlabels = [0 diff(labels)'];
% gets the leading edge and the lagging edge of a label run
windowL = 0;
weights = zeros(size(labels));
falseNegatives = 0;
perfectScore = sum(((1+exp(-5.2)).^(-1))*(dlabels > 0));

for k = 1:length(labels)
    windowL = windowL + labels(k);
    
    if (dlabels (k) < 0)
        sigmoidLeft = ((1+exp((5.2/windowL)*[-windowL:-1]')).^(-1));
        sigmoidRight = ((1+exp((5.2/windowL)*[0:windowL]')).^(-1));
        weights(max(1, k-windowL):k-1) = labels(max(1, k-windowL):k-1).*...
            sigmoidLeft;
        weights(k:min(N, k+windowL)) = labels(k:min(N, k+windowL))+...
            sigmoidRight (1:(min(N+1, k+windowL+1)-k));

        % zero out all alerts except for the first one in the windpow
        firstAlert = find (detections(max(1, k-windowL):k));
        if (firstAlert)
            detections (max(1, k-windowL)+firstAlert:k) = 0;
        else
            falseNegatives = falseNegatives + 1;
        end
        windowL = 0;
        nullScore = nullScore + A_fn;
    end
end

labels = 2*weights - 1;

labels = A_tp*(labels > 0).*labels - A_fp*(labels < 0).*labels;

S_A = sum(labels.*detections) + A_fn * falseNegatives;

%nonzeros(labels.*detections)

% subplot(5,1,5); plot(detections,'g'); title ('Numenta');  axis('tight');
% subplot(5,1,5); hold on; plot(labels, 'r.'); axis ('tight'); hold off;


