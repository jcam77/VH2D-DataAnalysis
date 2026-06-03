function tests = AuxFcn_LoadExperiment_005(cfg)
% AuxFcn_LoadExperiment_005 (NO MERGE / NO RESAMPLING)
% Load an arbitrary number of DAQ streams per test, with per-DAQ file formats.
%
% Supported formats:
%   "txt"   — DAQ pressure/trigger text exports  via AuxFcn_ReadDAQ_TXT_002
%   "tpc5"  — Elsys TransAS HDF5 binary          via AuxFcn_ReadTPC5_001
%   "mf4"   — Kistler KiStudio MDF4              via AuxFcn_ReadDAQ_MF4_001
%   "csv"   — Slow-sensor semicolon CSV          via AuxFcn_ReadDAQ_CSV_001  [NEW _005]
%
% Required cfg fields:
%   cfg.daqs : struct array with fields:
%       .id      : string  — DAQ identifier, e.g. "DAQ1-DBI"
%       .format  : string  — "txt" | "tpc5" | "mf4" | "csv"
%       .files   : cellstr/string array (empty entries allowed for missing tests)
%
% -------------------------------------------------------------------------
% Per-DAQ optional fields — SHARED (all formats):
%   .units        : 1×M string/cellstr — engineering unit override per channel
%   .channelType  : 1×M string/cellstr — channel type override
%                   ("pressure" | "trigger" | "concentration" | "unknown")
%
% Per-DAQ optional fields — TXT only:
%   (no extras beyond shared fields)
%
% Per-DAQ optional fields — TPC5 only:
%   .measurementId          : string  (default "")
%   .useTriggerTimeZero     : logical (default true)
%
% Per-DAQ optional fields — MF4 only:
%   .channelGroupIdx        : int     — channel group to read (default 1)
%   .timeChannelName        : string  — override time master (default "" = auto)
%   .convertToSI            : logical — bar/mbar/psi/mV → SI (default false)
%   .resampleFs             : scalar  — resample to uniform Hz (default 0 = off)
%
% Per-DAQ optional fields — CSV only:  [NEW in _005]
%   .csvDelimiter           : string  — field separator (default ";")
%   .csvTitleLines          : int     — lines to skip before header row (default 1)
%   .csvTimeFormat          : string  — datetime format (default "dd.MM.yyyy HH:mm:ss")
%   .csvTimeZone            : string  — IANA timezone string (default "" = local)
%
% -------------------------------------------------------------------------
% Trigger classification options (format-agnostic, per DAQ):
%   .trigger_channelIdx          : scalar or per-test vector (NaN = no trigger)
%   .trigger_namePattern         : regex string
%   .classifyByUnits             : logical (default false)
%   .assumeNonTriggerIsPressure  : logical (default false)
%
% -------------------------------------------------------------------------
% Output:
%   tests(i).daqs(k).id   : DAQ id string
%   tests(i).daqs(k).data : daqData struct from reader, or []
%   tests(i).meta         : per-test metadata (file names, notes)
%
% -------------------------------------------------------------------------
% EXAMPLE — full mixed-format campaign:
%
%   cfg.daqs(1).id     = "DAQ1-DBI";
%   cfg.daqs(1).format = "txt";
%   cfg.daqs(1).files  = {'Test1.txt','Test2.txt'};
%   cfg.daqs(1).units  = ["bar","bar","bar","V"];
%   cfg.daqs(1).channelType = ["pressure","pressure","pressure","trigger"];
%
%   cfg.daqs(2).id     = "DAQ2-Kistler";
%   cfg.daqs(2).format = "mf4";
%   cfg.daqs(2).files  = {'Test1.mf4','Test2.mf4'};
%   cfg.daqs(2).channelGroupIdx = 1;
%
%   cfg.daqs(3).id     = "DAQ3-Elsys";
%   cfg.daqs(3).format = "tpc5";
%   cfg.daqs(3).files  = {'Test1.tpc5','Test2.tpc5'};
%
%   cfg.daqs(4).id            = "H2-Sensor";
%   cfg.daqs(4).format        = "csv";
%   cfg.daqs(4).files         = {'Test1_H2.csv','Test2_H2.csv'};
%   cfg.daqs(4).units         = ["ppm"];
%   cfg.daqs(4).channelType   = ["concentration"];
%   cfg.daqs(4).csvTitleLines = 1;
%
%   tests = AuxFcn_LoadExperiment_005(cfg);
%
% -------------------------------------------------------------------------
% UPDATES:
%   _002 : multi-DAQ support (no merge).
%   _003 : renamed '.streams' → '.daqs'.
%   _004 : added MF4 format (AuxFcn_ReadDAQ_MF4_001).
%   _005 : added CSV format (AuxFcn_ReadDAQ_CSV_001).
%          Added per-DAQ CSV options: csvDelimiter, csvTitleLines,
%          csvTimeFormat, csvTimeZone.

