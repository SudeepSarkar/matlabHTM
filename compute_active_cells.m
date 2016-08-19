function anomalyScore = compute_active_cells (sdr)
% Given the input (sdr), this function (i) computes the active cells in the sequence memory array,
% basically, all predicted cell in an active column (column with 1 as input) is active.
% and all cells in an active column with no predicted cells are active; (ii) marks the appropriate
% cells for future learning using the SM.learnFlag tag array, and (iii) outputs an anomaly score.
%
% The anomalyScore computation is based on description at
% https://github.com/numenta/nupic/wiki/Anomaly-Detection-and-Anomaly-Scores
% using actual predictions rather than "confidences" as stated on the
% website. (NOTE: I am not sure what column "confidences" mean -- FUTURE MODIFICATION)

%% The following has NOT been implemented
% http://chetansurpur.com/slides/2014/5/4/cla-in-nupic.html#42
% At the beginning of a sequence we stay in "Pay Attention Mode" for a number of timesteps (relevant parameter: pamLength)
% When we are in PAM, we do not burst unpredicted columns during learning
% If new sequence, turn on "start cell" (the first one) for every active column
%
%   1.  If new sequence, turn on "start cell" (the first one) for every active column
%   2.  Otherwise, turn on any predicted cells in every active column
%   3.  If no predicted cells in a column, turn on every cell in the column



global SM

%% Find the index of the active input columns

[columnInput] = find(sdr);


%% Find index (row and col) of the predicted cells, i.e. cells in polarized state as stored in the
% 2D sparse array SM.CellPredicted. Note the lengths of the rowPredicted and colPredicted
% vectors is equal to the number of polarized cells. Any particular column or row index can occur
% multiple times in the vector.

[rowPredicted, columnPredicted] = find (SM.CellPredicted);

%% Find the index of the active input columns

[columnInput] = find(sdr);

%% Reset active cell array and the array that keeps track of the cells whose dendrites will be
% reinforced during learning.

SM.CellActive (:) = 0;
SM.learnFlag (:) = 0;
anomalyScore = 1;

%% Set correctly predicted cells to active state

% finds which of the predicted columns are active input columns — note that the predicted column
% indices are indexed by the predicted cells and we can have more than one predicted cell in any
% column or row. So, any particular column index can occur multiple times in the vector.

selectColumns = (ismember (columnPredicted, columnInput)); % note — this is a logical array



% selects the predicted row and column of the correctly predicted cells based on the "logical"
% array passed

correctRows = rowPredicted(selectColumns);
correctColumns = columnPredicted(selectColumns);

% compute the linear index from the above row and column indices and set the active and learning
% tags for these cells.
% tag of 1 - means that the dendrites of the cell will be reinforced.
% QUESTION: --� All connected dendrites reinforced? NEED TO CHECK THIS. no

linearIndex = sub2ind(size(SM.CellActive), correctRows, correctColumns);
SM.CellActive (linearIndex) = 1;
SM.CellActiveLearn (linearIndex) = 1;
SM.learnFlag (linearIndex) = 1;

%% Update temporal pooled vector - set the index of the correctly predicted columns to 1

uniqueCorrectColumns = unique(correctColumns);
%tpArray (tpIndex, uniqueCorrectColumns) = 1;

%% Compute anomaly score — differences of the ones in the input and the correctly predicted ones
%% THIS CAN BE EXPERIMENTED WITH AND UPDATED

anomalyScore = (length(columnInput) - length (uniqueCorrectColumns))/length(columnInput);


% The following uses the tip at http://floybix.github.io/2016/07/01/attempting-nab
% Instead of the raw bursting rate, a delta anomaly score was calculated:
% it considers only newly active columns (ignoring any remaining active from the previous timestep).
% The bursting rate is calculated only within these new columns. To handle small changes,
% the number of columns considered ? i.e. divided by ? is kept from falling below 20% of the total number
% of active columns (20% of 40 = 8).
% (number-of-newly-active-columns-that-are-bursting) /
% max(0.2 * number-of-active-columns, number-of-newly-active-columns)

% newlyActiveColumns = setdiff (find(SM.InputPrevious), columnInput);
% 
% newlyActiveColumnsCorrect = intersect(uniqueCorrectColumns, newlyActiveColumns);
% 
% anomalyScore = (length(newlyActiveColumns) - length (newlyActiveColumnsCorrect))/...
%     max (0.2*length(columnInput), length(newlyActiveColumns));

%% Tag wrongly predicted cells -- used during learning.

% (true, false) array that marks the wrongly predicted cells without a corresponding active input
selectColumns = ~selectColumns;

% wrongly predicted cell indices.
wrongRows = rowPredicted(selectColumns);
wrongColumns = columnPredicted(selectColumns);
linearIndex = sub2ind(size(SM.CellActive), wrongRows, wrongColumns);

% set corresponding learn flag to 3 — all dendrites of these cells will be deemphasized.

SM.learnFlag (linearIndex) = 3;


%% Burst the cells in the columns with no prediction but active input

SM.burstColumns = setdiff (columnInput, uniqueCorrectColumns);
SM.CellActive (1:SM.M, SM.burstColumns) = 1;




