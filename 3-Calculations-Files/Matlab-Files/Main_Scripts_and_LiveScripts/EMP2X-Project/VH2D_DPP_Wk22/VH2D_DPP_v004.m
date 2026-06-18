%% *Vented Hydrogen Deflagration Experiments*
%% *Preliminary Results Campaign Week 22 2026*
%% Data Processing Procedure (DPP)
%% *Objectives*
%% 
% * Learn how to operate systems and equipment to obtain reliable and repeatable 
% pressure measurements during a vented hydrogen deflagration.
% * Trouble shooting systems to identifying potential improvements or flaws 
% on procedures.
% * Vented Hydrogen deflagration time-series Analysis to determine maximum peak 
% over-pressure *∆Pmax [kPa]*.
%% General Plan
% add brief description and pictures
%% *Setup Description*
% add brief description and pictures
%% *Pressure Sensor Positioning*
% 
%% Data Processing Procedure (DPP) Overview
% *Units SI*
%% **1. Data Preparation (***DPR*)
% *1.1. Setup (Matlab Startup File)*
% *1.2 Load Raw Signal and MetaData Campaign*
%% 
% * Load Data and Assign Variables for each group of measurements
% * Loaded Data Table
% * Gas Mixing Table
% * DAQs System Table
% * Sensors Mapping Table
% * Group / daqSystem / daqChannel / locationLabel / isBlindSensor / Notes
% *1.3. Data Preprocessing*
%% 
% * *Unit conversion*
% * Pressure: bar to kPa
% * Concentration: ppm to vol.%
% * *Time Vectors Alignment*
% * Trigger at 4V define the zero time
% * *Pressure and Trigger Signal Preprocessed*
% * A preliminary temporal interval is defined to reduce data size before detailed 
% analysis.
%% *2. Exploratory Data Analysis (EDA)*
% 2.1 Preprocessed Data Overview
%% 
% * Preliminary Observations on Data Integrity (interference, missing data or 
% odd recordings behaviors)
% * Time Domain Analysis
% * Frequency Domain Analysis (FFT for each group/run)
%% **3. Data Processing & Analysis (***DPA*)
% *3.1 Data filtering/sensitivity*
%% 
% * Select Campaign/Group/Run/DAQ/Channel: choose one analysis target explicitly.
% * Filter Design
% * Based on EWT or FFT (depending on Blind Sensors Data Quality)
% * ∆Pmax in Function of Filter Order and Low Pass Filter Cutoff Frequency
% *3.1. Quantity of Interest (QoI) Extraction*
%% 
% * ∆Pmax
% * ∆P/∆t
% * Impulse
% * Summary Tables
% *3.3 Conclusions*
%% 
% * Conclusions
% * Potential Improvements Suggestions for Next Campaign
%% 1. Data Preparation (*DPR*)
% 1.1 Setup (Matlab Startup File)
% This m-File code prepare the environment to provide access to auxiliary files 
% and sub-folders.

clear ; clc; close all;
format short eng
scriptRoot = fileparts(mfilename("fullpath"));
[projectRoot,AuxFcn_GS] = AuxFcn_Matlab_Startup_File_001;
auxRoot = fullfile(projectRoot, ...
    "3-Calculations-Files", "Matlab-Files", "Auxilliary_Functions");
mainFcnRoot = fullfile(projectRoot, ...
    "3-Calculations-Files", "Matlab-Files", "Main_Functions");
addpath(genpath(auxRoot));
addpath(genpath(mainFcnRoot));
% Plots and Names Convention
% Figures are identified using a compact and traceable name. The same convention 
% will be used throughout preprocessing, exploratory data analysis, filtering, 
% and QoI extraction:
% 
% |Fig-<Run>-<Comparison>-<Stage>-<Purpose>-F<NN>-<Detail>|
% 
% *Stage codes*
%% 
% * |RAW|: raw data overview and loading diagnostics
% * |PP|: pressure/trigger preprocessing
% * |EDA|: exploratory data analysis
% * |FILT|: filtering and sensitivity analysis
% * |QOI|: quantity-of-interest extraction
%% 
% *Figure number*
%% 
% * |F01|, |F02|, |F03|, ... identify multiple figures within the same run/section.
% * |F| is used instead of |P| to avoid confusion with pressure sensor IDs such 
% as |P3|, |P5|, or |P7|.
%% 
% *Examples*
%% 
% * |Fig-Wk22-02-01-LUvsKistler-PP-WoI-F01-Flush|
% * |Fig-Wk22-02-02-LUvsKistler-PP-WoI-F01-Flush|
% * |Fig-Wk22-03-01-LUvsDBI-PP-F01-MountingMethods|
% * |Fig-Wk22-03-01-LUvsDBI-PP-WoI-F02-Recessed|
% * |Fig-Wk22-03-01-LUvsDBI-PP-WoI-F03-FlushBlind|
%% 
% *Future examples for later sections*
%% 
% * |Fig-Wk22-03-01-LUvsDBI-EDA-FFT-F01-AllComparable|
% * |Fig-Wk22-03-01-LUvsDBI-FILT-Sensitivity-F01-P5|
% * |Fig-Wk22-03-QOI-Summary-F01-Pmax|
%% 
% In MATLAB, the figure ID should be assigned to the figure |Name| property, 
% while the visible plot title can remain more descriptive for the report.

set(groot, 'defaultTextInterpreter', 'latex', 'defaultAxesTickLabelInterpreter','latex', 'defaultLegendInterpreter','latex');
LUCopper = [147, 86, 14]/255;LUCopper_Light = [225, 213, 199]/255;LUBlue = [17, 55, 125]/255;LUBlue_Light = [197, 204, 221]/255;
Red_Dark = [192, 0, 0]/255;Red_Light = [235, 200, 197]/255;pink = [255, 199, 206]/255;skyblue_light=[183/255 236/255 255/255];

% *1.2 Load & Overview of Raw Data Campaign*
% *1.2.1 Load Raw Data Campaign*
% *Campaign: VH2D-Wk22*
% One-Time-Run to Generate File Structure of the Campaign

% campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk22", ["02","03","04"]);
%% 
% Load Group Raw Data

campaignMatFile = fullfile(projectRoot, ...
    "2-Data", "ConvertedData", "VH2D-Wk22", ...
    "VH2D_Wk22_Groups_02_03_04.mat");
load(campaignMatFile)
campaign = VH2D_Wk22;
% *1.2 Raw Data Overview*
% The campaign cache contains the full raw data structure. The JSON metadata 
% files are used only to build compact, readable overview tables for the report.

metadataRoot = fullfile(projectRoot, "2-Data", "RawData", "VH2D-Wk22", "Metadata");
metadata = AuxFcn_LoadVH2DMetadata_001(metadataRoot, Groups=["02","03","04"]);
rawDataOverviewTable = AuxFcn_BuildVH2DRawOverviewTable_001(campaign, metadata);
reportTables = AuxFcn_BuildVH2DRawReportTables_001(campaign, metadata);
% *Raw Data Load Status*

rawLoadStatusTable = reportTables.rawLoadStatus;
rawLoadStatusDisplayTable = reportTables.rawLoadStatusDisplay;
% disp(rawLoadStatusDisplayTable);
% Channel Audit Summary
% (loaded channels vs. sensor mapping metadata)

daqSystemsToAudit = ["DAQ_1","DAQ_2_3","DAQ_4"];

[channelAuditTable, channelAuditSummaryTable, channelAuditWarningTable] = ...
    AuxFcn_BuildVH2DChannelAuditTable_001(campaign, metadata, ...
    DAQs=daqSystemsToAudit);
% Compact evidence overview: loaded channels plus expected metadata mapping.
% disp(channelAuditSummaryTable);

% Detailed rows only when the same loaded channel changes column across runs.
% disp(channelAuditWarningTable);
% *Run Plan Summary*

runPlanTable = reportTables.runPlan;
% disp(runPlanTable);
% *Gas Mixing Summary*

gasMixingTable = reportTables.gasMixing;
% disp(gasMixingTable);
% *DAQ Systems Summary*

daqSystemsTable = reportTables.daqSystems;
% disp(daqSystemsTable);
% *Pressure Sensor Mapping Summary*

sensorMappingTable = reportTables.sensorMap;
disp(sensorMappingTable);
% *Group and Run Notes Table*

groupAndRunNotesTable = reportTables.groupAndRunNotes;
% disp(groupAndRunNotesTable);
% *1.3. Data Preprocessing*
% *1.3.1 Unit Conversion*
% Pressure: bar to kPa and Concentration: ppm to vol.%

% Convert raw loaded units to analysis units while preserving the original
% raw campaign structure in `campaign`.
converted = AuxFcn_ConvertVH2DUnits_001(campaign);

conversionOverviewTable = converted.overview;
conversionSummaryTable = unique(conversionOverviewTable(:, ...
    {'DAQs','RawUnit','SourceUnit','SourceUnitEvidence', ...
    'TargetUnit','Factor','Status','Rule'}), 'rows');
% disp(conversionSummaryTable);
% *2.2 Time Vectors Alignment*
% Pressure Sensors Time aligned with Trigger at 4V define the zero time

% Use one common zero-time definition for all pressure/trigger DAQs:
% the first trigger crossing at 4 V. Signal values are not modified; only
% the time vectors are shifted.
aligned = AuxFcn_AlignVH2DTimeVectors_001(converted, ...
    TriggerZeroThreshold_V=4, ...
    DAQsToAlign=["DAQ_1","DAQ_2_3","DAQ_4"]);
alignmentOverviewTable = aligned.alignmentOverview;
alignmentSummaryDisplayTable = aligned.alignmentSummaryDisplayTable;
% disp(alignmentSummaryDisplayTable);
% 2.3 Remove DC Background Offset

% Remove DC background offset only from pressure channels. Trigger channels
% and concentration channels remain unchanged.
offsetCorrected = AuxFcn_RemoveVH2DPressureOffset_001(aligned, ...
    BaselineWindow_s=[-0.050, -0.005], ...
    KeepSourceSignal=false);

offsetOverviewTable = offsetCorrected.offsetOverview;
offsetSummaryTable = offsetOverviewTable(:, ...
    {'GroupId','RunId','DAQs','Column','Channel','Unit', ...
    'BaselineWindowStart_s','BaselineWindowEnd_s', ...
    'BaselineMean_kPa','BaselineStd_kPa','BaselineSamples','Status'});
% disp(offsetSummaryTable);
% 2.4 *Pressure and Trigger Signal Preprocessed*

% Keep only the preliminary pressure/trigger analysis window to reduce memory
% and plotting cost. Concentration measurements are not processed here.
pressurePreprocessed = AuxFcn_PreprocVH2DPressureTriggerSignals_001( ...
    offsetCorrected, ...
    PreprocWindow_s=[-0.050, 1.75], ...
    DAQs=["DAQ_1","DAQ_2_3","DAQ_4"]);
pressurePreprocessedOverviewTable = pressurePreprocessed.preprocOverview;
pressurePreprocessedSummaryTable = pressurePreprocessedOverviewTable(:, ...
    {'GroupId','RunId','DAQs','PreprocStart_s','PreprocEnd_s', ...
    'SourceSamples','KeptSamples','RemovedSamples','Status'});
% disp(pressurePreprocessedSummaryTable);
% clear campaign VH2D_Wk22 converted aligned offsetCorrected
% 2.5 Preprocessed Data
% *Group VH2D-Wk22-02 (LU vs Kistler)*

group = pressurePreprocessed.groups.Group_02;
run_Wk22_02_01 = group.runs.VH2D_Wk22_02_01;
run_Wk22_02_02 = group.runs.VH2D_Wk22_02_02;
run_Wk22_02_03 = group.runs.VH2D_Wk22_02_03;
run_Wk22_02_04 = group.runs.VH2D_Wk22_02_04;
% *Group VH2D-Wk22-03 (LU vs DBI)*

group = pressurePreprocessed.groups.Group_03;
run_Wk22_03_01 = group.runs.VH2D_Wk22_03_01;
run_Wk22_03_02 = group.runs.VH2D_Wk22_03_02;
run_Wk22_03_03 = group.runs.VH2D_Wk22_03_03;
run_Wk22_03_04 = group.runs.VH2D_Wk22_03_04;
run_Wk22_03_05 = group.runs.VH2D_Wk22_03_05;
% *Group VH2D-Wk22-04 (LU vs DBI)*

group = pressurePreprocessed.groups.Group_04;
run_Wk22_04_01 = group.runs.VH2D_Wk22_04_01;
run_Wk22_04_02 = group.runs.VH2D_Wk22_04_02;
run_Wk22_04_03 = group.runs.VH2D_Wk22_04_03;
run_Wk22_04_04 = group.runs.VH2D_Wk22_04_04;
run_Wk22_04_05 = group.runs.VH2D_Wk22_04_05;
%% 3. Exploratory Data Analysis (EDA)
% 3.1 Plot Preprocessed Data
% *3.1.1 Group VH2D-Wk22-02 (LU vs Kistler)*
% *Run Wk22-02-01*

% --- Run Wk22-02-01: Single Figure / 2 Tiles with Dynamic Axis Limits ---
% DAQ-1
t1 = run_Wk22_02_01.DAQ_1.t_s;
y1_p = run_Wk22_02_01.DAQ_1.signal(:,1);
ch1_p = run_Wk22_02_01.DAQ_1.channels(1);
y1_tr = run_Wk22_02_01.DAQ_1.signal(:,2);
ch1_tr = run_Wk22_02_01.DAQ_1.channels(2);

% DAQ-4
t2 = run_Wk22_02_01.DAQ_4.t_s;
y2_p = run_Wk22_02_01.DAQ_4.signal(:,1);
ch2_p = run_Wk22_02_01.DAQ_4.channels(1);
y2_tr = run_Wk22_02_01.DAQ_4.signal(:,2);
ch2_tr = run_Wk22_02_01.DAQ_4.channels(2);

% Define Window Of Interest (WoI) explicitly (seconds)
LB_WoI = 0;% in seconds
UB_WoI = 0.25;% in seconds
WoI = [LB_WoI, UB_WoI];  % in seconds

% Create 2x1 tiled figure and naming
figId = "Fig-Wk22-02-01-LUvsKistler-PP-WoI-F01-Flush";
fig = figure( ...
    'Name', figId, ...
    'NumberTitle', 'off', ...
    'Units','centimeters', ...
    'Position',[10 10 36 20]);

