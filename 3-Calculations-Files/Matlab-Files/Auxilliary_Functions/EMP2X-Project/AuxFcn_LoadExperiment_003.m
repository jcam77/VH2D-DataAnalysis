function tests = AuxFcn_LoadExperiment_003(cfg)
% AuxFcn_LoadExperiment_002 (NO MERGE / NO RESAMPLING)
% Load an arbitrary number of DAQ streams per test, with per-DAQ file formats.
%
% Required cfg fields:
%   cfg.daqs : struct array with fields:
%       .id      : string, e.g. "DAQ1"
%       .format  : "txt" or "tpc5"
%       .files   : cellstr/string array (can include empty entries)
%
% Optional per-DAQ fields (depending on format):
%   TXT:
%       .units        : 1xM string/cellstr (optional)
%       .channelType  : 1xM string/cellstr (optional)
%   TPC5:
%       .measurementId : string (optional)
%       .useTriggerTimeZero : logical (default true)
%
% Optional trigger classification (format-agnostic, per DAQ):
%   .trigger_channelIdx   : scalar or vector (length nTests), NaN = explicitly none
%   .trigger_namePattern  : regex string (optional)
%   .classifyByUnits      : logical (default false; only meaningful if mixed units)
%   .assumeNonTriggerIsPressure : logical (default false) -> if true, sets non-trigger channels to "pressure"
%
% Output:
%   tests(i).daqs(k) : struct with fields:
%       .id   : DAQ id string
%       .data : daqData struct returned by the reader (or [])
%   tests(i).meta        : metadata (files per DAQ, notes)
%
% USAGE / EXAMPLE:
% cfg = struct();
% cfg.daqs(1).id     = "DAQ1";
% cfg.daqs(1).format = "txt";
% cfg.daqs(1).files  = {'Problem grounding.txt','Test 2.txt'};
% cfg.daqs(1).units  = ["bar","bar","bar","V"];
% cfg.daqs(1).channelType = ["pressure","pressure","pressure","trigger"];
%
% cfg.daqs(2).id     = "DAQ2";
% cfg.daqs(2).format = "tpc5";
% cfg.daqs(2).files  = {'mytrace.tpc5','mytrace.tpc5'};
% cfg.daqs(2).trigger_channelIdx = [4 4];

% Optional: DAQ2 trigger classification (per-test mapping; NaN means “no trigger”)
% cfg.daqs(2).files  = {'mytrace.tpc5','SmallPump.tpc5'};
% cfg.daqs(2).trigger_channelIdx = [4 NaN];
% cfg.daqs(2).trigger_namePattern = "trig|trigger|ttl|ign";

% tests = AuxFcn_LoadExperiment_002(cfg);

% % UPDATES in _003:
% - Renamed output field '.streams' to '.daqs' for better descriptiveness. 

arguments
    cfg struct
end

assert(isfield(cfg,'daqs') && numel(cfg.daqs) >= 1, 'cfg.daqs must be a non-empty struct array.');
daqs = cfg.daqs;

% Normalize file lists and set defaults
for k = 1:numel(daqs)
    if ~isfield(daqs(k),'id');     error('cfg.daqs(%d) missing field "id".', k); end
    if ~isfield(daqs(k),'format'); error('cfg.daqs(%d) missing field "format".', k); end
    if ~isfield(daqs(k),'files');  daqs(k).files = {}; end
    if isstring(daqs(k).files);    daqs(k).files = cellstr(daqs(k).files); end

    % Reader options
    if ~isfield(daqs(k),'measurementId');      daqs(k).measurementId = ""; end
    if ~isfield(daqs(k),'useTriggerTimeZero'); daqs(k).useTriggerTimeZero = true; end
    if ~isfield(daqs(k),'units');              daqs(k).units = []; end
    if ~isfield(daqs(k),'channelType');        daqs(k).channelType = []; end

    % Trigger classification options
    if ~isfield(daqs(k),'trigger_channelIdx');  daqs(k).trigger_channelIdx = []; end
    if ~isfield(daqs(k),'trigger_namePattern'); daqs(k).trigger_namePattern = ""; end
    if ~isfield(daqs(k),'classifyByUnits');     daqs(k).classifyByUnits = false; end
    if ~isfield(daqs(k),'assumeNonTriggerIsPressure'); daqs(k).assumeNonTriggerIsPressure = false; end
end

% Determine number of tests as the maximum file list length across DAQs
nTests = 0;
for k = 1:numel(daqs)
    nTests = max(nTests, numel(daqs(k).files));
end

if nTests == 0
    tests = struct('streams',{},'meta',{});
    return;
end

% Preallocate output
tests = repmat(struct('streams',[],'meta',struct()), nTests, 1);

