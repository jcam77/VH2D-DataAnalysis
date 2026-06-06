# VH2D Wk22 Raw Campaign Loader

This note explains how `Load_VH2D_Wk22_RawCampaign_001.m` loads raw campaign data and how it connects to the auxiliary functions.

## Purpose

The loader builds a raw-data structure that resembles the folder hierarchy:

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
```

The loader is intended for raw loading only. It does not synchronize streams, resample data, align time vectors, or convert H2CM ppm to vol.%. Those steps should be handled later in processing scripts.

## Main Script

Main script:

```matlab
Load_VH2D_Wk22_RawCampaign_001.m
```

The script defines a campaign-specific `cfg` block:

```matlab
cfg.campaignName
cfg.rawFolderName
cfg.selectedGroups
cfg.groupFieldPrefix
cfg.groupNamePrefix
cfg.runPattern
cfg.streamSpecs
cfg.cacheVersion
```

For a different campaign, the main changes should be made in this config block, not in the auxiliary functions.

## Stream Configuration

`cfg.streamSpecs` tells the loader what to look for and where to place it in the output structure.

Required fields:

```matlab
id          % logical stream ID
folder      % folder inside each run
pattern     % file pattern inside the folder
format      % reader type: tpc5, mf4, csv, h2txt
```

The `format` field is the key that selects the reader function. The main script declares this map in `cfg.readerMap`:

| `format` | Reader function |
|---|---|
| `tpc5` | `AuxFcn_ReadTPC5_001.m` |
| `mf4` | `AuxFcn_ReadDAQ_MF4_ASAMMDF_001.m` when `MF4Reader="asammdf"` |
| `csv` | `AuxFcn_ReadDAQ_CSV_001.m` |
| `h2txt` | `AuxFcn_ReadHydrogenSensorTXT_001.m` |

`AuxFcn_ReadDAQ_MF4_ASAMMDF_001.m` then calls:

```text
AuxPy_ConvertMF4_ASAMMDF_001.py
```

The alternate MATLAB MF4 reader is:

```text
AuxFcn_ReadDAQ_MF4_001.m
```

It is used only if `MF4Reader="matlab"` and the required MATLAB MDF support is installed.

Optional fields used by `AuxFcn_LoadCampaignGroup_001`:

```matlab
outputPath              % output field path, e.g. "DAQ_2_3" or "Hydrogen_Sensors.Sensor_1"
requiredChannelPattern  % overview warning if expected channel is missing, e.g. "conc"
```

Example if a future campaign separates DAQ-2 and DAQ-3:

```matlab
cfg.streamSpecs = struct( ...
    'id',         {"DAQ-2", "DAQ-3"}, ...
    'folder',     {"DAQ-2", "DAQ-3"}, ...
    'pattern',    {"*.mf4", "*.mf4"}, ...
    'format',     {"mf4",   "mf4"}, ...
    'outputPath', {"DAQ_2", "DAQ_3"}, ...
    'requiredChannelPattern', {"", ""});
```

No auxiliary-function changes should be needed for that structure change.

## Auxiliary Function Chain

The raw loading chain is:

```text
Load_VH2D_Wk22_RawCampaign_001.m
  -> AuxFcn_LoadCampaignGroup_001.m
       -> AuxFcn_LoadCampaignRuns_001.m
            -> AuxFcn_ReadTPC5_001.m
            -> AuxFcn_ReadDAQ_MF4_ASAMMDF_001.m
                 -> AuxPy_ConvertMF4_ASAMMDF_001.py
            -> AuxFcn_ReadDAQ_CSV_001.m
            -> AuxFcn_ReadHydrogenSensorTXT_001.m
```

## Overview Table

Each group has an `overview` table with one row per run. For every configured stream, the table reports:

- `<stream>_Samples`: number of loaded samples.
- `<stream>_Channels`: number of loaded channels.
- `<stream>_Fs_Hz`: sampling rate in Hz.
- `<stream>_Dt_s`: sample interval in seconds.
- `<stream>_Status`: loaded, missing file, failed, or warning status.

For non-uniform streams such as some CSV/H2CM logs, `Fs_Hz` and `Dt_s` are mean estimates from the reader or from the time vector. Use the raw `t` vector for detailed timing checks.

## Function Roles

### `Load_VH2D_Wk22_RawCampaign_001.m`

Defines campaign-specific configuration, selected groups, cache behavior, and calls the group loader.

### `AuxFcn_LoadCampaignGroup_001.m`

Builds the clean group-level output structure:

```matlab
groupData.id
groupData.overview
groupData.runs.(runField).<configured stream output>
```

This function is config-driven. It should not contain campaign-specific stream assumptions.

### `AuxFcn_LoadCampaignRuns_001.m`

Discovers run folders and stream files, then calls the correct reader based on `format`.

`StreamSpecs` must be provided. This avoids hidden hardcoded campaign assumptions.

### Reader functions

Each reader returns raw stream data with a common shape:

```matlab
t          % local stream time vector, seconds
signal     % raw signal matrix
channels   % channel names
units      % units when available
```

## Time Vectors

All loaded time vectors are local stream time vectors in seconds:

- TPC5: seconds from TPC5 sample timing, currently trigger-aligned.
- MF4: seconds from asammdf export with `time_from_zero=true`.
- CSV/H2CM: seconds from first timestamp in the CSV file.
- Hydrogen sensor TXT: seconds from first time-of-day value in the TXT file.

These time vectors are not synchronized to a shared campaign clock. Synchronization should happen in a later processing stage.

## Units and Raw Values

The loader preserves raw stream values:

- `DAQ_*`: raw/physical values from the reader, with units when available.
- `H2CM`: raw CSV channel values in `signal`; no ppm-to-vol.% conversion is done during loading.
- `Hydrogen_Sensors`: raw selected TXT signal, currently `Output (%)`, stored as `signal`.

Conversions such as:

```matlab
H2CM_vol_pct = H2CM_ppm / 10000;
```

should be done explicitly in processing scripts.

## Cache File

Raw loading can be slow. The script saves a cached `.mat` file after the first successful load:

```text
2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat
```

The cache contains:

```matlab
VH2D_Wk22
VH2D_Wk22_cacheInfo
```

The campaign and cache metadata are saved using campaign-specific variable names instead of the generic names `campaigns` and `cacheInfo`. This prevents manual `load(...)` calls from overwriting existing workspace variables named `campaigns` or `cacheInfo`.

Older cache files that still contain generic `campaigns` or `cacheInfo` variables are migrated automatically the next time they are loaded through `MainFcn_Load_VH2D_RawCampaign_001`.

The campaign-specific cache info `version` is checked before loading. If the loader structure changes, the old cache is ignored and rebuilt.

To force a rebuild:

```matlab
useCachedMat = false;
```

## Recommended Workflow

1. Edit the `cfg` block for the campaign.
2. Run `Load_VH2D_Wk22_RawCampaign_001.m`.
3. Check `overview` tables for missing files or warnings.
4. Use the cached `.mat` for future analysis.
5. Do synchronization, filtering, resampling, unit conversion, and derived calculations in separate processing scripts.
