function campaign = AuxFcn_LoadCampaignRuns_001(rootDir, options)
% AuxFcn_LoadCampaignRuns_001
% Discover and load campaign data organized as:
%   campaign root / run folders / sensor-or-DAQ folders / files
%
% Recommended workflow:
%   1) Load individual runs first.
%   2) Use campaign.groups to analyze/compare groups.
%   3) Merge/resample streams only after selecting the streams needed.
%
% Example for VH2D Wk22:
%   streamSpecs = struct( ...
%       'id',      {"DAQ-1","DAQ-2-3","H2CM"}, ...
%       'folder',  {"DAQ-1","DAQ-2-3","H2CM"}, ...
%       'pattern', {"*.tpc5","*.mf4","*.csv"}, ...
%       'format',  {"tpc5","mf4","csv"});
%   campaign = AuxFcn_LoadCampaignRuns_001(rawRoot, ...
%       Groups=["02","03","04"], ...
%       RunPattern="VH2D-Wk22-*-*", ...
%       StreamSpecs=streamSpecs, ...
%       LoadData=false);
%
% Output:
%   campaign.rootDir       string
%   campaign.groups        struct array with .id and .runIdx
%   campaign.runs          struct array; one element per run folder
%   campaign.manifest      table with discovered files and load status
%
% StreamSpecs fields:
%   .id       stream label, e.g. "DAQ-1"
%   .folder   folder inside each run, e.g. "DAQ-1"
%   .pattern  file glob inside folder, e.g. "*.tpc5"
%   .format   reader key: "tpc5" | "mf4" | "csv" | "h2txt"

arguments
    rootDir (1,1) string = pwd
    options.Groups string = strings(0,1)
    options.RunPattern (1,1) string = "*"
    options.RunIdPattern (1,1) string = "^(.+)-(\d+)-(\d+)$"
    options.GroupTokenIdx (1,1) double = 2
    options.RunNumberTokenIdx (1,1) double = 3
    options.RunNumbers double = []
    options.StreamSpecs = []
    options.LoadData (1,1) logical = true
    options.MaxRuns (1,1) double = Inf
    options.SkipFormats string = strings(0,1)
    options.WarnOnLoadError (1,1) logical = true
    options.MF4Reader (1,1) string = "matlab"
    options.MF4ChannelGroupIdx (1,1) double = 1
    options.ConvertMF4ToSI (1,1) logical = false
    options.MF4ResampleFs (1,1) double = 0
    options.MF4PythonExecutable (1,1) string = ""
    options.UseTPC5TriggerTimeZero (1,1) logical = true
    options.CSVTimeZone (1,1) string = "Europe/Stockholm"
    options.CSVWarnNonUniform (1,1) logical = true
    options.HydrogenSignalColumns string = "Output (%)"
end

if isempty(options.StreamSpecs)
    error(['AuxFcn_LoadCampaignRuns_001: StreamSpecs must be provided. ' ...
        'Define stream IDs, folders, filename patterns, and formats in the campaign config.']);
end

rootDir = char(rootDir);
assert(isfolder(rootDir), 'Campaign root directory not found: %s', rootDir);

% Discover run folders from the campaign root, then filter by selected group
% IDs and optional run numbers.
groupsWanted = string(options.Groups);
runNumbersWanted = options.RunNumbers;
runDirs = dir(fullfile(rootDir, options.RunPattern));
runDirs = runDirs([runDirs.isdir]);
runRecords = localParseRunDirs(runDirs, groupsWanted, runNumbersWanted, options);
if isfinite(options.MaxRuns)
    runRecords = runRecords(1:min(numel(runRecords), options.MaxRuns));
end

assert(~isempty(runRecords), ...
    'No run folders found in "%s" for pattern "%s".', ...
    rootDir, options.RunPattern);

campaign = struct();
campaign.rootDir = string(rootDir);
campaign.options = options;
campaign.runs = repmat(localEmptyRun(), numel(runRecords), 1);

manifest = localEmptyManifest();

