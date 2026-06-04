function daqData = AuxFcn_ReadHydrogenSensorTXT_001(fileName, options)
% AuxFcn_ReadHydrogenSensorTXT_001
% Read VH2D hydrogen sensor tab-delimited TXT logs (D2/D3 style).
%
% The Hydrogen-Sensors TXT files are different from the pressure DAQ TXT
% exports handled by AuxFcn_ReadDAQ_TXT_002:
%   Line 1 : device metadata keys
%   Line 2 : device metadata values
%   Line 3 : data column names
%   Line 4+: tab-delimited data rows
%
% By default this reader imports only the hydrogen output channel:
%   Time + Output (%)
%
% Output follows the standard VH2D daqData contract:
%   .daqId, .fileName, .filePath
%   .t, .signal, .channelNames, .units, .channelType
%   .nSamples, .nChannels, .fs, .dt, .tbl, .meta

arguments
    fileName (1,1) {mustBeTextScalar}
    options.DaqId (1,1) string = "Hydrogen-Sensor"
    options.Delimiter (1,1) string = string(sprintf('\t'))
    options.SignalColumns string = "Output (%)"
    options.Units = []
    options.ChannelType = []
end

fileName = char(strtrim(fileName));
resolvedPath = which(fileName);
if isempty(resolvedPath)
    resolvedPath = fileName;
end
assert(exist(resolvedPath, 'file') == 2, ...
    'Hydrogen sensor TXT file not found: %s', fileName);

[~, baseName, ext] = fileparts(resolvedPath);
fileNameStr = string([baseName, ext]);
delim = char(options.Delimiter);

allLines = readlines(resolvedPath);
originalLineNumbers = (1:numel(allLines)).';
keepLine = ~(strtrim(allLines) == "");
allLines = allLines(keepLine);
originalLineNumbers = originalLineNumbers(keepLine);
assert(numel(allLines) >= 4, ...
    'Hydrogen sensor TXT file "%s" has too few lines.', fileNameStr);

headerLineIdx = localFindDataHeaderLine(allLines, delim);
metadataKeyLineIdx = max(1, headerLineIdx - 2);
metadataValLineIdx = max(1, headerLineIdx - 1);
dataLineStartIdx = headerLineIdx + 1;

metadataKeys = localSplitLine(allLines(metadataKeyLineIdx), delim);
metadataVals = localSplitLine(allLines(metadataValLineIdx), delim);
headerTokens = localSplitLine(allLines(headerLineIdx), delim);

metadataKeys = metadataKeys(metadataKeys ~= "");
metadataVals = metadataVals(1:min(numel(metadataVals), numel(metadataKeys)));

assert(numel(headerTokens) >= 3, ...
    'Hydrogen sensor TXT header in "%s" has too few columns.', fileNameStr);

iterationName = headerTokens(1);
timeName = headerTokens(2);
allSignalNames = headerTokens(3:end);
allSignalNames = allSignalNames(allSignalNames ~= "");

if any(lower(options.SignalColumns) == "all")
    selectedSignalNames = allSignalNames;
    selectedSignalIdx = 1:numel(allSignalNames);
else
    selectedSignalNames = string(options.SignalColumns);
    [isSelected, selectedSignalIdx] = ismember(selectedSignalNames, allSignalNames);
    assert(all(isSelected), ...
        'Requested hydrogen sensor columns not found in "%s": %s', ...
        fileNameStr, strjoin(selectedSignalNames(~isSelected), ", "));
end

signalNames = selectedSignalNames;
nChannels = numel(signalNames);

allVarNames = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName( ...
    [iterationName, timeName, allSignalNames]));
selectedVarNames = allVarNames([1, 2, selectedSignalIdx + 2]);

opts = delimitedTextImportOptions("NumVariables", 2 + numel(allSignalNames));
opts.Delimiter = delim;
opts.DataLines = [originalLineNumbers(dataLineStartIdx) Inf];
opts.VariableNames = cellstr(allVarNames);
opts.VariableTypes = ["double", "string", repmat("double", 1, numel(allSignalNames))];
opts.SelectedVariableNames = cellstr(selectedVarNames);
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "skip";
opts = setvaropts(opts, allVarNames(2), "WhitespaceRule", "preserve");
opts = setvaropts(opts, allVarNames(2), "EmptyFieldRule", "auto");

tblRaw = readtable(resolvedPath, opts);
nSamples = height(tblRaw);

iteration = tblRaw{:, 1};
timeText = string(tblRaw{:, 2});
signalMat = tblRaw{:, 3:end};
timeOfDaySeconds = localTimeOfDayToSeconds(timeText);

t = localElapsedSeconds(timeOfDaySeconds);

dtVec = diff(t);
dtVec = dtVec(isfinite(dtVec) & dtVec > 0);
if isempty(dtVec)
    dtMean = NaN;
    dtStd = NaN;
    fsMean = NaN;
    isNonUniform = true;
