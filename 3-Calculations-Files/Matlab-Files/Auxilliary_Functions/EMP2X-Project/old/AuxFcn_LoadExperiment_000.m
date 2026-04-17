function tests = AuxFcn_LoadExperiment_000(cfg)
% AuxFcn_LoadExperiment_000 (CLEANED — NO MERGE / NO RESAMPLING)
% Load paired DAQ streams (DAQ-1 TXT + DAQ-2 TPC5) and return per-test structs.
% This function is an *orchestrator only*: it does NOT retime, resample, or merge.
%
% Required configuration (cfg) fields :
%   cfg.daq1_txt_files   : cellstr/string array (can be empty)
%   cfg.daq2_tpc5_files  : cellstr/string array (can be empty)
%
% Optional cfg fields:
%   cfg.daq1_id          : string (default "DAQ1")
%   cfg.daq2_id          : string (default "DAQ2")
%   cfg.measurementId    : TPC5 measurement group id (default: first in file)
%   cfg.daq1_units       : 1xM string/cellstr, passed to AuxFcn_ReadDAQ_TXT_000 (optional)
%   cfg.daq1_channelType : 1xM string/cellstr, passed to AuxFcn_ReadDAQ_TXT_000 (optional)
%
% Optional DAQ2 trigger classification (recommended: explicit index):
%   cfg.daq2_trigger_channelIdx   : scalar OR vector (length nTests) with channel index; use NaN for “none”
%   cfg.daq2_trigger_namePattern  : regex pattern, e.g. "trig|trigger|ttl|ign"
%
% Output:
%   tests(i).DAQ1 : struct from AuxFcn_ReadDAQ_TXT_000 (or [])
%   tests(i).DAQ2 : struct from AuxFcn_ReadTPC5_000    (or [])
%   tests(i).meta : metadata (file names + note that no merge was performed)
%
% USAGE / EXAMPLE:
%   cfg = struct();
%   cfg.daq1_txt_files  = {'Problem grounding.txt','Test 2.txt'};
%   cfg.daq2_tpc5_files = {'mytrace.tpc5','mytrace.tpc5'};
%   cfg.daq1_id = "DAQ1";
%   cfg.daq2_id = "DAQ2";
%
%   % Optional: units/types for DAQ1 (TXT typically lacks units)
%   cfg.daq1_units = ["bar","bar","bar","bar"];
%   cfg.daq1_channelType = ["pressure","pressure","pressure","pressure"];
%
%   % Optional: DAQ2 trigger classification (per-test mapping; use NaN if not present)
%   cfg.daq2_trigger_channelIdx = [4 4 NaN];
%   % cfg.daq2_trigger_namePattern = "trig|trigger|ttl|ign";
%
%   tests = AuxFcn_LoadExperiment_000(cfg);
%   daq1 = tests(1).DAQ1;
%   daq2 = tests(1).DAQ2;

arguments
    cfg struct
end

% ---- defaults ----
if ~isfield(cfg,'daq1_txt_files');  cfg.daq1_txt_files = {}; end
if ~isfield(cfg,'daq2_tpc5_files'); cfg.daq2_tpc5_files = {}; end
if ~isfield(cfg,'daq1_id');         cfg.daq1_id = "DAQ1"; end
if ~isfield(cfg,'daq2_id');         cfg.daq2_id = "DAQ2"; end
if ~isfield(cfg,'measurementId');   cfg.measurementId = ""; end
if ~isfield(cfg,'daq1_units');      cfg.daq1_units = []; end
if ~isfield(cfg,'daq1_channelType');cfg.daq1_channelType = []; end

% Optional trigger selectors
if ~isfield(cfg,'daq2_trigger_channelIdx');  cfg.daq2_trigger_channelIdx = []; end
if ~isfield(cfg,'daq2_trigger_namePattern'); cfg.daq2_trigger_namePattern = ""; end

daq1Files = cfg.daq1_txt_files;
daq2Files = cfg.daq2_tpc5_files;

