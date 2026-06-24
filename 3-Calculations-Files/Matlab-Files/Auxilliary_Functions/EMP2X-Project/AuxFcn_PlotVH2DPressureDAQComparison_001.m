function [figHandles, plotPlanTable] = AuxFcn_PlotVH2DPressureDAQComparison_001(runData, sensorMappingTable, groupId, runId, options)
% AuxFcn_PlotVH2DPressureDAQComparison_001
% Plot pressure/trigger comparisons for one VH2D run using metadata evidence.
%
% This function intentionally avoids hardcoding the comparison layout. The
% caller must provide:
%   - DAQ-system to DAQ-family/loaded-field mapping
%   - mounting-class names and grease keywords
%   - trigger DAQs and plot styles
%   - figure plans, tile groups, titles, and axis labels
%
% The function builds the plotting plan from the sensor mapping table, then
% plots only the figure plans requested by the caller.

arguments
    runData (1,1) struct
    sensorMappingTable table
    groupId (1,1) string
    runId (1,1) string
    options.DaqFamilyMap struct
    options.FigurePlans struct
    options.FamilyStyles struct
    options.TriggerStyles struct
    options.TriggerDAQs string
    options.PressureYAxisLabel (1,1) string
    options.TriggerYAxisLabel (1,1) string
    options.TimeAxisLabel (1,1) string
    options.BlindMountingClass (1,1) string
    options.FlushMountingClass (1,1) string
    options.RecessedMountingClass (1,1) string
    options.RecessedGreaseMountingClass (1,1) string
    options.HighVacuumGreaseKeywords string
    options.ExcludedMountingMethods string = strings(0,1)
    options.PressureMeasuredQuantity (1,1) string = "pressure"
    options.GasMixingTable table = table()
    options.LineWidth (1,1) double = 0.75
    options.FigurePosition_cm (1,4) double = [10 10 36 24]
    options.AxisPaddingFraction (1,1) double = 0.05
end

localRequireStructFields(options.DaqFamilyMap, ...
    ["DaqSystem", "DaqFamily", "LoadedDAQField"], "DaqFamilyMap");
localRequireStructFields(options.FigurePlans, ...
    ["HandleField", "FigureId", "Subtitle", ...
    "MountingClasses", "TileTitles", "TimeWindow_s", ...
    "ShowTriggerInTiles", "IncludeTriggerOnlyTile"], "FigurePlans");
localRequireStructFields(options.FamilyStyles, ...
    ["DaqFamily", "Color", "LineStyle"], "FamilyStyles");
localRequireStructFields(options.TriggerStyles, ...
    ["DAQ", "Color", "LineStyle"], "TriggerStyles");

plotPlanTable = localBuildPlotPlan(sensorMappingTable, groupId, runId, options);

figHandles = struct();
for iFigure = 1:numel(options.FigurePlans)
    figurePlan = options.FigurePlans(iFigure);
    handleField = matlab.lang.makeValidName(string(figurePlan.HandleField));
    figHandles.(handleField) = localPlotFigure( ...
        runData, plotPlanTable, figurePlan, runId, options);
end
end

function plotPlanTable = localBuildPlotPlan(sensorMappingTable, groupId, runId, options)
variableNames = string(sensorMappingTable.Properties.VariableNames);
requiredColumns = ["GroupId", "IsActive", "IsTriggerChannel", ...
    "MeasuredQuantity", "MountingMethod", "IsBlindSensor", ...
    "DaqSystem", "DaqChannel", "SensorId", "LocationLabel", ...
    "LoadedDataColumn", "LoadedDataChannel"];
missingColumns = setdiff(requiredColumns, variableNames);
if ~isempty(missingColumns)
    error("AuxFcn_PlotVH2DPressureDAQComparison_001:MissingSensorMapColumns", ...
        "sensorMappingTable is missing required columns: %s", ...
        strjoin(missingColumns, ", "));
end

groupMask = string(sensorMappingTable.GroupId) == groupId;
activeMask = logical(sensorMappingTable.IsActive);
pressureMask = lower(string(sensorMappingTable.MeasuredQuantity)) == ...
    lower(options.PressureMeasuredQuantity);
triggerMask = logical(sensorMappingTable.IsTriggerChannel);
mountingMethod = lower(string(sensorMappingTable.MountingMethod));
excludedMounting = lower(string(options.ExcludedMountingMethods));
excludedMask = ismember(mountingMethod, excludedMounting);

plotPlanTable = sensorMappingTable( ...
    groupMask & activeMask & ~triggerMask & pressureMask & ~excludedMask, :);

MountingClass = localMountingClass(plotPlanTable, options);
[DaqFamily, LoadedDAQField] = localDaqFamilyAndField(plotPlanTable, options.DaqFamilyMap);
LoadedDataColumnForRun = localLoadedColumnForRun(plotPlanTable.LoadedDataColumn, runId);

