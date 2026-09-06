# EXP21D-B operational amendment 02

**Date:** 2026-09-01  
**Run:** `results/exp21d_boundary_continuation/2026-09-01_104515`  
**State:** 360/360 rows complete; all output tables and the 16/16-gate
`DSTR_BOUNDARY_STUDY_VALID` verdict had already been written.

The resume helper reconstructed the experiment metadata without the timer
field required by `finishExperiment`. After adding it, finalization exposed the
remaining missing index fields (`matlabRelease` and the original run ID). The
helper now reconstructs complete finalization metadata from
`boundary_opened.json`, the run-directory basename and the active MATLAB
version. The run is resumed from its complete checkpoint: there are zero
pending simulation groups, so it deterministically regenerates analysis files
and executes only final provenance/index housekeeping.

No registry, trajectory, metric, gate, analysis definition or scientific
verdict changes.
