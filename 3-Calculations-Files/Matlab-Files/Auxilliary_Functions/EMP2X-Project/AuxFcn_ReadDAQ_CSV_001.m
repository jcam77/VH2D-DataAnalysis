function daqData = AuxFcn_ReadDAQ_CSV_001(fileName, options)
% AuxFcn_ReadDAQ_CSV_001
% Read semicolon-delimited CSV files from slow/asynchronous sensors
% (e.g. H2 concentration loggers) and return a standardised daqData struct
% compatible with the VH2D pipeline.
%
% This reader handles the specific format produced by the H2 concentration
% sensor logger used in the VH2D campaign:
%   Line 1 : Title row       e.g.  "Title;VH2-PreliminaryTest-2026"
%   Line 2 : Column headers  e.g.  "Time;Conc5_TC"
%   Line 3+ : Data rows      e.g.  "23.04.2026 08:07:04;902.71"
%
% The time column contains ABSOLUTE wall-clock timestamps (not elapsed
% seconds). This reader converts them to elapsed seconds from the first
% sample, and stores the absolute datetime vector in daqData.meta.
%
% KEY DIFFERENCE FROM TXT/TPC5/MF4 READERS:
%   Concentration sensors are SLOW and ASYNCHRONOUS (~1 Hz, non-uniform).
%   daqData.fs and daqData.dt are therefore MEAN estimates, not exact.
%   Do NOT use this data stream with AuxFcn_SamplingRateVerification_001.
%
% SYNTAX:
%   daqData = AuxFcn_ReadDAQ_CSV_001(fileName)
%   daqData = AuxFcn_ReadDAQ_CSV_001(fileName, Name=Value, ...)
%
% INPUTS:
%   fileName         : char/string — filename or absolute path to CSV file
%
% NAME-VALUE OPTIONS:
%   DaqId            : string label stored in daqData.daqId (default "CSV")
%   Delimiter        : char — field separator (default ";")
%   TitleLines       : integer — number of non-header lines to skip before
%                      the column-name row (default 1, i.e. skip line 1)
%   TimeFormat       : string — datetime format of the time column.
%                      Default "dd.MM.yyyy HH:mm:ss" (European dot-date).
%                      Other supported formats:
%                        "yyyy-MM-dd HH:mm:ss"   (ISO)
%                        "dd/MM/yyyy HH:mm:ss"   (slash-date)
%                        "MM/dd/yyyy HH:mm:ss"   (US)
%                        "dd.MM.yyyy HH:mm:ss.SSS" (with ms)
%   TimeZone         : string — IANA timezone for the timestamps
%                      (default "" = no timezone / local). E.g. "UTC",
%                      "Europe/Stockholm".
%   Units            : 1×M string/cellstr — override units per channel.
%                      Leave [] to initialise all as "raw".
%   ChannelType      : 1×M string/cellstr — channel type override.
%                      Leave [] for "unknown".
%
% OUTPUT — daqData struct (standard VH2D pipeline contract):
%   .daqId            string       DaqId label
%   .fileName         string       basename
%   .filePath         string       absolute path
%   .t                N×1 double   elapsed time [s] from first sample
%   .signal           N×M double   signal matrix
%   .channelNames     1×M string   column names from file header
%   .units            1×M string   engineering units
%   .channelType      1×M string   "pressure" | "trigger" | "unknown"
%   .nChannels        scalar       M
%   .nSamples         scalar       N
%   .fs               scalar       MEAN sampling rate [Hz] (non-uniform)
%   .dt               scalar       MEAN sample interval [s] (non-uniform)
%   .tbl              table        [elapsed_s, channel1, ...] for compatibility
%   .meta.title             string    content of the title row
%   .meta.absoluteTime      datetime  N×1 absolute timestamp vector
%   .meta.absoluteTimeStr   string    ISO string of first timestamp
%   .meta.isNonUniform      logical   true if dt std/mean > 1%
%   .meta.dtStd             scalar    std of inter-sample intervals [s]
%
% NOTES:
%   * The concentration sensor timestamps have 1-second resolution, so
%     duplicate timestamps (two readings in the same second) can occur.
%     These are kept as-is; elapsed time will have repeated values.
%   * Do NOT pass this daqData to AuxFcn_SamplingRateVerification_001 —
%     it checks for the .tbl field having a t_s numeric column, which is
%     present here, but the non-uniform sampling will always trigger warnings.
%     Use the .meta fields for sensor-level timing validation instead.
%
% EXAMPLE — VH2D H2 concentration logger:
%   daqData = AuxFcn_ReadDAQ_CSV_001('VH2-JTCD-260423-080704.csv', ...
%       'DaqId',      "H2-Sensor",     ...
%       'Units',      ["ppm"],         ...
%       'ChannelType',["concentration"]);
%
% UPDATES:
%   _001 : initial release — handles VH2D H2 concentration CSV format.
%          Absolute datetime parsing, elapsed-second conversion, non-uniform
%          sampling detection, standard daqData contract output.

