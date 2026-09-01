function fig = plotStimArtifactPeaks(times,rawEMG_TAP,indsPeaks,id, ...
    trialNum,varargin)
%PLOTSTIMARTIFACTPEAKS Plot located stimulation artifact peaks in EMG.
%
%   Plot the raw EMG trace of the artifact localization muscle (normally
% the proximal tibialis anterior) for each leg with the identified
% stimulation artifact peaks highlighted by a filled triangle, so that
% the experimenter can verify the indices used for H-reflex snippet
% alignment before any amplitude is computed. Peaks flagged as weak by
% HREFLEX.EXTRACTSTIMARTIFACTINDSFROMTRIGGER are drawn distinctly so a
% disabled stimulator or a detached electrode is visible at a glance.
%
% Inputs:
%   times     - number of samples x 1 array of time in seconds from the
%               start of the trial for each sample
%   rawEMG    - 2-element cell of number of samples x 1 arrays for right
%               (cell 1) and left (cell 2) leg artifact localization
%               muscle EMG (if one cell is empty, that leg is not plot)
%   indsPeaks - 2-element cell of number of peaks x 1 arrays of the
%               stimulation artifact peak indices found by the algorithm
%   id        - string or character array of participant/session ID
%   trialNum  - string or character array of the trial number
%
% Optional Name-Value Inputs:
%   thresh  - peak finding threshold (V) to draw as a horizontal line;
%             not drawn if NaN (default: NaN)
%   pathFig - path for saving figures; not saved if empty (default: '')
%   labels  - 2-element cell of tile title strings for the right (cell
%             1) and left (cell 2) leg
%             (default: {'Right TAP', 'Left TAP'})
%   isWeak  - 2-element cell of number of peaks x 1 logical arrays
%             marking peaks whose absolute deflection fell below the
%             quality control floor (default: {[], []}, none flagged)
%
% Outputs:
%   fig - handle object to the figure generated for further customization
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.EXTRACTSTIMARTIFACTINDSFROMTRIGGER,
%   HREFLEX.PLOTSNIPPETS, GENERATEHREFLEXRECRUITMENTCURVES.

arguments
    times     (:,1) double
    rawEMG    cell
    indsPeaks cell
    id        (1,:) {mustBeText}
    trialNum  (1,:) {mustBeText}
    options.thresh  (1,1) double = NaN
    options.pathFig (1,:) char   = ''
    options.labels  cell         = {'Right TAP', 'Left TAP'}
    options.isWeak  cell         = {[], []}
end

if string(version('-release')) < "2019b" % if version older than 2019b, ...
    error(['MATLAB version must support ''tiledlayout'' (R2019b or ' ...
        'later).']);
end

% TODO: add check of correct dimensions for cell arrays
if isempty(times) || all(cellfun(@isempty,rawEMG_TAP)) || ...
        all(cellfun(@isempty,indsPeaks))    % validate input arguments
    error(['There is critical data missing for plotting the EMG ' ...
        'signal with detected artifact peaks.']);
end

numOptArgs = length(varargin);
switch numOptArgs
    case 0
        thresh = nan;               % default to Not-a-Number
        path = '';                  % default to empty
    case 1                          % one optional argument provided
        if isnumeric(varargin{1})   % if a number, ...
            thresh = varargin{1};   % it is the threshold
            path = '';
        else                        % otherwise, ...
            thresh = NaN;
            path = varargin{1};     % it is the file saving path
        end
    case 2                          % both optional arguments provided
        thresh = varargin{1};       % first always stim artifact threshold
        path = varargin{2};         % second always file saving path
    otherwise
        error('Too many optional arguments. Provide at most 2.');
end

numLegs = sum(cellfun(@(x) ~isempty(x),rawEMG_TAP));% number of legs
if numLegs > 2                                      % if more than 2, ...
    error('Input EMG signals must be limited to 2 legs (right and left).');
end

% set the figure to be full screen
fig = figure('Units','normalized','OuterPosition',[0 0 1 1]);
tl = tiledlayout(numLegs,1,'TileSpacing','tight');

labelsLegs = {'Right TAP','Left TAP'};
for leg = 1:2                       % for each leg, ...
    if ~isempty(rawEMG_TAP{leg})    % if EMG data is available, ...
        nexttile;                   % plot signal with detected peaks
        plotSignalWithPeaks(times, rawEMG_TAP{leg}, indsPeaks{leg}, thresh);
        title(labelsLegs(leg));
    end
end

% TODO: should y-axis limits be the same in case of both legs present?
% TODO: consider accepting labels as optional input argument
% global labels and title
xlabel(tl,'Time (s)');
ylabel(tl,'Raw EMG (V)');
title(tl,sprintf( ...
    '%s - Trial %s - Stimulation Artifact Peak Finding',id,trialNum));

if ~isempty(path)   % if figure saving path provided as input argument, ...
    saveFigure(fig,path,id,trialNum);
end

end

function plotSignalWithPeaks(x,y,inds,thresh)
%% Helper Functions

%PLOTSIGNALWITHPEAKS Plot one leg's EMG signal with its detected peaks.
%
%   Plot the raw EMG trace with a filled triangle at each detected
% stimulation artifact peak, drawing any peak flagged as weak in red so
% that it stands out from the accepted peaks.
%
% Inputs:
%   x      - number of samples x 1 array of time in seconds
%   y      - number of samples x 1 array of raw EMG signal (V)
%   inds   - number of peaks x 1 array of artifact peak indices
%   thresh - peak finding threshold (V); not drawn if NaN
%   isWeak - number of peaks x 1 logical array marking weak peaks, or
%            empty if no peak was flagged
%
% Outputs:
%   None
%
% Toolbox Dependencies:
%   None

% TODO: consider moving tile title into this helper function

hold on;
% below code is copied from MATLAB 'findpeaks' function to replicate
hLine = plot(x,y,'Tag','Signal');       % plot signal line
hAxes = ancestor(hLine,'Axes');
grid on;                                % turn on grid
if numel(y) > 1
    hAxes.XLim = hLine.XData([1 end]);  % restrict x-axis limits
end
color = get(hLine,'Color');             % use the color of the line
line(hLine.XData(inds),y(inds),'Parent',hAxes,'Marker','v', ...
    'MarkerFaceColor',color,'LineStyle','none','Color',color,'tag','Peak');
if ~isnan(thresh)                       % if threshold is not NaN, ...
    yline(thresh,'r','Peak Finding Threshold');     % plot it
end
hold off;

end

function saveFigure(fig,path,id,trialNum)
%SAVEFIGURE Save the artifact peak finding figure to disk.
%
%   Save the figure in both PNG and FIG formats using the standard
% participant and trial naming convention.
%
% Inputs:
%   fig      - handle to the figure to save
%   path     - path of the folder in which to save the figure
%   id       - string or character array of participant/session ID
%   trialNum - string or character array of the trial number
%
% Outputs:
%   None
%
% Toolbox Dependencies:
%   None

fileBase = fullfile(path, ...
    sprintf('%s_StimArtifactPeakFinding_Trial%s',id,trialNum));
saveas(fig,[fileBase '.png']);
saveas(fig,[fileBase '.fig']);
end