tiled = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
% Upper tile: pressures & triggers
% Left axis: pressures
axFull = nexttile;
yyaxis(axFull, 'left');
hP1 = plot(axFull, t1, y1_p, 'Color', LUBlue, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hP2 = plot(axFull, t2, y2_p, 'Color', LUCopper, 'LineStyle', '-', 'LineWidth', 0.5);
ylabel(axFull, "Overpressure [kPa]", 'Interpreter', 'latex');
axFull.YColor = 'k';
% Right axis: triggers
yyaxis(axFull, 'right');
hTr1 = plot(axFull, t1, y1_tr, 'Color', Red_Dark, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hTr2 = plot(axFull, t2, y2_tr, 'Color', Red_Light, 'LineStyle', ':', 'LineWidth', 0.5);
ylabel(axFull, 'Trigger Voltage [V]', 'Interpreter', 'latex');
axFull.YColor = Red_Dark;
% Common formatting
xlabel(axFull,'Time [s]', 'Interpreter', 'latex');
title(axFull,{'Preprocessed: Pressure $\&$ Trigger Signal',}, 'Interpreter', 'latex');

legend(axFull,[hP1,hP2,hTr1,hTr2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p,'Trigger (DAQ-1) ' + ch1_tr,'Trigger (DAQ-4) ' + ch2_tr}, ...
    'Location','northeast', 'Interpreter','latex');

grid(axFull,'on');
hold(axFull,'off')
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';

% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(:); t2(:)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axFull, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
yyaxis(axFull, 'left');
ylim(axFull, [pMin - pPad, pMax + pPad]);

% Right axis (triggers)
trAll = [y1_tr(:); y2_tr(:)];
trMin = min(trAll); trMax = max(trAll);
trRange = trMax - trMin;
if trRange == 0
    trPad = abs(trMin)*padFrac + 1e-3;
else
    trPad = padFrac * trRange;
end
yyaxis(axFull, 'right');
ylim(axFull, [trMin - trPad, trMax + trPad]);
box on

% Bottom tile: Window Of Interest (pressures only)
axWoI = nexttile;
% --- Logical indexing first (strict interval) ---
idx1 = find(t1 >= WoI(1) & t1 <= WoI(2));
idx2 = find(t2 >= WoI(1) & t2 <= WoI(2));

% --- Fallback to nearest-index if logical indexing yields empty
if isempty(idx1)
    [~, i0] = min(abs(t1 - WoI(1)));
    [~, i1] = min(abs(t1 - WoI(2)));
    idx1 = min(i0,i1):max(i0,i1);
end
if isempty(idx2)
    [~, j0] = min(abs(t2 - WoI(1)));
    [~, j1] = min(abs(t2 - WoI(2)));
    idx2 = min(j0,j1):max(j0,j1);
end


% Ensure non-empty before plotting
hold(axWoI,'on');
if ~isempty(idx1)
    axWoIhP1 = plot(axWoI, t1(idx1), y1_p(idx1), '-', 'Color', LUBlue, 'LineWidth', 0.9);
end
if ~isempty(idx2)
    axWoIhP2 = plot(axWoI, t2(idx2), y2_p(idx2), '-', 'Color', LUCopper, 'LineWidth', 0.9);
end
xlabel(axWoI, 'Time [s]', 'Interpreter','latex');
ylabel(axWoI, 'Overpressure [kPa]', 'Interpreter','latex');
legend(axWoI,[axWoIhP1,axWoIhP2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p}, ...
    'Location','northeast', 'Interpreter','latex');
title(axWoI, sprintf('Temporal Window of Interest: [%.3f, %.3f] s', WoI(1), WoI(2)), 'Interpreter','latex');
xlim(axWoI, WoI); 
% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(idx1); t2(idx2)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axWoI, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
ylim(axWoI, [pMin - pPad, pMax + pPad]);
grid(axWoI,'on');
hold(axWoI,'off');
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';
box on
% Add a single shared title above the two tiles
sgtitle(tiled, {"{\textbf{Run Wk22-02-01 (Conc. Target $H_2$ 18 vol.$\%$)}}",'LU vs Kistler DAQs (Flush Mounted Pressure Sensors + RTV)'}, 'Interpreter', 'latex');
% % close all
%% 
% *Run Wk22_02_02*

% --- Run Wk22-02-02: Single Figure / 2 Tiles with Dynamic Axis Limits ---
% DAQ-1
t1 = run_Wk22_02_02.DAQ_1.t_s;
y1_p = run_Wk22_02_02.DAQ_1.signal(:,1);
ch1_p = run_Wk22_02_02.DAQ_1.channels(1);
y1_tr = run_Wk22_02_02.DAQ_1.signal(:,2);
ch1_tr = run_Wk22_02_02.DAQ_1.channels(2);

% DAQ-4
t2 = run_Wk22_02_02.DAQ_4.t_s;
y2_p = run_Wk22_02_02.DAQ_4.signal(:,1);
ch2_p = run_Wk22_02_02.DAQ_4.channels(1);
y2_tr = run_Wk22_02_02.DAQ_4.signal(:,2);
ch2_tr = run_Wk22_02_02.DAQ_4.channels(2);

% Define Window Of Interest (WoI) explicitly (seconds)
LB_WoI = 0;% in seconds
UB_WoI = 0.25;% in seconds
WoI = [LB_WoI, UB_WoI];  % in seconds

% Create 2x1 tiled figure and naming
figId = "Fig-Wk22-02-02-LUvsKistler-PP-WoI-F01-Flush";
fig = figure( ...
    'Name', figId, ...
    'NumberTitle', 'off', ...
    'Units','centimeters', ...
    'Position',[10 10 36 20]);
tiled = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% Upper tile: pressures & triggers
% Left axis: pressures
axFull = nexttile;
yyaxis(axFull, 'left');
hP1 = plot(axFull, t1, y1_p, 'Color', LUBlue, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hP2 = plot(axFull, t2, y2_p, 'Color', LUCopper, 'LineStyle', '-', 'LineWidth', 0.5);
ylabel(axFull, "Overpressure [kPa]", 'Interpreter', 'latex');
axFull.YColor = 'k';
% Right axis: triggers
yyaxis(axFull, 'right');
hTr1 = plot(axFull, t1, y1_tr, 'Color', Red_Dark, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hTr2 = plot(axFull, t2, y2_tr, 'Color', Red_Light, 'LineStyle', ':', 'LineWidth', 0.5);
ylabel(axFull, 'Trigger Voltage [V]', 'Interpreter', 'latex');
axFull.YColor = Red_Dark;
% Common formatting
xlabel(axFull,'Time [s]', 'Interpreter', 'latex');
title(axFull,{'Preprocessed: Pressure $\&$ Trigger Signal',}, 'Interpreter', 'latex');

legend(axFull,[hP1,hP2,hTr1,hTr2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p,'Trigger (DAQ-1) ' + ch1_tr,'Trigger (DAQ-4) ' + ch2_tr}, ...
    'Location','northeast', 'Interpreter','latex');

grid(axFull,'on');
hold(axFull,'off')
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';

% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(:); t2(:)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axFull, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
yyaxis(axFull, 'left');
ylim(axFull, [pMin - pPad, pMax + pPad]);

% Right axis (triggers)
trAll = [y1_tr(:); y2_tr(:)];
trMin = min(trAll); trMax = max(trAll);
trRange = trMax - trMin;
if trRange == 0
    trPad = abs(trMin)*padFrac + 1e-3;
else
    trPad = padFrac * trRange;
end
yyaxis(axFull, 'right');
ylim(axFull, [trMin - trPad, trMax + trPad]);
box on

% Bottom tile: Window Of Interest (pressures only)
axWoI = nexttile;
% --- Logical indexing first (strict interval) ---
idx1 = find(t1 >= WoI(1) & t1 <= WoI(2));
idx2 = find(t2 >= WoI(1) & t2 <= WoI(2));

% --- Fallback to nearest-index if logical indexing yields empty
if isempty(idx1)
    [~, i0] = min(abs(t1 - WoI(1)));
    [~, i1] = min(abs(t1 - WoI(2)));
    idx1 = min(i0,i1):max(i0,i1);
end
if isempty(idx2)
    [~, j0] = min(abs(t2 - WoI(1)));
    [~, j1] = min(abs(t2 - WoI(2)));
    idx2 = min(j0,j1):max(j0,j1);
end


% Ensure non-empty before plotting
hold(axWoI,'on');
if ~isempty(idx1)
    axWoIhP1 = plot(axWoI, t1(idx1), y1_p(idx1), '-', 'Color', LUBlue, 'LineWidth', 0.9);
end
if ~isempty(idx2)
    axWoIhP2 = plot(axWoI, t2(idx2), y2_p(idx2), '-', 'Color', LUCopper, 'LineWidth', 0.9);
end
xlabel(axWoI, 'Time [s]', 'Interpreter','latex');
ylabel(axWoI, 'Overpressure [kPa]', 'Interpreter','latex');
legend(axWoI,[axWoIhP1,axWoIhP2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p}, ...
    'Location','northeast', 'Interpreter','latex');
title(axWoI, sprintf('Temporal Window of Interest: [%.3f, %.3f] s', WoI(1), WoI(2)), 'Interpreter','latex');
xlim(axWoI, WoI); 
% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(idx1); t2(idx2)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axWoI, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
ylim(axWoI, [pMin - pPad, pMax + pPad]);
grid(axWoI,'on');
hold(axWoI,'off');
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';
box on
% Add a single shared title above the two tiles
sgtitle(tiled, {"{\textbf{Run Wk22-02-02 (Conc. Target $H_2$ 18 vol.$\%$)}}",'LU vs Kistler DAQs (Flush Mounted Pressure Sensors + RTV)'}, 'Interpreter', 'latex');
% % close all
%% 
% *Run Wk22_02_03*

% --- Run Wk22-02-03: Single Figure / 2 Tiles with Dynamic Axis Limits ---
% DAQ-1
t1 = run_Wk22_02_03.DAQ_1.t_s;
y1_p = run_Wk22_02_03.DAQ_1.signal(:,1);
ch1_p = run_Wk22_02_03.DAQ_1.channels(1);
y1_tr = run_Wk22_02_03.DAQ_1.signal(:,2);
ch1_tr = run_Wk22_02_03.DAQ_1.channels(2);

% DAQ-4
t2 = run_Wk22_02_03.DAQ_4.t_s;
y2_p = run_Wk22_02_03.DAQ_4.signal(:,2);
ch2_p = run_Wk22_02_03.DAQ_4.channels(2);
y2_tr = run_Wk22_02_03.DAQ_4.signal(:,1);
ch2_tr = run_Wk22_02_03.DAQ_4.channels(1);

% Define Window Of Interest (WoI) explicitly (seconds)
LB_WoI = 0;% in seconds
UB_WoI = 0.25;% in seconds
WoI = [LB_WoI, UB_WoI];  % in seconds

% Create 2x1 tiled figure and naming
figId = "Fig-Wk22-02-03-LUvsKistler-PP-WoI-F01-Flush";
fig = figure( ...
    'Name', figId, ...
    'NumberTitle', 'off', ...
    'Units','centimeters', ...
    'Position',[10 10 36 20]);
tiled = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% Upper tile: pressures & triggers
% Left axis: pressures
axFull = nexttile;
yyaxis(axFull, 'left');
hP1 = plot(axFull, t1, y1_p, 'Color', LUBlue, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hP2 = plot(axFull, t2, y2_p, 'Color', LUCopper, 'LineStyle', '-', 'LineWidth', 0.5);
ylabel(axFull, "Overpressure [kPa]", 'Interpreter', 'latex');
axFull.YColor = 'k';
% Right axis: triggers
yyaxis(axFull, 'right');
hTr1 = plot(axFull, t1, y1_tr, 'Color', Red_Dark, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hTr2 = plot(axFull, t2, y2_tr, 'Color', Red_Light, 'LineStyle', ':', 'LineWidth', 0.5);
ylabel(axFull, 'Trigger Voltage [V]', 'Interpreter', 'latex');
axFull.YColor = Red_Dark;
% Common formatting
xlabel(axFull,'Time [s]', 'Interpreter', 'latex');
title(axFull,{'Preprocessed: Pressure $\&$ Trigger Signal',}, 'Interpreter', 'latex');

legend(axFull,[hP1,hP2,hTr1,hTr2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p,'Trigger (DAQ-1) ' + ch1_tr,'Trigger (DAQ-4) ' + ch2_tr}, ...
    'Location','northeast', 'Interpreter','latex');

grid(axFull,'on');
hold(axFull,'off')
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';

% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(:); t2(:)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axFull, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
yyaxis(axFull, 'left');
ylim(axFull, [pMin - pPad, pMax + pPad]);

% Right axis (triggers)
trAll = [y1_tr(:); y2_tr(:)];
trMin = min(trAll); trMax = max(trAll);
trRange = trMax - trMin;
if trRange == 0
    trPad = abs(trMin)*padFrac + 1e-3;
else
    trPad = padFrac * trRange;
end
yyaxis(axFull, 'right');
ylim(axFull, [trMin - trPad, trMax + trPad]);
box on

% Bottom tile: Window Of Interest (pressures only)
axWoI = nexttile;
% --- Logical indexing first (strict interval) ---
idx1 = find(t1 >= WoI(1) & t1 <= WoI(2));
idx2 = find(t2 >= WoI(1) & t2 <= WoI(2));

% --- Fallback to nearest-index if logical indexing yields empty
if isempty(idx1)
    [~, i0] = min(abs(t1 - WoI(1)));
    [~, i1] = min(abs(t1 - WoI(2)));
    idx1 = min(i0,i1):max(i0,i1);
end
if isempty(idx2)
    [~, j0] = min(abs(t2 - WoI(1)));
    [~, j1] = min(abs(t2 - WoI(2)));
    idx2 = min(j0,j1):max(j0,j1);
end


% Ensure non-empty before plotting
hold(axWoI,'on');
if ~isempty(idx1)
    axWoIhP1 = plot(axWoI, t1(idx1), y1_p(idx1), '-', 'Color', LUBlue, 'LineWidth', 0.9);
end
if ~isempty(idx2)
    axWoIhP2 = plot(axWoI, t2(idx2), y2_p(idx2), '-', 'Color', LUCopper, 'LineWidth', 0.9);
end
xlabel(axWoI, 'Time [s]', 'Interpreter','latex');
ylabel(axWoI, 'Overpressure [kPa]', 'Interpreter','latex');
legend(axWoI,[axWoIhP1,axWoIhP2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p}, ...
    'Location','northeast', 'Interpreter','latex');
title(axWoI, sprintf('Temporal Window of Interest: [%.3f, %.3f] s', WoI(1), WoI(2)), 'Interpreter','latex');
xlim(axWoI, WoI); 
% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(idx1); t2(idx2)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axWoI, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
ylim(axWoI, [pMin - pPad, pMax + pPad]);
grid(axWoI,'on');
hold(axWoI,'off');
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';
box on
% Add a single shared title above the two tiles
sgtitle(tiled, {"{\textbf{Run Wk22-02-03 (Conc. Target $H_2$ 20 vol.$\%$)}}",'LU vs Kistler DAQs (Flush Mounted Pressure Sensors + RTV)'}, 'Interpreter', 'latex');
% % close all
%% 
% *Run_Wk22_02_04*

% --- Run Wk22-02-04: Single Figure / 2 Tiles with Dynamic Axis Limits ---
% DAQ-1
t1 = run_Wk22_02_04.DAQ_1.t_s;
y1_p = run_Wk22_02_04.DAQ_1.signal(:,1);
ch1_p = run_Wk22_02_04.DAQ_1.channels(1);
y1_tr = run_Wk22_02_04.DAQ_1.signal(:,2);
ch1_tr = run_Wk22_02_04.DAQ_1.channels(2);

% DAQ-4
t2 = run_Wk22_02_04.DAQ_4.t_s;
y2_p = run_Wk22_02_04.DAQ_4.signal(:,2);
ch2_p = run_Wk22_02_04.DAQ_4.channels(2);
y2_tr = run_Wk22_02_04.DAQ_4.signal(:,1);
ch2_tr = run_Wk22_02_04.DAQ_4.channels(1);

% Define Window Of Interest (WoI) explicitly (seconds)
LB_WoI = 0;% in seconds
UB_WoI = 0.25;% in seconds
WoI = [LB_WoI, UB_WoI];  % in seconds

% Create 2x1 tiled figure and naming
figId = "Fig-Wk22-02-04-LUvsKistler-PP-WoI-F01-Flush";
fig = figure( ...
    'Name', figId, ...
    'NumberTitle', 'off', ...
    'Units','centimeters', ...
    'Position',[10 10 36 20]);
tiled = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% Upper tile: pressures & triggers
% Left axis: pressures
axFull = nexttile;
yyaxis(axFull, 'left');
hP1 = plot(axFull, t1, y1_p, 'Color', LUBlue, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hP2 = plot(axFull, t2, y2_p, 'Color', LUCopper, 'LineStyle', '-', 'LineWidth', 0.5);
ylabel(axFull, "Overpressure [kPa]", 'Interpreter', 'latex');
axFull.YColor = 'k';
% Right axis: triggers
yyaxis(axFull, 'right');
hTr1 = plot(axFull, t1, y1_tr, 'Color', Red_Dark, 'LineStyle', '-', 'LineWidth', 0.5); 
hold(axFull,'on');
hTr2 = plot(axFull, t2, y2_tr, 'Color', Red_Light, 'LineStyle', ':', 'LineWidth', 0.5);
ylabel(axFull, 'Trigger Voltage [V]', 'Interpreter', 'latex');
axFull.YColor = Red_Dark;
% Common formatting
xlabel(axFull,'Time [s]', 'Interpreter', 'latex');
title(axFull,{'Preprocessed: Pressure $\&$ Trigger Signal',}, 'Interpreter', 'latex');

legend(axFull,[hP1,hP2,hTr1,hTr2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p,'Trigger (DAQ-1) ' + ch1_tr,'Trigger (DAQ-4) ' + ch2_tr}, ...
    'Location','northeast', 'Interpreter','latex');

grid(axFull,'on');
hold(axFull,'off')
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';

% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(:); t2(:)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axFull, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
yyaxis(axFull, 'left');
ylim(axFull, [pMin - pPad, pMax + pPad]);

% Right axis (triggers)
trAll = [y1_tr(:); y2_tr(:)];
trMin = min(trAll); trMax = max(trAll);
trRange = trMax - trMin;
if trRange == 0
    trPad = abs(trMin)*padFrac + 1e-3;
else
    trPad = padFrac * trRange;
end
yyaxis(axFull, 'right');
ylim(axFull, [trMin - trPad, trMax + trPad]);
box on

% Bottom tile: Window Of Interest (pressures only)
axWoI = nexttile;
% --- Logical indexing first (strict interval) ---
idx1 = find(t1 >= WoI(1) & t1 <= WoI(2));
idx2 = find(t2 >= WoI(1) & t2 <= WoI(2));

% --- Fallback to nearest-index if logical indexing yields empty
if isempty(idx1)
    [~, i0] = min(abs(t1 - WoI(1)));
    [~, i1] = min(abs(t1 - WoI(2)));
    idx1 = min(i0,i1):max(i0,i1);
end
if isempty(idx2)
    [~, j0] = min(abs(t2 - WoI(1)));
    [~, j1] = min(abs(t2 - WoI(2)));
    idx2 = min(j0,j1):max(j0,j1);
end

% Ensure non-empty before plotting
hold(axWoI,'on');
if ~isempty(idx1)
    axWoIhP1 = plot(axWoI, t1(idx1), y1_p(idx1), '-', 'Color', LUBlue, 'LineWidth', 0.9);
end
if ~isempty(idx2)
    axWoIhP2 = plot(axWoI, t2(idx2), y2_p(idx2), '-', 'Color', LUCopper, 'LineWidth', 0.9);
end
xlabel(axWoI, 'Time [s]', 'Interpreter','latex');
ylabel(axWoI, 'Overpressure [kPa]', 'Interpreter','latex');
legend(axWoI,[axWoIhP1,axWoIhP2], ...
    {'Pressure (DAQ-1) '+ ch1_p,'Pressure (DAQ-4) ' + ch2_p}, ...
    'Location','northeast', 'Interpreter','latex');
title(axWoI, sprintf('Temporal Window of Interest: [%.3f, %.3f] s', WoI(1), WoI(2)), 'Interpreter','latex');
xlim(axWoI, WoI); 
% --- Dynamic axis limits (5% padding) ---
padFrac = 0.05;

% X limits combining t1 and t2
tAll = [t1(idx1); t2(idx2)];
tMin = min(tAll); tMax = max(tAll);
tRange = tMax - tMin;
if tRange == 0
    tPad = abs(tMin)*padFrac + 1e-3;
else
    tPad = padFrac * tRange;
end
xlim(axWoI, [tMin - tPad, tMax + tPad]);

% Left axis (pressures)
pAll = [y1_p(:); y2_p(:)];
pMin = min(pAll); pMax = max(pAll);
pRange = pMax - pMin;
if pRange == 0
    pPad = abs(pMin)*padFrac + 1e-3;
else
    pPad = padFrac * pRange;
end
ylim(axWoI, [pMin - pPad, pMax + pPad]);
grid(axWoI,'on');
hold(axWoI,'off');
% pbaspect(axFull, [16 9 1]);
% axFull.PlotBoxAspectRatioMode = 'manual';
box on
% Add a single shared title above the two tiles
sgtitle(tiled, {"{\textbf{Run Wk22-02-04 (Conc. Target $H_2$ 20 vol.$\%$)}}",'LU vs Kistler DAQs (Flush Mounted Pressure Sensors + RTV)'}, 'Interpreter', 'latex');
% % close all

% *3.1.2 Group VH2D-Wk22-03 (LU vs DBI)*
% *Note: Run Wk22-03-03 not included in the analysis.* Hot-wire short circuit. 
% Data potentially compromised.
% 
% *Group Sensors Mapping Plot Plan Table*
% Build the plotting plan from metadata and loaded-channel evidence. This
% avoids hardcoding channel columns, which is important because DAQ channel
% order can change between files.
groupId = "VH2D-Wk22-03";
plotPlanTable = sensorMappingTable( ...
    sensorMappingTable.GroupId == groupId & ...
    sensorMappingTable.IsActive & ...
    ~sensorMappingTable.IsTriggerChannel & ...
    lower(sensorMappingTable.MeasuredQuantity) == "pressure" & ...
    lower(sensorMappingTable.MountingMethod) ~= "other", :);

mountingNotes = lower(plotPlanTable.Notes);
hasHighVacuumGrease = contains(mountingNotes, "grease") | ...
    contains(mountingNotes, "greaese") | contains(mountingNotes, "vacuum");

MountingClass = strings(height(plotPlanTable), 1);
MountingClass(plotPlanTable.IsBlindSensor) = "Blind_RTV";
MountingClass(~plotPlanTable.IsBlindSensor & ...
    lower(plotPlanTable.MountingMethod) == "flush") = "Flush_RTV";
MountingClass(~plotPlanTable.IsBlindSensor & ...
    lower(plotPlanTable.MountingMethod) == "recessed" & ...
    ~hasHighVacuumGrease) = "Recessed_RTV";
MountingClass(~plotPlanTable.IsBlindSensor & ...
    lower(plotPlanTable.MountingMethod) == "recessed" & ...
    hasHighVacuumGrease) = "Recessed_RTV_HighVacuumGrease";

DaqFamily = strings(height(plotPlanTable), 1);
DaqFamily(contains(strtrim(plotPlanTable.DaqSystem), "DAQ-1")) = "LU";
DaqFamily(contains(strtrim(plotPlanTable.DaqSystem), "DAQ-2") | ...
    contains(strtrim(plotPlanTable.DaqSystem), "DAQ-3")) = "DBI";

plotPlanTable = addvars(plotPlanTable, MountingClass, DaqFamily, ...
    'After', 'MountingMethod');
plotPlanTable = sortrows(plotPlanTable, ...
    {'MountingClass','LocationLabel','DaqFamily','SensorId'});

disp(plotPlanTable(:, {'SensorId','DaqFamily','DaqSystem','DaqChannel', ...
    'LoadedDataColumn','LoadedDataChannel','LocationLabel', ...
    'MountingClass','IsBlindSensor'}));
%%
% **Plots Structure**
% *Fig-Wk22-03-01-LUvsDBI-PP-F01-MountingMethods*
% 
% (4 tiles in 1 column)
% 
% tile-1: Lu&DBI - Recessed + Trigger
% 
% tile-2: Lu&DBI -Recessed with Grease + Trigger
% 
% tile-3: Lu&DBI -Flush  + Trigger
% 
% tile-4: Lu&DBI -Blind  + Trigger
% 
% *Fig-Wk22-03-01-LUvsDBI-PP-WoI-F02-Recessed*
% 
% (2 tiles in 1 column)
% 
% WoI: [0-0.25]s
% 
% tile-1: Lu&DBI - Recessed
% 
% tile-2: Lu&DBI -Recessed with Grease
% 
% *Fig-Wk22-03-01-LUvsDBI-PP-WoI-F03-FlushBlind*
% 
% (2 tiles in 1 column)
% 
% WoI: [0-0.25]s
% 
% tile-1: Lu&DBI - Flush
% 
% tile-2: Lu&DBI -blind
%% 
% *Run Wk22-03-01*

runId = "VH2D-Wk22-03-01";
runData = run_Wk22_03_01;
%% 
figs_Wk22_03_01 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.25], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 
% *Run Wk22-03-02*

runId = "VH2D-Wk22-03-02";
runData = run_Wk22_03_02;
figs_Wk22_03_02 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.25], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 
% *Run Wk22-03-04*
% 
% *Note:* Strange behavior on data from DAQ-3 (DBI sensor recessed + High Vacuum 
% Grease) after the hot-wire short-circuit!!!

runId = "VH2D-Wk22-03-04";
runData = run_Wk22_03_04;
figs_Wk22_03_04 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.25], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 
% *Run Wk22-03-05*
runId = "VH2D-Wk22-03-05";
runData = run_Wk22_03_05;
figs_Wk22_03_05 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.25], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);

% *3.1.3 Group VH2D-Wk22-04 (LU vs DBI)*
% *Note: Run Wk22-04-05 not included in the analysis.* Non-Homogeneous Mixture
% 
% *Group Sensors Mapping Plot Plan Table*
% Build the plotting plan from metadata and loaded-channel evidence. This
% avoids hardcoding channel columns, which is important because DAQ channel
% order can change between files.
groupId = "VH2D-Wk22-04";
plotPlanTable = sensorMappingTable( ...
    sensorMappingTable.GroupId == groupId & ...
    sensorMappingTable.IsActive & ...
    ~sensorMappingTable.IsTriggerChannel & ...
    lower(sensorMappingTable.MeasuredQuantity) == "pressure" & ...
    lower(sensorMappingTable.MountingMethod) ~= "other", :);

mountingNotes = lower(plotPlanTable.Notes);
hasHighVacuumGrease = contains(mountingNotes, "grease") | ...
    contains(mountingNotes, "greaese") | contains(mountingNotes, "vacuum");

MountingClass = strings(height(plotPlanTable), 1);
MountingClass(plotPlanTable.IsBlindSensor) = "Blind_RTV";
MountingClass(~plotPlanTable.IsBlindSensor & ...
    lower(plotPlanTable.MountingMethod) == "flush") = "Flush_RTV";
MountingClass(~plotPlanTable.IsBlindSensor & ...
    lower(plotPlanTable.MountingMethod) == "recessed" & ...
    ~hasHighVacuumGrease) = "Recessed_RTV";
MountingClass(~plotPlanTable.IsBlindSensor & ...
    lower(plotPlanTable.MountingMethod) == "recessed" & ...
    hasHighVacuumGrease) = "Recessed_RTV_HighVacuumGrease";

DaqFamily = strings(height(plotPlanTable), 1);
DaqFamily(contains(strtrim(plotPlanTable.DaqSystem), "DAQ-1")) = "LU";
DaqFamily(contains(strtrim(plotPlanTable.DaqSystem), "DAQ-2") | ...
    contains(strtrim(plotPlanTable.DaqSystem), "DAQ-3")) = "DBI";

plotPlanTable = addvars(plotPlanTable, MountingClass, DaqFamily, ...
    'After', 'MountingMethod');
plotPlanTable = sortrows(plotPlanTable, ...
    {'MountingClass','LocationLabel','DaqFamily','SensorId'});

disp(plotPlanTable(:, {'SensorId','DaqFamily','DaqSystem','DaqChannel', ...
    'LoadedDataColumn','LoadedDataChannel','LocationLabel', ...
    'MountingClass','IsBlindSensor'}));
%% 
% *Run Wk22-04-01*

runId = "VH2D-Wk22-04-01";
runData = run_Wk22_04_01;
figs_Wk22_04_01 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.5], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 
% *Run Wk22-04-02*

runId = "VH2D-Wk22-04-02";
runData = run_Wk22_04_02;
figs_Wk22_04_02 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.5], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 
% *Run Wk22-04-03*

