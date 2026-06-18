function metadata = AuxFcn_LoadVH2DMetadata_001(metadataRoot, options)
% AuxFcn_LoadVH2DMetadata_001
% Read VH2D campaign JSON metadata and convert it into MATLAB tables.
%
% Expected files:
%   Experiment_Plan_v000.json
%   gas_mixing.json
%   daq_systems.json
%   sensors_mapping.json

arguments
    metadataRoot (1,1) string
    options.Groups string = strings(0,1)
end

assert(isfolder(metadataRoot), 'Metadata folder not found: %s', metadataRoot);

metadata = struct();
metadata.root = metadataRoot;
metadata.selectedGroups = string(options.Groups);

% Keep both representations:
%   Raw structs preserve everything from JSON for traceability.
%   Tables expose selected fields for report and analysis workflows.
experimentPlan = localReadJson(fullfile(metadataRoot, "Experiment_Plan_v000.json"));
gasMixing = localReadJson(fullfile(metadataRoot, "gas_mixing.json"));
daqSystems = localReadJson(fullfile(metadataRoot, "daq_systems.json"));
sensorsMapping = localReadJson(fullfile(metadataRoot, "sensors_mapping.json"));

metadata.experimentPlanRaw = experimentPlan;
metadata.gasMixingRaw = gasMixing;
metadata.daqSystemsRaw = daqSystems;
metadata.sensorsMappingRaw = sensorsMapping;

metadata.experimentPlanTable = localExperimentPlanTable(experimentPlan, options.Groups);
metadata.gasMixingTable = localGasMixingTable(gasMixing, options.Groups);
metadata.daqSystemsTable = localDaqSystemsTable(daqSystems);
metadata.sensorMappingTable = localSensorMappingTable(sensorsMapping, options.Groups);
metadata.groupNotesTable = localGroupNotesTable(sensorsMapping, options.Groups);

end

function data = localReadJson(filePath)
assert(isfile(filePath), 'Metadata JSON file not found: %s', filePath);
data = jsondecode(fileread(filePath));
end

function item = localGetJsonItem(items, idx)
if iscell(items)
    item = items{idx};
else
    item = items(idx);
end
end

function tbl = localExperimentPlanTable(experimentPlan, groups)
experiments = experimentPlan.experiments;
n = numel(experiments);

RunId = strings(n,1);
GroupId = strings(n,1);
Done = false(n,1);
IsPreparation = false(n,1);
PlannedDate = strings(n,1);
TargetH2_vol_pct = NaN(n,1);
P0_Pa = NaN(n,1);
T0_K = NaN(n,1);
Ignition = strings(n,1);
Vent = strings(n,1);
RecircStopToIgnition_s = NaN(n,1);
MFCFlow_slpm = NaN(n,1);
DataFiles = strings(n,1);
Notes = strings(n,1);

