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
    TriggerZeroThreshold_V=4, ...
    DAQsAlreadyAligned=strings(0,1), ...
    DAQsToAlign=["DAQ_1","DAQ_2_3","DAQ_4"]);
```

## Alignment Rule

- The trigger-zero voltage threshold is selected outside the function using `TriggerZeroThreshold_V`.
- DAQs listed in `DAQsAlreadyAligned` are treated as already zero-aligned and are kept unchanged. Use `strings(0,1)` when no DAQ should be kept unchanged.
- DAQs listed in `DAQsToAlign` are shifted so the first trigger threshold crossing becomes `t = 0 s`.
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

For DAQs selected in `DAQsToAlign`, the aligned time vector is:

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

For DAQs selected in `DAQsAlreadyAligned`, no shift is applied:

```matlab
stream.source_t_s = stream.t_s;
stream.t_s = stream.t_s;
```

This is intended for DAQs where the recorded time vector is already aligned to
the trigger zero time.

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

Each aligned DAQ keeps:

```matlab
runAligned.DAQ_4.source_t_s      % original converted time vector
runAligned.DAQ_4.t_s             % aligned time vector
runAligned.DAQ_4.signal          % same converted signal values
runAligned.DAQ_4.alignment       % alignment metadata
```

## Evidence Table

Use:

```matlab
disp(aligned.alignmentSummaryDisplayTable)
```

Important columns:

- `TriggerColumn`
- `TriggerChannel`
- `TriggerTime_source_s`
- `AppliedShift_s`
- `TriggerVoltageAtOriginalZeroTime_V`
- `TriggerVoltageAtAlignedZeroTime_V`
- `Status`

This table documents exactly which channel defined the time shift for each
DAQ and run.

`TriggerVoltageAtOriginalZeroTime_V` is the independent check: it evaluates
the trigger voltage at the original time vector zero before any shift is
applied.

`TriggerVoltageAtAlignedZeroTime_V` evaluates the trigger voltage at the final
aligned zero time. For DAQs shifted by this helper, this value should be close
to `TriggerZeroThreshold_V` by construction.

The full numeric table is also preserved:

```matlab
aligned.alignmentOverview
```
