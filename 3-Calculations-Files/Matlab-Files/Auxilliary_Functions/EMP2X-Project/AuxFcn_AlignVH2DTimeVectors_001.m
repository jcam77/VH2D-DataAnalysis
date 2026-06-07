function aligned = AuxFcn_AlignVH2DTimeVectors_001(converted, options)
% AuxFcn_AlignVH2DTimeVectors_001
% Build a trigger-aligned VH2D campaign structure without modifying input data.
%
% DAQ_1 is treated as already zero-aligned by default. DAQ_2_3 and DAQ_4
% are shifted so the first 4 V trigger crossing becomes t = 0 s.

arguments
    converted (1,1) struct
    options.TriggerThreshold_V (1,1) double = 4
    options.ReferenceStreams string = "DAQ_1"
    options.AlignStreams string = ["DAQ_2_3", "DAQ_4", "DAQ_2", "DAQ_3"]
end

aligned = converted;
aligned.source = "AuxFcn_AlignVH2DTimeVectors_001";
aligned.rule = "DAQ_1 kept unchanged; configured DAQ streams shifted to first 4 V trigger crossing.";
if isfield(converted, "overview")
    aligned.conversionOverview = converted.overview;
end

overview = table();

if ~isfield(aligned, "groups") || isempty(aligned.groups)
    aligned.alignmentOverview = overview;
    return
end

groupFields = string(fieldnames(aligned.groups));
for iGroup = 1:numel(groupFields)
    groupField = groupFields(iGroup);
    groupData = aligned.groups.(groupField);
    groupId = localGetStringField(groupData, "id", groupField);

    if ~isfield(groupData, "runs") || isempty(groupData.runs)
        aligned.groups.(groupField).alignmentOverview = table();
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

            [alignedValue, rows] = localAlignValue( ...
                value, groupId, runId, streamField, options);
            aligned.groups.(groupField).runs.(runField).(streamField) = alignedValue;
            groupOverview = localAppendTable(groupOverview, rows);
        end
    end

    aligned.groups.(groupField).alignmentOverview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

aligned.alignmentOverview = overview;
end

function [alignedValue, overview] = localAlignValue(value, groupId, runId, streamPath, options)
overview = table();
alignedValue = value;

if isfield(value, "signal")
    [alignedValue, overview] = localAlignStream(value, groupId, runId, streamPath, options);
    return
end

nestedFields = string(fieldnames(value));
for iField = 1:numel(nestedFields)
    nestedField = nestedFields(iField);
    nestedValue = value.(nestedField);
    if ~isstruct(nestedValue)
        continue
    end

    [alignedNested, nestedOverview] = localAlignValue( ...
        nestedValue, groupId, runId, streamPath + "." + nestedField, options);
    alignedValue.(nestedField) = alignedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [alignedStream, overview] = localAlignStream(streamData, groupId, runId, streamPath, options)
alignedStream = streamData;
overview = table();

if ~isfield(streamData, "t_s") || isempty(streamData.t_s) || ...
        ~isfield(streamData, "signal") || isempty(streamData.signal)
    return
end

t = streamData.t_s(:);
rootStream = localRootStream(streamPath);
isReference = any(rootStream == options.ReferenceStreams);
shouldAlign = any(rootStream == options.AlignStreams);

[triggerColumn, triggerChannel, triggerStatus] = localFindTriggerChannel(streamData);
[triggerTime, crossingStatus] = localFindTriggerCrossing( ...
    t, streamData.signal, triggerColumn, options.TriggerThreshold_V);

if isReference
    appliedShift = 0;
    status = "reference_kept";
elseif shouldAlign && ~isnan(triggerTime)
    appliedShift = triggerTime;
    alignedStream.t_s = t - appliedShift;
    status = "aligned_to_trigger";
elseif shouldAlign
    appliedShift = NaN;
    status = "missing_trigger_crossing";
