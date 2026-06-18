function groupData = AuxFcn_LoadCampaignGroup_001(rootDir, groupId, options)
% AuxFcn_LoadCampaignGroup_001
% Load one campaign group into a clean, config-driven hierarchy.
%
% Here "stream" means one raw data source inside a run folder, e.g. one DAQ
% file, one H2BGA file, or one hydrogen sensor file. The function does not
% assume specific names such as DAQ_1, H2BGA, or HS. The output structure
% follows StreamSpecs.
%
% Optional StreamSpecs fields used by this wrapper:
%   outputPath             : dot path for loaded data, e.g. "DAQ_1" or
%                            "Hydrogen_Sensors.Sensor_1"
%   requiredChannelPattern : warning pattern for overview status, e.g. "conc"
%
% Example:
%   groupData = AuxFcn_LoadCampaignGroup_001(rawRoot, "02", ...
%       GroupNamePrefix=cfg.groupNamePrefix, ...
%       RunPattern=cfg.runPattern, ...
%       StreamSpecs=cfg.streamSpecs, ...
%       MF4Reader="asammdf");
%
% Access:
%   runFields = fieldnames(groupData.runs);
%   runData = groupData.runs.(runFields{1});
%   runData.DAQ_1.t
%   runData.DAQ_2_3.signal

arguments
    rootDir (1,1) string
    groupId (1,1) string
    options.GroupNamePrefix (1,1) string = ""
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
    options.MF4Reader (1,1) string = "asammdf"
    options.MF4ChannelGroupIdx (1,1) double = 1
    options.MF4ResampleFs (1,1) double = 0
    options.MF4PythonExecutable (1,1) string = ""
    options.CSVWarnNonUniform (1,1) logical = false
    options.HydrogenSignalColumns string = "Output (%)"
    options.SaveMat (1,1) logical = false
    options.OutputDir (1,1) string = ""
end

% First load the selected raw runs into a flat run/stream representation.
campaign = AuxFcn_LoadCampaignRuns_001(rootDir, ...
    Groups=groupId, ...
    RunPattern=options.RunPattern, ...
    RunIdPattern=options.RunIdPattern, ...
    GroupTokenIdx=options.GroupTokenIdx, ...
    RunNumberTokenIdx=options.RunNumberTokenIdx, ...
    RunNumbers=options.RunNumbers, ...
    StreamSpecs=options.StreamSpecs, ...
    LoadData=options.LoadData, ...
    MaxRuns=options.MaxRuns, ...
    SkipFormats=options.SkipFormats, ...
    WarnOnLoadError=options.WarnOnLoadError, ...
    MF4Reader=options.MF4Reader, ...
    MF4ChannelGroupIdx=options.MF4ChannelGroupIdx, ...
    MF4ResampleFs=options.MF4ResampleFs, ...
    MF4PythonExecutable=options.MF4PythonExecutable, ...
    CSVWarnNonUniform=options.CSVWarnNonUniform, ...
    HydrogenSignalColumns=options.HydrogenSignalColumns);

groupData = struct();
groupData.id = options.GroupNamePrefix + groupId;
groupData.runs = struct();

for iRun = 1:numel(campaign.runs)
    campaignRun = campaign.runs(iRun);

    runOut = localEmptyRun();
    runOut.id = campaignRun.id;

    % Then place each loaded source into the user-facing hierarchy requested
    % by StreamSpecs.outputPath, e.g. DAQ_1 or HS.D_2.
    for iStream = 1:numel(campaignRun.streams)
        stream = campaignRun.streams(iStream);
        outputPath = localOutputPath(stream.id, options.StreamSpecs);
        streamData = localStreamToRaw(stream);
        runOut = localSetNestedField(runOut, outputPath, streamData);
    end

    runField = localRunFieldName(campaignRun.id);
    groupData.runs.(runField) = runOut;
end

groupData.overview = localBuildOverview(campaign.runs, options.StreamSpecs);

if options.SaveMat
    % Optional group-level cache. The main campaign loader normally writes
    % one campaign-level MAT file instead.
    outputDir = options.OutputDir;
    if strlength(outputDir) == 0
        outputDir = fullfile(fileparts(fileparts(string(rootDir))), "ConvertedData");
    end
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end
    matFile = fullfile(outputDir, groupData.id + ".mat");
    save(matFile, "groupData", "-v7.3");
end

end

function runOut = localEmptyRun()
runOut = struct('id', "");
end

function streamData = localStreamToRaw(stream)
streamData = struct();
streamData.t = [];
streamData.t_units = "s";
streamData.signal = [];
streamData.channels = strings(0,1);
streamData.units = strings(0,1);

if stream.loaded && ~isempty(stream.data)
    streamData.t = stream.data.t;
    streamData.signal = stream.data.signal;

    if isfield(stream.data, 'channelNames')
        streamData.channels = stream.data.channelNames;
    end
    if isfield(stream.data, 'units')
        streamData.units = stream.data.units;
    end
end
end

function outputPath = localOutputPath(streamId, streamSpecs)
streamId = string(streamId);
outputPath = string(localStreamFieldName(streamId));

if isempty(streamSpecs)
    return
end

specIdx = localFindSpecIndex(streamId, streamSpecs);
if isnan(specIdx)
    return
end

if isfield(streamSpecs, 'outputPath')
    configuredPath = string(streamSpecs(specIdx).outputPath);
    if strlength(configuredPath) > 0
        outputPath = configuredPath;
    end
end
end

function specIdx = localFindSpecIndex(streamId, streamSpecs)
streamIds = string({streamSpecs.id});
specIdx = find(streamIds == streamId, 1, "first");

if isempty(specIdx)
    baseStreamId = regexprep(streamId, "-\\d+$", "");
    specIdx = find(streamIds == baseStreamId, 1, "first");
