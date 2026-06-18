%% Load VH2D Wk22 raw campaign data into one clean struct
% Workspace result:
%   campaigns
%
% Hierarchy:
%   campaigns.(campaignField).groups.(groupField).runs.(runField).DAQ_1.t
%   campaigns.(campaignField).groups.(groupField).runs.(runField).DAQ_1.signal
%   campaigns.(campaignField).groups.(groupField).runs.(runField).DAQ_2_3.signal
%   campaigns.(campaignField).groups.(groupField).runs.(runField).DAQ_4.signal
%   campaigns.(campaignField).groups.(groupField).runs.(runField).H2CM.signal
%   campaigns.(campaignField).groups.(groupField).runs.(runField).Hydrogen_Sensors.Sensor_1.signal
%   campaigns.(campaignField).groups.(groupField).runs.(runField).Hydrogen_Sensors.Sensor_2.signal

clear; clc;

cfg = struct();
cfg.campaignName = "VH2D_Wk22";
cfg.rawFolderName = replace(cfg.campaignName, "_", "-");
cfg.selectedGroups = ["02","03","04"];
cfg.groupFieldPrefix = "Group_";
cfg.groupNamePrefix = cfg.rawFolderName + "-";
cfg.runPattern = cfg.rawFolderName + "-*-*";
cfg.cacheVersion = "raw_load_h2txt_auto_header_v1";

% Reader map used by AuxFcn_LoadCampaignRuns_001.
% StreamSpecs.format selects one of these readers.
cfg.readerMap = table( ...
    ["tpc5"; "mf4"; "csv"; "h2txt"], ...
    ["AuxFcn_ReadTPC5_001"; ...
     "AuxFcn_ReadDAQ_MF4_ASAMMDF_001"; ...
     "AuxFcn_ReadDAQ_CSV_001"; ...
     "AuxFcn_ReadHydrogenSensorTXT_001"], ...
    ["TPC5/HDF5 reader"; ...
     "MF4 reader via Python asammdf"; ...
     "semicolon CSV reader"; ...
     "hydrogen sensor TXT reader"], ...
    'VariableNames', {'Format','ReaderFunction','Description'});

% Load complete groups.
maxRuns = Inf;

% Cache the loaded campaign so future analysis reloads fast from MAT.
useCachedMat = true;
saveCampaignMat = true;

% Optional: save one MAT file per group in 2-Data/ConvertedData.
saveGroupMat = false;

projectRoot = fileparts(fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))));
auxRoot = fullfile(projectRoot, ...
    "3-Calculations-Files", "Matlab-Files", "Auxilliary_Functions");
rawRoot = fullfile(projectRoot, ...
    "2-Data", "RawData", cfg.rawFolderName);
convertedRoot = fullfile(projectRoot, ...
    "2-Data", "ConvertedData");
convertedCampaignRoot = fullfile(convertedRoot, cfg.rawFolderName);

selectedGroupTag = strjoin(cfg.selectedGroups, "_");
campaignMatFile = fullfile(convertedCampaignRoot, ...
    cfg.campaignName + "_Groups_" + selectedGroupTag + ".mat");

addpath(genpath(auxRoot));

if useCachedMat && isfile(campaignMatFile)
    cachedData = load(campaignMatFile);
    cacheIsCompatible = isfield(cachedData, "campaigns") && ...
        isfield(cachedData, "cacheInfo") && ...
        isfield(cachedData.cacheInfo, "version") && ...
        string(cachedData.cacheInfo.version) == cfg.cacheVersion;

    if cacheIsCompatible
        campaigns = cachedData.campaigns;
        fprintf("Loaded cached campaign MAT: %s\n", campaignMatFile);
        clearvars -except campaigns
        return
    end

    fprintf("Ignoring old campaign MAT cache, rebuilding: %s\n", campaignMatFile);
end

cfg.streamSpecs = struct( ...
    'id',                     {"DAQ-1", "DAQ-2-3", "DAQ-4", "H2CM", "Hydrogen-Sensor-1",       "Hydrogen-Sensor-2"}, ...
    'folder',                 {"DAQ-1", "DAQ-2-3", "DAQ-4", "H2CM", "Hydrogen-Sensors",       "Hydrogen-Sensors"}, ...
    'pattern',                {"*.tpc5","*.mf4",   "*.mf4","*.csv","*-D2.txt",                "*-D3.txt"}, ...
    'format',                 {"tpc5",  "mf4",     "mf4",  "csv",  "h2txt",                  "h2txt"}, ...
    'outputPath',             {"DAQ_1", "DAQ_2_3", "DAQ_4", "H2CM", "Hydrogen_Sensors.Sensor_1", "Hydrogen_Sensors.Sensor_2"}, ...
    'requiredChannelPattern', {"",      "",        "",     "conc", "",                       ""});

campaigns = struct();
campaignField = matlab.lang.makeValidName(cfg.campaignName);
campaigns.(campaignField).id = cfg.campaignName;

disp("Reader dispatch map:");
disp(cfg.readerMap);

for iGroup = 1:numel(cfg.selectedGroups)
    selectedGroup = cfg.selectedGroups(iGroup);
    groupField = cfg.groupFieldPrefix + selectedGroup;

    groupData = AuxFcn_LoadCampaignGroup_001(rawRoot, selectedGroup, ...
        GroupNamePrefix=cfg.groupNamePrefix, ...
        RunPattern=cfg.runPattern, ...
        StreamSpecs=cfg.streamSpecs, ...
        LoadData=true, ...
        MaxRuns=maxRuns, ...
        MF4Reader="asammdf", ...
        CSVWarnNonUniform=false, ...
        HydrogenSignalColumns="Output (%)", ...
        SaveMat=saveGroupMat, ...
        OutputDir=convertedCampaignRoot);

    campaigns.(campaignField).groups.(groupField) = groupData;

    runFields = fieldnames(campaigns.(campaignField).groups.(groupField).runs);
    fprintf("Loaded group: %s | Runs in memory: %d\n", ...
        campaigns.(campaignField).groups.(groupField).id, numel(runFields));
    disp(campaigns.(campaignField).groups.(groupField).overview);

    if ~isempty(runFields)
        runField = runFields{1};
        firstRun = campaigns.(campaignField).groups.(groupField).runs.(runField);
        fprintf("First run field: %s | DAQ_2_3 channels: %d\n", ...
            runField, size(firstRun.DAQ_2_3.signal, 2));
        disp(table(firstRun.DAQ_2_3.channels(:), firstRun.DAQ_2_3.units(:), ...
            'VariableNames', {'DAQ_2_3_Channel','Unit'}));
    end
end

if saveCampaignMat
    if ~isfolder(convertedCampaignRoot)
        mkdir(convertedCampaignRoot);
    end
    cacheInfo = struct();
    cacheInfo.version = cfg.cacheVersion;
    cacheInfo.createdAt = datetime("now");
    cacheInfo.config = cfg;
    save(campaignMatFile, "campaigns", "cacheInfo", "-v7.3");
    fprintf("Saved campaign MAT: %s\n", campaignMatFile);
end

% Keep the workspace clean.
clearvars -except campaigns
