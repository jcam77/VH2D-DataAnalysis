# VH2D Raw Campaign Loader

`MainFcn_Load_VH2D_RawCampaign_001.m` loads one campaign at a time. You pass the campaign name and the groups you want to load.

## Main Idea

Use the loader function only when you need to generate or rebuild the cached `.mat` file.

```matlab
campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk22", ["02","03","04"]);
```

For a future campaign:

```matlab
campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk27", ["01","02"]);
```

If you generate several campaign caches in the same workspace variable, pass the previous struct back in:

```matlab
campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk22", ["02","03","04"]);
campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk27", ["01","02"], ...
    ExistingCampaigns=campaigns);
```

Without `ExistingCampaigns=campaigns`, the second assignment replaces the workspace variable, because that is normal MATLAB assignment behavior.

For normal analysis, use the faster cached-load workflow:

```matlab
load("2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat")
```

Each call saves one campaign cache separately:

```text
2-Data/ConvertedData/<campaign-raw-folder>/<campaign-name>_Groups_<groups>.mat
```

For Wk22 this is:

```text
2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat
```

The `.mat` file stores the campaign and cache metadata using campaign-specific variable names, not generic `campaigns` or `cacheInfo` variables. For example:

```matlab
load("2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat")
```

creates:

```matlab
VH2D_Wk22
VH2D_Wk22_cacheInfo
```

This avoids overwriting existing workspace variables named `campaigns` or `cacheInfo` when manually loading cached files.

Older cache files that still contain generic `campaigns` or `cacheInfo` variables are migrated automatically the next time they are loaded through `MainFcn_Load_VH2D_RawCampaign_001`.

## Structure

The loaded data follows the campaign/group/run folder idea. If you used the loader function, the root is `campaigns.VH2D_Wk22`. If you used `load(...)` on the cached `.mat` file, the root is directly `VH2D_Wk22`.

```text
campaigns
  .VH2D_Wk22
    .groups
      .Group_02
        .overview
        .runs
          .VH2D_Wk22_02_01
            .DAQ_1
            .DAQ_2_3
            .DAQ_4
            .H2CM
            .Hydrogen_Sensors
              .Sensor_1
              .Sensor_2
```

## Extracting Data

Recommended fast workflow:

```matlab
load("2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat")
```

This creates the variable `VH2D_Wk22`. Then select one campaign, group, and run:

```matlab
campaign = VH2D_Wk22;
group = campaign.groups.Group_02;
run = group.runs.VH2D_Wk22_02_01;
```

If you are working with the function output instead, use:

```matlab
campaign = campaigns.VH2D_Wk22;
```

Each stream has the same basic raw-data shape:

```matlab
run.DAQ_1.t          % time vector [s]
run.DAQ_1.signal     % samples x channels
run.DAQ_1.channels   % channel names
run.DAQ_1.units      % channel units, when available
```

Examples:

```matlab
% DAQ-1 first channel
t = run.DAQ_1.t;
y = run.DAQ_1.signal(:,1);
channelName = run.DAQ_1.channels(1);
unit = run.DAQ_1.units(1);

plot(t, y);
xlabel("Time [s]");
ylabel(channelName + " [" + unit + "]");
grid on;
```

```matlab
% DAQ-2-3 all channels
t = run.DAQ_2_3.t;
Y = run.DAQ_2_3.signal;
channels = run.DAQ_2_3.channels;
```

```matlab
% H2CM raw signal
t_h2cm = run.H2CM.t;
h2cm_raw = run.H2CM.signal;
h2cm_channels = run.H2CM.channels;
```

```matlab
% Hydrogen sensor output percent
t_s1 = run.Hydrogen_Sensors.Sensor_1.t;
h2_s1_pct = run.Hydrogen_Sensors.Sensor_1.signal;

t_s2 = run.Hydrogen_Sensors.Sensor_2.t;
h2_s2_pct = run.Hydrogen_Sensors.Sensor_2.signal;
```

To inspect what runs are available:

```matlab
groupFields = fieldnames(campaign.groups);
runFields = fieldnames(campaign.groups.Group_02.runs);
```

To use the overview table:

```matlab
overview02 = VH2D_Wk22.groups.Group_02.overview;
disp(overview02);
```

The overview is useful for checking sample counts, channel counts, sampling rates, and load status before selecting data for processing.

## Campaign-Specific Details

Most campaigns should work with only:

```matlab
campaigns = MainFcn_Load_VH2D_RawCampaign_001(campaignName, selectedGroups);
```

Optional name-value inputs are available when a future campaign changes folder names or stream layout:

- `rawFolderName`: folder under `2-Data/RawData`, e.g. `VH2D-Wk22`.
- `runPattern`: run-folder discovery pattern.
- `runIdPattern`: regexp used to extract group/run number from folder names.
- `streamSpecs`: folders, file patterns, formats, and output paths.

If a future campaign separates `DAQ-2` and `DAQ-3`, pass a custom `StreamSpecs`:

```matlab
streamSpecs = struct( ...
    'id',         {"DAQ-2", "DAQ-3"}, ...
    'folder',     {"DAQ-2", "DAQ-3"}, ...
    'pattern',    {"*.mf4", "*.mf4"}, ...
    'format',     {"mf4",   "mf4"}, ...
    'outputPath', {"DAQ_2", "DAQ_3"}, ...
    'requiredChannelPattern', {"", ""});

campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk27", ["01","02"], ...
    StreamSpecs=streamSpecs);
```

## Overview Table

Each group has an `overview` table with one row per run. For every configured stream, the table reports:

- `<stream>_Samples`: number of loaded samples.
- `<stream>_Channels`: number of loaded channels.
- `<stream>_Fs_Hz`: sampling rate in Hz.
- `<stream>_Dt_s`: sample interval in seconds.
- `<stream>_Status`: loaded, missing file, failed, or warning status.

For non-uniform streams such as some CSV/H2CM logs, `Fs_Hz` and `Dt_s` are mean estimates from the reader or from the time vector. Use the raw `t` vector for detailed timing checks.

Because this changes the cached overview table shape, `MainFcn_Load_VH2D_RawCampaign_001.m` uses a new `cacheVersion` and rebuilds the `.mat` once.

## Auxiliary Function Chain

```text
MainFcn_Load_VH2D_RawCampaign_001.m
  -> AuxFcn_LoadCampaignGroup_001.m
       -> AuxFcn_LoadCampaignRuns_001.m
            -> AuxFcn_ReadTPC5_001.m
            -> AuxFcn_ReadDAQ_MF4_ASAMMDF_001.m
                 -> AuxPy_ConvertMF4_ASAMMDF_001.py
            -> AuxFcn_ReadDAQ_CSV_001.m
            -> AuxFcn_ReadHydrogenSensorTXT_001.m
```

`AuxFcn_LoadCampaignGroup_001.m` and `AuxFcn_LoadCampaignRuns_001.m` stay generic. The campaign script decides the folder names, run naming convention, and stream formats.

## Raw-Only Rule

This loader only loads raw stream data. It does not synchronize time vectors, resample data, align sensors, filter data, or convert H2CM ppm to vol.%. Those steps should remain explicit in later processing scripts.
