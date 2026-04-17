function [t_windowed, y_windowed, Fs] = AuxFcn_GetWindowedSignal_000( ...
    testSignalTensor, validNSamples, fsByTest, testIdx, chIdx, window, convertPressureToKPa)
% AuxFcn_GetWindowedSignal_000
% Extract one test/channel signal and apply a time window.
%
% Inputs:
%   testSignalTensor       (test, column, sample), column 1=time, 2..=channels
%   validNSamples          vector with valid sample count per test
%   fsByTest               vector with sampling frequency per test [Hz]
%   testIdx                selected test index (1-based)
%   chIdx                  selected channel index (1-based, Y[0] => 1)
%   window                 [tStart, tEnd] in seconds
%   convertPressureToKPa   optional logical, default true
%
% Outputs:
%   t_windowed             windowed time vector [s]
%   y_windowed             windowed signal vector (kPa for channels 1..3 if enabled)
%   Fs                     sampling frequency [Hz]

    if nargin < 7 || isempty(convertPressureToKPa)
        convertPressureToKPa = true;
    end

    nTests = size(testSignalTensor, 1);
    nCols = size(testSignalTensor, 2);

    assert(testIdx >= 1 && testIdx <= nTests, 'testIdx must be in [1, %d].', nTests);
    assert(chIdx >= 1 && (1 + chIdx) <= nCols, ...
        'chIdx=%d out of range for tensor with %d data columns.', chIdx, nCols - 1);
    assert(testIdx <= numel(validNSamples), ...
        'validNSamples does not contain entry for testIdx=%d.', testIdx);
    assert(testIdx <= numel(fsByTest), ...
        'fsByTest does not contain entry for testIdx=%d.', testIdx);
    assert(numel(window) == 2 && window(1) < window(2), ...
        'window must be [tStart, tEnd] with tStart < tEnd.');

    t_full = squeeze(testSignalTensor(testIdx, 1, 1:validNSamples(testIdx)));
    y_full = squeeze(testSignalTensor(testIdx, 1 + chIdx, 1:validNSamples(testIdx)));

    if convertPressureToKPa && chIdx <= 3
        y_full = y_full * 100; % Pressure channels to [kPa]
    end

    idxWindow = t_full >= window(1) & t_full <= window(2);
    assert(any(idxWindow), 'No samples found in Window [%.3f, %.3f] s.', window(1), window(2));

    t_windowed = t_full(idxWindow);
    y_windowed = y_full(idxWindow);
    Fs = fsByTest(testIdx);
end
