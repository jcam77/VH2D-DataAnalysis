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
    "RunId", "GroupId", "TargetH2_vol_pct", "Ignition", "Vent", ...
    "MFCFlow_slpm", "RecircStopToIgnition_s", "IsPreparation", "Done"]);
reportTables.gasMixing = localSelectTableColumns(metadata.gasMixingTable, [ ...
    "RunId", "targetVol", "tChamberC", "mfcFlowSlpm", ...
    "V_chamber_geom_m3", "volPipesM3", "V_chamber_corrected_m3", ...
    "mH2EstimatedG", "mH2CorrectedG", "V_H2_injected_m3"]);
reportTables.daqSystems = localSelectTableColumns(metadata.daqSystemsTable, [ ...
    "DaqSystem", "Owner", "MeasuredQuantity", "ChannelCount", ...
    "SamplingRate_Hz", "LastCalibrationDate", "IsActive"]);
reportTables.sensorMap = localSelectTableColumns(metadata.sensorMappingTable, [ ...
    "GroupId", "DaqSystem", "DaqChannel", "SensorId", "LocationLabel", ...
    "MeasuredQuantity", "X_m", "Y_m", "Z_m", "Sensitivity", ...
    "SensitivityUnit", "IsActive", "IsBlindSensor"]);
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
