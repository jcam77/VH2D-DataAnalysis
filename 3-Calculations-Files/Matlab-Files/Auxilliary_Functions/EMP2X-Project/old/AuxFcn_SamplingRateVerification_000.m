function [samplingRateSummary, timingUncertainty, samplingRateDiffSummary, metrics] = AuxFcn_SamplingRateVerification_000(activeTbl, dt, fs, fsDataSheet, kCoverage)
% AuxFcn_SamplingRateVerification_000
% Compare timestamp-derived dt/fs versus metadata and datasheet values.
%
% Inputs:
%   activeTbl               table containing at least column 'time' (timestamp text)
%   dt                      metadata sampling interval [s]
%   fs                      metadata sampling frequency [Hz]
%   fsDataSheet             nominal/datasheet sampling frequency [Hz] (default 200e3)
%   kCoverage               coverage factor for expanded uncertainty (default 2)
%
% Outputs:
%   samplingRateSummary     table with metadata/time-derived/datasheet dt and fs
%   timingUncertainty       table with mean/std/standard and expanded uncertainty
%   samplingRateDiffSummary table with relative differences [%] between rates
%   metrics                 struct with scalar metrics used in checks/logic

    if nargin < 4 || isempty(fsDataSheet)
        fsDataSheet = 200e3;  % [Hz]
    end
    if nargin < 5 || isempty(kCoverage)
        kCoverage = 2;        % ~95% for large n
    end

    assert(istable(activeTbl), 'activeTbl must be a table.');
    assert(any(strcmp(activeTbl.Properties.VariableNames, 'time')), ...
        'activeTbl must contain a ''time'' column.');
    assert(isfinite(dt) && dt > 0, 'dt must be a positive scalar.');
    assert(isfinite(fs) && fs > 0, 'fs must be a positive scalar.');
    assert(isfinite(fsDataSheet) && fsDataSheet > 0, 'fsDataSheet must be positive.');
    assert(isfinite(kCoverage) && kCoverage > 0, 'kCoverage must be positive.');

    % Parse timestamps with explicit format to avoid locale ambiguity.
    timeText = regexprep(string(activeTbl.time), '\s+', ' ');
    timeStamp = datetime(timeText, 'InputFormat', 'M/d/uuuu HH:mm:ss.SSSSSS');
    dtFromTime = seconds(diff(timeStamp));  % [s]
    nDt = numel(dtFromTime);
    assert(nDt > 0, 'Not enough timestamp samples to compute dt from time.');

    % Statistics from timestamps.
    dtFromTime_mean = mean(dtFromTime);      % [s]
    dtFromTime_std = std(dtFromTime);        % [s]

    % Standard and expanded uncertainty of the mean.
    u_dt_mean = dtFromTime_std / sqrt(nDt);  % [s]
    U95_dt_mean = kCoverage * u_dt_mean;     % [s]

    % Convert dt metrics to sampling-rate metrics.
    fsFromTime_mean = 1 / dtFromTime_mean;      % [Hz]
    u_fs_mean = u_dt_mean / (dtFromTime_mean^2);   % [Hz]
    U95_fs_mean = kCoverage * u_fs_mean;          % [Hz]

    dtDataSheet = 1 / fsDataSheet;  % [s]

    % Percent differences (relative to second quantity in each comparison).
    dtDiff_timeMean_vs_meta_pct = 100 * (dtFromTime_mean - dt) / dt;
    dtDiff_meta_vs_datasheet_pct = 100 * (dt - dtDataSheet) / dtDataSheet;
    dtDiff_timeMean_vs_datasheet_pct = 100 * (dtFromTime_mean - dtDataSheet) / dtDataSheet;

    fsDiff_timeMean_vs_meta_pct = 100 * (fsFromTime_mean - fs) / fs;
    fsDiff_meta_vs_datasheet_pct = 100 * (fs - fsDataSheet) / fsDataSheet;
    fsDiff_timeMean_vs_datasheet_pct = 100 * (fsFromTime_mean - fsDataSheet) / fsDataSheet;

    % Summary tables for reporting and cross-test comparison.
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
        'nDt', nDt, ...
        'kCoverage', kCoverage, ...
        'fsDataSheet', fsDataSheet, ...
        'dtDataSheet', dtDataSheet, ...
        'dtFromTime_mean', dtFromTime_mean, ...
        'dtFromTime_std', dtFromTime_std, ...
        'fsFromTime_mean', fsFromTime_mean, ...
        'u_dt_mean', u_dt_mean, ...
        'U95_dt_mean', U95_dt_mean, ...
        'u_fs_mean', u_fs_mean, ...
        'U95_fs_mean', U95_fs_mean, ...
        'dtDiff_timeMean_vs_meta_pct', dtDiff_timeMean_vs_meta_pct, ...
        'dtDiff_meta_vs_datasheet_pct', dtDiff_meta_vs_datasheet_pct, ...
        'dtDiff_timeMean_vs_datasheet_pct', dtDiff_timeMean_vs_datasheet_pct, ...
        'fsDiff_timeMean_vs_meta_pct', fsDiff_timeMean_vs_meta_pct, ...
        'fsDiff_meta_vs_datasheet_pct', fsDiff_meta_vs_datasheet_pct, ...
        'fsDiff_timeMean_vs_datasheet_pct', fsDiff_timeMean_vs_datasheet_pct);
end
