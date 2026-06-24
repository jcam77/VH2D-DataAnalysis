function fig = AuxFcn_PlotVH2DTwoDAQPressureTrigger_001(runData, options)
% AuxFcn_PlotVH2DTwoDAQPressureTrigger_001
% Controlled two-DAQ pressure/trigger plotting utility.
%
% This function does not infer pressure/trigger channels. The caller must
% provide the DAQ fields, channel columns, labels, colors, line styles,
% titles, figure ID, and temporal window of interest.

arguments
    runData (1,1) struct
    options.FigureId (1,1) string
    options.MainTitle (1,1) string
    options.Subtitle (1,1) string
    options.DAQ_A (1,1) string
    options.DAQ_B (1,1) string
    options.PressureColumn_A (1,1) double {mustBeInteger, mustBePositive}
    options.PressureColumn_B (1,1) double {mustBeInteger, mustBePositive}
    options.TriggerColumn_A (1,1) double {mustBeInteger, mustBePositive}
    options.TriggerColumn_B (1,1) double {mustBeInteger, mustBePositive}
    options.PressureLabel_A (1,1) string
    options.PressureLabel_B (1,1) string
    options.TriggerLabel_A (1,1) string
    options.TriggerLabel_B (1,1) string
    options.PressureColor_A (1,3) double
    options.PressureColor_B (1,3) double
    options.TriggerColor_A (1,3) double
    options.TriggerColor_B (1,3) double
    options.PressureYAxisLabel (1,1) string
    options.TriggerYAxisLabel (1,1) string
    options.TimeAxisLabel (1,1) string
    options.PressureLineStyle_A (1,1) string = "-"
    options.PressureLineStyle_B (1,1) string = "-"
    options.TriggerLineStyle_A (1,1) string = "-"
    options.TriggerLineStyle_B (1,1) string = ":"
    options.PressureLineWidth (1,1) double = 0.7
    options.TriggerLineWidth (1,1) double = 0.5
    options.WoI_s (1,2) double = [0, 0.25]
    options.FigurePosition_cm (1,4) double = [10 10 36 20]
    options.FullRecordTitle (1,1) string = "Preprocessed: Pressure $\&$ Trigger Signal"
    options.WoITitle (1,1) string = ""
    options.AxisPaddingFraction (1,1) double = 0.05
end

[tA, pA] = localSignal(runData, options.DAQ_A, options.PressureColumn_A);
[~, trA] = localSignal(runData, options.DAQ_A, options.TriggerColumn_A);
[tB, pB] = localSignal(runData, options.DAQ_B, options.PressureColumn_B);
[~, trB] = localSignal(runData, options.DAQ_B, options.TriggerColumn_B);

fig = figure( ...
    'Name', options.FigureId, ...
    'NumberTitle', 'off', ...
    'Units', 'centimeters', ...
    'Position', options.FigurePosition_cm);

tiled = tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

axFull = nexttile(tiled);
yyaxis(axFull, 'left');
hP_A = plot(axFull, tA, pA, ...
    'Color', options.PressureColor_A, ...
    'LineStyle', char(options.PressureLineStyle_A), ...
    'LineWidth', options.PressureLineWidth);
hold(axFull, 'on');
hP_B = plot(axFull, tB, pB, ...
    'Color', options.PressureColor_B, ...
    'LineStyle', char(options.PressureLineStyle_B), ...
    'LineWidth', options.PressureLineWidth);
ylabel(axFull, options.PressureYAxisLabel, 'Interpreter', 'latex');
axFull.YColor = 'k';
localApplyPaddedYLim(axFull, [pA(:); pB(:)], options.AxisPaddingFraction);

yyaxis(axFull, 'right');
hTr_A = plot(axFull, tA, trA, ...
    'Color', options.TriggerColor_A, ...
    'LineStyle', char(options.TriggerLineStyle_A), ...
    'LineWidth', options.TriggerLineWidth);
hold(axFull, 'on');
hTr_B = plot(axFull, tB, trB, ...
    'Color', options.TriggerColor_B, ...
    'LineStyle', char(options.TriggerLineStyle_B), ...
    'LineWidth', options.TriggerLineWidth);
ylabel(axFull, options.TriggerYAxisLabel, 'Interpreter', 'latex');
axFull.YColor = options.TriggerColor_A;
localApplyPaddedYLim(axFull, [trA(:); trB(:)], options.AxisPaddingFraction);

