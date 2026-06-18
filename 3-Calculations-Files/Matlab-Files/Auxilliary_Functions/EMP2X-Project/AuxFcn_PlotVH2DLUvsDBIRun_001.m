function figHandles = AuxFcn_PlotVH2DLUvsDBIRun_001(runData, plotPlanTable, runId, options)
% AuxFcn_PlotVH2DLUvsDBIRun_001
% Plot one LU vs DBI run using metadata-derived channel mapping.
%
% The function expects `plotPlanTable` to contain loaded-channel evidence
% columns, especially MountingClass, DaqFamily, LoadedDataColumn, and SensorId.
% Pressure columns are selected from the table, not hardcoded.

arguments
    runData (1,1) struct
    plotPlanTable table
    runId (1,1) string
    options.WoI_s (1,2) double = [0, 0.25]
    options.LUColor (1,3) double = [17, 55, 125] / 255
    options.DBIColor (1,3) double = [147, 86, 14] / 255
    options.TriggerColor (1,3) double = [192, 0, 0] / 255
    options.LineWidth (1,1) double = 0.5
    options.FigurePosition_cm (1,4) double = [10 10 36 24]
    options.GasMixingTable table = table()
end

runShortId = localRunShortId(runId);
runTitle = localRunTitle(runId, runShortId, options.GasMixingTable);
figHandles = struct();

figHandles.MountingMethods = localPlotMountingMethodsRecord( ...
    runData, plotPlanTable, runId, runShortId, runTitle, options);
figHandles.Recessed = localPlotWoIFigure( ...
    runData, plotPlanTable, runId, runShortId, runTitle, options, ...
    "F02", "Recessed", ["Recessed_RTV", "Recessed_RTV_HighVacuumGrease"], ...
    ["Recessed", "Recessed + High Vacuum Grease"]);
figHandles.FlushBlind = localPlotWoIFigure( ...
    runData, plotPlanTable, runId, runShortId, runTitle, options, ...
    "F03", "FlushBlind", ["Flush_RTV", "Blind_RTV"], ...
    ["Flush", "Blind"]);
end

function fig = localPlotMountingMethodsRecord(runData, plotPlanTable, runId, runShortId, runTitle, options)
figId = "Fig-" + runShortId + "-LUvsDBI-PP-F01-MountingMethods";
fig = figure('Name', figId, 'NumberTitle', 'off', ...
    'Units', 'centimeters', 'Position', options.FigurePosition_cm);

