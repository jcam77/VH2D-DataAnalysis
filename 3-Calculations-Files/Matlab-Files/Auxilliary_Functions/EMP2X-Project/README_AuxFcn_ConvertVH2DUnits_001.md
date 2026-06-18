# VH2D Unit Conversion Helper

`AuxFcn_ConvertVH2DUnits_001.m` builds a unit-converted campaign structure
without modifying the raw loaded data.

## Main Idea

Keep the raw campaign untouched:

```matlab
VH2D_Wk22.groups.Group_02.runs.VH2D_Wk22_02_01.DAQ_4.signal
```

Create a separate converted layer:

```matlab
converted = AuxFcn_ConvertVH2DUnits_001(VH2D_Wk22);
```

Then use:

```matlab
runConv = converted.groups.Group_02.runs.VH2D_Wk22_02_01;
```

## Structure

The converted structure mirrors the raw campaign/group/run structure:

```text
converted
  .groups
    .Group_02
      .runs
        .VH2D_Wk22_02_01
          .DAQ_1
          .DAQ_2_3
          .DAQ_4
          .H2BGA
          .HS
            .D_2
            .D_3
```

Each converted stream contains:

```matlab
runConv.DAQ_4.t_s          % time vector [s]
runConv.DAQ_4.signal       % converted signal matrix
runConv.DAQ_4.channels     % original raw channel names
runConv.DAQ_4.rawUnits     % units reported directly by the reader
runConv.DAQ_4.sourceUnits  % units from raw file
runConv.DAQ_4.units        % converted/target units
runConv.DAQ_4.conversion   % conversion evidence table
```

## Conversion Rules

The function converts from explicit evidence:

- reader-provided raw units, when available
- MF4/asammdf units exported by `AuxPy_ConvertMF4_ASAMMDF_001.py`
- unit labels embedded in raw channel names, e.g. `DAQ-2-Channel1 [bar]`
- known DAQ-level units for `H2BGA`, where raw CSV values are treated as `ppm`

Current conversion rules:

- `bar` -> `kPa`
- `mbar` -> `kPa`
- `Pa` -> `kPa`
- `ppm` -> `vol.%`
- `mV` -> `V`
- `%` concentration output is relabeled as `vol.%` with no numeric change.
- `kPa`, `V`, and `s` are kept unchanged.

Unknown units are copied unchanged and flagged in:

```matlab
converted.overview
```

## DAQs Notes

- DAQ pressure channels are converted to `kPa` when their source unit is pressure.
- If MF4/asammdf does not expose units for a DAQ, raw pressure channels are assumed `bar` and trigger/voltage channels are assumed `V`; this assumption is recorded in `SourceUnitEvidence`.
- Trigger channels remain in `V`.
- `H2BGA` means Hydrogen Binary Gas Analyser measurements; raw H2BGA values are converted from `ppm` to `vol.%`.
- `HS` means Hydrogen Sensors; their `%` output is numerically copied unchanged and labeled as `vol.%`.

## Example

```matlab
converted = AuxFcn_ConvertVH2DUnits_001(VH2D_Wk22);

runConv = converted.groups.Group_02.runs.VH2D_Wk22_02_01;

t = runConv.DAQ_4.t_s;
y = runConv.DAQ_4.signal(:,1);
channelName = runConv.DAQ_4.channels(1);
unit = runConv.DAQ_4.units(1);

plot(t, y);
xlabel("Time [s]");
ylabel(channelName + " [" + unit + "]");
grid on;
```

## Traceability

Use the conversion table to verify what happened:

```matlab
disp(runConv.DAQ_4.conversion)
disp(converted.overview)
```

This table records the source unit, target unit, conversion factor, status,
and rule for every converted channel.
