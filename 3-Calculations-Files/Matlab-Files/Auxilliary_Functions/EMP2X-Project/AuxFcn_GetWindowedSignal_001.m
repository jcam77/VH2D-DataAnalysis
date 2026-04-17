function [t_windowed, y_windowed, fs] = AuxFcn_GetWindowedSignal_001(daqData, chIdx, window, convertPressure)
% AuxFcn_GetWindowedSignal_001
% Extract a time-windowed signal segment using the standardized daqData structure.
%
% Inputs:
%   daqData         : struct from tests(i).daqs(k).data
%   chIdx           : scalar, selected channel index (1-based)
%   window          : 1x2 numeric vector, [tStart, tEnd] in seconds
%   convertPressure : logical, explicitly set to true to convert pressure to kPa
%
% Outputs:
%   t_windowed      : windowed time vector [s]
%   y_windowed      : windowed signal vector (converted to kPa ONLY if requested and validated)
%   fs              : sampling frequency [Hz]
%
% USAGE EXAMPLES:
%   % 1. Extract raw Trigger voltage (Explicitly set to false)
%   [t, y, fs] = AuxFcn_GetWindowedSignal_001(daqData, 4, [0.5 1.0], false); 
%
%   % 2. Extract Pressure and convert to kPa (Explicitly set to true)
%   [t, y, fs] = AuxFcn_GetWindowedSignal_001(daqData, 1, [0.2 0.4], true);
%
%   % 3. Extracting without the 4th argument (Safety Default: false/raw)
%   [t, y, fs] = AuxFcn_GetWindowedSignal_001(daqData, 2, [0.2 0.4]);
%
% UPDATES in _001:
% - Removed hard-coded "chIdx <= 3" restriction. Data conversion is now dynamic.
% - Default convertPressure is FALSE (No automatic modifications).
% - Uses daqData.channelType to verify ONLY actual pressure sensors are converted.

    % 1. Safety Default: Do not modify the raw data unless explicitly asked
    if nargin < 4 || isempty(convertPressure)
        convertPressure = false; 
    end

    % 2. Validation of inputs and structure
    assert(~isempty(daqData), 'daqData structure is empty.');
    assert(chIdx >= 1 && chIdx <= daqData.nChannels, ...
        'chIdx=%d out of range for DAQ with %d channels.', chIdx, daqData.nChannels);
    assert(numel(window) == 2 && window(1) < window(2), ...
        'window must be [tStart, tEnd] with tStart < tEnd.');

    % 3. Extraction from standardized daqData
    t_full = daqData.t; 
    y_full = daqData.signal(:, chIdx); 

    % 4. Active User Decision for Unit Conversion
    if convertPressure
        % Verify if the channel is actually defined as a pressure sensor via metadata
        if isfield(daqData, 'channelType') && daqData.channelType(chIdx) == "pressure"
            y_full = y_full * 100; % Convert raw sensor value to [kPa] 
        else
            % Protection: if user asks to convert a non-pressure channel, warn and skip
            chName = string(daqData.channelNames(chIdx));
            warning('Channel %d (%s) is not type "pressure". Returning raw data without conversion.', ...
                chIdx, chName); 
        end
    end

    % 5. Time Windowing logic
    idxWindow = t_full >= window(1) & t_full <= window(2);
    if ~any(idxWindow)
        error('No samples found in window [%.3f, %.3f] s.', window(1), window(2));
    end

    t_windowed = t_full(idxWindow);
    y_windowed = y_full(idxWindow);
    fs = daqData.fs; 
end