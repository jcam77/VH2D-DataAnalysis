function [channelAuditTable, channelAuditSummaryTable, channelAuditWarningTable] = ...
    AuxFcn_BuildVH2DChannelAuditTable_001(campaign, metadata, options)
% AuxFcn_BuildVH2DChannelAuditTable_001
% Evidence-only audit of loaded channel order versus sensor mapping metadata.
%
% This function does not infer sensor identity from channel names. It only
% reports:
%   - loaded DAQ/channel information from the data file
%   - expected DAQ/sensor/channel information from sensors_mapping.json
%   - whether a loaded channel name changes column across runs

arguments
    campaign (1,1) struct
    metadata (1,1) struct
    options.DAQs string = ["DAQ_1", "DAQ_2_3", "DAQ_4"]
end

sensorMap = table();
if isfield(metadata, 'sensorMappingTable')
    sensorMap = metadata.sensorMappingTable;
end

GroupId = strings(0,1);
RunId = strings(0,1);
RunField = strings(0,1);
LoadedDAQs = strings(0,1);
LoadedField = strings(0,1);
Column = zeros(0,1);
LoadedChannelName = strings(0,1);
ExpectedMappedDaqSystems = strings(0,1);
ExpectedSensorIds = strings(0,1);
ExpectedDaqChannels = strings(0,1);
ExpectedLocationLabels = strings(0,1);
ExpectedMountingMethods = strings(0,1);
ExpectedMeasuredQuantities = strings(0,1);

if isfield(campaign, 'groups')
    groupFields = string(fieldnames(campaign.groups));
else
    groupFields = strings(0,1);
end

for iGroup = 1:numel(groupFields)
    % Audit one group/run at a time so every result row can be traced back
    % directly to the campaign folder hierarchy.
    groupData = campaign.groups.(groupFields(iGroup));
    if ~isfield(groupData, 'runs')
        continue
    end

    groupId = localGetStringField(groupData, 'id', groupFields(iGroup));
    runFields = string(fieldnames(groupData.runs));
    for iRun = 1:numel(runFields)
        runData = groupData.runs.(runFields(iRun));
        runId = localGetStringField(runData, 'id', runFields(iRun));

        for iDAQ = 1:numel(options.DAQs)
            requestedDAQs = string(options.DAQs(iDAQ));
            loadedField = localResolveRunDAQField(runData, requestedDAQs);
            loadedDAQs = requestedDAQs;
            if strlength(loadedField) == 0
                continue
            end

            daqData = runData.(loadedField);
            if ~isfield(daqData, 'channels') || isempty(daqData.channels)
                continue
            end

            expected = localExpectedMetadata(sensorMap, groupId, loadedDAQs);
            loadedChannels = string(daqData.channels(:));
            for iChannel = 1:numel(loadedChannels)
                % No sensor identity is inferred here. The loaded channel
                % is recorded next to the expected metadata for transparent
                % manual verification.
                GroupId(end+1,1) = groupId; %#ok<AGROW>
                RunId(end+1,1) = runId; %#ok<AGROW>
                RunField(end+1,1) = runFields(iRun); %#ok<AGROW>
                LoadedDAQs(end+1,1) = loadedDAQs; %#ok<AGROW>
                LoadedField(end+1,1) = loadedField; %#ok<AGROW>
                Column(end+1,1) = iChannel; %#ok<AGROW>
                LoadedChannelName(end+1,1) = loadedChannels(iChannel); %#ok<AGROW>
                ExpectedMappedDaqSystems(end+1,1) = expected.DaqSystems; %#ok<AGROW>
                ExpectedSensorIds(end+1,1) = expected.SensorIds; %#ok<AGROW>
                ExpectedDaqChannels(end+1,1) = expected.DaqChannels; %#ok<AGROW>
                ExpectedLocationLabels(end+1,1) = expected.LocationLabels; %#ok<AGROW>
                ExpectedMountingMethods(end+1,1) = expected.MountingMethods; %#ok<AGROW>
                ExpectedMeasuredQuantities(end+1,1) = expected.MeasuredQuantities; %#ok<AGROW>
            end
        end
    end
end