plotPlanTable = addvars(plotPlanTable, MountingClass, DaqFamily, ...
    LoadedDAQField, LoadedDataColumnForRun, ...
    'After', 'MountingMethod');
plotPlanTable = sortrows(plotPlanTable, ...
    {'MountingClass', 'LocationLabel', 'DaqFamily', 'SensorId'});
end

function MountingClass = localMountingClass(plotPlanTable, options)
mountingMethod = lower(string(plotPlanTable.MountingMethod));
isBlind = logical(plotPlanTable.IsBlindSensor);
notes = strings(height(plotPlanTable), 1);
if ismember("Notes", string(plotPlanTable.Properties.VariableNames))
    notes = lower(string(plotPlanTable.Notes));
end

greaseKeywords = lower(string(options.HighVacuumGreaseKeywords));
hasHighVacuumGrease = false(height(plotPlanTable), 1);
for iKeyword = 1:numel(greaseKeywords)
    keyword = greaseKeywords(iKeyword);
    if strlength(keyword) == 0
        continue
    end
    hasHighVacuumGrease = hasHighVacuumGrease | contains(notes, keyword);
end

MountingClass = strings(height(plotPlanTable), 1);
MountingClass(isBlind) = options.BlindMountingClass;
MountingClass(~isBlind & mountingMethod == "flush") = options.FlushMountingClass;
MountingClass(~isBlind & mountingMethod == "recessed" & ...
    ~hasHighVacuumGrease) = options.RecessedMountingClass;
MountingClass(~isBlind & mountingMethod == "recessed" & ...
    hasHighVacuumGrease) = options.RecessedGreaseMountingClass;
end

function [DaqFamily, LoadedDAQField] = localDaqFamilyAndField(plotPlanTable, daqFamilyMap)
DaqFamily = strings(height(plotPlanTable), 1);
LoadedDAQField = strings(height(plotPlanTable), 1);
mappedDaqSystems = string({daqFamilyMap.DaqSystem});

for iRow = 1:height(plotPlanTable)
    daqSystem = string(plotPlanTable.DaqSystem(iRow));
    mapIdx = find(mappedDaqSystems == daqSystem, 1);
    if isempty(mapIdx)
        continue
    end

    DaqFamily(iRow) = string(daqFamilyMap(mapIdx).DaqFamily);
    LoadedDAQField(iRow) = string(daqFamilyMap(mapIdx).LoadedDAQField);
end
end

function LoadedDataColumnForRun = localLoadedColumnForRun(loadedDataColumn, runId)
LoadedDataColumnForRun = NaN(numel(loadedDataColumn), 1);
for iRow = 1:numel(loadedDataColumn)
    LoadedDataColumnForRun(iRow) = localColumnForRun(loadedDataColumn(iRow), runId);
end
end

function fig = localPlotFigure(runData, plotPlanTable, figurePlan, runId, options)
nMountingTiles = numel(string(figurePlan.MountingClasses));
nTriggerTiles = double(logical(figurePlan.IncludeTriggerOnlyTile));
nTiles = nMountingTiles + nTriggerTiles;

fig = figure( ...
    'Name', string(figurePlan.FigureId), ...
    'NumberTitle', 'off', ...
    'Units', 'centimeters', ...
    'Position', options.FigurePosition_cm);

