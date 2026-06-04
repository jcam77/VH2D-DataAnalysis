function campaigns = MainFcn_Load_VH2D_RawCampaign_001(campaignName, selectedGroups, options)
% MainFcn_Load_VH2D_RawCampaign_001
% Load one VH2D raw campaign and selected groups.
%
% Example:
%   campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk22", ["02","03","04"]);
%   campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk27", ["01","02"], ...
%       ExistingCampaigns=campaigns);
%
% Result:
%   campaigns.VH2D_Wk22.groups.Group_02.runs.VH2D_Wk22_02_01.DAQ_1.t
%
% The loader keeps raw streams as raw streams. It does not synchronize,
% resample, filter, or convert units for downstream processing.

arguments
    campaignName (1,1) string
    selectedGroups string
    options.ProjectRoot (1,1) string = ""
    options.RawFolderName (1,1) string = ""
    options.ConvertedFolderName (1,1) string = ""
    options.StreamSpecs = []
    options.ExistingCampaigns = struct()
    options.MaxRuns (1,1) double = Inf
    options.UseCachedMat (1,1) logical = true
    options.SaveCampaignMat (1,1) logical = true
    options.SaveGroupMat (1,1) logical = false
    options.GroupFieldPrefix (1,1) string = "Group_"
    options.GroupNamePrefix (1,1) string = ""
    options.RunPattern (1,1) string = ""
    options.RunIdPattern (1,1) string = "^(.+)-(\d+)-(\d+)$"
    options.GroupTokenIdx (1,1) double = 2
    options.RunNumberTokenIdx (1,1) double = 3
    options.CacheVersion (1,1) string = "raw_load_overview_sampling_v1"
    options.MF4Reader (1,1) string = "asammdf"
    options.MF4ChannelGroupIdx (1,1) double = 1
    options.MF4ResampleFs (1,1) double = 0
    options.MF4PythonExecutable (1,1) string = ""
    options.CSVWarnNonUniform (1,1) logical = false
    options.HydrogenSignalColumns string = "Output (%)"
    options.SkipFormats string = strings(0,1)
end

projectRoot = options.ProjectRoot;
if strlength(projectRoot) == 0
    projectRoot = localProjectRoot();
end

rawFolderName = options.RawFolderName;
if strlength(rawFolderName) == 0
    rawFolderName = replace(campaignName, "_", "-");
end

convertedFolderName = options.ConvertedFolderName;
if strlength(convertedFolderName) == 0
    convertedFolderName = rawFolderName;
end

runPattern = options.RunPattern;
if strlength(runPattern) == 0
    runPattern = rawFolderName + "-*-*";
end

groupNamePrefix = options.GroupNamePrefix;
if strlength(groupNamePrefix) == 0
    groupNamePrefix = rawFolderName + "-";
end

streamSpecs = options.StreamSpecs;
if isempty(streamSpecs)
    streamSpecs = localDefaultVH2DStreamSpecs();
end

auxRoot = fullfile(projectRoot, ...
    "3-Calculations-Files", "Matlab-Files", "Auxilliary_Functions");
rawRoot = fullfile(projectRoot, "2-Data", "RawData", rawFolderName);
convertedCampaignRoot = fullfile(projectRoot, ...
    "2-Data", "ConvertedData", convertedFolderName);

addpath(genpath(auxRoot));

campaignField = matlab.lang.makeValidName(campaignName);
campaignMatFile = fullfile(convertedCampaignRoot, ...
    campaignName + "_Groups_" + strjoin(string(selectedGroups), "_") + ".mat");

if options.UseCachedMat && isfile(campaignMatFile)
    cachedData = load(campaignMatFile);
    cachedCacheInfo = localCacheInfoFromCache(cachedData, campaignField);
    cacheIsCompatible = isfield(cachedCacheInfo, "version") && ...
        string(cachedCacheInfo.version) == options.CacheVersion;

    if cacheIsCompatible
        loadedCampaigns = localCampaignsFromCache(cachedData, campaignField);
        if isfield(cachedData, "campaigns") || isfield(cachedData, "cacheInfo")
            localSaveNamedCampaignCache(campaignMatFile, campaignField, ...
                loadedCampaigns.(campaignField), cachedCacheInfo);
            fprintf("Migrated cached MAT to campaign-named variables: %s\n", ...
                campaignMatFile);
        end
        campaigns = localMergeCampaign(options.ExistingCampaigns, ...
            loadedCampaigns, campaignField);
        fprintf("Loaded cached campaign MAT: %s\n", campaignMatFile);
        return
    end

    fprintf("Ignoring old campaign MAT cache, rebuilding: %s\n", campaignMatFile);
end

readerMap = localReaderMap(options.MF4Reader);
disp("Reader dispatch map:");
disp(readerMap);

campaigns = options.ExistingCampaigns;
campaigns.(campaignField).id = campaignName;
campaigns.(campaignField).groups = struct();

