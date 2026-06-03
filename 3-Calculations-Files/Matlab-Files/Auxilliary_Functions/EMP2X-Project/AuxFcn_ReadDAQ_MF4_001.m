function daqData = AuxFcn_ReadDAQ_MF4_001(filePath, options)
% AuxFcn_ReadDAQ_MF4_001
% Read an MDF4 (.mf4 / .mdf) file and return a standardised daqData struct
% compatible with the VH2D pipeline (same contract as AuxFcn_ReadDAQ_TXT_002).
%
% Validated against: Kistler KiStudio equidistant MDF 4.10 files.
%
% REQUIREMENTS:
%   MATLAB Vehicle Network Toolbox  (provides mdfinfo / mdfread)
%   Check: exist('mdfinfo','file') == 2
%
% HOW MATLAB mdfread RETURNS DATA:
%   mdfread() returns a TIMETABLE (not a plain table).
%   - Time vector  : tbl.Properties.RowTimes  (duration type → use seconds())
%   - Signal cols  : tbl.Properties.VariableNames  (one entry per data channel)
%   - Units        : tbl.Properties.VariableUnits  (cell array of strings)
%   The virtual master channel (channel_type=3 in MDF4) is consumed by
%   MATLAB into RowTimes automatically — it does NOT appear as a variable.
%
% SYNTAX:
%   daqData = AuxFcn_ReadDAQ_MF4_001(filePath)
%   daqData = AuxFcn_ReadDAQ_MF4_001(filePath, Name=Value, ...)
%
% INPUTS:
%   filePath          : char/string — absolute path to .mf4 / .mdf file
%
% NAME-VALUE OPTIONS:
%   DaqId             : string  — label stored in daqData.daqId (default "MF4")
%   Units             : 1×M string/cellstr — override units per channel.
%                       Leave [] to use file-embedded units (recommended).
%   ChannelType       : 1×M string/cellstr — override channelType per channel.
%                       ("pressure" | "trigger" | "unknown")
%                       Leave [] to initialise all as "unknown" and let
%                       localClassifyTrigger_001 handle it downstream.
%   ChannelGroupIdx   : positive integer — which MDF channel group to read
%                       (default 1). Use mdfinfo() to inspect available groups.
%   ChannelNames      : string/cellstr — subset of channel names to read.
%                       Leave [] to read all data channels in the group.
%   ConvertToSI       : logical — apply unit conversions to SI
%                       (bar→Pa, mbar→Pa, psi→Pa, kPa→Pa, mV→V). Default false.
%   ResampleFs        : scalar Hz — if > 0, resample to uniform grid via interp1.
%                       Default 0 (off). Useful for multi-rate MF4 files.
%
% OUTPUT — daqData struct (identical contract to AuxFcn_ReadDAQ_TXT_002):
%   .daqId            string        DaqId label
%   .fileName         string        basename of the file
%   .filePath         string        absolute path
%   .t                N×1 double    time vector [s]
%   .signal           N×M double    signal matrix (columns = channels)
%   .channelNames     1×M string    channel names from file (or subset)
%   .units            1×M string    engineering units
%   .channelType      1×M string    "pressure" | "trigger" | "unknown"
%   .nChannels        scalar        M
%   .nSamples         scalar        N
%   .fs               scalar        sampling rate [Hz]
%   .dt               scalar        sample interval [s]
%   .channelGroupIdx  scalar        MDF channel group index that was read
%   .mdfVersion       string        MDF version string from file header
%   .logger           string        logger software name (if in header comment)
%   .tbl              timetable     original MATLAB timetable from mdfread —
%                                   compatible with AuxFcn_SamplingRateVerification
%
% NOTES:
%   * Kistler KiStudio files (MDF 4.10, equidistant): fully validated.
%     Time master is a virtual master channel (channel_type=3); MATLAB
%     places it in RowTimes automatically.
%   * For multi-rate MF4 files, set ResampleFs to the desired output rate.
%   * For very large files, use ChannelNames to read only required channels.
%
% EXAMPLE — Kistler KiStudio trigger characterisation file:
%   daqData = AuxFcn_ReadDAQ_MF4_001('Test_01.mf4', ...
%       'DaqId',           "DAQ2-Kistler", ...
%       'ChannelGroupIdx', 1,              ...
%       'ChannelType',     ["trigger"]);
%
% EXAMPLE — multi-channel pressure file with unit override:
%   daqData = AuxFcn_ReadDAQ_MF4_001('PressureRun_03.mf4',  ...
%       'DaqId',       "DAQ2-MF4",                           ...
%       'Units',       ["bar","bar","bar","V"],               ...
%       'ChannelType', ["pressure","pressure","pressure","trigger"], ...
%       'ConvertToSI', false);
%
% UPDATES:
%   _001 : initial release — MDF4 support added to VH2D pipeline.
%   _001 (patch) : fixed timetable handling (mdfread returns timetable, not
%          table); time from RowTimes via seconds(); units from VariableUnits;
%          added Kistler KiStudio header metadata extraction;
%          removed localFindTimeMaster (handled automatically by mdfread);
%          added ChannelNames option for large-file subsetting.
%          Validated against Kistler KiStudio MDF 4.10 equidistant files.

