function daqData = AuxFcn_ReadDAQ_TXT_002(fileName, varargin)
% AuxFcn_ReadDAQ_TXT_002
% Robust TXT reader for DAQ exports with variable number of channels.
%
% Returns a standardized struct:
%   daqData.fileName, daqData.filePath, daqData.daqId
%   daqData.dt, daqData.fs
%   daqData.t         (Nx1) time [s]
%   daqData.signal    (NxM) channels
%   daqData.nSamples, daqData.nChannels
%   daqData.channelNames (1xM string)
%   daqData.units        (1xM string; placeholders unless encoded in file)
%   daqData.meta         (struct; parsing settings)
%
% Assumptions (configurable):
%   - dt is stored in a header line (default line 3) formatted like: "<label>;<dt>"
%   - column header line exists (default line 5) with ';' delimiter
%   - numeric data start at line 6
%
% USAGE / EXAMPLES:
%   % Basic read (uses header dt to construct uniform t)
% daq1 = AuxFcn_ReadDAQ_TXT_002('Problem grounding.txt', 'DaqId',"DAQ1");
% plot(daq1.t, daq1.signal(:,1)); grid on;
% title(char(daq1.channelNames(1)), 'Interpreter','none');
%
%   % Prefer reading the time column if it is numeric-like
%   daq1 = AuxFcn_ReadDAQ_TXT_002('Test_001_DAQ1.txt', ...
%       'PreferTimeColumn', true, 'DaqId',"DAQ1");
%
%   % Override parsing parameters (if your header differs)
%   daq1 = AuxFcn_ReadDAQ_TXT_002('Test_001_DAQ1.txt', ...
%       'Delimiter',';', 'HeaderDtLine',3, 'HeaderNamesLine',5, 'DataLines',[6 Inf]);

% UPDATES in _001:
% - Renamed input argument to 'fileName'. [cite: 1]
% - Standardized output fields: 'fileName' (short name) and 'filePath' (absolute path). [cite: 1]
%
% UPDATES in _002:
% - Uses RAW name tokens for .channelNames to avoid trailing underscores from makeValidName. [cite: 2]
% - This prevents LaTeX interpreter crashes in .mlx files during plotting. [cite: 2]

p = inputParser;
p.addRequired('fileName', @(x) ischar(x) || isstring(x));
p.addParameter('Delimiter', ';', @(x) ischar(x) || isstring(x));
p.addParameter('HeaderDtLine', 3, @(x) isnumeric(x) && isscalar(x) && x>=1);
p.addParameter('HeaderNamesLine', 5, @(x) isnumeric(x) && isscalar(x) && x>=1);
p.addParameter('DataLines', [6 Inf], @(x) isnumeric(x) && numel(x)==2);
p.addParameter('DaqId', "", @(x) ischar(x) || isstring(x));
p.addParameter('PreferTimeColumn', false, @(x) islogical(x) && isscalar(x));
p.addParameter('Units', [], @(x) isempty(x) || isstring(x) || iscellstr(x));
p.addParameter('ChannelType', [], @(x) isempty(x) || isstring(x) || iscellstr(x));

p.parse(fileName, varargin{:});
opt = p.Results;

fileName = string(fileName);
thisFile = which(char(fileName));
if isempty(thisFile)
    thisFile = char(fileName);
    assert(exist(thisFile,'file')==2, 'Raw data file not found: %s', fileName);
end

delim = char(opt.Delimiter);

% ---------- Read header (dt + column names) ----------
headerLines = readlines(thisFile);
assert(numel(headerLines) >= opt.HeaderNamesLine, ...
    'Unexpected header format (too few lines) in %s', thisFile);

% dt
dt_i = NaN;
try
    dtTokens = split(headerLines(opt.HeaderDtLine), delim);
    if numel(dtTokens) >= 2
        dt_i = str2double(dtTokens(2));
    end
catch
end
if isfinite(dt_i) && dt_i > 0
    fs_i = 1/dt_i;
else
    fs_i = NaN;
end

% column names (line with headers)
nameTokens = split(strtrim(headerLines(opt.HeaderNamesLine)), delim);
nameTokens = nameTokens(~(nameTokens==""));
nVars = numel(nameTokens);

% Fallback if header line is not usable
if nVars < 2
    nVars = 2;
    nameTokens = ["time","Y0"];
