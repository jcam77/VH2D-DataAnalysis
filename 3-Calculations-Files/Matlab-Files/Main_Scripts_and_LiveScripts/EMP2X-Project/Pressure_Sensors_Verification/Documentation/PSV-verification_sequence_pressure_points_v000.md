# Verification Sequence

The verification is divided into two measurement sets to avoid mixing different uncertainty effects.

**Set 1** is used to evaluate operating-range non-linearity and hysteresis. Six verification pressure levels are selected over the verification range \(FS_{\mathrm{ver}} = 0.5~\mathrm{bar}\), including the lower and upper limits and four internal pressure levels. The sequence consists of one increasing-pressure series and one decreasing-pressure series.

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

The non-linearity is evaluated from the deviation between the observed pressure response and a least-squares best-fit straight line (BFSL) over the selected verification range. Hysteresis is evaluated separately from the difference between increasing-pressure and decreasing-pressure readings at matching pressure levels.

For hysteresis, pair readings by matching the same nominal pressure level where both `up` and `down` measurements exist. The zero points (`VP01` and `VP12`) should be treated as baseline-drift checks rather than as hysteresis points.

**Set 2** is used to evaluate repeatability and baseline stability. Repeatability is evaluated from repeated measurements at \(0.250~\mathrm{bar}\), corresponding to \(50\%FS_{\mathrm{ver}}\). Zero-pressure readings are repeated separately to assess baseline drift, particularly for sensor configurations with short time constants where the zero signal may drift rapidly. Therefore, repeated zero readings are treated primarily as a zero-drift diagnostic rather than as pure repeatability.

## Set 2 — Repeatability and baseline stability

| Step | Pressure | %FS_ver | Purpose |
|---:|---:|---:|---|
| R1 | 0.000 bar | 0% | Baseline drift / zero stability check |
| R2 | 0.000 bar | 0% | Baseline drift / zero stability check |
| R3 | 0.000 bar | 0% | Baseline drift / zero stability check |
| R4 | 0.250 bar | 50% | Repeatability measurement |
| R5 | 0.250 bar | 50% | Repeatability measurement |
| R6 | 0.250 bar | 50% | Repeatability measurement |

If measurement time allows, an additional repeatability check may be performed at \(0.500~\mathrm{bar}\), corresponding to \(100\%FS_{\mathrm{ver}}\). This additional point is not required for the minimum verification sequence but may provide useful information near the upper bound of the verification range.

## Optional additional repeatability point

| Step | Pressure | %FS_ver | Purpose |
|---:|---:|---:|---|
| R7 | 0.500 bar | 100% | Optional upper-range repeatability |
| R8 | 0.500 bar | 100% | Optional upper-range repeatability |
| R9 | 0.500 bar | 100% | Optional upper-range repeatability |

## Notes for MATLAB Live Editor

Markdown tables in MATLAB Live Editor can render LaTeX inconsistently inside table cells. For this reason, the table headers use plain text `%FS_ver`. The explanatory text outside the tables keeps LaTeX notation.

