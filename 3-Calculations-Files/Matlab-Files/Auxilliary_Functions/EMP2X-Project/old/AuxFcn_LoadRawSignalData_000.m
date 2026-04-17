function [rawData, loadedDataSummary] = AuxFcn_LoadRawSignalData_000(rawDataNames)
% AuxFcn_LoadRawSignalData_000
% Load one or more raw overpressure txt files and return a struct array.
%
% Inputs:
%   rawDataNames        char/string/cellstr with txt file names on MATLAB path
%
% Outputs:
%   rawData             struct array with fields:
%                       name, file, dt, fs, tbl, signal, nSamples, nChannels
%   loadedDataSummary   table summary (file index, name, nSamples, dt, fs)

    if nargin < 1 || isempty(rawDataNames)
        error('rawDataNames must contain at least one file name.');
    end
    if isstring(rawDataNames)
        rawDataNames = cellstr(rawDataNames);
    end
    if ischar(rawDataNames)
        rawDataNames = {rawDataNames};
    end

    rawData = struct([]);
    for iFile = 1:numel(rawDataNames)
        thisName = rawDataNames{iFile};
        thisFile = which(thisName);
        assert(~isempty(thisFile), 'Raw data file not found on MATLAB path: %s', thisName);

        % Read DAQ metadata (delta t in seconds) from header without datetime parsing.
        headerLines = readlines(thisFile);
        assert(numel(headerLines) >= 3, 'Unexpected header format in %s', thisName);
        deltaTLine = split(headerLines(3), ';');
        assert(numel(deltaTLine) >= 2, 'Could not parse delta t header in %s', thisName);
        dt_i = str2double(deltaTLine(2));  % [s]
        assert(isfinite(dt_i) && dt_i > 0, 'Invalid delta t value in %s', thisName);
        fs_i = 1 / dt_i;                   % [Hz]

        % Read raw channels (Y[0]..Y[3]).
        opts = delimitedTextImportOptions("NumVariables", 5);
        opts.Delimiter = ';';
        opts.DataLines = [6 Inf];
        opts.VariableNames = ["time", "Y0", "Y1", "Y2", "Y3"];
        opts.VariableTypes = ["string", "double", "double", "double", "double"];
        rawTbl = readtable(thisFile, opts);
        rawSignal = rawTbl{:,2:5};  % Raw DAQ units from txt file

        rawData(iFile).name = thisName;
        rawData(iFile).file = thisFile;
        rawData(iFile).dt = dt_i;
        rawData(iFile).fs = fs_i;
        rawData(iFile).tbl = rawTbl;
        rawData(iFile).signal = rawSignal;
        rawData(iFile).nSamples = size(rawSignal,1);
        rawData(iFile).nChannels = size(rawSignal,2);
    end

    loadedDataSummary = table( ...
        (1:numel(rawDataNames))', string(rawDataNames(:)), ...
        [rawData.nSamples]', [rawData.dt]', [rawData.fs]', ...
        'VariableNames', {'FileIdx','FileName','nSamples','dt_s','fs_Hz'});
end