for i = 1:n
    item = localGetJsonItem(experiments, i);
    % Use the visible run name, not the app-internal numeric id.
    RunId(i) = localGetString(item, "name");
    GroupId(i) = localRunToGroupId(RunId(i));
    Done(i) = localGetLogical(item, "done");
    Notes(i) = localGetString(item, "notes");

    if isfield(item, "meta")
        meta = item.meta;
        IsPreparation(i) = localGetLogical(meta, "isPreparation");
        PlannedDate(i) = localGetString(meta, "plannedDate");
        TargetH2_vol_pct(i) = localGetDouble(meta, "h2");
        P0_Pa(i) = localGetDouble(meta, "p0");
        T0_K(i) = localGetDouble(meta, "t0");
        Ignition(i) = localGetString(meta, "ignition");
        Vent(i) = localGetString(meta, "vent");
        RecircStopToIgnition_s(i) = localGetDouble(meta, "recircStopToIgnitionSec");
        MFCFlow_slpm(i) = localGetDouble(meta, "mfcFlowSlpm");
        if isfield(meta, "dataFiles")
            DataFiles(i) = strjoin(string(meta.dataFiles(:)).', "; ");
        end
    end
end

tbl = table(RunId, GroupId, Done, IsPreparation, PlannedDate, ...
    TargetH2_vol_pct, P0_Pa, T0_K, Ignition, Vent, ...
    RecircStopToIgnition_s, MFCFlow_slpm, DataFiles, Notes);
tbl = localFilterByGroups(tbl, groups);
end

function tbl = localGasMixingTable(gasMixing, groups)
records = gasMixing.records;
n = numel(records);

RunId = strings(n,1);
GroupId = strings(n,1);
TargetH2_vol_pct = NaN(n,1);
targetVol = NaN(n,1);
PChamber_Pa = NaN(n,1);
TChamber_K = NaN(n,1);
tChamberC = NaN(n,1);
MFCFlow_slpm = NaN(n,1);
mfcFlowSlpm = NaN(n,1);
H2MassInjected_g = NaN(n,1);
mH2EstimatedG = NaN(n,1);
mH2CorrectedG = NaN(n,1);
H2VolumeStd_L = NaN(n,1);
ChamberVolumeCorrected_m3 = NaN(n,1);
V_chamber_geom_m3 = NaN(n,1);
volPipesM3 = NaN(n,1);
V_chamber_corrected_m3 = NaN(n,1);
V_H2_injected_m3 = NaN(n,1);
InjectionTime_s = NaN(n,1);
InjectionTime_min = NaN(n,1);
CalibrationApplied = strings(n,1);
Notes = strings(n,1);

for i = 1:n
    item = localGetJsonItem(records, i);
    % Keep original metadata names where useful and add report-friendly aliases
    % such as targetVol and tChamberC.
    RunId(i) = localGetString(item, "runName");
    GroupId(i) = localGetString(item, "group");
    TargetH2_vol_pct(i) = localGetDouble(item, "targetVol");
    targetVol(i) = TargetH2_vol_pct(i);
    PChamber_Pa(i) = localGetDouble(item, "pChamberPa");
    TChamber_K(i) = localGetDouble(item, "tChamberK");
    tChamberC(i) = localGetDouble(item, "tChamberC");
    if isnan(tChamberC(i)) && ~isnan(TChamber_K(i))
        tChamberC(i) = TChamber_K(i) - 273.15;
    end
    MFCFlow_slpm(i) = localGetDouble(item, "mfcFlowSlpm");
    mfcFlowSlpm(i) = MFCFlow_slpm(i);
    H2MassInjected_g(i) = localGetDouble(item, "mH2InjectedG");
    mH2EstimatedG(i) = localGetDouble(item, "mH2EstimatedG");
    mH2CorrectedG(i) = localGetDouble(item, "mH2CorrectedG");
    H2VolumeStd_L(i) = localGetDouble(item, "vH2StdL");
    ChamberVolumeCorrected_m3(i) = localGetDouble(item, "vChamberCorrectedM3");
    V_chamber_corrected_m3(i) = ChamberVolumeCorrected_m3(i);
    V_chamber_geom_m3(i) = localGetResultsDouble(item, "V_chamber_geom_m3");
    if isnan(V_chamber_geom_m3(i))
        V_chamber_geom_m3(i) = localGetDouble(item, "lM") * ...
            localGetDouble(item, "wM") * localGetDouble(item, "hM");
    end
    volPipesM3(i) = localGetDouble(item, "volPipesM3");
    V_H2_injected_m3(i) = localGetResultsDouble(item, "V_H2_injected_m3");
    InjectionTime_s(i) = localGetDouble(item, "injectionTimeS");
    InjectionTime_min(i) = localGetDouble(item, "injectionTimeMin");
    CalibrationApplied(i) = localGetString(item, "calibrationApplied");
    Notes(i) = localGetString(item, "notes");
end

tbl = table(RunId, GroupId, targetVol, tChamberC, mfcFlowSlpm, ...
    V_chamber_geom_m3, volPipesM3, V_chamber_corrected_m3, ...
    mH2EstimatedG, mH2CorrectedG, V_H2_injected_m3, ...
    TargetH2_vol_pct, PChamber_Pa, TChamber_K, MFCFlow_slpm, ...
    H2MassInjected_g, H2VolumeStd_L, ChamberVolumeCorrected_m3, ...
    InjectionTime_s, InjectionTime_min, CalibrationApplied, Notes);
tbl = localFilterByGroups(tbl, groups);
end

function tbl = localDaqSystemsTable(daqSystems)
systems = daqSystems.daqSystems;
n = numel(systems);

DaqSystem = strings(n,1);
Owner = strings(n,1);
Vendor = strings(n,1);
Model = strings(n,1);
SerialNumber = strings(n,1);
MeasuredQuantity = strings(n,1);
ChannelCount = NaN(n,1);
SamplingRate_Hz = NaN(n,1);
LastCalibrationDate = strings(n,1);
IsActive = false(n,1);
Notes = strings(n,1);

for i = 1:n
    item = localGetJsonItem(systems, i);
    DaqSystem(i) = strtrim(localGetString(item, "name"));
    Owner(i) = localGetString(item, "owner");
    Vendor(i) = localGetString(item, "vendor");
    Model(i) = localGetString(item, "model");
    SerialNumber(i) = localGetString(item, "serialNumber");
    MeasuredQuantity(i) = localGetString(item, "measuredQuantity");
    ChannelCount(i) = localGetDouble(item, "channelCount");
    SamplingRate_Hz(i) = localGetDouble(item, "samplingRateHz");
    LastCalibrationDate(i) = localGetString(item, "lastCalibrationDate");
    IsActive(i) = localGetLogical(item, "isActive");
    Notes(i) = localGetString(item, "notes");
end

tbl = table(DaqSystem, Owner, Vendor, Model, SerialNumber, ...
    MeasuredQuantity, ChannelCount, SamplingRate_Hz, ...
    LastCalibrationDate, IsActive, Notes);
end

function tbl = localSensorMappingTable(sensorsMapping, groups)
mappingsByGroup = sensorsMapping.mappingsByGroup;
jsonGroups = string(fieldnames(mappingsByGroup));

rows = table();
for iGroup = 1:numel(jsonGroups)
    jsonGroup = jsonGroups(iGroup);
    groupId = strrep(jsonGroup, "_", "-");
    if ~localGroupIsWanted(groupId, groups)
        continue
    end

    sensors = mappingsByGroup.(jsonGroup);
    n = numel(sensors);
    if n == 0
        continue
    end

    GroupId = repmat(string(groupId), n, 1);
    DaqSystem = strings(n,1);
    DaqChannel = strings(n,1);
    SensorId = strings(n,1);
    LocationLabel = strings(n,1);
    IsBlindSensor = false(n,1);
    IsTriggerChannel = false(n,1);
    IsActive = false(n,1);
    MeasuredQuantity = strings(n,1);
    Manufacturer = strings(n,1);
    Model = strings(n,1);
    SerialNumber = strings(n,1);
    Sensitivity = NaN(n,1);
    SensitivityUnit = strings(n,1);
    MountingMethod = strings(n,1);
    X_m = NaN(n,1);
    Y_m = NaN(n,1);
    Z_m = NaN(n,1);
    Notes = strings(n,1);

    for i = 1:n
        item = localGetJsonItem(sensors, i);
        DaqSystem(i) = strtrim(localGetString(item, "daqSystem"));
        DaqChannel(i) = strtrim(localGetString(item, "daqChannel"));
        SensorId(i) = localGetString(item, "sensorId");
        LocationLabel(i) = localGetString(item, "locationLabel");
        IsBlindSensor(i) = localGetLogical(item, "isBlindSensor");
        IsTriggerChannel(i) = localGetLogical(item, "isTriggerChannel");
        IsActive(i) = localGetLogical(item, "isActive");
        MeasuredQuantity(i) = localGetString(item, "measuredQuantity");
        Manufacturer(i) = localGetString(item, "manufacturer");
        Model(i) = localGetString(item, "model");
        SerialNumber(i) = localGetString(item, "serialNumber");
        Sensitivity(i) = localGetDouble(item, "sensitivity");
        SensitivityUnit(i) = localGetString(item, "sensitivityUnit");
        MountingMethod(i) = localGetString(item, "mountingMethod");
        X_m(i) = localGetDouble(item, "x");
        Y_m(i) = localGetDouble(item, "y");
        Z_m(i) = localGetDouble(item, "z");
        Notes(i) = localGetString(item, "notes");
    end

    rows = [rows; table(GroupId, DaqSystem, DaqChannel, SensorId, ...
        LocationLabel, IsBlindSensor, IsTriggerChannel, IsActive, ...
        MeasuredQuantity, Manufacturer, Model, SerialNumber, ...
        Sensitivity, SensitivityUnit, MountingMethod, X_m, Y_m, Z_m, Notes)]; %#ok<AGROW>
end

tbl = rows;
end

function tbl = localGroupNotesTable(sensorsMapping, groups)
groupNotes = sensorsMapping.groupNotes;
jsonGroups = string(fieldnames(groupNotes));
n = numel(jsonGroups);
GroupId = strings(n,1);
GroupNote = strings(n,1);

for i = 1:n
    GroupId(i) = strrep(jsonGroups(i), "_", "-");
    GroupNote(i) = string(groupNotes.(jsonGroups(i)));
end

tbl = table(GroupId, GroupNote);
tbl = localFilterByGroups(tbl, groups);
end

function tbl = localFilterByGroups(tbl, groups)
if isempty(groups)
    return
end

keep = false(height(tbl),1);
for i = 1:height(tbl)
    keep(i) = localGroupIsWanted(tbl.GroupId(i), groups);
end
tbl = tbl(keep,:);
end

function tf = localGroupIsWanted(groupId, groups)
groups = string(groups);
groups = groups(strlength(groups) > 0);
if isempty(groups)
    tf = true;
    return
end

groupId = string(groupId);
tf = any(groupId == groups) || any(endsWith(groupId, "-" + groups));
end

function groupId = localRunToGroupId(runId)
tokens = regexp(string(runId), "^(.+-\d+)-\d+$", "tokens", "once");
if isempty(tokens)
    groupId = "";
else
    groupId = string(tokens{1});
end
end

function value = localGetResultsDouble(s, fieldName)
value = NaN;
if ~isfield(s, "results") || isempty(s.results)
    return
end

value = localGetDouble(s.results, fieldName);
end

function value = localGetString(s, fieldName)
fieldName = char(fieldName);
if isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = string(s.(fieldName));
else
    value = "";
end
end

function value = localGetDouble(s, fieldName)
fieldName = char(fieldName);
value = NaN;
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    return
end

rawValue = s.(fieldName);
if isnumeric(rawValue) || islogical(rawValue)
    value = double(rawValue);
else
    value = str2double(string(rawValue));
end
end

function value = localGetLogical(s, fieldName)
fieldName = char(fieldName);
value = false;
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    return
end

rawValue = s.(fieldName);
if islogical(rawValue)
    value = rawValue;
elseif isnumeric(rawValue)
    value = rawValue ~= 0;
else
    value = any(lower(string(rawValue)) == ["true","1","yes"]);
end
end
