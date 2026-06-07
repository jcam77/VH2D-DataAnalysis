function pressurePreprocessed = AuxFcn_CropVH2DPressureTriggerSignals_001(offsetCorrected, options)
% AuxFcn_CropVH2DPressureTriggerSignals_001
% Crop pressure/trigger DAQ streams from a fixed pre-trigger time to record end.
%
% The complete campaign structure is preserved. Only configured DAQ streams
% are cropped; concentration streams such as H2BGA and HS are copied unchanged.

arguments
    offsetCorrected (1,1) struct
    options.CropWindow_s (1,2) double = [-0.050, Inf]
    options.StreamFields string = ["DAQ_1", "DAQ_2_3", "DAQ_4", "DAQ_2", "DAQ_3"]
end

pressurePreprocessed = offsetCorrected;
pressurePreprocessed.source = "AuxFcn_CropVH2DPressureTriggerSignals_001";
pressurePreprocessed.rule = "Crop configured pressure/trigger DAQ streams only.";
pressurePreprocessed.cropWindow_s = options.CropWindow_s;

overview = table();

if ~isfield(pressurePreprocessed, "groups") || isempty(pressurePreprocessed.groups)
    pressurePreprocessed.cropOverview = overview;
    return
end

groupFields = string(fieldnames(pressurePreprocessed.groups));
for iGroup = 1:numel(groupFields)
    groupField = groupFields(iGroup);
    groupData = pressurePreprocessed.groups.(groupField);
    groupId = localGetStringField(groupData, "id", groupField);

    if ~isfield(groupData, "runs") || isempty(groupData.runs)
        pressurePreprocessed.groups.(groupField).cropOverview = table();
        continue
    end

    groupOverview = table();
    runFields = string(fieldnames(groupData.runs));
    for iRun = 1:numel(runFields)
        runField = runFields(iRun);
        runData = groupData.runs.(runField);
        runId = localGetStringField(runData, "id", runField);

        streamFields = string(fieldnames(runData));
        streamFields = streamFields(streamFields ~= "id");
        for iStream = 1:numel(streamFields)
            streamField = streamFields(iStream);
            value = runData.(streamField);
            if ~isstruct(value)
                continue
            end

            [croppedValue, rows] = localCropValue( ...
                value, groupId, runId, streamField, options);
            pressurePreprocessed.groups.(groupField).runs.(runField).(streamField) = croppedValue;
            groupOverview = localAppendTable(groupOverview, rows);
        end
    end

    pressurePreprocessed.groups.(groupField).cropOverview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

pressurePreprocessed.cropOverview = overview;
end

function [croppedValue, overview] = localCropValue(value, groupId, runId, streamPath, options)
overview = table();
croppedValue = value;

if isfield(value, "signal")
    [croppedValue, overview] = localCropStream(value, groupId, runId, streamPath, options);
    return
end

nestedFields = string(fieldnames(value));
for iField = 1:numel(nestedFields)
    nestedField = nestedFields(iField);
    nestedValue = value.(nestedField);
    if ~isstruct(nestedValue)
        continue
    end

    [croppedNested, nestedOverview] = localCropValue( ...
        nestedValue, groupId, runId, streamPath + "." + nestedField, options);
    croppedValue.(nestedField) = croppedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [croppedStream, overview] = localCropStream(streamData, groupId, runId, streamPath, options)
croppedStream = streamData;

rootStream = localRootStream(streamPath);
shouldCrop = any(rootStream == options.StreamFields);
sourceSamples = localSampleCount(streamData);

status = "";
firstKeptIndex = NaN;
lastKeptIndex = NaN;
keptSamples = sourceSamples;
removedSamples = 0;

if ~shouldCrop
    status = "not_pressure_trigger_preprocessed";
    overview = localOverviewRow(groupId, runId, streamPath, rootStream, ...
        options.CropWindow_s, sourceSamples, keptSamples, removedSamples, ...
        firstKeptIndex, lastKeptIndex, status);
    return
end