xlabel(axFull, options.TimeAxisLabel, 'Interpreter', 'latex');
title(axFull, options.FullRecordTitle, 'Interpreter', 'latex');
legend(axFull, [hP_A, hP_B, hTr_A, hTr_B], ...
    cellstr([options.PressureLabel_A, options.PressureLabel_B, ...
    options.TriggerLabel_A, options.TriggerLabel_B]), ...
    'Location', 'northeast', 'Interpreter', 'latex');
localApplyPaddedXLim(axFull, [tA(:); tB(:)], options.AxisPaddingFraction);
grid(axFull, 'on');
box(axFull, 'on');
hold(axFull, 'off');

axWoI = nexttile(tiled);
idxA = localWindowIndices(tA, options.WoI_s);
idxB = localWindowIndices(tB, options.WoI_s);
hWoI_A = plot(axWoI, tA(idxA), pA(idxA), ...
    'Color', options.PressureColor_A, ...
    'LineStyle', char(options.PressureLineStyle_A), ...
    'LineWidth', options.PressureLineWidth);
hold(axWoI, 'on');
hWoI_B = plot(axWoI, tB(idxB), pB(idxB), ...
    'Color', options.PressureColor_B, ...
    'LineStyle', char(options.PressureLineStyle_B), ...
    'LineWidth', options.PressureLineWidth);
xlabel(axWoI, options.TimeAxisLabel, 'Interpreter', 'latex');
ylabel(axWoI, options.PressureYAxisLabel, 'Interpreter', 'latex');
legend(axWoI, [hWoI_A, hWoI_B], ...
    cellstr([options.PressureLabel_A, options.PressureLabel_B]), ...
    'Location', 'northeast', 'Interpreter', 'latex');

woiTitle = options.WoITitle;
if strlength(woiTitle) == 0
    woiTitle = sprintf("Temporal Window of Interest: [%.3f, %.3f] s", ...
        options.WoI_s(1), options.WoI_s(2));
end
title(axWoI, woiTitle, 'Interpreter', 'latex');
localApplyPaddedXLim(axWoI, [tA(idxA); tB(idxB)], options.AxisPaddingFraction);
localApplyPaddedYLim(axWoI, [pA(idxA); pB(idxB)], options.AxisPaddingFraction);
grid(axWoI, 'on');
box(axWoI, 'on');
hold(axWoI, 'off');

sgtitle(tiled, {options.MainTitle, options.Subtitle}, 'Interpreter', 'latex');
end

function [t, y] = localSignal(runData, daqField, columnIdx)
daqField = char(daqField);
if ~isfield(runData, daqField)
    error("AuxFcn_PlotVH2DTwoDAQPressureTrigger_001:MissingDAQ", ...
        'DAQ field "%s" does not exist in runData.', daqField);
end

daqData = runData.(daqField);
if ~isfield(daqData, "t_s") || ~isfield(daqData, "signal")
    error("AuxFcn_PlotVH2DTwoDAQPressureTrigger_001:MissingSignalData", ...
        'DAQ field "%s" must contain t_s and signal.', daqField);
end

if columnIdx > size(daqData.signal, 2)
    error("AuxFcn_PlotVH2DTwoDAQPressureTrigger_001:ColumnOutOfRange", ...
        'Requested column %d for "%s", but signal has only %d columns.', ...
        columnIdx, daqField, size(daqData.signal, 2));
end

t = daqData.t_s(:);
y = daqData.signal(:, columnIdx);
end

function idx = localWindowIndices(t, window_s)
idx = find(t >= window_s(1) & t <= window_s(2));
if ~isempty(idx)
    return
end

[~, i0] = min(abs(t - window_s(1)));
[~, i1] = min(abs(t - window_s(2)));
idx = min(i0, i1):max(i0, i1);
end

function localApplyPaddedXLim(ax, x, padFraction)
x = x(isfinite(x));
if isempty(x)
    return
end

xMin = min(x);
xMax = max(x);
xPad = localPadding(xMin, xMax, padFraction);
xlim(ax, [xMin - xPad, xMax + xPad]);
end

function localApplyPaddedYLim(ax, y, padFraction)
y = y(isfinite(y));
if isempty(y)
    return
end

yMin = min(y);
yMax = max(y);
yPad = localPadding(yMin, yMax, padFraction);
ylim(ax, [yMin - yPad, yMax + yPad]);
end

function pad = localPadding(minValue, maxValue, padFraction)
valueRange = maxValue - minValue;
if valueRange == 0
    pad = abs(minValue) * padFraction + 1e-3;
else
    pad = padFraction * valueRange;
end
end