for iGroup = 1:numel(selectedGroups)
    groupId = string(selectedGroups(iGroup));
    groupField = options.GroupFieldPrefix + groupId;

    groupData = AuxFcn_LoadCampaignGroup_001(rawRoot, groupId, ...
        GroupNamePrefix=groupNamePrefix, ...
        RunPattern=runPattern, ...
        RunIdPattern=options.RunIdPattern, ...
        GroupTokenIdx=options.GroupTokenIdx, ...
        RunNumberTokenIdx=options.RunNumberTokenIdx, ...
        StreamSpecs=streamSpecs, ...
        LoadData=true, ...
        MaxRuns=options.MaxRuns, ...
        SkipFormats=options.SkipFormats, ...
        MF4Reader=options.MF4Reader, ...
        MF4ChannelGroupIdx=options.MF4ChannelGroupIdx, ...
        MF4ResampleFs=options.MF4ResampleFs, ...
        MF4PythonExecutable=options.MF4PythonExecutable, ...
        CSVWarnNonUniform=options.CSVWarnNonUniform, ...
        HydrogenSignalColumns=options.HydrogenSignalColumns, ...
        SaveMat=options.SaveGroupMat, ...
        OutputDir=convertedCampaignRoot);

    campaigns.(campaignField).groups.(groupField) = groupData;

    runFields = fieldnames(campaigns.(campaignField).groups.(groupField).runs);
    fprintf("Loaded campaign: %s | group: %s | runs in memory: %d\n", ...
        campaignName, groupData.id, numel(runFields));
    disp(campaigns.(campaignField).groups.(groupField).overview);
end

if options.SaveCampaignMat
    if ~isfolder(convertedCampaignRoot)
        mkdir(convertedCampaignRoot);
    end

    cacheInfo = struct();
    cacheInfo.version = options.CacheVersion;
    cacheInfo.createdAt = datetime("now");
    cacheInfo.campaignName = campaignName;
    cacheInfo.selectedGroups = string(selectedGroups);
    cacheInfo.rawFolderName = rawFolderName;
    cacheInfo.streamSpecs = streamSpecs;
    cacheInfo.readerMap = readerMap;

    localSaveNamedCampaignCache(campaignMatFile, campaignField, ...
        campaigns.(campaignField), cacheInfo);
    fprintf("Saved campaign MAT: %s\n", campaignMatFile);
end
end

function localSaveNamedCampaignCache(campaignMatFile, campaignField, campaignData, cacheInfo)
campaignCache = struct();
campaignCache.(campaignField) = campaignData;
cacheInfoField = campaignField + "_cacheInfo";
campaignCache.(cacheInfoField) = cacheInfo;
save(campaignMatFile, "-struct", "campaignCache", "-v7.3");
end

function cacheInfo = localCacheInfoFromCache(cachedData, campaignField)
cacheInfoField = campaignField + "_cacheInfo";

if isfield(cachedData, cacheInfoField)
    cacheInfo = cachedData.(cacheInfoField);
    return
end

if isfield(cachedData, "cacheInfo")
    cacheInfo = cachedData.cacheInfo;
    return
end

cacheInfo = struct();
end

function loadedCampaigns = localCampaignsFromCache(cachedData, campaignField)
loadedCampaigns = struct();

if isfield(cachedData, campaignField)
    loadedCampaigns.(campaignField) = cachedData.(campaignField);
    return
end

if isfield(cachedData, "campaigns") && isfield(cachedData.campaigns, campaignField)
    loadedCampaigns.(campaignField) = cachedData.campaigns.(campaignField);
    return
end

error('Cached MAT file does not contain campaign "%s".', campaignField);
end

function campaigns = localMergeCampaign(existingCampaigns, loadedCampaigns, campaignField)
campaigns = existingCampaigns;
campaigns.(campaignField) = loadedCampaigns.(campaignField);
end

function projectRoot = localProjectRoot()
scriptRoot = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(fileparts(fileparts(scriptRoot))));
end

function streamSpecs = localDefaultVH2DStreamSpecs()
streamSpecs = struct( ...
    'id',                     {"DAQ-1", "DAQ-2-3", "DAQ-4", "H2CM", "Hydrogen-Sensor-1",       "Hydrogen-Sensor-2"}, ...
    'folder',                 {"DAQ-1", "DAQ-2-3", "DAQ-4", "H2CM", "Hydrogen-Sensors",       "Hydrogen-Sensors"}, ...
    'pattern',                {"*.tpc5","*.mf4",   "*.mf4","*.csv","*-D2.txt",                "*-D3.txt"}, ...
    'format',                 {"tpc5",  "mf4",     "mf4",  "csv",  "h2txt",                  "h2txt"}, ...
    'outputPath',             {"DAQ_1", "DAQ_2_3", "DAQ_4", "H2CM", "Hydrogen_Sensors.Sensor_1", "Hydrogen_Sensors.Sensor_2"}, ...
    'requiredChannelPattern', {"",      "",        "",     "conc", "",                       ""});
end

function readerMap = localReaderMap(mf4Reader)
if lower(string(mf4Reader)) == "asammdf"
    mf4Function = "AuxFcn_ReadDAQ_MF4_ASAMMDF_001";
    mf4Description = "MF4 reader via Python asammdf";
else
    mf4Function = "AuxFcn_ReadDAQ_MF4_001";
    mf4Description = "MATLAB MF4/MDF reader";
end

readerMap = table( ...
    ["tpc5"; "mf4"; "csv"; "h2txt"], ...
    ["AuxFcn_ReadTPC5_001"; ...
     mf4Function; ...
     "AuxFcn_ReadDAQ_CSV_001"; ...
     "AuxFcn_ReadHydrogenSensorTXT_001"], ...
    ["TPC5/HDF5 reader"; ...
     mf4Description; ...
     "semicolon CSV reader"; ...
     "hydrogen sensor TXT reader"], ...
    'VariableNames', {'Format','ReaderFunction','Description'});
end
