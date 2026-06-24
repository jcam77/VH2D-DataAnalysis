# Codex Prompt: MATLAB Workflow for Pressure Sensors Verification (PSV)

Generate a MATLAB workflow for extracting and analysing pressure-sensor verification data from measurement files.

The MATLAB workflow will be used for:

**Vented Hydrogen Deflagration Experiments — Pressure Sensors Verification (PSV)**

The code should be suitable for MATLAB `.mlx` live-script reporting and for modular `.m` function development.

---

## 1. Context

I am performing an operating-range verification of piezoelectric pressure sensors used in vented hydrogen deflagration experiments.

The original calibration certificates cover larger pressure ranges, for example 2 bar and 5 bar. However, the measured peak overpressures in the experiments are expected to remain within the lower part of the sensor range. Therefore, an additional operating-range verification is performed over:

$$
FS_{\mathrm{ver}} = 0.5~\mathrm{bar}
$$

The verification range is:

$$
0 \leq P \leq 0.5~\mathrm{bar}
$$

The main verification objectives are:

1. **Linearity estimation**
2. **Hysteresis estimation**
3. **Repeatability estimation**
4. **Baseline stability / zero-drift assessment**

---

## 2. Important metrological note

This verification is **not intended to replace the original calibration certificate** and must **not** be treated as a new accredited calibration.

Do not estimate or replace the official certificate sensitivity unless this is explicitly requested later.

The certificate sensitivity is retained for pressure conversion. The verification is used to quantify the behaviour of the measurement chain within the operating range relevant to the experiments and to support the uncertainty budget for peak overpressure measurements.

The workflow must keep the following stages separate:

1. Raw data extraction
2. Certificate-based pressure conversion
3. BFSL-based operating-range non-linearity estimation
4. Hysteresis estimation
5. Repeatability estimation
6. Baseline drift / zero stability assessment
7. Optional diagnostic checks

Do **not** silently fit a new slope and use it as a replacement calibration sensitivity.

---

## 3. Measurement sets

The verification is divided into two measurement sets to avoid mixing different uncertainty effects.

### Set 1 — Linearity and hysteresis

Set 1 is used to evaluate operating-range non-linearity and hysteresis.

Six verification pressure levels are selected over the verification range, including the lower and upper limits and four internal pressure levels. The sequence consists of one increasing-pressure series and one decreasing-pressure series.

The verification-point IDs use the prefix `VP` to avoid confusion with pressure-sensor IDs such as `P1`, `P2`, etc. The IDs are simple sequence identifiers from `VP01` to `VP12`. The pressure direction is stored in a separate column. Hysteresis pairing is performed by matching the same nominal pressure level in the `up` and `down` directions.

#### Set 1 pressure-point list

| Verification point ID | Pressure | %FS_ver | Direction | Purpose |
|---|---:|---:|---|---|
| VP01 | 0.000 bar | 0% | zero | Initial zero / baseline check |
| VP02 | 0.050 bar | 10% | up | Increasing-pressure response |
| VP03 | 0.125 bar | 25% | up | Increasing-pressure response |
| VP04 | 0.250 bar | 50% | up | Increasing-pressure response |
| VP05 | 0.375 bar | 75% | up | Increasing-pressure response |
| VP06 | 0.500 bar | 100% | up | Upper verification limit |
| VP07 | 0.500 bar | 100% | down | Upper turning-point / start of decreasing-pressure series |
| VP08 | 0.375 bar | 75% | down | Decreasing-pressure response |
| VP09 | 0.250 bar | 50% | down | Decreasing-pressure response |
| VP10 | 0.125 bar | 25% | down | Decreasing-pressure response |
| VP11 | 0.050 bar | 10% | down | Decreasing-pressure response |
| VP12 | 0.000 bar | 0% | zero check | Final zero / baseline drift check |

Use Set 1 to calculate:

- operating-range non-linearity,
- hysteresis,
- start/end zero drift,
- residual statistics,
- BFSL diagnostic metrics.