for i = 1:nTests
    tests(i).daqs = repmat(struct('id',"",'data',[]), numel(daqs), 1);

    % Meta once per test
    tests(i).meta.testIndex = i;
    tests(i).meta.note = "No merge/resampling performed. Streams preserved in native sampling.";

    for k = 1:numel(daqs)
        id     = string(daqs(k).id);
        fmt    = lower(string(daqs(k).format));
        files  = daqs(k).files;

        thisFile = "";
        if i <= numel(files) && ~isempty(files{i})
            thisFile = string(files{i});
        end

        daqData = [];

        if strlength(thisFile) > 0
            % --- Resolve files using MATLAB path (Project-friendly) ---
            thisFile = strtrim(thisFile);

            % 1) If file is on the MATLAB path, which() returns the absolute path
            p = which(char(thisFile));
            if ~isempty(p)
                thisFileResolved = string(p);
            else
                thisFileResolved = string(thisFile);
            end

            % 2) Use exist(...,'file') because it is path-aware (unlike isfile)
            fileExists = (exist(char(thisFileResolved), 'file') == 2);

            if fileExists
                try
                    switch fmt
                        case "txt"
                            % UPDATED: Now calling the _002 version of the TXT reader
                            daqData = AuxFcn_ReadDAQ_TXT_002(char(thisFileResolved), ...
                                'DaqId', id, ...
                                'Units', daqs(k).units, ...
                                'ChannelType', daqs(k).channelType);

                        case "tpc5"
                            % NOTE: This still calls _000 until we update TPC5 in Step 3
                            daqData = AuxFcn_ReadTPC5_001(char(thisFileResolved), ...
                                'DaqId', id, ...
                                'MeasurementId', daqs(k).measurementId, ...
                                'UseTriggerTimeZero', logical(daqs(k).useTriggerTimeZero));

                        otherwise
                            warning('Unsupported DAQ format "%s" for %s.', fmt, id);
                    end

                    if ~isempty(daqData)
                        % Classification logic
                        daqData = localClassifyTrigger_001(daqData, daqs(k), i);
                    end

                catch ME
                    warning('Error loading Test %d, DAQ %s: %s', i, id, ME.message);
                end
            else
                warning('Test %d: File not found for %s -> %s (pwd=%s)', i, id, thisFile, pwd);
            end
        end

        tests(i).daqs(k).id   = id;
        tests(i).daqs(k).data = daqData;

        % Per-DAQ file metadata
        tests(i).meta.(matlab.lang.makeValidName(id) + "_file") = thisFile;
    end
end

end

function daqData = localClassifyTrigger_001(daqData, daqSpec, testIdx)
% localClassifyTrigger_001 (Traceability preserved)
% Priority:
%   1) trigger_channelIdx (scalar or per-test vector; NaN => explicitly none)
%   2) trigger_namePattern (regex)
%   3) classifyByUnits (only meaningful if mixed units)
%
% Default: leaves unknown channels as "unknown" unless assumeNonTriggerIsPressure=true.

if isempty(daqData)
    return;
end

% Ensure channelType exists
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
        % NaN => explicitly "no trigger" for this test; stop silently
        return;
    end

    if idx == floor(idx) && idx >= 1 && idx <= daqData.nChannels
        daqData.channelType(idx) = "trigger";
        classifiedTrigger = true;
    else
        warning('%s trigger idx invalid for test %d: idx=%g, nChannels=%d.', ...
            string(daqSpec.id), testIdx, idx, daqData.nChannels);
    end
end

% --- 2) Regex name pattern ---
if ~classifiedTrigger && strlength(string(daqSpec.trigger_namePattern)) > 0
    pat = string(daqSpec.trigger_namePattern);
    nameL = lower(string(daqData.channelNames));
    idxTrig = ~cellfun(@isempty, regexp(cellstr(nameL), pat, 'once'));
    if any(idxTrig)
        daqData.channelType(idxTrig) = "trigger";
        classifiedTrigger = true;
    end
end

% --- 3) Units heuristic (only if mixed units) ---
if ~classifiedTrigger && logical(daqSpec.classifyByUnits) && isfield(daqData,'units')
    unitL  = lower(string(daqData.units));
    isVolt = contains(unitL, "v");           % "V", "mV", etc.

    if any(isVolt) && any(~isVolt)           % only meaningful if mixed units
        daqData.channelType(isVolt) = "trigger";
        classifiedTrigger = true;
    end
end

% Optional: treat all non-trigger channels as pressure (ONLY if explicitly enabled)
if classifiedTrigger && logical(daqSpec.assumeNonTriggerIsPressure)
    daqData.channelType(daqData.channelType == "unknown") = "pressure";
end

end