function pressurePreprocessed = AuxFcn_PreprocVH2DPressureTriggerSignals_001(offsetCorrected, options)
% AuxFcn_PreprocVH2DPressureTriggerSignals_001
% Preprocess pressure/trigger DAQs using a fixed temporal window.
%
% The complete campaign structure is preserved. Only configured DAQs
% are windowed; concentration data such as H2BGA and HS are copied unchanged.

arguments
    offsetCorrected (1,1) struct
    options.PreprocWindow_s (1,2) double = [-0.050, Inf]
    options.DAQs string = ["DAQ_1", "DAQ_2_3", "DAQ_4", "DAQ_2", "DAQ_3"]
end

pressurePreprocessed = offsetCorrected;
pressurePreprocessed.source = "AuxFcn_PreprocVH2DPressureTriggerSignals_001";
pressurePreprocessed.rule = "Preprocessed configured pressure/trigger DAQs only.";
pressurePreprocessed.PreprocWindow_s = options.PreprocWindow_s;

overview = table();

if ~isfield(pressurePreprocessed, "groups") || isempty(pressurePreprocessed.groups)
    pressurePreprocessed.preprocOverview = overview;
    return
end

groupFields = string(fieldnames(pressurePreprocessed.groups));
for iGroup = 1:numel(groupFields)
    % Walk through the campaign in the same group/run hierarchy used by the
    % raw data. This keeps traceability back to the original folders.
    groupField = groupFields(iGroup);
    groupData = pressurePreprocessed.groups.(groupField);
    groupId = localGetStringField(groupData, "id", groupField);

    if ~isfield(groupData, "runs") || isempty(groupData.runs)
        pressurePreprocessed.groups.(groupField).preprocOverview = table();
        continue
    end

    groupOverview = table();
    runFields = string(fieldnames(groupData.runs));
    for iRun = 1:numel(runFields)
        runField = runFields(iRun);
        runData = groupData.runs.(runField);
        runId = localGetStringField(runData, "id", runField);

        daqFields = string(fieldnames(runData));
        daqFields = daqFields(daqFields ~= "id");
        for iDAQ = 1:numel(daqFields)
            daqField = daqFields(iDAQ);
            value = runData.(daqField);
            if ~isstruct(value)
                continue
            end

            [preprocessedValue, rows] = localPreprocValue( ...
                value, groupId, runId, daqField, options);
            pressurePreprocessed.groups.(groupField).runs.(runField).(daqField) = preprocessedValue;
            groupOverview = localAppendTable(groupOverview, rows);
        end
    end

    pressurePreprocessed.groups.(groupField).preprocOverview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

pressurePreprocessed.preprocOverview = overview;
end

function [preprocessedValue, overview] = localPreprocValue(value, groupId, runId, daqPath, options)
overview = table();
preprocessedValue = value;

% Leaf DAQ structures contain `signal`; nested containers are traversed until
% a DAQ leaf is found.
if isfield(value, "signal")
    [preprocessedValue, overview] = localPreprocDAQ(value, groupId, runId, daqPath, options);
    return
end

nestedFields = string(fieldnames(value));
for iField = 1:numel(nestedFields)
    nestedField = nestedFields(iField);
    nestedValue = value.(nestedField);
    if ~isstruct(nestedValue)
        continue
    end

    [preprocessedNested, nestedOverview] = localPreprocValue( ...
        nestedValue, groupId, runId, daqPath + "." + nestedField, options);
    preprocessedValue.(nestedField) = preprocessedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [preprocessedDAQ, overview] = localPreprocDAQ(daqData, groupId, runId, daqPath, options)
preprocessedDAQ = daqData;

% Only configured pressure/trigger DAQs are windowed. Other data, including
% concentration measurements, are copied without sample removal.
rootDAQs = localRootDAQs(daqPath);
shouldPreproc = any(rootDAQs == options.DAQs);
sourceSamples = localSampleCount(daqData);

status = "";
firstKeptIndex = NaN;
lastKeptIndex = NaN;
keptSamples = sourceSamples;
removedSamples = 0;