channelAuditTable = table(GroupId, RunId, RunField, LoadedDAQs, ...
    LoadedField, Column, LoadedChannelName, ExpectedMappedDaqSystems, ...
    ExpectedSensorIds, ExpectedDaqChannels, ExpectedLocationLabels, ...
    ExpectedMountingMethods, ExpectedMeasuredQuantities);
channelAuditTable = localAddColumnConsistencyStatus(channelAuditTable);
channelAuditTable = sortrows(channelAuditTable, ...
    {'GroupId', 'RunId', 'LoadedDAQs', 'Column'});

[channelAuditSummaryTable, channelAuditWarningTable] = ...
    localBuildReportTables(channelAuditTable);

end

function value = localGetStringField(data, fieldName, fallback)
if isfield(data, fieldName) && ~isempty(data.(fieldName))
    value = string(data.(fieldName));
else
    value = string(fallback);
end
end

function expected = localExpectedMetadata(sensorMap, groupId, loadedDAQs)
expected = localEmptyExpectedMetadata();
if isempty(sensorMap)
    return
end

groupKey = localNormalizeId(groupId);
daqKey = localNormalizeDaqSystem(loadedDAQs);
mapGroup = localNormalizeId(string(sensorMap.GroupId));
mapDaq = localNormalizeDaqSystem(string(sensorMap.DaqSystem));
rowMask = mapGroup == groupKey & localDaqMatchesDAQs(mapDaq, daqKey);
idx = find(rowMask);
if isempty(idx)
    return
end

expected.DaqSystems = localJoinUnique(strtrim(string(sensorMap.DaqSystem(idx))));
expected.SensorIds = localJoinUnique(string(sensorMap.SensorId(idx)));
expected.DaqChannels = localJoinUnique(string(sensorMap.DaqChannel(idx)));
expected.LocationLabels = localJoinUnique(string(sensorMap.LocationLabel(idx)));
expected.MountingMethods = localJoinUnique(string(sensorMap.MountingMethod(idx)));
expected.MeasuredQuantities = localJoinUnique(string(sensorMap.MeasuredQuantity(idx)));
end

function expected = localEmptyExpectedMetadata()
expected = struct();
expected.DaqSystems = "";
expected.SensorIds = "";
expected.DaqChannels = "";
expected.LocationLabels = "";
expected.MountingMethods = "";
expected.MeasuredQuantities = "";
end

function tbl = localAddColumnConsistencyStatus(tbl)
ColumnConsistencyStatus = repmat("single_or_consistent_column", height(tbl), 1);

for iRow = 1:height(tbl)
    sameChannelRows = tbl.GroupId == tbl.GroupId(iRow) & ...
        tbl.LoadedDAQs == tbl.LoadedDAQs(iRow) & ...
        tbl.LoadedChannelName == tbl.LoadedChannelName(iRow);

    if numel(unique(tbl.Column(sameChannelRows))) > 1
        ColumnConsistencyStatus(iRow) = "WARNING_channel_column_changed";
    end
end

tbl.ColumnConsistencyStatus = ColumnConsistencyStatus;
end

function [summaryTable, warningTable] = localBuildReportTables(auditTable)
if isempty(auditTable)
    summaryTable = table();
    warningTable = table();
    return
end

auditTable.HasAuditWarning = ...
    startsWith(auditTable.ColumnConsistencyStatus, "WARNING");

summaryTable = groupsummary(auditTable, ...
    ["GroupId","LoadedDAQs"], "sum", "HasAuditWarning");
summaryTable.Properties.VariableNames{ ...
    strcmp(summaryTable.Properties.VariableNames, ...
    'GroupCount')} = 'LoadedChannels';
summaryTable.Properties.VariableNames{ ...
    strcmp(summaryTable.Properties.VariableNames, ...
    'sum_HasAuditWarning')} = 'Warnings';
summaryTable = localAddMetadataToSummary(summaryTable, auditTable);

warningTable = auditTable(auditTable.HasAuditWarning, :);
warningTable = warningTable(:, ...
    {'GroupId','RunId','LoadedDAQs','Column','LoadedChannelName', ...
    'ExpectedMappedDaqSystems','ExpectedSensorIds','ExpectedDaqChannels', ...
    'ExpectedLocationLabels','ExpectedMountingMethods', ...
    'ColumnConsistencyStatus'});
