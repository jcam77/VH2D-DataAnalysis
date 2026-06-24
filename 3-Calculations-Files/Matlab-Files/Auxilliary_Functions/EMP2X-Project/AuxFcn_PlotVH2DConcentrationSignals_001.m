function fig = AuxFcn_PlotVH2DConcentrationSignals_001(runData, signalPlans, options)
% AuxFcn_PlotVH2DConcentrationSignals_001
% Plot concentration signals for visual inspection before WoI extraction.
%
% This function does not choose extraction windows. It only plots the
% requested concentration streams so the WoI can be selected transparently
% in EDA before any rule is moved into DPR.

arguments
    runData (1,1) struct
    signalPlans struct
    options.FigureId (1,1) string
    options.MainTitle (1,1) string
    options.RunId (1,1) string = ""
    options.GasMixingTable table = table()
    options.Subtitle (1,1) string
    options.TimeAxisLabel (1,1) string
    options.ConcentrationYAxisLabel (1,1) string
    options.FigurePosition_cm (1,4) double = [10 10 32 22]
    options.LineWidth (1,1) double = 0.75
    options.AxisPaddingFraction (1,1) double = 0.05
end

localRequireStructFields(signalPlans, ...
    ["Label", "Path", "Column", "Color", "LineStyle"], "signalPlans");

nSignals = numel(signalPlans);
fig = figure( ...
    'Name', options.FigureId, ...
    'NumberTitle', 'off', ...
    'Units', 'centimeters', ...
    'Position', options.FigurePosition_cm);

tiled = tiledlayout(nSignals, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

for iSignal = 1:nSignals
    plan = signalPlans(iSignal);
    ax = nexttile(tiled);
    data = localGetNestedField(runData, string(plan.Path));
    [t, y, channelLabel, unitLabel] = localExtractSignal(data, plan.Column);

    plot(ax, t, y, ...
        'Color', plan.Color, ...
        'LineStyle', char(string(plan.LineStyle)), ...
        'LineWidth', options.LineWidth);
    grid(ax, 'on');
    box(ax, 'on');
    xlabel(ax, options.TimeAxisLabel, 'Interpreter', 'latex');
    ylabel(ax, options.ConcentrationYAxisLabel, 'Interpreter', 'latex');
    title(ax, localTileTitle(plan.Label, channelLabel, unitLabel), ...
        'Interpreter', 'none');
    localApplyPaddedYLim(ax, y, options.AxisPaddingFraction);
end

mainTitle = localMainTitle(options.MainTitle, options.RunId, options.GasMixingTable);
sgtitle(tiled, {mainTitle, options.Subtitle}, 'Interpreter', 'latex');
end

function mainTitle = localMainTitle(mainTitleOption, runId, gasMixingTable)
mainTitle = string(mainTitleOption);
if strlength(mainTitle) > 0 && lower(mainTitle) ~= "auto"
    return
end

if strlength(runId) == 0
    mainTitle = "{\textbf{Run}}";
    return
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

function data = localGetNestedField(rootStruct, pathText)
pathParts = split(pathText, ".");
data = rootStruct;
for iPart = 1:numel(pathParts)
    fieldName = char(pathParts(iPart));
    if ~isfield(data, fieldName)
        error("AuxFcn_PlotVH2DConcentrationSignals_001:MissingField", ...
            'Missing field "%s" in requested path "%s".', ...
            fieldName, pathText);
    end
    data = data.(fieldName);
end
end

function [t, y, channelLabel, unitLabel] = localExtractSignal(data, columnIdx)
if ~isfield(data, "t_s") || ~isfield(data, "signal")
    error("AuxFcn_PlotVH2DConcentrationSignals_001:MissingSignalData", ...
        "Each concentration stream must contain t_s and signal.");
end
if columnIdx > size(data.signal, 2)
    error("AuxFcn_PlotVH2DConcentrationSignals_001:ColumnOutOfRange", ...
        "Requested column %d, but signal has only %d columns.", ...
        columnIdx, size(data.signal, 2));
end

t = data.t_s(:);
y = data.signal(:, columnIdx);

channelLabel = "";
if isfield(data, "channels") && ~isempty(data.channels)
    channels = string(data.channels);
    if columnIdx <= numel(channels)
        channelLabel = channels(columnIdx);
    end
end

unitLabel = "";
if isfield(data, "units") && ~isempty(data.units)
    units = string(data.units);
    if columnIdx <= numel(units)
        unitLabel = units(columnIdx);
    end
end
end

function titleText = localTileTitle(label, channelLabel, unitLabel)
titleText = string(label);
if strlength(channelLabel) > 0
    titleText = titleText + " | " + channelLabel;
end
if strlength(unitLabel) > 0
    titleText = titleText + " [" + unitLabel + "]";
end
end

function localApplyPaddedYLim(ax, y, padFraction)
y = y(isfinite(y));
if isempty(y)
    return
end

yMin = min(y);
yMax = max(y);
if yMax == yMin
    yPad = abs(yMin) * padFraction + 1e-3;
else
    yPad = (yMax - yMin) * padFraction;
end
ylim(ax, [yMin - yPad, yMax + yPad]);
end

function localRequireStructFields(structArray, requiredFields, structName)
if isempty(structArray)
    error("AuxFcn_PlotVH2DConcentrationSignals_001:MissingStructArray", ...
        "%s must not be empty.", structName);
end

availableFields = string(fieldnames(structArray));
missingFields = setdiff(requiredFields, availableFields);
if ~isempty(missingFields)
    error("AuxFcn_PlotVH2DConcentrationSignals_001:MissingStructFields", ...
        "%s is missing required fields: %s", ...
        structName, strjoin(missingFields, ", "));
end
end
