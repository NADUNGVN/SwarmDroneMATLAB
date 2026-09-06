# EXP21D-B operational amendment 01

**Date:** 2026-09-01  
**Run:** `results/exp21d_boundary_continuation/2026-09-01_104515`  
**Applied after:** first complete checkpoint, 24/360 rows  
**Outcome access before change:** none; only row count/runtime was observed.

The original runner rebuilt the identical zero-loss kernel for both native and
warm arms and likewise rebuilt the identical beacon-loss kernel twice. It was
stopped after the first complete four-group checkpoint. The group runner now
builds one native schedule for each of the four unique conditions (`zero`,
`beacon-loss`, `restricted-management`, `churn-rejoin`) and passes the zero/loss
schedule to the corresponding warm transformation.

This is a deterministic computation cache. It does not change the registry,
seeds, random arrays, kernel configuration, warm coloring, event timeline,
controller, accounting, analysis or gates. The first 24 rows remain in the
checkpoint and are not recomputed.

