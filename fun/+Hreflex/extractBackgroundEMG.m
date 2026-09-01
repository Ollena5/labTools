function snippets = extractBackgroundEMG(inds, rawEMG, options)
%EXTRACTBACKGROUNDEMG Extract background EMG snippets before given indices.
%
%   Extract the snippets of the background EMG from the muscle signal
% before the indices provided.
%
% Inputs:
%   inds   - 2-element cell of number of indices x 1 arrays of the
%            indices for which to determine background EMG
%   rawEMG - 2-element cell of number of samples x 1 arrays for right
%            (cell 1) and left (cell 2) leg EMG signal (if one cell is
%            empty, that leg is skipped)
%
% Optional Name-Value Inputs:
%   dur           - background window duration, s (default: 0.050)
%   numSampsBefore - cell of number of samples to skip before each
%                    index; one cell per leg matching size of inds
%                    (default: zeros, i.e., start window immediately
%                    before each index)
%
% Outputs:
%   snippets - 2 x 1 cell of number of indices x number of samples
%              arrays for right (row 1) and left (row 2) leg
%              background EMG
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.EXTRACTSNIPPETS, COMPUTEHREFLEXPARAMETERS.

arguments
    inds   cell
    rawEMG cell
    options.dur           (1,1) double {mustBePositive} = 0.050 % s
    options.numSampsBefore        = []
end

if all(cellfun(@isempty, inds)) || all(cellfun(@isempty, rawEMG))
    error('Missing critical data for extracting background EMG.');
end

%% Resolve Optional Parameters
dur = options.dur;
if isempty(options.numSampsBefore)
    numSampsBefore = cellfun(@(x) zeros(size(x)), inds, ...
        'UniformOutput', false);
else
    numSampsBefore = options.numSampsBefore;
end

%% Compute Snippet Parameters
% NOTE: assuming sampling period remains constant
period    = 0.0005;                     % sampling period (seconds)
numSamps  = round(dur / period);        % number of samples in the window
snippets  = cell(2, 1);                 % preallocate output cell array

%% Extract Background EMG for Each Leg
for leg = 1:2                           % for right and left leg, ...
    if isempty(inds{leg}) || isempty(rawEMG{leg})   % if missing data, ...
        snippets{leg} = [];             % return empty array
        continue;                       % advance to next leg
    end

    numInds  = numel(inds{leg});        % number of indices for current leg
    snipLeg  = nan(numInds, numSamps);  % initialize snippet array for leg
    for ii = 1:numInds                  % for each index, ...
        numSkip = numSampsBefore{leg}(ii);  % number of samples to skip
        % relative window start and end index
        relStart = -numSamps - numSkip + 1;
        relEnd   = -numSkip;
        win = (inds{leg}(ii) + relStart):(inds{leg}(ii) + relEnd);
        % check boundaries: if window exceeds signal limits, fill with NaN
        valid = (win >= 1) & (win <= numel(rawEMG{leg}));
        temp = nan(1, numSamps);        % preallocate temporary snippets
        if any(valid)
            temp(valid) = rawEMG{leg}(win(valid));
        end
        snipLeg(ii, :) = temp;
    end
    snippets{leg} = snipLeg;
end

end