For hysteresis, pair readings by matching the same nominal pressure level where both `up` and `down` measurements exist. The zero points (`VP01` and `VP12`) should be treated as baseline-drift checks rather than as hysteresis points.

### Set 2 — Repeatability and baseline stability

Set 2 is used to evaluate repeatability and baseline stability.

Repeatability is evaluated from repeated measurements at:

$$
P = 0.250~\mathrm{bar}
$$

which corresponds to:

$$
50\%FS_{\mathrm{ver}}
$$

Zero-pressure readings are repeated separately to assess baseline drift, particularly for sensor configurations with short time constants where the zero signal may drift rapidly. Therefore, repeated zero readings are treated primarily as a zero-drift diagnostic rather than pure repeatability.

#### Set 2 pressure-point list

| Step | Pressure | %FS_ver | Purpose |
|---:|---:|---:|---|
| R1 | 0.000 bar | 0% | Baseline drift / zero stability check |
| R2 | 0.000 bar | 0% | Baseline drift / zero stability check |
| R3 | 0.000 bar | 0% | Baseline drift / zero stability check |
| R4 | 0.250 bar | 50% | Repeatability measurement |
| R5 | 0.250 bar | 50% | Repeatability measurement |
| R6 | 0.250 bar | 50% | Repeatability measurement |

If measurement time allows, add an optional upper-range repeatability check at:

$$
P = 0.500~\mathrm{bar}
$$

#### Optional Set 2 upper-range repeatability point

| Step | Pressure | %FS_ver | Purpose |
|---:|---:|---:|---|
| R7 | 0.500 bar | 100% | Optional upper-range repeatability |
| R8 | 0.500 bar | 100% | Optional upper-range repeatability |
| R9 | 0.500 bar | 100% | Optional upper-range repeatability |

---

## 4. Required MATLAB files/functions

Create modular MATLAB code with at least the following files:

- `main_PSV_workflow.m`
- `loadMeasurementFile.m`
- `readMf4File.m`
- `readTpc5File.m`
- `readCsvMeasurementFile.m`
- `selectChannels.m`
- `defineVerificationSequence.m`
- `interactiveWindowSelector.m`
- `extractWindowStatistics.m`
- `convertSignalToPressure.m`
- `calculateBFSLLinearity.m`
- `calculateLinearityResidualStandardError.m`
- `calculateHysteresis.m`
- `calculateRepeatability.m`
- `calculateBaselineDrift.m`
- `groupRepeatedPressurePoints.m`
- `plotPSVResults.m`
- `savePSVResults.m`
- `generateSyntheticPSVData.m`

The code should be readable, traceable, and robust. Prioritize a clear MATLAB workflow over a complex GUI.

---

## 5. Input files

The workflow must support:

- `.mf4`
- `.tpc5`
- `.csv`

### File-reading requirements

For `.mf4`, use MATLAB-supported MDF tools if available, such as:

- `mdf`
- `mdfread`
- `mdfDatastore`

depending on MATLAB version compatibility.

For `.tpc5`, do **not** assume MATLAB has native support. Create a wrapper function called:

```matlab
readTpc5File.m
```

If direct `.tpc5` reading is not possible, the wrapper should fail gracefully and explain that the user must provide one of the following:

- a vendor SDK reader,
- a vendor-exported CSV file,
- or a custom TPC5 import function.

The workflow should also support CSV import as a fallback because `.tpc5` data may need to be exported externally before analysis.

---

## 6. General workflow

### 6.1 File selection

Allow the user to select one or more `.mf4`, `.tpc5`, or `.csv` files.

Display available channel names.

Let the user select:

- sensor output channel,
- optional reference pressure channel,
- optional trigger/step/command channel,
- optional sensor ID/channel metadata.

Do not hard-code channel names.

### 6.2 Data structure

Convert loaded data into a consistent MATLAB `timetable` or `table` with:

- time vector,
- selected channels,
- source filename,
- channel names,
- units if available.

### 6.3 Plotting and signal inspection

Plot selected channels versus time.

The plot should support:

