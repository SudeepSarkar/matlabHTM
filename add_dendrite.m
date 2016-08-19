function y = add_dendrite (cellRow, cellCol)
% add a dendrite to the specified cell with synaptic functions to randomly
% selected active cells from pervious iteration.

global SM;

%% Add dendrite
fprintf (1, '\n Adding dendrite at cell (%d %d)', cellRow, cellCol);
rjj = sub2ind ([SM.M, SM.N], cellRow, cellCol);
SM.numDendritesPerCell(rjj) = SM.numDendritesPerCell(rjj)+1;
SM.totalDendrites= SM.totalDendrites + 1;
SM.DendriteToCell (SM.totalDendrites) = rjj;

%% Select synapses from active cells in SM.CellActivePrevious. 

[row_i, col_i]  = find(SM.CellActivePrevious); % index of active cells at time t-1
rp = randperm (length(row_i)); % random permutation vector
row_i = row_i(rp); % randomly permute the order of the cells.
col_i = col_i(rp); % randomly permute the order of the cells.
    
% remove active cells in the same column as the dendrite from possible
% synaptic junctions. Distal dendrities do not connect to cells in the same
% column.
indCol = not(ismember(col_i, cellCol)); 
row_i = row_i(indCol); col_i = col_i(indCol);
    
% The synapses should be from different columns -- no two synapses should
% be from the same column
[uc_i,IA,~] = unique(col_i); % find the unique columns
ur_i = row_i (IA);  % choose the corresponding rows
rp = randperm (length(ur_i)); % random permutation vector
ur_i = ur_i(rp); % randomly permute the order of the cells.
uc_i = uc_i(rp); % randomly permute the order of the cells.

a = ur_i(1:min(SM.Ns, length(ur_i))); % Ns maximum random synapses per dendrite
b = uc_i(1:min(SM.Ns, length(uc_i)));

randPermanence = P_initial;
%(2*SM.P_incr).*rand(size(a)) + SM.P_thresh - SM.P_incr;

%SM.P_initial*ones(size(ur_i));

newSynapses = [(SM.totalSynapses + 1) : (SM.totalSynapses + length(a))];

% stores the index of the dendrite it is connected to
SM.SynapseToDendrite (newSynapses) = SM.totalDendrites * ones(size(newSynapses)); 
SM.SynapsePermanence (newSynapses) = randPermanence;

cellIndex = sub2ind ([SM.M, SM.N], a, b);
SM.SynapseToCell (newSynapses) = cellIndex;

% increment counts

SM.numSynapsesPerCell(cellIndex)  = SM.numSynapsesPerCell(cellIndex) + 1;

SM.totalSynapses = SM.totalSynapses + length(a);


