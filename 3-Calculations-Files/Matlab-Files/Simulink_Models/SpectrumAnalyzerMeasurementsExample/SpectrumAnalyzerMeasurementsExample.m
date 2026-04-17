%% Spectrum Analyzer Measurements
% This example shows you how to use the Spectrum Analyzer block for
% harmonic distortion measurements (such as THD, SNR, SINAD, and SFDR), 
% third-order intermodulation (TOI) distortion measurements, and adjacent
% channel power ratio (ACPR) measurements. The example also shows you how
% to view time-varying spectra by using a spectrogram and automatic peak
% detection. The example includes five amplifier models, with each model
% representing a typical setup to perform one of the measurements. 

%%
% The |SpectrumAnalyzerMeasurements| example can be opened
% from the open button.
%
HelperSpectrumAnalyzerMeasurements('openModel');

%% Exploring the Example
% Open the |SpectrumAnalyzerMeasurements| example model by clicking on the
% open model button. Open the first amplifier model by double-clicking the
% Amplifier1 block.

HelperSpectrumAnalyzerMeasurements('openAmplifier');

%%
% In this model, you first combine the input with a Gaussian noise source
% and then run it through a high-order polynomial to model nonlinear
% distortion.
%
% You can modify the amount of additive noise on the input by clicking
% the Noise Source block and modifying the variance of the Gaussian distribution.
%
% You can modify the parameters of the amplifier by changing the polynomial
% coefficients.  The coefficients are arranged in descending
% order.  If you edit the last coefficient, you change the DC voltage offset
% of the amplifier.  If you change the second to last coefficient, you change
% the voltage gain of the amplifier.  If you change other coefficients, you
% can change the higher-order harmonics of the amplifier.

%% Harmonic Distortion
% You can measure harmonic distortion by stimulating the amplifier with a
% sinusoidal input and viewing the harmonics in a spectrum analyzer.
% You can access the harmonic distortion measurements from the Measurements
% tab. In the distortion section, click the Distortion icon in order
% to show the measurements.

HelperSpectrumAnalyzerMeasurements('runModel');
HelperSpectrumAnalyzerMeasurements('showHarmonicDistortion');

%%
% In the Distortion panel, you can see the
% amplitudes of the fundamental frequencies and the harmonics as
% well as their SNR, SINAD, THD and SFDR values, which are referenced to
% the fundamental output power.

%% TOI Distortion
% Amplifiers typically have significant odd-order harmonics.  If you
% stimulate the amplifier with two closely spaced sinusoids of equal
% amplitude, you can produce intermodulation products at the output.
% Typically, the distortion products decay away from the fundamental tones,
% the largest of which correspond to the third-order sum and difference
% frequencies of the input waveform.  You can measure output (TOI)
% distortion by selecting "Intermodulation" from the Distortion Type drop-down menu.

HelperSpectrumAnalyzerMeasurements('showIntermodulationDistortion');

%%
% In the *Distortion Measurement* panel, you can see that the intermodulation
% products are highlighted and you can also view the output TOI. Adjust the 
% polynomial coefficients in the amplifier to change the harmonics shown
% in the signal.

%% ACPR
% If you stimulate an amplifier that is broadcasting a communications
% channel, you can see spectral growth leaking into the bandwidth of the
% neighboring channels due to intermodulation distortion. You can measure
% how much power leaks into these adjacent channels by measuring the
% ACPR. You can view the measurements
% before and after stimulating the amplifier by toggling the measurement 
% input in the channel section of the Channel Measurements tab.
% You can select the ACPR measurements from the
% drop-down menu in the Channel Measurements section. You can display the
% Channel Measurements by clicking the icon.

HelperSpectrumAnalyzerMeasurements('showACPR');

%%
% Adjust the polynomial coefficients in the amplifier to obtain different
% amounts of spreading of the central power due to intermodulation
% distortion. You can observe the ACPR readings at the specified offset
% frequencies.

%%
% The image shows approximately 0.5 dB of compression
% between the input source (blue trace) and the output of Amplifier3
% (yellow trace). The peak-to-average power ratio (PAPR) for the input
% channel is 3.3 dB whereas the PAPR for the output channel is 2.8 dB. This
% loss of dynamic range suggests that there is too much input power applied
% to the amplifier.

%% Spectrogram
% You can view time-varying spectral information by using the Spectrogram
% Mode of the spectrum analyzer. If you stimulate the amplifier with a
% chirp waveform you can observe how the harmonics behave as time
% progresses. In the *Scope* tab, select the *Spectrogram* button.

HelperSpectrumAnalyzerMeasurements('showSpectrogram');

%%
% You can use cursors to measure the period of the chirp and
% to confirm that the other spectral components are harmonically related.

%% Peak Finder
% You can track time-varying spectral components by using the Peaks section
% under the Measurements tab.  You can show and optionally label up to 100 peaks.
% You can access the Peak Finder dialog box from the
% Measurements tab in the toolstrip.
HelperSpectrumAnalyzerMeasurements('showPeakFinder');

%%
HelperSpectrumAnalyzerMeasurements('closeModel');

%% References
% * IEEE Std. 1057-1994 IEEE Standard for Digitizing Waveform Recorders
% * Allan W. Scott, Rex Frobenius, RF Measurements for Cellular Phones and
%   Wireless Data Systems, John Wiley & Sons, Inc. 2008

%%
% Copyright 2013-2023 The MathWorks, Inc.