- zooming,
- panning,
- grid,
- labelled axes,
- clear legends.

If multiple channels are selected, plot them together using either dual y-axes or normalized display, but keep raw data unchanged.

### 6.4 Interactive time-window selection

Implement an interactive selector where the user manually selects stable time windows corresponding to pressure plateaus.

The user should be able to define each window by:

- clicking start and end times,
- or using interactive regions/rectangles.

For each selected window, ask the user for:

- unique verification point ID, e.g. `VP01`, `VP02`, ..., `VP12`,
- measurement set: `Set1` or `Set2`,
- nominal pressure in bar,
- direction: `up`, `down`, `zero`, `zero_check`, `repeatability`, or `unknown`,
- sensor ID,
- comment/notes.

Store:

- source filename,
- start time,
- end time,
- selected channels,
- assigned nominal/reference pressure,
- direction,
- measurement set,
- verification point ID,
- comment.

### 6.5 Window trimming

Include an option to trim the selected window before statistics are computed.

Default:

```matlab
trimFractionStart = 0.10;
trimFractionEnd   = 0.10;
```

This avoids including transient rise and decay regions near pressure changes.

---

## 7. Extracted point statistics

For every selected time window and selected channel, calculate:

- mean,
- standard deviation,
- minimum,
- maximum,
- median,
- MAD,
- number of samples,
- start time,
- end time,
- effective trimmed start time,
- effective trimmed end time.

Save these as raw extracted verification-point statistics.

---

## 8. Certificate-based pressure conversion

Add a configuration structure where the user can define, per sensor:

- sensor ID,
- certificate sensitivity `S_cert`,
- sensitivity unit, for example:
  - `pC/bar`,
  - `mV/bar`,
  - `V/bar`,
  - `bar` if already converted,
- amplifier gain `G_amp`, optional,
- DAQ gain, optional,
- zero offset method:
  - selected zero-pressure window,
  - manually entered zero value,
  - first zero window,
  - no zero subtraction if the signal is already pressure.

The indicated/observed pressure must be calculated using the certificate sensitivity, not a newly fitted sensitivity.

General form:

```matlab
P_obs = (mean_signal - zero_offset) / conversion_factor;
```

where `conversion_factor` is based on the certificate sensitivity and gain settings.

If the selected signal is already in bar:

```matlab
P_obs = mean_signal;
```

Make this conversion modular in:

```matlab
convertSignalToPressure.m
```

because the real signal units may differ between sensors and files.

---

## 9. Reference pressure

For each selected window, define the reference pressure as either:

- the mean of a selected reference-pressure channel over the same window,
- or the manually entered nominal/target pressure.

Store a flag:

```matlab
reference_source = "measured_reference_channel";
```

or:

```matlab
reference_source = "manual_target_pressure";
```

---

## 10. Linearity estimation

### 10.1 Definition

The pressure-sensor operating-range non-linearity is evaluated from the verification data as the maximum absolute deviation between the observed pressure response and a least-squares best-fit straight line (BFSL) over the 0–0.5 bar verification range.

The result must be reported as a percentage of the verification full-scale range:

$$
FS_{\mathrm{ver}} = 0.5~\mathrm{bar}
$$

### 10.2 BFSL fit

For each sensor, fit:

$$
P_{\mathrm{fit},i} = a + bP_{\mathrm{ref},i}
$$

where:

- \(P_{\mathrm{ref},i}\) is the reference pressure at point \(i\),
- \(P_{\mathrm{obs},i}\) is the observed pressure response obtained using certificate-based pressure conversion,
- \(a\) is the BFSL intercept,
- \(b\) is the BFSL slope.

In MATLAB, implement:

```matlab
coeff = polyfit(P_ref, P_obs, 1);
b = coeff(1);
a = coeff(2);
P_fit = polyval(coeff, P_ref);
```

### 10.3 Linearity residuals

Calculate the residual relative to the BFSL:

$$
r_{\mathrm{lin},i}
=
P_{\mathrm{obs},i}
-
P_{\mathrm{fit},i}
$$

In MATLAB:

