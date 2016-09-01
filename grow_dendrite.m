function y = grow_dendrite ()

global SM; 
% SM.SynapseWithPrevious and SM.SynapseWith--store the indices (linear) of the cells
% to synapse with from previous time step and current time step.


%% Mark the cells to synapse with in the NEXT step, inferred from the current input
% and the active dendritic connections

[row_i, col_i]  = find(SM.CellActive);
% can have columns with one active cell -- choose it to a potential synapse
% for next cycle
% can have columns with more than one active cell -- choose the "bext"
% active cell -- the one with maximum positive dentritic connection.
% can have bursting column with no dendrities, e.g. at the start of a new
% sequence, randomly choose one -- this will also be an anchor for a new
% dendrite.

activeCols = find(SM.Input);
cellIDPrevious = find(SM.SynapseWithPrevious);
[cellRowPrev, cellColPrev] = ind2sub ([SM.M, SM.N], cellIDPrevious);

n = length(activeCols);
SM.SynapseWith (:) = 0;
SM.AddDendrities (:) = 0;
for (k=1:n)
    % iterate though columns looking for synapse location.
    % if the column is shared between two time instant, use the location
    % chosen earlier.
    j = activeCols(k);
    i = row_i(ismember (col_i, j));
    cellIndex = sub2ind([SM.M SM.N], i, j*ones(size(i)));
    dendrites = ismember (SM.DendriteToCell, cellIndex);
    dendrites = find(dendrites);
    if (dendrites)
        [Val, id] = max(SM.DendritePositive(dendrites));
    end;
    if (~isempty(dendrites) && (Val > SM.minPositiveThreshold))
        SM.SynapseWith (SM.DendriteToCell(dendrites(id))) = 1;
    else
        % randomly choose location to add a dendrite  and the same location would be
        % potential synapse location for next step.
        
        xJ = find (cellColPrev == j);
        if xJ
            cellIndex = cellIDPrevious(xJ);
        else
            i = randi(SM.M);
            cellIndex = sub2ind([SM.M SM.N], i, j);
        end;
        SM.SynapseWith (cellIndex) = 1;
        SM.AddDendrities (cellIndex) = 1;
    end
end


dCells = find(SM.AddDendrities); %cells to grow dendrites
sCells = find(SM.SynapseWithPrevious); %potential cells to synapse with
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
            SM.DendriteToCell (SM.totalDendrites) = dC;
            
            newSynapses = [(SM.totalSynapses + 1) : (SM.totalSynapses + length(sC))];
            
            SM.SynapseToDendrite (newSynapses) = SM.totalDendrites * ones(size(newSynapses)); % stores the index of the dendrite it is connected to
            SM.SynapsePermanence (newSynapses) = randPermanence;
            
            SM.SynapseToCell (newSynapses) = sC;
            SM.numSynapsesPerCell(sC)  = SM.numSynapsesPerCell(sC) + 1;
            SM.totalSynapses = SM.totalSynapses + length(sC);
        else
            fprintf('\n Dendrite at cell %d NOT added. Has %d dendrities', dC, SM.numDendritesPerCell(dC)+0);
        end;
    end;
end;
        

    


