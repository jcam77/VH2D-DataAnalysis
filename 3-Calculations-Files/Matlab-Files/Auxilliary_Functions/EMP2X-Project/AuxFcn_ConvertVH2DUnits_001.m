function converted = AuxFcn_ConvertVH2DUnits_001(campaign)
% AuxFcn_ConvertVH2DUnits_001
% Build a unit-converted VH2D campaign structure without modifying raw data.
%
% The returned structure mirrors campaign.groups.<group>.runs.<run>, but each
% stream contains converted signals and a conversion table. Conversion is based
% on explicit unit labels from the loaded raw data, channel-name unit labels
% such as "[bar]", and known stream-level units for H2BGA. It does not use
% channel positions.

arguments
    campaign (1,1) struct
end

converted = struct();
converted.id = localGetStringField(campaign, "id", "converted_campaign");
converted.source = "AuxFcn_ConvertVH2DUnits_001";
converted.rule = "Convert by unit labels/channel-name evidence; leave unknown units unchanged.";
converted.groups = struct();

overview = table();

if ~isfield(campaign, "groups") || isempty(campaign.groups)
    converted.overview = overview;
    return
end

groupFields = string(fieldnames(campaign.groups));
for iGroup = 1:numel(groupFields)
    groupField = groupFields(iGroup);
    groupData = campaign.groups.(groupField);

    converted.groups.(groupField).id = localGetStringField(groupData, "id", groupField);
    converted.groups.(groupField).runs = struct();

    if ~isfield(groupData, "runs") || isempty(groupData.runs)
        converted.groups.(groupField).overview = table();
        continue
    end

    groupOverview = table();
    runFields = string(fieldnames(groupData.runs));
    for iRun = 1:numel(runFields)
        runField = runFields(iRun);
        runData = groupData.runs.(runField);
        runId = localGetStringField(runData, "id", runField);

        convertedRun = struct();
        convertedRun.id = runId;

        streamFields = string(fieldnames(runData));
        streamFields = streamFields(streamFields ~= "id");
        for iStream = 1:numel(streamFields)
            streamField = streamFields(iStream);
            streamData = runData.(streamField);
            if ~isstruct(streamData)
                continue
            end

            [convertedValue, streamOverview] = localConvertValue( ...
                streamData, converted.groups.(groupField).id, runId, streamField);
            convertedRun.(streamField) = convertedValue;
            groupOverview = localAppendTable(groupOverview, streamOverview);
        end

        converted.groups.(groupField).runs.(runField) = convertedRun;
    end

    converted.groups.(groupField).overview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

converted.overview = overview;
end

function [convertedValue, overview] = localConvertValue(value, groupId, runId, streamPath)
overview = table();
convertedValue = struct();

if isfield(value, "signal")
    [convertedValue, overview] = localConvertStream(value, groupId, runId, streamPath);
    return
end

nestedFields = string(fieldnames(value));
for iField = 1:numel(nestedFields)
    nestedField = nestedFields(iField);
    nestedValue = value.(nestedField);
    if ~isstruct(nestedValue)
        convertedValue.(nestedField) = nestedValue;
        continue
    end

    [convertedNested, nestedOverview] = localConvertValue( ...
        nestedValue, groupId, runId, streamPath + "." + nestedField);
    convertedValue.(nestedField) = convertedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [convertedStream, overview] = localConvertStream(streamData, groupId, runId, streamField)
convertedStream = struct();
convertedStream.t_s = localGetTimeVector(streamData);
convertedStream.signal = [];
convertedStream.channels = localGetChannels(streamData);
convertedStream.units = strings(1, 0);
convertedStream.sourceUnits = strings(1, 0);
convertedStream.conversion = table();

overview = table();

if ~isfield(streamData, "signal") || isempty(streamData.signal)
    return
end

signal = double(streamData.signal);
nChannels = size(signal, 2);
channels = localPadStringRow(convertedStream.channels, nChannels, "Channel_" + string(1:nChannels));
rawUnits = localPadStringRow(localGetUnits(streamData), nChannels, repmat("raw", 1, nChannels));
sourceUnits = strings(1, nChannels);
sourceUnitEvidence = strings(1, nChannels);

convertedSignal = NaN(size(signal));
targetUnits = strings(1, nChannels);
factor = NaN(1, nChannels);
offset = zeros(1, nChannels);
status = strings(1, nChannels);
rule = strings(1, nChannels);

for iChannel = 1:nChannels
    [sourceUnits(iChannel), sourceUnitEvidence(iChannel)] = localResolveSourceUnit( ...
        rawUnits(iChannel), channels(iChannel), streamField);
    [factor(iChannel), offset(iChannel), targetUnits(iChannel), ...
        status(iChannel), rule(iChannel)] = localConversionRule(sourceUnits(iChannel));
    convertedSignal(:, iChannel) = signal(:, iChannel) .* factor(iChannel) + offset(iChannel);
end