% -------------------------------------------------------------------------
% Input parsing
% -------------------------------------------------------------------------
arguments
    fileName  (1,1) {mustBeTextScalar}
    options.DaqId        (1,1) string  = "CSV"
    options.Delimiter    (1,1) string  = ";"
    options.TitleLines   (1,1) double  = 1
    options.TimeFormat   (1,1) string  = "dd.MM.yyyy HH:mm:ss"
    options.TimeZone     (1,1) string  = ""
    options.Units                      = []
    options.ChannelType                = []
end

% -------------------------------------------------------------------------
% File resolution
% -------------------------------------------------------------------------
fileName = char(strtrim(fileName));

resolvedPath = which(fileName);
if isempty(resolvedPath)
    resolvedPath = fileName;
end
assert(exist(resolvedPath, 'file') == 2, ...
    'CSV file not found: %s', fileName);

[~, baseName, ext] = fileparts(resolvedPath);
fileNameStr = string([baseName, ext]);

delim = char(options.Delimiter);

% -------------------------------------------------------------------------
% Read raw lines to extract title and column names
% -------------------------------------------------------------------------
allLines = readlines(resolvedPath);   % string array, one element per line

% Remove trailing empty lines
allLines = allLines(~(strtrim(allLines) == ""));
nLines = numel(allLines);

nSkip    = options.TitleLines;        % lines before the header row
headerLineIdx = nSkip + 1;           % column-name row

assert(nLines > headerLineIdx, ...
    'File "%s" has too few lines (found %d, need > %d).', ...
    fileNameStr, nLines, headerLineIdx);

% Extract title content (join all skipped lines)
titleParts = strings(nSkip, 1);
for k = 1:nSkip
    tokens = strsplit(allLines(k), delim);
    titleParts(k) = strjoin(tokens(2:end), delim);  % drop label in col 1
end
titleStr = strjoin(titleParts, ' | ');

% Extract column names from header row
headerTokens = strsplit(allLines(headerLineIdx), delim);
headerTokens = strtrim(headerTokens);
headerTokens = headerTokens(headerTokens ~= "");

assert(numel(headerTokens) >= 2, ...
    'Header row in "%s" has fewer than 2 columns: "%s"', ...
    fileNameStr, allLines(headerLineIdx));

% Column names: col 1 is time, rest are signal channels
timeColName    = headerTokens(1);
signalColNames = headerTokens(2:end);
nChannels      = numel(signalColNames);

% -------------------------------------------------------------------------
% Read data rows
% -------------------------------------------------------------------------
dataLineStart = headerLineIdx + 1;
dataLines     = allLines(dataLineStart:end);
dataLines     = dataLines(strtrim(dataLines) ~= "");  % drop blank rows
nSamples      = numel(dataLines);

assert(nSamples >= 1, ...
    'No data rows found in "%s" after line %d.', fileNameStr, dataLineStart);

% Pre-allocate
timeStrings = strings(nSamples, 1);
signalMat   = NaN(nSamples, nChannels);

for i = 1:nSamples
    tokens = strsplit(dataLines(i), delim);
    tokens = strtrim(tokens);

    if numel(tokens) < 1 + nChannels
        % Pad if row is short (handles trailing missing values)
        tokens(end+1 : 1+nChannels) = "";
    end

    timeStrings(i) = tokens(1);

    for ci = 1:nChannels
        val = str2double(tokens(ci + 1));
        signalMat(i, ci) = val;   % NaN if empty or non-numeric
    end
end

% -------------------------------------------------------------------------
% Parse absolute timestamps → elapsed seconds
% -------------------------------------------------------------------------
fmt = char(options.TimeFormat);