else
    nameTokens(1) = "time";
end

% Build variable names for internal table (Must be valid MATLAB identifiers)
varNames = strings(1,nVars);
varNames(1) = "time";
for k = 2:nVars
    tok = strtrim(nameTokens(k));
    if tok == ""
        tok = "Y" + string(k-2);
    end
    varNames(k) = string(matlab.lang.makeValidName(tok));
end

% ---------- Read table ----------
opts = delimitedTextImportOptions("NumVariables", nVars);
opts.Delimiter = delim;
opts.DataLines = opt.DataLines;
opts.VariableNames = varNames;
opts.VariableTypes = ["string", repmat("double",1,nVars-1)];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts = setvaropts(opts, varNames(1), "WhitespaceRule","preserve");
opts = setvaropts(opts, varNames(1), "EmptyFieldRule","auto");

tbl = readtable(thisFile, opts);

signal = tbl{:,2:end};
nSamples = size(signal,1);
nChannels = size(signal,2);

% ---------- Time vector ----------
t = NaN(nSamples,1);
timeCol = tbl{:,1};

if opt.PreferTimeColumn
    if isstring(timeCol) || iscellstr(timeCol)
        tTry = str2double(string(timeCol));
        if all(isfinite(tTry))
            t = tTry(:);
        end
    elseif isnumeric(timeCol)
        t = timeCol(:);
    end
end

if any(~isfinite(t))
    if isfinite(fs_i) && fs_i > 0
        t = (0:nSamples-1)'/fs_i;
    else
        if isnumeric(timeCol)
            dtEst = median(diff(timeCol));
            assert(isfinite(dtEst) && dtEst > 0, 'Cannot determine dt/fs for %s', thisFile);
            dt_i = dtEst; fs_i = 1/dt_i;
            t = (0:nSamples-1)'/fs_i;
        else
            error('Cannot determine dt/fs for %s. Provide a valid header dt or set PreferTimeColumn=true.', thisFile);
        end
    end
end

% ---------- Outputs ----------
daqData = struct();

% Renamed fields for readability and transparency [cite: 1]
[~, fName, fExt] = fileparts(fileName); 
daqData.fileName = string(fName) + string(fExt); % e.g., "Problem grounding.txt" [cite: 1]
daqData.filePath = string(thisFile);             % The full absolute path [cite: 1]
daqData.daqId = string(opt.DaqId);

daqData.dt = dt_i;
daqData.fs = fs_i;

daqData.tbl = tbl;
daqData.t = t(:);
daqData.signal = signal;
daqData.nSamples = nSamples;
daqData.nChannels = nChannels;

% FIX: Generate channelNames using RAW tokens to avoid LaTeX-breaking underscores [cite: 2]
chNames = strings(1,nChannels);
for k = 1:nChannels
    if numel(nameTokens) >= (k+1)
        % Use the raw token from the file header, trimmed but NOT sanitized [cite: 2]
        rawTok = strtrim(nameTokens(k+1)); 
        if rawTok == ""
            chNames(k) = "Y" + string(k-1);
        else
            chNames(k) = rawTok; 
        end
    else
        chNames(k) = "Y" + string(k-1);
    end
end
daqData.channelNames = chNames;

% Units: either user-provided, or placeholders if not available in TXT
if isempty(opt.Units)
    daqData.units = repmat("raw", 1, nChannels);
    daqData.meta.unitsNote = "TXT source does not provide units; 'raw' placeholders used.";
else
    u = string(opt.Units);
    assert(numel(u) == nChannels, 'Units must have length %d to match number of channels.', nChannels);
    daqData.units = reshape(u, 1, []);
end

% Channel types: optional (pressure/trigger/unknown)
if isempty(opt.ChannelType)
    daqData.channelType = repmat("unknown", 1, nChannels);
else
    ct = string(opt.ChannelType);
    assert(numel(ct) == nChannels, 'ChannelType must have length %d to match number of channels.', nChannels);
    daqData.channelType = reshape(ct, 1, []);
end

daqData.meta = struct();
daqData.meta.delimiter = delim;
daqData.meta.dataLines = opt.DataLines;
daqData.meta.headerDtLine = opt.HeaderDtLine;
daqData.meta.headerNamesLine = opt.HeaderNamesLine;

end