tiled = tiledlayout(nTiles, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
mountingClasses = string(figurePlan.MountingClasses);
tileTitles = string(figurePlan.TileTitles);
timeWindow_s = double(figurePlan.TimeWindow_s);
showTriggerInTiles = logical(figurePlan.ShowTriggerInTiles);

for iTile = 1:nMountingTiles
    ax = nexttile(tiled);
    localPlotMountingTile(ax, runData, plotPlanTable, mountingClasses(iTile), ...
        tileTitles(iTile), timeWindow_s, showTriggerInTiles, options);
end

if logical(figurePlan.IncludeTriggerOnlyTile)
    axTrigger = nexttile(tiled);
    localPlotTriggerTile(axTrigger, runData, timeWindow_s, options);
end

localSgtitle(tiled, figurePlan, runId, options);
end

function mainTitle = localMainTitle(figurePlan, runId, gasMixingTable)
if isfield(figurePlan, "MainTitle")
    mainTitle = string(figurePlan.MainTitle);
    if strlength(mainTitle) > 0 && lower(mainTitle) ~= "auto"
        return
    end
end

runShortId = erase(string(runId), "VH2D-");
targetH2VolPct = localTargetH2VolPct(runId, gasMixingTable);
if isnan(targetH2VolPct)
    mainTitle = "{\textbf{Run " + runShortId + "}}";
else
    mainTitle = "{\textbf{Run " + runShortId + ...
        " (Conc. Target $H_2$ " + compose("%g", targetH2VolPct) + ...
        " vol.$\%$)}}";
end
end

function targetH2VolPct = localTargetH2VolPct(runId, gasMixingTable)
targetH2VolPct = NaN;
if isempty(gasMixingTable) || ...
        ~ismember("RunId", string(gasMixingTable.Properties.VariableNames))
    return
end

runMask = string(gasMixingTable.RunId) == string(runId);
if ~any(runMask)
    return
end

variableNames = string(gasMixingTable.Properties.VariableNames);
rowIdx = find(runMask, 1);
if ismember("targetVol", variableNames)
    targetH2VolPct = localDoubleScalar(gasMixingTable.targetVol(rowIdx));
elseif ismember("TargetH2_vol_pct", variableNames)
    targetH2VolPct = localDoubleScalar(gasMixingTable.TargetH2_vol_pct(rowIdx));
end
end

function value = localDoubleScalar(valueIn)
if isnumeric(valueIn)
    value = double(valueIn(1));
else
    value = str2double(string(valueIn(1)));
end
end

function localSgtitle(tiled, figurePlan, runId, options)
mainTitle = localMainTitle(figurePlan, runId, options.GasMixingTable);
sgtitle(tiled, {mainTitle, string(figurePlan.Subtitle)}, ...
    'Interpreter', 'latex');
end

function localPlotMountingTile(ax, runData, plotPlanTable, mountingClass, ...
        tileTitle, timeWindow_s, showTrigger, options)
rows = plotPlanTable(plotPlanTable.MountingClass == mountingClass, :);

if showTrigger
    yyaxis(ax, 'left');
end
hold(ax, 'on');
pressureHandles = gobjects(0);
pressureLabels = strings(0, 1);
pressureYValues = [];

for iRow = 1:height(rows)
    daqField = string(rows.LoadedDAQField(iRow));
    columnIdx = rows.LoadedDataColumnForRun(iRow);
    if strlength(daqField) == 0 || isnan(columnIdx) || ...
            ~isfield(runData, char(daqField))
        continue
    end

    daqData = runData.(char(daqField));
    if columnIdx < 1 || columnIdx > size(daqData.signal, 2)
        continue
    end

    [t, y] = localWindowedSignal( ...
        daqData.t_s, daqData.signal(:, columnIdx), timeWindow_s);
    style = localFamilyStyle(rows.DaqFamily(iRow), options.FamilyStyles);
    h = plot(ax, t, y, ...
        'Color', style.Color, ...
        'LineStyle', char(style.LineStyle), ...
        'LineWidth', options.LineWidth);
    pressureHandles(end+1) = h; %#ok<AGROW>
    pressureLabels(end+1,1) = rows.DaqFamily(iRow) + " " + ...
        rows.SensorId(iRow) + " (" + rows.LocationLabel(iRow) + ")"; %#ok<AGROW>
    pressureYValues = [pressureYValues; y(:)]; %#ok<AGROW>
end

ylabel(ax, options.PressureYAxisLabel, 'Interpreter', 'latex');
ax.YColor = 'k';
localApplyPaddedYLim(ax, pressureYValues, options.AxisPaddingFraction);

triggerHandles = gobjects(0);
triggerLabels = strings(0, 1);
if showTrigger
    yyaxis(ax, 'right');
    hold(ax, 'on');
    [triggerHandles, triggerLabels, triggerYValues] = localPlotTriggersOnAxes( ...
        ax, runData, timeWindow_s, options);
    ylabel(ax, options.TriggerYAxisLabel, 'Interpreter', 'latex');
    if ~isempty(options.TriggerStyles)
        ax.YColor = options.TriggerStyles(1).Color;
    end
    localApplyPaddedYLim(ax, triggerYValues, options.AxisPaddingFraction);
end

xlabel(ax, options.TimeAxisLabel, 'Interpreter', 'latex');
title(ax, tileTitle, 'Interpreter', 'latex');
grid(ax, 'on');
box(ax, 'on');

legendHandles = [pressureHandles(:); triggerHandles(:)];
legendLabels = [pressureLabels(:); triggerLabels(:)];
if ~isempty(legendHandles)
    legend(ax, legendHandles, cellstr(legendLabels), ...
        'Location', 'northeast', 'Interpreter', 'none');
end
hold(ax, 'off');
end

function localPlotTriggerTile(ax, runData, timeWindow_s, options)
hold(ax, 'on');
[triggerHandles, triggerLabels, triggerYValues] = localPlotTriggersOnAxes( ...
    ax, runData, timeWindow_s, options);

xlabel(ax, options.TimeAxisLabel, 'Interpreter', 'latex');
ylabel(ax, options.TriggerYAxisLabel, 'Interpreter', 'latex');
title(ax, "Trigger Signals", 'Interpreter', 'latex');
grid(ax, 'on');
box(ax, 'on');
localApplyPaddedYLim(ax, triggerYValues, options.AxisPaddingFraction);

if ~isempty(triggerHandles)
    legend(ax, triggerHandles, cellstr(triggerLabels), ...
        'Location', 'northeast', 'Interpreter', 'none');
end
hold(ax, 'off');
end

function [triggerHandles, triggerLabels, triggerYValues] = localPlotTriggersOnAxes(ax, runData, timeWindow_s, options)
triggerHandles = gobjects(0);
triggerLabels = strings(0, 1);
triggerYValues = [];

for iDAQ = 1:numel(options.TriggerDAQs)
    daqField = string(options.TriggerDAQs(iDAQ));
    if ~isfield(runData, char(daqField))
        continue
    end

    daqData = runData.(char(daqField));
    triggerColumn = localTriggerColumn(daqData);
    if isnan(triggerColumn)
        continue
    end

    [tTrig, yTrig] = localWindowedSignal( ...
        daqData.t_s, daqData.signal(:, triggerColumn), timeWindow_s);
    style = localTriggerStyle(daqField, options.TriggerStyles);
    hTrig = plot(ax, tTrig, yTrig, ...
        'Color', style.Color, ...
        'LineStyle', char(style.LineStyle), ...
        'LineWidth', options.LineWidth);
    triggerHandles(end+1) = hTrig; %#ok<AGROW>
    triggerLabels(end+1,1) = "Trigger " + daqField; %#ok<AGROW>
    triggerYValues = [triggerYValues; yTrig(:)]; %#ok<AGROW>
end
end

function [tOut, yOut] = localWindowedSignal(t, y, timeWindow_s)
t = t(:);
y = y(:);
idx = isfinite(t) & isfinite(y) & ...
    t >= timeWindow_s(1) & t <= timeWindow_s(2);

if ~isempty(idx) && any(idx)
    tOut = t(idx);
    yOut = y(idx);
    return
end

tOut = t(isfinite(t) & isfinite(y));
yOut = y(isfinite(t) & isfinite(y));
end

function columnIdx = localColumnForRun(loadedDataColumn, runId)
columnIdx = NaN;
loadedDataColumn = string(loadedDataColumn);
runPattern = string(regexptranslate('escape', char(runId))) + ":col(\d+)";
tokens = regexp(char(loadedDataColumn), char(runPattern), "tokens", "once");
if ~isempty(tokens)
    columnIdx = str2double(tokens{1});
    return
end

tokens = regexp(char(loadedDataColumn), "col(\d+)", "tokens", "once");
if ~isempty(tokens)
    columnIdx = str2double(tokens{1});
end
end

function triggerColumn = localTriggerColumn(daqData)
triggerColumn = NaN;
if ~isfield(daqData, "channels") || isempty(daqData.channels)
    return
end

channels = lower(string(daqData.channels));
units = strings(size(channels));
if isfield(daqData, "units") && ~isempty(daqData.units)
    units = lower(string(daqData.units));
end

idx = find(contains(channels, "trigger") | contains(channels, "voltage") | ...
    units == "v", 1, "first");
if ~isempty(idx)
    triggerColumn = idx;
end
end

function style = localFamilyStyle(daqFamily, familyStyles)
style = familyStyles(1);
for iStyle = 1:numel(familyStyles)
    if string(familyStyles(iStyle).DaqFamily) == string(daqFamily)
        style = familyStyles(iStyle);
        return
    end
end
end

function style = localTriggerStyle(daqField, triggerStyles)
style = triggerStyles(1);
for iStyle = 1:numel(triggerStyles)
    if string(triggerStyles(iStyle).DAQ) == string(daqField)
        style = triggerStyles(iStyle);
        return
    end
end
end

function localApplyPaddedYLim(ax, yValues, padFraction)
yValues = yValues(isfinite(yValues));
if isempty(yValues)
    return
end

yMin = min(yValues);
yMax = max(yValues);
if yMax == yMin
    yPad = abs(yMin) * padFraction + 1e-3;
else
    yPad = (yMax - yMin) * padFraction;
end
ylim(ax, [yMin - yPad, yMax + yPad]);
end

function localRequireStructFields(structArray, requiredFields, structName)
if isempty(structArray)
    error("AuxFcn_PlotVH2DPressureDAQComparison_001:MissingStructArray", ...
        "%s must not be empty.", structName);
end

availableFields = string(fieldnames(structArray));
missingFields = setdiff(requiredFields, availableFields);
if ~isempty(missingFields)
    error("AuxFcn_PlotVH2DPressureDAQComparison_001:MissingStructFields", ...
        "%s is missing required fields: %s", ...
        structName, strjoin(missingFields, ", "));
end
end
