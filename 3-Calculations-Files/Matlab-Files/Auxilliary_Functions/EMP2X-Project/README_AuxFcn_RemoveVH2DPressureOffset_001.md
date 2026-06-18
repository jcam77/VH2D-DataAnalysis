# VH2D Pressure DC-Offset Removal Helper

`AuxFcn_RemoveVH2DPressureOffset_001.m` removes the background/DC offset from
pressure channels only. It does not modify trigger voltage or hydrogen
concentration channels.

## Main Idea

Input:

```matlab
aligned = AuxFcn_AlignVH2DTimeVectors_001(converted, ...
    TriggerZeroThreshold_V=4, ...
    DAQsAlreadyAligned=strings(0,1), ...
    DAQsToAlign=["DAQ_1","DAQ_2_3","DAQ_4"]);
```

Offset correction:

```matlab
offsetCorrected = AuxFcn_RemoveVH2DPressureOffset_001(aligned, ...
    BaselineWindow_s=[-0.050, -0.005]);
```

For lower memory use in report scripts:

```matlab
offsetCorrected = AuxFcn_RemoveVH2DPressureOffset_001(aligned, ...
    BaselineWindow_s=[-0.050, -0.005], ...
    KeepSourceSignal=false);
```

## Method

For each channel, the function checks the converted unit:

- `kPa`: pressure channel, offset correction is applied.
- anything else: copied unchanged.

This means:

- pressure channels are corrected
- trigger voltage channels are not touched
- `H2BGA` concentration channels are not touched
- `HS` concentration channels are not touched

## Baseline Window

The default baseline window is:

```text
-50 ms to -5 ms before trigger
```

or:

```matlab
BaselineWindow_s = [-0.050, -0.005];
```

The window stops at `-5 ms`, not exactly `0 s`, to avoid including trigger-edge
or electrical switching disturbance in the baseline estimate.

## Baseline Calculation

For each pressure channel:

```matlab
idx = t_s >= -0.050 & t_s <= -0.005;
baseline_kPa = mean(y_kPa(idx), "omitnan");
y_corrected_kPa = y_kPa - baseline_kPa;
```

The signal values are updated only in the new `offsetCorrected` structure.
The input `aligned` structure remains unchanged.

## Traceability

Each corrected stream stores:

```matlab
runOffset.DAQ_4.signal             % offset-corrected signal
runOffset.DAQ_4.offsetCorrection   % per-channel correction table
```

If `KeepSourceSignal=true`, each corrected stream also stores:

```matlab
runOffset.DAQ_4.source_signal      % signal before offset correction
```

For large DAQ matrices, `KeepSourceSignal=false` is recommended after the
workflow has been verified because it avoids keeping a second copy of every
large signal matrix.

The campaign-level overview is:

```matlab
disp(offsetCorrected.offsetOverview)
```

The overview keeps every channel that was inspected. Pressure channels show
`Status == "offset_removed"`, while trigger and concentration channels remain
visible with `Status == "not_offset_corrected"`.

Important columns:

- `Channel`
- `Unit`
- `BaselineWindowStart_s`
- `BaselineWindowEnd_s`
- `BaselineMean_kPa`
- `BaselineStd_kPa`
- `BaselineSamples`
- `Status`

Only rows with `Status == "offset_removed"` were corrected.
