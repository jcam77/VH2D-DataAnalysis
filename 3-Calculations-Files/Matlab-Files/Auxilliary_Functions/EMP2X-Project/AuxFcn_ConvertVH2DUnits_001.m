function converted = AuxFcn_ConvertVH2DUnits_001(campaign)
% AuxFcn_ConvertVH2DUnits_001
% Build a unit-converted VH2D campaign structure without modifying raw data.
%
% The returned structure mirrors campaign.groups.<group>.runs.<run>, but each
% DAQ contains converted signals and a conversion table. Conversion is based
% on explicit unit labels from the loaded raw data, channel-name unit labels
% such as "[bar]", and known DAQ-level units for H2BGA. It does not use
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
    % Preserve the original campaign hierarchy: group -> run -> DAQ.
    % Only the signal units are changed.
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

        daqFields = string(fieldnames(runData));
        daqFields = daqFields(daqFields ~= "id");
        for iDAQ = 1:numel(daqFields)
            daqField = daqFields(iDAQ);
            daqData = runData.(daqField);
            if ~isstruct(daqData)
                continue
            end

            [convertedValue, daqOverview] = localConvertValue( ...
                daqData, converted.groups.(groupField).id, runId, daqField);
            convertedRun.(daqField) = convertedValue;
            groupOverview = localAppendTable(groupOverview, daqOverview);
        end

        converted.groups.(groupField).runs.(runField) = convertedRun;
    end

    converted.groups.(groupField).overview = groupOverview;
    overview = localAppendTable(overview, groupOverview);
end

converted.overview = overview;
end

function [convertedValue, overview] = localConvertValue(value, groupId, runId, daqPath)
overview = table();
convertedValue = struct();

% A DAQ leaf is identified by the presence of `signal`. Nested containers
% such as Hydrogen_Sensors are traversed until their signal leaves are found.
if isfield(value, "signal")
    [convertedValue, overview] = localConvertDAQ(value, groupId, runId, daqPath);
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
        nestedValue, groupId, runId, daqPath + "." + nestedField);
    convertedValue.(nestedField) = convertedNested;
    overview = localAppendTable(overview, nestedOverview);
end
end

function [convertedDAQ, overview] = localConvertDAQ(daqData, groupId, runId, daqField)
convertedDAQ = struct();
convertedDAQ.t_s = localGetTimeVector(daqData);
convertedDAQ.signal = [];
convertedDAQ.channels = localGetChannels(daqData);
convertedDAQ.units = strings(1, 0);
convertedDAQ.sourceUnits = strings(1, 0);
convertedDAQ.conversion = table();

overview = table();

if ~isfield(daqData, "signal") || isempty(daqData.signal)
    return
end

signal = double(daqData.signal);
nChannels = size(signal, 2);
channels = localPadStringRow(convertedDAQ.channels, nChannels, "Channel_" + string(1:nChannels));
rawUnits = localPadStringRow(localGetUnits(daqData), nChannels, repmat("raw", 1, nChannels));
sourceUnits = strings(1, nChannels);
sourceUnitEvidence = strings(1, nChannels);

convertedSignal = NaN(size(signal));
targetUnits = strings(1, nChannels);
factor = NaN(1, nChannels);
offset = zeros(1, nChannels);
status = strings(1, nChannels);
rule = strings(1, nChannels);

%%%%%%%%%%%%%%%%%%---Units Conversion---%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iChannel = 1:nChannels
    % Resolve the source unit from evidence first, then apply a transparent
    % scalar conversion. Channel order is not used to decide the unit.
    [sourceUnits(iChannel), sourceUnitEvidence(iChannel)] = localResolveSourceUnit( ...
        rawUnits(iChannel), channels(iChannel), daqField);
    [factor(iChannel), offset(iChannel), targetUnits(iChannel), ...
        status(iChannel), rule(iChannel)] = localConversionRule(sourceUnits(iChannel));
    convertedSignal(:, iChannel) = signal(:, iChannel) .* factor(iChannel) + offset(iChannel);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

convertedDAQ.signal = convertedSignal;
convertedDAQ.channels = channels;
convertedDAQ.units = targetUnits;
convertedDAQ.sourceUnits = sourceUnits;
convertedDAQ.rawUnits = rawUnits;
convertedDAQ.sourceUnitEvidence = sourceUnitEvidence;
convertedDAQ.conversion = table( ...
    repmat(string(groupId), nChannels, 1), ...
    repmat(string(runId), nChannels, 1), ...
    repmat(string(daqField), nChannels, 1), ...
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
    'VariableNames', {'GroupId','RunId','DAQs','Column','Channel', ...
    'RawUnit','SourceUnit','SourceUnitEvidence','TargetUnit','Factor', ...
    'Offset','Status','Rule'});

overview = convertedDAQ.conversion;
end

function [sourceUnit, evidence] = localResolveSourceUnit(rawUnit, channelName, daqField)
rawUnit = string(rawUnit);
sourceUnit = strtrim(rawUnit);
evidence = "reader_unit";

% Reader-provided units are the strongest evidence and are used directly.
unitKey = lower(strtrim(sourceUnit));
if strlength(unitKey) > 0 && unitKey ~= "raw"
    return
end

% Some MF4 channels expose units in the channel name, e.g. "[bar]".
channelUnit = localExtractBracketUnit(channelName);
if strlength(channelUnit) > 0
    sourceUnit = channelUnit;
    evidence = "channel_name_bracket_unit";
    return
end

daqKey = lower(strrep(string(daqField), ".", "_"));
channelKey = lower(string(channelName));
% If the file does not expose units, record the assumption in the evidence
% column instead of silently converting.
if contains(daqKey, "h2bga")
    sourceUnit = "ppm";
    evidence = "H2BGA_raw_assumed_ppm";
elseif startsWith(daqKey, "daq")
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

function t = localGetTimeVector(daqData)
if isfield(daqData, "t") && ~isempty(daqData.t)
    t = daqData.t;
else
    t = [];
end
end

function channels = localGetChannels(daqData)
if isfield(daqData, "channels") && ~isempty(daqData.channels)
    channels = string(daqData.channels);
elseif isfield(daqData, "channelNames") && ~isempty(daqData.channelNames)
    channels = string(daqData.channelNames);
else
    channels = strings(1, 0);
end
channels = reshape(channels, 1, []);
end

function units = localGetUnits(daqData)
if isfield(daqData, "units") && ~isempty(daqData.units)
    units = string(daqData.units);
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