tiled = tiledlayout(5, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
mountingClasses = ["Recessed_RTV", "Recessed_RTV_HighVacuumGrease", "Flush_RTV", "Blind_RTV"];
tileTitles = ["Recessed", "Recessed + High Vacuum Grease", "Flush", "Blind"];

for iTile = 1:numel(mountingClasses)
    ax = nexttile(tiled);
    localPlotMountingTile(ax, runData, plotPlanTable, runId, ...
        mountingClasses(iTile), tileTitles(iTile), [-Inf, Inf], true, options);
end

axTrigger = nexttile(tiled);
localPlotTriggerTile(axTrigger, runData, [-Inf, Inf], options);

sgtitle(tiled, { ...
    runTitle, ...
    "LU vs DBI pressure sensors by mounting method"}, ...
    'Interpreter', 'latex');
end

function fig = localPlotWoIFigure(runData, plotPlanTable, runId, runShortId, runTitle, options, ...
        figureNumber, detail, mountingClasses, tileTitles)
figId = "Fig-" + runShortId + "-LUvsDBI-PP-WoI-" + figureNumber + "-" + detail;
fig = figure('Name', figId, 'NumberTitle', 'off', ...
    'Units', 'centimeters', 'Position', options.FigurePosition_cm);

tiled = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for iTile = 1:numel(mountingClasses)
    ax = nexttile(tiled);
    localPlotMountingTile(ax, runData, plotPlanTable, runId, ...
        mountingClasses(iTile), tileTitles(iTile), options.WoI_s, false, options);
end

sgtitle(tiled, { ...
    runTitle, ...
    "LU vs DBI pressure sensors, temporal window of interest"}, ...
    'Interpreter', 'latex');
end

function localPlotMountingTile(ax, runData, plotPlanTable, runId, mountingClass, ...
        tileTitle, timeWindow_s, showTrigger, options)
rows = plotPlanTable(plotPlanTable.MountingClass == mountingClass, :);

if showTrigger
    yyaxis(ax, 'left');
end
hold(ax, 'on');
pressureHandles = gobjects(0);
pressureLabels = strings(0, 1);

for iRow = 1:height(rows)
    daqField = localDaqField(rows.DaqSystem(iRow));
    columnIdx = localColumnForRun(rows.LoadedDataColumn(iRow), runId);
    if strlength(daqField) == 0 || isnan(columnIdx) || ~isfield(runData, char(daqField))
        continue
    end

    daqData = runData.(char(daqField));
    if columnIdx < 1 || columnIdx > size(daqData.signal, 2)
        continue
    end

    [t, y] = localWindowedSignal(daqData.t_s, daqData.signal(:, columnIdx), timeWindow_s);
    color = localFamilyColor(rows.DaqFamily(iRow), options);
    lineStyle = localFamilyLineStyle(rows.DaqFamily(iRow));
    h = plot(ax, t, y, 'Color', color, 'LineStyle', lineStyle, ...
        'LineWidth', options.LineWidth);
    pressureHandles(end+1) = h; %#ok<AGROW>
    pressureLabels(end+1,1) = rows.DaqFamily(iRow) + " " + rows.SensorId(iRow) + ...
        " (" + rows.LocationLabel(iRow) + ")"; %#ok<AGROW>
end

ylabel(ax, "Overpressure [kPa]", 'Interpreter', 'latex');
ax.YColor = 'k';

triggerHandles = gobjects(0);
triggerLabels = strings(0, 1);
if showTrigger
    yyaxis(ax, 'right');
    hold(ax, 'on');
    triggerDAQs = ["DAQ_1", "DAQ_2_3"];
    for iDAQ = 1:numel(triggerDAQs)
        if ~isfield(runData, char(triggerDAQs(iDAQ)))
            continue
        end
        daqData = runData.(char(triggerDAQs(iDAQ)));
        triggerColumn = localTriggerColumn(daqData);
        if isnan(triggerColumn)
            continue
        end
        [tTrig, yTrig] = localWindowedSignal( ...
            daqData.t_s, daqData.signal(:, triggerColumn), timeWindow_s);
        triggerColor = localTriggerOnlyColor(triggerDAQs(iDAQ), options);
        hTrig = plot(ax, tTrig, yTrig, ':', 'Color', triggerColor, ...
            'LineWidth', options.LineWidth);
        triggerHandles(end+1) = hTrig; %#ok<AGROW>
        triggerLabels(end+1,1) = "Trigger " + triggerDAQs(iDAQ); %#ok<AGROW>
    end
    ylabel(ax, "Trigger Voltage [V]", 'Interpreter', 'latex');
    ax.YColor = options.TriggerColor;
end

xlabel(ax, "Time [s]", 'Interpreter', 'latex');
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
triggerDAQs = ["DAQ_1", "DAQ_2_3"];
triggerHandles = gobjects(0);
triggerLabels = strings(0, 1);

for iDAQ = 1:numel(triggerDAQs)
    if ~isfield(runData, char(triggerDAQs(iDAQ)))
        continue
    end

    daqData = runData.(char(triggerDAQs(iDAQ)));
    triggerColumn = localTriggerColumn(daqData);
    if isnan(triggerColumn)
        continue
    end

    [tTrig, yTrig] = localWindowedSignal( ...
        daqData.t_s, daqData.signal(:, triggerColumn), timeWindow_s);
    triggerColor = localTriggerOnlyColor(triggerDAQs(iDAQ), options);
    hTrig = plot(ax, tTrig, yTrig, '-', 'Color', triggerColor, ...
        'LineWidth', options.LineWidth);
    triggerHandles(end+1) = hTrig; %#ok<AGROW>
    triggerLabels(end+1,1) = "Trigger " + triggerDAQs(iDAQ); %#ok<AGROW>
end

xlabel(ax, "Time [s]", 'Interpreter', 'latex');
ylabel(ax, "Trigger Voltage [V]", 'Interpreter', 'latex');
title(ax, "Trigger signals", 'Interpreter', 'latex');
grid(ax, 'on');
box(ax, 'on');

if ~isempty(triggerHandles)
    legend(ax, triggerHandles, cellstr(triggerLabels), ...
        'Location', 'northeast', 'Interpreter', 'none');
end
hold(ax, 'off');
end

function color = localTriggerOnlyColor(daqField, options)
if string(daqField) == "DAQ_1"
    color = options.LUColor;
else
    color = options.TriggerColor;
end
end

function [tOut, yOut] = localWindowedSignal(t, y, timeWindow_s)
t = t(:);
y = y(:);
idx = isfinite(t) & isfinite(y) & t >= timeWindow_s(1) & t <= timeWindow_s(2);
tOut = t(idx);
yOut = y(idx);
end

function daqField = localDaqField(daqSystem)
daqSystem = strtrim(string(daqSystem));
switch daqSystem
    case "DAQ-1"
        daqField = "DAQ_1";
    case {"DAQ-2", "DAQ-3"}
        daqField = "DAQ_2_3";
    case "DAQ-4"
        daqField = "DAQ_4";
    otherwise
        daqField = "";
end
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

idx = find(contains(channels, "trigger") | contains(channels, "voltage") | units == "v", ...
    1, "first");
if ~isempty(idx)
    triggerColumn = idx;
end
end

function color = localFamilyColor(daqFamily, options)
if string(daqFamily) == "LU"
    color = options.LUColor;
else
    color = options.DBIColor;
end
end

function lineStyle = localFamilyLineStyle(daqFamily)
if string(daqFamily) == "LU"
    lineStyle = "-";
else
    lineStyle = "-";
end
end

function runShortId = localRunShortId(runId)
runShortId = erase(string(runId), "VH2D-");
end

function runTitle = localRunTitle(runId, runShortId, gasMixingTable)
targetH2VolPct = localTargetH2VolPct(runId, gasMixingTable);
if isnan(targetH2VolPct)
    runTitle = "{\textbf{Run " + runShortId + "}}";
else
    runTitle = "{\textbf{Run " + runShortId + ...
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