if ~isfield(streamData, "t_s") || isempty(streamData.t_s) || ...
        ~isfield(streamData, "signal") || isempty(streamData.signal)
    status = "missing_time_or_signal";
    overview = localOverviewRow(groupId, runId, streamPath, rootStream, ...
        options.CropWindow_s, sourceSamples, keptSamples, removedSamples, ...
        firstKeptIndex, lastKeptIndex, status);
    return
end

t = streamData.t_s(:);
idxKeep = t >= options.CropWindow_s(1) & t <= options.CropWindow_s(2);
kept = find(idxKeep);

if isempty(kept)
    status = "missing_crop_window";
    keptSamples = 0;
    removedSamples = sourceSamples;
    overview = localOverviewRow(groupId, runId, streamPath, rootStream, ...
        options.CropWindow_s, sourceSamples, keptSamples, removedSamples, ...
        firstKeptIndex, lastKeptIndex, status);
    return
end

firstKeptIndex = kept(1);
lastKeptIndex = kept(end);
keptSamples = numel(kept);
removedSamples = sourceSamples - keptSamples;
croppedStream = localCropSampleFields(streamData, idxKeep, sourceSamples);
croppedStream.crop = struct( ...
    "cropWindow_s", options.CropWindow_s, ...
    "sourceSamples", sourceSamples, ...
    "keptSamples", keptSamples, ...
    "removedSamples", removedSamples, ...
    "firstKeptIndex", firstKeptIndex, ...
    "lastKeptIndex", lastKeptIndex, ...
    "status", "cropped");
status = "cropped";

overview = localOverviewRow(groupId, runId, streamPath, rootStream, ...
    options.CropWindow_s, sourceSamples, keptSamples, removedSamples, ...
    firstKeptIndex, lastKeptIndex, status);
end

function croppedStream = localCropSampleFields(streamData, idxKeep, nSamples)
croppedStream = streamData;
fieldNames = string(fieldnames(streamData));

for iField = 1:numel(fieldNames)
    fieldName = fieldNames(iField);
    value = streamData.(fieldName);

    if ~(isnumeric(value) || islogical(value)) || isempty(value) || ndims(value) > 2
        continue
    end

    if size(value, 1) == nSamples
        croppedStream.(fieldName) = value(idxKeep, :);
    elseif isrow(value) && size(value, 2) == nSamples
        croppedStream.(fieldName) = value(:, idxKeep);
    end
end
end

function row = localOverviewRow(groupId, runId, streamPath, rootStream, cropWindow, ...
        sourceSamples, keptSamples, removedSamples, firstKeptIndex, lastKeptIndex, status)
row = table( ...
    string(groupId), ...
    string(runId), ...
    string(streamPath), ...
    string(rootStream), ...
    cropWindow(1), ...
    cropWindow(2), ...
    sourceSamples, ...
    keptSamples, ...
    removedSamples, ...
    firstKeptIndex, ...
    lastKeptIndex, ...
    string(status), ...
    'VariableNames', {'GroupId','RunId','Stream','RootStream', ...
    'CropStart_s','CropEnd_s','SourceSamples','KeptSamples', ...
    'RemovedSamples','FirstKeptIndex','LastKeptIndex','Status'});
end

function nSamples = localSampleCount(streamData)
if isfield(streamData, "signal") && ~isempty(streamData.signal)
    nSamples = size(streamData.signal, 1);
elseif isfield(streamData, "t_s") && ~isempty(streamData.t_s)
    nSamples = numel(streamData.t_s);
else
    nSamples = 0;
end
end

function rootStream = localRootStream(streamPath)
parts = split(string(streamPath), ".");
rootStream = parts(1);
end

function value = localGetStringField(s, fieldName, fallback)
fieldName = char(fieldName);
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = string(s.(fieldName));
else
    value = string(fallback);
end
end

function tbl = localAppendTable(tbl, rows)
if isempty(rows)
    return
end

if isempty(tbl)
    tbl = rows;
else
    tbl = [tbl; rows]; %#ok<AGROW>
end
end
