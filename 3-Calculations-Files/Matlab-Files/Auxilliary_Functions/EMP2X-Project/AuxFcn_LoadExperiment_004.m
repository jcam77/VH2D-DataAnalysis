function tests = AuxFcn_LoadExperiment_004(cfg)
% AuxFcn_LoadExperiment_004 (NO MERGE / NO RESAMPLING)
% Load an arbitrary number of DAQ streams per test, with per-DAQ file formats.
%
% Supported formats:
%   "txt"   — delimited text files via AuxFcn_ReadDAQ_TXT_002
%   "tpc5"  — TPC5 binary files via AuxFcn_ReadTPC5_001
%   "mf4"   — MDF4 files (.mf4 / .mdf) via AuxFcn_ReadDAQ_MF4_001  [NEW in _004]
%
% Required cfg fields:
%   cfg.daqs : struct array with fields:
%       .id      : string, e.g. "DAQ1"
%       .format  : "txt" | "tpc5" | "mf4"
%       .files   : cellstr/string array (can include empty entries)
%
% Optional per-DAQ fields (shared):
%   .units        : 1×M string/cellstr — engineering unit override per channel
%   .channelType  : 1×M string/cellstr — channel type override per channel
%                   ("pressure" | "trigger" | "unknown")
%
% Optional per-DAQ fields (TXT only):
%   (none beyond .units and .channelType)
%
% Optional per-DAQ fields (TPC5 only):
%   .measurementId          : string (default "")
%   .useTriggerTimeZero     : logical (default true)
%
% Optional per-DAQ fields (MF4 only):  [NEW in _004]
%   .channelGroupIdx        : positive int — which MDF channel group to read
%                             (default 1; inspect with mdfinfo())
%   .timeChannelName        : string — explicit time-master channel name
%                             (default "" = auto-detect)
%   .convertToSI            : logical — apply bar/mbar/psi/mV → SI (default false)
%   .resampleFs             : scalar Hz — resample to uniform rate (default 0 = off)
%
% Optional trigger classification (format-agnostic, per DAQ):
%   .trigger_channelIdx          : scalar or vector (length nTests), NaN = explicitly none
%   .trigger_namePattern         : regex string (optional)
%   .classifyByUnits             : logical (default false; only if mixed units)
%   .assumeNonTriggerIsPressure  : logical (default false)
%
% Output:
%   tests(i).daqs(k) : struct with fields:
%       .id   : DAQ id string
%       .data : daqData struct returned by the reader, or []
%   tests(i).meta    : metadata (files per DAQ, notes)
%
% -------------------------------------------------------------------------
% EXAMPLE — mixed TXT + MF4 campaign:
%
%   cfg = struct();
%
%   cfg.daqs(1).id     = "DAQ1-DBI";
%   cfg.daqs(1).format = "txt";
%   cfg.daqs(1).files  = {'Test1.txt','Test2.txt'};
%   cfg.daqs(1).units  = ["bar","bar","bar","V"];
%   cfg.daqs(1).channelType = ["pressure","pressure","pressure","trigger"];
%
%   cfg.daqs(2).id              = "DAQ2-MF4";
%   cfg.daqs(2).format          = "mf4";
%   cfg.daqs(2).files           = {'Test1.mf4','Test2.mf4'};
%   cfg.daqs(2).units           = ["bar","bar","V"];
%   cfg.daqs(2).channelType     = ["pressure","pressure","trigger"];
%   cfg.daqs(2).channelGroupIdx = 1;
%   cfg.daqs(2).convertToSI     = false;
%
%   tests = AuxFcn_LoadExperiment_004(cfg);
%
% -------------------------------------------------------------------------
% UPDATES:
%   _002 : added multi-DAQ support (no merge).
%   _003 : renamed output field '.streams' → '.daqs' for descriptiveness.
%   _004 : added MF4 format support via AuxFcn_ReadDAQ_MF4_001.
%          Added per-DAQ MF4 options: channelGroupIdx, timeChannelName,
%          convertToSI, resampleFs.
% -------------------------------------------------------------------------

arguments
    cfg struct
end

assert(isfield(cfg,'daqs') && numel(cfg.daqs) >= 1, ...
    'cfg.daqs must be a non-empty struct array.');