end

if isempty(specIdx)
    specIdx = NaN;
end
end

function value = localSetNestedField(value, outputPath, streamData)
parts = split(string(outputPath), ".");
parts = parts(strlength(parts) > 0);

if isempty(parts)
    return
end

fieldName = char(matlab.lang.makeValidName(parts(1)));

if numel(parts) == 1
    value.(fieldName) = streamData;
    return
end

if ~isfield(value, fieldName) || ~isstruct(value.(fieldName))
    value.(fieldName) = struct();
end

remainingPath = strjoin(parts(2:end), ".");
value.(fieldName) = localSetNestedField(value.(fieldName), remainingPath, streamData);
end

function overview = localBuildOverview(campaignRuns, streamSpecs)
nRuns = numel(campaignRuns);

runId = strings(nRuns, 1);
runField = strings(nRuns, 1);
for iRun = 1:nRuns
    runId(iRun) = campaignRuns(iRun).id;
    runField(iRun) = string(localRunFieldName(campaignRuns(iRun).id));
end

overview = table(runId, runField, 'VariableNames', {'RunId','RunField'});

for iSpec = 1:numel(streamSpecs)
    outputPath = localSpecOutputPath(streamSpecs(iSpec));
    prefix = string(matlab.lang.makeValidName(strrep(outputPath, ".", "_")));

    samples = zeros(nRuns, 1);
    channels = zeros(nRuns, 1);
    fsHz = NaN(nRuns, 1);
    dt_s = NaN(nRuns, 1);
    status = strings(nRuns, 1);

    for iRun = 1:nRuns
        stream = localFindRunStream(campaignRuns(iRun), streamSpecs(iSpec).id);
        if isempty(stream)
            status(iRun) = "missing_file";
            continue
        end

        status(iRun) = localStreamOverviewStatus(stream, streamSpecs(iSpec));
        if stream.loaded && ~isempty(stream.data)
            samples(iRun) = localDataSamples(stream.data);
            channels(iRun) = localDataChannels(stream.data);
            fsHz(iRun) = localDataSamplingRate(stream.data);
            dt_s(iRun) = localDataSampleTime(stream.data);
        end
    end

    overview.(char(prefix + "_Samples")) = samples;
    overview.(char(prefix + "_Channels")) = channels;
    overview.(char(prefix + "_Fs_Hz")) = fsHz;
    overview.(char(prefix + "_Dt_s")) = dt_s;
    overview.(char(prefix + "_Status")) = status;
end
end

function outputPath = localSpecOutputPath(spec)
if isfield(spec, 'outputPath') && strlength(string(spec.outputPath)) > 0
    outputPath = string(spec.outputPath);
else
    outputPath = string(localStreamFieldName(spec.id));
end
end

function stream = localFindRunStream(campaignRun, specId)
stream = [];
specId = string(specId);

for iStream = 1:numel(campaignRun.streams)
    streamId = string(campaignRun.streams(iStream).id);
    if streamId == specId || regexprep(streamId, "-\\d+$", "") == specId
        stream = campaignRun.streams(iStream);
        return
    end
end
end

function status = localStreamOverviewStatus(stream, spec)
status = string(stream.status);

if ~stream.loaded || isempty(stream.data)
    if strlength(status) == 0
        status = "not_loaded";
    end
    return
end

if isfield(spec, 'requiredChannelPattern')
    pattern = string(spec.requiredChannelPattern);
    if strlength(pattern) > 0 && ~localHasChannelPattern(stream.data, pattern)
        status = "WARNING_missing_required_channel";
    end
end
end

function tf = localHasChannelPattern(data, pattern)
tf = false;

if ~isfield(data, 'channelNames') || isempty(data.channelNames)
    return
end

tf = any(contains(lower(string(data.channelNames)), lower(pattern)));
end

function nSamples = localDataSamples(data)
if isfield(data, 'nSamples') && ~isempty(data.nSamples)
    nSamples = double(data.nSamples);
elseif isfield(data, 'signal') && ~isempty(data.signal)
    nSamples = size(data.signal, 1);
else
    nSamples = 0;
end
end

function nChannels = localDataChannels(data)
if isfield(data, 'nChannels') && ~isempty(data.nChannels)
    nChannels = double(data.nChannels);
elseif isfield(data, 'signal') && ~isempty(data.signal)
    nChannels = size(data.signal, 2);
else
    nChannels = 0;
end
end

function fsHz = localDataSamplingRate(data)
fsHz = localScalarField(data, 'fs');
if isfinite(fsHz) && fsHz > 0
    return
end

dt_s = localDataSampleTime(data);
if isfinite(dt_s) && dt_s > 0
    fsHz = 1 / dt_s;
end
end

function dt_s = localDataSampleTime(data)
dt_s = localScalarField(data, 'dt');
if isfinite(dt_s) && dt_s > 0
    return
end

if ~isfield(data, 't') || numel(data.t) < 2
    return
end

dtVec = diff(double(data.t(:)));
dtVec = dtVec(isfinite(dtVec) & dtVec > 0);
if isempty(dtVec)
    return
end

dt_s = mean(dtVec, 'omitnan');
end

function value = localScalarField(data, fieldName)
value = NaN;

if ~isfield(data, fieldName) || isempty(data.(fieldName))
    return
end

fieldValue = double(data.(fieldName));
fieldValue = fieldValue(isfinite(fieldValue));
if ~isempty(fieldValue)
    value = fieldValue(1);
end
end

function fieldName = localStreamFieldName(streamId)
fieldName = char(matlab.lang.makeValidName(strrep(string(streamId), "-", "_")));
end

function runField = localRunFieldName(runId)
runField = char(matlab.lang.makeValidName(strrep(string(runId), "-", "_")));
end
