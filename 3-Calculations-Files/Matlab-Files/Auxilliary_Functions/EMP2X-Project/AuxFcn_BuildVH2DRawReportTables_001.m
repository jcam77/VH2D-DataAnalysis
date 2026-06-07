function reportTables = AuxFcn_BuildVH2DRawReportTables_001(campaign, metadata)
% AuxFcn_BuildVH2DRawReportTables_001
% Build small, readable tables for the VH2D raw-data DPP report.
%
% The complete raw data and complete metadata remain in campaign/metadata.
% This helper only selects the columns that are useful for report overview.

arguments
    campaign (1,1) struct
    metadata (1,1) struct
end

rawOverviewTable = AuxFcn_BuildVH2DRawOverviewTable_001(campaign, metadata);

reportTables = struct();
reportTables.rawLoadStatus = localRawLoadStatusTable(rawOverviewTable);
reportTables.rawLoadStatusDisplay = localAddRunSeparatorRows( ...
    reportTables.rawLoadStatus);
reportTables.runPlan = localSelectTableColumns(metadata.experimentPlanTable, [ ...
    "RunId", "TargetH2_vol_pct", "Ignition", "Vent", ...
    "MFCFlow_slpm", "RecircStopToIgnition_s"]);
reportTables.gasMixing = localSelectTableColumns(metadata.gasMixingTable, [ ...
    "RunId", "targetVol", "tChamberC", "mfcFlowSlpm", ...
    "V_chamber_geom_m3", "volPipesM3", "V_chamber_corrected_m3", ...
    "mH2EstimatedG", "mH2CorrectedG", "V_H2_injected_m3"]);
reportTables.daqSystems = localSelectTableColumns(metadata.daqSystemsTable, [ ...
    "DaqSystem", "Owner", "MeasuredQuantity", "ChannelCount", ...
    "SamplingRate_Hz", "LastCalibrationDate"]);
sensorMappingTable = localAddLoadedDataChannels( ...
    metadata.sensorMappingTable, campaign);
% reportTables.sensorMap = localSelectTableColumns(sensorMappingTable, [ ...
%     "GroupId", "DaqSystem", "DaqChannel", "SensorId", "LocationLabel","IsBlindSensor", "LoadedDataChannel", ...
%     "LoadedDataColumn", "LoadedDataMatch", ...
%     "MeasuredQuantity", "X_m", "Y_m", "Z_m", "Sensitivity", ...
%     "SensitivityUnit"]);
reportTables.sensorMap = localSelectTableColumns(sensorMappingTable, [ ...
    "GroupId", "DaqSystem", "DaqChannel", "SensorId", "LocationLabel","IsBlindSensor", "LoadedDataChannel", ...
    "LoadedDataColumn", "LoadedDataMatch", ...
    "MeasuredQuantity", "Sensitivity", ...
    "SensitivityUnit"]);
reportTables.groupNotes = localSelectTableColumns(metadata.groupNotesTable, [ ...
    "GroupId", "GroupNote"]);
reportTables.groupAndRunNotes = localGroupAndRunNotesTable( ...
    rawOverviewTable, metadata);
reportTables.runNotes = reportTables.groupAndRunNotes(:, ...
    {'GroupId', 'RunId', 'Notes'});

end

function tbl = localRawLoadStatusTable(rawOverviewTable)
streamPrefixes = ["DAQ_1", "DAQ_2_3", "DAQ_4", "H2BGA", ...
    "HS_D_2", "HS_D_3"];
fallbackPrefixes = ["", "DAQ_2", "", "", "", ""];
daqSystems = ["DAQ_1", "DAQ_2_3", "DAQ_4", "H2BGA", ...
    "HS_D_2", "HS_D_3"];

tbl = table();
for iPrefix = 1:numel(streamPrefixes)
    streamPrefix = localResolveOverviewPrefix(rawOverviewTable, ...
        streamPrefixes(iPrefix), fallbackPrefixes(iPrefix));
    nRows = height(rawOverviewTable);
    DAQ_System = repmat(daqSystems(iPrefix), nRows, 1);
    streamTable = table(rawOverviewTable.RunId, ...
        DAQ_System, ...
        localGetNumericColumn(rawOverviewTable, streamPrefix + "_Samples"), ...
        localGetNumericColumn(rawOverviewTable, streamPrefix + "_Channels"), ...
        localGetNumericColumn(rawOverviewTable, streamPrefix + "_Fs_Hz"), ...
        localGetStringColumn(rawOverviewTable, streamPrefix + "_Status"), ...
        'VariableNames', {'RunId','DAQ_System','Samples','Channels','Fs_Hz','Status'});
    tbl = [tbl; streamTable]; %#ok<AGROW>