```matlab
r_lin = P_obs - P_fit;
```

### 10.4 Maximum departure from BFSL

Calculate:

$$
\delta_{\mathrm{lin}}
=
\max_i
\left|
r_{\mathrm{lin},i}
\right|
$$

In MATLAB:

```matlab
delta_lin = max(abs(r_lin));
```

### 10.5 Linearity as percentage of verification full scale

Calculate:

$$
L_{\mathrm{lin}}(\%FS_{\mathrm{ver}})
=
\frac{\delta_{\mathrm{lin}}}{FS_{\mathrm{ver}}}
\times 100
$$

In MATLAB:

```matlab
linearity_percent_FS_verification = delta_lin / FS_verification * 100;
```

### 10.6 Standard uncertainty from non-linearity

Following the NIST gauge-study approach for non-linearity, treat the maximum departure from BFSL as a bounded systematic effect.

Assuming a rectangular distribution:

$$
u_{\mathrm{lin}}
=
\frac{\delta_{\mathrm{lin}}}{\sqrt{3}}
$$

In MATLAB:

```matlab
u_linearity = delta_lin / sqrt(3);
u_linearity_percent_FS_verification = u_linearity / FS_verification * 100;
```

### 10.7 Residual standard error as diagnostic only

Also calculate the residual standard error of the fitted line:

$$
s_{\mathrm{BFSL}}
=
\sqrt{
\frac{
\sum_{i=1}^{n}
\left(
P_{\mathrm{obs},i}
-
P_{\mathrm{fit},i}
\right)^2
}{
n-2
}
}
$$

This is a diagnostic measure of scatter around the fitted line. It must **not** be used as the primary linearity uncertainty component.

In MATLAB:

```matlab
n = numel(P_obs);
s_BFSL = sqrt(sum((P_obs - P_fit).^2) / (n - 2));
```

### 10.8 Important implementation warning

Do not call the BFSL slope a new calibration sensitivity.

The BFSL is used only to estimate operating-range non-linearity and diagnostic fit statistics.

The certificate sensitivity remains the sensitivity used for pressure conversion in the measurement chain.

---

## 11. Certificate-response compatibility check

In addition to the BFSL-based non-linearity estimate, calculate a separate compatibility check between the certificate-based observed pressure and the reference pressure.

For each point:

$$
r_{\mathrm{cert},i}
=
P_{\mathrm{obs},i}
-
P_{\mathrm{ref},i}
$$

In MATLAB:

```matlab
r_cert = P_obs - P_ref;
abs_r_cert = abs(r_cert);
r_cert_percent_FS = r_cert / FS_verification * 100;
```

For each sensor:

```matlab
delta_cert_max = max(abs(r_cert));
certificate_response_deviation_percent_FS = delta_cert_max / FS_verification * 100;
```

Label this result as:

- `certificate_response_deviation`
- or `operating_range_certificate_compatibility`

Do **not** call this pure non-linearity, because it may include sensitivity offset, zero offset, drift, reference uncertainty, and other systematic effects.

---

## 12. Hysteresis estimation

Hysteresis is evaluated separately from non-linearity because it represents path-dependent behaviour of the sensor response.

For matching nominal pressure levels measured during increasing and decreasing pressure sequences, calculate hysteresis by pairing points with the same pressure level and opposite directions (`up` and `down`):

$$
h_i
=
P_{\mathrm{up},i}
-
P_{\mathrm{down},i}
$$

In MATLAB:

```matlab
hysteresis = P_up - P_down;
hysteresis_abs = abs(hysteresis);
```

Maximum hysteresis:

$$
\delta_{\mathrm{hys}}
=
\max_i |h_i|
$$

In MATLAB:

```matlab
delta_hys = max(abs(hysteresis));
```

If included as a bounded systematic uncertainty contribution, calculate:

$$
u_{\mathrm{hys}}
=
\frac{\delta_{\mathrm{hys}}}{\sqrt{3}}
$$

In MATLAB:

