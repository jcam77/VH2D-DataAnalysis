# VH2D Pressure/Trigger Initial Crop Helper

`AuxFcn_CropVH2DPressureTriggerSignals_001.m` creates a pressure-preprocessed
campaign layer by cropping only the configured pressure/trigger DAQ streams.

The full campaign structure is preserved. Concentration streams remain inside
the structure but are not cropped.

## Main Idea

Input:

```matlab
offsetCorrected = AuxFcn_RemoveVH2DPressureOffset_001(aligned, ...
    BaselineWindow_s=[-0.050, -0.005]);
```

Initial crop:

```matlab
pressurePreprocessed = AuxFcn_CropVH2DPressureTriggerSignals_001( ...
    offsetCorrected, ...
    CropWindow_s=[-0.050, Inf], ...
    StreamFields=["DAQ_1","DAQ_2_3","DAQ_4"]);
```

## Method

Only streams listed in `StreamFields` are cropped. For the current VH2D raw
campaign workflow, these are:

- `DAQ_1`
- `DAQ_2_3`
- `DAQ_4`

These streams contain the pressure and trigger signals used for pressure
analysis.

The crop keeps:

```text
t_s >= -50 ms
```

and keeps the record until the end:

```matlab
CropWindow_s = [-0.050, Inf];
```

## What Is Not Cropped

Concentration measurements are independent from the pressure trigger and are
not pressure/trigger preprocessed in this step:

- `H2BGA`
- `HS.D_2`
- `HS.D_3`

They are copied unchanged into `pressurePreprocessed` so the folder-like
campaign structure remains complete and easy to navigate.

## Why This Is Not Final Windowing

This crop is an initial cleanup step for pressure/trigger data only. It removes
unneeded pre-trigger history after the baseline offset has already been
calculated.

Final analysis windows should be defined later, because they depend on:

- filtering choices
- quantity of interest
- plotted time interval
- peak/impulse/derivative metrics

## Traceability

The previous layer remains available:

```matlab
offsetCorrected        % full aligned and offset-corrected structure
pressurePreprocessed   % same structure, only DAQ pressure/trigger streams cropped
```

The campaign-level crop overview is:

```matlab
disp(pressurePreprocessed.cropOverview)
```

Important columns:

- `Stream`
- `RootStream`
- `CropStart_s`
- `CropEnd_s`
- `SourceSamples`
- `KeptSamples`
- `RemovedSamples`
- `Status`

Rows with `Status == "cropped"` were cropped. Rows with
`Status == "not_pressure_trigger_preprocessed"` were copied unchanged.
