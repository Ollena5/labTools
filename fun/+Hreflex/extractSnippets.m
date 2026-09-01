function [snippets,timesSnippet] = extractSnippets(indsPeaks,rawEMG,GRFz)
%EXTRACTSNIPPETS Extract H-reflex and optional GRF snippets for plotting.
%
%   Extract snippets of the H-reflex from the muscle raw EMG signal based
% on stimulation artifact peak alignment. Optionally, extract ground
% reaction force (GRF) snippets for visualizing if stimulation occurs
% during single stance.
%
% Inputs:
%   indsPeaks - 2-element cell of number of peaks x 1 arrays of the
%               stimulation artifact peak indices found by the algorithm
%   rawEMG    - 2-element cell of number of samples x 1 arrays for right
%               (cell 1) and left (cell 2) leg EMG signal (if one cell is
%               empty, that leg is skipped)
%
% Optional Name-Value Inputs:
%   GRFz - 2-element cell of number of samples x 1 arrays for right
%          (cell 1) and left (cell 2) treadmill force plate z-axis GRFs
%          (default: {[], []})
%
% Outputs:
%   snippets     - 2 x 3 cell of number of stimuli x number of samples
%                  arrays for right (row 1) and left (row 2) leg H-reflex
%                  (col 1), ipsilateral (col 2), and contralateral (col 3)
%                  GRF snippets
%   timesSnippet - number of samples x 1 array of relative time in seconds
%                  (t=0 is stimulation artifact peak alignment)
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.COMPUTEAMPLITUDES, HREFLEX.PLOTSNIPPETS,
%   COMPUTEHREFLEXPARAMETERS.

arguments
    indsPeaks cell
    rawEMG    cell
    options.GRFz cell = {[], []}
end

if all(cellfun(@isempty,indsPeaks)) || all(cellfun(@isempty,rawEMG))
    error('Critical data missing for extracting the H-reflex snippets.');
end

% NOTE: should always be same across trials and should be same for forces
% TODO: make optional input argument?
% parameters for snippet extraction
period = 0.0005;                        % sampling period (seconds)
snipStart = -0.005;                     % include 5 ms before artifact peak
snipEnd = 0.055;                        % include 55 ms after artifact peak
timesSnippet = snipStart:period:snipEnd;% snippet sample times for plotting
numSamps = numel(timesSnippet);         % number of samples in EMG snippet

% initialize the snippets cell array to be populated by extraction
numStim = cellfun(@length,indsPeaks);   % number of stimuli for each leg
% store right (row 1) and left (row 2) leg H-reflex (col 1), ipsilateral
% (col 2) and contralateral (col 3) GRF snippets for plotting
snippets = cell(2,3);                   % store snippets for each leg
for leg = 1:2                           % for right and left leg, ...
    snippets{leg,1} = nan(numStim(leg),numSamps);   % EMG snippets
    snippets{leg,2} = nan(numStim(leg),numSamps);   % ipsilateral GRF
    snippets{leg,3} = nan(numStim(leg),numSamps);   % contralateral GRF
end

for leg = 1:2                           % for right and left leg, ...
    if isempty(indsPeaks{leg}) || isempty(rawEMG{leg})
        continue;                       % advance to next leg
    end
    snippets(leg,:) = extractSnippetsLeg(indsPeaks{leg},rawEMG{leg},GRFz,leg,numSamps,snipStart,snipEnd,period);
end

end

function snipCell = extractSnippetsLeg(indsPeaks,EMG,GRFz,leg, ...
    numSamples,snipStart,snipEnd,period)
%% Helper Functions

numStim = numel(indsPeaks);             % number of stimuli for current leg
snipEMG = nan(numStim,numSamples);      % EMG snippets
snipIpsi = nan(numStim,numSamples);     % ipsilateral GRFz snippets
snipContra = nan(numStim,numSamples);   % contralateral GRFz snippets
%EXTRACTSNIPPETSLEG Extract EMG and GRF snippets for a single leg.
%
%   Loop over each provided stimulus index, extract the window relative to
% the index, and fill any out-of-bound positions with NaN.
%
% Inputs:
%   indsPeaks  - number of stimuli x 1 array of artifact peak indices
%   EMG        - number of samples x 1 array of raw EMG signal
%   GRFz       - 2-element cell of ipsilateral and contralateral GRFz
%   leg        - leg index: 1 = right, 2 = left
%   numSamples - number of samples per snippet
%   snipStart  - snippet start time relative to peak (s)
%   snipEnd    - snippet end time relative to peak (s)
%   period     - sampling period (s)
%
% Outputs:
%   snipCell - 1 x 3 cell: {EMG snippets, ipsilateral GRF, contralateral GRF}
%
% Toolbox Dependencies:
%   None

for st = 1:numStim                      % for each stimulus, ...
    win = (indsPeaks(st) + round(snipStart / period)) : ...
        (indsPeaks(st) + round(snipEnd / period));      % snippet window
    % create a temporary array for the snippet filled with 'NaN'
    temp = nan(1,numSamples);
    % determine valid indices within bounds for EMG
    valid = (win >= 1) & (win <= numel(EMG));
    if any(valid)                       % if any data within bounds, ...
        temp(valid) = EMG(win(valid));  % H-reflex snippet
    end
    snipEMG(st,:) = temp;

    if ~isempty(GRFz{leg})              % if GRFz data available, ...
        temp = nan(1,numSamples);
        valid = (win >= 1) & (win <= numel(GRFz{leg}));
        if any(valid)
            temp(valid) = GRFz{leg}(win(valid));        % ipsilateral GRFz
        end
        snipIpsi(st,:) = temp;
    end

    legContra = 3 - leg;                % contralat. index (1 -> 2, 2 -> 1)
    if ~isempty(GRFz{legContra})        % if GRFz data available, ...
        temp = nan(1,numSamples);
        valid = (win >= 1) & (win <= numel(GRFz{legContra}));
        if any(valid)
            temp(valid) = GRFz{legContra}(win(valid));  % contralateral GRF
        end
        snipContra(st,:) = temp;
    end
end

% return as a cell array [EMG, Ipsilateral GRF, Contralateral GRF]
snipCell = {snipEMG,snipIpsi,snipContra};

end