end

tbl = sortrows(tbl, {'RunId','DAQ_System'});

end

function streamPrefix = localResolveOverviewPrefix(tbl, preferredPrefix, fallbackPrefix)
streamPrefix = string(preferredPrefix);
if ismember(char(streamPrefix + "_Samples"), tbl.Properties.VariableNames)
    return
end

fallbackPrefix = string(fallbackPrefix);
if strlength(fallbackPrefix) > 0 && ...
        ismember(char(fallbackPrefix + "_Samples"), tbl.Properties.VariableNames)
    streamPrefix = fallbackPrefix;
end
end

function displayTbl = localAddRunSeparatorRows(tbl)
displayTbl = table();
runIds = unique(tbl.RunId, 'stable');

for iRun = 1:numel(runIds)
    thisRunId = runIds(iRun);
    runRows = tbl(tbl.RunId == thisRunId, :);
    displayTbl = [displayTbl; localStringDisplayTable(runRows)]; %#ok<AGROW>

    if iRun < numel(runIds)
        displayTbl = [displayTbl; localSeparatorRow(width(displayTbl))]; %#ok<AGROW>
    end
end
end

function displayTbl = localStringDisplayTable(tbl)
displayTbl = table( ...
    string(tbl.RunId), ...
    string(tbl.DAQ_System), ...
    string(tbl.Samples), ...
    string(tbl.Channels), ...
    string(tbl.Fs_Hz), ...
    string(tbl.Status), ...
    'VariableNames', {'RunId','DAQ_System','Samples','Channels','Fs_Hz','Status'});
end

function sensorMap = localAddLoadedDataChannels(sensorMap, campaign)
if isempty(sensorMap) || ~isfield(campaign, 'groups') || isempty(campaign.groups)
    return
end

nRows = height(sensorMap);
LoadedDataChannel = strings(nRows, 1);
LoadedDataColumn = strings(nRows, 1);
LoadedDataMatch = strings(nRows, 1);

for iRow = 1:nRows
    groupId = string(sensorMap.GroupId(iRow));
    daqSystem = string(sensorMap.DaqSystem(iRow));
    daqChannel = string(sensorMap.DaqChannel(iRow));
    sensorId = string(sensorMap.SensorId(iRow));
    isTrigger = false;
    if ismember('IsTriggerChannel', sensorMap.Properties.VariableNames)
        isTrigger = logical(sensorMap.IsTriggerChannel(iRow));
    end

    loaded = localLoadedChannelsForMapping(campaign, groupId, daqSystem);
    match = localMatchLoadedChannel(loaded, daqSystem, daqChannel, sensorId, isTrigger);

    LoadedDataChannel(iRow) = match.Channel;
    LoadedDataColumn(iRow) = match.Column;
    LoadedDataMatch(iRow) = match.Evidence;
end

if ismember('DaqChannel', sensorMap.Properties.VariableNames)
    sensorMap = addvars(sensorMap, LoadedDataChannel, LoadedDataColumn, ...
        LoadedDataMatch, 'After', 'DaqChannel');
else
    sensorMap = addvars(sensorMap, LoadedDataChannel, LoadedDataColumn, ...
        LoadedDataMatch);
end
end

function loaded = localLoadedChannelsForMapping(campaign, groupId, daqSystem)
loaded = table(strings(0,1), strings(0,1), zeros(0,1), strings(0,1), ...
    'VariableNames', {'RunId','Stream','Column','Channel'});

groupFields = string(fieldnames(campaign.groups));
groupIds = strings(numel(groupFields), 1);
for iGroup = 1:numel(groupFields)
    groupIds(iGroup) = localNormalizeId( ...
        localGetStringField(campaign.groups.(groupFields(iGroup)), 'id', groupFields(iGroup)));
end

iGroup = find(groupIds == localNormalizeId(groupId), 1);
if isempty(iGroup)
    return
