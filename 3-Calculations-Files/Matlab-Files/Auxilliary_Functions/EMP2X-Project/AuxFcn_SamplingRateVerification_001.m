function [samplingRateSummary, timingUncertainty, samplingRateDiffSummary, metrics] = AuxFcn_SamplingRateVerification_001(activeTbl, dt, fs, fsDataSheet, kCoverage)
% AuxFcn_SamplingRateVerification_001
% Compare timestamp-derived dt/fs versus metadata and datasheet values.
%
% UPDATES in _001:
% - Maintained compatibility with standardized daqData.tbl structure.
% - Preserved all uncertainty calculation logic and metrics.

    if nargin < 4 || isempty(fsDataSheet)
        fsDataSheet = 200e3;  % [Hz]
    end
    if nargin < 5 || isempty(kCoverage)
        kCoverage = 2;        % ~95% for large n
    end

    assert(istable(activeTbl), 'activeTbl must be a table.');
    assert(any(strcmp(activeTbl.Properties.VariableNames, 'time')), ...
        'activeTbl must contain a ''time'' column (Raw string timestamps).');

    % Parse timestamps with explicit format to avoid locale ambiguity.
    % Note: Uses the 'time' column which contains the raw string timestamps from TXT.
    timeText = regexprep(string(activeTbl.time), '\s+', ' ');
    timeStamp = datetime(timeText, 'InputFormat', 'M/d/uuuu HH:mm:ss.SSSSSS');
    dtFromTime = seconds(diff(timeStamp));  % [s]
    nDt = numel(dtFromTime);
    assert(nDt > 0, 'Not enough timestamp samples to compute dt from time.');

    % Statistics and Uncertainty Calculations (Preserved from _000)
    dtFromTime_mean = mean(dtFromTime);      
    dtFromTime_std = std(dtFromTime);        
    u_dt_mean = dtFromTime_std / sqrt(nDt);  
    U95_dt_mean = kCoverage * u_dt_mean;     
    fsFromTime_mean = 1 / dtFromTime_mean;      
    u_fs_mean = u_dt_mean / (dtFromTime_mean^2);   
    U95_fs_mean = kCoverage * u_fs_mean;          
    dtDataSheet = 1 / fsDataSheet;  

    % Relative Differences [%]
    dtDiff_timeMean_vs_meta_pct = 100 * (dtFromTime_mean - dt) / dt;
    dtDiff_meta_vs_datasheet_pct = 100 * (dt - dtDataSheet) / dtDataSheet;
    dtDiff_timeMean_vs_datasheet_pct = 100 * (dtFromTime_mean - dtDataSheet) / dtDataSheet;
    fsDiff_timeMean_vs_meta_pct = 100 * (fsFromTime_mean - fs) / fs;
    fsDiff_meta_vs_datasheet_pct = 100 * (fs - fsDataSheet) / fsDataSheet;
    fsDiff_timeMean_vs_datasheet_pct = 100 * (fsFromTime_mean - fsDataSheet) / fsDataSheet;

    % Summary Tables
    samplingRateSummary = table( ...
        ["Metadata"; "Timestamps (Mean)"; "Datasheet"], ...
        [dt; dtFromTime_mean; dtDataSheet], ...
        [fs; fsFromTime_mean; fsDataSheet], ...
        'VariableNames', {'Source', 'dt_s', 'fs_Hz'});

    timingUncertainty = table( ...
        nDt, dtFromTime_std, u_dt_mean, U95_dt_mean, u_fs_mean, U95_fs_mean, ...
        'VariableNames', {'nIntervals', 'std_dt_s', 'u_dt_mean_s', 'U95_dt_mean_s', 'u_fs_mean_Hz', 'U95_fs_mean_Hz'});

    samplingRateDiffSummary = table( ...
        ["TimeMean vs Metadata"; "Metadata vs Datasheet"; "TimeMean vs Datasheet"], ...
        [dtDiff_timeMean_vs_meta_pct; dtDiff_meta_vs_datasheet_pct; dtDiff_timeMean_vs_datasheet_pct], ...
        [fsDiff_timeMean_vs_meta_pct; fsDiff_meta_vs_datasheet_pct; fsDiff_timeMean_vs_datasheet_pct], ...
        'VariableNames', {'Comparison', 'dtDiff_pct', 'fsDiff_pct'});

    metrics = struct( ...
        'nDt', nDt, 'kCoverage', kCoverage, 'fsDataSheet', fsDataSheet, ...
        'dtDataSheet', dtDataSheet, 'dtFromTime_mean', dtFromTime_mean, ...
        'dtFromTime_std', dtFromTime_std, 'fsFromTime_mean', fsFromTime_mean, ...
        'u_dt_mean', u_dt_mean, 'U95_dt_mean', U95_dt_mean, ...
        'u_fs_mean', u_fs_mean, 'U95_fs_mean', U95_fs_mean, ...
        'dtDiff_timeMean_vs_meta_pct', dtDiff_timeMean_vs_meta_pct, ...
        'dtDiff_meta_vs_datasheet_pct', dtDiff_meta_vs_datasheet_pct, ...
        'dtDiff_timeMean_vs_datasheet_pct', dtDiff_timeMean_vs_datasheet_pct, ...
        'fsDiff_timeMean_vs_meta_pct', fsDiff_timeMean_vs_meta_pct, ...
        'fsDiff_meta_vs_datasheet_pct', fsDiff_meta_vs_datasheet_pct, ...
        'fsDiff_timeMean_vs_datasheet_pct', fsDiff_timeMean_vs_datasheet_pct);
end