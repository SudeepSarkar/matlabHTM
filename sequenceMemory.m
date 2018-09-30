function sequenceMemory (learnFlag)

global  SM 

    markActiveStates (); % based on x and PI_1 (prediction from past cycle)
    
    if learnFlag
       markLearnStates ();
       updateSynapses ();
    end

    % Predict next state
    SM.cellPredictedPrevious = SM.cellPredicted;   
    markPredictiveStates ();
   
end