daqs = cfg.daqs;

% -------------------------------------------------------------------------
% Normalise DAQ specs and set defaults
% -------------------------------------------------------------------------
for k = 1:numel(daqs)
    if ~isfield(daqs(k),'id');     error('cfg.daqs(%d) missing field "id".', k); end
    if ~isfield(daqs(k),'format'); error('cfg.daqs(%d) missing field "format".', k); end
    if ~isfield(daqs(k),'files');  daqs(k).files = {}; end
    if isstring(daqs(k).files);    daqs(k).files = cellstr(daqs(k).files); end

    % Shared reader options
    if ~isfield(daqs(k),'units');              daqs(k).units = []; end
    if ~isfield(daqs(k),'channelType');        daqs(k).channelType = []; end

    % TPC5 options
    if ~isfield(daqs(k),'measurementId');      daqs(k).measurementId = ""; end
    if ~isfield(daqs(k),'useTriggerTimeZero'); daqs(k).useTriggerTimeZero = true; end

    % MF4 options  [NEW in _004]
    if ~isfield(daqs(k),'channelGroupIdx');    daqs(k).channelGroupIdx = 1; end
    if ~isfield(daqs(k),'timeChannelName');    daqs(k).timeChannelName = ""; end
    if ~isfield(daqs(k),'convertToSI');        daqs(k).convertToSI = false; end
    if ~isfield(daqs(k),'resampleFs');         daqs(k).resampleFs = 0; end

    % Trigger classification options (format-agnostic)
    if ~isfield(daqs(k),'trigger_channelIdx');          daqs(k).trigger_channelIdx = []; end
    if ~isfield(daqs(k),'trigger_namePattern');         daqs(k).trigger_namePattern = ""; end
    if ~isfield(daqs(k),'classifyByUnits');             daqs(k).classifyByUnits = false; end
    if ~isfield(daqs(k),'assumeNonTriggerIsPressure');  daqs(k).assumeNonTriggerIsPressure = false; end
end

% -------------------------------------------------------------------------
% Determine test count = max file-list length across DAQs
% -------------------------------------------------------------------------
nTests = 0;
for k = 1:numel(daqs)
    nTests = max(nTests, numel(daqs(k).files));
end

if nTests == 0
    tests = struct('daqs',{},'meta',{});
    return;
end

% -------------------------------------------------------------------------
% Preallocate output
% -------------------------------------------------------------------------
tests = repmat(struct('daqs',[],'meta',struct()), nTests, 1);

% -------------------------------------------------------------------------
% Main loop: tests × DAQs
% -------------------------------------------------------------------------
for i = 1:nTests
    tests(i).daqs = repmat(struct('id',"",'data',[]), numel(daqs), 1);

    tests(i).meta.testIndex = i;
    tests(i).meta.note = "No merge/resampling performed. Streams preserved in native sampling.";

    for k = 1:numel(daqs)
        id    = string(daqs(k).id);
        fmt   = lower(string(daqs(k).format));
        files = daqs(k).files;

        thisFile = "";
        if i <= numel(files) && ~isempty(files{i})
            thisFile = string(files{i});
        end

        daqData = [];

        if strlength(thisFile) > 0
            thisFile = strtrim(thisFile);

            % Resolve to absolute path via MATLAB path
            p = which(char(thisFile));
            if ~isempty(p)
                thisFileResolved = string(p);
            else
                thisFileResolved = string(thisFile);
            end

            fileExists = (exist(char(thisFileResolved), 'file') == 2);

            if fileExists
                try
                    switch fmt

                        case "txt"
                            daqData = AuxFcn_ReadDAQ_TXT_002(char(thisFileResolved), ...
                                'DaqId',       id,                  ...
                                'Units',       daqs(k).units,       ...
                                'ChannelType', daqs(k).channelType);

                        case "tpc5"
                            daqData = AuxFcn_ReadTPC5_001(char(thisFileResolved), ...
                                'DaqId',               id,                             ...
                                'MeasurementId',       daqs(k).measurementId,          ...
                                'UseTriggerTimeZero',  logical(daqs(k).useTriggerTimeZero));

                        case "mf4"
                            % --------------------------------------------------
                            % MF4 / MDF4 reader  [NEW in _004]
                            % --------------------------------------------------
                            daqData = AuxFcn_ReadDAQ_MF4_001(char(thisFileResolved), ...
                                'DaqId',            id,                            ...
                                'Units',            daqs(k).units,                 ...
                                'ChannelType',      daqs(k).channelType,           ...
                                'ChannelGroupIdx',  daqs(k).channelGroupIdx,       ...
                                'TimeChannelName',  daqs(k).timeChannelName,       ...
                                'ConvertToSI',      logical(daqs(k).convertToSI),  ...
                                'ResampleFs',       daqs(k).resampleFs);

                        otherwise
                            warning('Unsupported DAQ format "%s" for DAQ "%s". Skipping.', fmt, id);
                    end

                    % Trigger / channel-type classification (format-agnostic)
                    if ~isempty(daqData)
                        daqData = localClassifyTrigger_001(daqData, daqs(k), i);
                    end

                catch ME
                    warning('Error loading Test %d, DAQ %s: %s\n  File: %s', ...
                        i, id, ME.message, thisFileResolved);
                end

            else
                warning('Test %d: File not found for DAQ "%s" → %s  (pwd = %s)', ...
                    i, id, thisFile, pwd);
            end
        end

        tests(i).daqs(k).id   = id;
        tests(i).daqs(k).data = daqData;

        % Per-DAQ file metadata
        tests(i).meta.(matlab.lang.makeValidName(id) + "_file") = thisFile;
    end