arguments
    cfg struct
end

assert(isfield(cfg,'daqs') && numel(cfg.daqs) >= 1, ...
    'cfg.daqs must be a non-empty struct array.');
daqs = cfg.daqs;

% -------------------------------------------------------------------------
% Normalise DAQ specs and set all defaults
% -------------------------------------------------------------------------
for k = 1:numel(daqs)
    if ~isfield(daqs(k),'id');     error('cfg.daqs(%d) missing field "id".', k); end
    if ~isfield(daqs(k),'format'); error('cfg.daqs(%d) missing field "format".', k); end
    if ~isfield(daqs(k),'files');  daqs(k).files = {}; end
    if isstring(daqs(k).files);    daqs(k).files = cellstr(daqs(k).files); end

    % Shared
    if ~isfield(daqs(k),'units');       daqs(k).units = []; end
    if ~isfield(daqs(k),'channelType'); daqs(k).channelType = []; end

    % TPC5
    if ~isfield(daqs(k),'measurementId');      daqs(k).measurementId = ""; end
    if ~isfield(daqs(k),'useTriggerTimeZero'); daqs(k).useTriggerTimeZero = true; end

    % MF4
    if ~isfield(daqs(k),'channelGroupIdx');  daqs(k).channelGroupIdx = 1; end
    if ~isfield(daqs(k),'timeChannelName');  daqs(k).timeChannelName = ""; end
    if ~isfield(daqs(k),'convertToSI');      daqs(k).convertToSI = false; end
    if ~isfield(daqs(k),'resampleFs');       daqs(k).resampleFs = 0; end

    % CSV  [NEW in _005]
    if ~isfield(daqs(k),'csvDelimiter');   daqs(k).csvDelimiter = ";"; end
    if ~isfield(daqs(k),'csvTitleLines');  daqs(k).csvTitleLines = 1; end
    if ~isfield(daqs(k),'csvTimeFormat');  daqs(k).csvTimeFormat = "dd.MM.yyyy HH:mm:ss"; end
    if ~isfield(daqs(k),'csvTimeZone');    daqs(k).csvTimeZone = ""; end

    % Trigger classification
    if ~isfield(daqs(k),'trigger_channelIdx');          daqs(k).trigger_channelIdx = []; end
    if ~isfield(daqs(k),'trigger_namePattern');         daqs(k).trigger_namePattern = ""; end
    if ~isfield(daqs(k),'classifyByUnits');             daqs(k).classifyByUnits = false; end
    if ~isfield(daqs(k),'assumeNonTriggerIsPressure');  daqs(k).assumeNonTriggerIsPressure = false; end
end