runId = "VH2D-Wk22-04-03";
runData = run_Wk22_04_03;
figs_Wk22_04_03 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.25], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 
% *Run Wk22-04-04*
% 
% *Note:* Strange behavior on data from DAQ-3 (DBI sensor recessed + High Vacuum 
% Grease) after the hot-wire short-circuit!!!

runId = "VH2D-Wk22-04-04";
runData = run_Wk22_04_04;
figs_Wk22_04_04 = AuxFcn_PlotVH2DLUvsDBIRun_001( ...
    runData, plotPlanTable, runId, ...
    WoI_s=[0, 0.25], ...
    LUColor=LUBlue, ...
    DBIColor=LUCopper, ...
    TriggerColor=Red_Dark, ...
    LineWidth=0.75, ...    
    GasMixingTable=gasMixingTable);
%% 3. Exploratory Data Analysis (EDA)
% *3.1 Sample Rate Verification*
% *Objective:* verify reported metadata in the generated .txt data file and 
% compare against DAQ system datasheet and samples time stamps.
% 
% *Workflow (Outputs to track):*
%% 
% # samplingRateSummary     -> metadata vs timestamps vs datasheet
% # timingUncertainty       -> mean/std/u/U95 from timestamp deltas
% # samplingRateDiffSummary -> relative differences (%)

daqIdx = 1; % Index of the TXT DAQ to verify
samplingRateResults = struct([]);

for iTest = 1:numel(tests)
    thisData = tests(iTest).daqs(daqIdx).data;

    % Only perform verification if data exists and contains the raw table (TXT files)
    if isempty(thisData) || ~isfield(thisData, 'tbl')
        continue;
    end

    % Call the new version of the auxiliary function
    [samplingRateSummary_i, timingUncertainty_i, samplingRateDiffSummary_i, samplingRateMetrics_i] = ...
        AuxFcn_SamplingRateVerification_001(thisData.tbl, thisData.dt, thisData.fs, 200e3, 2);

    % Store results using the new fileName field
    samplingRateResults(iTest).fileName = thisData.fileName;
    samplingRateResults(iTest).samplingRateSummary = samplingRateSummary_i;
    samplingRateResults(iTest).timingUncertainty = timingUncertainty_i;
    samplingRateResults(iTest).samplingRateDiffSummary = samplingRateDiffSummary_i;
    samplingRateResults(iTest).samplingRateMetrics = samplingRateMetrics_i;

    fprintf('\n--- Sample-rate verification: %s ---\n', thisData.fileName);
    disp(samplingRateSummary_i);
    disp(timingUncertainty_i);
    disp(samplingRateDiffSummary_i);

    % Check for discrepancies (> 1%)
    if abs(samplingRateMetrics_i.fsDiff_timeMean_vs_meta_pct) > 1
        warning('[%s] Timestamp mean fs and metadata fs differ by more than 1%%.', thisData.fileName);
    end

    if abs(samplingRateMetrics_i.fsDiff_meta_vs_datasheet_pct) > 1
        warning(['[%s] Metadata fs differs from datasheet nominal value by %.4f%% ' ...
            '(metadata: %.3f Hz, datasheet: %.3f Hz).'], ...
            thisData.fileName, samplingRateMetrics_i.fsDiff_meta_vs_datasheet_pct, ...
            thisData.fs, samplingRateMetrics_i.fsDataSheet);
    end
