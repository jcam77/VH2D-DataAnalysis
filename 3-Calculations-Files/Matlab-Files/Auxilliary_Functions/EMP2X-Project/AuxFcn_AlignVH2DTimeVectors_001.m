function aligned = AuxFcn_AlignVH2DTimeVectors_001(converted, options)
% AuxFcn_AlignVH2DTimeVectors_001
% Build a trigger-aligned VH2D campaign structure without modifying input data.
%
% DAQs listed in DAQsAlreadyAligned are kept unchanged. DAQs listed in
% DAQsToAlign are shifted so the first trigger threshold crossing becomes
% t = 0 s.

arguments
    converted (1,1) struct
    options.TriggerZeroThreshold_V (1,1) double = NaN
    options.DAQsAlreadyAligned string = strings(0,1)
    options.DAQsToAlign string = strings(0,1)
end

localValidateOptions(options);
aligned = converted;
aligned.source = "AuxFcn_AlignVH2DTimeVectors_001";
aligned.rule = "DAQsAlreadyAligned kept unchanged; DAQsToAlign shifted to first trigger threshold crossing.";
if isfield(converted, "overview")
    aligned.conversionOverview = converted.overview;
end

overview = table();

if ~isfield(aligned, "groups") || isempty(aligned.groups)
    aligned.alignmentOverview = overview;
    aligned.alignmentSummaryDisplayTable = overview;
    return
end

groupFields = string(fieldnames(aligned.groups));
for iGroup = 1:numel(groupFields)
    % Keep the same group/run/DAQ hierarchy. Alignment only changes time
    % vectors, never the measured signal values.
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

        daqFields = string(fieldnames(runData));
        daqFields = daqFields(daqFields ~= "id");
        for iDAQ = 1:numel(daqFields)
            daqField = daqFields(iDAQ);
            value = runData.(daqField);
            if ~isstruct(value)
                continue
            end

            [alignedValue, rows] = localAlignValue( ...
                value, groupId, runId, daqField, options);
            aligned.groups.(groupField).runs.(runField).(daqField) = alignedValue;
            groupOverview = localAppendTable(groupOverview, rows);
        end
    end

    aligned.groups.(groupField).alignmentOverview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

aligned.alignmentOverview = overview;
aligned.alignmentSummaryDisplayTable = localBuildAlignmentSummaryDisplayTable( ...
    overview, [options.DAQsAlreadyAligned(:); options.DAQsToAlign(:)]);
end

function [alignedValue, overview] = localAlignValue(value, groupId, runId, daqPath, options)
overview = table();
alignedValue = value;

% DAQ leaves contain `signal`; nested containers are recursively inspected.
if isfield(value, "signal")
    [alignedValue, overview] = localAlignDAQ(value, groupId, runId, daqPath, options);
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
        nestedValue, groupId, runId, daqPath + "." + nestedField, options);
    alignedValue.(nestedField) = alignedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [alignedDAQ, overview] = localAlignDAQ(daqData, groupId, runId, daqPath, options)
alignedDAQ = daqData;
overview = table();

if ~isfield(daqData, "t_s") || isempty(daqData.t_s) || ...
        ~isfield(daqData, "signal") || isempty(daqData.signal)
    return
end

t = daqData.t_s(:);
rootDAQs = localRootDAQs(daqPath);
isAlreadyAligned = any(rootDAQs == options.DAQsAlreadyAligned);
shouldAlign = any(rootDAQs == options.DAQsToAlign);

% Streams outside the configured pressure/trigger DAQ list are copied
% exactly as they came in. This prevents concentration streams such as H2BGA
% and HS from receiving misleading alignment metadata.
if ~isAlreadyAligned && ~shouldAlign
    return
end

% Trigger channel detection uses channel names and units, not a fixed column
% number, because DAQ channel order can change between runs.
[triggerColumn, triggerChannel, triggerStatus] = localFindTriggerChannel(daqData);
[triggerTime, crossingStatus] = localFindTriggerCrossing( ...
    t, daqData.signal, triggerColumn, options.TriggerZeroThreshold_V);

if isAlreadyAligned
    appliedShift = 0;
    status = "already_aligned_kept";
elseif shouldAlign && ~isnan(triggerTime)
    appliedShift = triggerTime;
    alignedDAQ.t_s = t - appliedShift;
    status = "aligned_to_trigger";
elseif shouldAlign
    appliedShift = NaN;
    status = "missing_trigger_crossing";
else
    appliedShift = 0;
    status = "copied_not_trigger_aligned";
end

% Report-facing evidence check. This shows what the DAQ trigger voltage was
% at the original logger zero time before any shift is applied.
triggerVoltageAtOriginalZeroTime = localEvaluateTriggerVoltageAtTime( ...
    t, daqData.signal, triggerColumn, 0);
triggerVoltageErrorAtOriginalZeroTime = triggerVoltageAtOriginalZeroTime - ...
    options.TriggerZeroThreshold_V;