for i = 1:numel(runRecords)
    % Each run folder is inspected independently. Missing DAQ/sensor folders
    % simply produce no stream for that run.
    runPath = fullfile(rootDir, runRecords(i).folderName);
    streamSpecs = localDiscoverStreams(runPath, options.StreamSpecs);

    runOut = localEmptyRun();
    runOut.id = string(runRecords(i).folderName);
    runOut.groupId = string(runRecords(i).groupId);
    runOut.runNumber = runRecords(i).runNumber;
    runOut.path = string(runPath);
    runOut.streams = repmat(localEmptyStream(), numel(streamSpecs), 1);

    for k = 1:numel(streamSpecs)
        spec = streamSpecs(k);
        data = [];
        loaded = false;
        loadError = "";
        status = "not_loaded";

        skipFormat = any(lower(string(spec.format)) == lower(string(options.SkipFormats)));

        if skipFormat
            status = "skipped";
            loadError = "Skipped by SkipFormats option.";
        elseif options.LoadData
            try
                % Reader dispatch is based only on the configured file format,
                % not on folder names or channel positions.
                data = localLoadStream(spec, options);
                loaded = ~isempty(data);
                if loaded
                    status = "loaded";
                end
            catch ME
                status = "failed";
                loadError = string(ME.message);
                if options.WarnOnLoadError
                    warning('Run "%s", stream "%s" failed to load:\n  %s', ...
                        runOut.id, spec.id, ME.message);
                end
            end
        end

        runOut.streams(k).id = spec.id;
        runOut.streams(k).format = spec.format;
        runOut.streams(k).folder = spec.folder;
        runOut.streams(k).fileName = spec.fileName;
        runOut.streams(k).filePath = spec.filePath;
        runOut.streams(k).data = data;
        runOut.streams(k).loaded = loaded;
        runOut.streams(k).status = status;
        runOut.streams(k).loadError = loadError;

        manifest = localAppendManifest(manifest, runOut, spec, loaded, status, loadError);
    end

    campaign.runs(i) = runOut;
end

campaign.groups = localBuildGroups(campaign.runs);
campaign.manifest = manifest;

end

function runRecords = localParseRunDirs(runDirs, groupsWanted, runNumbersWanted, options)
runRecords = struct('folderName', {}, 'groupId', {}, 'runNumber', {});

for i = 1:numel(runDirs)
    tokens = regexp(runDirs(i).name, options.RunIdPattern, 'tokens', 'once');
    if isempty(tokens)
        continue;
    end

    assert(numel(tokens) >= max(options.GroupTokenIdx, options.RunNumberTokenIdx), ...
        'RunIdPattern did not return enough tokens for folder "%s".', runDirs(i).name);

    groupId = string(tokens{options.GroupTokenIdx});
    runNumber = str2double(tokens{options.RunNumberTokenIdx});
    if ~isempty(groupsWanted) && ~any(groupId == groupsWanted)
        continue;
    end
    if ~isempty(runNumbersWanted) && ~any(runNumber == runNumbersWanted)
        continue;
    end

    runRecords(end+1).folderName = runDirs(i).name; %#ok<AGROW>
    runRecords(end).groupId = groupId;
    runRecords(end).runNumber = runNumber;
end

if isempty(runRecords)
    return;
end

groupNumbers = str2double(string({runRecords.groupId}));
if any(isnan(groupNumbers))
    [~, order] = sort(string({runRecords.groupId}));
else
    [~, order] = sort(groupNumbers * 1000 + [runRecords.runNumber]);
end
runRecords = runRecords(order);
end

function streamSpecs = localDiscoverStreams(runPath, requestedSpecs)
streamSpecs = localEmptyStreamSpec();
streamSpecs(:) = [];

for i = 1:numel(requestedSpecs)
    % StreamSpecs is the user-editable contract between folder layout and
    % reader format. This keeps campaign-specific folder names out of the
    % reader functions.
    requested = requestedSpecs(i);
    sensorPath = fullfile(runPath, requested.folder);
    if ~isfolder(sensorPath)
        continue;
    end

    files = dir(fullfile(sensorPath, requested.pattern));
    files = files(~[files.isdir]);
    if isempty(files)
        continue;
    end

    [~, order] = sort({files.name});
    files = files(order);

    for k = 1:numel(files)
        spec = localEmptyStreamSpec();
        if numel(files) == 1
            spec.id = string(requested.id);
        else
            spec.id = string(requested.id) + "-" + k;
        end
        spec.format = string(requested.format);
        spec.folder = string(requested.folder);
        spec.fileName = string(files(k).name);
        spec.filePath = string(fullfile(files(k).folder, files(k).name));
        streamSpecs(end+1) = spec; %#ok<AGROW>
    end