end
% 3.2 Pressure Sensors Signal Verification (Data Integrity Verification)
% *Objective:* verify the impact of the ignition mechanism (Channel 4 (Y)) on 
% pressure sensors. Time when ignition tigger
% 
% *Workflow:*
%% 
% # extract Test 1 pressure channel (Y[0]) and trigger channel (Y[3])
% # convert pressure to kPa
% # plot both channels with dual y-axes for time alignment check
% 3.2.1 Ignition *Trigger Misalignment & Synchronization Failure*

testIdx = 1;
daqIdx  = 1;

% Access data using the descriptive 'daqs' field
daqData = tests(testIdx).daqs(daqIdx).data;

if ~isempty(daqData) && daqData.nChannels >= 4
    % Extract signals from standardized fields
    t_test = daqData.t;

    % Pressure (Ch 1) and Trigger (Ch 4)
    y_pressure = daqData.signal(:, 1) * 100; % Convert to kPa
    y_trigger  = daqData.signal(:, 4);

    % Prepare LaTeX-safe labels
    label_Ch1 = sprintf('%s | %s', daqData.fileName, daqData.channelNames(1));
    label_Ch4 = sprintf('%s | %s', daqData.fileName, daqData.channelNames(4));

    figure;
    set(gcf,'color','w');
    colororder([LUBlue; Red_Dark]);

    % --- Main Plot: Left Axis ---
    yyaxis left
    plot(t_test, y_pressure, 'LineWidth', 1.2);
    ylabel('Overpressure [kPa]', 'Interpreter', 'latex');

    % --- Main Plot: Right Axis ---
    yyaxis right
    plot(t_test, y_trigger, 'LineWidth', 1.0);
    ylabel('Trigger Voltage Signal [V]', 'Interpreter', 'latex');

    xlabel('Time [s]', 'Interpreter', 'latex');
    title({'Tunnel Hydrogen Deflagration Experiments', daqData.fileName}, 'Interpreter', 'latex');
    legend({label_Ch1, label_Ch4}, 'Location', 'northeast', 'Interpreter', 'latex');

    set(gca, 'FontName', "Helvetica", 'FontSize', 14);
    grid on; box on;

    % --- INSERT ZOOM INSET (0.28 - 0.32 s) ---
    zoomWin = [0.28, 0.32];
    idxZoom = (t_test >= zoomWin(1) & t_test <= zoomWin(2));

    if any(idxZoom)
        % Position the inset axes (Top-center area)
        axMain = gca;
        axPos = axMain.Position;
        % [left, bottom, width, height]
        axIn = axes('Position', [axPos(1)+0.60*axPos(3), axPos(2)+0.45*axPos(4), 0.35*axPos(3), 0.40*axPos(4)]);

        % Plot Dual Y-Axis inside the inset
        yyaxis(axIn, 'left');
        plot(axIn, t_test(idxZoom), y_pressure(idxZoom), 'LineWidth', 1.2);
        set(axIn, 'YColor', LUBlue); % Ensure color consistency

        yyaxis(axIn, 'right');
        plot(axIn, t_test(idxZoom), y_trigger(idxZoom), 'LineWidth', 1.0);
        set(axIn, 'YColor', Red_Dark);

        % Inset Formatting
        xlim(axIn, zoomWin);
        grid(axIn, 'on');
        title(axIn, 'Zoom: 0.28-0.32 s', 'FontSize', 10, 'Interpreter', 'latex');
        set(axIn, 'FontSize', 9);
    end
end
% *2.3  Trigger Signal Verification (EMI Interference & Trigger Pulse Width)*
% (Trigger Noise Frequency Verification)
% 
% *Objective:* verify whether trigger-channel oscillation in Test 1 is consistent 
% with 50 Hz power-line EMI (Europe).
% 
% *Workflow:*
%% 
% # isolate the suspect interval (0.5-1.0 s) from Test 1, Channel 4
% # remove DC offset and apply Hann window (lower spectral leakage)
% # compute the single-sided FFT amplitude spectrum
% # quantify peaks near 50 Hz and in a broader 40-80 Hz band
% # plot time-domain segment + spectrum with 50/100/150 Hz references
% 2.3.1 Selected Data

emiTestIdx = 1;          % Test used for EMI check
emiDaqIdx  = 1;          % Standardized DAQ stream
emiChIdx   = 4;          % Channel 4 -> Y[3] trigger signal
emiWindow  = [0.5, 1.0]; % Analysis time window [s]

% Extract the standardized daqData object
daqDataEMI = tests(emiTestIdx).daqs(emiDaqIdx).data;

% Verify the required channel exists in the selected DAQ
assert(~isempty(daqDataEMI) && daqDataEMI.nChannels >= emiChIdx, ...
    'Selected DAQ does not contain channel %d.', emiChIdx);

% --- EXPLICIT CALL: 'false' means we want raw Volts, no conversion ---
[t_emi, y_emi, fs_emi] = AuxFcn_GetWindowedSignal_001(daqDataEMI, emiChIdx, emiWindow, false);
N_emi = numel(y_emi);

% 2.3.2 Remove DC Offset and Taper

y_emi_detr = y_emi - mean(y_emi, 'omitnan');
w_emi = hann(N_emi, 'periodic'); % see note on Hanning(Hann) window
y_emi_win = y_emi_detr .* w_emi;
% 2.3.3 Compute FFT
% FFT to one-sided amplitude spectrum (resolution = fs_emi/N_emi)

Y_emi = fft(y_emi_win);
P2_emi = abs(Y_emi / (N_emi * mean(w_emi))); % Added mean(w_emi) to recover the True Amplitude in Volts
P1_emi = P2_emi(1:floor(N_emi/2)+1);
if numel(P1_emi) > 2
    P1_emi(2:end-1) = 2 * P1_emi(2:end-1);
end
f_emi = fs_emi * (0:floor(N_emi/2)) / N_emi;
% 2.3.4 Quantify Frequency Peaks

% Peak search around nominal mains frequency
searchBW = 2;  % +/- Hz around 50 Hz
idx50 = f_emi >= (50 - searchBW) & f_emi <= (50 + searchBW);

f50_peak = NaN; A50_peak = NaN;
if any(idx50)
    [A50_peak, i50] = max(P1_emi(idx50));
    f50_vec = f_emi(idx50);
    f50_peak = f50_vec(i50);
end

% Identify dominant component in a broader EMI band
emiBand = [40, 80];
idxBand = f_emi >= emiBand(1) & f_emi <= emiBand(2);
f_dom = NaN; A_dom = NaN;
if any(idxBand)
    [A_dom, iDom] = max(P1_emi(idxBand));
    fBand = f_emi(idxBand);
    f_dom = fBand(iDom);
end

fprintf('\n--- EMI verification (%s, Trigger Channel %d, %.3f-%.3f s) ---\n', ...
    daqDataEMI.fileName, emiChIdx, emiWindow(1), emiWindow(2));
fprintf('Peak near 50 Hz: f = %.3f Hz, A = %.5g\n', f50_peak, A50_peak);
fprintf('Dominant peak in %.0f-%.0f Hz band: f = %.3f Hz, A = %.5g\n', ...
    emiBand(1), emiBand(2), f_dom, A_dom);
% --- Calculate Harmonics and Prominence ---
idx100 = f_emi >= (100 - searchBW) & f_emi <= (100 + searchBW);
idx150 = f_emi >= (150 - searchBW) & f_emi <= (150 + searchBW);
f100_peak = NaN; A100_peak = NaN;
f150_peak = NaN; A150_peak = NaN;

if any(idx100)
    [A100_peak, i100] = max(P1_emi(idx100));
    f100_vec = f_emi(idx100);
    f100_peak = f100_vec(i100);
end
if any(idx150)
    [A150_peak, i150] = max(P1_emi(idx150));
    f150_vec = f_emi(idx150);
    f150_peak = f150_vec(i150);
end

idxBandNo50 = idxBand & ~(f_emi >= (50 - searchBW) & f_emi <= (50 + searchBW));
A_band_no50 = P1_emi(idxBandNo50);
if isempty(A_band_no50)
    A_band_no50_med = NaN;
else
    A_band_no50_med = median(A_band_no50, 'omitnan');
end
prominence50 = A50_peak / A_band_no50_med;

% Compact summary table
emiSummaryTable = table( ...
    emiTestIdx, emiChIdx, emiWindow(1), emiWindow(2), ...
    f50_peak, A50_peak, f100_peak, A100_peak, f150_peak, A150_peak, ...
    f_dom, A_dom, prominence50, ...
    'VariableNames', { ...
    'TestIdx','ChannelIdx','WindowStart_s','WindowEnd_s', ...
    'Peak50_Hz','Amp50_V','Peak100_Hz','Amp100_V','Peak150_Hz','Amp150_V', ...
    'Dominant40to80_Hz','Dominant40to80Amp_V','Prominence50_vsBandMedian'});
disp(emiSummaryTable);
% Interpretation Logic
if ~isnan(f_dom) && abs(f_dom - 50) <= 1.5 && ~isnan(prominence50) && prominence50 >= 10
    emiInterpretation = sprintf(['EMI conclusion: Strong evidence of 50 Hz mains interference ' ...
        '(dominant %.2f Hz; prominence %.1fx above 40-80 Hz median excluding 50 Hz).'], ...
        f_dom, prominence50);
elseif ~isnan(f_dom) && abs(f_dom - 50) <= 3
    emiInterpretation = sprintf(['EMI conclusion: Likely 50 Hz mains interference ' ...
        '(dominant %.2f Hz), but with weaker separation from background.'], f_dom);
else
    emiInterpretation = sprintf(['EMI conclusion: Inconclusive for 50 Hz dominance ' ...
        '(dominant %.2f Hz in 40-80 Hz band).'], f_dom);
end
fprintf('%s\n', emiInterpretation);
% 2.3.5 Trigger Pulse Width Verification

% Extract the entire trigger signal to locate the actual pulse
t_full = daqDataEMI.t;
y_full = daqDataEMI.signal(:, emiChIdx);

% Define logical threshold for 5V TTL (2.5V is industry standard)
trigThreshold = 2.5;
isHigh = y_full >= trigThreshold;

% Find edge indices (diff = 1 for rising, -1 for falling)
edgeEvents = diff(isHigh);
idxRise = find(edgeEvents == 1, 1, 'first');
idxFall = find(edgeEvents == -1, 1, 'first');

if ~isempty(idxRise) && ~isempty(idxFall) && (idxFall > idxRise)
    t_rise = t_full(idxRise);
    t_fall = t_full(idxFall);
    pulseWidth_s = t_fall - t_rise; % Keep in seconds for ratio math

    % Calculate minimum required pulse based on sampling rate
    dt = 1 / fs_emi;
    minReqPulse_s = 2 * dt;
    pulseRatio = pulseWidth_s / minReqPulse_s;

    fprintf('Sampling Rate (fs): %.0f Hz (dt = %.5f s)\n', fs_emi, dt);
    fprintf('Rising Edge detected at:  %.4f s\n', t_rise);
    fprintf('Falling Edge detected at: %.4f s\n', t_fall);
    fprintf('Calculated Pulse Width:   %.4f s (%.1f ms)\n\n', pulseWidth_s, pulseWidth_s*1000);

    fprintf('OBSERVATION:\n');
    fprintf('To guarantee detection, a trigger pulse typically needs to be at least\n');
    fprintf('2x the sampling interval (2*dt = %.2f ms).\n', minReqPulse_s*1000);
    fprintf('The measured pulse is %.0f times longer than this theoretical minimum.\n', pulseRatio);
    fprintf('It is recommended to verify if this extended duration is required and any potential impact.\n');
else
    fprintf('WARNING: Could not cleanly detect both a rising and falling edge crossing %.1f V.\n', trigThreshold);
end
% 2.3.6 Visualisation


