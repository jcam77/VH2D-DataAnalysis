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
% Compact raw-data loading status: one row per run and DAQ/sensor system.
reportTables.rawLoadStatus = localRawLoadStatusTable(rawOverviewTable);
reportTables.rawLoadStatusDisplay = localAddRunSeparatorRows( ...
    reportTables.rawLoadStatus);
% Metadata-derived tables: select only the fields useful in the DPP report.
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
    "GroupId", "DaqSystem", "DaqChannel", "SensorId", "LocationLabel", ...
    "IsBlindSensor", "IsTriggerChannel", "IsActive", ...
    "MountingMethod", "Notes", "LoadedDataChannel", ...
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
% Convert the wide raw overview table into a long table sorted by run. This
% makes it easier to see, for each run, which DAQs/sensors loaded correctly.
daqPrefixes = ["DAQ_1", "DAQ_2_3", "DAQ_4", "H2BGA", ...
    "HS_D_2", "HS_D_3"];
fallbackPrefixes = ["", "DAQ_2", "", "", "", ""];
daqNames = ["DAQ_1", "DAQ_2_3", "DAQ_4", "H2BGA", ...
    "HS_D_2", "HS_D_3"];

tbl = table();
for iPrefix = 1:numel(daqPrefixes)
    daqPrefix = localResolveOverviewPrefix(rawOverviewTable, ...
        daqPrefixes(iPrefix), fallbackPrefixes(iPrefix));
    nRows = height(rawOverviewTable);
    DAQs = repmat(daqNames(iPrefix), nRows, 1);
    daqTable = table(rawOverviewTable.RunId, ...
        DAQs, ...
        localGetNumericColumn(rawOverviewTable, daqPrefix + "_Samples"), ...
        localGetNumericColumn(rawOverviewTable, daqPrefix + "_Channels"), ...
        localGetNumericColumn(rawOverviewTable, daqPrefix + "_Fs_Hz"), ...
        localGetStringColumn(rawOverviewTable, daqPrefix + "_Status"), ...
        'VariableNames', {'RunId','DAQs','Samples','Channels','Fs_Hz','Status'});
    tbl = [tbl; daqTable]; %#ok<AGROW>
end

tbl = sortrows(tbl, {'RunId','DAQs'});

end

function daqPrefix = localResolveOverviewPrefix(tbl, preferredPrefix, fallbackPrefix)
daqPrefix = string(preferredPrefix);
if ismember(char(daqPrefix + "_Samples"), tbl.Properties.VariableNames)
    return
end

fallbackPrefix = string(fallbackPrefix);
if strlength(fallbackPrefix) > 0 && ...
        ismember(char(fallbackPrefix + "_Samples"), tbl.Properties.VariableNames)
    daqPrefix = fallbackPrefix;
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
    string(tbl.DAQs), ...
    string(tbl.Samples), ...
    string(tbl.Channels), ...
    string(tbl.Fs_Hz), ...
    string(tbl.Status), ...
    'VariableNames', {'RunId','DAQs','Samples','Channels','Fs_Hz','Status'});
end

function sensorMap = localAddLoadedDataChannels(sensorMap, campaign)
if isempty(sensorMap) || ~isfield(campaign, 'groups') || isempty(campaign.groups)
    return
end

% Add loaded-channel evidence from the raw data next to each metadata mapping
% row. This supports traceability without guessing sensor identity.
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
    'VariableNames', {'RunId','DAQs','Column','Channel'});

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

daqFields = localDAQFieldsForDaqSystem(daqSystem);
runFields = string(fieldnames(groupData.runs));
for iRun = 1:numel(runFields)
    runData = groupData.runs.(runFields(iRun));
    runId = localGetStringField(runData, 'id', runFields(iRun));

    for iDAQ = 1:numel(daqFields)
        daqField = daqFields(iDAQ);
        if ~isfield(runData, daqField)
            continue
        end

        daqData = runData.(daqField);
        if ~isstruct(daqData) || ~isfield(daqData, 'channels') || ...
                isempty(daqData.channels)
            continue
        end

        channels = string(daqData.channels(:));
        nChannels = numel(channels);
        loaded = [loaded; table( ...
            repmat(string(runId), nChannels, 1), ...
            repmat(string(daqField), nChannels, 1), ...
            (1:nChannels)', ...
            channels, ...
            'VariableNames', {'RunId','DAQs','Column','Channel'})]; %#ok<AGROW>
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

function daqFields = localDAQFieldsForDaqSystem(daqSystem)
daqSystem = localNormalizeDaqSystem(daqSystem);
switch daqSystem
    case "DAQ-1"
        daqFields = ["DAQ_1"];
    case "DAQ-2"
        daqFields = ["DAQ_2", "DAQ_2_3"];
    case "DAQ-3"
        daqFields = ["DAQ_3", "DAQ_2_3"];
    case "DAQ-4"
        daqFields = ["DAQ_4"];
    otherwise
        daqFields = strings(0,1);
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
    'VariableNames', {'RunId','DAQs','Samples','Channels','Fs_Hz','Status'});
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
