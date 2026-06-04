# VH2D-DataAnalysis
Vented Hydrogen Deflagration Data Analysis

## Raw Campaign Loading

Use the main MATLAB function once to generate/rebuild the cached `.mat` file:

```matlab
campaigns = MainFcn_Load_VH2D_RawCampaign_001("VH2D_Wk22", ["02","03","04"]);
```

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

More extraction examples are documented in:

```text
3-Calculations-Files/Matlab-Files/Main_Functions/EMP2X-Project/README_MainFcn_Load_VH2D_RawCampaign_001.md
```