% -------------------------------------------------------------------------
% Input parsing
% -------------------------------------------------------------------------
arguments
    filePath  (1,1) {mustBeTextScalar}
    options.DaqId             (1,1) string  = "MF4"
    options.Units                           = []     % string/cellstr or []
    options.ChannelType                     = []     % string/cellstr or []
    options.ChannelGroupIdx   (1,1) double  = 1
    options.ChannelNames                    = []     % string/cellstr or []
    options.ConvertToSI       (1,1) logical = false
    options.ResampleFs        (1,1) double  = 0
end

filePath = char(strtrim(filePath));

% -------------------------------------------------------------------------
% Toolbox guard
% -------------------------------------------------------------------------
assert(exist('mdfinfo','file') == 2, ...
    ['mdfinfo() not found. The Vehicle Network Toolbox is required ' ...
     'to read MF4 files. Check your MATLAB toolbox installation.']);
assert(exist('mdfread','file') == 2, ...
    'mdfread() not found. Check your MATLAB toolbox installation.');

% -------------------------------------------------------------------------
% File validation
% -------------------------------------------------------------------------
assert(exist(filePath,'file') == 2, ...
    'MF4 file not found: %s', filePath);

[~, baseName, ext] = fileparts(filePath);
fileName = [baseName, ext];

validExts = {'.mf4','.mdf','.MF4','.MDF'};
assert(any(strcmpi(ext, validExts)), ...
    'Extension "%s" is not a recognised MDF extension (.mf4 / .mdf).', ext);

% -------------------------------------------------------------------------
% Inspect file structure via mdfinfo
% -------------------------------------------------------------------------
info   = mdfinfo(filePath);
cgIdx  = options.ChannelGroupIdx;
nGroups = numel(info.ChannelGroup);

assert(cgIdx >= 1 && cgIdx <= nGroups, ...
    'ChannelGroupIdx=%d out of range [1,%d] for: %s', cgIdx, nGroups, fileName);

% -------------------------------------------------------------------------
% Read data — mdfread returns a TIMETABLE
% -------------------------------------------------------------------------
readArgs = {'ChannelGroup', cgIdx};

% Optionally subset channels (large-file optimisation)
if ~isempty(options.ChannelNames)
    readArgs = [readArgs, {'ChannelNames', cellstr(string(options.ChannelNames))}];
end

tbl = mdfread(filePath, readArgs{:});

% Validate that we received a timetable
assert(isa(tbl, 'timetable'), ...
    ['mdfread returned a %s instead of a timetable. ' ...
     'This may indicate an unsupported MDF version or toolbox release. ' ...
     'Inspect the output of mdfread(''%s'') manually.'], class(tbl), fileName);

% -------------------------------------------------------------------------
% Extract time vector from RowTimes (duration → seconds)
% -------------------------------------------------------------------------
% mdfread places the MDF master/virtual-master channel into RowTimes.
% It does NOT appear as a variable column.
t = seconds(tbl.Properties.RowTimes);   % N×1 double [s]
t = t(:);
nSamples = numel(t);

