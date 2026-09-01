function [indsStimArtifact, isWeakArtifact] = ...
    extractStimArtifactIndsFromTrigger(times, rawEMGArtifact, ...
    pinHreflexStim, options)
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

arguments
    times             (:,1) double
    rawEMGArtifact    cell
    pinHreflexStim    cell
    options.threshStim      (1,1) double {mustBePositive} = 2.5   % V
    options.winDurStim      (1,1) double {mustBePositive} = 0.1   % s
    options.minArtifactPeak (1,1) double {mustBePositive} = 0.001 % V
end

if isempty(times) || all(cellfun(@isempty, rawEMGArtifact)) || ...
        all(cellfun(@isempty, pinHreflexStim))
    error(['There is data missing that is crucial for computing the ' ...
        'stimulation artifact indices']);
end

% NOTE: it does not work to use stim trigger pulse to retrieve peak times
% if stimulator is disabled during trial (because there will be a trigger
% pulse but the participant will not have been stimulated); such stimuli
% are flagged in isWeakArtifact rather than silently mislocalized

%% Identify Stimulation Onset Times
stimTimeRAbs = getStimOnsetTimes( ...
    pinHreflexStim{1}, times, options.threshStim);
stimTimeLAbs = getStimOnsetTimes( ...
    pinHreflexStim{2}, times, options.threshStim);

%% Localize Artifact Peaks in EMG Signal
indsStimArtifact = cell(2, 1);
isWeakArtifact   = cell(2, 1);
[indsStimArtifact{1}, isWeakArtifact{1}] = findStimArtifactInds( ...
    times, rawEMGArtifact{1}, stimTimeRAbs, options.winDurStim, ...
    options.minArtifactPeak);
[indsStimArtifact{2}, isWeakArtifact{2}] = findStimArtifactInds( ...
    times, rawEMGArtifact{2}, stimTimeLAbs, options.winDurStim, ...
    options.minArtifactPeak);

%% Warn About Stimuli With a Weak Artifact
labelsLegs = {'right', 'left'};
for leg = 1:2                               % for each leg, ...
    numWeak = sum(isWeakArtifact{leg});
    if numWeak > 0                          % if any weak artifact, ...
        warning('Hreflex:weakStimArtifact', ...
            ['%d of %d %s leg stimuli have a peak artifact ' ...
            'deflection below %.4f V. Verify the stimulator was ' ...
            'enabled and the electrodes attached.'], numWeak, ...
            numel(isWeakArtifact{leg}), labelsLegs{leg}, ...
            options.minArtifactPeak);
    end
end

end

%% Helper Functions

function stimTimes = getStimOnsetTimes(stimTrig, times, threshStim)
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

function [indsStimArtifact, isWeakArtifact] = findStimArtifactInds( ...
    times, rawEMG, stimTimes, winDurStim, minPeakHeight)
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
    indsStimArtifact = [];                  % return empty arrays
    isWeakArtifact   = [];
    return;
end

period = mean(diff(times));                 % sampling period
winSamples = round(winDurStim / period);    % search window dur. in samples
numStim = numel(stimTimes);                 % number of stimuli
indsStimArtifact = nan(numStim, 1);         % initialize array of indices
isWeakArtifact = false(numStim, 1);         % initialize QC flag array

for st = 1:numStim                          % for each stimulus, ...
    % locate EMG data index corresponding to onset of stim trigger pulse
    [~, indStim] = min(abs(times - stimTimes(st)));
    % ensure window does not exceed EMG data in case stim near trial end
    winSearch = max(1, indStim - winSamples): ...   % search window around
        min(length(rawEMG), indStim + winSamples);  % stimulation time
    segment = rawEMG(winSearch);
    % deflection from the window median, ignoring artifact polarity
    deflection = abs(segment - median(segment, 'omitnan'));
    [peakDeflection, indPeak] = max(deflection, [], 'omitnan');

    indsStimArtifact(st) = winSearch(indPeak);
    isWeakArtifact(st)   = peakDeflection < minPeakHeight;
end

end