if ~shouldPreproc
    status = "not_preprocessed";
    overview = localOverviewRow(groupId, runId, daqPath, rootDAQs, ...
        options.PreprocWindow_s, sourceSamples, keptSamples, removedSamples, ...
        firstKeptIndex, lastKeptIndex, status);
    return
end

if ~isfield(daqData, "t_s") || isempty(daqData.t_s) || ...
        ~isfield(daqData, "signal") || isempty(daqData.signal)
    status = "missing_time_or_signal";
    overview = localOverviewRow(groupId, runId, daqPath, rootDAQs, ...
        options.PreprocWindow_s, sourceSamples, keptSamples, removedSamples, ...
        firstKeptIndex, lastKeptIndex, status);
    return
end

t = daqData.t_s(:);
% The preliminary temporal window is defined in the already aligned time base.
idxKeep = t >= options.PreprocWindow_s(1) & t <= options.PreprocWindow_s(2);
kept = find(idxKeep);

if isempty(kept)
    status = "missing_preproc_window";
    keptSamples = 0;
    removedSamples = sourceSamples;
    overview = localOverviewRow(groupId, runId, daqPath, rootDAQs, ...
        options.PreprocWindow_s, sourceSamples, keptSamples, removedSamples, ...
        firstKeptIndex, lastKeptIndex, status);
    return
end

firstKeptIndex = kept(1);
lastKeptIndex = kept(end);
keptSamples = numel(kept);
removedSamples = sourceSamples - keptSamples;
preprocessedDAQ = localPreprocSampleFields(daqData, idxKeep, sourceSamples);
preprocessedDAQ.preproc = struct( ...
    "preprocWindow_s", options.PreprocWindow_s, ...
    "sourceSamples", sourceSamples, ...
    "keptSamples", keptSamples, ...
    "removedSamples", removedSamples, ...
    "firstKeptIndex", firstKeptIndex, ...
    "lastKeptIndex", lastKeptIndex, ...
    "status", "preprocessed");
status = "preprocessed";

overview = localOverviewRow(groupId, runId, daqPath, rootDAQs, ...
    options.PreprocWindow_s, sourceSamples, keptSamples, removedSamples, ...
    firstKeptIndex, lastKeptIndex, status);
end

function preprocessedDAQ = localPreprocSampleFields(daqData, idxKeep, nSamples)
preprocessedDAQ = daqData;
fieldNames = string(fieldnames(daqData));

% Apply the same sample mask to every vector/matrix field that has one row
% per time sample. Metadata fields such as channels/units are left unchanged.
for iField = 1:numel(fieldNames)
    fieldName = fieldNames(iField);
    value = daqData.(fieldName);

    if ~(isnumeric(value) || islogical(value)) || isempty(value) || ndims(value) > 2
        continue
    end

    if size(value, 1) == nSamples
        preprocessedDAQ.(fieldName) = value(idxKeep, :);
    elseif isrow(value) && size(value, 2) == nSamples
        preprocessedDAQ.(fieldName) = value(:, idxKeep);
    end
end
end

function row = localOverviewRow(groupId, runId, daqPath, rootDAQs, PreprocWindow, ...
        sourceSamples, keptSamples, removedSamples, firstKeptIndex, lastKeptIndex, status)
row = table( ...
    string(groupId), ...
    string(runId), ...
    string(daqPath), ...
    string(rootDAQs), ...
    PreprocWindow(1), ...
    PreprocWindow(2), ...
    sourceSamples, ...
    keptSamples, ...
    removedSamples, ...
    firstKeptIndex, ...
    lastKeptIndex, ...
    string(status), ...
    'VariableNames', {'GroupId','RunId','DAQs','RootDAQs', ...
    'PreprocStart_s','PreprocEnd_s','SourceSamples','KeptSamples', ...
    'RemovedSamples','FirstKeptIndex','LastKeptIndex','Status'});
end

function nSamples = localSampleCount(data)
if isfield(data, "signal") && ~isempty(data.signal)
    nSamples = size(data.signal, 1);
elseif isfield(data, "t_s") && ~isempty(data.t_s)
    nSamples = numel(data.t_s);
else
    nSamples = 0;
end
end

function rootDAQs = localRootDAQs(daqPath)
parts = split(string(daqPath), ".");
rootDAQs = parts(1);
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