if strlength(options.TimeZone) > 0
    absTime = datetime(timeStrings, 'InputFormat', fmt, ...
                       'TimeZone', char(options.TimeZone));
else
    absTime = datetime(timeStrings, 'InputFormat', fmt);
end

% Elapsed seconds from first valid sample
t0 = absTime(1);
t  = seconds(absTime - t0);   % N×1 double [s]
t  = t(:);

% -------------------------------------------------------------------------
% Sampling rate estimation (mean — non-uniform by nature)
% -------------------------------------------------------------------------
dtVec  = diff(t);
dtVec  = dtVec(isfinite(dtVec) & dtVec > 0);  % exclude zero/NaN

if ~isempty(dtVec)
    dt_mean  = mean(dtVec);
    dt_std   = std(dtVec);
    fs_mean  = 1 / dt_mean;
    relStd   = dt_std / dt_mean;
    isNonUniform = relStd > 0.01;
else
    dt_mean  = NaN;
    dt_std   = NaN;
    fs_mean  = NaN;
    isNonUniform = true;
end

if isNonUniform
    warning(['AuxFcn_ReadDAQ_CSV_001: Non-uniform sampling detected in "%s" ' ...
        '(dt std/mean = %.1f%%). fs/dt are MEAN estimates only. ' ...
        'Do not use with AuxFcn_SamplingRateVerification_001.'], ...
        fileNameStr, relStd * 100);
end

% -------------------------------------------------------------------------
% Units
% -------------------------------------------------------------------------
if ~isempty(options.Units)
    overrideUnits = string(options.Units);
    if numel(overrideUnits) == nChannels
        unitArr = overrideUnits;
    else
        warning(['AuxFcn_ReadDAQ_CSV_001: Units override length (%d) ≠ ' ...
            'nChannels (%d) for "%s". Using "raw".'], ...
            numel(overrideUnits), nChannels, fileNameStr);
        unitArr = repmat("raw", 1, nChannels);
    end
else
    unitArr = repmat("raw", 1, nChannels);
end

% -------------------------------------------------------------------------
% Channel type
% -------------------------------------------------------------------------
if ~isempty(options.ChannelType)
    overrideCT = string(options.ChannelType);
    if numel(overrideCT) == nChannels
        ctArr = overrideCT;
    else
        warning(['AuxFcn_ReadDAQ_CSV_001: ChannelType override length (%d) ≠ ' ...
            'nChannels (%d) for "%s". Using "unknown".'], ...
            numel(overrideCT), nChannels, fileNameStr);
        ctArr = repmat("unknown", 1, nChannels);
    end
else
    ctArr = repmat("unknown", 1, nChannels);
end

% -------------------------------------------------------------------------
% Build compatibility table  [elapsed_s, ch1, ch2, ...]
% -------------------------------------------------------------------------
validVarNames = ["t_s", matlab.lang.makeValidName(cellstr(signalColNames))];
tblData = [table(t, 'VariableNames', {'t_s'}), ...
           array2table(signalMat, 'VariableNames', validVarNames(2:end))];

% -------------------------------------------------------------------------
% Assemble daqData struct (standard VH2D contract)
% -------------------------------------------------------------------------
daqData = struct();
daqData.daqId        = string(options.DaqId);
daqData.fileName     = fileNameStr;
daqData.filePath     = string(resolvedPath);
daqData.t            = t;
daqData.signal       = signalMat;
daqData.channelNames = signalColNames;       % 1×M string (raw from header)
daqData.units        = unitArr;              % 1×M string
daqData.channelType  = ctArr;               % 1×M string
daqData.nChannels    = nChannels;
daqData.nSamples     = nSamples;
daqData.fs           = fs_mean;             % MEAN — non-uniform
daqData.dt           = dt_mean;             % MEAN — non-uniform
daqData.tbl          = tblData;

% Meta
daqData.meta = struct();
daqData.meta.title           = titleStr;
daqData.meta.absoluteTime    = absTime;          % datetime N×1
daqData.meta.absoluteTimeStr = string(t0);       % ISO string of t=0
daqData.meta.timeFormat      = string(fmt);
daqData.meta.isNonUniform    = isNonUniform;
daqData.meta.dtStd           = dt_std;
daqData.meta.delimiter       = string(delim);
daqData.meta.titleLines      = options.TitleLines;
daqData.meta.timeColumnName  = timeColName;

end
