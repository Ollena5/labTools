function fig = plotNoiseHistogram(amplitudesNoise,leg,id,trialNum,pathFig)
%PLOTNOISEHISTOGRAM Plot the noise amplitude distribution for the H-reflex.
%
%   Plot the H-reflex noise distribution histogram for a single leg.
%
% Inputs:
%   amplitudesNoise - 1 x number of stimuli array of noise amplitudes (mV)
%   leg             - 'Right Leg' or 'Left Leg'
%   id              - string or character array of participant/session ID
%   trialNum        - string or character array of the trial number
%
% Optional Name-Value Inputs:
%   pathFig - path for saving figures; not saved if empty (default: '')
%
% Outputs:
%   fig - handle to the figure generated
%
% Toolbox Dependencies:
%   None
%
% See also HREFLEX.PLOTCAL, GENERATEHREFLEXRECRUITMENTCURVES.

arguments
    amplitudesNoise (1,:) double
    leg             (1,:) {mustBeText}
    id              (1,:) {mustBeText}
    trialNum        (1,:) {mustBeText}
    options.pathFig (1,:) char = ''
end

noiseMean = mean(amplitudesNoise);      % mean of all noise amplitudes
noiseMed = median(amplitudesNoise);     % median
noise75 = prctile(amplitudesNoise,75);  % 75th percentile

fig = figure;                           % create a figure
hold on;
histogram(amplitudesNoise,0.00:0.05:0.30,'Normalization','probability');
xline(noiseMean,'r',sprintf('Mean = %.2f mV',noiseMean),'LineWidth',2);
xline(noiseMed,'g',sprintf('Median = %.2f mV',noiseMed),'LineWidth',2);
xline(noise75,'k',sprintf('75^{th} Percentile = %.2f mV',noise75), ...
    'LineWidth',2);
hold off;
axis([0 0.3 0 0.8]);
xlabel('Noise Amplitude Peak-to-Peak (mV)');
ylabel('Proportion of Stimuli');

txtTitle = sprintf('%s - Trial %s - %s - Noise Distribution', ...
    id,trialNum,leg);
title(txtTitle);

if ~isempty(pathFig)                % if figure saving path provided, ...
    legNoSpace = regexprep(leg,'\s+','');
    % TODO: make figure title and filename optional inputs
    nameFile = fullfile(pathFig,sprintf( ...
        '%s_NoiseDistribution_Trial%s_%s',id,trialNum,legNoSpace));
    saveas(fig,nameFile + ".png");  % save figure
    saveas(fig,nameFile + ".fig");  % TODO: just use 'fullfile' if readable
end

end

