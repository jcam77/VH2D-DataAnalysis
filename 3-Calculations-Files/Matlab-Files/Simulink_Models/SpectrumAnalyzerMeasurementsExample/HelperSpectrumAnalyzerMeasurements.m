function HelperSpectrumAnalyzerMeasurements(command)
%HelperSpectrumAnalyzerMeasurement show/hide various windows for 
% the SpectrumAnalyzerMeasurementsExample.
%
% This function HelperSpectrumAnalyzerMeasurement is only in
% support of SpectrumAnalyzerMeasurementsExample.
% It may be removed or change in a future release.

% Copyright 2013-2021 The MathWorks, Inc.
switch command
  case 'openModel'
    open_system('SpectrumAnalyzerMeasurements');
    HelperSpectrumAnalyzerMeasurements('closePlots');
  case 'closePlots'
    close_system('SpectrumAnalyzerMeasurements/Spectrogram');
    close_system('SpectrumAnalyzerMeasurements/Peak Finder');
    close_system('SpectrumAnalyzerMeasurements/ACPR');
    close_system('SpectrumAnalyzerMeasurements/Intermodulation Distortion');
    close_system('SpectrumAnalyzerMeasurements/Harmonic Distortion');
    pause(1); % wait for all scopes to close
  case 'openAmplifier'
    open_system('SpectrumAnalyzerMeasurements/Amplifier1','force');
  case 'runModel'
    set_param('SpectrumAnalyzerMeasurements','StopTime','0.01');
    sim('SpectrumAnalyzerMeasurements');
    set_param('SpectrumAnalyzerMeasurements','StopTime','Inf');
    HelperSpectrumAnalyzerMeasurements('closePlots');
  case 'showHarmonicDistortion'
    openForPublish('SpectrumAnalyzerMeasurements/Harmonic Distortion');    
  case 'showIntermodulationDistortion'
    openForPublish('SpectrumAnalyzerMeasurements/Intermodulation Distortion');
  case 'showACPR'
    openForPublish('SpectrumAnalyzerMeasurements/ACPR');
  case 'showSpectrogram'
    openForPublish('SpectrumAnalyzerMeasurements/Spectrogram');
  case 'showPeakFinder'
    openForPublish('SpectrumAnalyzerMeasurements/Peak Finder');
  case 'closeModel'
    close_system('SpectrumAnalyzerMeasurements',0);
end

function openForPublish(blk)
HelperSpectrumAnalyzerMeasurements('closePlots'); % Close all other plots
open_system(blk,'force'); % Open the current block
