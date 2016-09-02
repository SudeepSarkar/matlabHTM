function addDendrites (dCells)

global SM


sCells = find(SM.cellLearnPrevious); %potential cells to synapse with
%sCells = find(SM.cellActivePrevious);
if ~isempty(sCells)
    for i=1:length(dCells)
        dC = dCells(i);
        if (SM.numDendritesPerCell(dC) < SM.Nd)
            SM.numDendritesPerCell(dC) = SM.numDendritesPerCell(dC)+1;
            %             if (SM.numDendritesPerCell(dC)+0) > 1
            %                 fprintf('\n Adding dendrite at cell %d with %d dendrities', dC, SM.numDendritesPerCell(dC)+0);
            %             end
            %% select synapses from active cells in SM.SynapseWithPrevious.  -- only one per
            % column, which is ensured during the selection of the cells to
            % synapse with
            rp = randperm (length(sCells)); % random permutation vector
            sCells = sCells(rp);
            
            sC = sCells(1:min(SM.Ns, length(sCells))); % Ns maximum random synapses per dendrite
            
            randPermanence =  (2*SM.P_incr).*rand(size(sC)) + SM.P_initial - SM.P_incr;
            
            %SM.P_initial*ones(size(ur_i));
            
            SM.totalDendrites= SM.totalDendrites + 1;
            SM.dendriteToCell (SM.totalDendrites) = dC;
            
            newSynapses = [(SM.totalSynapses + 1) : (SM.totalSynapses + length(sC))];
            
            SM.synapseToDendrite (newSynapses) = SM.totalDendrites * ones(size(newSynapses)); % stores the index of the dendrite it is connected to
            SM.synapsePermanence (newSynapses) = randPermanence;
            
            SM.synapseToCell (newSynapses) = sC;
            SM.numSynapsesPerCell(sC)  = SM.numSynapsesPerCell(sC) + 1;
            SM.totalSynapses = SM.totalSynapses + length(sC);
        else
            fprintf('\n Dendrite at cell %d NOT added. Has %d dendrities', dC, SM.numDendritesPerCell(dC)+0);
        end;
    end;
end;