convertedStream.signal = convertedSignal;
convertedStream.channels = channels;
convertedStream.units = targetUnits;
convertedStream.sourceUnits = sourceUnits;
convertedStream.rawUnits = rawUnits;
convertedStream.sourceUnitEvidence = sourceUnitEvidence;
convertedStream.conversion = table( ...
    repmat(string(groupId), nChannels, 1), ...
    repmat(string(runId), nChannels, 1), ...
    repmat(string(streamField), nChannels, 1), ...
    (1:nChannels)', ...
    channels(:), ...
    rawUnits(:), ...
    sourceUnits(:), ...
    sourceUnitEvidence(:), ...
    targetUnits(:), ...
    factor(:), ...
    offset(:), ...
    status(:), ...
    rule(:), ...
    'VariableNames', {'GroupId','RunId','Stream','Column','Channel', ...
    'RawUnit','SourceUnit','SourceUnitEvidence','TargetUnit','Factor', ...
    'Offset','Status','Rule'});

overview = convertedStream.conversion;
end

function [sourceUnit, evidence] = localResolveSourceUnit(rawUnit, channelName, streamField)
rawUnit = string(rawUnit);
sourceUnit = strtrim(rawUnit);
evidence = "reader_unit";

unitKey = lower(strtrim(sourceUnit));
if strlength(unitKey) > 0 && unitKey ~= "raw"
    return
end

channelUnit = localExtractBracketUnit(channelName);
if strlength(channelUnit) > 0
    sourceUnit = channelUnit;
    evidence = "channel_name_bracket_unit";
    return
end

streamKey = lower(strrep(string(streamField), ".", "_"));
channelKey = lower(string(channelName));
if contains(streamKey, "h2bga")
    sourceUnit = "ppm";
    evidence = "H2BGA_raw_assumed_ppm";
elseif startsWith(streamKey, "daq")
    if contains(channelKey, "trigger") || contains(channelKey, "voltage")
        sourceUnit = "V";
        evidence = "DAQ_raw_trigger_assumed_V";
    else
        sourceUnit = "bar";
        evidence = "DAQ_raw_pressure_assumed_bar";
    end
else
    sourceUnit = rawUnit;
    evidence = "raw_unknown_unit";
end
end

function unit = localExtractBracketUnit(channelName)
unit = "";
tokens = regexp(char(string(channelName)), "\[([^\]]+)\]", "tokens", "once");
if ~isempty(tokens)
    unit = string(tokens{1});
end
end

function [factor, offset, targetUnit, status, rule] = localConversionRule(sourceUnit)
unitKey = lower(strtrim(string(sourceUnit)));
unitKey = replace(unitKey, ["％", "percent", "vol.%", "vol %", "volpct", "vol_pct"], "%");
unitKey = replace(unitKey, [" ", "_"], "");

factor = 1;
offset = 0;
targetUnit = string(sourceUnit);
status = "unchanged";
rule = "no conversion applied";

switch unitKey
    case {"bar"}
        factor = 100;
        targetUnit = "kPa";
        status = "converted";
        rule = "bar * 100 = kPa";
    case {"mbar"}
        factor = 0.1;
        targetUnit = "kPa";
        status = "converted";
        rule = "mbar * 0.1 = kPa";
    case {"pa"}
        factor = 0.001;
        targetUnit = "kPa";
        status = "converted";
        rule = "Pa * 0.001 = kPa";
    case {"kpa"}
        targetUnit = "kPa";
        rule = "already kPa";
    case {"ppm"}
        factor = 1e-4;
        targetUnit = "vol.%";
        status = "converted";
        rule = "ppm / 10000 = vol.%";
    case {"v"}
        targetUnit = "V";
        rule = "already V";
    case {"mv"}
        factor = 0.001;
        targetUnit = "V";
        status = "converted";
        rule = "mV * 0.001 = V";
    case {"%"}
        targetUnit = "vol.%";
        rule = "percent concentration relabeled as vol.%";
    case {"s"}
        targetUnit = "s";
        rule = "already seconds";
    otherwise
        if strlength(unitKey) == 0 || unitKey == "raw"
            targetUnit = "raw";
            status = "unchanged_unknown_unit";
            rule = "unknown/raw unit; signal copied unchanged";
        else
            status = "unchanged_unmapped_unit";
            rule = "unit not in conversion map; signal copied unchanged";
        end
end
end

function t = localGetTimeVector(streamData)
if isfield(streamData, "t") && ~isempty(streamData.t)
    t = streamData.t;
else
    t = [];
end
end

function channels = localGetChannels(streamData)
if isfield(streamData, "channels") && ~isempty(streamData.channels)
    channels = string(streamData.channels);
elseif isfield(streamData, "channelNames") && ~isempty(streamData.channelNames)
    channels = string(streamData.channelNames);
else
    channels = strings(1, 0);
end
channels = reshape(channels, 1, []);
end

function units = localGetUnits(streamData)
if isfield(streamData, "units") && ~isempty(streamData.units)
    units = string(streamData.units);
else
    units = strings(1, 0);
end
units = reshape(units, 1, []);
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
