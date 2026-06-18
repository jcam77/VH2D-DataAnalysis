# VH2D Pressure and Trigger Signal Preprocessing Helper

`AuxFcn_PreprocVH2DPressureTriggerSignals_001.m` creates a
pressure-preprocessed campaign layer by applying a preliminary temporal window
only to configured pressure/trigger DAQs.

The full campaign structure is preserved. Concentration data remain inside
the structure but are not pressure/trigger preprocessed.

## Main Idea

Input:

```matlab
offsetCorrected = AuxFcn_RemoveVH2DPressureOffset_001(aligned, ...
    BaselineWindow_s=[-0.050, -0.005]);
```

Pressure/trigger preprocessing:

```matlab
pressurePreprocessed = AuxFcn_PreprocVH2DPressureTriggerSignals_001( ...
    offsetCorrected, ...
    PreprocWindow_s=[-0.050, Inf], ...
    DAQs=["DAQ_1","DAQ_2_3","DAQ_4"]);
```

## Method

Only DAQs listed in `DAQs` are pressure/trigger preprocessed. For
the current VH2D raw campaign workflow, these are:

- `DAQ_1`
- `DAQ_2_3`
- `DAQ_4`

These DAQs contain the pressure and trigger signals used for pressure
analysis.

The preprocessing window keeps samples satisfying:

```text
t_s >= -50 ms
```

and keeps the record until the selected end time:

```matlab
PreprocWindow_s = [-0.050, Inf];
```

In the current report workflow this may be restricted, for example:

```matlab
PreprocWindow_s = [-0.050, 1.75];
```

This is a preliminary data-size reduction and organization step. It is not the
final analysis window.

## What Is Not Pressure/Trigger Preprocessed

Concentration measurements are independent from the pressure trigger and are
not pressure/trigger preprocessed in this step:

- `H2BGA`
- `HS.D_2`
- `HS.D_3`

They are copied unchanged into `pressurePreprocessed` so the folder-like
campaign structure remains complete and easy to navigate.

## Why This Is Not Final Windowing

This preprocessing step reduces unneeded pre-trigger history after baseline
offset correction has already been calculated.

Final analysis windows should be defined later because they depend on:

- filtering choices
- quantity of interest
- plotted time interval
- peak/impulse/derivative metrics

## Traceability

The previous layer remains available:

```matlab
offsetCorrected        % full aligned and offset-corrected structure
pressurePreprocessed   % same structure, only pressure/trigger DAQs windowed
```

Each preprocessed DAQ stores:

```matlab
DAQ.preproc
```

The campaign-level preprocessing overview is:

```matlab
disp(pressurePreprocessed.preprocOverview)
```

Important columns:

- `DAQs`
- `RootDAQs`
- `PreprocStart_s`
- `PreprocEnd_s`
- `SourceSamples`
- `KeptSamples`
- `RemovedSamples`
- `Status`

Rows with `Status == "preprocessed"` were pressure/trigger preprocessed. Rows
with `Status == "not_pressure_trigger_preprocessed"` were copied unchanged.
