function [active, reconstructionError] = spatialPooler (encodedInput, learnP, displayFlag)
%
% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
%
global  SM SP

if size(encodedInput, 1) == 1, encodedInput = encodedInput'; end;


%% compute overlap
overlap = (double(SP.synapse > SP.connectPerm) * encodedInput);

overThreshold = (overlap > SP.stimulusThreshold);
SP.overlapDutyCycle = 0.9 * SP.overlapDutyCycle + 0.1 * sum(overThreshold, 2);

overlap = overThreshold.*overlap;
if (learnP) overlap = overlap.*SP.boost; end;

%% inhibit responses -- pick the top k columns
[v,I] = sort (overlap, 'descend');
overlap(I(round(SP.activeSparse*SM.N):SM.N)) = 0; 
active = overlap > 0;

reconstructionError = 0;
if (learnP)
    %% reconstruct the input
    reconstructedInput = (double(SP.synapse > SP.connectPerm)' * active) > SM.Theta;
    
    reconstructionError = (sum(abs((reconstructedInput > 0) - encodedInput)));
    if (displayFlag) 
        subplot(10,1,4); plot(reconstructedInput); 
        hold on; plot (encodedInput, 'r*'); hold off; 
        title ('Reconstructed Input'); 
    end;
    
    if (reconstructionError < 2)
        fprintf('\n Reconstruction error is %d stop learning on this input', reconstructionError);
        learnP = false;
    end;
end;   

% note: learning can be switched off for an input in the previous if
% statement, so the two if-statements cannot be merged.
if (learnP) 

    %% learning
    
    activeCols = find(active);
    activeSynapses = find(encodedInput);
    
    SP.synapse(activeCols , activeSynapses) = min(1.0, SP.synapse(activeCols , activeSynapses) + ...
        SP.synPermActiveInc);
   
    inactiveSynapses = find(1 - encodedInput);
    SP.synapse(activeCols , inactiveSynapses) = max(0, SP.synapse(activeCols , inactiveSynapses) - ...
        SP.synPermInactiveDec);

    SP.synapse = SP.synapse.*SP.connections; % zero out the entries with no synapse connection
    
    %% boosting
    SP.minDutyCycle = 0.01 * max (SP.activeDutyCycle);
    SP.activeDutyCycle = (0.9 * SP.activeDutyCycle + 0.1 * sum(active, 2)); % need to change into running average later
        
    SP.boost = min (SP.maxBoost, max (1.0, SP.minDutyCycle./SP.activeDutyCycle));
    
    inDuty = find (SP.overlapDutyCycle < SP.minDutyCycle);
    SP.synapse (inDuty,:) = SP.synapse (inDuty,:) + 0.1;
    

end;
active = active';