if isstring(daq1Files); daq1Files = cellstr(daq1Files); end
if isstring(daq2Files); daq2Files = cellstr(daq2Files); end

n1 = numel(daq1Files);
n2 = numel(daq2Files);
nTests = max(n1, n2);

tests = repmat(struct('DAQ1',[],'DAQ2',[],'meta',struct()), nTests, 1);

for i = 1:nTests
    daq1 = [];
    daq2 = [];

    % ---- DAQ-1 TXT ----
    if i <= n1 && ~isempty(daq1Files{i})
        daq1 = AuxFcn_ReadDAQ_TXT_000(daq1Files{i}, ...
            'DaqId', cfg.daq1_id, ...
            'Units', cfg.daq1_units, ...
            'ChannelType', cfg.daq1_channelType);
    end

    % ---- DAQ-2 TPC5 ----
    if i <= n2 && ~isempty(daq2Files{i})
        daq2 = AuxFcn_ReadTPC5_000(daq2Files{i}, ...
            'DaqId', cfg.daq2_id, ...
            'MeasurementId', cfg.measurementId, ...
            'UseTriggerTimeZero', true);

        % Default: unknown unless we can classify robustly
        daq2.channelType = repmat("unknown", 1, daq2.nChannels);
        classified = false;

        % 1) Explicit index (scalar or per-test vector)
        if ~isempty(cfg.daq2_trigger_channelIdx)
            idxVec = cfg.daq2_trigger_channelIdx;

            if numel(idxVec) == 1
                idx = idxVec;
            else
                idx = idxVec(min(i, numel(idxVec)));
            end

            % IMPORTANT FIX:
            % NaN means: "explicitly no trigger for this test" -> do not warn, do not fall back.
            if ~isfinite(idx)
                classified = true;   % stop here; leave channelType as "unknown"
            elseif idx == floor(idx) && idx >= 1 && idx <= daq2.nChannels
                daq2.channelType(:) = "pressure";
                daq2.channelType(idx) = "trigger";
                classified = true;
            else
                warning('DAQ2 trigger idx invalid for test %d (%s): idx=%g, nChannels=%d. Trying pattern/heuristics.', ...
                    i, daq2.file, idx, daq2.nChannels);
            end
        end

        % 2) Name pattern
        if ~classified && strlength(string(cfg.daq2_trigger_namePattern)) > 0
            pat = string(cfg.daq2_trigger_namePattern);
            nameL = lower(string(daq2.channelNames));
            idxTrig = ~cellfun(@isempty, regexp(cellstr(nameL), pat, 'once'));
            if any(idxTrig)
                daq2.channelType(:) = "pressure";
                daq2.channelType(idxTrig) = "trigger";
                classified = true;
            else
                warning('DAQ2 trigger pattern did not match any channel names for test %d (%s).', i, daq2.file);
            end
        end

        % 3) Fallback heuristic (only if units are mixed)
        if ~classified
            unitL = lower(string(daq2.units));
            isVolt = contains(unitL, "v");

            if any(~isVolt)
                daq2.channelType(:) = "pressure";
                daq2.channelType(isVolt) = "trigger";
                classified = true;
            else
                warning('DAQ2 channelType unresolved for test %d (%s): all units are V and no valid trigger selector provided.', ...
                    i, daq2.file);
            end
        end
    end

    tests(i).DAQ1 = daq1;
    tests(i).DAQ2 = daq2;

    % ---- metadata ----
    tests(i).meta.testIndex = i;
    tests(i).meta.note = "No merge/resampling performed. DAQ streams preserved in native sampling.";

    tests(i).meta.daq1_file = "";
    tests(i).meta.daq2_file = "";
    if ~isempty(daq1) && isfield(daq1,'file'); tests(i).meta.daq1_file = daq1.file; end
    if ~isempty(daq2) && isfield(daq2,'file'); tests(i).meta.daq2_file = daq2.file; end
end

end