fileName = daqDataEMI.fileName;
chName   = daqDataEMI.channelNames(emiChIdx);
figure;
set(gcf, 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

% Top panel: Time domain trigger oscillation
nexttile;
plot(t_emi, y_emi, 'Color', Red_Dark, 'LineWidth', 1.0);
grid on; axis tight;
xlabel('Time [s]', 'Interpreter', 'latex');
ylabel('Trigger Voltage [V]', 'Interpreter', 'latex');
title(sprintf('%s | %s | EMI window %.1f-%.1f s', fileName, chName, emiWindow(1), emiWindow(2)), ...
    'Interpreter', 'latex');

% Bottom panel: FFT magnitude
nexttile;
plot(f_emi, P1_emi, 'Color', LUBlue, 'LineWidth', 1.0); hold on;
xline(50, '--', '50 Hz', 'Color', [0.30 0.30 0.30], 'LabelVerticalAlignment', 'bottom');
xline(100, '--', '100 Hz', 'Color', [0.30 0.30 0.30], 'LabelVerticalAlignment', 'bottom');
xline(150, '--', '150 Hz', 'Color', [0.30 0.30 0.30], 'LabelVerticalAlignment', 'bottom');

if ~isnan(f50_peak)
    plot(f50_peak, A50_peak, 'o', 'Color', Red_Dark, 'MarkerFaceColor', Red_Dark, 'DisplayName', 'Peak near 50 Hz');
end
if ~isnan(f_dom)
    plot(f_dom, A_dom, 'd', 'Color', Red_Dark, 'MarkerFaceColor', Red_Dark, 'DisplayName', 'Dominant 40-80 Hz peak');
end

grid on;
xlim([0, min(200, fs_emi/2)]);
xlabel('Frequency [Hz]', 'Interpreter', 'latex');
ylabel('Single-Sided Amplitude [V]', 'Interpreter', 'latex');
title('FFT of Trigger Signal (EMI Check)', 'Interpreter', 'latex');
legend('Location', 'northeast');
% 2.4 Time Domain Analysis
% *2.4.1 Baseline/Offset Assessment*
% *Objective:* Identify any baseline offset and decide on necessary baseline 
% correction.
% 
% *Workflow:*
%% 
% # select pre-event sample window
% # compute per-channel baseline statistics
% # decide whether offset removal is required
%% 
% *Note:* Offset correction based on the *first 100 samples.*
% *2.4.2 DC-Offset-Correction*
% *Objective:* Pressure reading corrected (offset/baseline removed)
% 
% *Workflow:*
%% 
% # estimate baseline from pre-event segment
% # subtract baseline from pressure channels
% # verify corrected traces preserve event dynamics

% Not Implemented
% 2.4.3 Corrected Pressure Signal Summary (DC-Offset-Corrected)
% *Objective:* quantify key time-domain metrics from corrected pressure signals 
% (peak overpressure, minimum pressure, timing, impulse, and energy).
% 
% *Workflow:*
%% 
% # use DC-offset-corrected pressure signals
% # compute pMax/pMin and corresponding occurrence times
% # compute impulse and cumulative impulse check
% # compute total signal energy
% # compile summary table for cross-test comparison
%% 
% *Compute Pressure max, and min across each test*

% Not Implemented
%% 
% *Compute Impulse and Signal Energy [kPa.ms]*

% Not Implemented
%% 
% *Impulse Check by Cumulative*

% Not Implemented
%% 
% *Compute Signal Energy [kPa^2]*

% Not Implemented
%% 
% *Table Summary*

% Not Implemented

%% 3. Preliminary Observations on Data Integrity
% *3.1 Justification for Suspending DC-Offset Correction*
% Based on the signal verification steps, the data integrity is currently compromised 
% by three interacting hardware issues, making standard software-based DC offset 
% corrections invalid:
%% 
% # *Thermal or Time Constant Effect:* In Section 1.2 (Plot Imported Signal 
% Data), it is evident that the pressure signals do not return to the baseline 
% (zero pressure) following the deflagration event. This behavior requires further 
% investigation, including consulting Kistler, to verify whether this offset is 
% an artifact of the system's discharge time constant (tau) or a result of thermal 
% shock to the sensor diaphragm.
% # *Trigger Misalignment & Synchronization Failure:* The exact Zero-Time (t=0) 
% is untrustworthy due to DAQ synchronization issues. Without a reliable time 
% reference, defining a "pre-event window" to calculate a baseline offset is arbitrary.
% # *Trigger Signal Characteristics (approx. 100ms pulse width):* Visual inspection 
% of the trigger channel reveals a pulse width of exactly 100 ms, which is excessively 
% long for standard DAQ synchronization. Furthermore, while the rising edge is 
% sharp, the falling edge exhibits a slow capacitive discharge curve (RC decay) 
% rather than a clean digital transition to ground. This indicates an unterminated 
% or floating signal line, further highlighting the unrefined state of the electrical 
% synchronization hardware.
% # *Ignition Artifacts (Cross-talk):* Section 2.2 revealed that the ignition 
% mechanism firing physically or electrically affects the pressure sensor signals. 
% This cross-talk overlaps with the actual physical pressure wave, meaning peak 
% over pressure (pMax) and impulse calculations would be artificially inflated 
% by electrical noise.
% # *Severe Electromagnetic Interference (EMI):* As proven in Section 2.3, the 
% system is contaminated by strong 50 Hz mains interference. 
% *3.2 Hardware Review Recommendations*
% To obtain valid pressure readings, impulse metrics, and signal energy calculations, 
% the following physical system reviews are required before further software processing:
%% 
% * *Grounding and Shielding:* Implement proper isolation for the pressure sensors 
% and DAQ channels to reject the 50 Hz mains EMI.
% * *Ignition Isolation:* Optically or galvanically isolate the ignition trigger 
% circuit from the DAQ to prevent high-voltage firing artifacts from bleeding 
% into the sensitive pressure channels.
% * *DAQ Synchronization:* Review the hardware trigger routing between devices 
% to ensure a strict, simultaneous t=0 across all streams.
% * *Synchronization Protocol Suggestion:* Synchronize the DAQ systems based 
% on the low-voltage Trigger Command rather than the Ignition Event. If precise 
% spark timing is required later, we can integrate a photodiode to optically detect 
% the initial spark or flame kernel.
% *3.3 Postponed Time-Domain Metrics*
% Due to the integrity issues documented above, the following calculations are 
% suspended pending hardware corrections:
%% 
% * DC-Offset estimation and subtraction.
% * Peak Overpressure (pMax) and Minimum Pressure (pMin) timing.
% * Signal Energy and Cumulative Impulse computations.
%% 4. **Data Processing & Analysis (***DPA*)
% 4.1 Selected Test to Filter
% *Objective:* Define the specific test, pressure channel, and analysis time 
% window used for (i) EWT-based spectral segmentation and (ii) low-pass filter 
% sensitivity analysis.
% 
% *Workflow:*
%% 
% # choose test index representative of experiment behavior
% # choose target pressure channel for filter tuning
% # define analysis time window covering relevant signal dynamics
%% 
% *Rationale:*
% 
% The ignition trigger provides a reproducible time reference (t_trigger). However, 
% the "end of relevance" is not determined by the trigger and may be affected 
% by DAQ chain dynamics (e.g., time constant tau).
% 
% *Therefore, the end time is set explicitly (engineering judgment) as a fixed 
% offset after t_trigger.*
% 4.1.1 User selections: Selected Data Test & Window Definition
% 2.3.1 Selected Data

TestIdx = 6;                    % Test used for filter design
DaqIdx  = 1;                    % Standardized DAQ stream
ChIdx = 1;                      % Pressure channel (kPa conversion enabled)
triggerChIdx = 4;               % Trigger channel (volts)
triggerWindow = [0.0, 1.0];     % Search interval for ignition trigger [s]

preTime = 0.000;                 % Window start offset relative to t_trigger [s]
postTime_user = 0.30;           % MANUAL: window end offset relative to t_trigger [s]

plotPad = 0.05;                 % Plotting context padding [s]

% Extract the standardized daqData object
daqData = tests(TestIdx).daqs(DaqIdx).data;
% 4.1.2 Extract trigger signal (volts) and precondition

[t_trig, y_trig, Fs_trig] = AuxFcn_GetWindowedSignal_001( ...
    daqData, triggerChIdx, triggerWindow, false);

% Mild smoothing to suppress high-frequency noise without materially smearing timing
y_trig_s = movmean(y_trig, max(5, round(0.0005 * Fs_trig)));  % ~0.5 ms
% 4.1.3 Detect ignition trigger time (robust threshold + persistence)

% Use a robust mid-level threshold based on percentiles (avoids assumptions about absolute voltage levels)
v10 = prctile(y_trig_s, 10);
v90 = prctile(y_trig_s, 90);
thrTrig = 0.5*(v10 + v90);

nPersist = max(10, round(0.001*Fs_trig));  % require persistence for 1 ms
idxCross = find(y_trig_s > thrTrig, 1, 'first');
assert(~isempty(idxCross), 'No trigger crossing found. Check triggerChIdx or triggerWindow.');

idxTrig = [];
for k = idxCross:(length(y_trig_s)-nPersist)
    if all(y_trig_s(k:(k+nPersist-1)) > thrTrig)
        idxTrig = k;
        break;
    end
end
assert(~isempty(idxTrig), 'Trigger did not satisfy persistence condition.');

t_trigger = t_trig(idxTrig);

% 4.1.4 Define analysis window (LB from trigger; UB manual)

LB_window = max(0, t_trigger - preTime);
UB_window = t_trigger + postTime_user;

Window = [LB_window, UB_window];
assert(Window(1) < Window(2), 'Window must satisfy [tStart < tEnd].');

fprintf('Selected analysis window: LB = %.6f s, UB = %.6f s (duration = %.4f s)\n', ...
    LB_window, UB_window, UB_window - LB_window);
% 4.1.5 Extract pressure signal within analysis window (convert to kPa = true)

[t_windowed, y_windowed, Fs] = AuxFcn_GetWindowedSignal_001( ...
    daqData, ChIdx, Window, true);
% 4.1.6 Diagnostic plot (trigger + pressure with selected window)

plotWindow = [max(0, LB_window - plotPad), UB_window + plotPad];
[t_pPlot, pPlot, ~] = AuxFcn_GetWindowedSignal_001( ...
    daqData, ChIdx, plotWindow, true);

figure;
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% Trigger
nexttile;
plot(t_trig, y_trig_s, 'LineWidth', 1, 'Color',Red_Dark); hold on;
xline(t_trigger, '--', 'LineWidth', 1);
grid on; box on;
xlabel('Time [s]','Interpreter','latex');
ylabel('Trigger [V]','Interpreter','latex');
title(sprintf('Trigger detection (Test %d, Ch %d): ) $t_{trigger}=$%.4f s', ...
    TestIdx, triggerChIdx, t_trigger), 'Interpreter','latex');
hold off;

% Pressure + window
nexttile;
plot(t_pPlot, pPlot, 'LineWidth', 0.5, 'Color',LUBlue); hold on;
yl = ylim;

patch([LB_window UB_window UB_window LB_window], ...
    [yl(1) yl(1) yl(2) yl(2)], ...
    LUCopper_Light, 'EdgeColor','none', 'FaceAlpha',0.25);

xline(LB_window, '-', 'LB', 'LineWidth', 1);
xline(UB_window, '-', 'UB', 'LineWidth', 1);

grid on; box on;
xlabel('Time [s]','Interpreter','latex');
ylabel('Pressure [kPa]','Interpreter','latex');
title(sprintf('Selected analysis window (Ch %d): [%.4f, %.4f] s', ...
    ChIdx, LB_window, UB_window), 'Interpreter','latex');
hold off;
% 4.2 EWT-Guided Cutoff Frequency Identification
% 4.2.1 Signal Decomposition by MRA using Empirical Wavelet Transform (EWT)
% *Objective:* Obtain a data-adaptive multiresolution analysis (MRA) of the 
% selected pressure signal (y_windowed) and extract the EWT filter-bank passbands 
% [Li, Ui]. These passbands define a data-driven spectral partition used later 
% to build candidate low-pass filter specifications.
% 
% *Workflow:*
%% 
% # run EWT on selected windowed signal
% # run EWT with MaxNumPeaks
% # convert normalized peak/passband frequencies to Hz
% # Verify signal reconstruction and coefficient energy preservation as per 
% MATLAB documentation.
% # summarize modes in table and plot original + IMFs
%% 
% *Notes:*
%% 
% * *Terminology:* Multiresolution analysis *(MRA),* Empirical Wavelet Transform 
% *(EWT).*
% * See "Note on EWT Data Processing: Signal vs. Coefficients vs. MRA."

assert(exist('ewt', 'file') == 2, ...
    'EWT function not available. Requires Wavelet Toolbox with ewt().');
MaxNumPeaks = 10;  % Maximum number of peaks retained in EWT segmentation (MATLAB ewt option)
% Ensure column vectors for consistent behavior
y_ewt = y_windowed(:);
% Run EWT
[mra, cfs, wfb, info] = ewt(y_ewt, 'MaxNumPeaks', MaxNumPeaks);
% Convert normalized peak frequencies and passbands to Hz
PeakFrequencies_Hz = Fs * info.PeakFrequencies(:);
Passbands_Hz = Fs * info.FilterBank.Passbands;   % rows correspond to MRA components
Passbands_Hz = sort(Passbands_Hz, 2);            % enforce [Li Ui] per row
Li = Passbands_Hz(:,1);
Ui = Passbands_Hz(:,2);
% 4.2.2 Signal Reconstruction and Energy Preservation Verification (MRA components sum to original signal) (sanity / traceability)
% *Reconstruction Error Check*

% Ensure column vector orientation for subtraction
recon = sum(mra, 2);
SignalReconAbsError = abs(y_ewt(:) - recon(:));
SignalReconCheck = max(abs(y_ewt(:) - recon(:)));

figure;
plot(t_windowed,SignalReconAbsError , 'Color',Red_Dark, 'LineWidth', 0.75);
title('EWT Reconstruction Error Over Time', 'Interpreter', 'latex','FontSize',12);
xlabel('Time [s]', 'Interpreter', 'latex','FontSize',12);
ylabel('Absolute Error |y - recon| [kPa]', 'Interpreter', 'latex','FontSize',12);
grid on; axis tight;
%% 
% *Coefficient Energy Preservation Check*

signalEnergy = norm(y_ewt, 2)^2;
cfsEnergy = sum(sum(abs(cfs).^2));
EnergyPreservRelDiffCheck = abs(cfsEnergy - signalEnergy) / signalEnergy * 100;
fprintf('\n--- EWT Mathematical Verification ---\n Reconstruction Error: %.3e (Ideal: < 1e-10)\n', SignalReconCheck);
fprintf('Energy Preservation:  %.3e %% difference\n', EnergyPreservRelDiffCheck);
%% 
% *Active Script Protection*

% 1. STRICT: MRA components must perfectly reconstruct the time-domain signal
assert(SignalReconCheck < 1e-9, 'CRITICAL WARNING: EWT MRA Reconstruction error is abnormally high.');
% 2. RELAXED: Coefficient energy preservation can drift slightly if transition bands overlap
% Set to 0.1% to allow for shorter time windows / lower frequency resolution
assert(EnergyPreservRelDiffCheck < 1e-1, 'WARNING: EWT coefficient energy preservation drifted > 0.1%%.');
% 4.2.3 Per-component metadata table (passbands + peaks-in-band + energy share)

numMRAComponents = size(mra,2);

% Energy fraction per component (useful for interpretation and later reporting)
modeEnergy = sum(abs(mra).^2, 1).';     % per component
modeEnergyPct = 100 * modeEnergy / sum(modeEnergy);

% Associate detected segmentation peaks to passbands (a band may contain multiple peaks)
peaksInBand = cell(numMRAComponents,1);
nPeaksInBand = zeros(numMRAComponents,1);

for j = 1:numMRAComponents
    inBand = (PeakFrequencies_Hz >= Li(j)) & (PeakFrequencies_Hz < Ui(j));
    peaksInBand{j} = PeakFrequencies_Hz(inBand);
    nPeaksInBand(j) = sum(inBand);
end

EWT_SummaryTable = table( ...
    (1:numMRAComponents).', Li, Ui, modeEnergyPct, nPeaksInBand, peaksInBand, ...
    'VariableNames', {'EWT_MRA_Component','PassbandLow_Hz','PassbandHigh_Hz', ...
    'ModeEnergy_%','NumPeaksInBand','PeaksInBand_Hz'} );

disp(EWT_SummaryTable);
% *4.2.4 Mechanical Design Recommendations: High-Energy Modal Coupling*
% *Observation from EWT Analysis*
% 
% While the presence of high-frequency structural ringing is unavoidable in 
% a vented deflagration testing, *the energy distribution revealed by the EWT 
% is highly anomalous.* The bulk deflagration pressure rise (Component 10, 0–270 
% Hz) accounts for only *25.6%* of the recorded signal energy. Conversely, narrow 
% high-frequency bands—specifically Components 6 and 7 (1.17 kHz to 1.21 kHz)—carry 
% a combined *~39.2%* of the signal energy.
% 
% *The Engineering Challenge*
% 
% The issue is not the existence of these high frequencies, but the disproportionate 
% level of energy they are transferring into the piezoelectric crystal. When structural 
% resonances dominate the signal energy, the sensor is excessively coupled to 
% the mechanical excitation of the chamber rather than the static gas pressure. 
% To reduce the amplitude and energy transfer of these high-frequency artifacts, 
% the following mechanical design review is recommended:
%% 
% * *Sensor Mounting Compliance (The "Tuning Fork" Effect):* A protruding or 
% thin-walled mounting boss acts as a mechanical amplifier when struck by the 
% blast wave. The sensor mount literally rings like a tuning fork, violently oscillating 
% the piezoelectric element at its natural frequency.
% * *Recommendation:* Increase the physical stiffness of the sensor port (e.g., 
% make it shorter, thicker, or heavily gusseted) to shift its natural frequency 
% significantly higher. Higher frequencies in the shockwave inherently contain 
% less excitation energy, which will drastically reduce the amplitude of the resulting 
% vibration and decouple it from the pressure measurement.
% 4.2.4 Plot: original signal + first N MRA components

% --- User control for y-label orientation ---
yLabelRotationDeg = 0;   % 0 recommended (as in your example)

% --- Use MATLAB order directly (no reordering) ---
mra_plot = mra;
Li_plot  = Li;
Ui_plot  = Ui;

numMRAComponents = size(mra_plot,2);
nPlotModes = min(numMRAComponents, MaxNumPeaks);

