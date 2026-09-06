# EXP23K amendment 01 — Source-arm lookup repair

Time: 2026-09-04, after all 60 horizon-scaled trajectories were checkpointed
and before a development contrast or verdict was produced.

The analysis routine attempted to read `cumulativeArm` and `periodicArm` from
the EXP23K registry. Those identifiers belong to the frozen EXP23I source
registry; EXP23K itself contains only the new horizon-scaled arm. MATLAB
therefore stopped before computing or displaying any contrast.

The repair obtains both source identifiers from
`exp23iCumulativeClosedLoopRegistry`. No trajectory, seed, configuration,
metric, threshold, bootstrap rule or decision rule changes. The 60-row
checkpoint is resumed without rerunning trajectories, while the original
pre-amendment source remains in the run snapshot.