% -------------------------------------------------------------------------
% Determine test count
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
    tests(i).meta.note = "No merge/resampling. Streams preserved in native sampling.";

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

            p = which(char(thisFile));
            thisFileResolved = string(p);
            if strlength(thisFileResolved) == 0
                thisFileResolved = thisFile;
            end

            fileExists = (exist(char(thisFileResolved), 'file') == 2);

            if fileExists
                try
                    switch fmt

                        % --------------------------------------------------
                        case "txt"
                        % --------------------------------------------------
                            daqData = AuxFcn_ReadDAQ_TXT_002(char(thisFileResolved), ...
                                'DaqId',       id,                  ...
                                'Units',       daqs(k).units,       ...
                                'ChannelType', daqs(k).channelType);

                        % --------------------------------------------------
                        case "tpc5"
                        % --------------------------------------------------
                            daqData = AuxFcn_ReadTPC5_001(char(thisFileResolved), ...
                                'DaqId',              id,                             ...
                                'MeasurementId',      daqs(k).measurementId,          ...
                                'UseTriggerTimeZero', logical(daqs(k).useTriggerTimeZero));

                            % Add channelType field if reader doesn't set it
                            if ~isfield(daqData,'channelType') || isempty(daqData.channelType)
                                daqData.channelType = repmat("unknown", 1, daqData.nChannels);
                            end

                        % --------------------------------------------------
                        case "mf4"
                        % --------------------------------------------------
                            daqData = AuxFcn_ReadDAQ_MF4_001(char(thisFileResolved), ...
                                'DaqId',           id,                           ...
                                'Units',           daqs(k).units,                ...
                                'ChannelType',     daqs(k).channelType,          ...
                                'ChannelGroupIdx', daqs(k).channelGroupIdx,      ...
                                'TimeChannelName', daqs(k).timeChannelName,      ...
                                'ConvertToSI',     logical(daqs(k).convertToSI), ...
                                'ResampleFs',      daqs(k).resampleFs);

                        % --------------------------------------------------
                        case "csv"   % [NEW in _005]
                        % --------------------------------------------------
                            daqData = AuxFcn_ReadDAQ_CSV_001(char(thisFileResolved), ...
                                'DaqId',       id,                        ...
                                'Units',       daqs(k).units,             ...
                                'ChannelType', daqs(k).channelType,       ...
                                'Delimiter',   daqs(k).csvDelimiter,      ...
                                'TitleLines',  daqs(k).csvTitleLines,     ...
                                'TimeFormat',  daqs(k).csvTimeFormat,     ...
                                'TimeZone',    daqs(k).csvTimeZone);

                        % --------------------------------------------------
                        otherwise
                        % --------------------------------------------------
                            warning('Unsupported format "%s" for DAQ "%s". Skipping.', fmt, id);
                    end

                    % Trigger classification (format-agnostic)
                    if ~isempty(daqData)
                        daqData = localClassifyTrigger_001(daqData, daqs(k), i);
                    end

                catch ME
                    warning('Error loading Test %d, DAQ "%s":\n  %s\n  File: %s', ...
                        i, id, ME.message, thisFileResolved);
                end

            else
                warning('Test %d: File not found for DAQ "%s" → %s', i, id, thisFile);
            end
        end

        tests(i).daqs(k).id   = id;
        tests(i).daqs(k).data = daqData;
        tests(i).meta.(matlab.lang.makeValidName(id) + "_file") = thisFile;
    end
end

end


% =========================================================================
%  LOCAL HELPER — Trigger classification (unchanged from _003/_004)
% =========================================================================

function daqData = localClassifyTrigger_001(daqData, daqSpec, testIdx)
% Priority:
%   1) trigger_channelIdx (scalar or per-test; NaN = no trigger)
%   2) trigger_namePattern (regex on channelNames)
%   3) classifyByUnits (only if mixed units)
%
% If assumeNonTriggerIsPressure=true, "unknown" → "pressure" after trigger found.

if isempty(daqData)
    return;
end

if ~isfield(daqData,'channelType') || isempty(daqData.channelType)
    daqData.channelType = repmat("unknown", 1, daqData.nChannels);
end

classifiedTrigger = false;

% 1) Explicit index
idxVec = daqSpec.trigger_channelIdx;
if ~isempty(idxVec)
    idx = idxVec(min(numel(idxVec), testIdx));
    if ~isfinite(idx); return; end   % NaN = explicitly no trigger
    if idx == floor(idx) && idx >= 1 && idx <= daqData.nChannels
        daqData.channelType(idx) = "trigger";
        classifiedTrigger = true;
    else
        warning('trigger_channelIdx=%g invalid for DAQ "%s", test %d (nChannels=%d).', ...
            idx, string(daqSpec.id), testIdx, daqData.nChannels);
    end
end

% 2) Name pattern
if ~classifiedTrigger && strlength(string(daqSpec.trigger_namePattern)) > 0
    pat    = string(daqSpec.trigger_namePattern);
    nameL  = lower(string(daqData.channelNames));
    isTrig = ~cellfun(@isempty, regexp(cellstr(nameL), pat, 'once'));
    if any(isTrig)
        daqData.channelType(isTrig) = "trigger";
        classifiedTrigger = true;
    end
end

% 3) Units heuristic
if ~classifiedTrigger && logical(daqSpec.classifyByUnits) && isfield(daqData,'units')
    unitL  = lower(string(daqData.units));
    isVolt = contains(unitL, "v");
    if any(isVolt) && any(~isVolt)
        daqData.channelType(isVolt) = "trigger";
        classifiedTrigger = true;
    end
end

% Optional: unknown → pressure
if classifiedTrigger && logical(daqSpec.assumeNonTriggerIsPressure)
    daqData.channelType(daqData.channelType == "unknown") = "pressure";
end

end