% Representative peak per component
if ~exist('repPeakHz','var')
    repPeakHz = nan(numMRAComponents,1);
    if exist('PeakFrequencies_Hz','var')
        for j = 1:numMRAComponents
            inBand = (PeakFrequencies_Hz >= Li_plot(j)) & (PeakFrequencies_Hz < Ui_plot(j));
            if any(inBand)
                repPeakHz(j) = PeakFrequencies_Hz(find(inBand,1,'first'));
            end
        end
    end
end

figure
x0=10; y0=10;
width=300;
height=20*(nPlotModes+1);
set(gcf,'units','centimeters','position',[x0,y0,width,height])

% --- Plot original signal at bottom (with background color) ---
signalAx = subplot(nPlotModes+1,1,nPlotModes+1);
plot(t_windowed, y_ewt, 'Color', LUBlue, 'LineWidth', 1);

ytickformat('%.3f')
ax = gca;
ax.YAxis.Exponent = 0;

ylimMax = max(y_ewt);
ylimMin = min(y_ewt);
ylim([ylimMin + ylimMin*0.2, ylimMax + ylimMax*0.2])

signalAx.Color = LUCopper_Light;

ylabel('Pressure [kPa]','Interpreter','latex');
signalAx.YLabel.Rotation = yLabelRotationDeg;
signalAx.YLabel.HorizontalAlignment = 'right';
signalAx.YLabel.VerticalAlignment = 'middle';

title(sprintf('Original Signal (Test %d, Ch %d) | Window [%.6f, %.6f] s', ...
    TestIdx, ChIdx, Window(1), Window(2)), 'Interpreter','latex');

xlabel('Time [s]','Interpreter','latex');
axis tight
box on
grid off

% --- Plot MRA components first (top) ---
for k = 1:nPlotModes
    modesAx = subplot(nPlotModes+1,1,k);
    plot(t_windowed, mra_plot(:,k), 'Color', LUBlue, 'LineWidth', 1);

    ytickformat('%.2f')
    ax = gca;
    ax.YAxis.Exponent = 0;

    ylimMax = max(mra_plot(:,k));
    ylimMin = min(mra_plot(:,k));
    ylim([ylimMin + ylimMin*0.2, ylimMax + ylimMax*0.2])

    ylabel(sprintf('MRA-%d [kPa]', k), 'Interpreter','latex');
    modesAx.YLabel.Rotation = yLabelRotationDeg;
    modesAx.YLabel.HorizontalAlignment = 'right';
    modesAx.YLabel.VerticalAlignment = 'middle';

    if ~isnan(repPeakHz(k))
        peakText = num2str(repPeakHz(k), '%.1f');
    else
        peakText = 'NaN';
    end

    % --- UPDATED TITLE: Now includes the energy percentage ---
    title(sprintf('MRA-%d (%.1f\\%% Energy) Pk-%s [Hz] - (%.0f - %.0f) [Hz]', ...
        k, modeEnergyPct(k), peakText, Li_plot(k), Ui_plot(k)), 'Interpreter','latex');

    axis tight
    box on
    grid off

    % Suppress x tick labels for all MRA subplots (leave only bottom axis)
    set(gca,'xticklabel',[])
end

sgtitle({ ...
    '\textbf{Empirical Wavelet Transform (EWT)}', ...
    sprintf('MRA decomposition | MaxNumPeaks = %d', MaxNumPeaks) ...
    }, 'Interpreter','latex');
% 4.2.5 Diagnostic Overlay: Raw Signal vs. EWT Baseline
% *Objective:* Visually demonstrate the severity of the mechanical coupling.
% 
% *Note:* This reconstruction is for visual diagnostic proof only. Quantitative 
% Pmax and dP/dt cannot be reliably extracted.

% Isolate the lowest frequency component (the bulk pressure curve)
% From the EWT table, this is the final component (e.g., Component 10)
baselineComponentIdx = 10;
y_baseline = mra_plot(:,baselineComponentIdx);

% Create the diagnostic figure
figure;
set(gcf, 'Color', 'w');
hold on; grid on;
% Plot the raw compromised signal (Light red/pink to sit in the background)
plot(t_windowed, y_windowed, 'Color', LUCopper_Light, 'LineWidth', 1.0, 'DisplayName', 'Raw Compromised Signal (Ringing)');

% Plot the extracted EWT baseline (Bold dark blue)
plot(t_windowed, y_baseline, 'Color', LUBlue, 'LineWidth', 2.5, ...
    'DisplayName', sprintf('EWT Baseline (Component %d: 0 - 270 Hz)', baselineComponentIdx));

% Formatting
xlabel('Time [s]', 'Interpreter', 'latex');
ylabel('Pressure [kPa]', 'Interpreter', 'latex');
title('Diagnostic Overlay: Structural Ringing vs. Extracted Deflagration Baseline', 'Interpreter', 'latex',FontSize=14);
legend('Location', 'northeast', 'Interpreter', 'latex');
axis tight;
ylim([min(y_windowed)-0.2*min(y_windowed), max(y_windowed)+ 0.2*max(y_windowed)]);
xlim([min(t_windowed), max(t_windowed)]);

% Add a diagnostic disclaimer textbox directly onto the plot
% Places the box in the lower right, below the legend
dim = [0.45 0.20 0.10 0.10];
str = {'\bf{DIAGNOSTIC VISUALIZATION ONLY}', ...
       'Mechanical coupling accounts for >60% of signal energy.', ...
       'Baseline is mathematically extracted but cannot be', ...
       'used for formal safety metrics (e.g., P_{max} or dP/dt).', ...
       'Hardware redesign is required before quantitative analysis.'};
annotation('textbox', dim, 'String', str, 'FitBoxToText', 'on', ...
           'BackgroundColor', [1 0.9 0.9], 'EdgeColor', 'r', 'Interpreter', 'tex',FontSize=8);
% 4.2.2 Candidate Cutoff Frequency Selection
% *Rationale:* The EWT segmentation provides local band limits [Li, Ui] for 
% each extracted component. To avoid placing a physically relevant spectral component 
% at the Butterworth half-power point (−3 dB), we define candidate passband edges 
% fp,i above the upper EWT boundary Ui using a bandwidth-proportional margin. 
% The stopband edge fs,i is then placed one additional local band width above 
% fp,i.
% 
% *Definitions:*
%% 
% * Local EWT band width:    Bi = Ui - Li
% * Passband edge (cutoff):  fp,i = Ui + gamma * Bi
% * Stopband edge:           fs,i = fp,i + kWidth * Bi
%% 
% *Robustness constraints:* Impose a minimum transition width (absolute + relative) 
% and enforce fs < Nyquist to prevent ill-conditioned designs (Ws ≈ Wp) and numerical 
% pathologies.
% User-defined parameters (explicit)

gamma           = 1.0;   % bandwidth-proportional margin above Ui [-]
kWidth          = 3.0;   % additional band width from fp to fs [-]
minDeltaAbsHz   = 10;    % absolute lower bound for (fs - fp) [Hz]
minDeltaRelFrac = 0.05;  % relative lower bound for (fs - fp) as fraction of fp [-]
minCutHz        = 1;     % discard candidates below this fp (set 20 if desired) [Hz]

nyq = Fs/2;

% Local EWT bandwidth
Bi = Ui - Li;

% Candidate passband edge (Hz)
cutoff_frequencies = Ui + gamma.*Bi;                  % fp

% Candidate stopband edge (Hz)
stop_frequencies   = cutoff_frequencies + kWidth.*Bi; % fs (initial)

% Minimum transition width (absolute + relative)
deltaMin = max(minDeltaAbsHz, minDeltaRelFrac.*cutoff_frequencies);
stop_frequencies = max(stop_frequencies, cutoff_frequencies + deltaMin);

% Nyquist constraint
stop_frequencies = min(stop_frequencies, nyq - 1);

% Practical validity filtering
valid = isfinite(cutoff_frequencies) & isfinite(stop_frequencies) & ...
        cutoff_frequencies >= minCutHz & ...
        cutoff_frequencies < 0.98*nyq & ...
        stop_frequencies > cutoff_frequencies;

cutoff_frequencies = cutoff_frequencies(valid);
stop_frequencies   = stop_frequencies(valid);

assert(~isempty(cutoff_frequencies), ...
    'No valid EWT-derived cutoff/stopband pairs after range filtering.');

% Diagnostic output (recommended during development)
deltaHz = stop_frequencies - cutoff_frequencies;
disp(table(cutoff_frequencies, stop_frequencies, deltaHz, ...
    'VariableNames', {'fp_Hz','fs_Hz','Delta_Hz'}));
% Diagnostic: effect of increasing stop frequency on theoretical order (buttord)

Rp = 3;
Rs = 40;
nyq = Fs/2;

scaleFactors = [1, 1.25, 1.5, 2, 3, 5];  % how much to widen (fs-fp)
nMax = nan(numel(scaleFactors),1);
nP90 = nan(numel(scaleFactors),1);
nMed = nan(numel(scaleFactors),1);

for s = 1:numel(scaleFactors)
    sf = scaleFactors(s);

    % Widen the transition band: fs_new = fp + sf*(fs - fp)
    stop_frequencies_test = cutoff_frequencies + sf.*(stop_frequencies - cutoff_frequencies);

    % Keep below Nyquist
    stop_frequencies_test = min(stop_frequencies_test, nyq - 1);

    % Compute n for each candidate
    n_test = zeros(size(cutoff_frequencies));
    for i = 1:numel(cutoff_frequencies)
        fc = cutoff_frequencies(i);
        fs_stop = stop_frequencies_test(i);

        Wp = fc/(Fs/2);
        Ws = fs_stop/(Fs/2);

        n_test(i) = buttord(Wp, Ws, Rp, Rs);
    end

    nMax(s) = max(n_test);
    nP90(s) = prctile(n_test, 90);
    nMed(s) = median(n_test);
end

stopSweepTable = table(scaleFactors(:), nMed, nP90, nMax, ...
    'VariableNames', {'ScaleFactor','n_median','n_p90','n_max'});
disp(stopSweepTable);
% 4.3 Low-Pass Filter Sensitivity Analysis
% 4.3.1 Filter-Order and Cutoff Sweep
% *Objective:* Quantify sensitivity of integral and peak metrics (signal energy, 
% impulse, peak pressure) to the low-pass specification across EWT-derived candidates 
% and a range of filter orders.
% 
% *Workflow:*
%% 
% # preliminary filter design. compute minimum Butterworth order for each candidate 
% cutoff
% # evaluate a range of filter orders
% # compute metric ratios vs unfiltered signal
% # select final cutoff using robustness criteria
%% 
% *Filter Order Design Parameters*

%% 3.3 Low-Pass Filter Sensitivity Analysis
% 3.3.1 Filter-Order and Cutoff Sweep
% Objective:
%   Quantify sensitivity of integral and peak metrics (signal energy, impulse,
%   peak pressure) to the low-pass specification across EWT-derived candidates
%   and a range of filter orders.
%
% Workflow:
%   1) Compute the theoretical minimum Butterworth order n(i) for each candidate
%      (fp, fs) using buttord() as a diagnostic indicator of specification tightness.
%   2) Perform a robustness sweep over a practical set of filter orders (fixed a priori)
%      to avoid pathological high-order designs driven by outlier candidates.
%   3) Compute metric ratios relative to the unfiltered signal.
%   4) Select the final cutoff using the robustness criterion (handled after filtering).

%% Filter Order Design Parameters (diagnostic only)
n = zeros(size(cutoff_frequencies,1),1);
for i = 1:length(cutoff_frequencies)
    fc = cutoff_frequencies(i);        % candidate passband edge fp (Hz)
    fs_stop = stop_frequencies(i);     % candidate stopband edge fs (Hz)

    Rp = 3;                            % passband attenuation at Wp (dB)
    Rs = 40;                           % stopband attenuation at Ws (dB)

    Wp = fc / (Fs/2);
    Ws = fs_stop / (Fs/2);

    n(i) = buttord(Wp, Ws, Rp, Rs);
end
% Identify and print the worst offenders
[nsort, idxSort] = sort(n, 'descend');
nTop = min(5, numel(n));

fprintf('\nTop %d worst buttord candidates:\n', nTop);
for kk = 1:nTop
    i = idxSort(kk);
    fc = cutoff_frequencies(i);
    fs_stop = stop_frequencies(i);
    Wp = fc/(Fs/2);
    Ws = fs_stop/(Fs/2);
    fprintf('#%d: i=%d | fp=%.6f Hz | fs=%.6f Hz | (fs-fp)=%.6f Hz | DeltaW=%.3e | n=%d\n', ...
        kk, i, fc, fs_stop, fs_stop-fc, Ws-Wp, n(i));
end

%% Diagnostic summary table (recommended for traceability)
Wp_vec = cutoff_frequencies / (Fs/2);
Ws_vec = stop_frequencies   / (Fs/2);
deltaW = Ws_vec - Wp_vec;

[~, idxWorst] = max(n);

buttordSummaryTable_3p3 = table( ...
    (1:numel(cutoff_frequencies)).', ...
    cutoff_frequencies(:), stop_frequencies(:), ...
    Wp_vec(:), Ws_vec(:), deltaW(:), ...
    n(:), ...
    'VariableNames', {'CandidateIdx','fp_Hz','fs_Hz','Wp','Ws','DeltaW','n_buttord'} );

disp(buttordSummaryTable_3p3);

fprintf('Worst candidate (max n): idx=%d, fp=%.3f Hz, fs=%.3f Hz, DeltaW=%.3e, n=%d\n', ...
    idxWorst, cutoff_frequencies(idxWorst), stop_frequencies(idxWorst), deltaW(idxWorst), n(idxWorst));

%% Practical order sweep for robustness study (do NOT anchor to max(n))
% Rationale:
%   Theoretical orders from buttord() can become excessively large when any single
%   candidate has a very narrow transition band. Such orders are not appropriate
%   for stable IIR filtering at high sampling rate and would dominate the analysis.
%   A fixed sweep provides an interpretable robustness check and prevents outliers
%   from dictating filter complexity.

filter_orders = [2, 4, 6, 8];

%% 
% *Performance Metrics*

energy_ratio_matrix = zeros(length(filter_orders), length(cutoff_frequencies));
impulse_ratio_matrix = zeros(length(filter_orders), length(cutoff_frequencies));
peak_pressure_ratio_matrix = zeros(length(filter_orders), length(cutoff_frequencies));

E_base = sum(abs(y_windowed).^2);
Impulse_base = trapz(t_windowed, y_windowed);
PeakPressure_base = max(y_windowed);