end

function summaryTable = localAddMetadataToSummary(summaryTable, auditTable)
LoadedChannelNames = strings(height(summaryTable), 1);
ExpectedMappedDaqSystems = strings(height(summaryTable), 1);
ExpectedSensorIds = strings(height(summaryTable), 1);
ExpectedDaqChannels = strings(height(summaryTable), 1);
ExpectedLocationLabels = strings(height(summaryTable), 1);
ExpectedMountingMethods = strings(height(summaryTable), 1);
ExpectedMeasuredQuantities = strings(height(summaryTable), 1);

for iRow = 1:height(summaryTable)
    rowMask = auditTable.GroupId == summaryTable.GroupId(iRow) & ...
        auditTable.LoadedDAQs == summaryTable.LoadedDAQs(iRow);
    rows = auditTable(rowMask, :);

    LoadedChannelNames(iRow) = localJoinUnique(rows.LoadedChannelName);
    ExpectedMappedDaqSystems(iRow) = ...
        localFirstNonEmpty(rows.ExpectedMappedDaqSystems);
    ExpectedSensorIds(iRow) = localFirstNonEmpty(rows.ExpectedSensorIds);
    ExpectedDaqChannels(iRow) = localFirstNonEmpty(rows.ExpectedDaqChannels);
    ExpectedLocationLabels(iRow) = ...
        localFirstNonEmpty(rows.ExpectedLocationLabels);
    ExpectedMountingMethods(iRow) = ...
        localFirstNonEmpty(rows.ExpectedMountingMethods);
    ExpectedMeasuredQuantities(iRow) = ...
        localFirstNonEmpty(rows.ExpectedMeasuredQuantities);
end

summaryTable.LoadedChannelNames = LoadedChannelNames;
summaryTable.ExpectedMappedDaqSystems = ExpectedMappedDaqSystems;
summaryTable.ExpectedSensorIds = ExpectedSensorIds;
summaryTable.ExpectedDaqChannels = ExpectedDaqChannels;
summaryTable.ExpectedLocationLabels = ExpectedLocationLabels;
summaryTable.ExpectedMountingMethods = ExpectedMountingMethods;
summaryTable.ExpectedMeasuredQuantities = ExpectedMeasuredQuantities;
end

function value = localJoinUnique(values)
values = string(values);
values = values(strlength(values) > 0);
value = strjoin(unique(values, 'stable'), "; ");
end

function value = localFirstNonEmpty(values)
values = string(values);
idx = find(strlength(values) > 0, 1);
if isempty(idx)
    value = "";
else
    value = values(idx);
end
end

function value = localNormalizeId(value)
value = string(value);
dashChars = ["–","—","−","‑"];
for iDash = 1:numel(dashChars)
    value = replace(value, dashChars(iDash), "-");
end
end

function value = localNormalizeDaqSystem(value)
value = upper(strtrim(string(value)));
value = replace(value, "_", "-");
end

function daqField = localResolveRunDAQField(runData, requestedDAQs)
requestedDAQs = string(requestedDAQs);
aliases = localDAQFieldAliases(requestedDAQs);
daqField = "";

for iAlias = 1:numel(aliases)
    if isfield(runData, aliases(iAlias))
        daqField = aliases(iAlias);
        return
    end
end
end

function aliases = localDAQFieldAliases(daqField)
daqField = string(daqField);
switch daqField
    case "DAQ_2"
        aliases = ["DAQ_2", "DAQ_2_3"];
    case "DAQ_2_3"
        aliases = ["DAQ_2_3", "DAQ_2"];
    otherwise
        aliases = daqField;
end
end

function tf = localDaqMatchesDAQs(mapDaq, daqKey)
mapDaq = localNormalizeDaqSystem(mapDaq);
daqKey = localNormalizeDaqSystem(daqKey);
tf = mapDaq == daqKey;

% The data file for DAQ-2 and DAQ-3 can be loaded as one combined DAQ_2_3
% structure, while the metadata lists physical DAQ-2 and DAQ-3 separately.
if daqKey == "DAQ-2" || daqKey == "DAQ-2-3"
    tf = tf | mapDaq == "DAQ-2" | mapDaq == "DAQ-3";
end
end
