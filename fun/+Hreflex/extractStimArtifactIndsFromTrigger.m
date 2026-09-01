function indsStimArtifact = extractStimArtifactIndsFromTrigger(times, ...
    rawEMG_TAP,pinHreflexStim,varargin)
%EXTRACTSTIMARTIFACTINDSFROMTRIGGER Extract stim artifact peak indices.
%
%   Extract the indices of the stimulation artifact peaks in the
% artifact localization muscle EMG signal (normally the proximal
% tibialis anterior, more robust than the calf muscles during walking)
% using the rising edge of the stimulation trigger pulse to localize the
% artifact peak.
%   Within the search window the peak is taken as the largest ABSOLUTE
% deflection from the window median. The artifact is frequently
% negative-dominant (its initial deflection is downward, with a smaller
% positive rebound ~1.5 ms later), so localizing on the signed maximum
% either lands on the rebound or, when the artifact is small, misses it
% entirely. Absolute deflection is polarity agnostic and needs no
% detection threshold, because the window is already anchored to a known
% trigger pulse.
%
% Inputs:
%   times          - number of samples x 1 array of time in seconds from
%                    the start of the trial for each sample
%   rawEMGArtifact - 2-element cell of number of samples x 1 arrays for
%                    right (cell 1) and left (cell 2) artifact
%                    localization muscle EMG (if one cell is empty, that
%                    leg is skipped)
%   pinHreflexStim - 2-element cell of number of samples x 1 arrays for
%                    right (cell 1) and left (cell 2) stim trigger pulses
%
% Optional Name-Value Inputs:
%   threshStim      - stim trigger pulse detection threshold, V
%                     (default: 2.5)
%   winDurStim      - search window duration around trigger pulse, s
%                     (default: 0.1). NOTE: the window must stay wide
%                     enough to span the wireless EMG transmission
%                     delay, which is ~50 ms for the Delsys system.
%   minArtifactPeak - quality control floor for the peak absolute
%                     artifact deflection, V (default: 0.001). A
%                     stimulus below it is still localized but is
%                     flagged in isWeakArtifact and warned about.
%
% Outputs:
%   indsStimArtifact - 2 x 1 cell of number of stimuli x 1 arrays for
%                      right (cell 1) and left (cell 2) stim artifact
%                      indices
%   isWeakArtifact   - 2 x 1 cell of number of stimuli x 1 logical
%                      arrays; true where the peak absolute deflection
%                      was below minArtifactPeak (e.g., a disabled
%                      stimulator or a detached electrode)
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.EXTRACTSNIPPETS, HREFLEX.PLOTSTIMARTIFACTPEAKS,
%   COMPUTEHREFLEXPARAMETERS.


if isempty(times) || all(cellfun(@isempty,rawEMG_TAP)) || ...
        all(cellfun(@isempty,pinHreflexStim))   % validate input arguments
    error(['There is data missing that is crucial for computing the ' ...
        'stimulation artifact indices']);
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is disabled during trial (because there will be a trigger
% pulse but the participant will not have been stimulated)

p = inputParser;        % parse optional inputs
addParameter(p,'threshStim',2.5,@(x) isnumeric(x) && x > 0);
addParameter(p,'winDurStim',0.1,@(x) isnumeric(x) && x > 0);
addParameter(p,'minArtifactPeak',0.001,@(x) isnumeric(x) && x > 0);
parse(p,varargin{:});

threshStim = p.Results.threshStim;  % stim trigger pulse threshold (V)
winDurStim = p.Results.winDurStim;  % +/- 100 ms of stim pulse onset
minPeak = p.Results.minArtifactPeak;% 1 mV min. stim artifact peak height

% get stimulation onset times
stimTimeRAbs = getStimOnsetTimes(pinHreflexStim{1},times,threshStim);
stimTimeLAbs = getStimOnsetTimes(pinHreflexStim{2},times,threshStim);

% convert stimulation times to indices in the EMG signal
indsStimArtifact = cell(2, 1);
indsStimArtifact{1} = findStimArtifactInds(times,rawEMG_TAP{1}, ...
    stimTimeRAbs,winDurStim,minPeak);
indsStimArtifact{2} = findStimArtifactInds(times,rawEMG_TAP{2}, ...
    stimTimeLAbs,winDurStim,minPeak);

end

%% Helper Functions

function stimTimes = getStimOnsetTimes(stimTrig,times,threshStim)
%GETSTIMONSETTIMES Find the times of the stim trigger pulse rising edges.
%
% Inputs:
%   stimTrig   - number of samples x 1 array of stim trigger pulses (V)
%   times      - number of samples x 1 array of time in seconds
%   threshStim - stim trigger pulse detection threshold (V)
%
% Outputs:
%   stimTimes - number of stimuli x 1 array of rising edge times (s)
%
% Toolbox Dependencies:
%   None

% detect rising edges of stimulation trigger pulses
indsStimAll = find(stimTrig > threshStim);
% determine which indices correspond to start of new stimulus pulse
% (i.e., there is jump in index greater than 1, not just next sample)
indsNewPulse = diff([0; indsStimAll]) > 1;      % rising edges
% determine time since trial start when stim pulse began (rising edge)
stimTimes = times(indsStimAll(indsNewPulse));

end

function indsStimArtifact = findStimArtifactInds(times,rawEMG, ...
    stimTimes,winDurStim,minPeakHeight)
%FINDSTIMARTIFACTINDS Locate stim artifact indices around stimulus times.
%
%   For each stimulus, take the sample of largest absolute deflection
% from the window median within +/- winDurStim of the trigger rising
% edge. Absolute deflection is used because the artifact is commonly
% negative-dominant; the window is anchored to a known trigger pulse, so
% the largest deflection within it is the artifact.
%
% Inputs:
%   times         - number of samples x 1 array of time in seconds
%   rawEMG        - number of samples x 1 array of raw EMG signal (V)
%   stimTimes     - number of stimuli x 1 array of stim onset times (s)
%   winDurStim    - search window duration around trigger pulse (s)
%   minPeakHeight - quality control floor for peak deflection (V)
%
% Outputs:
%   indsStimArtifact - number of stimuli x 1 array of artifact indices
%   isWeakArtifact   - number of stimuli x 1 logical array; true where
%                      the peak deflection was below minPeakHeight
%
% Toolbox Dependencies:
%   None

if isempty(rawEMG) || isempty(stimTimes)    % if no EMG or stim data, ...
    indsStimArtifact = [];                  % return empty array
    return;
end

period = mean(diff(times));                 % sampling period
winSamples = round(winDurStim / period);    % search window dur. in samples
numStim = numel(stimTimes);                 % number of stimuli
indsStimArtifact = nan(numStim,1);          % initialize array of indices

for st = 1:numStim                          % for each stimulus, ...
    % locate EMG data index corresponding to onset of stim trigger pulse
    [~,indStim] = min(abs(times - stimTimes(st)));
    % ensure window does not exceed EMG data in case stim near trial end
    winSearch = max(1,indStim - winSamples): ...    % search window around
        min(length(rawEMG),indStim + winSamples);   % stimulation time
    [~,locs] = findpeaks(rawEMG(winSearch),'MinPeakHeight',minPeakHeight);

    if isempty(locs)                        % if no peaks detected, ...
        [~,indMaxTAP] = max(rawEMG(winSearch)); % use maximum value as peak
    else                                    % otherwise, ...
        indMaxTAP = locs(1);                % use first (earliest) peak
    end

    indsStimArtifact(st) = winSearch(indMaxTAP);
end

end