%% Filtering + Metrics (correctly enforces Wp/Ws/Rp/Rs; uses SOS for stability)
for f_idx = 1:length(filter_orders)
    filter_order = filter_orders(f_idx);

    for c_idx = 1:length(cutoff_frequencies)
        fc = cutoff_frequencies(c_idx);
        fs_stop = stop_frequencies(c_idx);

        Rp = 3;
        Rs = 40;

        Wp = fc / (Fs/2);
        Ws = fs_stop / (Fs/2);

        % --- Determine a Butterworth cutoff (Wn_current) that satisfies both constraints ---
        % Butterworth magnitude model:
        %   |H(jw)|^2 = 1/(1 + (w/Wn)^(2n))
        % Passband constraint at Wp:  Ap=Rp => (Wp/Wn)^(2n) <= (10^(Rp/10)-1)
        % Stopband constraint at Ws:  As=Rs => (Ws/Wn)^(2n) >= (10^(Rs/10)-1)
        %
        % This yields a feasible interval for Wn:
        %   Wn >= Wp / (10^(Rp/10)-1)^(1/(2n))    (passband lower bound)
        %   Wn <= Ws / (10^(Rs/10)-1)^(1/(2n))    (stopband upper bound)
        %
        % We choose the largest feasible Wn (most conservative wrt preserving passband content),
        % i.e. Wn_current = Wn_stop, provided feasibility holds.

        Ap = 10^(Rp/10) - 1;
        As = 10^(Rs/10) - 1;

        Wn_pass = Wp / (Ap)^(1/(2*filter_order));   % minimum Wn to satisfy passband
        Wn_stop = Ws / (As)^(1/(2*filter_order));   % maximum Wn to satisfy stopband

        % Feasibility check (should hold for filter_order >= nMin)
        if Wn_pass > Wn_stop
            % If this triggers, the selected order cannot satisfy both specs for this candidate.
            % Keep the design conservative w.r.t. passband (use Wn_pass), but note that Rs will not be met.
            Wn_current = Wn_pass;
        else
            % Largest feasible cutoff -> least distortion in the retained band
            Wn_current = Wn_stop;
        end

        % Numerical safety: clamp to valid digital range
        Wn_current = min(max(Wn_current, eps), 0.999999);

        % --- Design + apply in SOS form ---
        [z,p,k] = butter(filter_order, Wn_current, 'low');
        [sos,g] = zp2sos(z,p,k);

        % Apply zero-phase filtering (compatibility across MATLAB versions/toolboxes)
        try
            % Some MATLAB versions support SOS directly via filtfilt
            p_filtered = filtfilt(sos, g, y_windowed);
        catch
            % Fallback: convert ZPK -> (b,a) and use standard filtfilt
            [b,a] = zp2tf(z,p,k);
            p_filtered = filtfilt(b, a, y_windowed);
        end

        % --- Metrics ---
        E_filtered = sum(abs(p_filtered).^2);
        Impulse_filtered = trapz(t_windowed, p_filtered);
        PeakPressure_filtered = max(p_filtered);

        energy_ratio_matrix(f_idx, c_idx) = (E_filtered / E_base) * 100;
        impulse_ratio_matrix(f_idx, c_idx) = (Impulse_filtered / Impulse_base) * 100;
        peak_pressure_ratio_matrix(f_idx, c_idx) = (PeakPressure_filtered / PeakPressure_base) * 100;
    end
end
%% 
% *Performance Metrics*

energy_ratio_matrix = zeros(length(filter_orders), length(cutoff_frequencies));
impulse_ratio_matrix = zeros(length(filter_orders), length(cutoff_frequencies));
peak_pressure_ratio_matrix = zeros(length(filter_orders), length(cutoff_frequencies));

E_base = sum(abs(y_windowed).^2);
Impulse_base = trapz(t_windowed, y_windowed);
PeakPressure_base = max(y_windowed);

for f_idx = 1:length(filter_orders)
    for c_idx = 1:length(cutoff_frequencies)
        fc = cutoff_frequencies(c_idx);
        filter_order = filter_orders(f_idx);
        lpFilt = designfilt('lowpassiir', ...
            'FilterOrder', filter_order, ...
            'HalfPowerFrequency', fc, ...
            'DesignMethod','butter', ...
            'SampleRate', Fs);

        p_filtered = filtfilt(lpFilt, y_windowed);
        E_filtered = sum(abs(p_filtered).^2);
        Impulse_filtered = trapz(t_windowed, p_filtered);
        PeakPressure_filtered = max(p_filtered);

        energy_ratio_matrix(f_idx, c_idx) = (E_filtered / E_base) * 100;
        impulse_ratio_matrix(f_idx, c_idx) = (Impulse_filtered / Impulse_base) * 100;
        peak_pressure_ratio_matrix(f_idx, c_idx) = (PeakPressure_filtered / PeakPressure_base) * 100;
    end
end
%% 
% *Final cutoff selection rule*
% 
% smallest cutoff where all tested orders preserve >=98% impulse and peak.

% Final cutoff selection rule:
% smallest cutoff where all tested orders preserve >=98% impulse and peak.
meetsCriterion = all(impulse_ratio_matrix >= 98, 1) & all(peak_pressure_ratio_matrix >= 98, 1);
if any(meetsCriterion)
    lfCut = cutoff_frequencies(find(meetsCriterion, 1, 'first'));
else
    [~, idxBest] = max(mean(impulse_ratio_matrix + peak_pressure_ratio_matrix, 1));
    lfCut = cutoff_frequencies(idxBest);
end
% 4.3.2 Summary Table (recommended for traceability)

deltaHz = stop_frequencies - cutoff_frequencies;
% Worst-case (most conservative) preservation across tested orders
min_energy_ratio = min(energy_ratio_matrix, [], 1).';
min_impulse_ratio = min(impulse_ratio_matrix, [], 1).';
min_peak_pressure_ratio = min(peak_pressure_ratio_matrix, [], 1).';

% Optional: average preservation across tested orders (less conservative)
mean_energy_ratio = mean(energy_ratio_matrix, 1).';
mean_impulse_ratio = mean(impulse_ratio_matrix, 1).';
mean_peak_pressure_ratio = mean(peak_pressure_ratio_matrix, 1).';

% Pass/fail per your rule (should match meetsCriterion)
meetsCriterion_col = meetsCriterion(:);

% Mark the selected cutoff
isSelected = cutoff_frequencies == lfCut;

summaryTable_3p3 = table( ...
    cutoff_frequencies(:), stop_frequencies(:), deltaHz(:), ...
    min_impulse_ratio, min_peak_pressure_ratio, min_energy_ratio, ...
    mean_impulse_ratio, mean_peak_pressure_ratio, mean_energy_ratio, ...
    meetsCriterion_col, isSelected(:), ...
    'VariableNames', { ...
        'fp_Hz','fs_Hz','Delta_Hz', ...
        'MinImpulse_%','MinPeak_%','MinEnergy_%', ...
        'MeanImpulse_%','MeanPeak_%','MeanEnergy_%', ...
        'MeetsCriterion','Selected' ...
    } );

disp(summaryTable_3p3);

% Optional: save for reporting/reproducibility
% writetable(summaryTable_3p3, sprintf('SummaryTable_3p3_Test%d.csv', TestIdx));


%% 
% Diagnostic: effect of increasing stop frequency on theoretical order (buttord)

Rp = 3;
Rs = 40;
nyq = Fs/2;

scaleFactors = [1, 1.25, 1.5, 2, 3, 5];  % how much to widen (fs-fp)
nMax = nan(numel(scaleFactors),1);
nP90 = nan(numel(scaleFactors),1);
nMed = nan(numel(scaleFactors),1);

for s = 1:numel(scaleFactors)
    sf = scaleFactors(s);

    % Widen the transition band: fs_new = fp + sf*(fs - fp)
    stop_frequencies_test = cutoff_frequencies + sf.*(stop_frequencies - cutoff_frequencies);

    % Keep below Nyquist
    stop_frequencies_test = min(stop_frequencies_test, nyq - 1);

    % Compute n for each candidate
    n_test = zeros(size(cutoff_frequencies));
    for i = 1:numel(cutoff_frequencies)
        fc = cutoff_frequencies(i);
        fs_stop = stop_frequencies_test(i);

        Wp = fc/(Fs/2);
        Ws = fs_stop/(Fs/2);

        n_test(i) = buttord(Wp, Ws, Rp, Rs);
    end

    nMax(s) = max(n_test);
    nP90(s) = prctile(n_test, 90);
    nMed(s) = median(n_test);
end

stopSweepTable = table(scaleFactors(:), nMed, nP90, nMax, ...
    'VariableNames', {'ScaleFactor','n_median','n_p90','n_max'});
disp(stopSweepTable);
% 4.3.3 Sensitivity Plots

figure;
tiledlayout(2,4, 'TileSpacing', 'compact', 'Padding', 'compact');

for f_idx = 1:length(filter_orders)
    nexttile(f_idx);
    plot(cutoff_frequencies, impulse_ratio_matrix(f_idx, :), '-s', ...
        'Color',LUBlue,'MarkerFaceColor',LUBlue_Light,'MarkerEdgeColor',LUBlue, 'LineWidth', 1);
    xlabel('Cutoff Frequency [Hz]', 'Interpreter', 'latex');
    xlim([-50 1050]);
    ylabel('Ratio [\%]', 'Interpreter', 'latex');
    ylim([min(min(impulse_ratio_matrix(:, :))) * 0.98, max(max(impulse_ratio_matrix(:, :))) * 1.02]);
    title({'Impulse Ratio',['(Filter Order = ' num2str(filter_orders(f_idx)) ')']},'Interpreter', 'latex');
    legend('Impulse Ratio', 'Location', 'northeast', 'Interpreter', 'latex');
    grid on;

    nexttile(f_idx + 4);
    plot(cutoff_frequencies, energy_ratio_matrix(f_idx, :), '-s', ...
        'Color',LUBlue,'MarkerFaceColor',LUBlue,'MarkerEdgeColor',LUBlue_Light, 'LineWidth', 1); hold on;
    plot(cutoff_frequencies, peak_pressure_ratio_matrix(f_idx, :), '-^', ...
        'Color',LUCopper,'MarkerEdgeColor',LUCopper,'MarkerFaceColor',LUCopper_Light, 'LineWidth', 1);
    hold off;
    xlabel('Cutoff Frequency [Hz]', 'Interpreter', 'latex');
    xlim([-50 1050]);
    ylabel('Ratio [\%]', 'Interpreter', 'latex');
    ylim([min(min([peak_pressure_ratio_matrix(:, :);energy_ratio_matrix(:, :)])) * 0.98, ...
          max(max([peak_pressure_ratio_matrix(:, :);energy_ratio_matrix(:, :)])) * 1.02]);
    title({'Signal Energy \& Peak Pressure Ratio vs. Cutoff',[' (Filter Order = ', num2str(filter_orders(f_idx)), ')']},'Interpreter', 'latex');
    legend('Signal Energy Ratio', 'Peak Pressure Ratio','Location', 'southeast', 'Interpreter', 'latex');
    grid on;
end
sgtitle({'\textbf{Low-Pass Filter Sensitivity Analysis}', ...
    sprintf('Test - %d | Selected cutoff %.1f Hz', TestIdx, lfCut)}, 'fontsize',14, 'Interpreter', 'latex')
hold off;

% 4.4 Final Filter Design and Phase Delay Effect
% 4.4.1 Butterworth Filter at Selected Cutoff
% *Objective:* design final low-pass filter using the selected EWT-guided cutoff 
% and evaluate phase delay compensation in time domain.

fc = lfCut;
fs_stop = fc + 500;
Rp = 3;
Rs = 40;
Wp = fc / (Fs/2);
Ws = fs_stop / (Fs/2);
[filter_order, Wn] = buttord(Wp, Ws, Rp, Rs);

lpFilt = designfilt('lowpassiir', ...
    'FilterOrder', filter_order, ...
    'HalfPowerFrequency', lfCut, ...
    'DesignMethod','butter',...
    'SampleRate', Fs);

dataLowPass = filtfilt(lpFilt, y_windowed);
dataLowPassPhaseDelay = filter(lpFilt,y_windowed);

% 4.4.2 Phase Delay Effect Plot

figure;
scatter(t_windowed, y_windowed, '.', ...
    'MarkerEdgeColor', LUCopper_Light, ...
    'MarkerEdgeAlpha', 1);
hold on;

plot(t_windowed, dataLowPassPhaseDelay, 'LineWidth', 1.5, 'Color', Red_Dark);
plot(t_windowed, dataLowPass, 'LineWidth', 1.5, 'Color', LUBlue);

title({"Compensate for the Delay Introduced by an IIR Filter", ...
       sprintf("Low-Pass Filtered at %.1f Hz", lfCut)}, 'fontsize', 16,'Interpreter','latex');
xlabel('Time [s]','Interpreter','latex');
ylabel('Pressure [kPa]','Interpreter','latex');
legend(sprintf('Test - %d: Original Signal (DC-Offset-Corrected)', TestIdx), ...
       sprintf("Phase Delay Not-Compensated Low-Pass Filtered at %.1f Hz", lfCut),...
       sprintf("Phase Delay Compensated Low-Pass Filtered at %.1f Hz", lfCut),...
       'Location','southeast', 'FontSize', 12,'Interpreter','latex');
box on;

zoom_start = 0.15;
zoom_end = 0.20;
zoom_idx = (t_windowed >= zoom_start) & (t_windowed <= zoom_end);

axes('Position', [0.55, 0.625, 0.35, 0.25]);
hold on;
scatter(t_windowed(zoom_idx), y_windowed(zoom_idx), '.', 'MarkerEdgeColor', LUCopper_Light);
plot(t_windowed(zoom_idx), dataLowPassPhaseDelay(zoom_idx), 'LineWidth', 1.5, 'Color', Red_Dark);
plot(t_windowed(zoom_idx), dataLowPass(zoom_idx), 'LineWidth', 1.5, 'Color', LUBlue);
xlabel('Time [s]','Interpreter','latex');
xlim([0.15 0.20]);
ylabel('Pressure [kPa]','Interpreter','latex');
box on;
hold off;
%% 5. Quantity of Interest (QoI) Extraction of *∆Pmax [kPa] after Filtering*
% 5.1 Define CutOff Frequencies & Minimum Filter Order

cutoff_frequencies = 250:50:1000;
nMin = zeros(size(cutoff_frequencies,1),1);
for i = 1:length(cutoff_frequencies)
    % Given parameters
    fc = cutoff_frequencies(i);   % Passband cutoff frequency (Hz)
    fs_stop = cutoff_frequencies(i) + 500; % Stopband frequency (Hz)
    Rp = 3;      % Maximum ripple in passband (dB)
    Rs = 40;     % Minimum stopband attenuation (dB)

    % Normalize frequencies to Nyquist frequency (Fs/2)
    Wp = fc / (Fs/2);
    Ws = fs_stop / (Fs/2);

    % Compute minimum Butterworth filter order
    nMin(i) = buttord(Wp, Ws, Rp, Rs);
end
filter_orders = nMin;  % Filter orders
% 5.2 Calculation *∆Pmax [kPa] after Filtering*

% Memory Allocation
peakPressureFiltered = zeros(length(cutoff_frequencies), length(testNum));
%% Apply Low-Pass Filtering for Different Cutoff Frequencies & Filter Orders
for t_idx = 1:length(testNum)
    for fc_idx = 1:length(cutoff_frequencies)
        fc = cutoff_frequencies(fc_idx);  % Current cutoff frequency
        filter_order = filter_orders(fc_idx);  % Current filter order
        lpFilt = designfilt('lowpassiir', ...
        'FilterOrder', filter_order, ...
        'HalfPowerFrequency', fc, ...
         'DesignMethod','butter',...
        'SampleRate', Fs);
        % Zero-phase filtering
        pressureFiltered = filtfilt(lpFilt, dataP(:,t_idx));

        % Compute Peak pressure after filtering
        [peakPressureFiltered(fc_idx, t_idx), idx] = max(pressureFiltered, [], 1); % [kPa]
    end
end
DeltaP_max = max(peakPressureFiltered);
% 5.3 Plot *∆Pmax [kPa] after Filtering*

