function T = tidyFromArray(dataStruct, axisNames, axisValues)
%TIDYFROMARRAY Convert per-condition result arrays into a long-format table.
%
%   T = tidyFromArray(dataStruct, axisNames, axisValues)
%
% dataStruct  struct whose fields are result arrays, all of the same size
%             [n1 n2 ... nd]
% axisNames   1xd cellstr naming each dimension, e.g.
%             {'seed','method','N','scenario'}
% axisValues  1xd cell; element k is either a numeric vector or a cellstr
%             of length nk giving the label of each level along dimension k
%
% Returns a table with prod(nk) rows: one column per axis followed by one
% column per field of dataStruct.
%
% Example
%   T = tidyFromArray( ...
%           struct('RMSE',RMSE,'AOI',AOI), ...
%           {'seed','method','scenario'}, ...
%           {1:numSeeds, methodNames, scenarioNames});
%
% Every experiment in this project stores seed in dimension 1 followed by
% the sweep axes in declaration order, so the same call shape works
% throughout.

if ~isstruct(dataStruct)
    error('tidyFromArray:badData','dataStruct must be a struct.');
end

if numel(axisNames) ~= numel(axisValues)
    error('tidyFromArray:axisMismatch', ...
        'axisNames (%d) and axisValues (%d) must have the same length.', ...
        numel(axisNames), numel(axisValues));
end


d  = numel(axisNames);
sz = zeros(1,d);

for k = 1:d
    sz(k) = numel(axisValues{k});
end

nRows = prod(sz);


%% ============================================================
% Index grids
% ============================================================

if d == 1

    idxGrids = {(1:sz(1))'};

else

    ranges = cell(1,d);

    for k = 1:d
        ranges{k} = (1:sz(k))';
    end

    idxGrids = cell(1,d);

    [idxGrids{:}] = ndgrid(ranges{:});

end


%% ============================================================
% Axis columns
% ============================================================

T = table();

for k = 1:d

    lin = idxGrids{k}(:);

    vals = axisValues{k};

    colName = matlab.lang.makeValidName(axisNames{k});

    % Force a column before indexing. Indexing a ROW vector with a
    % column index returns a row in MATLAB, which would not match the
    % table height.
    vals = vals(:);

    if iscell(vals) || isstring(vals)
        vals = cellstr(vals);
    end

    T.(colName) = vals(lin);

end


%% ============================================================
% Data columns
% ============================================================

fields = fieldnames(dataStruct);

for iF = 1:numel(fields)

    name = fields{iF};

    A = dataStruct.(name);

    if numel(A) ~= nRows
        error('tidyFromArray:sizeMismatch', ...
            ['Field "%s" has %d elements but the axes describe %d ' ...
             'conditions (%s).'], ...
            name, numel(A), nRows, mat2str(sz));
    end

    if islogical(A)
        A = double(A);
    end

    T.(matlab.lang.makeValidName(name)) = A(:);

end

end