end

end


% =========================================================================
%  LOCAL HELPER — Trigger / channel-type classification (unchanged from _003)
% =========================================================================

function daqData = localClassifyTrigger_001(daqData, daqSpec, testIdx)
% localClassifyTrigger_001
% Priority:
%   1) trigger_channelIdx (scalar or per-test vector; NaN => explicitly none)
%   2) trigger_namePattern (regex on channel names)
%   3) classifyByUnits (only when mixed units present)
%
% If assumeNonTriggerIsPressure=true, remaining "unknown" channels are set
% to "pressure" after a trigger is identified.

if isempty(daqData)
    return;
end

% Ensure channelType field exists
if ~isfield(daqData,'channelType') || isempty(daqData.channelType)
    daqData.channelType = repmat("unknown", 1, daqData.nChannels);
end

classifiedTrigger = false;

% --- 1) Explicit channel index ---
idxVec = daqSpec.trigger_channelIdx;
if ~isempty(idxVec)
    if numel(idxVec) == 1
        idx = idxVec;
    else
        idx = idxVec(min(testIdx, numel(idxVec)));
    end

    if ~isfinite(idx)
        return;   % NaN => no trigger for this test
    end

    if idx == floor(idx) && idx >= 1 && idx <= daqData.nChannels
        daqData.channelType(idx) = "trigger";
        classifiedTrigger = true;
    else
        warning('%s trigger_channelIdx invalid for test %d: idx=%g, nChannels=%d.', ...
            string(daqSpec.id), testIdx, idx, daqData.nChannels);
    end
end

% --- 2) Regex name pattern ---
if ~classifiedTrigger && strlength(string(daqSpec.trigger_namePattern)) > 0
    pat   = string(daqSpec.trigger_namePattern);
    nameL = lower(string(daqData.channelNames));
    idxTrig = ~cellfun(@isempty, regexp(cellstr(nameL), pat, 'once'));
    if any(idxTrig)
        daqData.channelType(idxTrig) = "trigger";
        classifiedTrigger = true;
    end
end

% --- 3) Units heuristic (only if mixed units present) ---
if ~classifiedTrigger && logical(daqSpec.classifyByUnits) && isfield(daqData,'units')
    unitL  = lower(string(daqData.units));
    isVolt = contains(unitL, "v");      % "V", "mV", etc.
    if any(isVolt) && any(~isVolt)
        daqData.channelType(isVolt) = "trigger";
        classifiedTrigger = true;
    end
end

% Optional: promote unknown → pressure once trigger is identified
if classifiedTrigger && logical(daqSpec.assumeNonTriggerIsPressure)
    daqData.channelType(daqData.channelType == "unknown") = "pressure";
end

end