```matlab
u_hysteresis = delta_hys / sqrt(3);
u_hysteresis_percent_FS_verification = u_hysteresis / FS_verification * 100;
```

Important:

Do not automatically combine hysteresis into the linearity uncertainty. Save it separately for later uncertainty-budget decisions.

---

## 13. Repeatability estimation

Repeatability is estimated from repeated measurements performed at selected pressure levels under nominally identical conditions.

For a given pressure level \(k\), with \(n_k\) repeated readings \(P_{k,j}\), the mean pressure is:

$$
\bar{P}_k
=
\frac{1}{n_k}
\sum_{j=1}^{n_k}
P_{k,j}
$$

The experimental standard deviation of the repeated readings is:

$$
s_{\mathrm{rep},k}
=
\sqrt{
\frac{1}{n_k-1}
\sum_{j=1}^{n_k}
\left(
P_{k,j}
-
\bar{P}_k
\right)^2
}
$$

If the mean value \(\bar{P}_k\) is used as the reported value at that pressure level, the Type A standard uncertainty of the mean is:

$$
u_{\mathrm{rep},k}
=
\frac{s_{\mathrm{rep},k}}{\sqrt{n_k}}
$$

In MATLAB:

```matlab
P_bar = mean(P_repeated);
s_rep = std(P_repeated, 0);      % sample standard deviation, n-1 normalization
u_rep_mean = s_rep / sqrt(n);
```

### 13.1 Conservative rectangular alternative

As an alternative, when the number of repeated measurements is small and a bounded rectangular model is preferred, estimate repeatability from the observed range:

$$
R_{\mathrm{rep},k}
=
P_{\max,k}
-
P_{\min,k}
$$

The half-width is:

$$
a_{\mathrm{rep},k}
=
\frac{R_{\mathrm{rep},k}}{2}
$$

The rectangular standard uncertainty is:

$$
u_{\mathrm{rep,rect},k}
=
\frac{R_{\mathrm{rep},k}}{2\sqrt{3}}
=
\frac{
P_{\max,k}
-
P_{\min,k}
}{
2\sqrt{3}
}
$$

In MATLAB:

```matlab
R_rep = max(P_repeated) - min(P_repeated);
u_rep_rect = R_rep / (2 * sqrt(3));
```

The selected repeatability contribution method must be stated explicitly in the outputs.

The output should report both:

- `u_rep_mean`
- `u_rep_rect`

and include a selected/recommended field:

```matlab
repeatability_method_selected = "typeA_mean";  % or "rectangular_range"
```

---

## 14. Baseline drift / zero stability

Zero readings must be treated separately from repeatability when short charge-amplifier time constants cause rapid baseline drift.

Calculate start-to-end zero drift in Set 1:

$$
\Delta P_{\mathrm{zero,Set1}}
=
P_{\mathrm{zero,end}}
-
P_{\mathrm{zero,start}}
$$

For repeated zero readings in Set 2, calculate:

- mean zero,
- standard deviation of zero,
- maximum zero,
- minimum zero,
- zero range,
- zero drift rate if timestamps are available.

Example MATLAB fields:

```matlab
zero_mean = mean(P_zero);
zero_std = std(P_zero, 0);
zero_range = max(P_zero) - min(P_zero);
zero_drift = P_zero(end) - P_zero(1);
```

Do not automatically combine zero drift with repeatability. Save it separately.

---

## 15. Grouping repeated pressure points

If the same reference/nominal pressure appears multiple times, group results by:

- sensor ID,
- source file,
- measurement set,
- pressure level,
- direction.

For each group calculate:

- mean observed pressure,
- standard deviation of observed pressure,
- mean reference pressure,
- mean certificate-response residual,
- standard deviation of certificate-response residual,
- number of selected windows,
- repeatability estimates,
- comments/warnings.

---

## 16. Plots

Generate and save the following plots for each sensor.

### Plot 1 — Observed pressure vs reference pressure

- x-axis: reference pressure
- y-axis: observed pressure
- include ideal line \(P_{\mathrm{obs}} = P_{\mathrm{ref}}\)
- include BFSL line
- label axes with units