assert(nSamples > 1, ...
    'Timetable from "%s" contains only %d sample(s). Check ChannelGroupIdx.', ...
    fileName, nSamples);

% -------------------------------------------------------------------------
% Extract channel names and signal matrix from timetable variables
% -------------------------------------------------------------------------
varNames    = string(tbl.Properties.VariableNames);   % 1×M
nChannels   = numel(varNames);
channelNames = varNames;

assert(nChannels >= 1, ...
    'No data channels found in channel group %d of "%s".', cgIdx, fileName);

signalMat = zeros(nSamples, nChannels, 'double');
for ci = 1:nChannels
    col = tbl.(char(varNames(ci)));
    signalMat(:, ci) = double(col(:));
end

% -------------------------------------------------------------------------
% Resample if requested (also handles non-uniform timestamp jitter)
% -------------------------------------------------------------------------
[t, signalMat] = localHandleResampling(t, signalMat, options.ResampleFs, fileName);
nSamples = numel(t);

% -------------------------------------------------------------------------
% Sampling rate — prefer header-declared value, fall back to timestamps
% -------------------------------------------------------------------------
[fs, dt] = localEstimateSamplingRate(t, info, cgIdx);

% -------------------------------------------------------------------------
% Units — from timetable VariableUnits, then apply override if provided
% -------------------------------------------------------------------------
% MATLAB stores units in tbl.Properties.VariableUnits (cell array of char)
fileUnits = string(tbl.Properties.VariableUnits);   % 1×M

% If VariableUnits is empty or shorter than nChannels, pad with ""
if numel(fileUnits) < nChannels
    fileUnits(end+1:nChannels) = "";
end

if ~isempty(options.Units)
    overrideUnits = string(options.Units);
    if numel(overrideUnits) == nChannels
        fileUnits = overrideUnits;
    else
        warning(['AuxFcn_ReadDAQ_MF4_001: Units override length (%d) ≠ ' ...
            'nChannels (%d) for "%s". Override ignored; using file units.'], ...
            numel(overrideUnits), nChannels, fileName);
    end
end

% -------------------------------------------------------------------------
% Unit conversion to SI (optional)
% -------------------------------------------------------------------------
if options.ConvertToSI
    [signalMat, fileUnits] = localConvertToSI(signalMat, fileUnits);
end

% -------------------------------------------------------------------------
% Channel type initialisation
% -------------------------------------------------------------------------
channelType = repmat("unknown", 1, nChannels);

if ~isempty(options.ChannelType)
    overrideCT = string(options.ChannelType);
    if numel(overrideCT) == nChannels
        channelType = overrideCT;
    else
        warning(['AuxFcn_ReadDAQ_MF4_001: ChannelType override length (%d) ≠ ' ...
            'nChannels (%d) for "%s". Override ignored.'], ...
            numel(overrideCT), nChannels, fileName);
    end
end

% -------------------------------------------------------------------------
% Extract logger metadata from MDF header comment (Kistler KiStudio etc.)
% -------------------------------------------------------------------------
loggerName = localExtractLoggerName(info);

% -------------------------------------------------------------------------
% Build output daqData struct
% -------------------------------------------------------------------------
daqData = struct();
daqData.daqId            = string(options.DaqId);
daqData.fileName         = string(fileName);
daqData.filePath         = string(filePath);
daqData.t                = t;
daqData.signal           = signalMat;
daqData.channelNames     = channelNames;         % 1×M string
daqData.units            = fileUnits;            % 1×M string
daqData.channelType      = channelType;          % 1×M string
daqData.nChannels        = nChannels;
daqData.nSamples         = nSamples;
daqData.fs               = fs;
daqData.dt               = dt;
daqData.channelGroupIdx  = cgIdx;
daqData.mdfVersion       = string(info.MDF_Version);
daqData.logger           = loggerName;

% Keep original timetable for AuxFcn_SamplingRateVerification_001
% (the function expects a .tbl field with a t_s column or RowTimes)
daqData.tbl = tbl;

end


% =========================================================================
%  LOCAL HELPERS
% =========================================================================

