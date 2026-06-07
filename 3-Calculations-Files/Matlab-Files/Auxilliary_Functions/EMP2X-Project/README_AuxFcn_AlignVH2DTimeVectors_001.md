# VH2D Time-Vector Alignment Helper

`AuxFcn_AlignVH2DTimeVectors_001.m` builds a trigger-aligned campaign
structure without modifying the unit-converted input data.

## Main Idea

Input:

```matlab
converted = AuxFcn_ConvertVH2DUnits_001(VH2D_Wk22);
```

Alignment:

```matlab
aligned = AuxFcn_AlignVH2DTimeVectors_001(converted, ...
    TriggerThreshold_V=4, ...
    ReferenceStreams="DAQ_1", ...
    AlignStreams=["DAQ_2_3","DAQ_4"]);
```

## Alignment Rule

- `DAQ_1` is treated as already zero-aligned and is kept unchanged.
- `DAQ_2_3` and `DAQ_4` are shifted so the first 4 V trigger crossing becomes `t = 0 s`.
- Time samples before the trigger become negative.
- The original time vector is preserved as `source_t_s`.
- The aligned time vector is stored as `t_s`.

## Trigger Channel Detection

Trigger columns are not selected by fixed column position. The helper searches
per stream using:

- channel names containing `trigger`
- channel names containing `voltage`
- converted channel units equal to `V`

If multiple trigger candidates are found, the first candidate is used and the
status is recorded in the overview table.

## Structure

The aligned structure mirrors the converted campaign/group/run structure:

```text
aligned
  .groups
    .Group_02
      .runs
        .VH2D_Wk22_02_01
          .DAQ_1
          .DAQ_2_3
          .DAQ_4
```

Each aligned stream keeps:

```matlab
runAligned.DAQ_4.source_t_s      % original converted time vector
runAligned.DAQ_4.t_s             % aligned time vector
runAligned.DAQ_4.signal          % same converted signal values
runAligned.DAQ_4.alignment       % alignment metadata
```

## Evidence Table

Use:

```matlab
disp(aligned.alignmentOverview)
```

Important columns:

- `TriggerColumn`
- `TriggerChannel`
- `TriggerTime_source_s`
- `AppliedShift_s`
- `Status`

This table documents exactly which channel defined the time shift for each
stream and run.