triggerVoltageAtAlignedZeroTime = localEvaluateTriggerVoltageAtTime( ...
    t, daqData.signal, triggerColumn, appliedShift);

alignedDAQ.source_t_s = t;
alignedDAQ.alignment = struct( ...
    "triggerZeroThreshold_V", options.TriggerZeroThreshold_V, ...
    "triggerColumn", triggerColumn, ...
    "triggerChannel", triggerChannel, ...
    "triggerTime_source_s", triggerTime, ...
    "appliedShift_s", appliedShift, ...
    "triggerVoltageAtOriginalZeroTime_V", triggerVoltageAtOriginalZeroTime, ...
    "triggerVoltageErrorAtOriginalZeroTime_V", triggerVoltageErrorAtOriginalZeroTime, ...
    "triggerVoltageAtAlignedZeroTime_V", triggerVoltageAtAlignedZeroTime, ...
    "status", status);

overview = table( ...
    string(groupId), ...
    string(runId), ...
    string(daqPath), ...
    rootDAQs, ...
    triggerColumn, ...
    triggerChannel, ...
    options.TriggerZeroThreshold_V, ...
    triggerTime, ...
    appliedShift, ...
    triggerVoltageAtOriginalZeroTime, ...
    triggerVoltageErrorAtOriginalZeroTime, ...
    triggerVoltageAtAlignedZeroTime, ...
    triggerStatus, ...
    crossingStatus, ...
    status, ...
    'VariableNames', {'GroupId','RunId','DAQs','RootDAQs', ...
    'TriggerColumn','TriggerChannel','TriggerZeroThreshold_V', ...
    'TriggerTime_source_s','AppliedShift_s', ...
    'TriggerVoltageAtOriginalZeroTime_V', ...
    'TriggerVoltageErrorAtOriginalZeroTime_V', ...
    'TriggerVoltageAtAlignedZeroTime_V', ...
    'TriggerChannelStatus', ...
    'CrossingStatus','Status'});
end

function [triggerColumn, triggerChannel, status] = localFindTriggerChannel(daqData)
triggerColumn = NaN;
triggerChannel = "";
status = "missing_trigger_channel";

if ~isfield(daqData, "signal") || isempty(daqData.signal)
    return
end

nChannels = size(daqData.signal, 2);
channels = localPadStringRow(localGetStringRow(daqData, "channels"), ...
    nChannels, "Channel_" + string(1:nChannels));
units = localPadStringRow(localGetStringRow(daqData, "units"), ...
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

function voltage = localEvaluateTriggerVoltageAtTime(t, signal, triggerColumn, queryTime)
voltage = NaN;

if isnan(queryTime) || isnan(triggerColumn) || ...
        triggerColumn < 1 || triggerColumn > size(signal, 2)
    return
end

y = signal(:, triggerColumn);
valid = isfinite(t) & isfinite(y);
t = t(valid);
y = y(valid);

if numel(t) < 2
    return
end

[t, uniqueIdx] = unique(t, "stable");
y = y(uniqueIdx);
voltage = interp1(t, y, queryTime, "linear", NaN);
end

function rootDAQs = localRootDAQs(daqPath)
parts = split(string(daqPath), ".");
rootDAQs = parts(1);
end

function displayTable = localBuildAlignmentSummaryDisplayTable(overview, daqsToShow)
if isempty(overview)
    displayTable = overview;
    return
end

summaryTable = overview( ...
    ismember(overview.RootDAQs, string(daqsToShow)), ...
    {'GroupId','RunId','DAQs','TriggerColumn','TriggerChannel', ...
    'TriggerTime_source_s','AppliedShift_s', ...
    'TriggerVoltageAtOriginalZeroTime_V', ...
    'TriggerVoltageAtAlignedZeroTime_V','Status'});

displayTable = summaryTable;
displayTable.TriggerTime_source_s = ...
    compose("%.9g", summaryTable.TriggerTime_source_s);
displayTable.AppliedShift_s = ...
    compose("%.9g", summaryTable.AppliedShift_s);
displayTable.TriggerVoltageAtOriginalZeroTime_V = ...
    compose("%.4f", summaryTable.TriggerVoltageAtOriginalZeroTime_V);
displayTable.TriggerVoltageAtAlignedZeroTime_V = ...
    compose("%.4f", summaryTable.TriggerVoltageAtAlignedZeroTime_V);
end

function localValidateOptions(options)
if isnan(options.TriggerZeroThreshold_V)
    error("AuxFcn_AlignVH2DTimeVectors_001:MissingTriggerThreshold", ...
        "TriggerZeroThreshold_V must be provided explicitly, for example TriggerZeroThreshold_V=4.");
end

if isempty(options.DAQsToAlign) || all(strlength(options.DAQsToAlign) == 0)
    error("AuxFcn_AlignVH2DTimeVectors_001:MissingDAQsToAlign", ...
        "DAQsToAlign must be provided explicitly, for example DAQsToAlign=[""DAQ_2_3"",""DAQ_4""].");
end
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