else
    dtMean = mean(dtVec);
    dtStd = std(dtVec);
    fsMean = 1 / dtMean;
    isNonUniform = (dtStd / dtMean) > 0.01;
end

daqData = struct();
daqData.fileName = fileNameStr;
daqData.filePath = string(resolvedPath);
daqData.daqId = string(options.DaqId);
daqData.dt = dtMean;
daqData.fs = fsMean;
daqData.t = t(:);
daqData.signal = signalMat;
daqData.nSamples = nSamples;
daqData.nChannels = nChannels;
daqData.channelNames = reshape(signalNames, 1, []);

if isempty(options.Units)
    daqData.units = localExtractUnits(signalNames);
else
    units = string(options.Units);
    assert(numel(units) == nChannels, ...
        'Units must have length %d to match hydrogen sensor channels.', nChannels);
    daqData.units = reshape(units, 1, []);
end

if isempty(options.ChannelType)
    daqData.channelType = repmat("unknown", 1, nChannels);
    outputIdx = lower(signalNames) == "output (%)";
    daqData.channelType(outputIdx) = "concentration";
else
    channelType = string(options.ChannelType);
    assert(numel(channelType) == nChannels, ...
        'ChannelType must have length %d to match hydrogen sensor channels.', nChannels);
    daqData.channelType = reshape(channelType, 1, []);
end

tblVarNames = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName( ...
    ["elapsed_s", iterationName, timeName, signalNames]));
daqData.tbl = array2table([t(:), iteration(:), timeOfDaySeconds(:), signalMat], ...
    'VariableNames', cellstr(tblVarNames));

daqData.meta = struct();
daqData.meta.delimiter = delim;
daqData.meta.headerLine = originalLineNumbers(headerLineIdx);
daqData.meta.dataLineStart = originalLineNumbers(dataLineStartIdx);
daqData.meta.iteration = iteration;
daqData.meta.timeOfDaySeconds = timeOfDaySeconds;
daqData.meta.isNonUniform = isNonUniform;
daqData.meta.dtStd = dtStd;
daqData.meta.deviceInfo = localMetadataStruct(metadataKeys, metadataVals);
daqData.meta.importedColumns = signalNames;
daqData.meta.availableColumns = allSignalNames;

end

function headerLineIdx = localFindDataHeaderLine(lines, delim)
headerLineIdx = [];

for i = 1:numel(lines)
    tokens = lower(localSplitLine(lines(i), delim));
    if numel(tokens) >= 3 && tokens(1) == "iteration" && ...
            tokens(2) == "time" && any(tokens == "output (%)")
        headerLineIdx(end+1) = i; %#ok<AGROW>
    end
end

assert(~isempty(headerLineIdx), ...
    'Could not find hydrogen sensor data header line: Iteration Time Output (%%).');

headerLineIdx = headerLineIdx(end);
end

function tokens = localSplitLine(line, delim)
tokens = split(string(line), delim);
tokens = strtrim(tokens(:).');
while ~isempty(tokens) && tokens(end) == ""
    tokens(end) = [];
end
end

function secondsValue = localTimeOfDayToSeconds(timeText)
timeText = string(timeText);
secondsValue = NaN(size(timeText));

tokens = regexp(strtrim(timeText), '^(\d+):(\d+):(\d+(?:\.\d+)?)$', ...
    'tokens', 'once');

for i = 1:numel(tokens)
    if isempty(tokens{i})
        continue;
    end
    hours = str2double(tokens{i}{1});
    minutes = str2double(tokens{i}{2});
    secondsPart = str2double(tokens{i}{3});
    secondsValue(i) = hours * 3600 + minutes * 60 + secondsPart;
end

secondsValue = secondsValue(:);
end

function elapsed = localElapsedSeconds(timeOfDaySeconds)
elapsed = timeOfDaySeconds(:);
validIdx = find(isfinite(elapsed), 1, 'first');
if isempty(validIdx)
    elapsed(:) = NaN;
    return;
end

dayOffset = 0;
previous = elapsed(validIdx);
for i = validIdx+1:numel(elapsed)
    if ~isfinite(elapsed(i))
        continue;
    end
    if elapsed(i) + dayOffset < previous
        dayOffset = dayOffset + 24 * 3600;
    end
    elapsed(i) = elapsed(i) + dayOffset;
    previous = elapsed(i);
end

elapsed = elapsed - elapsed(validIdx);
end

function units = localExtractUnits(channelNames)
channelNames = string(channelNames);
units = strings(1, numel(channelNames));
for i = 1:numel(channelNames)
    token = regexp(channelNames(i), '\(([^)]*)\)', 'tokens', 'once');
    if isempty(token)
        units(i) = "raw";
    else
        units(i) = string(token{1});
    end
end
end

function info = localMetadataStruct(keys, vals)
info = struct();
for i = 1:min(numel(keys), numel(vals))
    key = matlab.lang.makeValidName(keys(i));
    if strlength(key) == 0
        key = "Field" + i;
    end
    info.(key) = vals(i);
end
end
