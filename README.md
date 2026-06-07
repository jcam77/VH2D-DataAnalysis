# VH2D-DataAnalysis
Vented Hydrogen Deflagration Data Analysis

## Raw Campaign Loading

Use the main MATLAB function once to generate/rebuild the cached `.mat` file:

```matlab
campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk22", ["02","03","04"]);
```

The default stream layout currently expected by the loader is:

```matlab
streamSpecs = struct( ...
    'id',                     {"DAQ-1", "DAQ-2-3", "DAQ-4", "H2BGA", "HS-D2", "HS-D3"}, ...
    'folder',                 {"DAQ-1", "DAQ-2-3", "DAQ-4", "H2BGA", "H2S",   "H2S"}, ...
    'pattern',                {"*.tpc5","*.mf4",   "*.mf4", "*.csv", "*-D2.txt", "*-D3.txt"}, ...
    'format',                 {"tpc5",  "mf4",     "mf4",   "csv",  "h2txt",    "h2txt"}, ...
    'outputPath',             {"DAQ_1", "DAQ_2_3", "DAQ_4", "H2BGA","HS.D_2",   "HS.D_3"}, ...
    'requiredChannelPattern', {"",      "",        "",      "conc", "",         ""});
```

This means `DAQ-2-3` is still loaded as one combined stream. If a future
campaign separates `DAQ-2` and `DAQ-3`, pass a custom `StreamSpecs` at the
function call instead of changing the loader internals.

Abbreviations: `H2BGA` means Hydrogen Binary Gas Analyser measurements, and
`HS` means Hydrogen Sensors.

The function is located at:

```text
3-Calculations-Files/Matlab-Files/Main_Functions/EMP2X-Project/MainFcn_Load_VH2D_RawCampaign_001.m
```

For normal analysis, load the cached `.mat` file directly because it is faster:

```matlab
load("2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat")
```

Each campaign cache is saved separately in:

```text
2-Data/ConvertedData/<campaign-folder>/<campaign-name>_Groups_<groups>.mat
```

The cached `.mat` file stores the campaign and cache metadata using campaign-specific variable names, not generic `campaigns` or `cacheInfo` variables. For example, loading:

```matlab
load("2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat")
```

creates:

```matlab
VH2D_Wk22
VH2D_Wk22_cacheInfo
```

This avoids overwriting existing workspace variables named `campaigns` or `cacheInfo`.

Older cache files that still contain generic `campaigns` or `cacheInfo` variables are migrated automatically the next time they are loaded through `MainFcn_Load_VH2D_RawCampaign_001`.

Basic extraction example:

```matlab
campaign = VH2D_Wk22;
group = campaign.groups.Group_02;
run = group.runs.VH2D_Wk22_02_01;

t = run.DAQ_1.t;
y = run.DAQ_1.signal(:,1);
plot(t, y);
```

## Unit Conversion Layer

Raw loaded data is not modified. Unit conversion is handled by a dedicated
auxiliary function:

```matlab
converted = AuxFcn_ConvertVH2DUnits_001(VH2D_Wk22);
```

Details are documented in:

```text
3-Calculations-Files/Matlab-Files/Auxilliary_Functions/EMP2X-Project/README_AuxFcn_ConvertVH2DUnits_001.md
```

## Time-Vector Alignment Layer

After unit conversion, build a separate trigger-aligned layer:

```matlab
aligned = AuxFcn_AlignVH2DTimeVectors_001(converted, ...
    TriggerThreshold_V=4, ...
    ReferenceStreams="DAQ_1", ...
    AlignStreams=["DAQ_2_3","DAQ_4"]);
```

Details are documented in:

```text
3-Calculations-Files/Matlab-Files/Auxilliary_Functions/EMP2X-Project/README_AuxFcn_AlignVH2DTimeVectors_001.md
```

More extraction examples are documented in:

```text
3-Calculations-Files/Matlab-Files/Main_Functions/EMP2X-Project/README_MainFcn_Load_VH2D_RawCampaign_001.md
```

Campaign metadata JSON files are stored in:

```text
2-Data/RawData/VH2D-Wk22/Metadata
```

Use `AuxFcn_LoadVH2DMetadata_001` to read the full JSON metadata, then use `AuxFcn_BuildVH2DRawReportTables_001` to display small report-friendly tables. The complete metadata remains available internally, but the DPP should show focused summaries such as raw load status, run plan, gas mixing, DAQ systems, sensor mapping, and group notes.