### Plot 2 — BFSL residual vs reference pressure

- x-axis: reference pressure
- y-axis: \(r_{\mathrm{lin}}\)
- include zero residual line
- mark the maximum absolute BFSL residual

### Plot 3 — BFSL residual as %FS_ver

- x-axis: reference pressure
- y-axis: \(r_{\mathrm{lin}}/FS_{\mathrm{ver}}\times100\)

### Plot 4 — Certificate-response residual vs reference pressure

- x-axis: reference pressure
- y-axis: \(r_{\mathrm{cert}}\)
- include zero residual line

### Plot 5 — Certificate-response residual as %FS_ver

- x-axis: reference pressure
- y-axis: \(r_{\mathrm{cert}}/FS_{\mathrm{ver}}\times100\)

### Plot 6 — Hysteresis vs reference pressure

Generate only if matching up/down data are available.

### Plot 7 — Repeatability plot

For repeated pressure points, plot repeated readings at each repeatability pressure level.

### Plot 8 — Raw signal with selected windows highlighted

Overlay selected windows on the raw signal.

---

## 17. Output files

Save all outputs to a user-selected results folder.

Save:

- `.mat` file with all raw extracted data structures,
- `.csv` table with selected-window metadata,
- `.csv` table with extracted point statistics,
- `.csv` table with point-by-point PSV results,
- `.csv` table with Set 1 linearity/hysteresis results,
- `.csv` table with Set 2 repeatability/baseline results,
- `.csv` table with sensor-level PSV summary,
- optionally `.xlsx` workbook with separate sheets,
- `.png` or `.fig` plots.

### 17.1 Point-by-point result table

The point-by-point result table must include:

- source filename,
- sensor ID,
- channel name,
- measurement set,
- verification point ID,
- verification full scale,
- certificate sensitivity used,
- sensitivity unit,
- gain settings,
- zero-offset method,
- nominal pressure,
- reference pressure,
- reference source,
- observed pressure,
- BFSL fitted pressure,
- BFSL residual,
- BFSL absolute residual,
- BFSL residual as %FS_ver,
- certificate-response residual,
- certificate-response absolute residual,
- certificate-response residual as %FS_ver,
- direction,
- number of samples,
- standard deviation inside selected window,
- median,
- MAD,
- selected start time,
- selected end time,
- trimmed start time,
- trimmed end time,
- comments.

### 17.2 Sensor-level summary table

The sensor-level summary table must include:

- sensor ID,
- source file or file group,
- verification range,
- number of Set 1 verification points,
- number of Set 2 repeatability points,
- BFSL slope,
- BFSL intercept,
- BFSL residual standard error,
- maximum absolute BFSL residual,
- linearity %FS_ver over 0–0.5 bar,
- standard uncertainty from linearity,
- standard uncertainty from linearity as %FS_ver,
- maximum certificate-response deviation,
- certificate-response deviation as %FS_ver,
- maximum hysteresis if available,
- hysteresis standard uncertainty if calculated,
- repeatability Type A standard deviation,
- repeatability standard uncertainty of the mean,
- repeatability rectangular range-based uncertainty,
- selected repeatability method,
- baseline drift / zero stability metrics,
- notes/warnings.

---

## 18. Demonstration mode

If no measurement file is available, include a synthetic-data demo using:

```matlab
generateSyntheticPSVData.m
```

The synthetic data should mimic:

- Set 1 increasing/decreasing pressure plateaus over 0–0.5 bar,
- Set 2 repeated points at 0 bar and 0.250 bar,
- optional repeated points at 0.500 bar,
- small noise,
- baseline drift,
- transient rise and decay regions,
- small non-linearity,
- hysteresis effect.

This must allow testing of:

- plotting,
- channel selection,
- window selection,
- point extraction,
- BFSL non-linearity calculation,
- certificate-response compatibility check,
- hysteresis calculation,
- repeatability calculation,
- baseline drift calculation,
- output generation.

---

## 19. Error handling

The code should fail gracefully if:

- no time channel is found,
- selected channel lengths do not match,
- required metadata are missing,
- certificate sensitivity is missing,
- units are unsupported,
- `.tpc5` reader is unavailable,
- no windows are selected,
- reference pressure is missing,
- fewer than 3 Set 1 points are available for BFSL fitting,
- insufficient matching up/down pressure levels are available for hysteresis,
- insufficient repeated points are available for repeatability.

Error messages should explain what the user needs to provide.

---

## 20. Quality requirements

- Do not overwrite raw data.
- Do not modify raw data during processing.
- Do not hard-code channel names.
- Keep all units explicit.
- Use clear variable names.
- Add comments explaining each major calculation.
- Keep the workflow traceable and suitable for later GUM uncertainty-budget work.
- Prioritize robust, readable MATLAB code over a complex GUI.
- Use plain MATLAB figures and interactive tools if possible.
- Avoid requiring App Designer unless necessary.
- Make the main script readable enough to be used in a MATLAB Live Script report.

---

## 21. Key MATLAB equations to implement

### Certificate-based pressure conversion

```matlab
P_obs = certificateBasedPressure(mean_signal, zero_offset, S_cert, G_amp, DAQ_gain);
```

or, if already converted:

```matlab
P_obs = mean_signal;
```

### BFSL non-linearity

```matlab
FS_verification = 0.5; % bar

coeff = polyfit(P_ref, P_obs, 1);
b = coeff(1);
a = coeff(2);

P_fit = polyval(coeff, P_ref);

r_lin = P_obs - P_fit;
delta_lin = max(abs(r_lin));

linearity_percent_FS_verification = delta_lin / FS_verification * 100;

u_linearity = delta_lin / sqrt(3);
u_linearity_percent_FS_verification = u_linearity / FS_verification * 100;

n = numel(P_obs);
s_BFSL = sqrt(sum((P_obs - P_fit).^2) / (n - 2));
```

### Certificate-response compatibility

```matlab
r_cert = P_obs - P_ref;
abs_r_cert = abs(r_cert);
r_cert_percent_FS = r_cert / FS_verification * 100;

delta_cert_max = max(abs(r_cert));
certificate_response_deviation_percent_FS = delta_cert_max / FS_verification * 100;
```

### Hysteresis

```matlab
hysteresis = P_up - P_down;
delta_hys = max(abs(hysteresis));

u_hysteresis = delta_hys / sqrt(3);
u_hysteresis_percent_FS_verification = u_hysteresis / FS_verification * 100;
```

### Repeatability

```matlab
P_bar = mean(P_repeated);
s_rep = std(P_repeated, 0);
n = numel(P_repeated);

u_rep_mean = s_rep / sqrt(n);

R_rep = max(P_repeated) - min(P_repeated);
u_rep_rect = R_rep / (2 * sqrt(3));
```

### Baseline drift

```matlab
zero_mean = mean(P_zero);
zero_std = std(P_zero, 0);
zero_range = max(P_zero) - min(P_zero);
zero_drift = P_zero(end) - P_zero(1);
```

---

## 22. Deliverable requested from Codex

Please generate the complete MATLAB code files listed above, with a short explanation of how to run the workflow step by step.

The implementation should support both real measurement files and synthetic demonstration data.

The code must clearly separate:

1. raw extraction,
2. certificate-based pressure conversion,
3. BFSL non-linearity estimation,
4. certificate-response compatibility check,
5. hysteresis estimation,
6. repeatability estimation,
7. baseline drift assessment,
8. result export.

Do not silently turn the operating-range verification into a recalibration.

---

## 23. References for methodology labels

Use the following terminology in comments and output labels:

[1] NIST gauge-study approach for non-linearity: maximum departure from fitted line treated as bounded systematic effect and converted using a rectangular distribution.

[2] JCGM/GUM Type A repeatability: sample standard deviation and standard uncertainty of the mean.

[3] EURAMET cg-17 pressure-instrument calibration logic: increasing/decreasing pressure sequence, separate evaluation of linearity, hysteresis, and repeatability.

