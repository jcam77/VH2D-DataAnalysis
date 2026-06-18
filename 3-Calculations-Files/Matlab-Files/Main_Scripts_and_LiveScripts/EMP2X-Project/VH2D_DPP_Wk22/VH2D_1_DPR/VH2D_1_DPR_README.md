# VH2D DPR — Data Preparation

This folder contains the first stage of the VH2D Data Processing Procedure
(DPP): **Data Preparation (DPR)**.

The DPR stage prepares the raw campaign data so later EDA and DPA scripts can
load a clean, traceable MATLAB data artifact instead of repeating expensive raw
data loading and preprocessing.

## Main Script

- `VH2D_1_DPR_v001_live.m`

This script is currently called from:

- `../VH2D_DPP_Master_v001_live.m`

The frozen reference file for this workflow is:

- `../VH2D_DPP_v004_live.m`

Do not edit the reference file unless intentionally creating a new reference
version.

## Current DPR Workflow

The script currently performs these steps:

1. **MATLAB setup**
   - Clears the workspace.
   - Adds auxiliary and main-function folders to the MATLAB path.
   - Defines plotting colors and figure naming convention.

2. **Raw campaign loading**
   - Loads the cached raw campaign MAT file:
     - `2-Data/ConvertedData/VH2D-Wk22/VH2D_Wk22_Groups_02_03_04.mat`
   - Assigns the campaign structure to `campaign`.

3. **Metadata loading**
   - Loads JSON metadata from:
     - `2-Data/RawData/VH2D-Wk22/Metadata`
   - Builds compact report/overview tables.

4. **Raw data overview and audit**
   - Raw data load status table.
   - Channel audit table comparing loaded channels against sensor-mapping
     metadata.
   - Run plan, gas mixing, DAQ systems, sensor mapping, and group/run notes.

5. **Unit conversion**
   - Pressure channels are converted to `kPa`.
   - Concentration channels are converted or relabeled to `vol.%` where
     applicable.
   - Conversion evidence is stored in overview tables.

6. **Time-vector alignment**
   - Pressure/trigger DAQs are aligned using the first trigger crossing at
     `4 V`.
   - Signal values are not changed during alignment; only time vectors are
     shifted.

7. **Pressure DC-offset removal**
   - Only pressure channels with unit `kPa` are corrected.
   - The baseline mean is estimated from `[-0.050, -0.005] s`.
   - Trigger and concentration channels are not offset-corrected.

8. **Pressure and trigger preprocessing**
   - Keeps a preliminary analysis interval of `[-0.050, 1.75] s`.
   - This reduces memory and plotting cost.
   - Concentration streams are currently copied through unchanged.

9. **Export DPR artifact**
   - Saves the prepared structure as:
     - `2-Data/CleanData/VH2D-Wk22/DPR_VH2D_Wk22_Groups_02_03_04.mat`

## Current Output

The main exported variable is:

```matlab
DPR_VH2D_Wk22_Groups_02_03_04
```

At the moment this variable is assigned from:

```matlab
pressurePreprocessed
```

Later, after concentration preprocessing is completed, this output should be
updated to include both:

- pressure/trigger prepared data
- concentration prepared data

## Not Yet Completed

The concentration preprocessing section is intentionally still under
construction. It should later define how to extract and store representative
hydrogen concentration information from:

- `H2BGA`
- `HS.D_2`
- `HS.D_3`

## Design Rule

The DPR stage should be the only stage that performs heavy raw-data preparation.
Later stages should load the saved DPR MAT file and avoid recomputing:

- raw campaign loading
- metadata parsing
- unit conversion
- trigger alignment
- pressure offset removal
- preliminary pressure/trigger preprocessing

This keeps EDA and DPA scripts lighter, faster, and easier to review.