end

groupData = campaign.groups.(groupFields(iGroup));
if ~isfield(groupData, 'runs') || isempty(groupData.runs)
    return
end

streamFields = localStreamFieldsForDaqSystem(daqSystem);
runFields = string(fieldnames(groupData.runs));
for iRun = 1:numel(runFields)
    runData = groupData.runs.(runFields(iRun));
    runId = localGetStringField(runData, 'id', runFields(iRun));

    for iStream = 1:numel(streamFields)
        streamField = streamFields(iStream);
        if ~isfield(runData, streamField)
            continue
        end

        streamData = runData.(streamField);
        if ~isstruct(streamData) || ~isfield(streamData, 'channels') || ...
                isempty(streamData.channels)
            continue
        end

        channels = string(streamData.channels(:));
        nChannels = numel(channels);
        loaded = [loaded; table( ...
            repmat(string(runId), nChannels, 1), ...
            repmat(string(streamField), nChannels, 1), ...
            (1:nChannels)', ...
            channels, ...
            'VariableNames', {'RunId','Stream','Column','Channel'})]; %#ok<AGROW>
    end
end
end

function match = localMatchLoadedChannel(loaded, daqSystem, daqChannel, sensorId, isTrigger)
match = struct('Channel', "", 'Column', "", 'Evidence', "not_found");
if isempty(loaded)
    return
end

channelKey = lower(string(loaded.Channel));

[daqChannelMatch, daqEvidence] = localMatchByDaqChannel(loaded, daqSystem, daqChannel);
if any(daqChannelMatch)
    match = localBuildLoadedMatch(loaded, daqChannelMatch, daqEvidence);
    return
end

[sensorMatch, sensorEvidence] = localMatchBySensorId(loaded, sensorId);
if any(sensorMatch)
    match = localBuildLoadedMatch(loaded, sensorMatch, sensorEvidence);
    return
end

if isTrigger
    triggerMatch = contains(channelKey, "trigger") | contains(channelKey, "voltage");
    if any(triggerMatch)
        match = localBuildLoadedMatch(loaded, triggerMatch, "trigger_channel_name");
    end
end
end

function [mask, evidence] = localMatchByDaqChannel(loaded, daqSystem, daqChannel)
daqSystem = localNormalizeDaqSystem(daqSystem);
channelNumber = localDaqChannelNumber(daqChannel);
mask = false(height(loaded), 1);
evidence = "not_found";
if isnan(channelNumber)
    return
end

channelText = string(loaded.Channel);
channelKey = lower(channelText);

if daqSystem == "DAQ-1"
    mask = contains(channelKey, "a" + string(channelNumber));
    evidence = "DAQ-1_A_channel_from_DaqChannel";
elseif daqSystem == "DAQ-2" || daqSystem == "DAQ-3" || daqSystem == "DAQ-4"
    expected = lower(daqSystem + "-channel" + string(channelNumber));
    mask = contains(channelKey, expected);
    evidence = "DAQ_channel_name_from_DaqSystem_DaqChannel";
end
end

function [mask, evidence] = localMatchBySensorId(loaded, sensorId)
sensorToken = localSensorToken(sensorId);
mask = false(height(loaded), 1);
evidence = "not_found";
if strlength(sensorToken) == 0
    return
end

channelKey = lower(string(loaded.Channel));
tokenKey = lower(sensorToken);
mask = startsWith(channelKey, tokenKey + "_") | ...
    startsWith(channelKey, tokenKey + "-") | ...
    channelKey == tokenKey;
evidence = "loaded_channel_name_from_sensor_id";
end

function match = localBuildLoadedMatch(loaded, mask, evidence)
matched = loaded(mask, :);
channels = unique(string(matched.Channel), 'stable');

columnPairs = strings(height(matched), 1);
for i = 1:height(matched)
    columnPairs(i) = string(matched.RunId(i)) + ":col" + string(matched.Column(i));
end
columnPairs = unique(columnPairs, 'stable');

match = struct();
match.Channel = strjoin(channels, "; ");
match.Column = strjoin(columnPairs, "; ");
match.Evidence = string(evidence);
end

