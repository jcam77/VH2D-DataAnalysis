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
reportTables.runPlan = localSelectTableColumns(metadata.experimentPlanTable, [ ...
    "RunId", "GroupId", "TargetH2_vol_pct", "Ignition", "Vent", ...
    "MFCFlow_slpm", "RecircStopToIgnition_s", "IsPreparation", "Done"]);
reportTables.gasMixing = localSelectTableColumns(metadata.gasMixingTable, [ ...
    "RunId", "GroupId", "TargetH2_vol_pct", "H2MassInjected_g", ...
    "H2VolumeStd_L", "InjectionTime_s", "InjectionTime_min", ...
    "PChamber_Pa", "TChamber_K"]);
reportTables.daqSystems = localSelectTableColumns(metadata.daqSystemsTable, [ ...
    "DaqSystem", "Owner", "MeasuredQuantity", "ChannelCount", ...
    "SamplingRate_Hz", "LastCalibrationDate", "IsActive"]);
reportTables.sensorMap = localSelectTableColumns(metadata.sensorMappingTable, [ ...
    "GroupId", "DaqSystem", "DaqChannel", "SensorId", "LocationLabel", ...
    "MeasuredQuantity", "X_m", "Y_m", "Z_m", "Sensitivity", ...
    "SensitivityUnit", "IsActive", "IsBlindSensor"]);
reportTables.groupNotes = localSelectTableColumns(metadata.groupNotesTable, [ ...
    "GroupId", "GroupNote"]);

end

function tbl = localRawLoadStatusTable(rawOverviewTable)
streamPrefixes = ["DAQ_1", "DAQ_2_3", "DAQ_4", "H2CM", ...
    "Hydrogen_Sensors_Sensor_1", "Hydrogen_Sensors_Sensor_2"];
daqSystems = ["DAQ_1", "DAQ_2_3", "DAQ_4", "H2CM", ...
    "Hydrogen_Sensor_1", "Hydrogen_Sensor_2"];

tbl = table();
for iPrefix = 1:numel(streamPrefixes)
    nRows = height(rawOverviewTable);
    DAQ_System = repmat(daqSystems(iPrefix), nRows, 1);
    streamTable = table(rawOverviewTable.RunId, ...
        DAQ_System, ...
        localGetNumericColumn(rawOverviewTable, streamPrefixes(iPrefix) + "_Samples"), ...
        localGetNumericColumn(rawOverviewTable, streamPrefixes(iPrefix) + "_Channels"), ...
        localGetNumericColumn(rawOverviewTable, streamPrefixes(iPrefix) + "_Fs_Hz"), ...
        localGetStringColumn(rawOverviewTable, streamPrefixes(iPrefix) + "_Status"), ...
        'VariableNames', {'RunId','DAQ_System','Samples','Channels','Fs_Hz','Status'});
    tbl = [tbl; streamTable]; %#ok<AGROW>
end

tbl = sortrows(tbl, {'RunId','DAQ_System'});

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