else
    appliedShift = 0;
    status = "copied_not_trigger_aligned";
end

alignedStream.source_t_s = t;
alignedStream.alignment = struct( ...
    "triggerThreshold_V", options.TriggerThreshold_V, ...
    "triggerColumn", triggerColumn, ...
    "triggerChannel", triggerChannel, ...
    "triggerTime_source_s", triggerTime, ...
    "appliedShift_s", appliedShift, ...
    "status", status);

overview = table( ...
    string(groupId), ...
    string(runId), ...
    string(streamPath), ...
    rootStream, ...
    triggerColumn, ...
    triggerChannel, ...
    options.TriggerThreshold_V, ...
    triggerTime, ...
    appliedShift, ...
    triggerStatus, ...
    crossingStatus, ...
    status, ...
    'VariableNames', {'GroupId','RunId','Stream','RootStream', ...
    'TriggerColumn','TriggerChannel','TriggerThreshold_V', ...
    'TriggerTime_source_s','AppliedShift_s','TriggerChannelStatus', ...
    'CrossingStatus','Status'});
end

function [triggerColumn, triggerChannel, status] = localFindTriggerChannel(streamData)
triggerColumn = NaN;
triggerChannel = "";
status = "missing_trigger_channel";

if ~isfield(streamData, "signal") || isempty(streamData.signal)
    return
end

nChannels = size(streamData.signal, 2);
channels = localPadStringRow(localGetStringRow(streamData, "channels"), ...
    nChannels, "Channel_" + string(1:nChannels));
units = localPadStringRow(localGetStringRow(streamData, "units"), ...
    nChannels, repmat("raw", 1, nChannels));

channelKey = lower(channels);
unitKey = lower(strtrim(units));
candidateIdx = find(contains(channelKey, "trigger") | ...
    contains(channelKey, "voltage") | unitKey == "v");

if isempty(candidateIdx)
    return
end

triggerColumn = candidateIdx(1);
triggerChannel = channels(triggerColumn);
if numel(candidateIdx) > 1
    status = "multiple_trigger_candidates_first_used";
else
    status = "trigger_channel_found";
end
end

function [triggerTime, status] = localFindTriggerCrossing(t, signal, triggerColumn, threshold)
triggerTime = NaN;
status = "missing_trigger_channel";

if isnan(triggerColumn) || triggerColumn < 1 || triggerColumn > size(signal, 2)
    return
end

y = signal(:, triggerColumn);
valid = isfinite(t) & isfinite(y);
t = t(valid);
y = y(valid);

if isempty(t)
    status = "empty_trigger_signal";
    return
end

crossIdx = find(y >= threshold, 1, "first");
if isempty(crossIdx)
    status = "threshold_not_crossed";
    return
end

if crossIdx == 1
    triggerTime = t(1);
    status = "crossing_at_first_sample";
    return
end

t0 = t(crossIdx - 1);
t1 = t(crossIdx);
y0 = y(crossIdx - 1);
y1 = y(crossIdx);

if y1 == y0
    triggerTime = t1;
    status = "crossing_no_interpolation";
else
    triggerTime = t0 + (threshold - y0) .* (t1 - t0) ./ (y1 - y0);
    status = "crossing_interpolated";
end
end

function rootStream = localRootStream(streamPath)
parts = split(string(streamPath), ".");
rootStream = parts(1);
end

function values = localGetStringRow(s, fieldName)
fieldName = char(fieldName);
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    values = string(s.(fieldName));
else
    values = strings(1, 0);
end
values = reshape(values, 1, []);
end

function values = localPadStringRow(values, nValues, fallbackValues)
values = reshape(string(values), 1, []);
fallbackValues = reshape(string(fallbackValues), 1, []);

if numel(values) < nValues
    values(numel(values)+1:nValues) = fallbackValues(numel(values)+1:nValues);
elseif numel(values) > nValues
    values = values(1:nValues);
end
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
