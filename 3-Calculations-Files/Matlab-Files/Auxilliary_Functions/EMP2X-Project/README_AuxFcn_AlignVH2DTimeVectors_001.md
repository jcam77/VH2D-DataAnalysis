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

## Method

The method is applied independently to each selected stream in each run.

### 1. Select the Trigger Signal

For each stream, the function first identifies the trigger channel using the
rules in the next section. No fixed column number is assumed.

Let:

```matlab
t = stream.t_s;
y = trigger signal;
V_trigger = 4;
```

### 2. Find the First Threshold Crossing

The trigger time is defined as the first time where the trigger signal reaches
or exceeds the threshold:

```matlab
y >= 4 V
```

The first crossing sample is:

```matlab
i = find(y >= 4, 1, "first");
```

The method does not require a sample with exactly `4.000 V`. In sampled data,
the signal will usually jump from a value below 4 V to a value above 4 V
between two samples. Therefore, the function searches for the first sample
above the threshold and then estimates the crossing time between samples.

This is intentionally different from:

```matlab
y == 4
```

because exact equality is unreliable for sampled analog signals.

### 3. Interpolate the Trigger Time

If the crossing is not at the first sample, the function linearly interpolates
between the sample before the crossing and the first sample above the
threshold.

Using:

```matlab
t0 = t(i-1);
t1 = t(i);
y0 = y(i-1);
y1 = y(i);
```

the trigger time is:

```matlab
t_trigger = t0 + (4 - y0) * (t1 - t0) / (y1 - y0);
```

This gives a more precise trigger time than simply using the first sample
above 4 V.

Example:

```text
t0 = 0.120000 s, y0 = 3.7 V
t1 = 0.120005 s, y1 = 4.3 V
```

There is no exact `4.000 V` sample, but the signal crossed 4 V between these
two samples. The interpolation estimates that crossing time and uses it as
the zero-time reference.

### 4. Shift the Time Vector

For streams selected in `AlignStreams`, the aligned time vector is:

```matlab
t_aligned = t_original - t_trigger;
```

Therefore:

- samples before trigger have negative time
- the trigger crossing occurs at approximately `t = 0 s`
- samples after trigger have positive time

### 5. Preserve the Original Time Vector

The original time vector is not deleted:

```matlab
stream.source_t_s = t_original;
stream.t_s = t_aligned;
```

For `DAQ_1`, no shift is applied by default:

```matlab
stream.source_t_s = stream.t_s;
stream.t_s = stream.t_s;
```

because `DAQ_1` is treated as already trigger-zero aligned.

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
