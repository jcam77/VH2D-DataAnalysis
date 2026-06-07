function offsetCorrected = AuxFcn_RemoveVH2DPressureOffset_001(aligned, options)
% AuxFcn_RemoveVH2DPressureOffset_001
% Remove pressure-channel DC background offset using a pre-trigger window.
%
% Only channels with unit kPa are corrected. Trigger voltage, concentration,
% raw, and unknown-unit channels are copied unchanged.

arguments
    aligned (1,1) struct
    options.BaselineWindow_s (1,2) double = [-0.050, -0.005]
end

offsetCorrected = aligned;
offsetCorrected.source = "AuxFcn_RemoveVH2DPressureOffset_001";
offsetCorrected.rule = "Subtract mean pressure baseline from kPa channels only.";
offsetCorrected.baselineWindow_s = options.BaselineWindow_s;
if isfield(aligned, "alignmentOverview")
    offsetCorrected.alignmentOverview = aligned.alignmentOverview;
end

overview = table();

if ~isfield(offsetCorrected, "groups") || isempty(offsetCorrected.groups)
    offsetCorrected.offsetOverview = overview;
    return
end

groupFields = string(fieldnames(offsetCorrected.groups));
for iGroup = 1:numel(groupFields)
    groupField = groupFields(iGroup);
    groupData = offsetCorrected.groups.(groupField);
    groupId = localGetStringField(groupData, "id", groupField);

    if ~isfield(groupData, "runs") || isempty(groupData.runs)
        offsetCorrected.groups.(groupField).offsetOverview = table();
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

            [correctedValue, rows] = localCorrectValue( ...
                value, groupId, runId, streamField, options.BaselineWindow_s);
            offsetCorrected.groups.(groupField).runs.(runField).(streamField) = correctedValue;
            groupOverview = localAppendTable(groupOverview, rows);
        end
    end

    offsetCorrected.groups.(groupField).offsetOverview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

offsetCorrected.offsetOverview = overview;
end

function [correctedValue, overview] = localCorrectValue(value, groupId, runId, streamPath, baselineWindow)
overview = table();
correctedValue = value;

if isfield(value, "signal")
    [correctedValue, overview] = localCorrectStream(value, groupId, runId, streamPath, baselineWindow);
    return
end

nestedFields = string(fieldnames(value));
for iField = 1:numel(nestedFields)
    nestedField = nestedFields(iField);
    nestedValue = value.(nestedField);
    if ~isstruct(nestedValue)
        continue
    end

    [correctedNested, nestedOverview] = localCorrectValue( ...
        nestedValue, groupId, runId, streamPath + "." + nestedField, baselineWindow);
    correctedValue.(nestedField) = correctedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [correctedStream, overview] = localCorrectStream(streamData, groupId, runId, streamPath, baselineWindow)
correctedStream = streamData;
overview = table();

if ~isfield(streamData, "t_s") || isempty(streamData.t_s) || ...
        ~isfield(streamData, "signal") || isempty(streamData.signal)
    return
end

t = streamData.t_s(:);
signal = double(streamData.signal);
nChannels = size(signal, 2);
channels = localPadStringRow(localGetStringRow(streamData, "channels"), ...
    nChannels, "Channel_" + string(1:nChannels));
units = localPadStringRow(localGetStringRow(streamData, "units"), ...
    nChannels, repmat("raw", 1, nChannels));

correctedSignal = signal;
baselineMean = NaN(nChannels, 1);
baselineStd = NaN(nChannels, 1);
baselineSamples = zeros(nChannels, 1);
status = strings(nChannels, 1);

idxWindow = t >= baselineWindow(1) & t <= baselineWindow(2);

for iChannel = 1:nChannels
    if lower(strtrim(units(iChannel))) ~= "kpa"
        status(iChannel) = "not_offset_corrected";
        continue
    end

    y = signal(:, iChannel);
    idx = idxWindow & isfinite(y);
    baselineSamples(iChannel) = nnz(idx);

    if baselineSamples(iChannel) == 0
        status(iChannel) = "missing_baseline_window";
        continue
    end

    baselineMean(iChannel) = mean(y(idx), "omitnan");
    baselineStd(iChannel) = std(y(idx), "omitnan");
    correctedSignal(:, iChannel) = y - baselineMean(iChannel);
    status(iChannel) = "offset_removed";
end

correctedStream.source_signal = streamData.signal;
correctedStream.signal = correctedSignal;
correctedStream.offsetCorrection = table( ...
    repmat(string(groupId), nChannels, 1), ...
    repmat(string(runId), nChannels, 1), ...
    repmat(string(streamPath), nChannels, 1), ...
    (1:nChannels)', ...
    channels(:), ...
    units(:), ...
    repmat(baselineWindow(1), nChannels, 1), ...
    repmat(baselineWindow(2), nChannels, 1), ...
    baselineMean, ...
    baselineStd, ...
    baselineSamples, ...
    status, ...
    'VariableNames', {'GroupId','RunId','Stream','Column','Channel', ...
    'Unit','BaselineWindowStart_s','BaselineWindowEnd_s', ...
    'BaselineMean_kPa','BaselineStd_kPa','BaselineSamples','Status'});

overview = correctedStream.offsetCorrection;
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