function [fs, dt] = localEstimateSamplingRate(t, info, cgIdx)
% localEstimateSamplingRate
% Priority:
%   1) SamplingInterval declared in mdfinfo ChannelGroup (most accurate)
%   2) Mean of timestamp differences

    fs = NaN; dt = NaN;

    % --- Attempt 1: mdfinfo declared sampling interval ---
    cgInfo = info.ChannelGroup(cgIdx);
    siFields = {'SamplingInterval','Interval','dt','SampleInterval'};
    for f = siFields
        if isfield(cgInfo, f{1})
            val = cgInfo.(f{1});
            if isnumeric(val) && isfinite(val) && val > 0
                dt = val;
                fs = 1 / dt;
                return;
            end
        end
    end

    % --- Attempt 2: timestamp deltas ---
    if numel(t) > 1
        dtVec = diff(t);
        dt    = mean(dtVec, 'omitnan');
        fs    = 1 / dt;

        % Warn if non-uniform
        relStd = std(dtVec, 'omitnan') / dt;
        if relStd > 0.01
            warning(['AuxFcn_ReadDAQ_MF4_001: Non-uniform timestamps detected ' ...
                '(relative std = %.2f%%). Consider setting ResampleFs.'], relStd*100);
        end
    end
end


function loggerName = localExtractLoggerName(info)
% localExtractLoggerName  Parse logger software from MDF header comment.
% Handles Kistler KiStudio, Dewesoft, HBK Perception, ETAS INCA patterns.

    loggerName = "unknown";

    % mdfinfo may expose the header comment as FileComment or HDcomment
    commentFields = {'FileComment','Comment','HDComment','HeaderComment'};
    commentStr = "";
    for f = commentFields
        if isfield(info, f{1}) && ~isempty(info.(f{1}))
            commentStr = string(info.(f{1}));
            break;
        end
    end

    if strlength(commentStr) == 0
        return;
    end

    % Known logger patterns (case-insensitive)
    patterns = { ...
        'KiStudio',     'Kistler KiStudio';  ...
        'KiStudio',     'Kistler KiStudio';  ...
        'Dewesoft',     'Dewesoft';           ...
        'Perception',   'HBK Perception';     ...
        'INCA',         'ETAS INCA';          ...
        'CANape',       'Vector CANape';      ...
        'DIAdem',       'NI DIAdem';          ...
    };

    for pi = 1:size(patterns,1)
        if contains(commentStr, patterns{pi,1}, 'IgnoreCase', true)
            loggerName = string(patterns{pi,2});
            return;
        end
    end
end


function [signalMat, units] = localConvertToSI(signalMat, units)
% localConvertToSI  Apply known unit conversions to SI.

    convFactor = struct('bar',1e5, 'mbar',100, 'psi',6894.757, ...
                        'kpa',1e3, 'mv',1e-3);
    siUnit     = struct('bar','Pa','mbar','Pa','psi','Pa', ...
                        'kpa','Pa','mv','V');

    for ci = 1:numel(units)
        key = lower(strtrim(char(units(ci))));
        % Remove trailing/leading whitespace and special chars
        key = regexprep(key,'[^a-z]','');
        if isfield(convFactor, key)
            signalMat(:, ci) = signalMat(:, ci) * convFactor.(key);
            units(ci)        = string(siUnit.(key));
        end
    end
end


function [t, signalMat] = localHandleResampling(t, signalMat, targetFs, fileName)
% localHandleResampling  Uniform-grid resampling via interp1 (linear).
% Only active when targetFs > 0.

    if targetFs <= 0
        return;
    end

    assert(isnumeric(targetFs) && isfinite(targetFs) && targetFs > 0, ...
        'ResampleFs must be a positive finite scalar. Got: %g', targetFs);

    tNew     = (t(1) : 1/targetFs : t(end)).';
    nCh      = size(signalMat, 2);
    sigNew   = zeros(numel(tNew), nCh, 'double');

    for ci = 1:nCh
        sigNew(:, ci) = interp1(t, signalMat(:, ci), tNew, 'linear', 'extrap');
    end

    fprintf('AuxFcn_ReadDAQ_MF4_001: Resampled "%s" to %.0f Hz (%d → %d samples).\n', ...
        fileName, targetFs, numel(t), numel(tNew));

    t         = tNew;
    signalMat = sigNew;
end