function streamFields = localStreamFieldsForDaqSystem(daqSystem)
daqSystem = localNormalizeDaqSystem(daqSystem);
switch daqSystem
    case "DAQ-1"
        streamFields = ["DAQ_1"];
    case "DAQ-2"
        streamFields = ["DAQ_2", "DAQ_2_3"];
    case "DAQ-3"
        streamFields = ["DAQ_3", "DAQ_2_3"];
    case "DAQ-4"
        streamFields = ["DAQ_4"];
    otherwise
        streamFields = strings(0,1);
end
end

function value = localNormalizeDaqSystem(value)
value = upper(strtrim(string(value)));
value = replace(value, "_", "-");
end

function channelNumber = localDaqChannelNumber(daqChannel)
tokens = regexp(char(lower(string(daqChannel))), "ch\s*(\d+)", ...
    "tokens", "once");
if isempty(tokens)
    channelNumber = NaN;
else
    channelNumber = str2double(tokens{1});
end
end

function token = localSensorToken(sensorId)
sensorId = string(sensorId);
tokens = regexp(char(sensorId), "^(P\d+|Trig-\d+)", "tokens", "once");
if isempty(tokens)
    token = "";
else
    token = string(tokens{1});
end
end

function row = localSeparatorRow(nVariables)
separator = repmat("----------------", 1, nVariables);
row = array2table(separator, ...
    'VariableNames', {'RunId','DAQ_System','Samples','Channels','Fs_Hz','Status'});
end

function notesTbl = localGroupAndRunNotesTable(rawOverviewTable, metadata)
RunId = unique(string(rawOverviewTable.RunId), 'stable');
RunKey = localNormalizeId(RunId);
GroupId = regexprep(RunKey, "-\d+$", "");

GroupNote = strings(numel(RunId), 1);
Notes = strings(numel(RunId), 1);

if isfield(metadata, 'groupNotesTable') && ~isempty(metadata.groupNotesTable)
    groupTbl = metadata.groupNotesTable;
    groupKeys = localNormalizeId(string(groupTbl.GroupId));
    for iRun = 1:numel(RunId)
        iGroup = find(groupKeys == GroupId(iRun), 1);
        if ~isempty(iGroup)
            GroupNote(iRun) = string(groupTbl.GroupNote(iGroup));
        end
    end
end

if isfield(metadata, 'experimentPlanRaw') && ...
        isfield(metadata.experimentPlanRaw, 'experiments')
    experiments = metadata.experimentPlanRaw.experiments;
    for iExperiment = 1:numel(experiments)
        experiment = localGetJsonItem(experiments, iExperiment);
        if ~isfield(experiment, 'name')
            continue
        end

        experimentKey = localNormalizeId(string(experiment.name));
        iRun = find(RunKey == experimentKey, 1);
        if isempty(iRun) || ~isfield(experiment, 'notes')
            continue
        end

        Notes(iRun) = localSingleLineText(string(experiment.notes));
    end
end

notesTbl = table(GroupId, RunId, GroupNote, Notes);
notesTbl = sortrows(notesTbl, {'GroupId','RunId'});
end

function value = localNormalizeId(value)
value = string(value);
dashChars = ["–","—","−","‑"];
for iDash = 1:numel(dashChars)
    value = replace(value, dashChars(iDash), "-");
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

function item = localGetJsonItem(items, idx)
if iscell(items)
    item = items{idx};
else
    item = items(idx);
end
end

function value = localSingleLineText(value)
value = string(value);
value = replace(value, newline, " | ");
value = regexprep(value, "\s+", " ");
value = strtrim(value);
end

function tbl = localSelectTableColumns(tbl, requestedVars)
if isempty(tbl)
    return
end

availableVars = string(tbl.Properties.VariableNames);
keepVars = requestedVars(ismember(requestedVars, availableVars));
tbl = tbl(:, cellstr(keepVars));
end

function values = localGetNumericColumn(tbl, variableName)
variableName = char(variableName);
if ismember(variableName, tbl.Properties.VariableNames)
    values = tbl.(variableName);
else
    values = NaN(height(tbl), 1);
end
end

function values = localGetStringColumn(tbl, variableName)
variableName = char(variableName);
if ismember(variableName, tbl.Properties.VariableNames)
    values = string(tbl.(variableName));
else
    values = repmat("not_in_campaign", height(tbl), 1);
end
end
