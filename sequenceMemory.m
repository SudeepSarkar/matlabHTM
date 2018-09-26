function sequenceMemory (learnFlag)

global  SP SM TP data anomalyScores iteration predictions

    markActiveStates (); % based on x and PI_1 (prediction from past cycle)
    
    if learnFlag
       markLearnStates ();
       updateSynapses ();
    end

    % Predict next state
    SM.cellPredictedPrevious = SM.cellPredicted;
    
    markPredictiveStates ();
   
    SM.cellActivePrevious = SM.cellActive;
    SM.inputPrevious = SM.input;
    SM.cellLearnPrevious = SM.cellLearn;
   
end

