function markLearnStates ()
% Update the learn states of the cells (one per ACTIVE columns). This is to be run after the active states
% have been updated (compute_active_states). For those ACTIVE COLUMNS, this code further selects ONE cell
% per column as the learning cell (learnState). The logic is as follows. If an active cell has a segment that
% became active from cells chosen with learnState on, this cell is selected as the learning cell, i.e. learnState is
% set to 1.

% For bursting columns, the best matching cell is chosen as the learning cell and a new segment is added to that
% cell. Note that it is possible that there is no best matching cell; in this case getBestMatchingCell chooses
% a cell with the fewest number of segments, using a random tiebreaker

% getBestMatchingCell - For the given column, return the cell with the best matching segment (as defined below).
% If no cell has a matching segment, then return a cell with the fewest number of segments using a
% random tiebreaker.

% Best matching segment - For the given column c cell i, find the segment with the largest number of ACTIVE
% synapses. This routine is aggressive in finding the best match. The permanence value of
% synapses is ALLOWED to be below connectedPerm. The number of active synapses is allowed to
% be below activationThreshold, but must be above minThreshold. The routine returns the
% segment index. If no segments are found, then an index of -1 is returned.
%
%% Copyright (c) 2016,  Sudeep Sarkar, University of South Florida, Tampa, USA
% This work is licensed under the Attribution-NonCommercial-ShareAlike 4.0 International License.
% To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

global SM;

SM.cellLearn (:) = 0;
activeCols = find(SM.input);

%% Mark the correctly predicted active cells with dendrites that are also
% predictive based on on learning states. 

[xL, ~, ~] = find(SM.dendriteLearn); % active learning dendrites
uL = unique(SM.dendriteToCell(xL)); % marks cells with active learning dendrites
if ~isempty(SM.predictedActive)
    lc_cols = find(SM.predictedActive (uL));
    [R, C] = ind2sub ([SM.M, SM.N], lc_cols);
    % u = ismember (SM.predictedActiveCells, uL); % which of the active cells are connected to learning dendrites
    % [R, C] = ind2sub ([SM.M, SM.N], SM.predictedActiveCells(u));
    
    [C,IA,~] = unique(C);  R = R(IA); % select only one active per column
    
    SM.cellLearn(sub2ind([SM.M, SM.N], R, C)) = true;
else
   lc_cols = [];
end
%% find the active columns without a learnCell state set -- activeCols
%[~, lc_cols]  = find(SM.predictedActiveCells(u));
[~, x] = setdiff(activeCols, lc_cols);
activeCols = activeCols(x); % removed some columns with learnCell already set

%% Iterate through the remaining columns selecting a single learnState cell in each
n = length(activeCols);
[row_i, col_i]  = find(SM.cellActive);
cellIDPrevious = find(SM.cellLearnPrevious);
[~, cellColPrev] = ind2sub ([SM.M, SM.N], cellIDPrevious);
dCells = zeros(SM.N, 1); nDCells = 0;
expandDendrites = zeros(SM.N, 1);

for k=1:n
    % iterate though columns looking for cell to set learnState
    
    j = activeCols(k);
    
    % find the row indices (row_i) of active cells in column j
    i = row_i(ismember (col_i, j)); % Could be more than 1 -- i can be a vector
    
    [cellChosen, newSynapsesToDendrite, updateFlag] = getBestMatchingCell (j, i);

    % if the column is shared between two time instant, use the location
    % chosen earlier.
    if (updateFlag && (newSynapsesToDendrite < 0)) % i.e. add new dendrite
        xJ = find (cellColPrev == j);
        if xJ       
            cellChosen = cellIDPrevious(xJ(1));  % pick only one, if multiple
        end
    end
    SM.cellLearn(cellChosen) = 1;
    if (updateFlag)
        nDCells = nDCells + 1;
        dCells (nDCells) = cellChosen;
        expandDendrites (nDCells) = newSynapsesToDendrite;
    end
end

addDendrites (dCells, expandDendrites, nDCells);

end
%%
function [chosenCell, addNewSynapsesToDendrite, updateFlag]  = getBestMatchingCell (j, i)
% i could be a vector - is the list of active cells (could be bursting) in the column, j.
%
% getBestMatchingCell - For the given column, return the cell with the best matching segment (as defined below).
% If no cell has a matching segment, then return a cell with the fewest number of segments using a
% random tiebreaker.

% Best matching segment - For the given column j cells i, find the segment with the largest number of ACTIVE
% synapses. This routine is aggressive in finding the best match. The permanence value of
% synapses is ALLOWED to be below connectedPerm. The number of active synapses is allowed to
% be below activationThreshold, but must be above minThreshold. The routine returns the
% segment index. If no segments are found, then an index of -1 is returned.

% we can have  one active cell -- choose it to a potential synapse for next cycle
% can more than one active cell -- choose the "best" active cell -- the one with maximum positive dentritic connection.
% can have bursting column with or without any dendrities, e.g. at the start of a new
% sequence, randomly choose one -- this will also be an anchor for a new dendrite.

global SM;

cellIndex = sub2ind([SM.M SM.N], i, j*ones(size(i))); % can be a vector
dendrites = ismember (SM.dendriteToCell, cellIndex);
dendrites = find(dendrites);
lcChosen = false;
addNewSynapsesToDendrite = -1;
updateFlag = false;
%fprintf (1, '\n dendrite list for column %d: %s', j, sprintf('%d ', dendrites));

% % which of the dendrites connected to active cells are also predicted for learning
% % Of these, pick the one with maximum positive value from these.
% pLearn = SM.dendriteLearn(dendrites);
% dendritesL = dendrites(logical(pLearn));
% if (dendritesL)
%     [val, id] = max(SM.dendritePositive(dendritesL));
%     if (val > SM.minPositiveThreshold)
%         chosenCell = SM.dendriteToCell(dendritesL(id));
%         lcChosen = true;
%     end;    
%     % if no learning dendrite found, then the one with maximum positive value.
% else
    if (dendrites)
        [val, id] = max(SM.dendritePositive(dendrites));
        if (val > SM.minPositiveThreshold)
            chosenCell = SM.dendriteToCell(dendrites(id));
            lcChosen = true;
            if (val < SM.Theta) 
                addNewSynapsesToDendrite = dendrites(id); 
                updateFlag = true;
            end
        end
        %fprintf (1, '\n Chosen dendrite %d at %d with %d dendrite strength', dendrites(id), chosenCell, nonzeros(val));
    end
%end

% if no dendrites of the active cells are above minimum threshold add new
% dendrite
if (lcChosen == false)
    % randomly choose location to add a dendrite.
    [val, id] = sort(SM.numDendritesPerCell(cellIndex), 'ascend');
    tie = (val == val(1));     rid = randi(sum(tie));
    chosenCell = cellIndex(id(rid));
    updateFlag = true;
%    fprintf(1, '\n Chosen dendrite (random) for cell at: %d with %d dendrites', chosenCell, nonzeros(val(rid)));
end
end