figure;
subplot(2,1,1)
boxplot(peakPressureFiltered, 'Whisker', Inf, 'Widths',.75);
h = findobj(gca,'Tag','Box');
for j=1:length(h)
    patch(get(h(j),'XData'),get(h(j),'YData'),LUBlue_Light,'FaceAlpha',.25);
end

xlabel('Test Number','Interpreter','latex','FontSize',12)
ylabel ('$\Delta P_{Max}$ [kPa]','Interpreter','latex','FontSize',12)
title({'$\Delta P_{Max}$ Dispersion','Due to Different Low-Pass Filter $f_{c}$ Frequencies (250-1000 [Hz])'},'Interpreter','latex','FontSize',12)
box on
subplot(2,1,2)
scatter(dataRMH, DeltaP_max, 's','MarkerFaceColor',LUBlue); % Overlay mean values
hold on
ylabel ('$\Delta P_{Max}$ [kPa]','Interpreter','latex','FontSize',12)
xlabel('Released Mass of Hydrogen [g]','FontSize',12)
xlim([0 16])
ylim([-1 16])
grid on
box on
hold off
%% 6. *Conclusions and Suggestions*
% *Synchronization Hardware*
% 
% The trigger signal exhibits a 100 ms pulse width with a floating RC-discharge 
% edge, and lacks isolation from 50 Hz mains EMI.
% 
% _Suggestion: Upgrade to an optically isolated, active-pulldown 5V TTL trigger 
% with a 1-5 ms pulse width._
% 
% *Sensor Baseline Drift*
% 
% The charge amplifier setup exhibits severe negative voltage drift (time-constant 
% bleed) prior to ignition, rendering the absolute zero-pressure reference unstable.
% 
% _Suggestion: Review the DAQ coupling (AC vs DC) and the Kistler charge amplifier 
% time-constant settings._
% 
% *Apparent Severe Mechanical Resonance*
% 
% EWT analysis mathematically proves that over 60% of the recorded signal energy 
% exists as structural/acoustic ringing in the kilohertz range, rather than physical 
% gas pressure.
% 
% *Data Invalidation*
% 
% As demonstrated by the filter sensitivity sweep, attempting to digitally low-pass 
% filter the ringing introduces unacceptable uncertainty into the P_{max} calculation.
% 
% _Suggestion: Redesign the sensor mounting boss to increase structural stiffness 
% and ensure the sensor is perfectly flush-mounted to eliminate acoustic cavity 
% resonance before further testing._
%% *Note: The Purpose of the Hanning Window*
% *Problem (Spectral Leakage)*
% When a DAQ system records a finite block of data (e.g., a 0.5-second window 
% of a signal), it inherently captures a snapshot of a longer process. The FFT 
% algorithm, however, assumes that this finite block is exactly one period of 
% an infinitely repeating signal. At the boundaries where the block ends and would 
% theoretically repeat, there is almost always a discontinuity between the last 
% sample and the first sample. These abrupt jumps introduce artificial frequency 
% components that smear the true energy from actual frequencies (like a 50 Hz 
% EMI peak) across neighboring bins.
% *Solution*
% We apply a Hanning (Hann) window—a smooth, bell-shaped mathematical taper—to 
% the entire recorded data block before computing the FFT. This gently attenuates 
% the signal amplitude to exactly zero at both the beginning and end of the block.
% *Result*
% With both ends tapered to zero, the discontinuity at the block boundaries 
% is eliminated. When the FFT implicitly repeats the block, the ends connect seamlessly. 
% This reduce spectral leakage, keeping the 50 Hz EMI peak sharp, isolated, and 
% accurately quantified in the frequency domain.
% 
% *Figure placeholder:* Low-pass filtering illustration to be inserted later.
% Summary (source:*Understanding FFTs and Windowing* https://www.ni.com/)
%% 
% * All signals in the time domain can be represented by a series of sines.
% * An *FFT transform* deconstructs a time domain representation of a signal 
% into the frequency domain representation to analyze the different frequencies 
% in a signal.
% * The *frequency domain* is great at showing you if a clean signal in the 
% time domain actually contains cross talk, noise, or jitter.
% * *Spectral leakage* is caused by discontinuities in the original, noninteger 
% number of periods in a signal and can be improved using windowing.
% * *Windowing* reduces the amplitude of the discontinuities at the boundaries 
% of each finite sequence acquired by the digitizer.
% * No window is often called the uniform or rectangular window because there 
% is still a windowing effect.
% * In general, the *Hanning window* is satisfactory in 95 percent of cases. 
% It has good frequency resolution and reduced spectral leakage.
% * You should compare the performance of different window functions to find 
% the best one for the application.
%% 
% *References*
% 
% [1] Veloni, A., Miridakis, N., & Boukouvala, E. (2018). *Digital and Statistical 
% Signal Processing* (1st ed.). CRC Press. <https://doi-org.ludwig.lub.lu.se/10.1201/9780429507526 
% https://doi-org.ludwig.lub.lu.se/10.1201/9780429507526>
% 
% [2] *Chapter 13: "Digital Signal Processing Tricks", Understanding Digital 
% Signal Processing* Third Edition Richard G. Lyons. Prince Hall, 2010
% 
% [3] *Understanding FFTs and Windowing* <https://www.ni.com/en/shop/data-acquisition/measurement-fundamentals/analog-fundamentals/understanding-ffts-and-windowing.html 
% https://www.ni.com/en/shop/data-acquisition/measurement-fundamentals/analog-fundamentals/understanding-ffts-and-windowing.html>
% 
% [4] *Understanding the Hanning Window: A Practical Guide for Beginners* https://wraycastle.com/blogs/knowledge-base/hanning-window
%% Note on EWT Data Processing: Signal vs. Coefficients vs. MRA
% EWT Energy Concepts: Signal, Coefficients (cfs), and MRA Components
% 
% Understanding these three concepts is core to how the Empirical Wavelet Transform 
% (EWT) and digital signal processing work.
% 1. The Energy of the Signal (|signalEnergy|)
% • *The Code:* |norm(y\_ewt, 2)^2|
% 
% • *Concept:* This is your Ground Truth. It is the total mathematical variance 
% (or "power") of your raw pressure wave in the time domain over your selected 
% window.
% 
% • *Math:* It is calculated by taking every single discrete pressure sample 
% |y\[n\]|, squaring it, and adding them all together: |E\_{signal} = \sum\_{n} 
% |y\[n\]|^2|. This represents the total physical event you recorded.
% 2. The Energy of the Coefficients (|cfsEnergy|)
% • *The Code:* |sum(sum(abs(cfs).^2))|
% 
% • *Concept:* When MATLAB runs the |ewt()| function, it translates your time-domain 
% signal into the frequency domain. The coefficients (|cfs|) are the raw, abstract 
% mathematical weights assigned to the wavelet filters.
% 
% • *Analogy:* Think of the coefficients as the blueprint. They are not time-domain 
% pressure waves; they are just abstract multipliers in the wavelet space that 
% tell the algorithm how much of each frequency exists. The "Coefficient Energy" 
% is the total sum of all these squared blueprint weights.
% 3. Why Do We Compare Them?
% *Parseval's Theorem* (see reference [1] and  [2])
% 
% In a perfectly lossless digital transform (a "Tight Parseval Frame"), the 
% total energy in the time domain must perfectly equal the total energy in the 
% frequency domain.
% 
% • *Concept:* Energy of the House (Signal) MUST = Energy of the Blueprint (Coefficients).
% 
% • Calculating |EnergyPreservRelDiffCheck| proves that the EWT algorithm mapped 
% your signal into the frequency domain without losing or creating data. If that 
% number is near zero, the transform was perfectly lossless.
% 4. The Crucial Difference: |cfs| vs. |mra|
% • |*cfs*| *(Coefficients):* Abstract frequency weights. You cannot plot these 
% against time.
% 
% • |*mra*| *(Multi-Resolution Analysis):* These are the coefficients transformed 
% _back_ into the time domain. An MRA component is a physical pressure wave (in 
% kPa) representing just one slice of your frequencies.
% 
% When calculating the mode energy (|modeEnergy = sum(abs(mra).^2, 1).';|), 
% you calculate the energy of the _reconstructed time-domain modes_, not the abstract 
% coefficients. Because the |mra| components are back in the time domain, you 
% can safely state conclusions like, "MRA Component 7 contains 29% of the physical 
% signal energy."
% *5. MRA Reconstruction: Peaks vs. Bands (extracted from Matlab Documentation)*
% According to the official MATLAB documentation, the *Empirical Wavelet Transform 
% (EWT)* creates a *Multiresolution Analysis (MRA)* by adaptively subdividing 
% a signal's spectrum. The distinction between how peaks and bands are used is 
% critical for the physical interpretation of the data:
%% 
% * *The Peak (Setup Phase):* The algorithm identifies the highest peaks in 
% the power spectral estimate to act as landmarks. The documentation states that 
% these are used to construct the boundaries ($L_i, U_i$) of the passbands, typically 
% placing them at the _"geometric mean frequency of the adjacent peaks."_
% * *The Band (Data Reconstruction):* Once the borders are set, the MRA is defined 
% as a _"decomposition of a signal into components on different... frequency bands."_ 
% The algorithm uses the wavelets to _"filter the signal in the frequency domain"_ 
% to obtain the coefficients.
% * *Final Physical Waveform:* Because an MRA component is reconstructed using 
% the entire frequency band (the "passband"), it is a physical time-domain wave 
% containing *every frequency, noise component, and vibration* located within 
% that band. It is not a pure sine wave at the peak frequency; it is the sum of 
% all spectral energy between L_i and U_i.
%% 
% *References*
% 
% [1] Veloni, A., Miridakis, N., & Boukouvala, E. (2018). *Digital and Statistical 
% Signal Processing (1st ed.)*. CRC Press. <https://doi-org.ludwig.lub.lu.se/10.1201/9780429507526 
% https://doi-org.ludwig.lub.lu.se/10.1201/9780429507526>
% 
% [2] *Parseval's Theorem* <https://www.ni.com/docs/en-US/bundle/labwindows-cvi/page/advancedanalysisconcepts/lvac_parseval_s_theorem.html 
% https://www.ni.com/docs/en-US/bundle/labwindows-cvi/page/advancedanalysisconcepts/lvac_parseval_s_theorem.html>
%% Note on Multiresolution analysis *(MRA)* Empirical Wavelet Transform *(EWT).*
% General Considerations
% *1. Deflagration Pressure Signals Have Dominant Low-Frequency Components*
%% 
% * The *overpressure rise* in deflagration events is often *gradual* compared 
% to high-frequency noise.
% * The *dominant physical processes* (combustion expansion, flame acceleration, 
% venting effects) evolve on timescales much longer than *sensor vibrations or 
% electronic noise*.
%% 
% *2. Common Sources of High-Frequency Noise*
%% 
% * *Sensor Vibrations & Structural Resonances:*
% * Pressure transducers, particularly those mounted on rigid test chambers, 
% can pick up *high-frequency mechanical vibrations*.
% * *Electrical Noise:*
% * Data acquisition (DAQ) systems and amplification circuits introduce *high-frequency 
% interference*.
% * *Shock-Induced Transients (if present):*
% * If a strong shock develops, it may introduce *high-frequency components*, 
% but *for deflagrations*, most of the pressure signal energy is *low-frequency*.
%% 
% *3. Why a Low-Pass Filter is Appropriate?*
%% 
% * The primarily interested in:
% * *Peak overpressure* *∆Pmax*
% * *Impulse (integral of pressure over time)*
% * *Time of peak pressure,* not as relevant as ∆Pmax, however, it is still 
% considered a good metric to consider in the evaluation of the Low-Pass FIlter 
% Effect during the Data Processing Procedure.
% * These *key metrics* are *not affected by removing high-frequency noise*.
% * A properly chosen *low-pass cutoff frequency* ensures the removal unwanted 
% noise while *preserving* the physically meaningful pressure rise.
%% 
% *4. Consideration for Cutoff Frequency Selection*
% 
% This is a challenge aspec of th edata processing due to the lack of knlodges 
% about the frequencies a that migh tdominate the phenomena, however, several 
% assumption required to be made.
%% 
% * The *filter cutoff frequency* should be:
% * *Well above* the dominant deflagration pressure rise rate.
% * *Below* the typical noise frequency components.
% * A *frequency-domain analysis* (FFT or EWT) of the raw pressure signal) help 
% to *identify the frequencies present in each test and determine* an *appropriate 
% cutoff frequency.*
%% 
% *Remark*
% 
% *Applying a low-pass filter makes sense* for the deflagration experiments 
% *as long as the cutoff frequency is chosen appropriately*.
% 
% To ensures that it is captured the *pressure response* while removing high-frequency 
% noise that does not represent physical pressure changes.
% Empirical Wavelet Transform (EWT) [3]
% *Extracted from Matlab*
% 
% *Figure placeholder:* Empirical Wavelet Transform illustration to be inserted 
% later.
% 
% The key thing to note is that similar to the wavelet and EMD decompositions, 
% VMD segregates the three components of interest into completely separate modes 
% or into a small number of adjacent modes. All three techniques allow you to 
% visualize signal components on the same time scale as the original signal. There 
% is a data-adaptive technique which actually constructs wavelet filters based 
% on the frequency content of the data. This technique is the _empirical wavelet 
% transform_ (EWT) [3]. One of the major criticisms of EMD is that its definition 
% is purely algorithmic. As a result, it is not readily amenable to mathematical 
% analysis. EWT on the other hand actually constructs Meyer wavelets based on 
% the frequency content of the analyzed signal. Accordingly, the results of EWT 
% are amenable to mathematical analysis because the filters used in the analysis 
% are available to the user. Repeat the analysis of the synthetic signal using 
% the EWT.
% 
% *References*
% 
% [1] Dragomiretskiy, Konstantin, and Dominique Zosso. “Variational Mode Decomposition.” 
% _IEEE Transactions on Signal Processing_ 62, no. 3 (February 2014): 531–44. 
% <https://doi.org/10.1109/TSP.2013.2288675 https://doi.org/10.1109/TSP.2013.2288675>.
% 
% [2] Flandrin, P., G. Rilling, and P. Goncalves. “Empirical Mode Decomposition 
% as a Filter Bank.” _IEEE Signal Processing Letters_ 11, no. 2 (February 2004): 
% 112–14. <https://doi.org/10.1109/LSP.2003.821662 https://doi.org/10.1109/LSP.2003.821662>.
% 
% [3] Giles, J. "Empirical wavelet transform", _IEEE Transactions on Signal 
% Processing,_ vol. 61, no. 16 (May 2013): 3999 - 4010.
% 
% [4] Huang, Norden E., Zheng Shen, Steven R. Long, Manli C. Wu, Hsing H. Shih, 
% Quanan Zheng, Nai-Chyuan Yen, Chi Chao Tung, and Henry H. Liu. “The Empirical 
% Mode Decomposition and the Hilbert Spectrum for Nonlinear and Non-Stationary 
% Time Series Analysis.” _Proceedings of the Royal Society of London. Series A: 
% Mathematical, Physical and Engineering Sciences_ 454, no. 1971 (March 8, 1998): 
% 903–95. <https://doi.org/10.1098/rspa.1998.0193 https://doi.org/10.1098/rspa.1998.0193>.
% 
% [5] Percival, Donald B., and Andrew T. Walden. _Wavelet Methods for Time Series 
% Analysis_. Cambridge Series in Statistical and Probabilistic Mathematics. Cambridge 
% ; New York: Cambridge University Press, 2000.
% 
% _Copyright 2019 The MathWorks, Inc._