end
end

function data = localLoadStream(spec, options)
% Reader dispatch is selected by cfg.streamSpecs(k).format in the campaign
% loading script.
switch lower(spec.format)
    case "tpc5"
        data = AuxFcn_ReadTPC5_001(spec.filePath, ...
            'DaqId', spec.id, ...
            'UseTriggerTimeZero', options.UseTPC5TriggerTimeZero);

    case "mf4"
        switch lower(options.MF4Reader)
            case "matlab"
                data = AuxFcn_ReadDAQ_MF4_001(spec.filePath, ...
                    'DaqId', spec.id, ...
                    'ChannelGroupIdx', options.MF4ChannelGroupIdx, ...
                    'ConvertToSI', options.ConvertMF4ToSI, ...
                    'ResampleFs', options.MF4ResampleFs);

            case "asammdf"
                data = AuxFcn_ReadDAQ_MF4_ASAMMDF_001(spec.filePath, ...
                    'DaqId', spec.id, ...
                    'ChannelGroupIdx', options.MF4ChannelGroupIdx, ...
                    'ResampleFs', options.MF4ResampleFs, ...
                    'PythonExecutable', options.MF4PythonExecutable);

            otherwise
                error('Unsupported MF4Reader "%s". Use "matlab" or "asammdf".', ...
                    options.MF4Reader);
        end

    case "csv"
        data = AuxFcn_ReadDAQ_CSV_001(spec.filePath, ...
            'DaqId', spec.id, ...
            'TimeZone', options.CSVTimeZone, ...
            'WarnNonUniform', options.CSVWarnNonUniform);

    case "h2txt"
        data = AuxFcn_ReadHydrogenSensorTXT_001(spec.filePath, ...
            'DaqId', spec.id, ...
            'SignalColumns', options.HydrogenSignalColumns);

    otherwise
        error('Unsupported stream format "%s".', spec.format);
end
end

function groups = localBuildGroups(runs)
groupIds = unique(string({runs.groupId}), 'stable');
groups = repmat(struct('id', "", 'runIdx', []), numel(groupIds), 1);
for i = 1:numel(groupIds)
    groups(i).id = groupIds(i);
    groups(i).runIdx = find(string({runs.groupId}) == groupIds(i));
end
end

function runOut = localEmptyRun()
runOut = struct( ...
    'id', "", ...
    'groupId', "", ...
    'runNumber', NaN, ...
    'path', "", ...
    'streams', localEmptyStream());
runOut.streams(:) = [];
end

function stream = localEmptyStream()
stream = struct( ...
    'id', "", ...
    'format', "", ...
    'folder', "", ...
    'fileName', "", ...
    'filePath', "", ...
    'data', [], ...
    'loaded', false, ...
    'status', "", ...
    'loadError', "");
end

function spec = localEmptyStreamSpec()
spec = struct( ...
    'id', "", ...
    'format', "", ...
    'folder', "", ...
    'pattern', "", ...
    'fileName', "", ...
    'filePath', "");
end

function manifest = localEmptyManifest()
manifest = table( ...
    strings(0,1), strings(0,1), zeros(0,1), strings(0,1), ...
    strings(0,1), strings(0,1), strings(0,1), strings(0,1), ...
    false(0,1), strings(0,1), strings(0,1), ...
    'VariableNames', {'RunId','GroupId','RunNumber','StreamId', ...
    'SensorFolder','Format','FileName','FilePath','Loaded','Status','LoadError'});
end

function manifest = localAppendManifest(manifest, runOut, spec, loaded, status, loadError)
row = table( ...
    string(runOut.id), string(runOut.groupId), runOut.runNumber, ...
    string(spec.id), string(spec.folder), string(spec.format), ...
    string(spec.fileName), string(spec.filePath), logical(loaded), ...
    string(status), string(loadError), ...
    'VariableNames', manifest.Properties.VariableNames);
manifest = [manifest; row]; %#ok<AGROW>
end
